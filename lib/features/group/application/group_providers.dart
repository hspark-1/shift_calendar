// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../data/datasources/group_remote_datasource.dart';
import '../data/repositories/group_repository_impl.dart';
import '../domain/entities/group_models.dart';
import '../domain/repositories/group_repository.dart';

final groupRemoteDataSourceProvider = Provider<GroupRemoteDataSource>((ref) {
  return DioGroupRemoteDataSource(ref.watch(dioProvider));
});

final groupRepositoryProvider = Provider<GroupRepository>((ref) {
  return GroupRepositoryImpl(ref.watch(groupRemoteDataSourceProvider));
});

class GroupListState {
  const GroupListState({
    this.groups = const [],
    this.pagination,
    this.is_loading = false,
    this.error,
  });

  final List<GroupSummary> groups;
  final GroupPagination? pagination;
  final bool is_loading;
  final Object? error;

  GroupListState copyWith({
    List<GroupSummary>? groups,
    GroupPagination? pagination,
    bool? is_loading,
    Object? error,
    bool clear_error = false,
  }) {
    return GroupListState(
      groups: groups ?? this.groups,
      pagination: pagination ?? this.pagination,
      is_loading: is_loading ?? this.is_loading,
      error: clear_error ? null : error ?? this.error,
    );
  }
}

final groupListProvider =
    StateNotifierProvider<GroupListNotifier, GroupListState>((ref) {
      return GroupListNotifier(ref.watch(groupRepositoryProvider));
    });

class GroupListNotifier extends StateNotifier<GroupListState> {
  GroupListNotifier(this._repository) : super(const GroupListState());

  final GroupRepository _repository;

  Future<void> loadGroups({int page = 1, int limit = 20}) async {
    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final result = await _repository.getGroups(page: page, limit: limit);
      state = GroupListState(
        groups: result.groups,
        pagination: result.pagination,
      );
    } catch (error) {
      state = state.copyWith(is_loading: false, error: error);
    }
  }

  Future<void> loadMore() async {
    final pagination = state.pagination;
    if (state.is_loading ||
        pagination == null ||
        pagination.page >= pagination.total_pages) {
      return;
    }

    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final result = await _repository.getGroups(
        page: pagination.page + 1,
        limit: pagination.limit,
      );
      final by_id = <String, GroupSummary>{
        for (final group in state.groups) group.group_id: group,
        for (final group in result.groups) group.group_id: group,
      };
      state = GroupListState(
        groups: List.unmodifiable(by_id.values),
        pagination: result.pagination,
      );
    } catch (error) {
      state = state.copyWith(is_loading: false, error: error);
    }
  }

  Future<GroupDetail?> createGroup({
    required String name,
    String? timezone,
    List<String> invitee_user_ids = const [],
  }) async {
    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final result = await _repository.createGroup(
        name: name,
        timezone: timezone,
        invitee_user_ids: invitee_user_ids,
      );
      await loadGroups();
      return result.group;
    } catch (error) {
      state = state.copyWith(is_loading: false, error: error);
      return null;
    }
  }

  void removeGroup(String group_id) {
    state = state.copyWith(
      groups: state.groups
          .where((group) => group.group_id != group_id)
          .toList(growable: false),
    );
  }

  void clearError() {
    state = state.copyWith(clear_error: true);
  }
}

class GroupDetailState {
  const GroupDetailState({this.group, this.is_loading = false, this.error});

  final GroupDetail? group;
  final bool is_loading;
  final Object? error;

  GroupDetailState copyWith({
    GroupDetail? group,
    bool? is_loading,
    Object? error,
    bool clear_error = false,
  }) {
    return GroupDetailState(
      group: group ?? this.group,
      is_loading: is_loading ?? this.is_loading,
      error: clear_error ? null : error ?? this.error,
    );
  }
}

final groupDetailProvider = StateNotifierProvider.autoDispose
    .family<GroupDetailNotifier, GroupDetailState, String>((ref, group_id) {
      return GroupDetailNotifier(
        repository: ref.watch(groupRepositoryProvider),
        group_id: group_id,
      );
    });

class GroupDetailNotifier extends StateNotifier<GroupDetailState> {
  GroupDetailNotifier({
    required GroupRepository repository,
    required String group_id,
  }) : _repository = repository,
       _group_id = group_id,
       super(const GroupDetailState());

  final GroupRepository _repository;
  final String _group_id;

  Future<void> load() async {
    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final group = await _repository.getGroupDetail(_group_id);
      state = GroupDetailState(group: group);
    } catch (error) {
      state = state.copyWith(is_loading: false, error: error);
    }
  }

  Future<bool> updateGroup({String? name, String? timezone}) async {
    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final group = await _repository.updateGroup(
        group_id: _group_id,
        name: name,
        timezone: timezone,
      );
      state = GroupDetailState(group: group);
      return true;
    } catch (error) {
      state = state.copyWith(is_loading: false, error: error);
      return false;
    }
  }

  Future<bool> removeMember(String user_id) async {
    try {
      await _repository.removeMember(group_id: _group_id, user_id: user_id);
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(error: error);
      return false;
    }
  }

  Future<bool> updateMemberRole(String user_id, GroupRole role) async {
    try {
      await _repository.updateMemberRole(
        group_id: _group_id,
        user_id: user_id,
        role: role,
      );
      await load();
      return true;
    } catch (error) {
      state = state.copyWith(error: error);
      return false;
    }
  }

  Future<bool> transferOwnership(String new_owner_user_id) async {
    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final group = await _repository.transferOwnership(
        group_id: _group_id,
        new_owner_user_id: new_owner_user_id,
      );
      state = GroupDetailState(group: group);
      return true;
    } catch (error) {
      state = state.copyWith(is_loading: false, error: error);
      return false;
    }
  }

  Future<bool> deleteGroup() async {
    try {
      await _repository.deleteGroup(_group_id);
      return true;
    } catch (error) {
      state = state.copyWith(error: error);
      return false;
    }
  }

  Future<bool> leaveGroup() async {
    try {
      await _repository.leaveGroup(_group_id);
      return true;
    } catch (error) {
      state = state.copyWith(error: error);
      return false;
    }
  }
}

class GroupInvitationState {
  const GroupInvitationState({
    this.invitations = const [],
    this.pagination,
    this.processing_ids = const {},
    this.is_loading = false,
    this.has_loaded = false,
    this.error,
  });

  final List<GroupInvitation> invitations;
  final GroupPagination? pagination;
  final Set<String> processing_ids;
  final bool is_loading;
  final bool has_loaded;
  final Object? error;

  GroupInvitationState copyWith({
    List<GroupInvitation>? invitations,
    GroupPagination? pagination,
    Set<String>? processing_ids,
    bool? is_loading,
    bool? has_loaded,
    Object? error,
    bool clear_error = false,
  }) {
    return GroupInvitationState(
      invitations: invitations ?? this.invitations,
      pagination: pagination ?? this.pagination,
      processing_ids: processing_ids ?? this.processing_ids,
      is_loading: is_loading ?? this.is_loading,
      has_loaded: has_loaded ?? this.has_loaded,
      error: clear_error ? null : error ?? this.error,
    );
  }
}

final receivedGroupInvitationsProvider =
    StateNotifierProvider<
      ReceivedGroupInvitationsNotifier,
      GroupInvitationState
    >((ref) {
      return ReceivedGroupInvitationsNotifier(
        repository: ref.watch(groupRepositoryProvider),
        on_group_accepted: () =>
            ref.read(groupListProvider.notifier).loadGroups(),
      );
    });

class ReceivedGroupInvitationsNotifier
    extends StateNotifier<GroupInvitationState> {
  ReceivedGroupInvitationsNotifier({
    required GroupRepository repository,
    required Future<void> Function() on_group_accepted,
  }) : _repository = repository,
       _on_group_accepted = on_group_accepted,
       super(const GroupInvitationState());

  final GroupRepository _repository;
  final Future<void> Function() _on_group_accepted;

  Future<void> load({int page = 1, int limit = 20}) async {
    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final result = await _repository.getReceivedInvitations(
        status: GroupInvitationStatus.pending,
        page: page,
        limit: limit,
      );
      state = GroupInvitationState(
        invitations: result.invitations,
        pagination: result.pagination,
        has_loaded: true,
      );
    } catch (error) {
      state = state.copyWith(is_loading: false, has_loaded: true, error: error);
    }
  }

  Future<bool> respond({
    required String invitation_id,
    required String action,
  }) async {
    if (state.processing_ids.contains(invitation_id)) return false;
    state = state.copyWith(
      processing_ids: {...state.processing_ids, invitation_id},
      clear_error: true,
    );
    try {
      await _repository.respondToInvitation(
        invitation_id: invitation_id,
        action: action,
      );
      state = state.copyWith(
        invitations: state.invitations
            .where((item) => item.invitation_id != invitation_id)
            .toList(growable: false),
        processing_ids: {...state.processing_ids}..remove(invitation_id),
      );
      if (action == 'accept') await _on_group_accepted();
      return true;
    } catch (error) {
      if (_shouldRefreshInvitationState(error)) {
        final limit = state.pagination?.limit ?? 20;
        await load(limit: limit);
        state = state.copyWith(
          processing_ids: {...state.processing_ids}..remove(invitation_id),
          error: error,
        );
        if (error is ApiException &&
            error.code == 'GROUP_MEMBER_ALREADY_EXISTS') {
          await _on_group_accepted();
        }
        return false;
      }
      state = state.copyWith(
        processing_ids: {...state.processing_ids}..remove(invitation_id),
        error: error,
      );
      return false;
    }
  }

  bool _shouldRefreshInvitationState(Object error) {
    if (error is! ApiException) return false;
    return const {
      'GROUP_INVITATION_ALREADY_PROCESSED',
      'GROUP_INVITATION_EXPIRED',
      'GROUP_INVITATION_NOT_FOUND',
      'GROUP_MEMBER_ALREADY_EXISTS',
      'GROUP_MEMBER_LIMIT_REACHED',
    }.contains(error.code);
  }

  Future<void> loadMore() async {
    final pagination = state.pagination;
    if (state.is_loading ||
        pagination == null ||
        pagination.page >= pagination.total_pages) {
      return;
    }

    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final result = await _repository.getReceivedInvitations(
        status: GroupInvitationStatus.pending,
        page: pagination.page + 1,
        limit: pagination.limit,
      );
      final by_id = <String, GroupInvitation>{
        for (final invitation in state.invitations)
          invitation.invitation_id: invitation,
        for (final invitation in result.invitations)
          invitation.invitation_id: invitation,
      };
      state = GroupInvitationState(
        invitations: List.unmodifiable(by_id.values),
        pagination: result.pagination,
        has_loaded: true,
      );
    } catch (error) {
      state = state.copyWith(is_loading: false, error: error);
    }
  }
}

final groupOutgoingInvitationsProvider = StateNotifierProvider.autoDispose
    .family<GroupOutgoingInvitationsNotifier, GroupInvitationState, String>((
      ref,
      group_id,
    ) {
      return GroupOutgoingInvitationsNotifier(
        repository: ref.watch(groupRepositoryProvider),
        group_id: group_id,
      );
    });

class GroupOutgoingInvitationsNotifier
    extends StateNotifier<GroupInvitationState> {
  GroupOutgoingInvitationsNotifier({
    required GroupRepository repository,
    required String group_id,
  }) : _repository = repository,
       _group_id = group_id,
       super(const GroupInvitationState());

  final GroupRepository _repository;
  final String _group_id;

  Future<void> load({int page = 1, int limit = 100}) async {
    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      final result = await _repository.getGroupInvitations(
        group_id: _group_id,
        status: GroupInvitationStatus.pending,
        page: page,
        limit: limit,
      );
      if (!mounted) return;
      state = GroupInvitationState(
        invitations: result.invitations,
        pagination: result.pagination,
        has_loaded: true,
      );
    } catch (error) {
      if (!mounted) return;
      state = state.copyWith(is_loading: false, has_loaded: true, error: error);
    }
  }

  Future<bool> create({
    required List<String> invitee_user_ids,
    String? message,
  }) async {
    if (invitee_user_ids.isEmpty || state.is_loading) return false;
    state = state.copyWith(is_loading: true, clear_error: true);
    try {
      await _repository.createInvitations(
        group_id: _group_id,
        invitee_user_ids: invitee_user_ids,
        message: message,
      );
      if (!mounted) return false;
      state = state.copyWith(is_loading: false);
      return true;
    } catch (error) {
      if (!mounted) return false;
      state = state.copyWith(is_loading: false, error: error);
      return false;
    }
  }

  Future<bool> cancel(String invitation_id) async {
    if (state.processing_ids.contains(invitation_id)) return false;
    state = state.copyWith(
      processing_ids: {...state.processing_ids, invitation_id},
      clear_error: true,
    );
    try {
      await _repository.cancelInvitation(invitation_id);
      if (!mounted) return false;
      state = state.copyWith(
        invitations: state.invitations
            .where((item) => item.invitation_id != invitation_id)
            .toList(growable: false),
        processing_ids: {...state.processing_ids}..remove(invitation_id),
      );
      return true;
    } catch (error) {
      if (!mounted) return false;
      if (error is ApiException &&
          const {
            'GROUP_INVITATION_ALREADY_PROCESSED',
            'GROUP_INVITATION_EXPIRED',
            'GROUP_INVITATION_NOT_FOUND',
          }.contains(error.code)) {
        await load();
        if (!mounted) return false;
        state = state.copyWith(
          processing_ids: {...state.processing_ids}..remove(invitation_id),
          error: error,
        );
        return false;
      }
      state = state.copyWith(
        processing_ids: {...state.processing_ids}..remove(invitation_id),
        error: error,
      );
      return false;
    }
  }
}
