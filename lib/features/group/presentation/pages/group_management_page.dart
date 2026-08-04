// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../friend/data/models/friend_model.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../application/group_calendar_provider.dart';
import '../../application/group_providers.dart';
import '../../domain/entities/group_models.dart';
import 'group_edit_page.dart';
import 'group_invite_page.dart';

enum GroupManagementResult { membership_ended }

class GroupManagementPage extends ConsumerStatefulWidget {
  const GroupManagementPage({super.key, required this.group_id});

  final String group_id;

  @override
  ConsumerState<GroupManagementPage> createState() =>
      _GroupManagementPageState();
}

class _GroupManagementPageState extends ConsumerState<GroupManagementPage> {
  final Set<String> _processing_member_ids = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final detail_state = ref.read(groupDetailProvider(widget.group_id));
      if (detail_state.group == null) {
        ref.read(groupDetailProvider(widget.group_id).notifier).load();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final detail_state = ref.watch(groupDetailProvider(widget.group_id));
    final group = detail_state.group;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: const CupertinoNavigationBar(middle: Text('그룹 정보')),
      child: SafeArea(child: _buildBody(detail_state, group)),
    );
  }

  Widget _buildBody(GroupDetailState state, GroupDetail? group) {
    if (group == null && state.is_loading) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (group == null) {
      final message = state.error is ApiException
          ? (state.error! as ApiException).message
          : '그룹 정보를 불러오지 못했습니다.';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            CupertinoButton(
              onPressed: () => ref
                  .read(groupDetailProvider(widget.group_id).notifier)
                  .load(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    final can_manage =
        group.my_role == GroupRole.owner || group.my_role == GroupRole.admin;
    return ListView(
      padding: const EdgeInsets.all(AppTheme.spacing_md),
      children: [
        _buildGroupHeader(group, can_manage),
        const SizedBox(height: AppTheme.spacing_md),
        if (can_manage) ...[
          CupertinoButton.filled(
            key: const ValueKey('group-management-invite-button'),
            onPressed: group.member_count >= 20
                ? null
                : () => _openInvitePage(group),
            child: const Text('친구 초대'),
          ),
          const SizedBox(height: AppTheme.spacing_md),
        ],
        _buildMembersSection(group),
        if (AppConstants.group_p1_enabled && can_manage) ...[
          const SizedBox(height: AppTheme.spacing_md),
          _buildPendingInvitations(),
        ],
        if (AppConstants.group_p1_enabled) ...[
          const SizedBox(height: AppTheme.spacing_lg),
          _buildMembershipActions(group),
        ],
        const SizedBox(height: AppTheme.spacing_lg),
      ],
    );
  }

  Widget _buildGroupHeader(GroupDetail group, bool can_manage) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing_md),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppTheme.surface_container_color,
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.person_3_fill),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.name,
                  style: AppTheme.body_large.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${group.member_count}명 · ${group.timezone}',
                  style: AppTheme.body_small.copyWith(
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ],
            ),
          ),
          if (AppConstants.group_p1_enabled && can_manage)
            CupertinoButton(
              key: const ValueKey('group-management-edit-button'),
              padding: const EdgeInsets.all(8),
              onPressed: () => _openEditPage(group),
              child: const Icon(CupertinoIcons.pencil, size: 20),
            ),
        ],
      ),
    );
  }

  Widget _buildMembersSection(GroupDetail group) {
    final current_user_id = ref.watch(authProvider).user?.id;
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Text(
              '멤버 ${group.member_count}명',
              style: AppTheme.body_medium.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final member in group.members)
            _buildMemberRow(group, member, current_user_id),
        ],
      ),
    );
  }

  Widget _buildMemberRow(
    GroupDetail group,
    GroupMember member,
    String? current_user_id,
  ) {
    final has_actions = _canActOnMember(group, member, current_user_id);
    final processing = _processing_member_ids.contains(member.user_id);
    return CupertinoButton(
      key: ValueKey('group-management-member-${member.user_id}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onPressed: has_actions && !processing
          ? () => _showMemberActions(group, member)
          : null,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.surface_container_color,
              shape: BoxShape.circle,
            ),
            child: Text(member.name.isEmpty ? '?' : member.name[0]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.user_id == current_user_id
                  ? '${member.name} (나)'
                  : member.name,
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_color,
              ),
            ),
          ),
          Text(
            _roleLabel(member.role),
            style: AppTheme.body_small.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
          if (processing) ...[
            const SizedBox(width: 8),
            const CupertinoActivityIndicator(radius: 8),
          ] else if (has_actions) ...[
            const SizedBox(width: 8),
            const Icon(
              CupertinoIcons.chevron_forward,
              size: 14,
              color: AppTheme.outline_variant_color,
            ),
          ],
        ],
      ),
    );
  }

  bool _canActOnMember(
    GroupDetail group,
    GroupMember member,
    String? current_user_id,
  ) {
    if (!AppConstants.group_p1_enabled ||
        member.user_id == current_user_id ||
        member.role == GroupRole.owner) {
      return false;
    }
    if (group.my_role == GroupRole.owner) return true;
    return group.my_role == GroupRole.admin && member.role == GroupRole.member;
  }

  Widget _buildPendingInvitations() {
    final state = ref.watch(groupOutgoingInvitationsProvider(widget.group_id));
    if (!state.has_loaded) {
      if (!state.is_loading) _schedulePendingInvitationLoad();
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.error != null && state.invitations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppTheme.spacing_md),
        decoration: AppTheme.cardDecoration(),
        child: Column(
          children: [
            const Text('대기 중인 초대를 불러오지 못했습니다.'),
            CupertinoButton(
              onPressed: () => ref
                  .read(
                    groupOutgoingInvitationsProvider(widget.group_id).notifier,
                  )
                  .load(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (state.invitations.isEmpty) return const SizedBox.shrink();

    final friend_state = ref.watch(friendListProvider);
    if (friend_state.friends.isEmpty && !friend_state.isLoading) {
      _scheduleFriendLoad();
    }
    final friends = friend_state.friends;
    return Container(
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
            child: Text(
              '대기 중인 초대 ${state.invitations.length}건',
              style: AppTheme.body_medium.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          for (final invitation in state.invitations)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _friendName(friends, invitation.invitee_user_id),
                      style: AppTheme.body_medium,
                    ),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    onPressed:
                        state.processing_ids.contains(invitation.invitation_id)
                        ? null
                        : () => _cancelInvitation(invitation),
                    child: const Text('취소'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _schedulePendingInvitationLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = groupOutgoingInvitationsProvider(widget.group_id);
      final current_state = ref.read(provider);
      if (!current_state.has_loaded && !current_state.is_loading) {
        ref.read(provider.notifier).load();
      }
    });
  }

  void _scheduleFriendLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final friend_state = ref.read(friendListProvider);
      if (friend_state.friends.isEmpty && !friend_state.isLoading) {
        ref.read(friendListProvider.notifier).loadFriends(limit: 100);
      }
    });
  }

  Widget _buildMembershipActions(GroupDetail group) {
    if (group.my_role == GroupRole.owner) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoButton(
            key: const ValueKey('group-transfer-owner-button'),
            color: AppTheme.surface_container_color,
            onPressed: group.members.length <= 1
                ? null
                : () => _chooseTransferTarget(group),
            child: Text(
              '소유권 이전',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_color,
              ),
            ),
          ),
          const SizedBox(height: AppTheme.spacing_sm),
          CupertinoButton(
            key: const ValueKey('group-delete-button'),
            color: CupertinoColors.systemRed.withValues(alpha: 0.1),
            onPressed: () => _confirmDelete(group),
            child: const Text(
              '그룹 삭제',
              style: TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
        ],
      );
    }

    return CupertinoButton(
      key: const ValueKey('group-leave-button'),
      color: CupertinoColors.systemRed.withValues(alpha: 0.1),
      onPressed: () => _confirmLeave(group),
      child: const Text(
        '그룹 나가기',
        style: TextStyle(color: CupertinoColors.systemRed),
      ),
    );
  }

  Future<void> _openInvitePage(GroupDetail group) async {
    final sent = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (context) => GroupInvitePage(group: group),
      ),
    );
    if (!mounted || sent != true) return;
    if (AppConstants.group_p1_enabled) {
      await ref
          .read(groupOutgoingInvitationsProvider(widget.group_id).notifier)
          .load();
    }
  }

  Future<void> _openEditPage(GroupDetail group) async {
    final updated = await Navigator.of(context).push<bool>(
      CupertinoPageRoute<bool>(
        builder: (context) => GroupEditPage(group: group),
      ),
    );
    if (!mounted || updated != true) return;
    await ref
        .read(groupCalendarRangeProvider(widget.group_id).notifier)
        .refreshMonth(DateTime.now());
  }

  Future<void> _showMemberActions(GroupDetail group, GroupMember member) async {
    final selected_action = await showCupertinoModalPopup<String>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(member.name),
        actions: [
          if (group.my_role == GroupRole.owner)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop('role'),
              child: Text(
                member.role == GroupRole.admin ? '멤버로 변경' : '관리자로 변경',
              ),
            ),
          if (group.my_role == GroupRole.owner)
            CupertinoActionSheetAction(
              onPressed: () => Navigator.of(context).pop('transfer'),
              child: const Text('이 멤버에게 소유권 이전'),
            ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop('remove'),
            child: const Text('그룹에서 제거'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ),
    );
    if (!mounted || selected_action == null) return;
    switch (selected_action) {
      case 'role':
        await _changeMemberRole(member);
      case 'transfer':
        await _confirmTransfer(group, member);
      case 'remove':
        await _confirmRemoveMember(group, member);
    }
  }

  Future<void> _changeMemberRole(GroupMember member) async {
    final next_role = member.role == GroupRole.admin
        ? GroupRole.member
        : GroupRole.admin;
    await _runMemberOperation(
      member.user_id,
      () => ref
          .read(groupDetailProvider(widget.group_id).notifier)
          .updateMemberRole(member.user_id, next_role),
    );
  }

  Future<void> _confirmRemoveMember(
    GroupDetail group,
    GroupMember member,
  ) async {
    final confirmed = await _confirm(
      title: '멤버 제거',
      message: '${member.name}님을 ${group.name} 그룹에서 제거할까요?',
      action_label: '제거',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final success = await _runMemberOperation(
      member.user_id,
      () => ref
          .read(groupDetailProvider(widget.group_id).notifier)
          .removeMember(member.user_id),
    );
    if (success) await _refreshGroupCalendar();
  }

  Future<void> _chooseTransferTarget(GroupDetail group) async {
    final target = await showCupertinoModalPopup<GroupMember>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('새 소유자 선택'),
        actions: [
          for (final member in group.members)
            if (member.role != GroupRole.owner)
              CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(member),
                child: Text(member.name),
              ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('취소'),
        ),
      ),
    );
    if (!mounted || target == null) return;
    await _confirmTransfer(group, target);
  }

  Future<void> _confirmTransfer(GroupDetail group, GroupMember member) async {
    final confirmed = await _confirm(
      title: '소유권 이전',
      message: '${member.name}님에게 소유권을 이전하면 나는 관리자가 됩니다.',
      action_label: '이전',
    );
    if (!confirmed || !mounted) return;
    final success = await _runMemberOperation(
      member.user_id,
      () => ref
          .read(groupDetailProvider(widget.group_id).notifier)
          .transferOwnership(member.user_id),
    );
    if (success) {
      await ref.read(groupListProvider.notifier).loadGroups();
    }
  }

  Future<bool> _runMemberOperation(
    String user_id,
    Future<bool> Function() operation,
  ) async {
    if (_processing_member_ids.contains(user_id)) return false;
    setState(() => _processing_member_ids.add(user_id));
    final success = await operation();
    if (!mounted) return success;
    setState(() => _processing_member_ids.remove(user_id));
    if (!success) {
      final error = ref.read(groupDetailProvider(widget.group_id)).error;
      _showError(error is ApiException ? error.message : '멤버 정보를 변경하지 못했습니다.');
      await ref.read(groupDetailProvider(widget.group_id).notifier).load();
    }
    return success;
  }

  Future<void> _cancelInvitation(GroupInvitation invitation) async {
    final confirmed = await _confirm(
      title: '초대 취소',
      message: '대기 중인 그룹 초대를 취소할까요?',
      action_label: '취소하기',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final success = await ref
        .read(groupOutgoingInvitationsProvider(widget.group_id).notifier)
        .cancel(invitation.invitation_id);
    if (!success && mounted) {
      final error = ref
          .read(groupOutgoingInvitationsProvider(widget.group_id))
          .error;
      if (error is ApiException && error.code == 'GROUP_PERMISSION_DENIED') {
        await ref.read(groupDetailProvider(widget.group_id).notifier).load();
        if (!mounted) return;
      }
      _showError(error is ApiException ? error.message : '초대를 취소하지 못했습니다.');
    }
  }

  Future<void> _confirmDelete(GroupDetail group) async {
    final confirmed = await _confirm(
      title: '그룹 삭제',
      message: '${group.name} 그룹을 삭제하면 되돌릴 수 없습니다.',
      action_label: '삭제',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final success = await ref
        .read(groupDetailProvider(widget.group_id).notifier)
        .deleteGroup();
    if (!mounted) return;
    if (!success) {
      _showDetailError('그룹을 삭제하지 못했습니다.');
      return;
    }
    ref.read(groupListProvider.notifier).removeGroup(widget.group_id);
    Navigator.of(context).pop(GroupManagementResult.membership_ended);
  }

  Future<void> _confirmLeave(GroupDetail group) async {
    final confirmed = await _confirm(
      title: '그룹 나가기',
      message: '${group.name} 그룹에서 나갈까요?',
      action_label: '나가기',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final success = await ref
        .read(groupDetailProvider(widget.group_id).notifier)
        .leaveGroup();
    if (!mounted) return;
    if (!success) {
      _showDetailError('그룹에서 나가지 못했습니다.');
      return;
    }
    ref.read(groupListProvider.notifier).removeGroup(widget.group_id);
    Navigator.of(context).pop(GroupManagementResult.membership_ended);
  }

  Future<void> _refreshGroupCalendar() {
    return ref
        .read(groupCalendarRangeProvider(widget.group_id).notifier)
        .refreshMonth(DateTime.now());
  }

  Future<bool> _confirm({
    required String title,
    required String message,
    required String action_label,
    bool destructive = false,
  }) async {
    final result = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('닫기'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(action_label),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showDetailError(String fallback) {
    final error = ref.read(groupDetailProvider(widget.group_id)).error;
    _showError(error is ApiException ? error.message : fallback);
  }

  void _showError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  String _roleLabel(GroupRole role) {
    return switch (role) {
      GroupRole.owner => '소유자',
      GroupRole.admin => '관리자',
      GroupRole.member => '멤버',
      GroupRole.unknown => '알 수 없음',
    };
  }

  String _friendName(List<FriendModel> friends, String user_id) {
    for (final friend in friends) {
      if (friend.userId == user_id) return friend.name;
    }
    return '초대받은 친구';
  }
}
