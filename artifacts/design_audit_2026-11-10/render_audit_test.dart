// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/presentation/pages/login_page.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:shift_mate/features/auth/presentation/pages/settings_page.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/bottom_action_bar.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/personal_event_form_modal.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_color_picker_page.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_type_form_modal.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/data/models/notification_model.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_detail_page.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_list_page.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/widgets/notification_item.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';
import 'package:shift_mate/features/group/presentation/pages/group_create_page.dart';
import 'package:shift_mate/features/group/presentation/pages/group_edit_page.dart';

const audit_user = User(
  id: 'audit-user',
  email: 'sample@example.com',
  name: '샘플 사용자',
  phone: '010-1234-5678',
  timezone: 'Asia/Seoul',
  requires_profile_setup: false,
);
final audit_friend = FriendModel(
  userId: 'audit-friend',
  name: '샘플 친구',
  email: 'friend@example.com',
  friendLevel: 2,
  canView: true,
  createdAt: DateTime(2026, 11, 10),
);
final audit_group = GroupDetail(
  group_id: 'audit-group',
  name: '함께 보는 근무표',
  timezone: 'Asia/Seoul',
  my_role: GroupRole.owner,
  member_count: 1,
  members: const [],
  created_by_user_id: 'audit-user',
  created_at: DateTime(2026, 11, 10),
  updated_at: DateTime(2026, 11, 10),
);

class AuditAuthRepository implements AuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<User> getProfile() async => audit_user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class AuditFriendNotifier extends FriendListNotifier {
  AuditFriendNotifier() : super(FriendService(Dio())) {
    state = FriendListState(friends: [audit_friend]);
  }
  @override
  Future<void> loadFriends({int page = 1, int limit = 20}) async {}
}

class AuditGroupRepository implements GroupRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final output_dir = Directory('artifacts/design_audit_2026-11-10');
  final measurements = <String, dynamic>{};
  setUpAll(() async {
    output_dir.createSync(recursive: true);
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
  setUp(() {
    // 테스트 전용 렌더러를 캡처 산출물 옆에 보관한다.
    // ignore: invalid_use_of_visible_for_testing_member
    SharedPreferences.setMockInitialValues({
      'shift_custom_recent_colors_v1': ['FF9500', 'E85F80', '4355B8'],
    });
  });

  Future<void> renderPage(
    WidgetTester tester,
    String name,
    Widget page, {
    Size size = const Size(390, 844),
    double text_scale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(AuditAuthRepository()),
        friendListProvider.overrideWith((ref) => AuditFriendNotifier()),
        groupRepositoryProvider.overrideWithValue(AuditGroupRepository()),
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
                padding: const EdgeInsets.only(top: 47, bottom: 34),
                textScaler: TextScaler.linear(text_scale),
              ),
              child: child!,
            ),
            home: page,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      for (final image in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(image.image, capture_key.currentContext!);
      }
    });
    await tester.pumpAndSettle();
    final errors = <String>[];
    Object? error;
    while ((error = tester.takeException()) != null) {
      errors.add(error.toString());
    }
    final boundary =
        capture_key.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File(
        '${output_dir.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    measurements[name] = {
      'size': '${size.width}x${size.height}',
      'text_scale': text_scale,
      'framework_errors': errors,
    };
    if (page is ShiftCustomColorPickerPage) {
      final recent = find.text('최근 사용한 색상');
      measurements[name]['recent_label_built'] = recent.evaluate().isNotEmpty;
      if (recent.evaluate().isNotEmpty) {
        measurements[name]['recent_label_rect'] = tester
            .getRect(recent)
            .toString();
      }
      final scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      measurements[name]['scroll_extent'] = scrollable.position.maxScrollExtent;
      final before = scrollable.position.pixels;
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      measurements[name]['scroll_pixels_after_drag'] =
          scrollable.position.pixels;
      measurements[name]['scroll_pixels_before_drag'] = before;
    }
    if (name == 'shift_type_form') {
      measurements[name]['color_button_size'] = tester
          .getSize(find.byKey(const Key('shift_type_color_button')))
          .toString();
      measurements[name]['time_label_font_size'] = tester
          .widget<Text>(find.text('근무 시간'))
          .style
          ?.fontSize;
    }
    if (name == 'settings') {
      measurements[name]['real_switch_count'] = find
          .byType(CupertinoSwitch)
          .evaluate()
          .length;
      final bio = find.text('로그인 생체 인증');
      measurements[name]['biometric_label_font_size'] = tester
          .widget<Text>(bio)
          .style
          ?.fontSize;
    }
    if (name == 'notification_card') {
      final buttons = find.byType(CupertinoButton);
      measurements[name]['button_sizes'] = [
        for (final element in buttons.evaluate())
          (element.renderObject as RenderBox).size.toString(),
      ];
    }
    if (name == 'bottom_bar') {
      measurements[name]['gesture_sizes'] = [
        for (final element in find.byType(GestureDetector).evaluate())
          (element.renderObject as RenderBox).size.toString(),
      ];
    }
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    container.dispose();
    await tester.binding.setSurfaceSize(null);
  }

  testWidgets('주요 화면 시각 검토와 컨트롤 크기 측정', (tester) async {
    await renderPage(
      tester,
      'login',
      const LoginPage(apple_login_enabled: true),
    );
    await renderPage(tester, 'settings', const SettingsPage());
    await renderPage(
      tester,
      'profile_edit',
      const ProfileSetupPage.edit(user: audit_user),
    );
    await renderPage(
      tester,
      'color_picker',
      const ShiftColorPickerPage(initial_color: Color(0xFF0061A4)),
    );
    await renderPage(
      tester,
      'custom_color',
      const ShiftCustomColorPickerPage(initial_color: Color(0xFF0061A4)),
    );
    await renderPage(
      tester,
      'custom_color_small',
      const ShiftCustomColorPickerPage(initial_color: Color(0xFF0061A4)),
      size: const Size(320, 568),
    );
    await renderPage(
      tester,
      'custom_color_text2',
      const ShiftCustomColorPickerPage(initial_color: Color(0xFF0061A4)),
      text_scale: 2,
    );
    await renderPage(
      tester,
      'friend_detail',
      FriendDetailPage(friend: audit_friend),
    );
    await renderPage(tester, 'friend_list', const FriendListPage());
    await renderPage(tester, 'group_create', const GroupCreatePage());
    await renderPage(tester, 'group_edit', GroupEditPage(group: audit_group));
    await renderPage(
      tester,
      'shift_type_form',
      const ShiftTypeFormModal(existingTypes: []),
    );
    await renderPage(
      tester,
      'personal_event_form',
      PersonalEventFormModal(initialDate: DateTime(2026, 11, 10)),
    );
    await renderPage(
      tester,
      'bottom_bar',
      CupertinoPageScaffold(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: BottomActionBar(
            onFriendTap: () {},
            onCalendarTap: () {},
            onNotificationTap: () {},
          ),
        ),
      ),
    );
    await renderPage(
      tester,
      'notification_card',
      CupertinoPageScaffold(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                child: NotificationItem(
                  notification: NotificationModel(
                    notificationId: 'audit-notification',
                    notificationType: NotificationType.friendRequest,
                    title: '친구 요청',
                    body: '샘플 친구님이 친구 요청을 보냈습니다.',
                    payload: NotificationPayload(rawData: const {}),
                    isRead: false,
                    createdAt: DateTime(2026, 11, 10),
                    actions: [
                      NotificationAction(
                        type: NotificationActionType.reject,
                        label: '거절',
                      ),
                      NotificationAction(
                        type: NotificationActionType.accept,
                        label: '수락',
                      ),
                    ],
                  ),
                  onActionTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await File(
        '${output_dir.path}/measurements.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(measurements));
    });
    debugPrint(const JsonEncoder.withIndent('  ').convert(measurements));
    expect(measurements, hasLength(15));
  });
}
