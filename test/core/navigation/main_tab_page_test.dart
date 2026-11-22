// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:shift_mate/main.dart' as app_main;
import 'package:shift_mate/features/auth/presentation/pages/login_page.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shift_mate/core/constants/app_constants.dart';
import 'package:shift_mate/features/friend/data/models/notification_model.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_calendar_page.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_list_page.dart';
import 'package:shift_mate/features/friend/presentation/pages/notification_page.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';
import 'package:shift_mate/features/group/presentation/pages/group_calendar_page.dart';
import 'package:shift_mate/core/navigation/app_navigation.dart';
import 'package:shift_mate/core/navigation/main_tab_page.dart';
import 'package:shift_mate/core/push/push_providers.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/data/services/calendar_service.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/data/services/notification_service.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:shift_mate/features/friend/presentation/widgets/add_friend_modal.dart';

class _AuthRepository implements AuthRepository {
  @override
  Future<bool> isLoggedIn() async => true;
  @override
  Future<User> getProfile() async => const User(
    id: 'tab-user',
    email: 'test@example.com',
    name: '테스트',
    phone: '01012345678',
    requires_profile_setup: false,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LoginRepository extends _AuthRepository {
  bool logged_in = false;
  User user = const User(
    id: 'first',
    email: 'test@example.com',
    name: '테스트',
    phone: '01012345678',
    requires_profile_setup: false,
  );
  @override
  Future<bool> isLoggedIn() async => logged_in;
  @override
  Future<User> getProfile() async => user;
  @override
  Future<AuthResponse> loginWithGoogle() async {
    logged_in = true;
    return AuthResponse(
      user: user,
      access_token: 'test-token',
      refresh_token: 'test-refresh',
      expires_at: DateTime(2030),
      requires_profile_setup: user.requires_profile_setup ?? false,
    );
  }

  @override
  Future<void> logout() async {
    logged_in = false;
  }
}

class _CalendarService extends CalendarService {
  _CalendarService() : super(Dio());
  @override
  Future<CalendarRangeResponse> getCalendarRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async => CalendarRangeResponse(
    success: true,
    data: CalendarRangeData(workShifts: [], events: []),
  );
}

class _FriendService extends FriendService {
  _FriendService() : super(Dio());

  @override
  Future<SearchUserResponse> searchUser(String query) async =>
      SearchUserResponse(
        success: true,
        user: SearchUserModel(
          userId: 'requester-1',
          name: '요청한 친구',
          email: query,
          isFriend: false,
          hasPendingRequest: true,
          pendingRequestDirection: 'received',
        ),
      );

  @override
  Future<CalendarRangeResponse> getFriendCalendarRange({
    required String friendUserId,
    required DateTime startDate,
    required DateTime endDate,
  }) async => CalendarRangeResponse(
    success: true,
    data: CalendarRangeData(workShifts: [], events: []),
  );
}

class _GroupRepository implements GroupRepository {
  @override
  Future<PaginatedGroups> getGroups({int page = 1, int limit = 20}) async => (
    groups: [
      GroupSummary(
        group_id: 'group-1',
        name: '초대 그룹',
        timezone: 'Asia/Seoul',
        my_role: GroupRole.member,
        member_count: 0,
        members_preview: const [],
        created_at: DateTime(2026),
        updated_at: DateTime(2026),
      ),
    ],
    pagination: const GroupPagination(
      page: 1,
      limit: 20,
      total: 1,
      total_pages: 1,
    ),
  );

  @override
  Future<PaginatedGroupInvitations> getReceivedInvitations({
    GroupInvitationStatus? status,
    int page = 1,
    int limit = 20,
  }) async => (
    invitations: [
      GroupInvitation(
        invitation_id: 'invitation-1',
        group: const GroupInvitationGroup(
          group_id: 'group-1',
          name: '초대 그룹',
          member_count: 1,
        ),
        inviter: const GroupUserSummary(user_id: 'inviter', name: '초대자'),
        invitee_user_id: 'tab-user',
        status: GroupInvitationStatus.pending,
        expires_at: DateTime(2030),
        created_at: DateTime(2026),
      ),
    ],
    pagination: const GroupPagination(
      page: 1,
      limit: 20,
      total: 1,
      total_pages: 1,
    ),
  );

  @override
  Future<GroupDetail> getGroupDetail(String group_id) async => GroupDetail(
    group_id: group_id,
    name: '초대 그룹',
    timezone: 'Asia/Seoul',
    my_role: GroupRole.member,
    member_count: 0,
    members: const [],
    created_by_user_id: 'owner',
    created_at: DateTime(2026),
    updated_at: DateTime(2026),
  );

  @override
  Future<GroupCalendarRange> getGroupCalendarRange({
    required String group_id,
    required DateTime start_date,
    required DateTime end_date,
  }) async => GroupCalendarRange(
    group: GroupCalendarHeader(
      group_id: group_id,
      name: '초대 그룹',
      timezone: 'Asia/Seoul',
    ),
    start_date: start_date.toIso8601String(),
    end_date: end_date.toIso8601String(),
    members: const [],
    work_shifts: const [],
    events: const [],
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FriendNotifier extends FriendListNotifier {
  _FriendNotifier({bool with_friends = false}) : super(FriendService(Dio())) {
    if (with_friends) {
      state = FriendListState(
        friends: [
          FriendModel(
            userId: 'friend-1',
            name: '친구',
            email: 'friend@example.com',
            friendLevel: 1,
            canView: true,
            createdAt: DateTime.utc(2026, 11, 12),
          ),
        ],
      );
    }
  }
  @override
  Future<void> loadFriends({int page = 1, int limit = 20}) async {}
}

class _NotificationNotifier extends NotificationNotifier {
  _NotificationNotifier({List<NotificationModel> notifications = const []})
    : super(NotificationService(Dio()), FriendService(Dio())) {
    state = NotificationState(notifications: notifications);
  }
  void setNotification(NotificationModel notification) {
    state = state.copyWith(notifications: [notification]);
  }

  Completer<bool>? response;
  @override
  Future<bool> handleNotificationAction({
    required NotificationModel notification,
    required NotificationAction action,
  }) async => response == null ? true : await response!.future;
  int load_count = 0;
  @override
  Future<void> fetchUnreadCount() async {}
  @override
  Future<void> loadNotifications({int page = 1, int limit = 20}) async {
    load_count++;
  }
}

Future<
  ({
    ProviderContainer container,
    GlobalKey<NavigatorState> root_key,
    _NotificationNotifier notifications,
  })
>
_pumpTabs(
  WidgetTester tester, {
  bool pending = false,
  Size screen_size = const Size(390, 844),
  bool reduce_motion = false,
  bool dark_mode = false,
  bool high_contrast = false,
  double text_scale = 1,
  bool with_friends = false,
  EdgeInsets safe_padding = EdgeInsets.zero,
  List<NotificationModel> initial_notifications = const [],
}) async {
  await tester.binding.setSurfaceSize(screen_size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final notifications = _NotificationNotifier(
    notifications: initial_notifications,
  );
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      calendarServiceProvider.overrideWithValue(_CalendarService()),
      friendServiceProvider.overrideWithValue(_FriendService()),
      groupRepositoryProvider.overrideWithValue(_GroupRepository()),
      shiftTypesProvider.overrideWith((ref) async => []),
      friendListProvider.overrideWith(
        (ref) => _FriendNotifier(with_friends: with_friends),
      ),
      notificationProvider.overrideWith((ref) => notifications),
    ],
  );
  addTearDown(container.dispose);
  await container.read(authProvider.notifier).checkAuthStatus();
  container.read(pendingPushNotificationNavigationProvider.notifier).state =
      pending;
  final root_key = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: CupertinoApp(
        navigatorKey: root_key,
        navigatorObservers: [rootNavigationObserver],
        theme: dark_mode ? AppTheme.darkTheme : AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: screen_size,
            padding: safe_padding,
            viewPadding: safe_padding,
            highContrast: high_contrast,
            disableAnimations: reduce_motion,
            textScaler: TextScaler.linear(text_scale),
          ),
          child: RepaintBoundary(
            key: const ValueKey('main-tabs-capture'),
            child: child!,
          ),
        ),
        home: const MainTabPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (
    container: container,
    root_key: root_key,
    notifications: notifications,
  );
}

Future<void> _expectContinuousTabBackground(
  WidgetTester tester,
  Rect bar_rect,
  Rect page_rect,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('main-tabs-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final pixels = (await image.toByteData())!;
      // 같은 세로 전환 음영이 바 위와 홈 인디케이터 영역까지 이어져야 한다.
      final sample_x = (page_rect.left - 6).floor();
      final upper_pixel =
          ((bar_rect.top - 24).floor() * image.width + sample_x) * 4;
      final lower_pixel = ((image.height - 2) * image.width + sample_x) * 4;
      for (var channel = 0; channel < 3; channel++) {
        expect(
          pixels.getUint8(lower_pixel + channel),
          closeTo(pixels.getUint8(upper_pixel + channel), 2),
        );
      }
    } finally {
      image.dispose();
    }
  });
}

Future<void> _captureTabFrame(WidgetTester tester, String name) async {
  final output_path = Platform.environment['NAV_RENDER_OUTPUT'];
  if (output_path == null) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('main-tabs-capture')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final output_dir = Directory(output_path);
      await output_dir.create(recursive: true);
      await File(
        '${output_dir.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
    } finally {
      image.dispose();
    }
  });
}

Color _tabIconColor(WidgetTester tester, int index) {
  return tester
      .widget<Icon>(
        find.descendant(
          of: find.byKey(ValueKey('main-tab-$index')),
          matching: find.byType(Icon),
        ),
      )
      .color!;
}

NotificationModel _notification({
  NotificationActionType action = NotificationActionType.navigate,
  bool group = false,
  String friend_id = 'friend-1',
}) => NotificationModel(
  notificationId: 'notification-1',
  notificationType: group && action == NotificationActionType.accept
      ? NotificationType.groupInvitation
      : NotificationType.friendRequest,
  title: '경로 테스트',
  body: '바로가기',
  payload: NotificationPayload.fromJson({
    'related_user_id': friend_id,
    'request_id': 'request-1',
    if (group) ...{
      'group_id': 'group-1',
      'invitation_id': 'invitation-1',
      'invitation_status': 'PENDING',
    },
  }),
  actions: [
    NotificationAction(
      type: action,
      label: switch (action) {
        NotificationActionType.accept => '수락',
        NotificationActionType.reject => '거절',
        _ => '친구 목록 보기',
      },
      route: '/friends',
    ),
    if (group && action == NotificationActionType.accept)
      NotificationAction(type: NotificationActionType.reject, label: '거절'),
  ],
  isRead: true,
  createdAt: DateTime(2026, 11, 12),
);

void _expectFriendTabSelected(WidgetTester tester) {
  final semantics = tester.widget<Semantics>(
    find
        .ancestor(
          of: find.byKey(const ValueKey('main-tab-1')),
          matching: find.byType(Semantics),
        )
        .first,
  );
  expect(semantics.properties.selected, isTrue);
}

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: '');
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
    SharedPreferences.setMockInitialValues({});
  });

  for (final screen_size in [
    const Size(375, 667),
    const Size(844, 390),
    const Size(768, 1024),
  ]) {
    testWidgets('하단 선택 배경과 색상은 연속 탭에서도 현재 위치부터 부드럽게 전환한다: $screen_size', (
      tester,
    ) async {
      await _pumpTabs(
        tester,
        screen_size: screen_size,
        dark_mode: screen_size.width == 768,
        text_scale: screen_size.width == 768 ? 2 : 1,
        with_friends: true,
      );
      final indicator = find.byKey(const ValueKey('main-tab-indicator'));
      final bar = find.byKey(const ValueKey('main-glass-tab-bar'));
      final tab_rects = List.generate(
        3,
        (index) => tester.getRect(find.byKey(ValueKey('main-tab-$index'))),
      );
      final bar_rect = tester.getRect(bar);
      final selected_color = _tabIconColor(tester, 0);
      final unselected_color = _tabIconColor(tester, 1);
      final initial_rect = tester.getRect(indicator);
      expect(initial_rect.center.dx, closeTo(tab_rects[0].center.dx, 0.01));
      expect(initial_rect.width, closeTo(tab_rects[0].width, 0.01));
      expect(tab_rects[0].height, greaterThanOrEqualTo(44));

      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pump();
      expect(tester.getRect(indicator), initial_rect);
      await tester.pump(const Duration(milliseconds: 70));
      final moving_x = tester.getCenter(indicator).dx;
      expect(moving_x, greaterThan(tab_rects[0].center.dx));
      expect(moving_x, lessThan(tab_rects[1].center.dx));
      final progress = Curves.easeOutCubic.transform(70 / 280);
      expect(
        _tabIconColor(tester, 0),
        Color.lerp(selected_color, unselected_color, progress),
      );
      expect(
        _tabIconColor(tester, 1),
        Color.lerp(unselected_color, selected_color, progress),
      );

      await tester.tap(find.byKey(const ValueKey('main-tab-2')));
      await tester.pump();
      expect(tester.getCenter(indicator).dx, closeTo(moving_x, 0.01));
      await tester.pump(const Duration(milliseconds: 70));
      expect(tester.getCenter(indicator).dx, greaterThan(moving_x));
      await tester.pumpAndSettle();
      expect(
        tester.getCenter(indicator).dx,
        closeTo(tab_rects[2].center.dx, 0.01),
      );
      expect(_tabIconColor(tester, 2), selected_color);
      expect(_tabIconColor(tester, 0), unselected_color);

      await tester.tap(find.byKey(const ValueKey('main-tab-0')));
      await tester.pumpAndSettle();
      expect(tester.getRect(indicator), initial_rect);
      expect(tester.getRect(bar), bar_rect);
      for (var index = 0; index < 3; index++) {
        expect(
          tester.getRect(find.byKey(ValueKey('main-tab-$index'))),
          tab_rects[index],
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final scenario in [
    (
      size: const Size(375, 667),
      scale: 1.0,
      dark: false,
      contrast: false,
      reduced: false,
      safe: const EdgeInsets.only(top: 47, bottom: 34),
    ),
    (
      size: const Size(844, 390),
      scale: 1.0,
      dark: false,
      contrast: false,
      reduced: false,
      safe: const EdgeInsets.only(bottom: 21),
    ),
    (
      size: const Size(768, 1024),
      scale: 2.0,
      dark: true,
      contrast: false,
      reduced: false,
      safe: const EdgeInsets.only(top: 24, bottom: 20),
    ),
    (
      size: const Size(768, 1240),
      scale: 3.2,
      dark: false,
      contrast: true,
      reduced: true,
      safe: const EdgeInsets.only(top: 47, bottom: 34),
    ),
  ]) {
    testWidgets('친구 뒤로가기 전환은 하단 탭 뒤까지 전체 화면을 사용한다: ${scenario.size}', (
      tester,
    ) async {
      final screen_size = scenario.size;
      await _pumpTabs(
        tester,
        screen_size: screen_size,
        with_friends: true,
        safe_padding: scenario.safe,
        text_scale: scenario.scale,
        dark_mode: scenario.dark,
        high_contrast: scenario.contrast,
        reduce_motion: scenario.reduced,
      );
      final bar = find.byKey(const ValueKey('main-glass-tab-bar'));
      final bar_rect = tester.getRect(bar);
      final main_body = tester.getRect(
        find.byKey(const ValueKey('main-calendar-layout')),
      );
      expect(main_body.bottom, closeTo(bar_rect.top, 0.01));
      expect(screen_size.height - bar_rect.bottom, scenario.safe.bottom);
      await _captureTabFrame(
        tester,
        'calendar-${screen_size.width.toInt()}-${screen_size.height.toInt()}',
      );
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('friend@example.com'));
      await tester.pumpAndSettle();
      final page = find.byType(FriendCalendarPage);
      final navigator = find
          .ancestor(of: page, matching: find.byType(Navigator))
          .first;
      expect(tester.getRect(navigator).bottom, screen_size.height);
      expect(tester.getRect(page).bottom, screen_size.height);
      expect(
        tester
            .getRect(find.byKey(const ValueKey('friend-calendar-layout')))
            .bottom,
        closeTo(bar_rect.top, 0.01),
      );
      await _captureTabFrame(
        tester,
        'friend-${screen_size.width.toInt()}-${screen_size.height.toInt()}',
      );
      final gesture_origin = Offset(1, screen_size.height * 0.7);
      final drag_distance = screen_size.width * 0.4;
      final gesture = await tester.startGesture(gesture_origin);
      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      await gesture.moveBy(Offset(drag_distance - 20, 0));
      await tester.pump();
      expect(tester.getTopLeft(page).dx, greaterThan(0));
      expect(tester.getRect(page).bottom, screen_size.height);
      expect(tester.getRect(bar), bar_rect);
      await _captureTabFrame(
        tester,
        'swipe-${screen_size.width.toInt()}-${screen_size.height.toInt()}',
      );
      await _expectContinuousTabBackground(
        tester,
        bar_rect,
        tester.getRect(page),
      );
      await gesture.moveBy(Offset(-drag_distance, 0));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(find.byType(FriendCalendarPage), findsOneWidget);
      await tester.dragFrom(
        gesture_origin,
        Offset(screen_size.width * 0.95, 0),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FriendCalendarPage), findsNothing);
      expect(find.byType(FriendListPage), findsOneWidget);
      expect(tester.getRect(bar), bar_rect);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('동작 줄이기에서는 하단 선택 배경과 아이콘 색상이 즉시 확정된다', (tester) async {
    await _pumpTabs(tester, reduce_motion: true);
    final indicator = find.byKey(const ValueKey('main-tab-indicator'));
    final selected_color = _tabIconColor(tester, 0);
    for (final index in [2, 1, 0]) {
      final tab = find.byKey(ValueKey('main-tab-$index'));
      await tester.tap(tab);
      await tester.pump();
      expect(
        tester.getCenter(indicator).dx,
        closeTo(tester.getCenter(tab).dx, 0.01),
      );
      expect(_tabIconColor(tester, index), selected_color);
      await tester.pumpAndSettle();
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('탭 이동과 재선택은 달을 보존하고 오늘 버튼만 오늘로 이동한다', (tester) async {
    final fixture = await _pumpTabs(tester);
    final calendar = find.byKey(const ValueKey('main-calendar'));
    final today = DateTime.now();
    final target = DateTime(today.year, today.month - 1, 12);
    tester.widget<TableCalendar>(calendar).onDaySelected!(target, target);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-room-footer-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main-tab-2')));
    await tester.pumpAndSettle();
    expect(fixture.notifications.load_count, 1);
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    expect(
      find.text(AppConstants.group_api_enabled ? '초대 그룹' : '우리 병동'),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('main-tab-0')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main-tab-0')));
    await tester.pumpAndSettle();
    expect(
      isSameDay(tester.widget<TableCalendar>(calendar).focusedDay, target),
      isTrue,
    );
    expect(
      tester.widget<TableCalendar>(calendar).selectedDayPredicate!(target),
      isTrue,
    );
    await tester.tap(find.byKey(const ValueKey('calendar-today-button')));
    await tester.pumpAndSettle();
    expect(
      isSameDay(tester.widget<TableCalendar>(calendar).focusedDay, today),
      isTrue,
    );
    expect(fixture.root_key.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 보류된 푸시는 알림 탭을 열고 루트 페이지를 중복 생성하지 않는다', (tester) async {
    final fixture = await _pumpTabs(tester, pending: true);
    expect(find.text('알림이 없습니다'), findsOneWidget);
    expect(fixture.notifications.load_count, 1);
    expect(
      fixture.container.read(pendingPushNotificationNavigationProvider),
      isFalse,
    );
    expect(fixture.root_key.currentState!.canPop(), isFalse);
  });

  testWidgets('친구 추가의 받은 요청 확인은 시트를 닫고 기존 알림 탭으로 이동한다', (tester) async {
    final fixture = await _pumpTabs(tester, with_friends: true);
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-friend-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('add-friend-search-input')),
      'requester@example.com',
    );
    await tester.tap(find.byKey(const ValueKey('add-friend-search-button')));
    await tester.pumpAndSettle();
    final action = find.byKey(
      const ValueKey('add-friend-received-request-button'),
    );
    await tester.ensureVisible(action);
    await tester.tap(action);
    await tester.pumpAndSettle();
    expect(find.byType(AddFriendModal), findsNothing);
    expect(find.byType(NotificationPage), findsOneWidget);
    expect(fixture.notifications.load_count, 1);
    expect(fixture.root_key.currentState!.canPop(), isFalse);
    final selected = tester.widget<Semantics>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('main-tab-2')),
            matching: find.byType(Semantics),
          )
          .first,
    );
    expect(selected.properties.selected, isTrue);
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    expect(find.byType(FriendListPage), findsOneWidget);
    expect(fixture.root_key.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('폼이 열려 있으면 푸시 이동을 보류하고 닫힌 뒤 알림 탭을 연다', (tester) async {
    final fixture = await _pumpTabs(tester);
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    fixture.root_key.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (_) => CupertinoPageScaffold(
          navigationBar: const CupertinoNavigationBar(middle: Text('편집')),
          child: Center(child: CupertinoTextField(controller: controller)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(CupertinoTextField), '보존할 입력');
    fixture.container
            .read(pendingPushNotificationNavigationProvider.notifier)
            .state =
        true;
    await tester.pumpAndSettle();
    expect(controller.text, '보존할 입력');
    expect(fixture.notifications.load_count, 0);
    expect(
      fixture.container.read(pendingPushNotificationNavigationProvider),
      isTrue,
    );
    fixture.root_key.currentState!.pop();
    await tester.pumpAndSettle();
    expect(find.text('알림이 없습니다'), findsOneWidget);
    expect(fixture.notifications.load_count, 1);
    expect(
      fixture.container.read(pendingPushNotificationNavigationProvider),
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('탭 내부 상세 화면은 뒤로가기로 같은 그룹 목록에 복귀한다', (tester) async {
    final fixture = await _pumpTabs(tester);
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('group-room-footer-button')));
    await tester.pumpAndSettle();
    final group_card = find.byKey(
      ValueKey(
        AppConstants.group_api_enabled
            ? 'group-room-card-group-1'
            : 'group-room-preview-card',
      ),
    );
    await tester.tap(group_card);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('main-tab-1')), findsOneWidget);
    expect(fixture.root_key.currentState!.canPop(), isFalse);
    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pumpAndSettle();
    expect(group_card, findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(375, 667), const Size(768, 1024)]) {
    testWidgets('하단 재선택은 친구 상세에서 홈으로 복귀하고 목록끼리 전환한다: $size', (tester) async {
      final fixture = await _pumpTabs(
        tester,
        with_friends: true,
        screen_size: size,
        reduce_motion: size.width == 768,
        dark_mode: size.width == 768,
      );
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('friend@example.com'));
      await tester.pumpAndSettle();
      final calendar = find.byKey(const ValueKey('friend-calendar'));
      final target = DateTime(2026, 10, 12);
      tester.widget<TableCalendar>(calendar).onDaySelected!(target, target);
      await tester.pumpAndSettle();
      final calendar_state = tester.state(find.byType(FriendCalendarPage));
      await tester.tap(find.byKey(const ValueKey('main-tab-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(FriendCalendarPage)),
        same(calendar_state),
      );
      expect(
        tester.widget<TableCalendar>(calendar).selectedDayPredicate!(target),
        isTrue,
      );
      await tester.tap(find.byIcon(CupertinoIcons.gear));
      await tester.pumpAndSettle();
      expect(find.text('친구 정보'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      expect(find.byType(FriendCalendarPage), findsNothing);
      expect(find.byType(FriendListPage), findsOneWidget);
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('friend-group-page-view')),
            )
            .controller!
            .page,
        0,
      );
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      expect(find.text('그룹 방'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('add-friend-button')), findsOneWidget);
      expect(fixture.root_key.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('하단 재선택은 가로 화면·동작 줄이기에서도 친구와 그룹을 즉시 전환한다', (tester) async {
    await _pumpTabs(
      tester,
      with_friends: true,
      screen_size: const Size(844, 390),
      reduce_motion: true,
      dark_mode: true,
    );
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pump();
    expect(
      tester
          .widget<PageView>(
            find.byKey(const ValueKey('friend-group-page-view')),
          )
          .controller!
          .page,
      1,
    );
    await tester.tap(find.byKey(const ValueKey('main-tab-1')));
    await tester.pump();
    expect(
      tester
          .widget<PageView>(
            find.byKey(const ValueKey('friend-group-page-view')),
          )
          .controller!
          .page,
      0,
    );
    expect(tester.takeException(), isNull);
  });

  for (final visited in [false, true]) {
    testWidgets('알림 친구 목록 경로는 기존 상세·그룹 선택을 정리한다: visited=$visited', (
      tester,
    ) async {
      final fixture = await _pumpTabs(
        tester,
        with_friends: true,
        initial_notifications: [_notification()],
      );
      if (visited) {
        await tester.tap(find.byKey(const ValueKey('main-tab-1')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('friend@example.com'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const ValueKey('main-tab-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('친구 목록 보기'));
      await tester.pumpAndSettle();
      _expectFriendTabSelected(tester);
      expect(find.byType(FriendListPage), findsOneWidget);
      expect(find.byType(FriendCalendarPage), findsNothing);
      expect(find.byType(CupertinoNavigationBarBackButton), findsNothing);
      // 목록에서 그룹을 선택한 뒤 같은 바로가기를 눌러도 친구 목록이 목적지다.
      await tester.tap(find.byKey(const ValueKey('main-tab-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('main-tab-2')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('친구 목록 보기'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('add-friend-button')), findsOneWidget);
      expect(fixture.root_key.currentState!.canPop(), isFalse);
      expect(tester.takeException(), isNull);
    });
  }

  for (final group in [false, true]) {
    for (final action in [
      NotificationActionType.accept,
      NotificationActionType.navigate,
    ]) {
      if (!group && action == NotificationActionType.navigate) continue;
      if (group &&
          action == NotificationActionType.accept &&
          !AppConstants.group_api_enabled) {
        continue;
      }
      testWidgets(
        '알림 수락·바로가기 경로는 친구 탭 목록 아래에 상세를 연결한다: group=$group action=$action',
        (tester) async {
          final fixture = await _pumpTabs(
            tester,
            with_friends: true,
            initial_notifications: [
              _notification(group: group, action: action),
            ],
          );
          // 친구 수락은 첫 방문, 그룹 이동은 기존 친구 상세가 있는 탭을 사용한다.
          if (group) {
            await tester.tap(find.byKey(const ValueKey('main-tab-1')));
            await tester.pumpAndSettle();
            await tester.tap(find.text('friend@example.com'));
            await tester.pumpAndSettle();
          }
          await tester.tap(find.byKey(const ValueKey('main-tab-2')));
          await tester.pumpAndSettle();
          await tester.tap(
            find.text(
              action == NotificationActionType.accept ? '수락' : '친구 목록 보기',
            ),
          );
          await tester.pumpAndSettle();
          _expectFriendTabSelected(tester);
          expect(
            group
                ? find.byType(GroupCalendarPage)
                : find.byType(FriendCalendarPage),
            findsOneWidget,
          );
          expect(fixture.root_key.currentState!.canPop(), isFalse);
          await tester.tap(
            group && action == NotificationActionType.accept
                ? find.byKey(const ValueKey('main-tab-1'))
                : find.byType(CupertinoNavigationBarBackButton),
          );
          await tester.pumpAndSettle();
          expect(find.byType(FriendListPage), findsOneWidget);
          expect(find.byType(CupertinoNavigationBarBackButton), findsNothing);
          expect(
            tester
                .widget<PageView>(
                  find.byKey(const ValueKey('friend-group-page-view')),
                )
                .controller!
                .page,
            group ? 1 : 0,
          );
          await tester.tap(find.byKey(const ValueKey('main-tab-2')));
          await tester.pumpAndSettle();
          expect(find.byType(NotificationPage), findsOneWidget);
          expect(find.byType(CupertinoNavigationBarBackButton), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }

  testWidgets('알림 수락 실패·친구 누락·거절은 목적지로 이동하지 않는다', (tester) async {
    final fixture = await _pumpTabs(
      tester,
      initial_notifications: [
        _notification(action: NotificationActionType.accept),
      ],
    );
    fixture.notifications.response = Completer<bool>();
    await tester.tap(find.byKey(const ValueKey('main-tab-2')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('수락'));
    await tester.pump();
    fixture.notifications.response!.complete(false);
    await tester.pumpAndSettle();
    expect(find.text('오류'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    fixture.notifications.response = null;
    await tester.tap(find.text('수락'));
    await tester.pumpAndSettle();
    expect(find.text('친구 정보를 불러오지 못했습니다.'), findsOneWidget);
    expect(find.byType(FriendCalendarPage), findsNothing);
    expect(find.byType(NotificationPage), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    final item = fixture.notifications;
    // 거절은 성공하더라도 기존 알림 탭에 머문다.
    item.setNotification(_notification(action: NotificationActionType.reject));
    await tester.pumpAndSettle();
    await tester.tap(find.text('거절'));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('로그인·가입 상태 변경·로그아웃은 인증 게이트와 한 개 탭 컨테이너를 유지한다', (tester) async {
    final repository = _LoginRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        calendarServiceProvider.overrideWithValue(_CalendarService()),
        friendServiceProvider.overrideWithValue(_FriendService()),
        groupRepositoryProvider.overrideWithValue(_GroupRepository()),
        shiftTypesProvider.overrideWith((ref) async => []),
        friendListProvider.overrideWith((ref) => _FriendNotifier()),
        notificationProvider.overrideWith((ref) => _NotificationNotifier()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: CupertinoApp(
          navigatorKey: app_main.rootNavigatorKey,
          navigatorObservers: [rootNavigationObserver],
          theme: AppTheme.lightTheme,
          home: const app_main.AuthWrapper(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    await tester.tap(find.byKey(const Key('google_login_button')));
    await tester.pumpAndSettle();
    expect(find.byType(MainTabPage), findsOneWidget);
    expect(find.byType(app_main.AuthWrapper), findsOneWidget);
    expect(app_main.rootNavigatorKey.currentState!.canPop(), isFalse);
    app_main.rootNavigatorKey.currentState!.push(
      CupertinoPageRoute<void>(
        builder: (_) => const CupertinoPageScaffold(child: Text('열린 설정')),
      ),
    );
    await tester.pumpAndSettle();
    await container.read(authProvider.notifier).logout();
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(find.byType(MainTabPage), findsNothing);
    expect(find.text('열린 설정'), findsNothing);
    repository.user = repository.user.copyWith(
      id: 'second',
      requires_profile_setup: true,
    );
    await tester.tap(find.byKey(const Key('google_login_button')));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSetupPage), findsOneWidget);
    expect(find.byType(MainTabPage), findsNothing);
    repository.user = repository.user.copyWith(requires_profile_setup: false);
    await container.read(authProvider.notifier).checkAuthStatus();
    await tester.pumpAndSettle();
    expect(find.byType(MainTabPage), findsOneWidget);
    expect(find.byType(ProfileSetupPage), findsNothing);
    expect(app_main.rootNavigatorKey.currentState!.canPop(), isFalse);
    expect(tester.takeException(), isNull);
  });
}
