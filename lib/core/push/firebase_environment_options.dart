// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Debug는 Stage, Profile/Release는 Production Firebase 프로젝트를 사용한다.
/// 실제 프로젝트 식별자는 빌드 시스템의 --dart-define으로 주입한다.
class FirebaseEnvironmentOptions {
  FirebaseEnvironmentOptions._();

  static const String _stage_project_id = String.fromEnvironment(
    'FIREBASE_STAGE_PROJECT_ID',
  );
  static const String _stage_sender_id = String.fromEnvironment(
    'FIREBASE_STAGE_MESSAGING_SENDER_ID',
  );
  static const String _stage_android_api_key = String.fromEnvironment(
    'FIREBASE_STAGE_ANDROID_API_KEY',
  );
  static const String _stage_android_app_id = String.fromEnvironment(
    'FIREBASE_STAGE_ANDROID_APP_ID',
  );
  static const String _stage_ios_api_key = String.fromEnvironment(
    'FIREBASE_STAGE_IOS_API_KEY',
  );
  static const String _stage_ios_app_id = String.fromEnvironment(
    'FIREBASE_STAGE_IOS_APP_ID',
  );
  static const String _stage_storage_bucket = String.fromEnvironment(
    'FIREBASE_STAGE_STORAGE_BUCKET',
  );

  static const String _prod_project_id = String.fromEnvironment(
    'FIREBASE_PROD_PROJECT_ID',
  );
  static const String _prod_sender_id = String.fromEnvironment(
    'FIREBASE_PROD_MESSAGING_SENDER_ID',
  );
  static const String _prod_android_api_key = String.fromEnvironment(
    'FIREBASE_PROD_ANDROID_API_KEY',
  );
  static const String _prod_android_app_id = String.fromEnvironment(
    'FIREBASE_PROD_ANDROID_APP_ID',
  );
  static const String _prod_ios_api_key = String.fromEnvironment(
    'FIREBASE_PROD_IOS_API_KEY',
  );
  static const String _prod_ios_app_id = String.fromEnvironment(
    'FIREBASE_PROD_IOS_APP_ID',
  );
  static const String _prod_storage_bucket = String.fromEnvironment(
    'FIREBASE_PROD_STORAGE_BUCKET',
  );

  static bool get is_stage => kDebugMode;

  static String get project_id =>
      is_stage ? _stage_project_id : _prod_project_id;
  static String get sender_id => is_stage ? _stage_sender_id : _prod_sender_id;
  static String get storage_bucket =>
      is_stage ? _stage_storage_bucket : _prod_storage_bucket;

  static String get api_key {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return is_stage ? _stage_ios_api_key : _prod_ios_api_key;
    }
    return is_stage ? _stage_android_api_key : _prod_android_api_key;
  }

  static String get app_id {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return is_stage ? _stage_ios_app_id : _prod_ios_app_id;
    }
    return is_stage ? _stage_android_app_id : _prod_android_app_id;
  }

  static bool get is_configured =>
      project_id.isNotEmpty &&
      sender_id.isNotEmpty &&
      api_key.isNotEmpty &&
      app_id.isNotEmpty;

  static FirebaseOptions get current {
    if (!is_configured) {
      throw StateError('현재 빌드 환경의 Firebase 설정이 없습니다.');
    }
    return FirebaseOptions(
      apiKey: api_key,
      appId: app_id,
      messagingSenderId: sender_id,
      projectId: project_id,
      storageBucket: storage_bucket.isEmpty ? null : storage_bucket,
      iosBundleId: defaultTargetPlatform == TargetPlatform.iOS
          ? 'com.hspark.shiftmate'
          : null,
    );
  }
}
