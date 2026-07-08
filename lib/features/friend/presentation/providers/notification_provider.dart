import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/friend_model.dart';
import '../../data/models/notification_model.dart';
import '../../data/services/notification_service.dart';
import '../../data/services/friend_service.dart';

/// 알림 상태
class NotificationState {
  final List<NotificationModel> notifications;
  final PaginationInfo? pagination;
  final int unreadCount;
  final bool isLoading;
  final dynamic error;

  const NotificationState({
    this.notifications = const [],
    this.pagination,
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    PaginationInfo? pagination,
    int? unreadCount,
    bool? isLoading,
    dynamic error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      pagination: pagination ?? this.pagination,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 알림 Provider
final notificationProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
      final notificationService = ref.watch(notificationServiceProvider);
      final friendService = ref.watch(friendServiceProvider);
      return NotificationNotifier(notificationService, friendService);
    });

/// 알림 Notifier
class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _notificationService;
  final FriendService _friendService;
  final Map<String, NotificationModel> _locallyRespondedNotifications = {};

  NotificationNotifier(this._notificationService, this._friendService)
    : super(const NotificationState());

  /// 알림 목록 조회 (조회 시 읽음 처리됨)
  Future<void> loadNotifications({int page = 1, int limit = 20}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _notificationService.getNotifications(
        page: page,
        limit: limit,
      );
      state = NotificationState(
        notifications: _mergeLocalRespondedNotifications(
          response.data.notifications,
        ),
        pagination: response.data.pagination,
        unreadCount: 0, // 조회 시 읽음 처리되므로 0으로 설정
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// 더 불러오기 (페이지네이션)
  Future<void> loadMore() async {
    if (state.pagination == null ||
        state.pagination!.page >= state.pagination!.totalPages) {
      return;
    }

    final nextPage = state.pagination!.page + 1;
    state = state.copyWith(isLoading: true);

    try {
      final response = await _notificationService.getNotifications(
        page: nextPage,
        limit: state.pagination!.limit,
      );
      state = NotificationState(
        notifications: _mergeLocalRespondedNotifications([
          ...state.notifications,
          ...response.data.notifications,
        ]),
        pagination: response.data.pagination,
        unreadCount: state.unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// 미읽음 알림 개수 조회 (읽음 처리 안함)
  Future<void> fetchUnreadCount() async {
    try {
      final response = await _notificationService.getUnreadCount();
      state = state.copyWith(unreadCount: response.unreadCount);
    } catch (e) {
      // 미읽음 개수 조회 실패는 무시 (중요하지 않은 에러)
    }
  }

  /// 알림 액션 처리
  Future<bool> handleNotificationAction({
    required NotificationModel notification,
    required NotificationAction action,
  }) async {
    switch (action.type) {
      case NotificationActionType.accept:
        return _respondToFriendRequest(
          notification: notification,
          actionType: action.type,
          requestAction: 'accept',
        );

      case NotificationActionType.reject:
        return _respondToFriendRequest(
          notification: notification,
          actionType: action.type,
          requestAction: 'reject',
        );

      case NotificationActionType.navigate:
        // 네비게이션은 UI에서 처리
        return true;

      case NotificationActionType.dismiss:
        // 닫기는 별도 처리 불필요
        return true;
    }
  }

  Future<bool> _respondToFriendRequest({
    required NotificationModel notification,
    required NotificationActionType actionType,
    required String requestAction,
  }) async {
    final requestId = notification.payload.requestId;
    if (requestId == null) return false;

    final previousState = state;
    final optimisticNotification = _buildRespondedNotification(
      notification: notification,
      actionType: actionType,
    );
    final optimisticUnreadCount = notification.isRead
        ? state.unreadCount
        : (state.unreadCount > 0 ? state.unreadCount - 1 : 0);

    _replaceNotification(
      notification.notificationId,
      optimisticNotification,
      unreadCount: optimisticUnreadCount,
    );
    _cacheLocalRespondedNotification(optimisticNotification);

    try {
      final response = await _friendService.respondToRequest(
        requestId: requestId,
        action: requestAction,
      );
      final updatedNotification =
          response.data.notification ??
          _buildRespondedNotification(
            notification: notification,
            actionType: actionType,
            respondedAt: response.data.respondedAt,
          );

      _replaceNotification(notification.notificationId, updatedNotification);
      _removeLocalRespondedNotification(notification);
      _cacheLocalRespondedNotification(updatedNotification);
      return true;
    } catch (e) {
      _removeLocalRespondedNotification(notification);
      state = previousState.copyWith(error: e);
      return false;
    }
  }

  NotificationModel _buildRespondedNotification({
    required NotificationModel notification,
    required NotificationActionType actionType,
    DateTime? respondedAt,
  }) {
    final isAccepted = actionType == NotificationActionType.accept;
    final respondedAtValue = (respondedAt ?? DateTime.now()).toUtc();
    final status = isAccepted ? 'ACCEPTED' : 'REJECTED';
    final actionLabel = isAccepted ? '수락' : '거절';
    final userName = notification.payload.userName;
    final body = userName == null || userName.isEmpty
        ? '친구 요청을 $actionLabel했습니다.'
        : '$userName님의 친구 요청을 $actionLabel했습니다.';
    final payloadData = Map<String, dynamic>.from(notification.payload.rawData)
      ..['related_user_id'] = notification.payload.relatedUserId
      ..['request_id'] = notification.payload.requestId
      ..['user_name'] = notification.payload.userName
      ..['profile_image_url'] = notification.payload.profileImageUrl
      ..['request_status'] = status
      ..['responded_at'] = respondedAtValue.toIso8601String();

    return notification.copyWith(
      notificationType: isAccepted
          ? NotificationType.friendAccepted
          : NotificationType.friendRejected,
      title: '친구 요청 $actionLabel',
      body: body,
      payload: NotificationPayload.fromJson(payloadData),
      actions: const [],
      isRead: true,
      readAt: respondedAtValue,
    );
  }

  /// 알림 목록에서 특정 알림을 교체
  void _replaceNotification(
    String notificationId,
    NotificationModel notification, {
    int? unreadCount,
  }) {
    var replaced = false;
    final updatedNotifications = state.notifications.map((n) {
      if (_isSameNotification(n, notificationId, notification)) {
        replaced = true;
        return notification;
      }
      return n;
    }).toList();
    if (!replaced) {
      updatedNotifications.insert(0, notification);
    }
    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }

  List<NotificationModel> _mergeLocalRespondedNotifications(
    List<NotificationModel> notifications,
  ) {
    if (_locallyRespondedNotifications.isEmpty) {
      return notifications;
    }

    final mergedNotifications = [...notifications];
    for (final localNotification in _locallyRespondedNotifications.values) {
      final index = mergedNotifications.indexWhere(
        (notification) => _isSameNotification(
          notification,
          localNotification.notificationId,
          localNotification,
        ),
      );
      if (index >= 0) {
        mergedNotifications[index] = localNotification;
      } else {
        mergedNotifications.insert(0, localNotification);
      }
    }
    return mergedNotifications;
  }

  bool _isSameNotification(
    NotificationModel notification,
    String notificationId,
    NotificationModel replacement,
  ) {
    final requestId = replacement.payload.requestId;
    return notification.notificationId == notificationId ||
        notification.notificationId == replacement.notificationId ||
        (requestId != null && notification.payload.requestId == requestId);
  }

  void _cacheLocalRespondedNotification(NotificationModel notification) {
    _removeLocalRespondedNotification(notification);
    _locallyRespondedNotifications[notification.notificationId] = notification;
  }

  void _removeLocalRespondedNotification(NotificationModel notification) {
    _locallyRespondedNotifications.remove(notification.notificationId);
    final requestId = notification.payload.requestId;
    if (requestId == null) return;

    _locallyRespondedNotifications.removeWhere(
      (_, cachedNotification) =>
          cachedNotification.payload.requestId == requestId,
    );
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 미읽음 알림 개수 Provider (간편 조회용)
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationProvider).unreadCount;
});

/// 에러 메시지 추출
String getNotificationErrorMessage(dynamic error) {
  if (error is ApiException) {
    return error.message;
  }
  return '알 수 없는 오류가 발생했습니다.';
}
