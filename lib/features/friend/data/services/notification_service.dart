import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../models/notification_model.dart';

/// NotificationService Provider
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final dio = ref.watch(dioProvider);
  return NotificationService(dio);
});

/// 알림 관리 서비스
class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  /// 알림 목록 조회
  ///
  /// 엔드포인트: GET /api/v1/notifications
  /// 인증: 필요
  /// 참고: 조회 시 자동으로 읽음 처리됩니다.
  Future<NotificationsResponse> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications,
        queryParameters: {
          'page': page,
          'limit': limit,
        },
      );
      return NotificationsResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 미읽음 알림 개수 조회
  ///
  /// 엔드포인트: GET /api/v1/notifications/unread-count
  /// 인증: 필요
  /// 참고: 읽음 처리하지 않습니다.
  Future<UnreadCountResponse> getUnreadCount() async {
    try {
      final response = await _dio.get(
        ApiConstants.notifications_unread_count,
      );
      return UnreadCountResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }
}

