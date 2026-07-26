// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';

/// 하단 액션 바 모드
enum BottomActionBarMode {
  main, // 메인 페이지: 친구, 31, 알림
  add, // 추가 페이지: 시간, 31, 알림
}

/// 화면별 footer 구성을 주입할 때 사용하는 액션 항목
class BottomActionBarItem {
  const BottomActionBarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.is_selected = false,
    this.badge_count = 0,
    this.widget_key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool is_selected;
  final int badge_count;
  final Key? widget_key;
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
    this.items,
  });

  final BottomActionBarMode mode;
  final VoidCallback? onFriendTap;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onNotificationTap;
  final int unreadNotificationCount;
  final List<BottomActionBarItem>? items;

  @override
  Widget build(BuildContext context) {
    final custom_items = items;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface_color,
        border: Border(
          top: BorderSide(color: AppTheme.outline_variant_color, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            if (custom_items != null)
              for (final item in custom_items)
                _buildActionButton(
                  key: item.widget_key,
                  icon: item.icon,
                  label: item.label,
                  onTap: item.onTap,
                  badgeCount: item.badge_count,
                  is_selected: item.is_selected,
                )
            else ...[
              _buildActionButton(
                icon: mode == BottomActionBarMode.main
                    ? CupertinoIcons.person_2
                    : CupertinoIcons.clock,
                label: mode == BottomActionBarMode.main ? '친구' : '시간',
                onTap: onFriendTap,
              ),
              _buildCalendarButton(onTap: onCalendarTap),
              _buildActionButton(
                icon: CupertinoIcons.bell,
                label: '알림',
                onTap: onNotificationTap,
                badgeCount: unreadNotificationCount,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    Key? key,
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    int badgeCount = 0,
    bool is_selected = false,
  }) {
    final foreground_color = is_selected
        ? AppTheme.primary_dark_color
        : AppTheme.on_surface_color;

    return GestureDetector(
      key: key,
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Semantics(
        button: true,
        selected: is_selected,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: is_selected
                    ? AppTheme.primary_color.withValues(alpha: 0.08)
                    : AppTheme.surface_color,
                border: Border.all(
                  color: is_selected
                      ? AppTheme.primary_dark_color
                      : AppTheme.outline_variant_color,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: foreground_color),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: AppTheme.body_small.copyWith(
                      color: foreground_color,
                      fontWeight: is_selected
                          ? FontWeight.w700
                          : FontWeight.normal,
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
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
          color: AppTheme.surface_color,
          border: Border.all(color: AppTheme.outline_variant_color),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Center(
          child: Text(
            '$today',
            style: AppTheme.heading_small.copyWith(
              color: AppTheme.on_surface_color,
            ),
          ),
        ),
      ),
    );
  }
}
