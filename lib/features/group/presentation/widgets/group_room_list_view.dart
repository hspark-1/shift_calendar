// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/group_providers.dart';
import '../../domain/entities/group_models.dart';

class GroupRoomListView extends ConsumerStatefulWidget {
  const GroupRoomListView({super.key, required this.onGroupTap});

  final void Function(GroupSummary group) onGroupTap;

  @override
  ConsumerState<GroupRoomListView> createState() => _GroupRoomListViewState();
}

class _GroupRoomListViewState extends ConsumerState<GroupRoomListView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(groupListProvider).groups.isEmpty) {
        ref.read(groupListProvider.notifier).loadGroups();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupListProvider);
    if (state.is_loading && state.groups.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.error != null && state.groups.isEmpty) {
      return _ErrorState(
        message: _errorMessage(state.error),
        onRetry: () => ref.read(groupListProvider.notifier).loadGroups(),
      );
    }
    if (state.groups.isEmpty) {
      return const _EmptyState();
    }

    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        final metrics = notification.metrics;
        if (metrics.extentAfter < 120) {
          ref.read(groupListProvider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        key: const ValueKey('group-room-api-list'),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () => ref.read(groupListProvider.notifier).loadGroups(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacing_md),
            sliver: SliverList.separated(
              itemCount: state.groups.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppTheme.spacing_sm),
              itemBuilder: (context, index) {
                final group = state.groups[index];
                return _GroupRoomCard(
                  group: group,
                  onTap: () => widget.onGroupTap(group),
                );
              },
            ),
          ),
          if (state.is_loading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(AppTheme.spacing_md),
                child: Center(child: CupertinoActivityIndicator()),
              ),
            ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppTheme.spacing_md),
          ),
        ],
      ),
    );
  }

  String _errorMessage(Object? error) {
    return error is ApiException ? error.message : '그룹 목록을 불러오지 못했습니다.';
  }
}

class _GroupRoomCard extends StatelessWidget {
  const _GroupRoomCard({required this.group, required this.onTap});

  final GroupSummary group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${group.name}, ${group.member_count}명 그룹 열기',
      child: GestureDetector(
        key: ValueKey('group-room-card-${group.group_id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spacing_md),
          decoration: AppTheme.cardDecoration(),
          child: Row(
            children: [
              _AvatarStack(members: group.members_preview),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.body_medium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${group.member_count}명 · ${_roleLabel(group.my_role)}',
                      style: AppTheme.body_small.copyWith(
                        color: AppTheme.on_surface_variant_color,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: AppTheme.outline_variant_color,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleLabel(GroupRole role) {
    return switch (role) {
      GroupRole.owner => '소유자',
      GroupRole.admin => '관리자',
      GroupRole.member => '멤버',
      GroupRole.unknown => '그룹 멤버',
    };
  }
}

class _AvatarStack extends StatelessWidget {
  const _AvatarStack({required this.members});

  final List<GroupUserSummary> members;

  @override
  Widget build(BuildContext context) {
    const size = 34.0;
    const overlap = 22.0;
    final visible = members.take(4).toList(growable: false);
    final width = visible.isEmpty
        ? size
        : size + (visible.length - 1) * overlap;
    return SizedBox(
      width: width,
      height: size,
      child: Stack(
        children: [
          if (visible.isEmpty)
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                color: AppTheme.surface_container_color,
                shape: BoxShape.circle,
              ),
              child: const Icon(CupertinoIcons.person_2, size: 17),
            ),
          for (var index = 0; index < visible.length; index++)
            Positioned(
              left: index * overlap,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _memberColor(visible[index].user_id),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.surface_color, width: 2),
                ),
                child: Text(
                  visible[index].name.isEmpty ? '?' : visible[index].name[0],
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

  Color _memberColor(String user_id) {
    const colors = [
      Color(0xFFFF9500),
      Color(0xFFE85F80),
      Color(0xFF4355B8),
      Color(0xFF448F53),
      Color(0xFF717782),
    ];
    return colors[user_id.hashCode.abs() % colors.length];
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.person_3,
            size: 64,
            color: AppTheme.outline_variant_color,
          ),
          const SizedBox(height: AppTheme.spacing_md),
          Text('참여 중인 그룹이 없습니다', style: AppTheme.body_large),
          const SizedBox(height: AppTheme.spacing_sm),
          Text(
            '새 그룹을 만들거나 받은 초대를 확인해보세요',
            style: AppTheme.body_small.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.exclamationmark_circle,
            size: 48,
            color: AppTheme.outline_color,
          ),
          const SizedBox(height: AppTheme.spacing_md),
          Text(message, textAlign: TextAlign.center),
          CupertinoButton(onPressed: onRetry, child: const Text('다시 시도')),
        ],
      ),
    );
  }
}
