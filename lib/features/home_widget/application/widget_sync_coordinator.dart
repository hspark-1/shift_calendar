// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../calendar/data/models/event_api_model.dart';
import '../../calendar/data/services/calendar_service.dart';
import '../data/home_widget_store.dart';
import '../data/shift_widget_snapshot.dart';

typedef WidgetCalendarLoader =
    Future<CalendarRangeData> Function({
      required DateTime start_date,
      required DateTime end_date,
    });

final widgetSyncCoordinatorProvider = Provider<WidgetSyncCoordinator>((ref) {
  // mutation 서비스의 갱신 콜백이 coordinator를 읽으므로, 조회용 인스턴스는
  // 같은 인증 Dio만 공유해 provider 의존성이 순환하지 않게 한다.
  final service = CalendarService(ref.watch(dioProvider));
  final coordinator = WidgetSyncCoordinator(
    enabled: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
    store: IosHomeWidgetStore(),
    loader: ({required start_date, required end_date}) async {
      final response = await service.getCalendarRange(
        startDate: start_date,
        endDate: end_date,
      );
      return response.data;
    },
    device_timezone: () async =>
        (await FlutterTimezone.getLocalTimezone()).identifier,
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// API 결과와 공유 저장소 쓰기를 별도로 직렬화한다. 계정/요청 revision이
/// 바뀌면 늦은 응답을 폐기하고, 확정되지 않은 근무/일정 draft는 저장하지 않는다.
class WidgetSyncCoordinator {
  WidgetSyncCoordinator({
    required this.enabled,
    required this.store,
    required this.loader,
    required this.device_timezone,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  final bool enabled;
  final HomeWidgetStore store;
  final WidgetCalendarLoader loader;
  final Future<String> Function() device_timezone;
  final DateTime Function() now;
  String? _owner_id;
  String? _timezone;
  bool _has_session = false;
  bool _disposed = false;
  int _session_revision = 0;
  int _request_revision = 0;
  Future<void> _writes = Future.value();
  Future<void>? _in_flight;
  Future<void> _ready = Future.value();

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _writes.then((_) => action());
    _writes = next.catchError((Object _) {});
    return next;
  }

  bool _isCurrent(int session_revision, int request_revision) =>
      !_disposed &&
      session_revision == _session_revision &&
      request_revision == _request_revision;

  Future<void> setSession({String? owner_id, String? timezone}) {
    if (!enabled || _disposed) return Future.value();
    if (_has_session && _owner_id == owner_id && _timezone == timezone) {
      return _ready;
    }
    _has_session = true;
    _owner_id = owner_id;
    _timezone = timezone;
    final session_revision = ++_session_revision;
    ++_request_revision;
    _in_flight = null;
    _ready =
        _enqueue(() async {
          if (_disposed || session_revision != _session_revision) return;
          if (owner_id == null) {
            await store.write(null);
            await store.reload();
            return;
          }
          // 같은 계정으로 시작할 때는 마지막 확정 데이터를 오프라인에서도 유지한다.
          Map<String, dynamic>? cached;
          try {
            final raw = await store.read();
            cached = raw == null
                ? null
                : jsonDecode(raw) as Map<String, dynamic>;
          } catch (_) {
            cached = null;
          }
          if (_disposed || session_revision != _session_revision) return;
          if (cached?['owner_id'] != owner_id ||
              (timezone != null && cached?['timezone'] != timezone)) {
            await store.write(null);
            await store.reload();
          }
        }).catchError((Object _) {
          if (session_revision == _session_revision) _has_session = false;
          debugPrint('위젯 공유 저장소 초기화 실패');
        });
    return _ready.then((_) => owner_id == null ? null : sync());
  }

  Future<void> sync({bool force = false}) {
    if (!enabled || _disposed || _owner_id == null) return Future.value();
    if (!force && _in_flight != null) return _in_flight!;
    final session_revision = _session_revision;
    final request_revision = ++_request_revision;
    final owner_id = _owner_id!;
    final requested_timezone = _timezone;
    final operation = _sync(
      session_revision,
      request_revision,
      owner_id,
      requested_timezone,
    );
    _in_flight = operation;
    unawaited(
      operation.then((_) {
        if (identical(_in_flight, operation)) _in_flight = null;
      }),
    );
    return operation;
  }

  Future<void> _sync(
    int session_revision,
    int request_revision,
    String owner_id,
    String? requested_timezone,
  ) async {
    try {
      await _ready;
      if (!_isCurrent(session_revision, request_revision)) return;
      String timezone;
      try {
        tz.getLocation(requested_timezone ?? '');
        timezone = requested_timezone!;
      } on tz.LocationNotFoundException {
        timezone = await device_timezone();
        tz.getLocation(timezone);
      }
      if (!_isCurrent(session_revision, request_revision)) return;
      final range = ShiftWidgetSnapshot.rangeFor(now(), timezone);
      final calendar_data = await loader(
        start_date: range.start_date,
        end_date: range.end_date,
      );
      if (!_isCurrent(session_revision, request_revision)) return;
      final snapshot = ShiftWidgetSnapshot(
        owner_id: owner_id,
        timezone: timezone,
        updated_at: now(),
        start_date: range.start_date,
        end_date: range.end_date,
        shifts: calendar_data.workShifts,
        events: calendar_data.events,
      );
      await _enqueue(() async {
        if (!_isCurrent(session_revision, request_revision)) return;
        await store.write(jsonEncode(snapshot.toJson()));
        // 로그아웃이 write를 기다리는 경우 다음 직렬 작업이 삭제한다.
        if (!_isCurrent(session_revision, request_revision)) return;
        await store.reload();
      });
    } catch (error) {
      if (!_isCurrent(session_revision, request_revision)) return;
      if (error is ApiException &&
          (error.statusCode == 401 || error.statusCode == 403)) {
        try {
          await _enqueue(() async {
            if (!_isCurrent(session_revision, request_revision)) return;
            await store.write(null);
            await store.reload();
          });
        } catch (_) {
          debugPrint('위젯 공유 데이터 삭제 실패');
        }
      }
      // 인증/근무·일정 저장을 위젯 동기화의 성공 여부에 종속시키지 않는다.
      debugPrint('위젯 캘린더 동기화 실패');
    }
  }

  void dispose() {
    _disposed = true;
    ++_session_revision;
    ++_request_revision;
  }
}
