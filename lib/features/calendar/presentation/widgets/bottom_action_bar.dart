import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';

/// 하단 액션 바 모드
enum BottomActionBarMode {
  main, // 메인 페이지: 친구, 31, 알림
  add, // 추가 페이지: 시간, 31, 알림
}

/// 하단 액션 바 위젯
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    this.mode = BottomActionBarMode.main,
    this.onFriendTap,
    this.onCalendarTap,
    this.onNotificationTap,
    this.unreadNotificationCount = 0,
  });

  final BottomActionBarMode mode;
  final VoidCallback? onFriendTap;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onNotificationTap;
  final int unreadNotificationCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildActionButton(
              icon: mode == BottomActionBarMode.main
                  ? CupertinoIcons.person_2
                  : CupertinoIcons.clock,
              label: mode == BottomActionBarMode.main ? '친구' : '시간',
              onTap: onFriendTap,
            ),
            _buildCalendarButton(
              onTap: onCalendarTap,
            ),
            _buildActionButton(
              icon: CupertinoIcons.bell,
              label: '알림',
              onTap: onNotificationTap,
              badgeCount: unreadNotificationCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: CupertinoColors.systemGrey4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: CupertinoColors.label,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: AppTheme.body_small.copyWith(
                    color: CupertinoColors.label,
                  ),
                ),
              ],
            ),
          ),
          // 알림 배지
          if (badgeCount > 0)
            Positioned(
              right: -4,
              top: -4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                child: Center(
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCalendarButton({VoidCallback? onTap}) {
    final today = DateTime.now().day;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          border: Border.all(color: CupertinoColors.systemGrey4),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            '$today',
            style: AppTheme.heading_small.copyWith(
              color: CupertinoColors.label,
            ),
          ),
        ),
      ),
    );
  }
}

