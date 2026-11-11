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
import 'package:shift_mate/core/navigation/app_navigation.dart';
import 'package:shift_mate/core/navigation/main_tab_page.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';

import '../design_update_2026-11-10/render_update_test.dart' as fixtures;

class _Notifications extends fixtures.AuditNotificationNotifier {
  _Notifications() {
    state = state.copyWith(unreadCount: 123);
  }
}

void main() {
  final output_dir = Directory('artifacts/glass_navigation_2026-11-11');
  final measurements = <String, Object?>{};

  setUpAll(() async {
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
  });

  Future<void> capture(
    WidgetTester tester,
    String name, {
    Size size = const Size(390, 844),
    double text_scale = 1,
    bool high_contrast = false,
    bool reduced_motion = false,
    bool dark = false,
    int tab = 0,
    bool settings = false,
    bool profile = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    // 산출물 옆에 두는 테스트 전용 렌더러의 로컬 저장소를 격리한다.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          fixtures.AuditAuthRepository(),
        ),
        calendarServiceProvider.overrideWithValue(
          fixtures.AuditCalendarService(),
        ),
        shiftTypesProvider.overrideWith((ref) async => []),
        friendListProvider.overrideWith(
          (ref) => fixtures.AuditFriendNotifier(),
        ),
        notificationProvider.overrideWith((ref) => _Notifications()),
        groupRepositoryProvider.overrideWithValue(
          fixtures.AuditGroupRepository(),
        ),
      ],
    );
    await container.read(authProvider.notifier).checkAuthStatus();
    final capture_key = GlobalKey();
    final root_key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      RepaintBoundary(
        key: capture_key,
        child: UncontrolledProviderScope(
          container: container,
          child: CupertinoApp(
            navigatorKey: root_key,
            navigatorObservers: [rootNavigationObserver],
            theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
            debugShowCheckedModeBanner: false,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: size,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
                textScaler: TextScaler.linear(text_scale),
                highContrast: high_contrast,
                disableAnimations: reduced_motion,
              ),
              child: child!,
            ),
            home: const MainTabPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    if (tab != 0) {
      await tester.tap(find.byKey(ValueKey('main-tab-$tab')));
      await tester.pumpAndSettle();
    }
    if (settings) {
      await tester.tap(find.byIcon(CupertinoIcons.gear));
      await tester.pumpAndSettle();
    }
    if (profile) {
      root_key.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) =>
              const ProfileSetupPage.edit(user: fixtures.audit_user),
        ),
      );
      await tester.pumpAndSettle();
    }
    final scroll = find.byKey(const ValueKey('main-calendar-scroll'));
    if (scroll.evaluate().isNotEmpty && !settings && !profile) {
      await tester.drag(scroll, const Offset(0, -1800));
      await tester.pumpAndSettle();
    }
    final bar = find.byKey(const ValueKey('main-glass-tab-bar'));
    final result = <String, Object?>{
      'size': '${size.width}x${size.height}',
      'text_scale': text_scale,
      'high_contrast': high_contrast,
      'reduced_motion': reduced_motion,
      'dark_navigation_only': dark,
    };
    if (!settings && !profile) {
      final bar_rect = tester.getRect(bar);
      expect(bar_rect.width, lessThanOrEqualTo(AppTheme.navigation_max_width));
      expect(size.height - bar_rect.bottom, greaterThanOrEqualTo(42));
      result['bar_rect'] = bar_rect.toString();
      final badge = find.text('99+');
      if (badge.evaluate().isNotEmpty) {
        final badge_rect = tester.getRect(badge);
        expect(badge_rect.right, lessThanOrEqualTo(bar_rect.right - 12));
        expect(badge_rect.top, greaterThanOrEqualTo(bar_rect.top));
        result['badge_rect'] = badge_rect.toString();
      }
      for (var index = 0; index < 3; index++) {
        final target = tester.getRect(find.byKey(ValueKey('main-tab-$index')));
        expect(target.width, greaterThanOrEqualTo(44));
        expect(target.height, greaterThanOrEqualTo(44));
      }
      if (tab == 0) {
        final card_rect = tester.getRect(
          find.byKey(const ValueKey('calendar-schedule-card')),
        );
        final gap = bar_rect.top - card_rect.bottom;
        result['card_to_bar_gap'] = gap;
        expect(gap, closeTo(16, 0.01));
      }
    } else {
      expect(bar, findsNothing);
      expect(find.byType(CupertinoNavigationBar), findsOneWidget);
    }
    final errors = <String>[];
    Object? error;
    while ((error = tester.takeException()) != null) {
      errors.add(error.toString());
    }
    result['framework_errors'] = errors;
    expect(errors, isEmpty);
    final boundary =
        capture_key.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    await tester.runAsync(() async {
      output_dir.createSync(recursive: true);
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '${output_dir.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    measurements[name] = result;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    container.dispose();
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('글라스 내비게이션 렌더와 안전영역 확인', (tester) async {
    await capture(tester, 'calendar');
    await capture(tester, 'friend', tab: 1);
    await capture(tester, 'notifications', tab: 2);
    await capture(tester, 'small375', size: const Size(375, 812));
    await capture(tester, 'small320', size: const Size(320, 568));
    await capture(tester, 'text2', size: const Size(320, 568), text_scale: 2);
    await capture(tester, 'landscape', size: const Size(844, 390));
    await capture(tester, 'high_contrast', high_contrast: true);
    await capture(tester, 'reduced_motion', reduced_motion: true, tab: 1);
    await capture(tester, 'dark_navigation', dark: true);
    await capture(tester, 'settings', settings: true);
    await capture(tester, 'profile', profile: true);
    await tester.runAsync(() async {
      await File(
        '${output_dir.path}/measurements.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(measurements));
    });
  });
}
