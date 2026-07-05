import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/notification_model.dart';

/// 알림 아이템 위젯
/// 동적 액션 버튼을 지원합니다.
class NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final void Function(NotificationAction action)? onActionTap;

  const NotificationItem({
    super.key,
    required this.notification,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: notification.isRead
            ? CupertinoColors.white
            : AppTheme.primary_color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: notification.isRead
              ? CupertinoColors.systemGrey5
              : AppTheme.primary_color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 아이콘 + 타이틀 + 시간
          Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: AppTheme.body_medium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeAgo(notification.createdAt),
                      style: AppTheme.body_small.copyWith(
                        color: CupertinoColors.secondaryLabel,
                      ),
                    ),
                  ],
                ),
              ),
              // 읽지 않음 표시
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primary_color,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // 본문
          Text(
            notification.body,
            style: AppTheme.body_medium.copyWith(
              color: CupertinoColors.label,
            ),
          ),
          // 액션 버튼 (동적 생성)
          if (notification.hasActions) ...[
            const SizedBox(height: 12),
            _buildActions(context),
          ],
        ],
      ),
    );
  }

  Widget _buildIcon() {
    IconData icon;
    Color color;

    switch (notification.notificationType) {
      case NotificationType.friendRequest:
        icon = CupertinoIcons.person_add;
        color = CupertinoColors.systemBlue;
        break;
      case NotificationType.friendAccepted:
        icon = CupertinoIcons.person_2_fill;
        color = CupertinoColors.systemGreen;
        break;
      case NotificationType.friendRejected:
        icon = CupertinoIcons.person_badge_minus;
        color = CupertinoColors.systemRed;
        break;
      case NotificationType.scheduleShared:
        icon = CupertinoIcons.calendar;
        color = CupertinoColors.systemOrange;
        break;
      case NotificationType.system:
        icon = CupertinoIcons.gear;
        color = CupertinoColors.systemGrey;
        break;
      case NotificationType.general:
        icon = CupertinoIcons.bell_fill;
        color = CupertinoColors.systemGrey;
        break;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.15),
      ),
      child: Icon(
        icon,
        size: 20,
        color: color,
      ),
    );
  }

  /// 동적 액션 버튼 빌드
  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: notification.actions.map((action) {
        return Padding(
          padding: const EdgeInsets.only(left: 8),
          child: _buildActionButton(context, action),
        );
      }).toList(),
    );
  }

  /// 액션 타입에 따른 버튼 스타일 결정
  Widget _buildActionButton(BuildContext context, NotificationAction action) {
    // 액션 타입에 따라 버튼 스타일 결정
    Color backgroundColor;
    Color textColor;

    switch (action.type) {
      case NotificationActionType.accept:
        backgroundColor = AppTheme.primary_color;
        textColor = CupertinoColors.white;
        break;
      case NotificationActionType.reject:
        backgroundColor = CupertinoColors.systemGrey5;
        textColor = CupertinoColors.label.resolveFrom(context);
        break;
      case NotificationActionType.navigate:
        backgroundColor = CupertinoColors.systemBlue.withValues(alpha: 0.15);
        textColor = CupertinoColors.systemBlue;
        break;
      case NotificationActionType.dismiss:
        backgroundColor = CupertinoColors.systemGrey5;
        textColor = CupertinoColors.secondaryLabel.resolveFrom(context);
        break;
    }

    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      minSize: 0,
      borderRadius: BorderRadius.circular(18),
      onPressed: () => onActionTap?.call(action),
      child: Text(
        action.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: textColor,
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return '방금 전';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}분 전';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}시간 전';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}일 전';
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }
}

