// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/navigation/app_navigation.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/scrollable_centered_body.dart';
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
import 'notification_page.dart';

/// 친구 목록 페이지
class FriendListPage extends ConsumerStatefulWidget {
  const FriendListPage({super.key});

  @override
  ConsumerState<FriendListPage> createState() => FriendListPageState();
}

class FriendListPageState extends ConsumerState<FriendListPage> {
  final _page_controller = PageController();
  FriendTabSection _selected_section = FriendTabSection.friends;
  bool _has_opened_groups = false;

  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 친구 목록 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(friendListProvider.notifier).loadFriends();
    });
  }

  @override
  void dispose() {
    _page_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(friendListProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        // 친구/그룹 목록을 전환하거나 스크롤해도 같은 헤더 배경을 유지한다.
        automaticBackgroundVisibility: false,
        backgroundColor: AppTheme.background_color,
        border: null,
        middle: Text(
          _selected_section == FriendTabSection.friends ? '친구' : '그룹 방',
        ),
        trailing: _buildNavigationActions(),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: CupertinoSlidingSegmentedControl<FriendTabSection>(
                  groupValue: _selected_section,
                  children: const {
                    FriendTabSection.friends: Padding(
                      key: ValueKey('friend-list-footer-button'),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('친구'),
                    ),
                    FriendTabSection.groups: Padding(
                      key: ValueKey('group-room-footer-button'),
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('그룹'),
                    ),
                  },
                  onValueChanged: (section) {
                    if (section != null) showSection(section);
                  },
                ),
              ),
            ),
            Expanded(
              child: PageView(
                key: const ValueKey('friend-group-page-view'),
                controller: _page_controller,
                onPageChanged: (index) =>
                    _selectSection(FriendTabSection.values[index]),
                children: [
                  _KeepAliveSection(child: _buildContent(state)),
                  _KeepAliveSection(
                    child: _has_opened_groups
                        ? _buildGroupRoomList()
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(FriendListState state) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      slivers: [
        CupertinoSliverRefreshControl(
          onRefresh: () async {
            if (!ref.read(friendListProvider).isLoading) {
              await ref.read(friendListProvider.notifier).loadFriends();
            }
          },
        ),
        _buildContentSliver(state),
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

  Widget _buildContentSliver(FriendListState state) {
    if (state.isLoading && state.friends.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (state.error != null && state.friends.isEmpty) {
      return SliverCenteredBody(
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
      );
    }

    if (state.friends.isEmpty) {
      return SliverCenteredBody(
        children: [
          const Icon(
            CupertinoIcons.person_2,
            size: 64,
            color: AppTheme.outline_variant_color,
          ),
          const SizedBox(height: 16),
          Text(
            '아직 친구가 없습니다',
            textAlign: TextAlign.center,
            style: AppTheme.body_large.copyWith(
              color: AppTheme.on_surface_color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '친구를 추가하여 일정을 공유해보세요',
            textAlign: TextAlign.center,
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
      );
    }

    return SliverPadding(
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
    if (_selected_section == FriendTabSection.friends) {
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

  void _selectSection(FriendTabSection section) {
    if (_selected_section == section) return;
    setState(() {
      _selected_section = section;
      if (section == FriendTabSection.groups) _has_opened_groups = true;
    });
  }

  void toggleSection() => showSection(
    _selected_section == FriendTabSection.friends
        ? FriendTabSection.groups
        : FriendTabSection.friends,
  );

  void showSection(FriendTabSection section) {
    _selectSection(section);
    if (MediaQuery.disableAnimationsOf(context)) {
      _page_controller.jumpToPage(section.index);
    } else {
      _page_controller.animateToPage(
        section.index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  Future<void> _showAddFriendModal(BuildContext context) async {
    final tabs = AppTabNavigation.maybeOf(context);
    final open_received_requests = await showCupertinoModalPopup<bool>(
      context: context,
      builder: (context) => const AddFriendModal(),
    );
    if (!context.mounted || open_received_requests != true) return;
    if (tabs != null) {
      tabs.selectTab(2);
    } else {
      Navigator.of(context).push(
        CupertinoPageRoute<void>(builder: (_) => const NotificationPage()),
      );
    }
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
    final group_id = await Navigator.of(context, rootNavigator: true)
        .push<String>(
          CupertinoPageRoute<String>(
            builder: (context) => const GroupCreatePage(),
          ),
        );
    if (!mounted) return;
    await ref.read(groupListProvider.notifier).loadGroups();
    if (!mounted || group_id == null) return;
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (_) => GroupCalendarPage(group_id: group_id),
      ),
    );
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

/// 화면 밖으로 넘어간 목록도 유지해 각 목록의 스크롤 위치를 보존한다.
class _KeepAliveSection extends StatefulWidget {
  const _KeepAliveSection({required this.child});

  final Widget child;

  @override
  State<_KeepAliveSection> createState() => _KeepAliveSectionState();
}

class _KeepAliveSectionState extends State<_KeepAliveSection>
    with AutomaticKeepAliveClientMixin<_KeepAliveSection> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
