// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/navigation/main_tab_page.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_schedule_card.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import '../design_update_2026-11-10/render_update_test.dart' as fixtures;

class EditRenderService extends CalendarService {
  EditRenderService() : super(Dio());
  final delete_pending = Completer<String>();
  EventApiModel get event {
    final date = DateTime.now();
    return EventApiModel(
      eventId: 'edit-render',
      title: '친구와 저녁 약속',
      memo: '퇴근 후 함께 식사하기',
      place: '서울역',
      allDay: false,
      startAt: DateTime(date.year, date.month, date.day, 18, 30),
      endAt: DateTime(date.year, date.month, date.day, 20),
      visibilityLevel: 2,
    );
  }

  @override
  Future<CalendarRangeResponse> getCalendarRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async => CalendarRangeResponse(
    success: true,
    data: CalendarRangeData(workShifts: [], events: [event]),
  );
  @override
  Future<EventApiModel> updateEvent(
    String event_id,
    UpdateEventRequest request,
  ) async => throw StateError('render-only save failure');
  @override
  Future<String> deleteEvent(String event_id) => delete_pending.future;
}

void main() {
  testWidgets('개인 일정 수정/삭제의 실제 메인 진입·화면/키보드/큰 글자를 검증한다', (tester) async {
    await initializeDateFormatting('ko_KR');
    for (final entry in {
      'Cafe24SsurroundAir': 'assets/fonts/Cafe24SsurroundAir-v1.1.ttf',
      'Cafe24Ssurround': 'assets/fonts/Cafe24Ssurround-v2.0.ttf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    final output = Directory('artifacts/personal_event_edit_2026-11-12')
      ..createSync(recursive: true);
    final measurements = <String, Object>{};
    for (final scenario in [
      (
        name: 'normal',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 0.0,
        reduced: false,
      ),
      (
        name: 'phone375',
        size: const Size(375, 812),
        scale: 1.0,
        keyboard: 0.0,
        reduced: false,
      ),
      (
        name: 'small320',
        size: const Size(320, 568),
        scale: 1.0,
        keyboard: 0.0,
        reduced: false,
      ),
      (
        name: 'large_text',
        size: const Size(320, 568),
        scale: 2.0,
        keyboard: 0.0,
        reduced: false,
      ),
      (
        name: 'keyboard',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 300.0,
        reduced: false,
      ),
      (
        name: 'landscape',
        size: const Size(844, 390),
        scale: 1.0,
        keyboard: 0.0,
        reduced: false,
      ),
      (
        name: 'tablet',
        size: const Size(768, 1024),
        scale: 1.0,
        keyboard: 0.0,
        reduced: false,
      ),
      (
        name: 'reduced_motion',
        size: const Size(375, 812),
        scale: 1.0,
        keyboard: 0.0,
        reduced: true,
      ),
    ]) {
      await tester.binding.setSurfaceSize(scenario.size);
      // 실제 기기 저장소를 사용하지 않는 위젯 렌더 fixture.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final service = EditRenderService();
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            fixtures.AuditAuthRepository(),
          ),
          calendarServiceProvider.overrideWithValue(service),
          shiftTypesProvider.overrideWith((ref) async => []),
          friendListProvider.overrideWith(
            (ref) => fixtures.AuditFriendNotifier(),
          ),
          notificationProvider.overrideWith(
            (ref) => fixtures.AuditNotificationNotifier(),
          ),
          groupRepositoryProvider.overrideWithValue(
            fixtures.AuditGroupRepository(),
          ),
        ],
      );
      await container.read(authProvider.notifier).checkAuthStatus();
      final capture_key = GlobalKey();
      final inset = ValueNotifier<double>(0);
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture_key,
          child: UncontrolledProviderScope(
            container: container,
            child: CupertinoApp(
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => ValueListenableBuilder<double>(
                valueListenable: inset,
                builder: (context, value, _) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: scenario.size,
                    textScaler: TextScaler.linear(scenario.scale),
                    viewInsets: EdgeInsets.only(bottom: value),
                    disableAnimations: scenario.reduced,
                  ),
                  child: child!,
                ),
              ),
              home: const MainTabPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> capture(String suffix) async {
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 32));
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final boundary =
              capture_key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 2);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File(
            '${output.path}/${scenario.name}_$suffix.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
      }

      final row = find.byKey(const ValueKey('event-edit-render-0'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(CalendarEventItem)).height,
        greaterThanOrEqualTo(48),
      );
      await capture('list');
      await tester.tap(row);
      await tester.pumpAndSettle();
      inset.value = scenario.keyboard;
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('personal-event-save-button'));
      final save_rect = tester.getRect(save);
      expect(
        save_rect.bottom,
        lessThanOrEqualTo(scenario.size.height - scenario.keyboard),
      );
      expect(save_rect.height, greaterThanOrEqualTo(48));
      expect(find.text('개인 일정 수정'), findsOneWidget);
      await capture('edit');
      measurements[scenario.name] = {
        'width': scenario.size.width,
        'height': scenario.size.height,
        'scale': scenario.scale,
        'keyboard': scenario.keyboard,
        'save_bottom': save_rect.bottom,
        'save_height': save_rect.height,
        'exceptions': 0,
      };
      if (scenario.name == 'normal') {
        await tester.enterText(
          find.byKey(const Key('personal-event-title-field')),
          '수정한 저녁 약속',
        );
        await tester.pumpAndSettle();
        await tester.tap(save);
        await tester.pumpAndSettle();
        await capture('error');
        await tester.tap(find.byKey(const Key('personal-event-back-button')));
        await tester.pumpAndSettle();
        final gesture = await tester.startGesture(tester.getCenter(row));
        await gesture.moveBy(const Offset(-20, 0));
        await tester.pump();
        await gesture.moveBy(const Offset(-110, 0));
        await tester.pump(const Duration(milliseconds: 200));
        await capture('swipe');
        await gesture.up();
        await tester.pumpAndSettle();
        await tester.drag(row, const Offset(-360, 0));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        await capture('deleting');
        service.delete_pending.complete('edit-render');
        await tester.pumpAndSettle();
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
      inset.dispose();
      container.dispose();
    }
    await tester.runAsync(
      () => File(
        '${output.path}/measurements.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(measurements)),
    );
    await tester.binding.setSurfaceSize(null);
  });
}
