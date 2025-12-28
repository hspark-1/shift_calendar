import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';

/// 하단 액션 바 모드
enum BottomActionBarMode {
  main, // 메인 페이지: 전자, 31, 알림
  add, // 추가 페이지: 시간, 31, 알림
}

/// 하단 액션 바 위젯
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    this.mode = BottomActionBarMode.main,
    this.onMemoTap,
    this.onCalendarTap,
    this.onNotificationTap,
  });

  final BottomActionBarMode mode;
  final VoidCallback? onMemoTap;
  final VoidCallback? onCalendarTap;
  final VoidCallback? onNotificationTap;

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
                  ? CupertinoIcons.doc_text
                  : CupertinoIcons.clock,
              label: mode == BottomActionBarMode.main ? '메모' : '시간',
              onTap: onMemoTap,
            ),
            _buildCalendarButton(
              onTap: onCalendarTap,
            ),
            _buildActionButton(
              icon: CupertinoIcons.bell,
              label: '알림',
              onTap: onNotificationTap,
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
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
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

