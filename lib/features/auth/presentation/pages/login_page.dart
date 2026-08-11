// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../providers/auth_provider.dart';
import 'profile_setup_page.dart';

/// 소셜 로그인 페이지
class LoginPage extends ConsumerStatefulWidget {
  final bool apple_login_enabled;

  const LoginPage({
    super.key,
    this.apple_login_enabled = AppConstants.apple_login_enabled,
  });

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  bool _is_loading = false;

  Future<void> _handleKakaoLogin() async {
    if (_is_loading) return;

    setState(() {
      _is_loading = true;
    });

    final success = await ref.read(authProvider.notifier).loginWithKakao();

    if (!mounted) return;

    setState(() {
      _is_loading = false;
    });

    if (success) {
      final authState = ref.read(authProvider);

      if (authState.is_new_user) {
        // 신규 가입: 추가 정보 입력 페이지로
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => ProfileSetupPage(user: authState.user!),
          ),
        );
      } else {
        // 기존 회원: 메인 페이지로
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const CalendarPage()),
        );
      }
    } else {
      // 에러 표시
      final error = ref.read(authProvider).error;
      if (error != null) {
        _showErrorDialog(error);
      }
    }
  }

  Future<void> _handleNaverLogin() async {
    if (_is_loading) return;

    setState(() {
      _is_loading = true;
    });

    final success = await ref.read(authProvider.notifier).loginWithNaver();

    if (!mounted) return;

    setState(() {
      _is_loading = false;
    });

    if (success) {
      final authState = ref.read(authProvider);

      if (authState.is_new_user) {
        // 신규 가입: 추가 정보 입력 페이지로
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => ProfileSetupPage(user: authState.user!),
          ),
        );
      } else {
        // 기존 회원: 메인 페이지로
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const CalendarPage()),
        );
      }
    } else {
      // 에러 표시
      final error = ref.read(authProvider).error;
      if (error != null) {
        _showErrorDialog(error);
      }
    }
  }

  Future<void> _handleGoogleLogin() async {
    if (_is_loading) return;

    setState(() {
      _is_loading = true;
    });

    final success = await ref.read(authProvider.notifier).loginWithGoogle();

    if (!mounted) return;

    setState(() {
      _is_loading = false;
    });

    if (success) {
      final authState = ref.read(authProvider);

      if (authState.is_new_user) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => ProfileSetupPage(user: authState.user!),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const CalendarPage()),
        );
      }
    } else {
      // 사용자 취소는 error가 null이므로 별도 실패 다이얼로그를 표시하지 않는다.
      final error = ref.read(authProvider).error;
      if (error != null) {
        _showErrorDialog(error);
      }
    }
  }

  Future<void> _handleAppleLogin() async {
    if (_is_loading) return;

    setState(() {
      _is_loading = true;
    });

    final success = await ref.read(authProvider.notifier).loginWithApple();

    if (!mounted) return;

    setState(() {
      _is_loading = false;
    });

    if (success) {
      final authState = ref.read(authProvider);

      if (authState.is_new_user) {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(
            builder: (context) => ProfileSetupPage(user: authState.user!),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          CupertinoPageRoute(builder: (context) => const CalendarPage()),
        );
      }
    } else {
      // 사용자 취소는 error가 null이므로 별도 실패 다이얼로그를 표시하지 않는다.
      final error = ref.read(authProvider).error;
      if (error != null) {
        _showErrorDialog(error);
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('로그인 실패'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 앱 로고 및 타이틀
              _buildHeader(),
              const Spacer(flex: 2),
              // 소셜 로그인 버튼
              _buildSocialLoginButtons(),
              const SizedBox(height: 12),
              SizedBox(
                height: 20,
                child: _is_loading
                    ? const CupertinoActivityIndicator(radius: 9)
                    : null,
              ),
              const SizedBox(height: 8),
              // 이용약관 안내
              _buildTermsText(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 앱 아이콘
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary_color.withValues(alpha: 0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/icons/app_icon.png',
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 24),
        // 앱 이름
        const Text(AppConstants.app_name, style: AppTheme.heading_large),
        const SizedBox(height: 8),
        // 설명
        Text(
          '교대 근무 일정을 쉽게 관리하고\n친구들과 공유하세요',
          textAlign: TextAlign.center,
          style: AppTheme.body_large.copyWith(
            color: AppTheme.on_surface_variant_color,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialLoginButtons() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 20,
      runSpacing: 12,
      children: [
        _buildSocialLoginButton(
          button_key: const Key('kakao_login_button'),
          asset_path: 'assets/icons/kakao.png',
          semantics_label: '카카오 로그인',
          on_pressed: _handleKakaoLogin,
        ),
        _buildSocialLoginButton(
          button_key: const Key('naver_login_button'),
          asset_path: 'assets/icons/naver.png',
          semantics_label: '네이버 로그인',
          on_pressed: _handleNaverLogin,
        ),
        _buildSocialLoginButton(
          button_key: const Key('google_login_button'),
          asset_path: 'assets/icons/google.png',
          semantics_label: 'Google 로그인',
          on_pressed: _handleGoogleLogin,
        ),
        if (widget.apple_login_enabled) ...[
          _buildSocialLoginButton(
            button_key: const Key('apple_login_button'),
            asset_path: 'assets/icons/apple.png',
            semantics_label: 'Apple 로그인',
            on_pressed: _handleAppleLogin,
          ),
        ],
      ],
    );
  }

  Widget _buildSocialLoginButton({
    required Key button_key,
    required String asset_path,
    required String semantics_label,
    required VoidCallback on_pressed,
  }) {
    const button_size = 64.0;

    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      enabled: !_is_loading,
      label: semantics_label,
      child: CupertinoButton(
        key: button_key,
        padding: EdgeInsets.zero,
        minimumSize: const Size(button_size, button_size),
        pressedOpacity: 0.7,
        onPressed: _is_loading ? null : on_pressed,
        child: AnimatedOpacity(
          opacity: _is_loading ? 0.45 : 1,
          duration: const Duration(milliseconds: 150),
          child: ClipOval(
            child: Image.asset(
              asset_path,
              width: button_size,
              height: button_size,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTermsText() {
    return Text(
      '로그인 시 이용약관 및 개인정보처리방침에 동의합니다.',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 12,
        color: CupertinoColors.systemGrey.resolveFrom(context),
      ),
    );
  }
}
