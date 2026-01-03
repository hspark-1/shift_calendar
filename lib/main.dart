import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/profile_setup_page.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 카카오 SDK 초기화
  final kakaoKey = AppConstants.kakao_native_app_key;
  assert(
    kakaoKey.isNotEmpty,
    'KAKAO_NATIVE_APP_KEY가 설정되지 않았습니다.\n'
    '실행 방법: flutter run --dart-define=KAKAO_NATIVE_APP_KEY=실제키값\n'
    '또는 ios/Flutter/Secrets.xcconfig, android/secrets.properties 파일에 키를 설정하세요.',
  );
  KakaoSdk.init(nativeAppKey: kakaoKey);

  // 한국어 로케일 데이터 초기화
  await initializeDateFormatting('ko_KR', null);

  runApp(const ProviderScope(child: ShiftCalendarApp()));
}

/// 메인 앱 위젯
class ShiftCalendarApp extends StatelessWidget {
  const ShiftCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Shift Calendar',
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

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // 앱 시작 시 인증 상태 확인
    Future.microtask(() {
      ref.read(authProvider.notifier).checkAuthStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    switch (authState.status) {
      case AuthStatus.initial:
        // 로딩 중
        return const _SplashScreen();

      case AuthStatus.authenticated:
        // 인증됨
        if (authState.is_new_user && authState.user != null) {
          // 신규 가입자: 프로필 설정 페이지
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
      backgroundColor: const Color(0xFFF8F9FA),
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
                    color: AppTheme.primary_color.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
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
            const Text(
              'Shift Calendar',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.label,
              ),
            ),
            const SizedBox(height: 40),
            const CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }
}
