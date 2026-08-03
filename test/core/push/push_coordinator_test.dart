// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/push/push_coordinator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('schema v1 알림 목적지 payload만 파싱한다', () {
    final envelope = PushMessageEnvelope.tryParse({
      'schema_version': '1',
      'notification_id': 'notification-1',
      'notification_type': 'FRIEND_REQUEST',
      'destination': 'NOTIFICATIONS',
    });

    expect(envelope?.notification_id, 'notification-1');
    expect(envelope?.notification_type, 'FRIEND_REQUEST');
    expect(
      PushMessageEnvelope.tryParse({
        'schema_version': '2',
        'notification_id': 'notification-1',
        'notification_type': 'FRIEND_REQUEST',
        'destination': 'NOTIFICATIONS',
      }),
      isNull,
    );
    expect(
      PushMessageEnvelope.tryParse({
        'schema_version': '1',
        'notification_id': 'notification-1',
        'notification_type': 'FRIEND_REQUEST',
        'destination': 'FRIENDS',
      }),
      isNull,
    );
  });

  test('최근 notification_id는 지속 저장해 foreground 중복을 제거한다', () async {
    SharedPreferences.setMockInitialValues({});
    final store = PushDeduplicationStore();

    expect(await store.markIfNew('notification-1'), isTrue);
    expect(await store.markIfNew('notification-1'), isFalse);
    expect(await store.markIfNew('notification-2'), isTrue);

    await store.clear();
    expect(await store.markIfNew('notification-1'), isTrue);
  });
}
