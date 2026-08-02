// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../friend/data/models/friend_model.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../application/group_providers.dart';
import '../../domain/entities/group_models.dart';

class GroupInvitePage extends ConsumerStatefulWidget {
  const GroupInvitePage({super.key, required this.group});

  final GroupDetail group;

  @override
  ConsumerState<GroupInvitePage> createState() => _GroupInvitePageState();
}

class _GroupInvitePageState extends ConsumerState<GroupInvitePage> {
  final Set<String> _selected_friend_ids = {};
  final TextEditingController _message_controller = TextEditingController();

  int get _remaining_seats => math.max(0, 20 - widget.group.member_count);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(friendListProvider).friends.isEmpty) {
        ref.read(friendListProvider.notifier).loadFriends(limit: 100);
      }
    });
  }

  @override
  void dispose() {
    _message_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friend_state = ref.watch(friendListProvider);
    final invitation_state = ref.watch(
      groupOutgoingInvitationsProvider(widget.group.group_id),
    );
    final member_ids = widget.group.members
        .map((member) => member.user_id)
        .toSet();
    final candidates = friend_state.friends
        .where((friend) => !member_ids.contains(friend.userId))
        .toList(growable: false);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('친구 초대'),
        trailing: CupertinoButton(
          key: const ValueKey('group-invite-submit-button'),
          padding: EdgeInsets.zero,
          onPressed: invitation_state.is_loading || _selected_friend_ids.isEmpty
              ? null
              : _submit,
          child: invitation_state.is_loading
              ? const CupertinoActivityIndicator()
              : const Text('보내기'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing_md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacing_md),
              decoration: AppTheme.cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '초대 메시지 (선택)',
                    style: AppTheme.body_medium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing_sm),
                  CupertinoTextField(
                    key: const ValueKey('group-invite-message-field'),
                    controller: _message_controller,
                    placeholder: '그룹에 함께할 친구에게 메시지를 남겨보세요',
                    maxLength: 200,
                    maxLines: 3,
                    padding: const EdgeInsets.all(12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            Text(
              '친구 선택 (${_selected_friend_ids.length}/$_remaining_seats)',
              style: AppTheme.body_medium.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              '현재 활성 멤버 기준 남은 좌석만큼 선택할 수 있습니다.',
              style: AppTheme.body_small.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
            const SizedBox(height: AppTheme.spacing_sm),
            if (friend_state.isLoading && friend_state.friends.isEmpty)
              const Padding(
                padding: EdgeInsets.all(AppTheme.spacing_lg),
                child: Center(child: CupertinoActivityIndicator()),
              )
            else if (_remaining_seats == 0)
              const _EmptyInviteState(message: '그룹 정원 20명이 모두 찼습니다.')
            else if (candidates.isEmpty)
              const _EmptyInviteState(message: '새로 초대할 친구가 없습니다.')
            else
              Container(
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  children: [
                    for (final friend in candidates) _buildFriendRow(friend),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendRow(FriendModel friend) {
    final selected = _selected_friend_ids.contains(friend.userId);
    return CupertinoButton(
      key: ValueKey('group-invite-friend-${friend.userId}'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      onPressed: () {
        if (!selected && _selected_friend_ids.length >= _remaining_seats) {
          _showError('남은 그룹 좌석 수를 초과해 선택할 수 없습니다.');
          return;
        }
        setState(() {
          if (selected) {
            _selected_friend_ids.remove(friend.userId);
          } else {
            _selected_friend_ids.add(friend.userId);
          }
        });
      },
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
            child: Text(friend.name.isEmpty ? '?' : friend.name[0]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              friend.name,
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_color,
              ),
            ),
          ),
          Icon(
            selected
                ? CupertinoIcons.check_mark_circled_solid
                : CupertinoIcons.circle,
            color: selected
                ? AppTheme.primary_color
                : AppTheme.outline_variant_color,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final raw_message = _message_controller.text.trim();
    final notifier = ref.read(
      groupOutgoingInvitationsProvider(widget.group.group_id).notifier,
    );
    final success = await notifier.create(
      invitee_user_ids: _selected_friend_ids.toList(growable: false),
      message: raw_message.isEmpty ? null : raw_message,
    );
    if (!mounted) return;
    if (!success) {
      final error = ref
          .read(groupOutgoingInvitationsProvider(widget.group.group_id))
          .error;
      if (error is ApiException && error.code == 'GROUP_PERMISSION_DENIED') {
        await ref
            .read(groupDetailProvider(widget.group.group_id).notifier)
            .load();
        if (!mounted) return;
      }
      _showError(error is ApiException ? error.message : '그룹 초대를 보내지 못했습니다.');
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _showError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('확인'),
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
}

class _EmptyInviteState extends StatelessWidget {
  const _EmptyInviteState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing_lg),
      decoration: AppTheme.cardDecoration(),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: AppTheme.body_small.copyWith(
          color: AppTheme.on_surface_variant_color,
        ),
      ),
    );
  }
}
