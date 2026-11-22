// ignore_for_file: non_constant_identifier_names

import 'package:firebase_core/firebase_core.dart';

import '../network/api_exception.dart';
import '../push/firebase_environment_options.dart';

/// 푸시와 전화 인증이 동일한 환경의 default app 초기화를 공유한다.
class FirebaseInitializer {
  static Future<FirebaseApp>? _initializing;

  static Future<FirebaseApp> ensureInitialized() async {
    if (!FirebaseEnvironmentOptions.is_configured) {
      throw ApiException(
        code: 'PHONE_AUTH_NOT_CONFIGURED',
        message: '휴대폰 인증을 준비하지 못했어요. 잠시 후 다시 시도해주세요.',
      );
    }
    final current = Firebase.apps.where((app) => app.name == '[DEFAULT]');
    if (current.isNotEmpty) {
      final app = current.first;
      if (app.options.projectId != FirebaseEnvironmentOptions.project_id ||
          app.options.appId != FirebaseEnvironmentOptions.app_id) {
        throw ApiException(
          code: 'PHONE_AUTH_CONFIGURATION_MISMATCH',
          message: '휴대폰 인증 설정을 확인하지 못했어요.',
        );
      }
      return app;
    }
    final pending = _initializing;
    if (pending != null) return pending;
    final future = Firebase.initializeApp(
      options: FirebaseEnvironmentOptions.current,
    );
    _initializing = future;
    try {
      return await future;
    } finally {
      if (identical(_initializing, future)) _initializing = null;
    }
  }
}
