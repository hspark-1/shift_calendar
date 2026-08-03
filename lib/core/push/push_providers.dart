// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/friend/presentation/providers/notification_provider.dart';
import 'device_remote_datasource.dart';
import 'installation_id_service.dart';
import 'push_coordinator.dart';

final pushFirebaseEnabledProvider = Provider<bool>((ref) => false);
final pendingPushNotificationNavigationProvider = StateProvider<bool>(
  (ref) => false,
);

final pushCoordinatorProvider = Provider<PushCoordinator>((ref) {
  return PushCoordinator(
    firebase_enabled: ref.watch(pushFirebaseEnabledProvider),
    device_remote_datasource: ref.watch(deviceRemoteDataSourceProvider),
    installation_id_service: ref.watch(installationIdServiceProvider),
    on_notification_tap: () async {
      ref.read(pendingPushNotificationNavigationProvider.notifier).state = true;
    },
    on_foreground_message: () async {
      await ref.read(notificationProvider.notifier).fetchUnreadCount();
    },
  );
});
