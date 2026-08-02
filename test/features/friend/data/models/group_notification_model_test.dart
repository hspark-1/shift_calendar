// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/friend/data/models/notification_model.dart';

void main() {
  test('PENDING 그룹 초대이고 수락·거절 액션이 모두 있을 때만 응답 가능하다', () {
    final notification = NotificationModel.fromJson({
      'notification_id': 'notification-1',
      'notification_type': 'GROUP_INVITATION',
      'title': '그룹 초대',
      'body': '우리 병동 그룹에 초대했습니다.',
      'payload': {
        'invitation_id': 'invitation-1',
        'group_id': 'group-1',
        'group_name': '우리 병동',
        'invitation_status': 'PENDING',
        'expires_at': '2026-08-08T03:00:00.000Z',
      },
      'actions': [
        {'type': 'accept', 'label': '수락'},
        {'type': 'reject', 'label': '거절'},
      ],
      'is_read': false,
      'read_at': null,
      'created_at': '2026-08-01T03:00:00.000Z',
    });

    expect(notification.notificationType, NotificationType.groupInvitation);
    expect(notification.payload.invitation_id, 'invitation-1');
    expect(notification.payload.group_id, 'group-1');
    expect(notification.payload.expires_at?.isUtc, isTrue);
    expect(notification.is_pending_group_invitation, isTrue);
  });

  test('EXPIRED 그룹 초대는 타입이 유지돼도 응답 버튼 대상이 아니다', () {
    final notification = NotificationModel.fromJson({
      'notification_id': 'notification-2',
      'notification_type': 'GROUP_INVITATION',
      'title': '그룹 초대',
      'body': '만료된 초대입니다.',
      'payload': {
        'invitation_id': 'invitation-2',
        'invitation_status': 'EXPIRED',
      },
      'actions': <Map<String, dynamic>>[],
      'is_read': true,
      'read_at': '2026-08-08T03:00:00.000Z',
      'created_at': '2026-08-01T03:00:00.000Z',
    });

    expect(notification.notificationType, NotificationType.groupInvitation);
    expect(notification.is_pending_group_invitation, isFalse);
    expect(notification.hasActions, isFalse);
  });
}
