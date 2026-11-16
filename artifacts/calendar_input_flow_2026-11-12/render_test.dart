// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/date_picker_sheet.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/time_picker_sheet.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/navigation/main_tab_page.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';

import '../design_update_2026-11-10/render_update_test.dart' as fixtures;
import '../personal_event_edit_2026-11-12/render_test.dart' as edit;

void main() {
  testWidgets('실제 메인 오버레이와 제목 완료·캘린더·휠 시간 연결을 렌더한다', (tester) async {
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
    final picker_output = Platform.environment['PICKER_CONFIRM_RENDER_OUTPUT'];
    final toast_output = Platform.environment['TOAST_DISMISS_RENDER_OUTPUT'];
    final visibility_output =
        Platform.environment['EVENT_VISIBILITY_RENDER_OUTPUT'];
    final output = Directory(
      toast_output ??
          picker_output ??
          visibility_output ??
          'artifacts/calendar_input_flow_2026-11-12',
    )..createSync(recursive: true);
    final measurements = <String, Object>{};
    for (final scenario in [
      (name: 'normal', size: const Size(390, 844), scale: 1.0, dark: false),
      (name: 'phone375', size: const Size(375, 812), scale: 1.0, dark: false),
      (name: 'small320', size: const Size(320, 568), scale: 1.0, dark: false),
      (name: 'large_text', size: const Size(320, 568), scale: 2.0, dark: false),
      (name: 'landscape', size: const Size(844, 390), scale: 1.0, dark: false),
      (name: 'tablet', size: const Size(768, 1024), scale: 1.0, dark: false),
      (name: 'dark', size: const Size(390, 844), scale: 1.0, dark: true),
    ]) {
      await tester.binding.setSurfaceSize(scenario.size);
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final service = edit.EditRenderService();
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
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture_key,
          child: UncontrolledProviderScope(
            container: container,
            child: CupertinoApp(
              theme: scenario.dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(scenario.scale),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const MainTabPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.takeException(),
        isNull,
        reason: '${scenario.name}: 삭제 전 화면',
      );
      final row = find.byKey(const ValueKey('event-edit-render-0'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      final calendar = find.byKey(const ValueKey('main-calendar'));
      final card = find.byKey(const ValueKey('calendar-schedule-card'));
      final calendar_rect = tester.getRect(calendar);
      final card_rect = tester.getRect(card);
      await tester.drag(row, const Offset(-700, 0));
      await tester.pumpAndSettle();
      final toast = find.byKey(const ValueKey('calendar-delete-toast'));
      final button = find.byKey(const ValueKey('calendar-delete-undo'));
      final tab_bar = find.byKey(const ValueKey('main-glass-tab-bar'));
      expect(toast, findsOneWidget);
      expect(tester.getRect(calendar), calendar_rect);
      expect(tester.getRect(card), card_rect);
      expect(
        tester.getRect(toast).bottom,
        lessThanOrEqualTo(tester.getRect(tab_bar).top),
      );
      expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      measurements[scenario.name] = {
        'width': scenario.size.width,
        'height': scenario.size.height,
        'text_scale': scenario.scale,
        'toast_bottom': tester.getRect(toast).bottom,
        'tab_top': tester.getRect(tab_bar).top,
        'button_height': tester.getSize(button).height,
        'layout_unchanged': true,
        'exceptions': 0,
      };
      Future<void> capture(String step) async {
        if (visibility_output != null && step != 'visibility') return;
        await tester.pump();
        expect(
          tester.takeException(),
          isNull,
          reason: '${scenario.name}: $step',
        );
        await tester.runAsync(() async {
          final boundary =
              capture_key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final picture = await boundary.toImage(pixelRatio: 2);
          final bytes = await picture.toByteData(
            format: ui.ImageByteFormat.png,
          );
          await File(
            '${output.path}/${scenario.name}_$step.png',
          ).writeAsBytes(bytes!.buffer.asUint8List());
          picture.dispose();
        });
      }

      await capture('toast');
      if (toast_output != null) {
        final toast_rect = tester.getRect(toast);
        final gesture = await tester.startGesture(toast_rect.center);
        await gesture.moveBy(const Offset(0, 20));
        await gesture.moveBy(const Offset(0, 20));
        await tester.pump();
        final drag_distance = tester.getRect(toast).top - toast_rect.top;
        expect(drag_distance, greaterThan(0));
        await capture('drag');
        await gesture.moveBy(const Offset(0, 100));
        await gesture.up();
        await tester.pumpAndSettle();
        expect(toast, findsNothing);
        expect(tester.getRect(calendar), calendar_rect);
        expect(tester.getRect(card), card_rect);
        expect(row, findsNothing);
        await capture('dismissed');
        measurements[scenario.name] = {
          ...measurements[scenario.name] as Map<String, Object>,
          'drag_distance': drag_distance,
          'dismissed': true,
          'pending_event_hidden': true,
        };
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        container.dispose();
        continue;
      }
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(row, findsOneWidget);
      expect(toast, findsNothing);
      final add = find.text('일정 추가하기...');
      await tester.ensureVisible(add);
      await tester.pumpAndSettle();
      await tester.tap(add);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('personal-event-title-field')),
        '친구와 저녁 약속',
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerSheet), findsOneWidget);
      await capture('calendar');
      final today = DateTime.now();
      final day = find.byKey(
        ValueKey('date-picker-day-${today.year}-${today.month}-${today.day}'),
      );
      for (
        var scroll_attempt = 0;
        day.hitTestable().evaluate().isEmpty && scroll_attempt < 4;
        scroll_attempt++
      ) {
        final scroll_rect = tester.getRect(
          find.byKey(const ValueKey('date-picker-scroll')),
        );
        await tester.dragFrom(
          Offset(scroll_rect.left + 4, scroll_rect.center.dy),
          const Offset(0, -140),
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(day);
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerSheet), findsOneWidget);
      expect(find.byType(TimePickerSheet), findsNothing);
      final confirm = find.byKey(const ValueKey('date-picker-confirm'));
      final today_button = find.byKey(const ValueKey('date-picker-today'));
      expect(
        tester.getRect(today_button).bottom,
        lessThanOrEqualTo(
          tester
              .getRect(find.byKey(const ValueKey('date-picker-calendar')))
              .top,
        ),
      );
      expect(
        tester.getRect(confirm).bottom,
        lessThanOrEqualTo(scenario.size.height),
      );
      expect(tester.getSize(confirm).height, greaterThanOrEqualTo(48));
      if (picker_output != null && scenario.name == 'normal') {
        await capture('selected');
        final handle = find.byKey(const ValueKey('date-picker-handle'));
        final sheet = find.byKey(const ValueKey('date-picker-sheet'));
        final top = tester.getTopLeft(sheet).dy;
        final gesture = await tester.startGesture(tester.getCenter(handle));
        await gesture.moveBy(const Offset(0, 70));
        await tester.pump();
        await capture('drag');
        await gesture.up();
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(sheet).dy, closeTo(top, 0.1));
      }
      measurements[scenario.name] = {
        ...measurements[scenario.name] as Map<String, Object>,
        'date_confirm_height': tester.getSize(confirm).height,
        'date_confirm_bottom': tester.getRect(confirm).bottom,
        'today_above_calendar': true,
      };
      await tester.tap(confirm);
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerSheet), findsOneWidget);
      await tester.ensureVisible(find.byType(CupertinoDatePicker));
      await tester.pumpAndSettle();
      await capture('start_time');
      await tester.tap(find.text('선택한 시간 적용'));
      await tester.pumpAndSettle();
      expect(find.text('종료시간 선택'), findsOneWidget);
      await tester.tap(find.text('선택한 시간 적용'));
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerSheet), findsNothing);
      expect(find.text('친구에게 공개').hitTestable(), findsOneWidget);
      final visibility_slider = tester.widget<CupertinoSlider>(
        find.byKey(const Key('personal-event-level-slider')),
      );
      expect(visibility_slider.min, 1);
      expect(visibility_slider.max, 5);
      expect(visibility_slider.value, 1);
      expect(find.byKey(const ValueKey('event-visibility-0')), findsNothing);
      measurements[scenario.name] = {
        ...measurements[scenario.name] as Map<String, Object>,
        'visibility_min': visibility_slider.min,
        'visibility_max': visibility_slider.max,
        'visibility_default': visibility_slider.value,
      };
      if (scenario.name == 'normal' || visibility_output != null) {
        await capture('visibility');
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
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
