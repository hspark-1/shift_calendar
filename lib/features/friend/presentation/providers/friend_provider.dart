import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../data/models/friend_model.dart';
import '../../data/models/friend_request_model.dart';
import '../../data/services/friend_service.dart';

/// 친구 목록 상태
class FriendListState {
  final List<FriendModel> friends;
  final PaginationInfo? pagination;
  final bool isLoading;
  final dynamic error;

  const FriendListState({
    this.friends = const [],
    this.pagination,
    this.isLoading = false,
    this.error,
  });

  FriendListState copyWith({
    List<FriendModel>? friends,
    PaginationInfo? pagination,
    bool? isLoading,
    dynamic error,
  }) {
    return FriendListState(
      friends: friends ?? this.friends,
      pagination: pagination ?? this.pagination,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 친구 목록 Provider
final friendListProvider =
    StateNotifierProvider<FriendListNotifier, FriendListState>((ref) {
      final service = ref.watch(friendServiceProvider);
      return FriendListNotifier(service);
    });

/// 친구 목록 Notifier
class FriendListNotifier extends StateNotifier<FriendListState> {
  final FriendService _service;

  FriendListNotifier(this._service) : super(const FriendListState());

  /// 친구 목록 조회
  Future<void> loadFriends({int page = 1, int limit = 20}) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getFriends(page: page, limit: limit);
      state = FriendListState(
        friends: response.data.friends,
        pagination: response.data.pagination,
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
      final response = await _service.getFriends(
        page: nextPage,
        limit: state.pagination!.limit,
      );
      state = FriendListState(
        friends: [...state.friends, ...response.data.friends],
        pagination: response.data.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// 친구 설정 변경
  Future<bool> updateFriendSettings({
    required String friendUserId,
    int? friendLevel,
    bool? canView,
  }) async {
    try {
      await _service.updateFriendSettings(
        friendUserId: friendUserId,
        friendLevel: friendLevel,
        canView: canView,
      );

      // 로컬 상태 업데이트
      final updatedFriends = state.friends.map((friend) {
        if (friend.userId == friendUserId) {
          return FriendModel(
            userId: friend.userId,
            name: friend.name,
            email: friend.email,
            phone: friend.phone,
            profileImageUrl: friend.profileImageUrl,
            friendLevel: friendLevel ?? friend.friendLevel,
            canView: canView ?? friend.canView,
            createdAt: friend.createdAt,
          );
        }
        return friend;
      }).toList();

      state = state.copyWith(friends: updatedFriends);
      return true;
    } catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  /// 친구 삭제
  Future<bool> deleteFriend(String friendUserId) async {
    try {
      await _service.deleteFriend(friendUserId);

      // 로컬 상태 업데이트
      final updatedFriends = state.friends
          .where((f) => f.userId != friendUserId)
          .toList();
      state = state.copyWith(friends: updatedFriends);
      return true;
    } catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// =========================================================
// 사용자 검색 Provider
// =========================================================

/// 사용자 검색 상태
class SearchUserState {
  final SearchUserModel? user;
  final bool isLoading;
  final dynamic error;
  final bool hasSearched;

  const SearchUserState({
    this.user,
    this.isLoading = false,
    this.error,
    this.hasSearched = false,
  });

  SearchUserState copyWith({
    SearchUserModel? user,
    bool? isLoading,
    dynamic error,
    bool? hasSearched,
    bool clearUser = false,
  }) {
    return SearchUserState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasSearched: hasSearched ?? this.hasSearched,
    );
  }
}

/// 사용자 검색 Provider
final searchUserProvider =
    StateNotifierProvider<SearchUserNotifier, SearchUserState>((ref) {
      final service = ref.watch(friendServiceProvider);
      return SearchUserNotifier(service);
    });

/// 사용자 검색 Notifier
class SearchUserNotifier extends StateNotifier<SearchUserState> {
  final FriendService _service;

  SearchUserNotifier(this._service) : super(const SearchUserState());

  /// 사용자 검색
  Future<void> searchUser(String query) async {
    if (query.isEmpty) {
      state = const SearchUserState();
      return;
    }

    state = state.copyWith(isLoading: true, error: null, hasSearched: true);

    try {
      final response = await _service.searchUser(query);
      state = SearchUserState(
        user: response.user,
        isLoading: false,
        hasSearched: true,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e, clearUser: true);
    }
  }

  /// 상태 초기화
  void reset() {
    state = const SearchUserState();
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// =========================================================
// 친구 요청 Provider
// =========================================================

/// 친구 요청 상태
class FriendRequestsState {
  final List<ReceivedFriendRequestModel> receivedRequests;
  final List<SentFriendRequestModel> sentRequests;
  final PaginationInfo? receivedPagination;
  final PaginationInfo? sentPagination;
  final bool isLoading;
  final dynamic error;

  const FriendRequestsState({
    this.receivedRequests = const [],
    this.sentRequests = const [],
    this.receivedPagination,
    this.sentPagination,
    this.isLoading = false,
    this.error,
  });

  FriendRequestsState copyWith({
    List<ReceivedFriendRequestModel>? receivedRequests,
    List<SentFriendRequestModel>? sentRequests,
    PaginationInfo? receivedPagination,
    PaginationInfo? sentPagination,
    bool? isLoading,
    dynamic error,
  }) {
    return FriendRequestsState(
      receivedRequests: receivedRequests ?? this.receivedRequests,
      sentRequests: sentRequests ?? this.sentRequests,
      receivedPagination: receivedPagination ?? this.receivedPagination,
      sentPagination: sentPagination ?? this.sentPagination,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 친구 요청 Provider
final friendRequestsProvider =
    StateNotifierProvider<FriendRequestsNotifier, FriendRequestsState>((ref) {
      final service = ref.watch(friendServiceProvider);
      return FriendRequestsNotifier(service);
    });

/// 친구 요청 Notifier
class FriendRequestsNotifier extends StateNotifier<FriendRequestsState> {
  final FriendService _service;

  FriendRequestsNotifier(this._service) : super(const FriendRequestsState());

  /// 받은 요청 목록 조회
  Future<void> loadReceivedRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getReceivedRequests(
        status: status,
        page: page,
        limit: limit,
      );
      state = state.copyWith(
        receivedRequests: response.data.requests,
        receivedPagination: response.data.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// 보낸 요청 목록 조회
  Future<void> loadSentRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _service.getSentRequests(
        status: status,
        page: page,
        limit: limit,
      );
      state = state.copyWith(
        sentRequests: response.data.requests,
        sentPagination: response.data.pagination,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// 친구 요청 보내기
  Future<bool> sendFriendRequest({
    required String addresseeUserId,
    String? message,
  }) async {
    try {
      await _service.sendFriendRequest(
        addresseeUserId: addresseeUserId,
        message: message,
      );
      // 보낸 요청 목록 새로고침
      await loadSentRequests();
      return true;
    } catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  /// 친구 요청 응답 (수락)
  Future<bool> acceptRequest(String requestId) async {
    try {
      await _service.respondToRequest(requestId: requestId, action: 'accept');
      // 받은 요청 목록에서 해당 요청 제거
      final updatedRequests = state.receivedRequests
          .where((r) => r.requestId != requestId)
          .toList();
      state = state.copyWith(receivedRequests: updatedRequests);
      return true;
    } catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  /// 친구 요청 응답 (거절)
  Future<bool> rejectRequest(String requestId) async {
    try {
      await _service.respondToRequest(requestId: requestId, action: 'reject');
      // 받은 요청 목록에서 해당 요청 제거
      final updatedRequests = state.receivedRequests
          .where((r) => r.requestId != requestId)
          .toList();
      state = state.copyWith(receivedRequests: updatedRequests);
      return true;
    } catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  /// 친구 요청 취소
  Future<bool> cancelRequest(String requestId) async {
    try {
      await _service.cancelRequest(requestId);
      // 보낸 요청 목록에서 해당 요청 제거
      final updatedRequests = state.sentRequests
          .where((r) => r.requestId != requestId)
          .toList();
      state = state.copyWith(sentRequests: updatedRequests);
      return true;
    } catch (e) {
      state = state.copyWith(error: e);
      return false;
    }
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}

// =========================================================
// 유틸리티 함수
// =========================================================

/// 에러 메시지 추출
String getErrorMessage(dynamic error) {
  if (error is ApiException) {
    return error.message;
  }
  return '알 수 없는 오류가 발생했습니다.';
}
