// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../network/api_client.dart';

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  return DeviceRemoteDataSource(ref.watch(dioProvider));
});

class DeviceRemoteDataSource {
  final Dio _dio;

  DeviceRemoteDataSource(this._dio);

  Future<void> syncCurrentDevice({
    required String installation_id,
    required String platform,
    required String? provider_target,
    required bool push_permission_enabled,
    required String app_version,
  }) async {
    await _dio.put(
      ApiConstants.devices_current,
      data: {
        'installation_id': installation_id,
        'platform': platform,
        'provider_target': provider_target,
        'push_permission_enabled': push_permission_enabled,
        'app_version': app_version,
      },
    );
  }
}
