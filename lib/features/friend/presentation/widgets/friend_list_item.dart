import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/friend_model.dart';

/// 친구 리스트 아이템 위젯
class FriendListItem extends StatelessWidget {
  final FriendModel friend;
  final VoidCallback? onTap;

  const FriendListItem({super.key, required this.friend, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.cardDecoration(),
        child: Row(
          children: [
            // 프로필 이미지
            _buildProfileImage(),
            const SizedBox(width: 12),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    friend.name,
                    style: AppTheme.body_medium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    friend.email,
                    style: AppTheme.body_small.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                ],
              ),
            ),
            // 레벨 표시
            _buildLevelBadge(),
            const SizedBox(width: 8),
            // 화살표
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 16,
              color: AppTheme.outline_variant_color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.surface_container_color,
        image: friend.profileImageUrl != null
            ? DecorationImage(
                image: NetworkImage(friend.profileImageUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: friend.profileImageUrl == null
          ? const Icon(
              CupertinoIcons.person_fill,
              size: 24,
              color: AppTheme.outline_color,
            )
          : null,
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getLevelColor().withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppTheme.chip_radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(CupertinoIcons.star_fill, size: 12, color: _getLevelColor()),
          const SizedBox(width: 4),
          Text(
            'Lv.${friend.friendLevel}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getLevelColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    switch (friend.friendLevel) {
      case 0:
        return CupertinoColors.systemGrey;
      case 1:
        return CupertinoColors.systemGreen;
      case 2:
        return AppTheme.primary_color;
      case 3:
        return CupertinoColors.systemPurple;
      case 4:
        return CupertinoColors.systemOrange;
      case 5:
        return CupertinoColors.systemRed;
      default:
        return CupertinoColors.systemGrey;
    }
  }
}
