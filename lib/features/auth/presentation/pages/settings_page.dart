// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/user.dart';
import '../../../calendar/presentation/pages/shift_template_settings_page.dart';
import '../providers/auth_provider.dart';
import 'login_page.dart';

/// 설정 페이지
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  static const double _settings_scale = 0.8;
  static const Color _primary_fixed_color = Color(0xFFD1E4FF);
  static const Color _error_container_color = Color(0xFFFFDAD6);
  static const Color _on_error_container_color = Color(0xFF93000A);
  static const Color _settings_section_border_color = Color(0x660061A4);
  static const Color _switch_off_color = Color(0xFFCCCCCC);

  bool _is_logging_out = false;
  bool _is_deleting_account = false;

  bool get _is_processing => _is_logging_out || _is_deleting_account;

  static double _scaled(double value) {
    return value * _settings_scale;
  }

  TextStyle _scaledTextStyle(
    TextStyle style, {
    required double fontSize,
    Color? color,
    FontWeight? fontWeight,
  }) {
    return style.copyWith(
      color: color,
      fontSize: _scaled(fontSize),
      fontWeight: fontWeight,
    );
  }

  void _showFeatureUnavailableAlert(String feature_name) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialog_context) => CupertinoAlertDialog(
        title: const Text('준비 중인 기능'),
        content: Text('$feature_name 기능은 아직 개발되지 않았습니다.'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialog_context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  /// 로그아웃 확인 다이얼로그 표시
  void _showLogoutConfirmDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialog_context) => CupertinoAlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialog_context).pop(),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialog_context).pop();
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
    _navigateToLogin();
  }

  void _navigateToLogin() {
    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      CupertinoPageRoute<void>(builder: (context) => const LoginPage()),
      (route) => false,
    );
  }

  void _showDeleteAccountConfirmDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialog_context) => CupertinoAlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text(
          '회원 탈퇴 시 일정, 근무표, 친구 관계 및 그룹 정보가 '
          '삭제됩니다.\n삭제된 데이터는 복구할 수 없습니다.\n\n'
          '정말 탈퇴하시겠습니까?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialog_context).pop(),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(dialog_context).pop();
              _handleDeleteAccount();
            },
            child: const Text('탈퇴'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteAccount() async {
    setState(() => _is_deleting_account = true);

    final result = await ref.read(authProvider.notifier).deleteAccount();
    if (!mounted) return;

    setState(() => _is_deleting_account = false);

    switch (result) {
      case AccountDeletionResult.accepted:
      case AccountDeletionResult.session_ended:
        _navigateToLogin();
        return;
      case AccountDeletionResult.reauthentication_required:
        _showReauthenticationAlert();
        return;
      case AccountDeletionResult.failed:
        _showAccountDeletionError();
        return;
    }
  }

  void _showReauthenticationAlert() {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialog_context) => CupertinoAlertDialog(
        title: const Text('다시 로그인이 필요합니다'),
        content: const Text(
          '안전한 회원 탈퇴를 위해 다시 로그인해주세요. '
          '로그인 후 탈퇴 요청을 다시 확인해야 합니다.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(dialog_context).pop(),
            child: const Text('나중에'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              Navigator.of(dialog_context).pop();
              await ref.read(authProvider.notifier).logout();
              if (mounted) _navigateToLogin();
            },
            child: const Text('다시 로그인'),
          ),
        ],
      ),
    );
  }

  void _showAccountDeletionError() {
    final message = ref.read(authProvider).error ?? '잠시 후 다시 시도해주세요.';
    showCupertinoDialog<void>(
      context: context,
      builder: (dialog_context) => CupertinoAlertDialog(
        title: const Text('회원 탈퇴 실패'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialog_context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _openShiftPatternSettings() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => const ShiftTemplateSettingsPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth_state = ref.watch(authProvider);
    final user = auth_state.user;
    final bottom_padding = MediaQuery.of(context).padding.bottom;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.background_color,
        border: const Border(
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 1),
        ),
        middle: Text(
          '설정',
          style: AppTheme.heading_small.copyWith(
            color: AppTheme.on_surface_color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            _scaled(20),
            _scaled(16),
            _scaled(20),
            _scaled(40) + bottom_padding,
          ),
          children: [
            if (user != null) _buildProfileCard(user),
            if (user != null) SizedBox(height: _scaled(24)),
            _buildSettingsSection(
              title: '근무 관리',
              children: [
                _buildSettingsRow(
                  icon: CupertinoIcons.calendar,
                  title: '근무 패턴 설정',
                  onTap: _openShiftPatternSettings,
                ),
                _buildSettingsRow(
                  icon: CupertinoIcons.bell,
                  title: '기본 알림 설정',
                  onTap: () => _showFeatureUnavailableAlert('기본 알림 설정'),
                ),
              ],
            ),
            SizedBox(height: _scaled(24)),
            _buildSettingsSection(
              title: '앱 설정',
              children: [
                _buildSwitchRow(
                  icon: CupertinoIcons.moon,
                  title: '다크 모드',
                  value: false,
                  featureName: '다크 모드',
                ),
                _buildSettingsRow(
                  icon: CupertinoIcons.globe,
                  title: '언어 및 지역',
                  value: '한국어',
                  onTap: () => _showFeatureUnavailableAlert('언어 및 지역'),
                ),
                _buildSettingsRow(
                  icon: CupertinoIcons.textformat_size,
                  title: '글꼴 크기',
                  onTap: () => _showFeatureUnavailableAlert('글꼴 크기'),
                ),
              ],
            ),
            SizedBox(height: _scaled(24)),
            _buildSettingsSection(
              title: '계정 및 보안',
              children: [
                _buildSettingsRow(
                  icon: CupertinoIcons.lock,
                  title: '비밀번호 변경',
                  onTap: () => _showFeatureUnavailableAlert('비밀번호 변경'),
                ),
                _buildSwitchRow(
                  icon: CupertinoIcons.lock_shield,
                  title: '로그인 생체 인증',
                  value: true,
                  featureName: '로그인 생체 인증',
                ),
              ],
            ),
            SizedBox(height: _scaled(24)),
            _buildSettingsSection(
              title: '지원',
              children: [
                _buildSettingsRow(
                  icon: CupertinoIcons.speaker_2,
                  title: '공지사항',
                  onTap: () => _showFeatureUnavailableAlert('공지사항'),
                ),
                _buildSettingsRow(
                  icon: CupertinoIcons.question_circle,
                  title: '고객 센터',
                  onTap: () => _showFeatureUnavailableAlert('고객 센터'),
                ),
                _buildSettingsRow(
                  icon: CupertinoIcons.info_circle,
                  title: '버전 정보',
                  value: 'v${AppConstants.app_version}',
                  showChevron: false,
                ),
              ],
            ),
            SizedBox(height: _scaled(24)),
            _buildLogoutButton(),
            SizedBox(height: _scaled(12)),
            _buildDeleteAccountButton(),
          ],
        ),
      ),
    );
  }

  /// 프로필 섹션
  Widget _buildProfileCard(User user) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _showFeatureUnavailableAlert('프로필 편집'),
      child: Container(
        padding: EdgeInsets.all(_scaled(24)),
        decoration: AppTheme.cardDecoration(radius: _scaled(16)),
        child: Row(
          children: [
            _buildProfileAvatar(user),
            SizedBox(width: _scaled(24)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _scaledTextStyle(
                      AppTheme.heading_small,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: _scaled(2)),
                  Text(
                    user.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _scaledTextStyle(
                      AppTheme.body_large,
                      color: AppTheme.on_surface_color,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: _scaled(12)),
            Icon(
              CupertinoIcons.chevron_right,
              size: _scaled(30),
              color: AppTheme.outline_color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileAvatar(User user) {
    final profile_image_url = user.profile_image_url;
    final has_profile_image =
        profile_image_url != null && profile_image_url.isNotEmpty;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: _scaled(64),
          height: _scaled(64),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: _primary_fixed_color, width: _scaled(3)),
          ),
          child: ClipOval(
            child: has_profile_image
                ? Image.network(
                    profile_image_url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack_trace) =>
                        _buildProfileFallback(),
                  )
                : _buildProfileFallback(),
          ),
        ),
        Positioned(
          right: -_scaled(2),
          bottom: -_scaled(2),
          child: Container(
            width: _scaled(32),
            height: _scaled(32),
            decoration: BoxDecoration(
              color: AppTheme.primary_color,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.surface_color,
                width: _scaled(2),
              ),
            ),
            child: Icon(
              CupertinoIcons.pencil,
              size: _scaled(18),
              color: CupertinoColors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileFallback() {
    return Container(
      color: AppTheme.surface_container_low_color,
      child: Center(
        child: Icon(
          CupertinoIcons.person_fill,
          size: _scaled(30),
          color: AppTheme.outline_color,
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: _scaled(16), bottom: _scaled(10)),
          child: Text(
            title,
            style: _scaledTextStyle(
              AppTheme.body_medium,
              color: AppTheme.on_surface_variant_color,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        _buildSettingsCard(children),
      ],
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    final radius = _scaled(16);
    final border_radius = BorderRadius.circular(radius);

    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: border_radius,
        border: Border.all(color: _settings_section_border_color, width: 1),
      ),
      child: ClipRRect(
        borderRadius: border_radius,
        child: ColoredBox(
          color: AppTheme.surface_color,
          child: Column(children: _withDividers(children)),
        ),
      ),
    );
  }

  List<Widget> _withDividers(List<Widget> children) {
    final divided_children = <Widget>[];
    for (var index = 0; index < children.length; index += 1) {
      if (index > 0) {
        divided_children.add(
          Container(height: 1, color: AppTheme.outline_variant_color),
        );
      }
      divided_children.add(children[index]);
    }
    return divided_children;
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required String title,
    String? value,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    return _buildRowShell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: _scaled(28), color: AppTheme.primary_color),
          SizedBox(width: _scaled(18)),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _scaledTextStyle(
                AppTheme.body_large,
                color: AppTheme.on_surface_color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (value != null) ...[
            SizedBox(width: _scaled(12)),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _scaledTextStyle(
                AppTheme.body_large,
                color: AppTheme.on_surface_variant_color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (showChevron) ...[
            SizedBox(width: _scaled(10)),
            Icon(
              CupertinoIcons.chevron_right,
              size: _scaled(30),
              color: AppTheme.outline_color,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSwitchRow({
    required IconData icon,
    required String title,
    required bool value,
    required String featureName,
  }) {
    return _buildRowShell(
      onTap: () => _showFeatureUnavailableAlert(featureName),
      child: Row(
        children: [
          Icon(icon, size: _scaled(28), color: AppTheme.primary_color),
          SizedBox(width: _scaled(18)),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _scaledTextStyle(
                AppTheme.body_large,
                color: AppTheme.on_surface_color,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _buildStaticSwitch(value: value),
        ],
      ),
    );
  }

  Widget _buildStaticSwitch({required bool value}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: _scaled(44),
      height: _scaled(24),
      padding: EdgeInsets.all(_scaled(3)),
      decoration: BoxDecoration(
        color: value ? AppTheme.primary_color : _switch_off_color,
        borderRadius: BorderRadius.circular(_scaled(12)),
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 160),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: _scaled(18),
          height: _scaled(18),
          decoration: const BoxDecoration(
            color: AppTheme.surface_color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildRowShell({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: _scaled(56)),
        padding: EdgeInsets.symmetric(
          horizontal: _scaled(20),
          vertical: _scaled(12),
        ),
        color: AppTheme.surface_color,
        child: child,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: _is_processing ? null : _showLogoutConfirmDialog,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: _scaled(20),
          vertical: _scaled(14),
        ),
        decoration: BoxDecoration(
          color: _error_container_color,
          borderRadius: BorderRadius.circular(_scaled(15)),
          border: Border.all(color: CupertinoColors.systemRed, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_is_logging_out)
              const CupertinoActivityIndicator()
            else
              Icon(
                CupertinoIcons.arrow_right_square,
                size: _scaled(24),
                color: _on_error_container_color,
              ),
            SizedBox(width: _scaled(8)),
            Text(
              _is_logging_out ? '로그아웃 중' : '로그아웃',
              style: _scaledTextStyle(
                AppTheme.body_large,
                color: _on_error_container_color,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return CupertinoButton(
      key: const Key('delete_account_button'),
      padding: EdgeInsets.zero,
      onPressed: _is_processing ? null : _showDeleteAccountConfirmDialog,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 44),
        alignment: Alignment.center,
        child: _is_deleting_account
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(),
                  SizedBox(width: _scaled(8)),
                  Text(
                    '탈퇴 요청 중',
                    style: _scaledTextStyle(
                      AppTheme.body_large,
                      color: _on_error_container_color,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              )
            : Text(
                '회원 탈퇴',
                style: _scaledTextStyle(
                  AppTheme.body_large,
                  color: _on_error_container_color,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }
}
