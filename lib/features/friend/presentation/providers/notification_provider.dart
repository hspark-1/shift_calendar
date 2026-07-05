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
        notifications: response.data.notifications,
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
        notifications: [...state.notifications, ...response.data.notifications],
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
    try {
      switch (action.type) {
        case NotificationActionType.accept:
          // 친구 요청 수락
          final requestId = notification.payload.requestId;
          if (requestId != null) {
            await _friendService.respondToRequest(
              requestId: requestId,
              action: 'accept',
            );
            // 해당 알림 제거
            _removeNotification(notification.notificationId);
            return true;
          }
          return false;

        case NotificationActionType.reject:
          // 친구 요청 거절
          final requestId = notification.payload.requestId;
          if (requestId != null) {
            await _friendService.respondToRequest(
              requestId: requestId,
              action: 'reject',
            );
            // 해당 알림 제거
            _removeNotification(notification.notificationId);
            return true;
          }
          return false;

        case NotificationActionType.navigate:
          // 네비게이션은 UI에서 처리
          return true;

        case NotificationActionType.dismiss:
          // 닫기는 별도 처리 불필요
          return true;
      }
    } catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  /// 알림 목록에서 제거
  void _removeNotification(String notificationId) {
    final updatedNotifications = state.notifications
        .where((n) => n.notificationId != notificationId)
        .toList();
    state = state.copyWith(notifications: updatedNotifications);
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

