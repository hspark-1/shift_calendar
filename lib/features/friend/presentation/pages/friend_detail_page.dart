// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/friend_model.dart';
import '../providers/friend_provider.dart';

enum FriendDetailResult { saved, deleted }

/// 친구 상세 페이지
class FriendDetailPage extends ConsumerStatefulWidget {
  final FriendModel friend;

  const FriendDetailPage({super.key, required this.friend});

  @override
  ConsumerState<FriendDetailPage> createState() => _FriendDetailPageState();
}

class _FriendDetailPageState extends ConsumerState<FriendDetailPage> {
  late int _selected_level;
  late int _saved_level;
  late bool _can_view;
  late bool _saved_can_view;
  bool _is_updating = false;

  @override
  void initState() {
    super.initState();
    _selected_level = widget.friend.friendLevel;
    _saved_level = widget.friend.friendLevel;
    _can_view = widget.friend.canView;
    _saved_can_view = widget.friend.canView;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.background_color,
        border: const Border(
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 1),
        ),
        leading: CupertinoButton(
          minimumSize: const Size(40, 40),
          padding: EdgeInsets.zero,
          onPressed: _is_updating ? null : () => Navigator.of(context).pop(),
          child: const Icon(
            CupertinoIcons.back,
            color: AppTheme.on_surface_color,
            size: 28,
          ),
        ),
        middle: Text(
          '친구 정보',
          style: AppTheme.heading_small.copyWith(
            color: AppTheme.on_surface_color,
            fontWeight: FontWeight.w700,
          ),
        ),
        trailing: CupertinoButton(
          minimumSize: const Size(40, 40),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          onPressed: _is_updating || !_hasChanges() ? null : _saveSettings,
          child: _is_updating
              ? const CupertinoActivityIndicator(radius: 9)
              : Text(
                  '저장',
                  style: AppTheme.body_medium.copyWith(
                    color: _hasChanges()
                        ? AppTheme.primary_dark_color
                        : AppTheme.on_surface_variant_color.withValues(
                            alpha: 0.45,
                          ),
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            24,
            16,
            MediaQuery.paddingOf(context).bottom + 32,
          ),
          children: [
            _buildProfileSection(),
            const SizedBox(height: 28),
            _buildLevelSection(),
            const SizedBox(height: 14),
            _buildViewSettingSection(),
            const SizedBox(height: 32),
            _buildDeleteSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surface_container_color,
            border: Border.all(color: AppTheme.surface_color, width: 4),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.05),
                blurRadius: 9,
                offset: const Offset(0, 2),
              ),
            ],
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
                  size: 40,
                  color: AppTheme.outline_color,
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          widget.friend.name,
          style: AppTheme.heading_large.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          widget.friend.email,
          style: AppTheme.body_large.copyWith(
            color: AppTheme.on_surface_variant_color,
            fontWeight: FontWeight.w400,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLevelSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _settingsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(
            icon: CupertinoIcons.chart_bar_alt_fill,
            title: '친구 레벨 설정',
          ),
          const SizedBox(height: 16),
          _buildFriendLevelSelector(),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                CupertinoIcons.info_circle,
                color: AppTheme.primary_color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: AppTheme.body_medium.copyWith(
                      color: AppTheme.on_surface_variant_color,
                      fontWeight: FontWeight.w400,
                    ),
                    children: [
                      const TextSpan(text: '레벨이 높을수록 더 많은 일정을 공유합니다.\n'),
                      TextSpan(
                        text:
                            '레벨 $_selected_level: ${_levelDescription(_selected_level)}',
                        style: AppTheme.body_medium.copyWith(
                          color: AppTheme.on_surface_color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _updateFriendLevelFromPosition({
    required Offset localPosition,
    required double trackWidth,
  }) {
    if (_is_updating || trackWidth <= 0) return;

    final clampedX = localPosition.dx.clamp(0.0, trackWidth).toDouble();
    final segmentWidth = trackWidth / 6;
    final nextLevel = (clampedX / segmentWidth).floor().clamp(0, 5).toInt();

    if (nextLevel == _selected_level) return;

    setState(() {
      _selected_level = nextLevel;
    });
  }

  Widget _buildFriendLevelSelector() {
    const selectorHeight = 42.0;
    const selectorPadding = 3.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final innerWidth = trackWidth - (selectorPadding * 2);
        final segmentWidth = innerWidth <= 0 ? 0.0 : innerWidth / 6;
        final indicatorLeft =
            selectorPadding + (segmentWidth * _selected_level);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _updateFriendLevelFromPosition(
              localPosition: details.localPosition,
              trackWidth: trackWidth,
            );
          },
          onHorizontalDragStart: (details) {
            _updateFriendLevelFromPosition(
              localPosition: details.localPosition,
              trackWidth: trackWidth,
            );
          },
          onHorizontalDragUpdate: (details) {
            _updateFriendLevelFromPosition(
              localPosition: details.localPosition,
              trackWidth: trackWidth,
            );
          },
          child: Container(
            height: selectorHeight,
            decoration: BoxDecoration(
              color: AppTheme.surface_container_color,
              borderRadius: AppTheme.input_border_radius,
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  top: selectorPadding,
                  bottom: selectorPadding,
                  left: indicatorLeft,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary_color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: selectorPadding,
                  ),
                  child: Row(
                    children: [
                      for (int level = 0; level <= 5; level++)
                        Expanded(
                          child: Center(
                            child: Text(
                              '$level',
                              style: TextStyle(
                                color: level == _selected_level
                                    ? CupertinoColors.white
                                    : AppTheme.on_surface_color,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewSettingSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _settingsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSectionTitle(
                  icon: CupertinoIcons.calendar,
                  title: '내 캘린더 공유',
                ),
              ),
              SizedBox(
                width: 46,
                height: 31,
                child: Transform.scale(
                  scale: 0.78,
                  alignment: Alignment.centerRight,
                  child: CupertinoSwitch(
                    value: _can_view,
                    activeTrackColor: AppTheme.primary_color,
                    inactiveTrackColor: AppTheme.surface_container_high_color,
                    onChanged: _is_updating
                        ? null
                        : (value) => setState(() => _can_view = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '비활성화하면 이 친구가 내 캘린더를 볼 수 없습니다. 친구 관계는 유지됩니다.',
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeleteSection() {
    return CupertinoButton(
      color: const Color(0xFFFFDAD6).withValues(alpha: 0.58),
      borderRadius: AppTheme.input_border_radius,
      padding: const EdgeInsets.symmetric(vertical: 14),
      onPressed: _is_updating ? null : () => _showDeleteConfirmation(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.person_badge_minus,
            color: AppTheme.accent_red_color,
            size: 22,
          ),
          const SizedBox(width: 8),
          Text(
            '친구 삭제',
            style: AppTheme.body_large.copyWith(
              color: AppTheme.accent_red_color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.on_surface_variant_color, size: 20),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            title,
            style: AppTheme.body_large.copyWith(
              fontWeight: FontWeight.w700,
              color: AppTheme.on_surface_variant_color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  BoxDecoration _settingsCardDecoration() {
    return BoxDecoration(
      color: AppTheme.surface_color,
      borderRadius: BorderRadius.circular(AppTheme.card_radius),
      border: Border.all(
        color: AppTheme.outline_variant_color.withValues(alpha: 0.50),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: CupertinoColors.black.withValues(alpha: 0.05),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  String _levelDescription(int level) {
    switch (level) {
      case 0:
        return '근무표만 공유';
      case 5:
        return '모든 일정 공유';
      default:
        return '레벨 $level 이하 일정 공유';
    }
  }

  bool _hasChanges() {
    return _selected_level != _saved_level || _can_view != _saved_can_view;
  }

  Future<void> _saveSettings() async {
    if (_is_updating || !_hasChanges()) return;

    setState(() => _is_updating = true);

    final success = await ref
        .read(friendListProvider.notifier)
        .updateFriendSettings(
          friendUserId: widget.friend.userId,
          friendLevel: _selected_level,
          canView: _can_view,
        );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(FriendDetailResult.saved);
      return;
    }

    setState(() => _is_updating = false);
    _showError('설정 변경에 실패했습니다.');
  }

  Future<void> _deleteFriend() async {
    setState(() => _is_updating = true);

    final success = await ref
        .read(friendListProvider.notifier)
        .deleteFriend(widget.friend.userId);

    if (!mounted) return;

    setState(() => _is_updating = false);

    if (success) {
      Navigator.of(context).pop(FriendDetailResult.deleted);
    } else {
      _showError('친구 삭제에 실패했습니다.');
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
