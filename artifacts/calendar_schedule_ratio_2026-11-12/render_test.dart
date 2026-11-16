// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

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
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:table_calendar/table_calendar.dart';

import '../design_update_2026-11-10/render_update_test.dart' as fixtures;
import '../personal_event_edit_2026-11-12/render_test.dart' as edit;

void main() {
  testWidgets('실제 메인 탭의 남은 일정 공간과 작은 화면 경계를 렌더한다', (tester) async {
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
    final output = Directory('artifacts/calendar_remaining_space_2026-11-12')
      ..createSync(recursive: true);
    final measurements = <String, Object>{};
    for (final scenario in [
      (name: 'small320', size: const Size(320, 568), scale: 1.0),
      (name: 'boundary750', size: const Size(390, 750), scale: 1.0),
      (name: 'phone375', size: const Size(375, 812), scale: 1.0),
      (name: 'normal', size: const Size(390, 844), scale: 1.0),
      (name: 'large430', size: const Size(430, 932), scale: 1.0),
      (name: 'tablet', size: const Size(768, 1024), scale: 1.0),
      (name: 'landscape', size: const Size(844, 390), scale: 1.0),
      (name: 'large_text', size: const Size(320, 568), scale: 2.0),
    ]) {
      await tester.binding.setSurfaceSize(scenario.size);
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            fixtures.AuditAuthRepository(),
          ),
          calendarServiceProvider.overrideWithValue(edit.EditRenderService()),
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
              theme: AppTheme.lightTheme,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: scenario.size,
                  padding: const EdgeInsets.only(top: 47, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
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
      expect(tester.takeException(), isNull, reason: scenario.name);
      final body = find.byKey(const ValueKey('main-calendar-layout'));
      final card = find.byKey(const ValueKey('calendar-schedule-card'));
      final tab = find.byKey(const ValueKey('main-glass-tab-bar'));
      final fallback = find
          .byKey(const ValueKey('main-calendar-scroll'))
          .evaluate()
          .isNotEmpty;
      final ratio = tester.getSize(card).height / tester.getSize(body).height;
      expect(
        fallback,
        scenario.name == 'landscape' || scenario.name == 'large_text',
      );
      if (!fallback) {
        final calendar_scroll = find.byKey(
          const ValueKey('main-calendar-grid-scroll'),
        );
        expect(
          tester.getRect(card).top,
          tester.getRect(calendar_scroll).bottom + AppTheme.spacing_xs,
        );
        expect(
          tester.getRect(body).bottom - tester.getRect(card).bottom,
          AppTheme.spacing_md,
        );
        expect(tester.getRect(card).bottom, lessThan(tester.getRect(tab).top));
        expect(find.text('일정 추가하기...').hitTestable(), findsOneWidget);
      } else {
        await tester.ensureVisible(find.text('일정 추가하기...'));
        await tester.pumpAndSettle();
        expect(find.text('일정 추가하기...').hitTestable(), findsOneWidget);
      }
      measurements[scenario.name] = {
        'width': scenario.size.width,
        'height': scenario.size.height,
        'text_scale': scenario.scale,
        'body_height': tester.getSize(body).height,
        'card_height': tester.getSize(card).height,
        'card_fraction': ratio,
        'card_bottom': tester.getRect(card).bottom,
        'full_scroll_fallback': fallback,
        'tab_top': tester.getRect(tab).top,
        'exceptions': 0,
      };
      await _capture(
        tester,
        capture_key,
        '${output.path}/${scenario.name}.png',
      );
      if (scenario.name == 'boundary750') {
        final calendar = find.byKey(const ValueKey('main-calendar'));
        for (
          var step = 0;
          step < 12 &&
              tester.widget<TableCalendar>(calendar).focusedDay.month != 8;
          step++
        ) {
          await tester.tap(find.byIcon(CupertinoIcons.chevron_left));
          await tester.pumpAndSettle();
        }
        expect(tester.widget<TableCalendar>(calendar).focusedDay.month, 8);
        expect(
          tester.widget<TableCalendar>(calendar).calendarFormat,
          CalendarFormat.month,
        );
        final card_rect = tester.getRect(card);
        expect(card_rect.bottom, lessThan(tester.getRect(tab).top));
        await _capture(tester, capture_key, '${output.path}/six_weeks.png');
        final grid_scroll = find
            .descendant(
              of: find.byKey(const ValueKey('main-calendar-grid-scroll')),
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is Scrollable &&
                    widget.axisDirection == AxisDirection.down,
              ),
            )
            .first;
        final position = tester.state<ScrollableState>(grid_scroll).position;
        expect(position.maxScrollExtent, greaterThan(0));
        expect(card_rect.height, 144);
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(tester.getRect(card), card_rect);
        await _capture(
          tester,
          capture_key,
          '${output.path}/six_weeks_scrolled.png',
        );
        position.jumpTo(0);
        await tester.pumpAndSettle();
      }
      if (!fallback) {
        final card_rect = tester.getRect(card);
        final calendar_rect = tester.getRect(
          find.byKey(const ValueKey('main-calendar')),
        );
        final list = find.descendant(
          of: card,
          matching: find.byType(SingleChildScrollView),
        );
        await tester.drag(list, const Offset(0, -100));
        await tester.pumpAndSettle();
        if (scenario.name == 'small320') {
          final list_scroll = find
              .descendant(
                of: list,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is Scrollable &&
                      widget.axisDirection == AxisDirection.down,
                ),
              )
              .first;
          expect(
            tester.state<ScrollableState>(list_scroll).position.pixels,
            greaterThan(0),
          );
        }
        expect(tester.getRect(card), card_rect);
        expect(
          tester.getRect(find.byKey(const ValueKey('main-calendar'))),
          calendar_rect,
        );
        await tester.tap(find.byIcon(CupertinoIcons.add));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byKey(const ValueKey('shift-add-card'))),
          card_rect,
        );
        expect(find.text('완료').hitTestable(), findsOneWidget);
        await _capture(
          tester,
          capture_key,
          '${output.path}/${scenario.name}_shift.png',
        );
      }
      expect(tester.takeException(), isNull, reason: scenario.name);
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

Future<void> _capture(
  WidgetTester tester,
  GlobalKey capture_key,
  String path,
) async {
  await tester.runAsync(() async {
    final boundary =
        capture_key.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    final picture = await boundary.toImage(pixelRatio: 2);
    final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    picture.dispose();
  });
}
