// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/friend/data/models/notification_model.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/data/services/notification_service.dart';
import 'package:shift_mate/features/friend/presentation/providers/notification_provider.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';

class _FakeGroupRepository implements GroupRepository {
  int response_call_count = 0;

  @override
  Future<RespondGroupInvitationResult> respondToInvitation({
    required String invitation_id,
    required String action,
  }) async {
    response_call_count += 1;
    return RespondGroupInvitationResult(
      invitation_id: invitation_id,
      status: action == 'accept'
          ? GroupInvitationStatus.accepted
          : GroupInvitationStatus.rejected,
      responded_at: DateTime.utc(2026, 8, 1, 4),
      group: const GroupInvitationResponseGroup(
        group_id: 'group-1',
        name: '우리 병동',
        timezone: 'Asia/Seoul',
        my_role: GroupRole.member,
        member_count: 2,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFriendService extends FriendService {
  _FakeFriendService() : super(Dio());

  int response_call_count = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

NotificationModel _groupInvitation() {
  return NotificationModel.fromJson({
    'notification_id': 'notification-1',
    'notification_type': 'GROUP_INVITATION',
    'title': '그룹 초대',
    'body': '우리 병동 그룹에 초대했습니다.',
    'payload': {
      'invitation_id': 'invitation-1',
      'group_id': 'group-1',
      'group_name': '우리 병동',
      'invitation_status': 'PENDING',
    },
    'actions': [
      {'type': 'accept', 'label': '수락'},
      {'type': 'reject', 'label': '거절'},
    ],
    'is_read': false,
    'read_at': null,
    'created_at': '2026-08-01T03:00:00.000Z',
  });
}

void main() {
  test('그룹 초대 수락은 친구 요청 API가 아니라 그룹 초대 API를 호출한다', () async {
    final group_repository = _FakeGroupRepository();
    final friend_service = _FakeFriendService();
    var accepted_callback_count = 0;
    final notifier = NotificationNotifier(
      NotificationService(Dio()),
      friend_service,
      group_repository: group_repository,
      on_group_invitation_responded: (accepted) async {
        if (accepted) accepted_callback_count += 1;
      },
    );
    addTearDown(notifier.dispose);
    final notification = _groupInvitation();

    final success = await notifier.handleNotificationAction(
      notification: notification,
      action: notification.findAction(NotificationActionType.accept)!,
    );

    expect(success, isTrue);
    expect(group_repository.response_call_count, 1);
    expect(friend_service.response_call_count, 0);
    expect(accepted_callback_count, 1);
    expect(
      notifier.state.notifications.single.notificationType,
      NotificationType.groupInvitationAccepted,
    );
    expect(notifier.state.notifications.single.actions, isEmpty);
    expect(notifier.state.notifications.single.isRead, isTrue);
  });
}
