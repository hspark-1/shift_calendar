// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'device_remote_datasource.dart';
import 'firebase_environment_options.dart';
import 'installation_id_service.dart';

const String push_android_channel_id = 'shiftmate_high';

class PushMessageEnvelope {
  final String notification_id;
  final String notification_type;
  final String destination;

  const PushMessageEnvelope({
    required this.notification_id,
    required this.notification_type,
    required this.destination,
  });

  static PushMessageEnvelope? tryParse(Map<String, dynamic> data) {
    if (data['schema_version'] != '1' ||
        data['destination'] != 'NOTIFICATIONS') {
      return null;
    }
    final notification_id = data['notification_id'];
    final notification_type = data['notification_type'];
    if (notification_id is! String ||
        notification_id.isEmpty ||
        notification_type is! String ||
        notification_type.isEmpty) {
      return null;
    }
    return PushMessageEnvelope(
      notification_id: notification_id,
      notification_type: notification_type,
      destination: 'NOTIFICATIONS',
    );
  }
}

class PushDeduplicationStore {
  static const String _key = 'recent_push_notification_ids';
  static const int _limit = 50;

  Future<bool> markIfNew(String notification_id) async {
    final preferences = await SharedPreferences.getInstance();
    final recent_ids = preferences.getStringList(_key) ?? <String>[];
    if (recent_ids.contains(notification_id)) return false;
    final updated_ids = <String>[notification_id, ...recent_ids];
    await preferences.setStringList(
      _key,
      updated_ids.take(_limit).toList(growable: false),
    );
    return true;
  }

  Future<void> clear() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_key);
  }
}

Future<bool> initializePushFirebase() async {
  if (!FirebaseEnvironmentOptions.is_configured) {
    debugPrint('Firebase push 설정이 없어 푸시 기능을 비활성화합니다.');
    return false;
  }
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: FirebaseEnvironmentOptions.current);
    }
    return true;
  } catch (error) {
    debugPrint('Firebase 초기화 실패: ${error.runtimeType}');
    return false;
  }
}

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await initializePushFirebase();
}

class PushCoordinator {
  final bool firebase_enabled;
  final DeviceRemoteDataSource _device_remote_datasource;
  final InstallationIdService _installation_id_service;
  final PushDeduplicationStore _deduplication_store;
  final FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _local_notifications;
  final Future<void> Function() _on_notification_tap;
  final Future<void> Function() _on_foreground_message;

  StreamSubscription<String>? _token_subscription;
  StreamSubscription<RemoteMessage>? _foreground_subscription;
  StreamSubscription<RemoteMessage>? _opened_subscription;
  DateTime? _last_sync_at;
  bool _is_authenticated = false;
  bool _local_notifications_initialized = false;

  PushCoordinator({
    required this.firebase_enabled,
    required DeviceRemoteDataSource device_remote_datasource,
    required InstallationIdService installation_id_service,
    required Future<void> Function() on_notification_tap,
    required Future<void> Function() on_foreground_message,
    PushDeduplicationStore? deduplication_store,
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? local_notifications,
  }) : _device_remote_datasource = device_remote_datasource,
       _installation_id_service = installation_id_service,
       _on_notification_tap = on_notification_tap,
       _on_foreground_message = on_foreground_message,
       _deduplication_store = deduplication_store ?? PushDeduplicationStore(),
       _messaging = firebase_enabled
           ? (messaging ?? FirebaseMessaging.instance)
           : null,
       _local_notifications =
           local_notifications ?? FlutterLocalNotificationsPlugin();

  Future<void> startAuthenticated() async {
    if (!firebase_enabled || _is_authenticated || _messaging == null) return;
    _is_authenticated = true;
    try {
      await _initializeLocalNotifications();
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );

      _token_subscription = _messaging.onTokenRefresh.listen((token) {
        unawaited(syncCurrentDevice(force: true, provider_target: token));
      });
      _foreground_subscription = FirebaseMessaging.onMessage.listen((message) {
        unawaited(_handleForegroundMessage(message));
      });
      _opened_subscription = FirebaseMessaging.onMessageOpenedApp.listen((
        message,
      ) {
        unawaited(_handleRemoteTap(message));
      });

      await requestPermissionAndSync();
      final initial_message = await _messaging.getInitialMessage();
      if (initial_message != null) await _handleRemoteTap(initial_message);
    } catch (error) {
      debugPrint('푸시 인증 lifecycle 시작 실패: ${error.runtimeType}');
      await stopAuthenticated();
    }
  }

  Future<void> stopAuthenticated() async {
    _is_authenticated = false;
    await _token_subscription?.cancel();
    await _foreground_subscription?.cancel();
    await _opened_subscription?.cancel();
    _token_subscription = null;
    _foreground_subscription = null;
    _opened_subscription = null;
    _last_sync_at = null;
    await _deduplication_store.clear();
  }

  Future<void> requestPermissionAndSync() async {
    final messaging = _messaging;
    if (!_is_authenticated || messaging == null) return;
    try {
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final enabled =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!enabled) {
        await syncCurrentDevice(
          force: true,
          provider_target: null,
          permission_enabled: false,
        );
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        for (var attempt = 0; attempt < 10; attempt++) {
          if (await messaging.getAPNSToken() != null) break;
          await Future<void>.delayed(const Duration(milliseconds: 500));
        }
        if (await messaging.getAPNSToken() == null) {
          await syncCurrentDevice(
            force: true,
            provider_target: null,
            permission_enabled: true,
          );
          return;
        }
      }
      await syncCurrentDevice(
        force: true,
        provider_target: await messaging.getToken(),
        permission_enabled: true,
      );
    } catch (error) {
      debugPrint('푸시 권한/기기 동기화 실패: ${error.runtimeType}');
    }
  }

  Future<void> onAppResumed() async {
    await syncCurrentDevice();
  }

  Future<void> syncCurrentDevice({
    bool force = false,
    String? provider_target,
    bool? permission_enabled,
  }) async {
    final messaging = _messaging;
    if (!_is_authenticated || messaging == null) return;
    final now = DateTime.now();
    if (!force &&
        _last_sync_at != null &&
        now.difference(_last_sync_at!) < const Duration(minutes: 5)) {
      return;
    }

    try {
      final settings = await messaging.getNotificationSettings();
      final is_permission_enabled =
          permission_enabled ??
          (settings.authorizationStatus == AuthorizationStatus.authorized ||
              settings.authorizationStatus == AuthorizationStatus.provisional);
      final target = is_permission_enabled
          ? (provider_target ?? await messaging.getToken())
          : null;
      final package_info = await PackageInfo.fromPlatform();
      await _device_remote_datasource.syncCurrentDevice(
        installation_id: await _installation_id_service.getOrCreate(),
        platform: defaultTargetPlatform == TargetPlatform.iOS
            ? 'IOS'
            : 'ANDROID',
        provider_target: target,
        push_permission_enabled: is_permission_enabled,
        app_version: '${package_info.version}+${package_info.buildNumber}',
      );
      _last_sync_at = now;
    } catch (error) {
      debugPrint('푸시 기기 동기화 실패: ${error.runtimeType}');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    if (_local_notifications_initialized) return;
    const initialization_settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _local_notifications.initialize(
      settings: initialization_settings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload == 'NOTIFICATIONS') {
          unawaited(_on_notification_tap());
        }
      },
    );
    const channel = AndroidNotificationChannel(
      push_android_channel_id,
      'ShiftMate 알림',
      description: '친구 요청과 그룹 초대 알림',
      importance: Importance.high,
      playSound: true,
    );
    await _local_notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    _local_notifications_initialized = true;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final envelope = PushMessageEnvelope.tryParse(message.data);
    if (envelope == null ||
        !await _deduplication_store.markIfNew(envelope.notification_id)) {
      return;
    }
    await _on_foreground_message();
    final notification = message.notification;
    if (notification == null) return;
    await _local_notifications.show(
      id: _stableNotificationId(envelope.notification_id),
      title: notification.title,
      body: notification.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          push_android_channel_id,
          'ShiftMate 알림',
          channelDescription: '친구 요청과 그룹 초대 알림',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: false,
          presentSound: true,
        ),
      ),
      payload: 'NOTIFICATIONS',
    );
  }

  Future<void> _handleRemoteTap(RemoteMessage message) async {
    if (PushMessageEnvelope.tryParse(message.data) == null) return;
    await _on_notification_tap();
  }

  int _stableNotificationId(String value) {
    var hash = 0x811c9dc5;
    for (final code_unit in value.codeUnits) {
      hash ^= code_unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}
