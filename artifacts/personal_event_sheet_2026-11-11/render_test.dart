// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/navigation/app_navigation.dart';
import 'package:shift_mate/core/navigation/main_tab_page.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import '../design_update_2026-11-10/render_update_test.dart' as fixtures;

class _SheetCalendarService extends fixtures.AuditCalendarService {
  @override
  Future<EventApiModel> createEvent(CreateEventRequest request) async {
    throw StateError('render-only save failure');
  }
}

void main() {
  testWidgets('개인 일정 재설계의 화면·글자·키보드와 입력 접근을 검증한다', (tester) async {
    await initializeDateFormatting('ko_KR');
    final output = Directory('artifacts/personal_event_sheet_2026-11-11');
    output.createSync(recursive: true);
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
    final measurements = <String, Object>{};
    for (final scenario in [
      (name: 'normal', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (name: 'private', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (name: 'details', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (name: 'all_day', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (
        name: 'save_error',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'small', size: const Size(320, 568), scale: 1.0, keyboard: 0.0),
      (
        name: 'small_details',
        size: const Size(320, 568),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'phone375', size: const Size(375, 812), scale: 1.0, keyboard: 0.0),
      (
        name: 'large_text',
        size: const Size(390, 844),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'large_text_details',
        size: const Size(390, 844),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'small_large_details',
        size: const Size(320, 568),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'keyboard_title',
        size: const Size(320, 568),
        scale: 1.0,
        keyboard: 240.0,
      ),
      (
        name: 'keyboard_memo',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 300.0,
      ),
      (
        name: 'landscape',
        size: const Size(844, 390),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'tablet', size: const Size(768, 1024), scale: 1.0, keyboard: 0.0),
      (
        name: 'visibility',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (
        name: 'visibility_large',
        size: const Size(320, 568),
        scale: 2.0,
        keyboard: 0.0,
      ),
    ]) {
      await tester.binding.setSurfaceSize(scenario.size);
      // 렌더 전용 모의 저장소를 사용해 실제 캘린더 진입 흐름을 재현한다.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            fixtures.AuditAuthRepository(),
          ),
          calendarServiceProvider.overrideWithValue(_SheetCalendarService()),
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
      final keyboard_inset = ValueNotifier<double>(0);
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture_key,
          child: UncontrolledProviderScope(
            container: container,
            child: CupertinoApp(
              debugShowCheckedModeBanner: false,
              navigatorObservers: [rootNavigationObserver],
              theme: AppTheme.lightTheme,
              builder: (context, child) => ValueListenableBuilder<double>(
                valueListenable: keyboard_inset,
                builder: (context, inset, _) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: scenario.size,
                    padding: const EdgeInsets.only(top: 47, bottom: 34),
                    viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
                    textScaler: TextScaler.linear(scenario.scale),
                    viewInsets: EdgeInsets.only(bottom: inset),
                    disableAnimations: true,
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
      final add_event = find.text('일정 추가하기...');
      await tester.ensureVisible(add_event);
      await tester.pumpAndSettle();
      await tester.tap(add_event);
      await tester.pumpAndSettle();
      keyboard_inset.value = scenario.keyboard;
      await tester.pumpAndSettle();
      final sheet_rect = tester.getRect(
        find.byKey(const Key('personal-event-sheet')),
      );
      expect(sheet_rect.top, greaterThanOrEqualTo(59));
      expect(
        sheet_rect.bottom,
        closeTo(scenario.size.height - scenario.keyboard, 1),
      );
      final save = find.byKey(const Key('personal-event-save-button'));
      final save_before = tester.getRect(save);
      expect(save.hitTestable(), findsOneWidget);
      expect(save_before.height, greaterThanOrEqualTo(52));
      expect(
        save_before.bottom,
        lessThanOrEqualTo(scenario.size.height - scenario.keyboard - 34),
      );
      Rect? focused_rect;
      if (scenario.name.contains('details') ||
          scenario.name == 'keyboard_memo') {
        final details = find.byKey(const Key('personal-event-details-toggle'));
        await tester.ensureVisible(details);
        await tester.pumpAndSettle();
        await tester.tap(details);
        await tester.pumpAndSettle();
        final memo = find.byKey(const Key('personal-event-memo-field'));
        await tester.ensureVisible(memo);
        await tester.pumpAndSettle();
        expect(memo.hitTestable(), findsOneWidget);
        if (scenario.keyboard > 0) {
          await tester.tap(memo);
          await tester.pumpAndSettle();
        }
        focused_rect = tester.getRect(memo);
        expect(focused_rect.bottom, lessThanOrEqualTo(save_before.top));
        expect(tester.getRect(save), save_before);
      }
      if (scenario.name == 'keyboard_title') {
        final title = find.byKey(const Key('personal-event-title-field'));
        await tester.tap(title);
        await tester.pumpAndSettle();
        focused_rect = tester.getRect(title);
        expect(focused_rect.bottom, lessThanOrEqualTo(save_before.top));
      }
      if (scenario.name == 'all_day') {
        await tester.tap(find.byKey(const Key('personal-event-all-day')));
        await tester.pumpAndSettle();
      }
      if (scenario.name == 'save_error') {
        await tester.enterText(
          find.byKey(const Key('personal-event-title-field')),
          '친구와 저녁 약속',
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('다시 저장'), findsOneWidget);
        expect(save.hitTestable(), findsOneWidget);
      }
      if (scenario.name == 'private') {
        final mode = find.byKey(const Key('event-visibility-private'));
        await tester.ensureVisible(mode);
        await tester.pumpAndSettle();
        await tester.tap(mode);
        await tester.pumpAndSettle();
        expect(find.text('나만 보기'), findsOneWidget);
      }
      if (scenario.name.startsWith('visibility')) {
        final slider = find.byKey(const Key('personal-event-level-slider'));
        await tester.ensureVisible(slider);
        await tester.pumpAndSettle();
        tester.widget<CupertinoSlider>(slider).onChanged!(3);
        await tester.pumpAndSettle();
        expect(tester.widget<CupertinoSlider>(slider).value, 3);
      }
      final errors = <String>[];
      Object? error;
      while ((error = tester.takeException()) != null) {
        errors.add(error.toString());
      }
      measurements[scenario.name] = {
        'size': '${scenario.size.width}x${scenario.size.height}',
        'scale': scenario.scale,
        'keyboard_inset': scenario.keyboard,
        'sheet_top': sheet_rect.top,
        'sheet_height': sheet_rect.height,
        'sheet_bottom': sheet_rect.bottom,
        'save_height': save_before.height,
        'save_top': save_before.top,
        'save_bottom': save_before.bottom,
        if (focused_rect != null) 'focused_field_bottom': focused_rect.bottom,
        'framework_errors': errors,
      };
      final boundary =
          capture_key.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      boundary.markNeedsPaint();
      await tester.pump();
      await tester.runAsync(() async {
        final capture = await boundary.toImage(pixelRatio: 2);
        final raw = await capture.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        final button_rect = tester.getRect(save);
        var label_pixels = 0;
        for (
          var y = (button_rect.center.dy * 2 - 12).round();
          y < button_rect.center.dy * 2 + 12;
          y++
        ) {
          for (
            var x = (button_rect.center.dx * 2 - 60).round();
            x < button_rect.center.dx * 2 + 60;
            x++
          ) {
            final offset = (y * capture.width + x) * 4;
            if (raw!.getUint8(offset) > 230 &&
                raw.getUint8(offset + 1) > 230 &&
                raw.getUint8(offset + 2) > 230) {
              label_pixels++;
            }
          }
        }
        expect(
          label_pixels,
          greaterThan(20),
          reason: '${scenario.name} 저장 라벨이 이미지에 그려져야 한다',
        );
        final bytes = await capture.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/${scenario.name}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        capture.dispose();
      });
      expect(errors, isEmpty, reason: scenario.name);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      keyboard_inset.dispose();
      container.dispose();
    }
    await tester.binding.setSurfaceSize(null);
    await tester.runAsync(() async {
      await File(
        '${output.path}/measurements.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(measurements));
    });
  });
}
