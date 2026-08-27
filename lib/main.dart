// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';
import 'package:timezone/data/latest.dart' as timezone_data;

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/korean_holidays.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/profile_setup_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';
import 'features/friend/presentation/pages/notification_page.dart';
import 'core/push/push_coordinator.dart';
import 'core/push/push_providers.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // .env 파일 로드
  await dotenv.load(fileName: '.env');

  // 카카오 SDK 초기화
  final kakao_key = AppConstants.kakao_native_app_key;
  if (kakao_key.isEmpty) {
    final kakao_key_define_name = AppConstants.kakao_native_app_key_define_name;
    throw StateError(
      '$kakao_key_define_name가 Dart define에 설정되지 않았습니다.\n'
      '실행 방법: flutter run --dart-define-from-file=.env\n'
      'Debug(Stage)는 KAKAO_NATIVE_APP_KEY_STAGE, Profile/Release는 '
      'KAKAO_NATIVE_APP_KEY를 사용합니다. 네이티브 URL Scheme을 위해 '
      'ios/Flutter/Secrets.xcconfig와 android/secrets.properties에도 '
      '환경별 키가 별도로 필요합니다.',
    );
  }
  KakaoSdk.init(nativeAppKey: kakao_key);

  // 한국어 로케일 데이터 초기화
  await initializeDateFormatting('ko_KR', null);

  // 그룹 캘린더 이벤트를 서버의 IANA timezone 기준 날짜로 배치한다.
  timezone_data.initializeTimeZones();

  // 이전 실행에서 저장한 공휴일을 모든 캘린더가 즉시 사용할 수 있게 복원
  await KoreanHolidays.initialize();

  final firebase_enabled = await initializePushFirebase();
  if (firebase_enabled) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  runApp(
    ProviderScope(
      overrides: [
        pushFirebaseEnabledProvider.overrideWithValue(firebase_enabled),
      ],
      child: const ShiftMateApp(),
    ),
  );
}

/// 메인 앱 위젯
class ShiftMateApp extends StatelessWidget {
  const ShiftMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      navigatorKey: rootNavigatorKey,
      title: AppConstants.app_name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

/// 인증 상태에 따른 화면 분기 위젯
class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 앱 시작 시 인증 상태 확인
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(pushCoordinatorProvider).onAppResumed();
    }
  }

  void _openPendingNotificationIfReady(AuthState auth_state) {
    if (auth_state.status != AuthStatus.authenticated ||
        auth_state.requires_profile_setup ||
        !ref.read(pendingPushNotificationNavigationProvider)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || rootNavigatorKey.currentState == null) return;
      ref.read(pendingPushNotificationNavigationProvider.notifier).state =
          false;
      rootNavigatorKey.currentState!.push(
        CupertinoPageRoute<void>(builder: (_) => const NotificationPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (previous, next) {
      final coordinator = ref.read(pushCoordinatorProvider);
      if (next.status == AuthStatus.authenticated &&
          previous?.status != AuthStatus.authenticated) {
        coordinator.startAuthenticated();
      } else if (next.status == AuthStatus.unauthenticated &&
          previous?.status == AuthStatus.authenticated) {
        ref.read(pendingPushNotificationNavigationProvider.notifier).state =
            false;
        coordinator.stopAuthenticated();
      }
      _openPendingNotificationIfReady(next);
    });
    ref.listen<bool>(pendingPushNotificationNavigationProvider, (_, next) {
      if (next) _openPendingNotificationIfReady(ref.read(authProvider));
    });

    switch (authState.status) {
      case AuthStatus.initial:
        // 로딩 중
        return const _SplashScreen();

      case AuthStatus.authenticated:
        // 인증됨
        if (authState.requires_profile_setup && authState.user != null) {
          // 서버가 가입 프로필 미완료로 판정한 사용자
          return ProfileSetupPage(user: authState.user!);
        }
        // 기존 회원: 캘린더 페이지
        return const CalendarPage();

      case AuthStatus.unauthenticated:
        // 인증 안됨: 로그인 페이지
        return const LoginPage();
    }
  }
}

/// 스플래시 화면
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 앱 아이콘
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primary_color,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary_color.withValues(alpha: 0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.calendar,
                size: 50,
                color: CupertinoColors.white,
              ),
            ),
            const SizedBox(height: 24),
            const Text(AppConstants.app_name, style: AppTheme.heading_medium),
            const SizedBox(height: 40),
            const CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }
}
