import 'friend_model.dart';

/// 친구 요청의 사용자 정보
class FriendRequestUser {
  final String userId;
  final String name;
  final String email;
  final String? profileImageUrl;

  FriendRequestUser({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  factory FriendRequestUser.fromJson(Map<String, dynamic> json) {
    return FriendRequestUser(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
    );
  }
}

/// 친구 요청 상태
enum FriendRequestStatus {
  pending,
  accepted,
  rejected,
  canceled;

  static FriendRequestStatus fromString(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return FriendRequestStatus.pending;
      case 'ACCEPTED':
        return FriendRequestStatus.accepted;
      case 'REJECTED':
        return FriendRequestStatus.rejected;
      case 'CANCELED':
        return FriendRequestStatus.canceled;
      default:
        return FriendRequestStatus.pending;
    }
  }

  String get value => name.toUpperCase();
}

/// 받은 친구 요청 모델
class ReceivedFriendRequestModel {
  final String requestId;
  final FriendRequestUser requester;
  final FriendRequestStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;

  ReceivedFriendRequestModel({
    required this.requestId,
    required this.requester,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  factory ReceivedFriendRequestModel.fromJson(Map<String, dynamic> json) {
    return ReceivedFriendRequestModel(
      requestId: json['request_id'] as String,
      requester:
          FriendRequestUser.fromJson(json['requester'] as Map<String, dynamic>),
      status: FriendRequestStatus.fromString(json['status'] as String),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }
}

/// 보낸 친구 요청 모델
class SentFriendRequestModel {
  final String requestId;
  final FriendRequestUser addressee;
  final FriendRequestStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;

  SentFriendRequestModel({
    required this.requestId,
    required this.addressee,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  factory SentFriendRequestModel.fromJson(Map<String, dynamic> json) {
    return SentFriendRequestModel(
      requestId: json['request_id'] as String,
      addressee:
          FriendRequestUser.fromJson(json['addressee'] as Map<String, dynamic>),
      status: FriendRequestStatus.fromString(json['status'] as String),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }
}

/// 받은 친구 요청 목록 응답 데이터
class ReceivedRequestsData {
  final List<ReceivedFriendRequestModel> requests;
  final PaginationInfo pagination;

  ReceivedRequestsData({
    required this.requests,
    required this.pagination,
  });

  factory ReceivedRequestsData.fromJson(Map<String, dynamic> json) {
    return ReceivedRequestsData(
      requests: (json['requests'] as List)
          .map((e) =>
              ReceivedFriendRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

/// 받은 친구 요청 목록 응답
class ReceivedRequestsResponse {
  final bool success;
  final ReceivedRequestsData data;

  ReceivedRequestsResponse({
    required this.success,
    required this.data,
  });

  factory ReceivedRequestsResponse.fromJson(Map<String, dynamic> json) {
    return ReceivedRequestsResponse(
      success: json['success'] as bool,
      data: ReceivedRequestsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 보낸 친구 요청 목록 응답 데이터
class SentRequestsData {
  final List<SentFriendRequestModel> requests;
  final PaginationInfo pagination;

  SentRequestsData({
    required this.requests,
    required this.pagination,
  });

  factory SentRequestsData.fromJson(Map<String, dynamic> json) {
    return SentRequestsData(
      requests: (json['requests'] as List)
          .map((e) =>
              SentFriendRequestModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

/// 보낸 친구 요청 목록 응답
class SentRequestsResponse {
  final bool success;
  final SentRequestsData data;

  SentRequestsResponse({
    required this.success,
    required this.data,
  });

  factory SentRequestsResponse.fromJson(Map<String, dynamic> json) {
    return SentRequestsResponse(
      success: json['success'] as bool,
      data: SentRequestsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 친구 요청 보내기 요청
class SendFriendRequestRequest {
  final String addresseeUserId;
  final String? message;

  SendFriendRequestRequest({
    required this.addresseeUserId,
    this.message,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'addressee_user_id': addresseeUserId,
    };
    if (message != null) map['message'] = message;
    return map;
  }
}

/// 친구 요청 응답 데이터
class FriendRequestData {
  final String requestId;
  final String requesterUserId;
  final String addresseeUserId;
  final FriendRequestStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;

  FriendRequestData({
    required this.requestId,
    required this.requesterUserId,
    required this.addresseeUserId,
    required this.status,
    this.message,
    required this.createdAt,
    this.respondedAt,
  });

  factory FriendRequestData.fromJson(Map<String, dynamic> json) {
    return FriendRequestData(
      requestId: json['request_id'] as String,
      requesterUserId: json['requester_user_id'] as String,
      addresseeUserId: json['addressee_user_id'] as String,
      status: FriendRequestStatus.fromString(json['status'] as String),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }
}

/// 친구 요청 보내기 응답
class SendFriendRequestResponse {
  final bool success;
  final FriendRequestData data;
  final String message;

  SendFriendRequestResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory SendFriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return SendFriendRequestResponse(
      success: json['success'] as bool,
      data: FriendRequestData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }
}

/// 친구 요청 응답(수락/거절) 요청
class RespondFriendRequestRequest {
  final String action; // "accept" | "reject"

  RespondFriendRequestRequest({required this.action});

  Map<String, dynamic> toJson() => {'action': action};
}

/// 친구 관계 정보 (수락 시 반환)
class FriendshipInfo {
  final String userIdA;
  final String userIdB;
  final DateTime createdAt;

  FriendshipInfo({
    required this.userIdA,
    required this.userIdB,
    required this.createdAt,
  });

  factory FriendshipInfo.fromJson(Map<String, dynamic> json) {
    return FriendshipInfo(
      userIdA: json['user_id_a'] as String,
      userIdB: json['user_id_b'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// 친구 요청 응답(수락/거절) 응답 데이터
class RespondRequestData {
  final String requestId;
  final FriendRequestStatus status;
  final DateTime respondedAt;
  final FriendshipInfo? friendship; // 수락 시에만 포함

  RespondRequestData({
    required this.requestId,
    required this.status,
    required this.respondedAt,
    this.friendship,
  });

  factory RespondRequestData.fromJson(Map<String, dynamic> json) {
    return RespondRequestData(
      requestId: json['request_id'] as String,
      status: FriendRequestStatus.fromString(json['status'] as String),
      respondedAt: DateTime.parse(json['responded_at'] as String),
      friendship: json['friendship'] != null
          ? FriendshipInfo.fromJson(json['friendship'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// 친구 요청 응답(수락/거절) 응답
class RespondFriendRequestResponse {
  final bool success;
  final RespondRequestData data;
  final String message;

  RespondFriendRequestResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory RespondFriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return RespondFriendRequestResponse(
      success: json['success'] as bool,
      data: RespondRequestData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }
}

/// 친구 요청 취소 응답 데이터
class CancelRequestData {
  final String requestId;
  final FriendRequestStatus status;
  final DateTime respondedAt;

  CancelRequestData({
    required this.requestId,
    required this.status,
    required this.respondedAt,
  });

  factory CancelRequestData.fromJson(Map<String, dynamic> json) {
    return CancelRequestData(
      requestId: json['request_id'] as String,
      status: FriendRequestStatus.fromString(json['status'] as String),
      respondedAt: DateTime.parse(json['responded_at'] as String),
    );
  }
}

/// 친구 요청 취소 응답
class CancelFriendRequestResponse {
  final bool success;
  final CancelRequestData data;
  final String message;

  CancelFriendRequestResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory CancelFriendRequestResponse.fromJson(Map<String, dynamic> json) {
    return CancelFriendRequestResponse(
      success: json['success'] as bool,
      data: CancelRequestData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }
}

