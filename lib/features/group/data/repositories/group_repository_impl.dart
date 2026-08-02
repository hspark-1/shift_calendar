// ignore_for_file: non_constant_identifier_names

import '../../../../core/utils/color_parser.dart';
import '../../domain/entities/group_models.dart';
import '../../domain/repositories/group_repository.dart';
import '../datasources/group_remote_datasource.dart';

class GroupRepositoryImpl implements GroupRepository {
  GroupRepositoryImpl(this._remote_data_source);

  final GroupRemoteDataSource _remote_data_source;

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _data(Map<String, dynamic> response) {
    return response['data'] as Map<String, dynamic>;
  }

  @override
  Future<PaginatedGroups> getGroups({int page = 1, int limit = 20}) async {
    final response = await _remote_data_source.getGroups(
      page: page,
      limit: limit,
    );
    final data = _data(response);
    return (
      groups: (data['groups'] as List)
          .map((item) => GroupSummary.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      pagination: GroupPagination.fromJson(
        data['pagination'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<CreateGroupResult> createGroup({
    required String name,
    String? timezone,
    List<String> invitee_user_ids = const [],
  }) async {
    final response = await _remote_data_source.createGroup(
      name: name.trim(),
      timezone: timezone,
      invitee_user_ids: invitee_user_ids,
    );
    final data = _data(response);
    return CreateGroupResult(
      group: GroupDetail.fromJson(data['group'] as Map<String, dynamic>),
      invitations: ((data['invitations'] as List?) ?? const [])
          .map(
            (item) =>
                GroupInvitationBrief.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  @override
  Future<GroupDetail> getGroupDetail(String group_id) async {
    final response = await _remote_data_source.getGroupDetail(group_id);
    return GroupDetail.fromJson(
      _data(response)['group'] as Map<String, dynamic>,
    );
  }

  @override
  Future<GroupCalendarRange> getGroupCalendarRange({
    required String group_id,
    required DateTime start_date,
    required DateTime end_date,
  }) async {
    final response = await _remote_data_source.getGroupCalendarRange(
      group_id: group_id,
      start_date: _formatDate(start_date),
      end_date: _formatDate(end_date),
    );
    final data = _data(response);
    final range = data['range'] as Map<String, dynamic>;
    return GroupCalendarRange(
      group: GroupCalendarHeader.fromJson(
        data['group'] as Map<String, dynamic>,
      ),
      start_date: range['start_date'] as String,
      end_date: range['end_date'] as String,
      members: (data['members'] as List)
          .map(
            (item) =>
                GroupCalendarMember.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      work_shifts: (data['work_shifts'] as List)
          .map((item) => _workShiftFromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      events: (data['events'] as List)
          .map((item) => _eventFromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  GroupCalendarWorkShift _workShiftFromJson(Map<String, dynamic> json) {
    return GroupCalendarWorkShift(
      owner_user_id: json['owner_user_id'] as String,
      work_shift_id: json['work_shift_id'] as String,
      work_date: json['work_date'] as String,
      shift_type_code: json['shift_type_code'] as String,
      shift_type_name: json['shift_type_name'] as String,
      shift_type_color: parseApiColorValue(json['shift_type_color']),
      start_time: json['start_time'] as String?,
      end_time: json['end_time'] as String?,
      note: json['note'] as String?,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }

  GroupCalendarEvent _eventFromJson(Map<String, dynamic> json) {
    return GroupCalendarEvent(
      owner_user_id: json['owner_user_id'] as String,
      event_id: json['event_id'] as String,
      title: json['title'] as String,
      memo: json['memo'] as String?,
      place: json['place'] as String?,
      all_day: json['all_day'] as bool,
      start_at: DateTime.parse(json['start_at'] as String).toUtc(),
      end_at: DateTime.parse(json['end_at'] as String).toUtc(),
      visibility_level: json['visibility_level'] as int,
    );
  }

  @override
  Future<List<GroupInvitationBrief>> createInvitations({
    required String group_id,
    required List<String> invitee_user_ids,
    String? message,
  }) async {
    final response = await _remote_data_source.createInvitations(
      group_id: group_id,
      invitee_user_ids: invitee_user_ids,
      message: message,
    );
    return (_data(response)['invitations'] as List)
        .map(
          (item) => GroupInvitationBrief.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<PaginatedGroupInvitations> getReceivedInvitations({
    GroupInvitationStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _remote_data_source.getReceivedInvitations(
      status: status?.api_value,
      page: page,
      limit: limit,
    );
    return _parseInvitations(response);
  }

  @override
  Future<RespondGroupInvitationResult> respondToInvitation({
    required String invitation_id,
    required String action,
  }) async {
    final response = await _remote_data_source.respondToInvitation(
      invitation_id: invitation_id,
      action: action,
    );
    final data = _data(response);
    final invitation = data['invitation'] as Map<String, dynamic>;
    return RespondGroupInvitationResult(
      invitation_id: invitation['invitation_id'] as String,
      status: GroupInvitationStatus.fromJson(invitation['status']),
      responded_at: DateTime.parse(invitation['responded_at'] as String),
      group: data['group'] == null
          ? null
          : GroupInvitationResponseGroup.fromJson(
              data['group'] as Map<String, dynamic>,
            ),
      notification: data['notification'] as Map<String, dynamic>?,
    );
  }

  @override
  Future<GroupDetail> updateGroup({
    required String group_id,
    String? name,
    String? timezone,
  }) async {
    final response = await _remote_data_source.updateGroup(
      group_id: group_id,
      name: name?.trim(),
      timezone: timezone,
    );
    return GroupDetail.fromJson(
      _data(response)['group'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteGroup(String group_id) {
    return _remote_data_source.deleteGroup(group_id);
  }

  @override
  Future<PaginatedGroupInvitations> getGroupInvitations({
    required String group_id,
    GroupInvitationStatus? status,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _remote_data_source.getGroupInvitations(
      group_id: group_id,
      status: status?.api_value,
      page: page,
      limit: limit,
    );
    return _parseInvitations(response);
  }

  PaginatedGroupInvitations _parseInvitations(Map<String, dynamic> response) {
    final data = _data(response);
    return (
      invitations: (data['invitations'] as List)
          .map((item) => GroupInvitation.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      pagination: GroupPagination.fromJson(
        data['pagination'] as Map<String, dynamic>,
      ),
    );
  }

  @override
  Future<void> cancelInvitation(String invitation_id) async {
    await _remote_data_source.cancelInvitation(invitation_id);
  }

  @override
  Future<void> removeMember({
    required String group_id,
    required String user_id,
  }) {
    return _remote_data_source.removeMember(
      group_id: group_id,
      user_id: user_id,
    );
  }

  @override
  Future<GroupMember> updateMemberRole({
    required String group_id,
    required String user_id,
    required GroupRole role,
  }) async {
    final response = await _remote_data_source.updateMemberRole(
      group_id: group_id,
      user_id: user_id,
      role: role.api_value,
    );
    return GroupMember.fromJson(
      _data(response)['member'] as Map<String, dynamic>,
    );
  }

  @override
  Future<void> leaveGroup(String group_id) {
    return _remote_data_source.leaveGroup(group_id);
  }

  @override
  Future<GroupDetail> transferOwnership({
    required String group_id,
    required String new_owner_user_id,
  }) async {
    final response = await _remote_data_source.transferOwnership(
      group_id: group_id,
      new_owner_user_id: new_owner_user_id,
    );
    return GroupDetail.fromJson(
      _data(response)['group'] as Map<String, dynamic>,
    );
  }
}
