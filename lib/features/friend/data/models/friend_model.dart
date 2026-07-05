/// 친구 정보 모델
class FriendModel {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final int friendLevel;
  final bool canView;
  final DateTime createdAt;

  FriendModel({
    required this.userId,
    required this.name,
    required this.email,
    this.phone,
    this.profileImageUrl,
    required this.friendLevel,
    required this.canView,
    required this.createdAt,
  });

  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      friendLevel: json['friend_level'] as int,
      canView: json['can_view'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_image_url': profileImageUrl,
      'friend_level': friendLevel,
      'can_view': canView,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

/// 친구 목록 페이지네이션 정보
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['total_pages'] as int,
    );
  }
}

/// 친구 목록 응답 데이터
class FriendsData {
  final List<FriendModel> friends;
  final PaginationInfo pagination;

  FriendsData({
    required this.friends,
    required this.pagination,
  });

  factory FriendsData.fromJson(Map<String, dynamic> json) {
    return FriendsData(
      friends: (json['friends'] as List)
          .map((e) => FriendModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination:
          PaginationInfo.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

/// 친구 목록 응답
class FriendsResponse {
  final bool success;
  final FriendsData data;

  FriendsResponse({
    required this.success,
    required this.data,
  });

  factory FriendsResponse.fromJson(Map<String, dynamic> json) {
    return FriendsResponse(
      success: json['success'] as bool,
      data: FriendsData.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// 사용자 검색 결과 모델
class SearchUserModel {
  final String userId;
  final String name;
  final String email;
  final String? profileImageUrl;
  final bool isFriend;
  final bool hasPendingRequest;
  final String? pendingRequestDirection; // "sent" | "received" | null

  SearchUserModel({
    required this.userId,
    required this.name,
    required this.email,
    this.profileImageUrl,
    required this.isFriend,
    required this.hasPendingRequest,
    this.pendingRequestDirection,
  });

  factory SearchUserModel.fromJson(Map<String, dynamic> json) {
    return SearchUserModel(
      userId: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      profileImageUrl: json['profile_image_url'] as String?,
      isFriend: json['is_friend'] as bool,
      hasPendingRequest: json['has_pending_request'] as bool,
      pendingRequestDirection: json['pending_request_direction'] as String?,
    );
  }
}

/// 사용자 검색 응답
class SearchUserResponse {
  final bool success;
  final SearchUserModel user;

  SearchUserResponse({
    required this.success,
    required this.user,
  });

  factory SearchUserResponse.fromJson(Map<String, dynamic> json) {
    return SearchUserResponse(
      success: json['success'] as bool,
      user: SearchUserModel.fromJson(json['data']['user'] as Map<String, dynamic>),
    );
  }
}

/// 친구 설정 변경 요청
class UpdateFriendSettingsRequest {
  final int? friendLevel;
  final bool? canView;

  UpdateFriendSettingsRequest({
    this.friendLevel,
    this.canView,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (friendLevel != null) map['friend_level'] = friendLevel;
    if (canView != null) map['can_view'] = canView;
    return map;
  }
}

/// 친구 설정 변경 응답 데이터
class FriendSettingsData {
  final String ownerUserId;
  final String friendUserId;
  final int friendLevel;
  final bool canView;
  final DateTime updatedAt;

  FriendSettingsData({
    required this.ownerUserId,
    required this.friendUserId,
    required this.friendLevel,
    required this.canView,
    required this.updatedAt,
  });

  factory FriendSettingsData.fromJson(Map<String, dynamic> json) {
    return FriendSettingsData(
      ownerUserId: json['owner_user_id'] as String,
      friendUserId: json['friend_user_id'] as String,
      friendLevel: json['friend_level'] as int,
      canView: json['can_view'] as bool,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

/// 친구 설정 변경 응답
class UpdateFriendSettingsResponse {
  final bool success;
  final FriendSettingsData data;
  final String message;

  UpdateFriendSettingsResponse({
    required this.success,
    required this.data,
    required this.message,
  });

  factory UpdateFriendSettingsResponse.fromJson(Map<String, dynamic> json) {
    return UpdateFriendSettingsResponse(
      success: json['success'] as bool,
      data: FriendSettingsData.fromJson(json['data'] as Map<String, dynamic>),
      message: json['message'] as String,
    );
  }
}

