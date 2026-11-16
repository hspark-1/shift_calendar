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

import '../design_update_2026-11-10/render_update_test.dart' as fixtures;
import '../personal_event_edit_2026-11-12/render_test.dart' as edit;

void main() {
  testWidgets('실제 메인 탭에서 삭제 토스트의 가독성·안전영역·되돌리기를 렌더한다', (tester) async {
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
    final output = Directory('artifacts/calendar_delete_undo_2026-11-12')
      ..createSync(recursive: true);
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
      await tester.drag(row, const Offset(-700, 0));
      await tester.pumpAndSettle();
      final toast = find.byKey(const ValueKey('calendar-delete-toast'));
      final button = find.byKey(const ValueKey('calendar-delete-undo'));
      final tab_bar = find.byKey(const ValueKey('main-glass-tab-bar'));
      expect(toast, findsOneWidget);
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
        'exceptions': 0,
      };
      await tester.runAsync(() async {
        final boundary =
            capture_key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final picture = await boundary.toImage(pixelRatio: 2);
        final bytes = await picture.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/${scenario.name}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        picture.dispose();
      });
      await tester.tap(button);
      await tester.pumpAndSettle();
      expect(row, findsOneWidget);
      expect(toast, findsNothing);
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
