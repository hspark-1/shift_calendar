// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/core/network/api_client.dart';
import 'package:shift_mate/features/calendar/data/models/work_shift_api_model.dart';
import 'package:shift_mate/features/calendar/data/models/shift_type_api_model.dart';
import 'package:shift_mate/features/calendar/data/services/work_shift_service.dart';
import 'package:shift_mate/features/calendar/data/services/shift_type_service.dart';
import 'package:shift_mate/features/home_widget/application/widget_sync_coordinator.dart';
import 'package:shift_mate/features/home_widget/data/home_widget_store.dart';
import 'package:shift_mate/features/home_widget/data/shift_widget_snapshot.dart';

class MemoryStore implements HomeWidgetStore {
  String? value;
  int reloads = 0;
  Completer<void>? write_gate;
  Completer<void>? write_started;
  bool fail_read = false;

  @override
  Future<String?> read() async {
    if (fail_read) throw StateError('read');
    return value;
  }

  @override
  Future<void> write(String? snapshot) async {
    if (snapshot != null && write_gate != null) {
      write_started?.complete();
      await write_gate!.future;
    }
    value = snapshot;
  }

  @override
  Future<void> reload() async => reloads++;
}

WorkShiftApiModel shift(String code, {DateTime? date}) => WorkShiftApiModel(
  workShiftId: 'work-id',
  workDate: date ?? DateTime(2026, 11, 21),
  shiftTypeCode: code,
  shiftTypeName: '근무 이름',
  shiftTypeColor: 0xFF0061A4,
  startTime: '23:00:00',
  endTime: '07:00:00',
  note: '공유하면 안 되는 메모',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(timezone_data.initializeTimeZones);

  test('Dart 공유 JSON을 Swift 계약 검증에 전달한다', () {
    final output = Platform.environment['WIDGET_CONTRACT_OUTPUT'];
    final snapshot = ShiftWidgetSnapshot(
      owner_id: 'contract-owner',
      timezone: 'Asia/Seoul',
      updated_at: DateTime.utc(2026, 11, 21),
      start_date: DateTime(2026, 11, 16),
      end_date: DateTime(2026, 12, 27),
      shifts: [shift('N')],
    );
    if (output != null) {
      File(output).writeAsStringSync(jsonEncode(snapshot.toJson()));
    }
    expect(snapshot.toJson()['schema_version'], 1);
  });

  test('시간대의 날짜와 월요일·6주 범위를 사용하고 민감 필드를 제외한다', () {
    final now = DateTime.utc(2026, 11, 22, 16);
    final range = ShiftWidgetSnapshot.rangeFor(now, 'Asia/Seoul');
    expect(range.start_date, DateTime(2026, 11, 23));
    expect(range.end_date, DateTime(2027, 1, 3));
    final json = ShiftWidgetSnapshot(
      owner_id: 'owner',
      timezone: 'Asia/Seoul',
      updated_at: now,
      start_date: range.start_date,
      end_date: range.end_date,
      shifts: [
        shift('N', date: DateTime(2026, 11, 24)),
        shift('old'),
      ],
    ).toJson();
    final shifts = json['shifts'] as List;
    expect(shifts, hasLength(1));
    expect(shifts.single, containsPair('date', '2026-11-24'));
    expect(jsonEncode(json), isNot(contains('공유하면')));
    expect(jsonEncode(json), isNot(contains('work-id')));
    expect(jsonEncode(json), isNot(contains('events')));
    final dst_range = ShiftWidgetSnapshot.rangeFor(
      DateTime.utc(2026, 11, 1, 6),
      'America/New_York',
    );
    expect(dst_range.start_date, DateTime(2026, 10, 26));
    expect(dst_range.end_date, DateTime(2026, 12, 6));
  });

  late MemoryStore store;
  late WidgetSyncCoordinator coordinator;
  var calls = 0;
  var zone_calls = 0;
  late WidgetShiftLoader loader;

  setUp(() {
    store = MemoryStore();
    calls = 0;
    zone_calls = 0;
    loader = ({required start_date, required end_date}) async => [shift('D')];
    coordinator = WidgetSyncCoordinator(
      enabled: true,
      store: store,
      loader: ({required start_date, required end_date}) {
        calls++;
        return loader(start_date: start_date, end_date: end_date);
      },
      device_timezone: () async {
        zone_calls++;
        return 'Asia/Seoul';
      },
      now: () => DateTime.utc(2026, 11, 21),
    );
  });
  tearDown(() => coordinator.dispose());

  test('실제 서비스 provider는 확정된 근무·타입 mutation에만 갱신을 연결한다', () async {
    final work = {
      'work_shift_id': 'id',
      'work_date': '2026-11-21',
      'shift_type_code': 'D',
      'shift_type_name': '데이',
      'created_at': '2026-11-21T00:00:00Z',
      'updated_at': '2026-11-21T00:00:00Z',
    };
    var fail = false;
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (fail) {
            handler.reject(
              DioException(
                requestOptions: options,
                response: Response(requestOptions: options, statusCode: 500),
                type: DioExceptionType.badResponse,
              ),
            );
            return;
          }
          final Object data;
          if (options.path.contains('shift-types')) {
            data = options.method == 'DELETE'
                ? {
                    'shift_type_id': 'type',
                    'deleted_at': '2026-11-21T00:00:00Z',
                  }
                : {
                    'shift_type_id': 'type',
                    'code': 'N',
                    'name': '야간',
                    'crosses_midnight': true,
                    'duration_minutes': 480,
                  };
          } else {
            data = options.path.endsWith('/batch')
                ? {
                    'work_shifts': [work],
                  }
                : work;
          }
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: {'success': true, 'data': data},
            ),
          );
        },
      ),
    );
    final container = ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        widgetSyncCoordinatorProvider.overrideWithValue(coordinator),
      ],
    );
    addTearDown(container.dispose);
    await coordinator.setSession(owner_id: 'a', timezone: 'Asia/Seoul');
    final service = container.read(workShiftServiceProvider);
    await service.upsertWorkShift(
      workDate: DateTime(2026, 11, 21),
      shiftTypeCode: 'D',
    );
    await coordinator.sync();
    expect(calls, 2);
    await service.updateWorkShift(workShiftId: 'id', shiftTypeCode: 'N');
    await coordinator.sync();
    expect(calls, 3);
    await service.batchUpsertWorkShifts(
      workShifts: [
        {'work_date': '2026-11-21', 'shift_type_code': 'N'},
      ],
    );
    await coordinator.sync();
    expect(calls, 4);
    await service.deleteWorkShift('id');
    await coordinator.sync();
    expect(calls, 5);
    final types = container.read(shiftTypeServiceProvider);
    await types.updateShiftType('type', UpdateShiftTypeRequest(name: '야간'));
    await coordinator.sync();
    expect(calls, 6);
    await types.deleteShiftType('type');
    await coordinator.sync();
    expect(calls, 7);
    fail = true;
    await expectLater(
      service.deleteWorkShift('id'),
      throwsA(isA<ApiException>()),
    );
    expect(calls, 7);
  });

  test('시작·복귀 갱신과 삭제 후 빈 응답을 덮어쓴다', () async {
    await coordinator.setSession(owner_id: 'a', timezone: 'Asia/Seoul');
    expect(calls, 1);
    expect(zone_calls, 0);
    expect((jsonDecode(store.value!)['shifts'] as List).single['code'], 'D');
    loader = ({required start_date, required end_date}) async => [];
    await coordinator.sync(force: true);
    expect(jsonDecode(store.value!)['shifts'], isEmpty);
    await coordinator.setSession();
    expect(store.value, isNull);
  });

  test('조회 중 로그아웃하면 늦은 응답을 폐기한다', () async {
    final response = Completer<List<WorkShiftApiModel>>();
    final started = Completer<void>();
    loader = ({required start_date, required end_date}) {
      started.complete();
      return response.future;
    };
    final login = coordinator.setSession(owner_id: 'a');
    await started.future;
    await coordinator.setSession();
    response.complete([shift('N')]);
    await login;
    expect(store.value, isNull);
  });

  test('저장 중 로그아웃은 진행 중 write 뒤에서 삭제를 완료한다', () async {
    store.write_gate = Completer<void>();
    store.write_started = Completer<void>();
    final login = coordinator.setSession(owner_id: 'a', timezone: 'Asia/Seoul');
    await store.write_started!.future;
    final logout = coordinator.setSession();
    store.write_gate!.complete();
    await Future.wait([login, logout]);
    expect(store.value, isNull);
  });

  test('다른 계정 전환은 이전 캐시와 응답을 재사용하지 않는다', () async {
    await coordinator.setSession(owner_id: 'a', timezone: 'Asia/Seoul');
    final old = Completer<List<WorkShiftApiModel>>();
    loader = ({required start_date, required end_date}) => old.future;
    final pending = coordinator.sync();
    await Future<void>.delayed(Duration.zero);
    loader = ({required start_date, required end_date}) async {
      expect(store.value, isNull);
      return [shift('B')];
    };
    await coordinator.setSession(owner_id: 'b', timezone: 'Asia/Seoul');
    old.complete([shift('A')]);
    await pending;
    expect(jsonDecode(store.value!)['owner_id'], 'b');
    expect((jsonDecode(store.value!)['shifts'] as List).single['code'], 'B');
  });

  test('수정 이후 강제 조회가 먼저 끝나면 이전 응답은 무시한다', () async {
    await coordinator.setSession(owner_id: 'a', timezone: 'Asia/Seoul');
    final old = Completer<List<WorkShiftApiModel>>();
    loader = ({required start_date, required end_date}) => old.future;
    final pending = coordinator.sync();
    await Future<void>.delayed(Duration.zero);
    expect(identical(pending, coordinator.sync()), isTrue);
    loader = ({required start_date, required end_date}) async => [shift('NEW')];
    await coordinator.sync(force: true);
    old.complete([shift('OLD')]);
    await pending;
    expect((jsonDecode(store.value!)['shifts'] as List).single['code'], 'NEW');
  });

  test('동일 계정 오프라인은 캐시 유지, 인증 실패는 삭제 후 재시도 가능', () async {
    await coordinator.setSession(owner_id: 'a', timezone: 'Asia/Seoul');
    final cached = store.value;
    coordinator.dispose();
    coordinator = WidgetSyncCoordinator(
      enabled: true,
      store: store,
      loader: ({required start_date, required end_date}) async =>
          throw StateError('offline'),
      device_timezone: () async => 'Asia/Seoul',
    );
    await coordinator.setSession(owner_id: 'a', timezone: 'Asia/Seoul');
    expect(store.value, cached);
    coordinator.dispose();
    coordinator = WidgetSyncCoordinator(
      enabled: true,
      store: store,
      loader: ({required start_date, required end_date}) =>
          loader(start_date: start_date, end_date: end_date),
      device_timezone: () async => 'Asia/Seoul',
    );
    loader = ({required start_date, required end_date}) async =>
        throw ApiException(code: 'UNAUTHORIZED', message: '', statusCode: 401);
    await coordinator.setSession(owner_id: 'a', timezone: 'Asia/Seoul');
    expect(store.value, isNull);
    loader = ({required start_date, required end_date}) async => [];
    await coordinator.sync();
    expect(store.value, isNotNull);
  });

  test('잘못된 시간대는 기기 시간대로 대체하고 비 iOS는 통신하지 않는다', () async {
    await coordinator.setSession(owner_id: 'a', timezone: 'invalid');
    expect(zone_calls, 1);
    expect(jsonDecode(store.value!)['timezone'], 'Asia/Seoul');
    coordinator.dispose();
    coordinator = WidgetSyncCoordinator(
      enabled: false,
      store: store,
      loader: ({required start_date, required end_date}) async =>
          throw StateError('호출 금지'),
      device_timezone: () async => throw StateError('호출 금지'),
    );
    final cached = store.value;
    await coordinator.setSession(owner_id: 'b');
    await coordinator.sync(force: true);
    await coordinator.setSession();
    expect(store.value, cached);
  });

  test('로그아웃 정리는 저장소 read 실패와 무관하게 삭제한다', () async {
    store.value = 'stale';
    store.fail_read = true;
    await coordinator.setSession();
    expect(store.value, isNull);
  });

  test('home_widget 실제 채널에 동일 App Group·키·kind와 null 삭제를 전달한다', () async {
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (
          call,
        ) async {
          calls.add(call);
          return call.method == 'getWidgetData' ? 'cache' : true;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), null),
    );
    final native = IosHomeWidgetStore();
    expect(await native.read(), 'cache');
    await native.write('{"schema_version":1}');
    await native.write(null);
    await native.reload();
    expect(calls.map((call) => call.method), [
      'getWidgetData',
      'saveWidgetData',
      'saveWidgetData',
      'updateWidget',
      'updateWidget',
    ]);
    expect(calls[2].arguments, {
      'id': IosHomeWidgetStore.snapshot_key,
      'data': null,
      'appGroupId': IosHomeWidgetStore.app_group,
    });
    expect(
      calls[calls.length - 2].arguments['ios'],
      IosHomeWidgetStore.widget_kind,
    );
    expect(
      calls.last.arguments['ios'],
      IosHomeWidgetStore.tomorrow_widget_kind,
    );
  });

  for (final throws_error in [false, true]) {
    test('오늘 위젯 갱신 실패($throws_error)에서도 내일 위젯 갱신을 시도한다', () async {
      final requested = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('home_widget'), (
            call,
          ) async {
            final kind = call.arguments['ios'] as String;
            requested.add(kind);
            if (kind == IosHomeWidgetStore.widget_kind) {
              if (throws_error) throw PlatformException(code: 'reload-failed');
              return false;
            }
            return true;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(const MethodChannel('home_widget'), null),
      );
      await expectLater(IosHomeWidgetStore().reload(), throwsStateError);
      expect(requested, IosHomeWidgetStore.widget_kinds);
    });
  }
}
