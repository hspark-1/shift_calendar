// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_error_handler.dart';

abstract interface class GroupRemoteDataSource {
  Future<Map<String, dynamic>> getGroups({
    required int page,
    required int limit,
  });

  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? timezone,
    required List<String> invitee_user_ids,
  });

  Future<Map<String, dynamic>> getGroupDetail(String group_id);

  Future<Map<String, dynamic>> getGroupCalendarRange({
    required String group_id,
    required String start_date,
    required String end_date,
  });

  Future<Map<String, dynamic>> createInvitations({
    required String group_id,
    required List<String> invitee_user_ids,
    String? message,
  });

  Future<Map<String, dynamic>> getReceivedInvitations({
    String? status,
    required int page,
    required int limit,
  });

  Future<Map<String, dynamic>> respondToInvitation({
    required String invitation_id,
    required String action,
  });

  Future<Map<String, dynamic>> updateGroup({
    required String group_id,
    String? name,
    String? timezone,
  });

  Future<void> deleteGroup(String group_id);

  Future<Map<String, dynamic>> getGroupInvitations({
    required String group_id,
    String? status,
    required int page,
    required int limit,
  });

  Future<Map<String, dynamic>> cancelInvitation(String invitation_id);

  Future<void> removeMember({
    required String group_id,
    required String user_id,
  });

  Future<Map<String, dynamic>> updateMemberRole({
    required String group_id,
    required String user_id,
    required String role,
  });

  Future<void> leaveGroup(String group_id);

  Future<Map<String, dynamic>> transferOwnership({
    required String group_id,
    required String new_owner_user_id,
  });
}

class DioGroupRemoteDataSource implements GroupRemoteDataSource {
  DioGroupRemoteDataSource(this._dio);

  final Dio _dio;

  Map<String, dynamic> _responseMap(Response<dynamic> response) {
    return response.data as Map<String, dynamic>;
  }

  @override
  Future<Map<String, dynamic>> getGroups({
    required int page,
    required int limit,
  }) async {
    try {
      return _responseMap(
        await _dio.get(
          ApiConstants.groups,
          queryParameters: {'page': page, 'limit': limit},
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> createGroup({
    required String name,
    String? timezone,
    required List<String> invitee_user_ids,
  }) async {
    try {
      return _responseMap(
        await _dio.post(
          ApiConstants.groups,
          data: {
            'name': name,
            if (timezone != null) 'timezone': timezone,
            if (invitee_user_ids.isNotEmpty)
              'invitee_user_ids': invitee_user_ids,
          },
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getGroupDetail(String group_id) async {
    try {
      return _responseMap(await _dio.get('${ApiConstants.groups}/$group_id'));
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getGroupCalendarRange({
    required String group_id,
    required String start_date,
    required String end_date,
  }) async {
    try {
      return _responseMap(
        await _dio.get(
          '${ApiConstants.groups}/$group_id/calendar/range',
          queryParameters: {'start_date': start_date, 'end_date': end_date},
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> createInvitations({
    required String group_id,
    required List<String> invitee_user_ids,
    String? message,
  }) async {
    try {
      return _responseMap(
        await _dio.post(
          '${ApiConstants.groups}/$group_id/invitations',
          data: {
            'invitee_user_ids': invitee_user_ids,
            if (message != null && message.trim().isNotEmpty)
              'message': message.trim(),
          },
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getReceivedInvitations({
    String? status,
    required int page,
    required int limit,
  }) async {
    try {
      return _responseMap(
        await _dio.get(
          ApiConstants.group_invitations_received,
          queryParameters: {
            if (status != null) 'status': status,
            'page': page,
            'limit': limit,
          },
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> respondToInvitation({
    required String invitation_id,
    required String action,
  }) async {
    try {
      return _responseMap(
        await _dio.put(
          '${ApiConstants.group_invitations}/$invitation_id/respond',
          data: {'action': action},
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> updateGroup({
    required String group_id,
    String? name,
    String? timezone,
  }) async {
    try {
      return _responseMap(
        await _dio.patch(
          '${ApiConstants.groups}/$group_id',
          data: {
            if (name != null) 'name': name,
            if (timezone != null) 'timezone': timezone,
          },
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<void> deleteGroup(String group_id) async {
    try {
      await _dio.delete('${ApiConstants.groups}/$group_id');
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> getGroupInvitations({
    required String group_id,
    String? status,
    required int page,
    required int limit,
  }) async {
    try {
      return _responseMap(
        await _dio.get(
          '${ApiConstants.groups}/$group_id/invitations',
          queryParameters: {
            if (status != null) 'status': status,
            'page': page,
            'limit': limit,
          },
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> cancelInvitation(String invitation_id) async {
    try {
      return _responseMap(
        await _dio.put(
          '${ApiConstants.group_invitations}/$invitation_id/cancel',
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<void> removeMember({
    required String group_id,
    required String user_id,
  }) async {
    try {
      await _dio.delete('${ApiConstants.groups}/$group_id/members/$user_id');
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> updateMemberRole({
    required String group_id,
    required String user_id,
    required String role,
  }) async {
    try {
      return _responseMap(
        await _dio.patch(
          '${ApiConstants.groups}/$group_id/members/$user_id',
          data: {'role': role},
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<void> leaveGroup(String group_id) async {
    try {
      await _dio.post('${ApiConstants.groups}/$group_id/leave');
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }

  @override
  Future<Map<String, dynamic>> transferOwnership({
    required String group_id,
    required String new_owner_user_id,
  }) async {
    try {
      return _responseMap(
        await _dio.put(
          '${ApiConstants.groups}/$group_id/owner',
          data: {'new_owner_user_id': new_owner_user_id},
        ),
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }
}
