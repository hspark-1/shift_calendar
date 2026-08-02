// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../friend/data/models/friend_model.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../application/group_providers.dart';
import 'group_calendar_page.dart';

class GroupCreatePage extends ConsumerStatefulWidget {
  const GroupCreatePage({super.key});

  @override
  ConsumerState<GroupCreatePage> createState() => _GroupCreatePageState();
}

class _GroupCreatePageState extends ConsumerState<GroupCreatePage> {
  final TextEditingController _name_controller = TextEditingController();
  final Set<String> _selected_friend_ids = {};

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
    _name_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friend_state = ref.watch(friendListProvider);
    final group_state = ref.watch(groupListProvider);
    final timezone =
        ref.watch(authProvider).user?.timezone ?? AppConstants.default_timezone;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('그룹 만들기'),
        trailing: CupertinoButton(
          key: const ValueKey('create-group-submit-button'),
          padding: EdgeInsets.zero,
          onPressed: group_state.is_loading ? null : () => _submit(timezone),
          child: group_state.is_loading
              ? const CupertinoActivityIndicator()
              : const Text('완료'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing_md),
          children: [
            _SectionCard(
              title: '그룹 정보',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoTextField(
                    key: const ValueKey('create-group-name-field'),
                    controller: _name_controller,
                    placeholder: '그룹 이름',
                    maxLength: 50,
                    textInputAction: TextInputAction.done,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface_container_low_color,
                      borderRadius: BorderRadius.circular(AppTheme.radius_md),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacing_sm),
                  Text(
                    '시간대 · $timezone',
                    style: AppTheme.body_small.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            _SectionCard(
              title: '친구 초대 (${_selected_friend_ids.length}/19)',
              child: _buildFriendSelection(friend_state),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendSelection(FriendListState state) {
    if (state.isLoading && state.friends.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(AppTheme.spacing_lg),
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    if (state.friends.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing_lg),
        child: Text(
          '초대할 친구가 없습니다. 그룹은 먼저 만들 수 있습니다.',
          textAlign: TextAlign.center,
          style: AppTheme.body_small.copyWith(
            color: AppTheme.on_surface_variant_color,
          ),
        ),
      );
    }

    return Column(
      children: [for (final friend in state.friends) _buildFriendRow(friend)],
    );
  }

  Widget _buildFriendRow(FriendModel friend) {
    final selected = _selected_friend_ids.contains(friend.userId);
    return CupertinoButton(
      key: ValueKey('create-group-friend-${friend.userId}'),
      padding: const EdgeInsets.symmetric(vertical: 9),
      onPressed: () {
        if (!selected && _selected_friend_ids.length >= 19) {
          _showError('그룹은 소유자를 포함해 최대 20명까지 참여할 수 있습니다.');
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
            width: 36,
            height: 36,
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

  Future<void> _submit(String timezone) async {
    final name = _name_controller.text.trim();
    if (name.isEmpty) {
      _showError('그룹 이름을 입력해주세요.');
      return;
    }

    final group = await ref
        .read(groupListProvider.notifier)
        .createGroup(
          name: name,
          timezone: timezone,
          invitee_user_ids: _selected_friend_ids.toList(growable: false),
        );
    if (!mounted) return;
    if (group == null) {
      final error = ref.read(groupListProvider).error;
      _showError(error is ApiException ? error.message : '그룹을 만들지 못했습니다.');
      return;
    }

    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(
        builder: (context) => GroupCalendarPage(group_id: group.group_id),
      ),
    );
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing_md),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: AppTheme.body_medium.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppTheme.spacing_md),
          child,
        ],
      ),
    );
  }
}
