// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/group_providers.dart';
import '../../domain/entities/group_models.dart';

class ReceivedGroupInvitationsPage extends ConsumerStatefulWidget {
  const ReceivedGroupInvitationsPage({super.key});

  @override
  ConsumerState<ReceivedGroupInvitationsPage> createState() =>
      _ReceivedGroupInvitationsPageState();
}

class _ReceivedGroupInvitationsPageState
    extends ConsumerState<ReceivedGroupInvitationsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(receivedGroupInvitationsProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(receivedGroupInvitationsProvider);
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: const CupertinoNavigationBar(middle: Text('받은 그룹 초대')),
      child: SafeArea(child: _buildBody(state)),
    );
  }

  Widget _buildBody(GroupInvitationState state) {
    if (state.is_loading && state.invitations.isEmpty) {
      return const Center(child: CupertinoActivityIndicator());
    }
    if (state.error != null && state.invitations.isEmpty) {
      final message = state.error is ApiException
          ? (state.error! as ApiException).message
          : '초대 목록을 불러오지 못했습니다.';
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(message, textAlign: TextAlign.center),
            CupertinoButton(
              onPressed: () =>
                  ref.read(receivedGroupInvitationsProvider.notifier).load(),
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (state.invitations.isEmpty) {
      return Center(
        child: Text(
          '대기 중인 그룹 초대가 없습니다',
          style: AppTheme.body_medium.copyWith(
            color: AppTheme.on_surface_variant_color,
          ),
        ),
      );
    }

    return NotificationListener<ScrollEndNotification>(
      onNotification: (notification) {
        if (notification.metrics.extentAfter < 120) {
          ref.read(receivedGroupInvitationsProvider.notifier).loadMore();
        }
        return false;
      },
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: () =>
                ref.read(receivedGroupInvitationsProvider.notifier).load(),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacing_md),
            sliver: SliverList.separated(
              itemCount: state.invitations.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(height: AppTheme.spacing_sm),
              itemBuilder: (context, index) {
                final invitation = state.invitations[index];
                return _InvitationCard(
                  invitation: invitation,
                  is_processing: state.processing_ids.contains(
                    invitation.invitation_id,
                  ),
                  onAccept: () => _respond(invitation, 'accept'),
                  onReject: () => _respond(invitation, 'reject'),
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
        ],
      ),
    );
  }

  Future<void> _respond(GroupInvitation invitation, String action) async {
    final success = await ref
        .read(receivedGroupInvitationsProvider.notifier)
        .respond(invitation_id: invitation.invitation_id, action: action);
    if (!success && mounted) {
      final error = ref.read(receivedGroupInvitationsProvider).error;
      _showError(error is ApiException ? error.message : '그룹 초대를 처리하지 못했습니다.');
    }
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
}

class _InvitationCard extends StatelessWidget {
  const _InvitationCard({
    required this.invitation,
    required this.is_processing,
    required this.onAccept,
    required this.onReject,
  });

  final GroupInvitation invitation;
  final bool is_processing;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: ValueKey('group-invitation-${invitation.invitation_id}'),
      padding: const EdgeInsets.all(AppTheme.spacing_md),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            invitation.group.name,
            style: AppTheme.body_large.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${invitation.inviter.name}님이 초대했습니다 · '
            '${invitation.group.member_count}명',
            style: AppTheme.body_small.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
          if (invitation.message != null) ...[
            const SizedBox(height: AppTheme.spacing_sm),
            Text(invitation.message!, style: AppTheme.body_medium),
          ],
          const SizedBox(height: AppTheme.spacing_md),
          if (is_processing)
            const Center(child: CupertinoActivityIndicator())
          else
            Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    key: ValueKey(
                      'group-invitation-reject-${invitation.invitation_id}',
                    ),
                    color: AppTheme.surface_container_color,
                    onPressed: onReject,
                    child: Text(
                      '거절',
                      style: AppTheme.body_medium.copyWith(
                        color: AppTheme.on_surface_color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacing_sm),
                Expanded(
                  child: CupertinoButton.filled(
                    key: ValueKey(
                      'group-invitation-accept-${invitation.invitation_id}',
                    ),
                    onPressed: onAccept,
                    child: const Text('수락'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
