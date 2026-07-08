import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/friend_model.dart';
import '../providers/friend_provider.dart';

/// 친구 상세 페이지
class FriendDetailPage extends ConsumerStatefulWidget {
  final FriendModel friend;

  const FriendDetailPage({super.key, required this.friend});

  @override
  ConsumerState<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends ConsumerState<FriendDetailPage> {
  late int _selectedLevel;
  late bool _canView;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.friend.friendLevel;
    _canView = widget.friend.canView;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: const CupertinoNavigationBar(middle: Text('친구 정보')),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 32),
            // 프로필 섹션
            _buildProfileSection(),
            const SizedBox(height: 32),
            // 친구 레벨 설정
            _buildLevelSection(),
            const SizedBox(height: 16),
            // 열람 설정
            _buildViewSettingSection(),
            const SizedBox(height: 32),
            // 친구 삭제
            _buildDeleteSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        // 프로필 이미지
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: CupertinoColors.systemGrey5,
            image: widget.friend.profileImageUrl != null
                ? DecorationImage(
                    image: NetworkImage(widget.friend.profileImageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: widget.friend.profileImageUrl == null
              ? const Icon(
                  CupertinoIcons.person_fill,
                  size: 48,
                  color: CupertinoColors.systemGrey2,
                )
              : null,
        ),
        const SizedBox(height: 16),
        // 이름
        Text(
          widget.friend.name,
          style: AppTheme.heading_medium.copyWith(color: CupertinoColors.label),
        ),
        const SizedBox(height: 4),
        // 이메일
        Text(
          widget.friend.email,
          style: AppTheme.body_small.copyWith(
            color: CupertinoColors.secondaryLabel,
          ),
        ),
        if (widget.friend.phone != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.friend.phone!,
            style: AppTheme.body_small.copyWith(
              color: CupertinoColors.secondaryLabel,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLevelSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('친구 레벨 설정'),
      footer: const Text('레벨이 높을수록 더 많은 일정을 공유합니다.\n레벨 0: 근무표만 공유'),
      children: [
        CupertinoListTile(
          title: const Text('친구 레벨'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (int i = 0; i <= 5; i++) ...[
                GestureDetector(
                  onTap: () => _updateLevel(i),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= _selectedLevel
                          ? AppTheme.primary_color
                          : CupertinoColors.systemGrey5,
                    ),
                    child: Center(
                      child: Text(
                        '$i',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: i <= _selectedLevel
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ),
                ),
                if (i < 5) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildViewSettingSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('열람 설정'),
      footer: const Text('비활성화하면 이 친구가 내 캘린더를 볼 수 없습니다.\n친구 관계는 유지됩니다.'),
      children: [
        CupertinoListTile(
          title: const Text('내 캘린더 공유'),
          trailing: CupertinoSwitch(
            value: _canView,
            onChanged: (value) => _updateCanView(value),
          ),
        ),
      ],
    );
  }

  Widget _buildDeleteSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        color: CupertinoColors.destructiveRed.withValues(alpha: 0.1),
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: _isUpdating ? null : () => _showDeleteConfirmation(),
        child: Text(
          '친구 삭제',
          style: AppTheme.body_medium.copyWith(
            color: CupertinoColors.destructiveRed,
          ),
        ),
      ),
    );
  }

  Future<void> _updateLevel(int level) async {
    if (_isUpdating || level == _selectedLevel) return;

    setState(() {
      _isUpdating = true;
      _selectedLevel = level;
    });

    final success = await ref
        .read(friendListProvider.notifier)
        .updateFriendSettings(
          friendUserId: widget.friend.userId,
          friendLevel: level,
        );

    setState(() => _isUpdating = false);

    if (!success && mounted) {
      // 실패 시 원래 값으로 복원
      setState(() => _selectedLevel = widget.friend.friendLevel);
      _showError('친구 레벨 변경에 실패했습니다.');
    }
  }

  Future<void> _updateCanView(bool canView) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
      _canView = canView;
    });

    final success = await ref
        .read(friendListProvider.notifier)
        .updateFriendSettings(
          friendUserId: widget.friend.userId,
          canView: canView,
        );

    setState(() => _isUpdating = false);

    if (!success && mounted) {
      // 실패 시 원래 값으로 복원
      setState(() => _canView = widget.friend.canView);
      _showError('설정 변경에 실패했습니다.');
    }
  }

  void _showDeleteConfirmation() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('친구 삭제'),
        content: Text('${widget.friend.name}님을 친구 목록에서 삭제하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.of(context).pop();
              _deleteFriend();
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFriend() async {
    setState(() => _isUpdating = true);

    final success = await ref
        .read(friendListProvider.notifier)
        .deleteFriend(widget.friend.userId);

    if (!mounted) return;

    setState(() => _isUpdating = false);

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      _showError('친구 삭제에 실패했습니다.');
    }
  }

  void _showError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
