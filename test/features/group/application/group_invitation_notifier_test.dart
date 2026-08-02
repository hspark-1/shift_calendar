// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';

class _ExpiredInvitationRepository implements GroupRepository {
  int received_call_count = 0;

  @override
  Future<PaginatedGroupInvitations> getReceivedInvitations({
    GroupInvitationStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    received_call_count += 1;
    return (
      invitations: received_call_count == 1
          ? [_pendingInvitation()]
          : const <GroupInvitation>[],
      pagination: GroupPagination(
        page: page,
        limit: limit,
        total: received_call_count == 1 ? 1 : 0,
        total_pages: received_call_count == 1 ? 1 : 0,
      ),
    );
  }

  @override
  Future<RespondGroupInvitationResult> respondToInvitation({
    required String invitation_id,
    required String action,
  }) {
    throw ApiException(
      code: 'GROUP_INVITATION_EXPIRED',
      message: '그룹 초대가 만료되었습니다.',
      statusCode: 409,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GroupInvitation _pendingInvitation() {
  return GroupInvitation(
    invitation_id: 'invitation-1',
    group: const GroupInvitationGroup(
      group_id: 'group-1',
      name: '우리 병동',
      member_count: 1,
    ),
    inviter: const GroupUserSummary(user_id: 'owner', name: '소유자'),
    invitee_user_id: 'me',
    status: GroupInvitationStatus.pending,
    expires_at: DateTime.utc(2026, 8, 8),
    created_at: DateTime.utc(2026, 8, 1),
  );
}

void main() {
  test('초대 만료 409는 서버 목록을 다시 읽고 처리 중 상태를 해제한다', () async {
    final repository = _ExpiredInvitationRepository();
    final notifier = ReceivedGroupInvitationsNotifier(
      repository: repository,
      on_group_accepted: () async {},
    );
    addTearDown(notifier.dispose);
    await notifier.load();

    final success = await notifier.respond(
      invitation_id: 'invitation-1',
      action: 'accept',
    );

    expect(success, isFalse);
    expect(repository.received_call_count, 2);
    expect(notifier.state.invitations, isEmpty);
    expect(notifier.state.processing_ids, isEmpty);
    expect(
      (notifier.state.error! as ApiException).code,
      'GROUP_INVITATION_EXPIRED',
    );
  });
}
