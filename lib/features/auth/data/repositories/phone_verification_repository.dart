// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error_handler.dart';
import '../../../../core/network/api_exception.dart';
import '../models/phone_verification_models.dart';

final phone_verification_repository_provider =
    Provider<PhoneVerificationRepository>(
      (ref) => RemotePhoneVerificationRepository(ref.watch(dioProvider)),
    );

abstract class PhoneVerificationRepository {
  Future<PhoneChallenge> createChallenge({
    required String phone,
    required PhoneVerificationPurpose purpose,
    required String idempotency_key,
  });

  Future<PhoneVerificationProof> verifyFirebasePhone({
    required String challenge_id,
    required String firebase_id_token,
    required String idempotency_key,
  });
}

class RemotePhoneVerificationRepository implements PhoneVerificationRepository {
  final Dio _dio;
  RemotePhoneVerificationRepository(this._dio);

  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body,
    String idempotency_key,
  ) async {
    try {
      final response = await _dio.post<Object?>(
        path,
        data: body,
        options: Options(headers: {'Idempotency-Key': idempotency_key}),
      );
      final wrapper = response.data;
      if (wrapper is! Map<String, dynamic> ||
          wrapper['success'] != true ||
          wrapper['data'] is! Map<String, dynamic>) {
        throw const FormatException('Invalid phone response');
      }
      return wrapper['data'] as Map<String, dynamic>;
    } on DioException catch (error) {
      if (error.response?.statusCode == 404 ||
          error.response?.statusCode == 501) {
        throw ApiException(
          code: 'PHONE_VERIFICATION_UNAVAILABLE',
          message: '휴대폰 인증을 준비 중이에요. 잠시 후 다시 시도해주세요.',
          statusCode: error.response?.statusCode,
        );
      }
      throw handleApiError(error);
    }
  }

  @override
  Future<PhoneChallenge> createChallenge({
    required String phone,
    required PhoneVerificationPurpose purpose,
    required String idempotency_key,
  }) async {
    try {
      return PhoneChallenge.fromJson(
        await _post(ApiConstants.auth_phone_challenges, {
          'phone': phone,
          'purpose': purpose.api_value,
        }, idempotency_key),
      );
    } on FormatException {
      throw _invalidResponse();
    }
  }

  @override
  Future<PhoneVerificationProof> verifyFirebasePhone({
    required String challenge_id,
    required String firebase_id_token,
    required String idempotency_key,
  }) async {
    try {
      return PhoneVerificationProof.fromJson(
        await _post(ApiConstants.auth_phone_verify, {
          'challenge_id': challenge_id,
          'firebase_id_token': firebase_id_token,
        }, idempotency_key),
      );
    } on FormatException {
      throw _invalidResponse();
    }
  }

  ApiException _invalidResponse() => ApiException(
    code: 'PHONE_VERIFICATION_INVALID_RESPONSE',
    message: '인증 결과를 확인하지 못했어요. 다시 시도해주세요.',
  );
}
