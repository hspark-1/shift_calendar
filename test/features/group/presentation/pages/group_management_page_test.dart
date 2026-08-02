// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/constants/app_constants.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';
import 'package:shift_mate/features/group/presentation/pages/group_management_page.dart';

class _FakeGroupRepository implements GroupRepository {
  @override
  Future<GroupDetail> getGroupDetail(String group_id) async {
    return GroupDetail(
      group_id: group_id,
      name: '우리 병동',
      timezone: 'Asia/Seoul',
      my_role: GroupRole.owner,
      member_count: 2,
      members: [
        GroupMember(
          user_id: 'owner',
          name: '소유자',
          role: GroupRole.owner,
          joined_at: DateTime.utc(2026, 8, 1),
        ),
        GroupMember(
          user_id: 'member',
          name: '멤버',
          role: GroupRole.member,
          joined_at: DateTime.utc(2026, 8, 1, 1),
        ),
      ],
      created_by_user_id: 'owner',
      created_at: DateTime.utc(2026, 8, 1),
      updated_at: DateTime.utc(2026, 8, 1),
    );
  }

  @override
  Future<PaginatedGroupInvitations> getGroupInvitations({
    required String group_id,
    GroupInvitationStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    return (
      invitations: const <GroupInvitation>[],
      pagination: GroupPagination(
        page: page,
        limit: limit,
        total: 0,
        total_pages: 0,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFriendService extends FriendService {
  _FakeFriendService() : super(Dio());

  @override
  Future<FriendsResponse> getFriends({int page = 1, int limit = 20}) async {
    return FriendsResponse(
      success: true,
      data: FriendsData(
        friends: const [],
        pagination: PaginationInfo(
          page: page,
          limit: limit,
          total: 0,
          totalPages: 0,
        ),
      ),
    );
  }
}

void main() {
  testWidgets('P0 초대는 항상 보이고 P1 관리 액션은 플래그를 따른다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
          friendServiceProvider.overrideWithValue(_FakeFriendService()),
        ],
        child: const CupertinoApp(
          home: GroupManagementPage(group_id: 'group-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('group-management-invite-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('group-management-edit-button')),
      AppConstants.group_p1_enabled ? findsOneWidget : findsNothing,
    );
    expect(
      find.byKey(const ValueKey('group-transfer-owner-button')),
      AppConstants.group_p1_enabled ? findsOneWidget : findsNothing,
    );
    expect(
      find.byKey(const ValueKey('group-delete-button')),
      AppConstants.group_p1_enabled ? findsOneWidget : findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
