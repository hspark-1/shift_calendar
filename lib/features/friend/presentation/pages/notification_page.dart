// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../group/application/group_providers.dart';
import '../../../group/presentation/pages/group_calendar_page.dart';
import '../../data/models/friend_model.dart';
import '../../data/models/notification_model.dart';
import '../providers/notification_provider.dart';
import '../providers/friend_provider.dart';
import '../widgets/notification_item.dart';
import 'friend_calendar_page.dart';
import 'friend_list_page.dart';

/// 알림 페이지
class NotificationPage extends ConsumerStatefulWidget {
  const NotificationPage({super.key});

  @override
  ConsumerState<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends ConsumerState<NotificationPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 알림 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
      if (AppConstants.group_api_enabled) {
        ref.read(receivedGroupInvitationsProvider.notifier).load(limit: 100);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final group_invitation_state = AppConstants.group_api_enabled
        ? ref.watch(receivedGroupInvitationsProvider)
        : const GroupInvitationState(has_loaded: true);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: const CupertinoNavigationBar(middle: Text('알림')),
      child: SafeArea(
        bottom: false,
        child: _buildContent(state, group_invitation_state),
      ),
    );
  }

  Widget _buildContent(
    NotificationState state,
    GroupInvitationState group_invitation_state,
  ) {
    // 로딩 중
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    // 에러 발생
    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: AppTheme.outline_color,
            ),
            const SizedBox(height: 16),
            Text(
              getNotificationErrorMessage(state.error),
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () =>
                  ref.read(notificationProvider.notifier).loadNotifications(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    // 알림 없음
    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.bell_slash,
              size: 64,
              color: AppTheme.outline_variant_color,
            ),
            const SizedBox(height: 16),
            Text(
              '알림이 없습니다',
              style: AppTheme.body_large.copyWith(
                color: AppTheme.on_surface_color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '새로운 알림이 오면 여기에 표시됩니다',
              style: AppTheme.body_small.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
          ],
        ),
      );
    }

    // 알림 목록 표시
    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () =>
              ref.read(notificationProvider.notifier).loadNotifications(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final notification = state.notifications[index];
              final invitation_id = notification.payload.invitation_id;
              final is_group_invitation =
                  notification.notificationType ==
                  NotificationType.groupInvitation;
              final pending_invitation_ids = group_invitation_state.invitations
                  .map((item) => item.invitation_id)
                  .toSet();
              final show_group_actions =
                  group_invitation_state.has_loaded &&
                  group_invitation_state.error == null &&
                  notification.is_pending_group_invitation &&
                  invitation_id != null &&
                  pending_invitation_ids.contains(invitation_id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NotificationItem(
                  notification: notification,
                  onActionTap: (action) =>
                      _handleNotificationAction(notification, action),
                  show_actions: !is_group_invitation || show_group_actions,
                  actions_enabled:
                      invitation_id == null ||
                      !state.group_processing_ids.contains(invitation_id),
                ),
              );
            }, childCount: state.notifications.length),
          ),
        ),
        // 더 불러오기 인디케이터
        if (state.isLoading && state.notifications.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
        SliverToBoxAdapter(child: _buildListFooter(state)),
      ],
    );
  }

  Widget _buildListFooter(NotificationState state) {
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final footerPadding = bottomSafeArea + 28.0;
    final pagination = state.pagination;
    final hasMoreNotifications =
        pagination != null && pagination.page < pagination.totalPages;

    if (state.isLoading || hasMoreNotifications) {
      return SizedBox(height: footerPadding);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 8, 16, footerPadding),
      child: Center(
        child: Text(
          '모든 알림을 확인했습니다',
          style: AppTheme.body_small.copyWith(
            color: AppTheme.on_surface_variant_color,
          ),
        ),
      ),
    );
  }

  Future<void> _handleNotificationAction(
    NotificationModel notification,
    NotificationAction action,
  ) async {
    switch (action.type) {
      case NotificationActionType.accept:
      case NotificationActionType.reject:
        final is_group_invitation =
            notification.notificationType == NotificationType.groupInvitation;
        final success = await ref
            .read(notificationProvider.notifier)
            .handleNotificationAction(
              notification: notification,
              action: action,
            );
        if (success) {
          if (is_group_invitation) {
            if (!mounted) return;
            if (action.type == NotificationActionType.accept) {
              _navigateToAcceptedGroup(notification);
            }
            return;
          }

          await ref
              .read(friendListProvider.notifier)
              .loadFriends(
                limit: action.type == NotificationActionType.accept ? 100 : 20,
              );
          if (!mounted) return;

          if (action.type == NotificationActionType.accept) {
            _navigateToAcceptedFriendCalendar(notification);
          }
        } else if (mounted) {
          _showError(
            getNotificationErrorMessage(ref.read(notificationProvider).error),
          );
        }
        break;

      case NotificationActionType.navigate:
        if (notification.payload.group_id != null) {
          _navigateToAcceptedGroup(notification);
          break;
        }
        if (action.route != null) {
          // 라우트에 따라 네비게이션
          if (action.route == '/friends') {
            Navigator.of(context).push(
              CupertinoPageRoute<void>(
                builder: (context) => const FriendListPage(),
              ),
            );
          }
        }
        break;

      case NotificationActionType.dismiss:
        // 닫기는 별도 처리 불필요
        break;
    }
  }

  void _navigateToAcceptedGroup(NotificationModel notification) {
    final group_id = notification.payload.group_id;
    if (group_id == null) {
      _showError('그룹 정보를 불러오지 못했습니다.');
      return;
    }

    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => GroupCalendarPage(group_id: group_id),
      ),
    );
  }

  void _navigateToAcceptedFriendCalendar(NotificationModel notification) {
    final friend = _findFriendById(notification.payload.relatedUserId);
    if (friend == null) {
      _showError('친구 정보를 불러오지 못했습니다.');
      return;
    }

    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => FriendCalendarPage(friend: friend),
      ),
    );
  }

  FriendModel? _findFriendById(String? friendUserId) {
    if (friendUserId == null) return null;

    for (final friend in ref.read(friendListProvider).friends) {
      if (friend.userId == friendUserId) {
        return friend;
      }
    }
    return null;
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
