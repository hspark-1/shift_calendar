import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

/// 설정 페이지
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool _is_logging_out = false;

  /// 로그아웃 확인 다이얼로그 표시
  void _showLogoutConfirmDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: false,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }

  /// 로그아웃 처리
  Future<void> _handleLogout() async {
    setState(() {
      _is_logging_out = true;
    });

    await ref.read(authProvider.notifier).logout();

    if (!mounted) return;

    setState(() {
      _is_logging_out = false;
    });

    // 로그아웃 후 네비게이션 스택 초기화하고 로그인 페이지로 이동
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      CupertinoPageRoute(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(middle: Text('설정')),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // 프로필 섹션
            if (user != null) _buildProfileSection(user),
            const SizedBox(height: 32),
            // 계정 섹션
            _buildAccountSection(),
          ],
        ),
      ),
    );
  }

  /// 프로필 섹션
  Widget _buildProfileSection(User user) {
    return CupertinoListSection.insetGrouped(
      header: const Text('프로필'),
      children: [
        CupertinoListTile(
          leading: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.systemGrey5,
              image: user.profile_image_url != null
                  ? DecorationImage(
                      image: NetworkImage(user.profile_image_url!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.profile_image_url == null
                ? const Icon(
                    CupertinoIcons.person_fill,
                    size: 28,
                    color: CupertinoColors.systemGrey,
                  )
                : null,
          ),
          title: Text(
            user.name,
            style: AppTheme.body_large.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            user.email,
            style: AppTheme.body_small.copyWith(
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      ],
    );
  }

  /// 계정 섹션
  Widget _buildAccountSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('계정'),
      children: [
        CupertinoListTile(
          leading: const Icon(
            CupertinoIcons.arrow_right_square,
            color: CupertinoColors.systemRed,
          ),
          title: Text(
            '로그아웃',
            style: AppTheme.body_large.copyWith(
              color: CupertinoColors.systemRed,
            ),
          ),
          trailing: _is_logging_out
              ? const CupertinoActivityIndicator()
              : const CupertinoListTileChevron(),
          onTap: _is_logging_out ? null : _showLogoutConfirmDialog,
        ),
      ],
    );
  }
}
