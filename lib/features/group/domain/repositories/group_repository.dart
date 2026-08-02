// ignore_for_file: non_constant_identifier_names

import '../entities/group_models.dart';

typedef PaginatedGroups = ({
  List<GroupSummary> groups,
  GroupPagination pagination,
});

typedef PaginatedGroupInvitations = ({
  List<GroupInvitation> invitations,
  GroupPagination pagination,
});

abstract interface class GroupRepository {
  Future<PaginatedGroups> getGroups({int page = 1, int limit = 20});

  Future<CreateGroupResult> createGroup({
    required String name,
    String? timezone,
    List<String> invitee_user_ids = const [],
  });

  Future<GroupDetail> getGroupDetail(String group_id);

  Future<GroupCalendarRange> getGroupCalendarRange({
    required String group_id,
    required DateTime start_date,
    required DateTime end_date,
  });

  Future<List<GroupInvitationBrief>> createInvitations({
    required String group_id,
    required List<String> invitee_user_ids,
    String? message,
  });

  Future<PaginatedGroupInvitations> getReceivedInvitations({
    GroupInvitationStatus? status,
    int page = 1,
    int limit = 20,
  });

  Future<RespondGroupInvitationResult> respondToInvitation({
    required String invitation_id,
    required String action,
  });

  Future<GroupDetail> updateGroup({
    required String group_id,
    String? name,
    String? timezone,
  });

  Future<void> deleteGroup(String group_id);

  Future<PaginatedGroupInvitations> getGroupInvitations({
    required String group_id,
    GroupInvitationStatus? status,
    int page = 1,
    int limit = 20,
  });

  Future<void> cancelInvitation(String invitation_id);

  Future<void> removeMember({
    required String group_id,
    required String user_id,
  });

  Future<GroupMember> updateMemberRole({
    required String group_id,
    required String user_id,
    required GroupRole role,
  });

  Future<void> leaveGroup(String group_id);

  Future<GroupDetail> transferOwnership({
    required String group_id,
    required String new_owner_user_id,
  });
}
