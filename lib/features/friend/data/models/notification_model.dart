import 'friend_model.dart';

/// 알림 타입
enum NotificationType {
  friendRequest,
  friendAccepted,
  friendRejected,
  scheduleShared,
  system,
  general;

  static NotificationType fromString(String type) {
    switch (type.toUpperCase()) {
      case 'FRIEND_REQUEST':
        return NotificationType.friendRequest;
      case 'FRIEND_REQUEST_ACCEPTED':
      case 'FRIEND_ACCEPTED':
        return NotificationType.friendAccepted;
      case 'FRIEND_REQUEST_REJECTED':
      case 'FRIEND_REJECTED':
        return NotificationType.friendRejected;
      case 'SCHEDULE_SHARED':
        return NotificationType.scheduleShared;
      case 'SYSTEM':
        return NotificationType.system;
      case 'GENERAL':
      default:
        return NotificationType.general;
    }
  }

  String get value {
    switch (this) {
      case NotificationType.friendRequest:
        return 'FRIEND_REQUEST';
      case NotificationType.friendAccepted:
        return 'FRIEND_REQUEST_ACCEPTED';
      case NotificationType.friendRejected:
        return 'FRIEND_REQUEST_REJECTED';
      case NotificationType.scheduleShared:
        return 'SCHEDULE_SHARED';
      case NotificationType.system:
        return 'SYSTEM';
      case NotificationType.general:
        return 'GENERAL';
    }
  }
}

/// 알림 액션 타입
enum NotificationActionType {
  accept,
  reject,
  navigate,
  dismiss;

  static NotificationActionType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'accept':
        return NotificationActionType.accept;
      case 'reject':
        return NotificationActionType.reject;
      case 'navigate':
        return NotificationActionType.navigate;
      case 'dismiss':
      default:
        return NotificationActionType.dismiss;
    }
  }
}

/// 알림 액션 모델
class NotificationAction {
  final NotificationActionType type;
  final String label;
  final String? route; // navigate 타입일 때 이동할 경로

  NotificationAction({required this.type, required this.label, this.route});

  factory NotificationAction.fromJson(Map<String, dynamic> json) {
    return NotificationAction(
      type: NotificationActionType.fromString(json['type'] as String),
      label: json['label'] as String,
      route: json['route'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'type': type.name, 'label': label};
    if (route != null) map['route'] = route;
    return map;
  }
}

/// 알림 페이로드 (타입별 추가 데이터)
class NotificationPayload {
  final String? relatedUserId;
  final String? requestId;
  final String? userName;
  final String? profileImageUrl;
  final String? requestStatus;
  final DateTime? respondedAt;
  final Map<String, dynamic> rawData;

  NotificationPayload({
    this.relatedUserId,
    this.requestId,
    this.userName,
    this.profileImageUrl,
    this.requestStatus,
    this.respondedAt,
    required this.rawData,
  });

  factory NotificationPayload.fromJson(Map<String, dynamic> json) {
    final respondedAtValue = json['responded_at'];

    return NotificationPayload(
      relatedUserId: json['related_user_id'] as String?,
      requestId: json['request_id'] as String?,
      userName: json['user_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      requestStatus: json['request_status'] as String?,
      respondedAt: respondedAtValue is String
          ? DateTime.tryParse(respondedAtValue)
          : null,
      rawData: json,
    );
  }

  /// 추가 데이터 접근
  T? get<T>(String key) {
    final value = rawData[key];
    if (value is T) return value;
    return null;
  }
}

/// 알림 모델
class NotificationModel {
  final String notificationId;
  final NotificationType notificationType;
  final String title;
  final String body;
  final NotificationPayload payload;
  final List<NotificationAction> actions;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.notificationId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.payload,
    required this.actions,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? notificationId,
    NotificationType? notificationType,
    String? title,
    String? body,
    NotificationPayload? payload,
    List<NotificationAction>? actions,
    bool? isRead,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      notificationId: notificationId ?? this.notificationId,
      notificationType: notificationType ?? this.notificationType,
      title: title ?? this.title,
      body: body ?? this.body,
      payload: payload ?? this.payload,
      actions: actions ?? this.actions,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId: json['notification_id'] as String,
      notificationType: NotificationType.fromString(
        json['notification_type'] as String,
      ),
      title: json['title'] as String,
      body: json['body'] as String,
      payload: NotificationPayload.fromJson(
        json['payload'] as Map<String, dynamic>? ?? {},
      ),
      actions:
          (json['actions'] as List?)
              ?.map(
                (e) => NotificationAction.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
      isRead: json['is_read'] as bool,
      readAt: json['read_at'] != null
          ? DateTime.parse(json['read_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 액션이 있는지 확인
  bool get hasActions => actions.isNotEmpty;

  /// 특정 타입의 액션 찾기
  NotificationAction? findAction(NotificationActionType type) {
    try {
      return actions.firstWhere((a) => a.type == type);
    } catch (_) {
      return null;
    }
  }
}

/// 알림 목록 응답 데이터
class NotificationsData {
  final List<NotificationModel> notifications;
  final PaginationInfo pagination;

  NotificationsData({required this.notifications, required this.pagination});

  factory NotificationsData.fromJson(Map<String, dynamic> json) {
    return NotificationsData(
      notifications: (json['notifications'] as List)
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

/// 알림 목록 응답
class NotificationsResponse {
  final bool success;
  final NotificationsData data;

  NotificationsResponse({required this.success, required this.data});

  factory NotificationsResponse.fromJson(Map<String, dynamic> json) {
    return NotificationsResponse(
      success: json['success'] as bool,
      data: NotificationsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 미읽음 알림 개수 응답
class UnreadCountResponse {
  final bool success;
  final int unreadCount;

  UnreadCountResponse({required this.success, required this.unreadCount});

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(
      success: json['success'] as bool,
      unreadCount: json['data']['unread_count'] as int,
    );
  }
}
