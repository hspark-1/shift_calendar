// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/widgets/bottom_action_bar.dart';
import '../../../group/application/group_providers.dart';
import '../../../group/domain/entities/group_models.dart';
import '../../../group/presentation/pages/group_calendar_page.dart';
import '../../../group/presentation/pages/group_create_page.dart';
import '../../../group/presentation/pages/received_group_invitations_page.dart';
import '../../../group/presentation/widgets/group_room_list_view.dart';
import '../../data/models/friend_model.dart';
import '../providers/friend_provider.dart';
import '../widgets/add_friend_modal.dart';
import '../widgets/friend_list_item.dart';
import 'friend_calendar_page.dart';
import 'group_calendar_preview_page.dart';

enum _FriendListSection { friends, groupRooms }

/// 친구 목록 페이지
class FriendListPage extends ConsumerStatefulWidget {
  const FriendListPage({super.key});

  @override
  ConsumerState<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends ConsumerState<FriendListPage> {
  _FriendListSection _selected_section = _FriendListSection.friends;

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 친구 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendListProvider.notifier).loadFriends();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        middle: Text(
          _selected_section == _FriendListSection.friends ? '친구' : '그룹 방',
        ),
        trailing: _buildNavigationActions(),
      ),
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: _selected_section == _FriendListSection.friends
                  ? _buildContent(state)
                  : _buildGroupRoomList(),
            ),
          ),
          BottomActionBar(
            items: [
              BottomActionBarItem(
                widget_key: const ValueKey('friend-list-footer-button'),
                icon: _selected_section == _FriendListSection.friends
                    ? CupertinoIcons.person_2_fill
                    : CupertinoIcons.person_2,
                label: '친구 리스트',
                is_selected: _selected_section == _FriendListSection.friends,
                onTap: () => _selectSection(_FriendListSection.friends),
              ),
              BottomActionBarItem(
                widget_key: const ValueKey('group-room-footer-button'),
                icon: _selected_section == _FriendListSection.groupRooms
                    ? CupertinoIcons.square_stack_3d_up_fill
                    : CupertinoIcons.square_stack_3d_up,
                label: '그룹 방',
                is_selected: _selected_section == _FriendListSection.groupRooms,
                onTap: () => _selectSection(_FriendListSection.groupRooms),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(FriendListState state) {
    if (state.isLoading && state.friends.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (state.error != null && state.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: AppTheme.outline_color,
            ),
            const SizedBox(height: 16),
            Text(
              getErrorMessage(state.error),
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () =>
                  ref.read(friendListProvider.notifier).loadFriends(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (state.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_2,
              size: 64,
              color: AppTheme.outline_variant_color,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 친구가 없습니다',
              style: AppTheme.body_large.copyWith(
                color: AppTheme.on_surface_color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '친구를 추가하여 일정을 공유해보세요',
              style: AppTheme.body_small.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
            const SizedBox(height: 24),
            CupertinoButton.filled(
              onPressed: () => _showAddFriendModal(context),
              child: const Text('친구 추가하기'),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () => ref.read(friendListProvider.notifier).loadFriends(),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              if (index >= state.friends.length) {
                return null;
              }
              final friend = state.friends[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FriendListItem(
                  friend: friend,
                  onTap: () => _navigateToDetail(friend),
                ),
              );
            }, childCount: state.friends.length),
          ),
        ),
        // 더 불러오기 인디케이터
        if (state.isLoading && state.friends.isNotEmpty)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CupertinoActivityIndicator()),
            ),
          ),
      ],
    );
  }

  Widget _buildGroupRoomList() {
    if (AppConstants.group_api_enabled) {
      return GroupRoomListView(onGroupTap: _navigateToGroup);
    }

    return CustomScrollView(
      key: const ValueKey('group-room-list'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.list(
            children: [
              Semantics(
                button: true,
                label: '우리 병동 그룹 캘린더 미리보기 열기',
                child: GestureDetector(
                  key: const ValueKey('group-room-preview-card'),
                  behavior: HitTestBehavior.opaque,
                  onTap: _navigateToGroupPreview,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AppTheme.cardDecoration(),
                    child: Row(
                      children: [
                        _buildGroupRoomAvatars(),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      '우리 병동',
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTheme.body_medium.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary_color.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.chip_radius,
                                      ),
                                    ),
                                    child: Text(
                                      '미리보기',
                                      style: AppTheme.body_small.copyWith(
                                        color: AppTheme.primary_dark_color,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${group_preview_members.length}명 · '
                                '그룹 캘린더',
                                style: AppTheme.body_small.copyWith(
                                  color: AppTheme.on_surface_variant_color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 16,
                          color: AppTheme.outline_variant_color,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget? _buildNavigationActions() {
    if (_selected_section == _FriendListSection.friends) {
      return CupertinoButton(
        key: const ValueKey('add-friend-button'),
        padding: const EdgeInsets.only(left: 6),
        onPressed: () => _showAddFriendModal(context),
        child: const Icon(CupertinoIcons.person_add),
      );
    }
    if (!AppConstants.group_api_enabled) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CupertinoButton(
          key: const ValueKey('received-group-invitations-button'),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          minimumSize: const Size(36, 36),
          onPressed: _navigateToGroupInvitations,
          child: const Icon(CupertinoIcons.envelope),
        ),
        CupertinoButton(
          key: const ValueKey('create-group-button'),
          padding: const EdgeInsets.only(left: 6),
          minimumSize: const Size(36, 36),
          onPressed: _navigateToGroupCreate,
          child: const Icon(CupertinoIcons.add),
        ),
      ],
    );
  }

  Widget _buildGroupRoomAvatars() {
    const avatar_size = 34.0;
    const avatar_overlap = 22.0;
    final avatar_width =
        avatar_size + ((group_preview_members.length - 1) * avatar_overlap);

    return SizedBox(
      key: const ValueKey('group-room-preview-avatars'),
      width: avatar_width,
      height: avatar_size,
      child: Stack(
        children: [
          for (var index = 0; index < group_preview_members.length; index++)
            Positioned(
              left: index * avatar_overlap,
              child: Container(
                width: avatar_size,
                height: avatar_size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: group_preview_members[index].color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface_color, width: 2),
                ),
                child: Text(
                  group_preview_members[index].initial,
                  style: const TextStyle(
                    color: AppTheme.surface_color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _selectSection(_FriendListSection section) {
    if (_selected_section == section) return;
    setState(() => _selected_section = section);
  }

  void _showAddFriendModal(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => const AddFriendModal(),
    );
  }

  void _navigateToDetail(FriendModel friend) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => FriendCalendarPage(friend: friend),
      ),
    );
  }

  void _navigateToGroupPreview() {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => const GroupCalendarPreviewPage(),
      ),
    );
  }

  void _navigateToGroup(GroupSummary group) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => GroupCalendarPage(group_id: group.group_id),
      ),
    );
  }

  Future<void> _navigateToGroupCreate() async {
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(builder: (context) => const GroupCreatePage()),
    );
    if (!mounted) return;
    await ref.read(groupListProvider.notifier).loadGroups();
  }

  Future<void> _navigateToGroupInvitations() async {
    await Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => const ReceivedGroupInvitationsPage(),
      ),
    );
    if (!mounted) return;
    await ref.read(groupListProvider.notifier).loadGroups();
  }
}
