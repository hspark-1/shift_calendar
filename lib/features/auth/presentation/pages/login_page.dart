import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../providers/auth_provider.dart';
import 'profile_setup_page.dart';

/// 카카오 로그인 페이지
class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

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
      backgroundColor: const Color(0xFFF8F9FA),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 앱 로고 및 타이틀
              _buildHeader(),
              const Spacer(flex: 2),
              // 카카오 로그인 버튼
              _buildKakaoLoginButton(),
              const SizedBox(height: 16),
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
                color: AppTheme.primary_color.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
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
        const Text(
          'Shift Calendar',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        // 설명
        Text(
          '교대 근무 일정을 쉽게 관리하고\n친구들과 공유하세요',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: CupertinoColors.systemGrey.resolveFrom(context),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildKakaoLoginButton() {
    return GestureDetector(
      onTap: _is_loading ? null : _handleKakaoLogin,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: const Color(0xFFFEE500),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFEE500).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _is_loading
            ? const Center(
                child: CupertinoActivityIndicator(color: Color(0xFF191919)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 카카오 아이콘
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFF191919),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'K',
                        style: TextStyle(
                          color: Color(0xFFFEE500),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    '카카오 로그인',
                    style: TextStyle(
                      color: Color(0xFF191919),
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
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
