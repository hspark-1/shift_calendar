import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/friend_model.dart';
import '../providers/friend_provider.dart';
import '../widgets/add_friend_modal.dart';
import '../widgets/friend_list_item.dart';
import 'friend_detail_page.dart';

/// 친구 목록 페이지
class FriendListPage extends ConsumerStatefulWidget {
  const FriendListPage({super.key});

  @override
  ConsumerState<FriendListPage> createState() => _FriendListPageState();
}

class _FriendListPageState extends ConsumerState<FriendListPage> {
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
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('친구'),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _showAddFriendModal(context),
          child: const Icon(CupertinoIcons.person_add),
        ),
      ),
      child: SafeArea(
        child: _buildContent(state),
      ),
    );
  }

  Widget _buildContent(FriendListState state) {
    if (state.isLoading && state.friends.isEmpty) {
      return const Center(
        child: CupertinoActivityIndicator(),
      );
    }

    if (state.error != null && state.friends.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 48,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 16),
            Text(
              getErrorMessage(state.error),
              style: AppTheme.body_medium.copyWith(
                color: CupertinoColors.systemGrey,
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
              color: CupertinoColors.systemGrey3,
            ),
            const SizedBox(height: 16),
            Text(
              '아직 친구가 없습니다',
              style: AppTheme.body_large.copyWith(
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '친구를 추가하여 일정을 공유해보세요',
              style: AppTheme.body_small.copyWith(
                color: CupertinoColors.systemGrey2,
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
            delegate: SliverChildBuilderDelegate(
              (context, index) {
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
              },
              childCount: state.friends.length,
            ),
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

  void _showAddFriendModal(BuildContext context) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => const AddFriendModal(),
    );
  }

  void _navigateToDetail(FriendModel friend) {
    Navigator.of(context).push(
      CupertinoPageRoute<void>(
        builder: (context) => FriendDetailPage(friend: friend),
      ),
    );
  }
}

