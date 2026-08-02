// ignore_for_file: constant_identifier_names, non_constant_identifier_names

enum GroupRole {
  owner,
  admin,
  member,
  unknown;

  static GroupRole fromJson(Object? value) {
    return switch (value) {
      'OWNER' => GroupRole.owner,
      'ADMIN' => GroupRole.admin,
      'MEMBER' => GroupRole.member,
      _ => GroupRole.unknown,
    };
  }

  String get api_value => switch (this) {
    GroupRole.owner => 'OWNER',
    GroupRole.admin => 'ADMIN',
    GroupRole.member => 'MEMBER',
    GroupRole.unknown => 'UNKNOWN',
  };
}

enum GroupInvitationStatus {
  pending,
  accepted,
  rejected,
  canceled,
  expired,
  unknown;

  static GroupInvitationStatus fromJson(Object? value) {
    return switch (value) {
      'PENDING' => GroupInvitationStatus.pending,
      'ACCEPTED' => GroupInvitationStatus.accepted,
      'REJECTED' => GroupInvitationStatus.rejected,
      'CANCELED' => GroupInvitationStatus.canceled,
      'EXPIRED' => GroupInvitationStatus.expired,
      _ => GroupInvitationStatus.unknown,
    };
  }

  String get api_value => switch (this) {
    GroupInvitationStatus.pending => 'PENDING',
    GroupInvitationStatus.accepted => 'ACCEPTED',
    GroupInvitationStatus.rejected => 'REJECTED',
    GroupInvitationStatus.canceled => 'CANCELED',
    GroupInvitationStatus.expired => 'EXPIRED',
    GroupInvitationStatus.unknown => 'UNKNOWN',
  };
}

enum CalendarAccess {
  self,
  visible,
  denied,
  unknown;

  static CalendarAccess fromJson(Object? value) {
    return switch (value) {
      'SELF' => CalendarAccess.self,
      'VISIBLE' => CalendarAccess.visible,
      'DENIED' => CalendarAccess.denied,
      _ => CalendarAccess.unknown,
    };
  }
}

class GroupPagination {
  const GroupPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.total_pages,
  });

  final int page;
  final int limit;
  final int total;
  final int total_pages;

  factory GroupPagination.fromJson(Map<String, dynamic> json) {
    return GroupPagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      total_pages: json['total_pages'] as int,
    );
  }
}

class GroupUserSummary {
  const GroupUserSummary({
    required this.user_id,
    required this.name,
    this.profile_image_url,
  });

  final String user_id;
  final String name;
  final String? profile_image_url;

  factory GroupUserSummary.fromJson(Map<String, dynamic> json) {
    return GroupUserSummary(
      user_id: json['user_id'] as String,
      name: json['name'] as String,
      profile_image_url: json['profile_image_url'] as String?,
    );
  }
}

class GroupMember extends GroupUserSummary {
  const GroupMember({
    required super.user_id,
    required super.name,
    super.profile_image_url,
    required this.role,
    required this.joined_at,
  });

  final GroupRole role;
  final DateTime joined_at;

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      user_id: json['user_id'] as String,
      name: json['name'] as String,
      profile_image_url: json['profile_image_url'] as String?,
      role: GroupRole.fromJson(json['role']),
      joined_at: DateTime.parse(json['joined_at'] as String),
    );
  }
}

class GroupSummary {
  const GroupSummary({
    required this.group_id,
    required this.name,
    required this.timezone,
    required this.my_role,
    required this.member_count,
    required this.members_preview,
    required this.created_at,
    required this.updated_at,
  });

  final String group_id;
  final String name;
  final String timezone;
  final GroupRole my_role;
  final int member_count;
  final List<GroupUserSummary> members_preview;
  final DateTime created_at;
  final DateTime updated_at;

  factory GroupSummary.fromJson(Map<String, dynamic> json) {
    return GroupSummary(
      group_id: json['group_id'] as String,
      name: json['name'] as String,
      timezone: json['timezone'] as String,
      my_role: GroupRole.fromJson(json['my_role']),
      member_count: json['member_count'] as int,
      members_preview: ((json['members_preview'] as List?) ?? const [])
          .map(
            (item) => GroupUserSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class GroupDetail {
  const GroupDetail({
    required this.group_id,
    required this.name,
    required this.timezone,
    required this.my_role,
    required this.member_count,
    required this.members,
    required this.created_by_user_id,
    required this.created_at,
    required this.updated_at,
  });

  final String group_id;
  final String name;
  final String timezone;
  final GroupRole my_role;
  final int member_count;
  final List<GroupMember> members;
  final String created_by_user_id;
  final DateTime created_at;
  final DateTime updated_at;

  factory GroupDetail.fromJson(Map<String, dynamic> json) {
    return GroupDetail(
      group_id: json['group_id'] as String,
      name: json['name'] as String,
      timezone: json['timezone'] as String,
      my_role: GroupRole.fromJson(json['my_role']),
      member_count: json['member_count'] as int,
      members: (json['members'] as List)
          .map((item) => GroupMember.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      created_by_user_id: json['created_by_user_id'] as String,
      created_at: DateTime.parse(json['created_at'] as String),
      updated_at: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class GroupInvitationBrief {
  const GroupInvitationBrief({
    required this.invitation_id,
    required this.invitee_user_id,
    required this.status,
    required this.expires_at,
  });

  final String invitation_id;
  final String invitee_user_id;
  final GroupInvitationStatus status;
  final DateTime expires_at;

  factory GroupInvitationBrief.fromJson(Map<String, dynamic> json) {
    return GroupInvitationBrief(
      invitation_id: json['invitation_id'] as String,
      invitee_user_id: json['invitee_user_id'] as String,
      status: GroupInvitationStatus.fromJson(json['status']),
      expires_at: DateTime.parse(json['expires_at'] as String),
    );
  }
}

class GroupInvitationGroup {
  const GroupInvitationGroup({
    required this.group_id,
    required this.name,
    required this.member_count,
  });

  final String group_id;
  final String name;
  final int member_count;

  factory GroupInvitationGroup.fromJson(Map<String, dynamic> json) {
    return GroupInvitationGroup(
      group_id: json['group_id'] as String,
      name: json['name'] as String,
      member_count: json['member_count'] as int,
    );
  }
}

class GroupInvitation {
  const GroupInvitation({
    required this.invitation_id,
    required this.group,
    required this.inviter,
    required this.invitee_user_id,
    required this.status,
    this.message,
    required this.expires_at,
    required this.created_at,
    this.responded_at,
  });

  final String invitation_id;
  final GroupInvitationGroup group;
  final GroupUserSummary inviter;
  final String invitee_user_id;
  final GroupInvitationStatus status;
  final String? message;
  final DateTime expires_at;
  final DateTime created_at;
  final DateTime? responded_at;

  factory GroupInvitation.fromJson(Map<String, dynamic> json) {
    return GroupInvitation(
      invitation_id: json['invitation_id'] as String,
      group: GroupInvitationGroup.fromJson(
        json['group'] as Map<String, dynamic>,
      ),
      inviter: GroupUserSummary.fromJson(
        json['inviter'] as Map<String, dynamic>,
      ),
      invitee_user_id: json['invitee_user_id'] as String,
      status: GroupInvitationStatus.fromJson(json['status']),
      message: json['message'] as String?,
      expires_at: DateTime.parse(json['expires_at'] as String),
      created_at: DateTime.parse(json['created_at'] as String),
      responded_at: json['responded_at'] == null
          ? null
          : DateTime.parse(json['responded_at'] as String),
    );
  }
}

class GroupCalendarHeader {
  const GroupCalendarHeader({
    required this.group_id,
    required this.name,
    required this.timezone,
  });

  final String group_id;
  final String name;
  final String timezone;

  factory GroupCalendarHeader.fromJson(Map<String, dynamic> json) {
    return GroupCalendarHeader(
      group_id: json['group_id'] as String,
      name: json['name'] as String,
      timezone: json['timezone'] as String,
    );
  }
}

class GroupCalendarMember extends GroupMember {
  const GroupCalendarMember({
    required super.user_id,
    required super.name,
    super.profile_image_url,
    required super.role,
    required super.joined_at,
    required this.calendar_access,
  });

  final CalendarAccess calendar_access;

  factory GroupCalendarMember.fromJson(Map<String, dynamic> json) {
    return GroupCalendarMember(
      user_id: json['user_id'] as String,
      name: json['name'] as String,
      profile_image_url: json['profile_image_url'] as String?,
      role: GroupRole.fromJson(json['role']),
      joined_at: DateTime.parse(json['joined_at'] as String),
      calendar_access: CalendarAccess.fromJson(json['calendar_access']),
    );
  }
}

class GroupCalendarWorkShift {
  const GroupCalendarWorkShift({
    required this.owner_user_id,
    required this.work_shift_id,
    required this.work_date,
    required this.shift_type_code,
    required this.shift_type_name,
    this.shift_type_color,
    this.start_time,
    this.end_time,
    this.note,
    required this.created_at,
    required this.updated_at,
  });

  final String owner_user_id;
  final String work_shift_id;
  final String work_date;
  final String shift_type_code;
  final String shift_type_name;
  final int? shift_type_color;
  final String? start_time;
  final String? end_time;
  final String? note;
  final DateTime created_at;
  final DateTime updated_at;
}

class GroupCalendarEvent {
  const GroupCalendarEvent({
    required this.owner_user_id,
    required this.event_id,
    required this.title,
    this.memo,
    this.place,
    required this.all_day,
    required this.start_at,
    required this.end_at,
    required this.visibility_level,
  });

  final String owner_user_id;
  final String event_id;
  final String title;
  final String? memo;
  final String? place;
  final bool all_day;
  final DateTime start_at;
  final DateTime end_at;
  final int visibility_level;
}

class GroupCalendarRange {
  const GroupCalendarRange({
    required this.group,
    required this.start_date,
    required this.end_date,
    required this.members,
    required this.work_shifts,
    required this.events,
  });

  final GroupCalendarHeader group;
  final String start_date;
  final String end_date;
  final List<GroupCalendarMember> members;
  final List<GroupCalendarWorkShift> work_shifts;
  final List<GroupCalendarEvent> events;
}

class CreateGroupResult {
  const CreateGroupResult({required this.group, required this.invitations});

  final GroupDetail group;
  final List<GroupInvitationBrief> invitations;
}

class RespondGroupInvitationResult {
  const RespondGroupInvitationResult({
    required this.invitation_id,
    required this.status,
    required this.responded_at,
    this.group,
    this.notification,
  });

  final String invitation_id;
  final GroupInvitationStatus status;
  final DateTime responded_at;
  final GroupInvitationResponseGroup? group;
  final Map<String, dynamic>? notification;
}

class GroupInvitationResponseGroup {
  const GroupInvitationResponseGroup({
    required this.group_id,
    required this.name,
    required this.timezone,
    required this.my_role,
    required this.member_count,
  });

  final String group_id;
  final String name;
  final String timezone;
  final GroupRole? my_role;
  final int member_count;

  factory GroupInvitationResponseGroup.fromJson(Map<String, dynamic> json) {
    final role_value = json['my_role'];
    return GroupInvitationResponseGroup(
      group_id: json['group_id'] as String,
      name: json['name'] as String,
      timezone: json['timezone'] as String,
      my_role: role_value == null ? null : GroupRole.fromJson(role_value),
      member_count: json['member_count'] as int,
    );
  }
}
