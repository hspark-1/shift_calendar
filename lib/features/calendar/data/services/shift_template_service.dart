import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../models/shift_template_api_model.dart';

/// ShiftTemplateService Provider
final shiftTemplateServiceProvider = Provider<ShiftTemplateService>((ref) {
  final dio = ref.watch(dioProvider);
  return ShiftTemplateService(dio);
});

/// 템플릿 관리 서비스
class ShiftTemplateService {
  final Dio _dio;

  ShiftTemplateService(this._dio);

  /// 현재 사용자의 활성 템플릿 조회
  ///
  /// 엔드포인트: GET /api/v1/shift-templates/current
  /// 인증: 필요
  Future<ShiftTemplateResponse> getCurrentTemplate() async {
    try {
      final response = await _dio.get(ApiConstants.shift_templates_current);
      return ShiftTemplateResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }

  /// 템플릿 이름 변경
  ///
  /// 엔드포인트: PUT /api/v1/shift-templates/current
  /// 인증: 필요
  Future<UpdateTemplateNameResponse> updateTemplateName(String name) async {
    try {
      final request = UpdateTemplateNameRequest(name: name);
      final response = await _dio.put(
        ApiConstants.shift_templates_current,
        data: request.toJson(),
      );
      return UpdateTemplateNameResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw handleApiError(e);
    }
  }
}

