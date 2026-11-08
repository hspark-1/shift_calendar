// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_error_handler.dart';
import '../domain/app_update_policy.dart';

class AppUpdateRepository {
  final Dio dio;
  final String platform;
  final Future<SharedPreferences> Function() preferences_loader;

  AppUpdateRepository({
    required this.dio,
    required this.platform,
    Future<SharedPreferences> Function()? preferences_loader,
  }) : preferences_loader = preferences_loader ?? SharedPreferences.getInstance;

  // Stage/운영/로컬 정책을 서로 공유하지 않는다.
  String get cache_key =>
      'app_update_policy_v1:${dio.options.baseUrl}:$platform';

  Future<AppUpdatePolicy?> readCachedPolicy() async {
    final preferences = await preferences_loader();
    final raw = preferences.getString(cache_key);
    if (raw == null) return null;
    try {
      return AppUpdatePolicy.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
        expected_platform: platform,
      );
    } on Object {
      await preferences.remove(cache_key);
      return null;
    }
  }

  Future<void> savePolicy(AppUpdatePolicy policy) async {
    final preferences = await preferences_loader();
    await preferences.setString(cache_key, jsonEncode(policy.toJson()));
  }

  Future<AppUpdatePolicy> fetchPolicy() async {
    final cancel_token = CancelToken();
    try {
      final response = await dio
          .get<dynamic>(
            ApiConstants.app_version_policy,
            queryParameters: {'platform': platform},
            options: Options(
              followRedirects: false,
              receiveTimeout: const Duration(seconds: 5),
              headers: {'Cache-Control': 'no-cache'},
            ),
            cancelToken: cancel_token,
          )
          .timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              cancel_token.cancel('app_update_policy_timeout');
              throw TimeoutException('앱 호환 정책 조회 시간 초과');
            },
          );
      final body = response.data;
      if (body is! Map<String, dynamic> ||
          body['success'] != true ||
          body['data'] is! Map<String, dynamic>) {
        throw const FormatException('유효하지 않은 앱 호환 정책 응답입니다.');
      }
      return AppUpdatePolicy.fromJson(
        body['data'] as Map<String, dynamic>,
        expected_platform: platform,
      );
    } on DioException catch (error) {
      throw handleApiError(error);
    }
  }
}
