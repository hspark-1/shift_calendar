// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:shift_mate/main.dart' as app_main;
import 'package:shift_mate/features/auth/presentation/pages/login_page.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:table_calendar/table_calendar.dart';
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
import 'package:shift_mate/features/friend/data/services/notification_service.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';

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

class _FriendNotifier extends FriendListNotifier {
  _FriendNotifier() : super(FriendService(Dio()));
  @override
  Future<void> loadFriends({int page = 1, int limit = 20}) async {}
}

class _NotificationNotifier extends NotificationNotifier {
  _NotificationNotifier()
    : super(NotificationService(Dio()), FriendService(Dio()));
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
_pumpTabs(WidgetTester tester, {bool pending = false}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final notifications = _NotificationNotifier();
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(_AuthRepository()),
      calendarServiceProvider.overrideWithValue(_CalendarService()),
      shiftTypesProvider.overrideWith((ref) async => []),
      friendListProvider.overrideWith((ref) => _FriendNotifier()),
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
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(size: const Size(390, 844)),
          child: child!,
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

void main() {
  setUpAll(() async {
    dotenv.testLoad(fileInput: '');
    await initializeDateFormatting('ko_KR');
  });
  setUp(() {
    SharedPreferences.setMockInitialValues({});
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
    expect(find.text('우리 병동'), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('group-room-preview-card')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('main-tab-1')), findsOneWidget);
    expect(fixture.root_key.currentState!.canPop(), isFalse);
    await tester.tap(find.byType(CupertinoNavigationBarBackButton));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('group-room-preview-card')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('로그인·가입 상태 변경·로그아웃은 인증 게이트와 한 개 탭 컨테이너를 유지한다', (tester) async {
    final repository = _LoginRepository();
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        calendarServiceProvider.overrideWithValue(_CalendarService()),
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
