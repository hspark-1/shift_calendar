// ignore_for_file: non_constant_identifier_names

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../data/app_update_repository.dart';
import '../domain/app_update_policy.dart';

final appUpdateControllerProvider =
    StateNotifierProvider<AppUpdateController, AppUpdateState>((ref) {
      final platform = switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'IOS',
        TargetPlatform.android => 'ANDROID',
        _ => null,
      };
      return AppUpdateController(
        repository: platform == null || kIsWeb
            ? null
            : AppUpdateRepository(
                dio: ref.watch(dioProvider),
                platform: platform,
              ),
      );
    });

class AppUpdateState {
  final bool initialized;
  final bool checking;
  final AppUpdatePolicy? policy;
  final bool check_failed;
  final int compatibility_version;

  const AppUpdateState({
    this.initialized = false,
    this.checking = false,
    this.policy,
    this.check_failed = false,
    this.compatibility_version = AppConstants.api_compatibility_version,
  });

  bool get update_required =>
      policy?.requiresUpdate(compatibility_version) ?? false;
}

class AppUpdateController extends StateNotifier<AppUpdateState> {
  final AppUpdateRepository? repository;
  final int compatibility_version;
  Future<void>? _in_flight;

  AppUpdateController({
    required this.repository,
    this.compatibility_version = AppConstants.api_compatibility_version,
  }) : super(AppUpdateState(compatibility_version: compatibility_version));

  /// 앱 시작·복귀·수동 재확인의 동시 요청은 하나로 합친다.
  Future<void> check() {
    final pending = _in_flight;
    if (pending != null) return pending;
    final future = _check();
    _in_flight = future;
    future.whenComplete(() {
      if (identical(_in_flight, future)) _in_flight = null;
    });
    return future;
  }

  Future<void> _check() async {
    final source = repository;
    if (source == null) {
      if (mounted) {
        state = AppUpdateState(
          initialized: true,
          compatibility_version: compatibility_version,
        );
      }
      return;
    }
    var policy = state.policy;
    final was_initialized = state.initialized;
    state = AppUpdateState(
      initialized: was_initialized,
      checking: true,
      policy: policy,
      compatibility_version: compatibility_version,
    );
    if (!was_initialized) {
      try {
        policy = await source.readCachedPolicy();
      } on Object catch (error) {
        debugPrint('app_update_cache_read_failed: ${error.runtimeType}');
      }
      if (!mounted) return;
    }
    try {
      final fresh_policy = await source.fetchPolicy();
      if (!mounted) return;
      policy = fresh_policy;
      try {
        await source.savePolicy(fresh_policy);
      } on Object catch (error) {
        debugPrint('app_update_cache_write_failed: ${error.runtimeType}');
      }
      if (!mounted) return;
      state = AppUpdateState(
        initialized: true,
        policy: policy,
        compatibility_version: compatibility_version,
      );
    } on Object catch (error) {
      debugPrint('app_update_check_failed: ${error.runtimeType}');
      if (!mounted) return;
      // 조회 장애만으로 최초 사용자를 차단하지 않으며 이미 확인한 차단은 유지한다.
      state = AppUpdateState(
        initialized: true,
        policy: policy,
        check_failed: true,
        compatibility_version: compatibility_version,
      );
    }
  }
}
