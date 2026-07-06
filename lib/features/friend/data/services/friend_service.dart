import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../calendar/data/models/event_api_model.dart';
import '../models/friend_model.dart';
import '../models/friend_request_model.dart';

/// FriendService Provider
final friendServiceProvider = Provider<FriendService>((ref) {
  final dio = ref.watch(dioProvider);
  return FriendService(dio);
});

/// 친구 관리 서비스
class FriendService {
  final Dio _dio;

  FriendService(this._dio);

  /// 날짜 형식 변환 (YYYY-MM-DD)
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // =========================================================
  // 친구 관련 API
  // =========================================================

  /// 친구 목록 조회
  ///
  /// 엔드포인트: GET /api/v1/friends
  /// 인증: 필요
  Future<FriendsResponse> getFriends({int page = 1, int limit = 20}) async {
    try {
      final response = await _dio.get(
        ApiConstants.friends,
        queryParameters: {'page': page, 'limit': limit},
      );
      return FriendsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 사용자 검색 (친구 추가용)
  ///
  /// 엔드포인트: GET /api/v1/users/search?query=...
  /// 인증: 필요
  Future<SearchUserResponse> searchUser(String query) async {
    try {
      final response = await _dio.get(
        ApiConstants.users_search,
        queryParameters: {'query': query},
      );
      return SearchUserResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 친구 설정 변경
  ///
  /// 엔드포인트: PUT /api/v1/friends/:friend_user_id/settings
  /// 인증: 필요
  Future<UpdateFriendSettingsResponse> updateFriendSettings({
    required String friendUserId,
    int? friendLevel,
    bool? canView,
  }) async {
    try {
      final request = UpdateFriendSettingsRequest(
        friendLevel: friendLevel,
        canView: canView,
      );
      final response = await _dio.put(
        '${ApiConstants.friends}/$friendUserId/settings',
        data: request.toJson(),
      );
      return UpdateFriendSettingsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 친구 삭제
  ///
  /// 엔드포인트: DELETE /api/v1/friends/:friend_user_id
  /// 인증: 필요
  Future<void> deleteFriend(String friendUserId) async {
    try {
      await _dio.delete('${ApiConstants.friends}/$friendUserId');
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 친구 캘린더 기간 조회
  ///
  /// 엔드포인트: GET /api/v1/friends/:friend_user_id/calendar/range
  /// 인증: 필요
  ///
  /// 서버는 friend_level_settings(owner_user_id=friend_user_id,
  /// friend_user_id=viewer_user_id)의 can_view/friend_level 조건으로
  /// 열람 가능한 근무표와 일정만 반환해야 한다.
  Future<CalendarRangeResponse> getFriendCalendarRange({
    required String friendUserId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final path = '${ApiConstants.friends}/$friendUserId/calendar/range';
      final response = await _dio.get(
        path,
        queryParameters: {
          'start_date': _formatDate(startDate),
          'end_date': _formatDate(endDate),
        },
      );
      return CalendarRangeResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  // =========================================================
  // 친구 요청 관련 API
  // =========================================================

  /// 친구 요청 보내기
  ///
  /// 엔드포인트: POST /api/v1/friend-requests
  /// 인증: 필요
  Future<SendFriendRequestResponse> sendFriendRequest({
    required String addresseeUserId,
    String? message,
  }) async {
    try {
      final request = SendFriendRequestRequest(
        addresseeUserId: addresseeUserId,
        message: message,
      );
      final response = await _dio.post(
        ApiConstants.friend_requests,
        data: request.toJson(),
      );
      return SendFriendRequestResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 받은 친구 요청 목록 조회
  ///
  /// 엔드포인트: GET /api/v1/friend-requests/received
  /// 인증: 필요
  Future<ReceivedRequestsResponse> getReceivedRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        ApiConstants.friend_requests_received,
        queryParameters: queryParams,
      );
      return ReceivedRequestsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 보낸 친구 요청 목록 조회
  ///
  /// 엔드포인트: GET /api/v1/friend-requests/sent
  /// 인증: 필요
  Future<SentRequestsResponse> getSentRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{'page': page, 'limit': limit};
      if (status != null) queryParams['status'] = status;

      final response = await _dio.get(
        ApiConstants.friend_requests_sent,
        queryParameters: queryParams,
      );
      return SentRequestsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 친구 요청 응답 (수락/거절)
  ///
  /// 엔드포인트: PUT /api/v1/friend-requests/:request_id/respond
  /// 인증: 필요
  Future<RespondFriendRequestResponse> respondToRequest({
    required String requestId,
    required String action, // "accept" | "reject"
  }) async {
    try {
      final request = RespondFriendRequestRequest(action: action);
      final response = await _dio.put(
        '${ApiConstants.friend_requests}/$requestId/respond',
        data: request.toJson(),
      );
      return RespondFriendRequestResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 친구 요청 취소
  ///
  /// 엔드포인트: PUT /api/v1/friend-requests/:request_id/cancel
  /// 인증: 필요
  Future<CancelFriendRequestResponse> cancelRequest(String requestId) async {
    try {
      final response = await _dio.put(
        '${ApiConstants.friend_requests}/$requestId/cancel',
      );
      return CancelFriendRequestResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }
}
