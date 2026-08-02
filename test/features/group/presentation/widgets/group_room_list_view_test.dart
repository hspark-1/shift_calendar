// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';
import 'package:shift_mate/features/group/presentation/widgets/group_room_list_view.dart';

class _FakeGroupRepository implements GroupRepository {
  @override
  Future<PaginatedGroups> getGroups({int page = 1, int limit = 20}) async {
    return (
      groups: [
        GroupSummary(
          group_id: 'group-1',
          name: '응급실 A팀',
          timezone: 'Asia/Seoul',
          my_role: GroupRole.admin,
          member_count: 3,
          members_preview: const [
            GroupUserSummary(user_id: 'user-1', name: '가'),
            GroupUserSummary(user_id: 'user-2', name: '나'),
          ],
          created_at: DateTime.utc(2026, 8, 1),
          updated_at: DateTime.utc(2026, 8, 1),
        ),
      ],
      pagination: GroupPagination(
        page: page,
        limit: limit,
        total: 1,
        total_pages: 1,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('그룹 목록은 summary 정보만 표시하고 카드 탭을 전달한다', (tester) async {
    GroupSummary? selected_group;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          groupRepositoryProvider.overrideWithValue(_FakeGroupRepository()),
        ],
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: GroupRoomListView(
              onGroupTap: (group) => selected_group = group,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('응급실 A팀'), findsOneWidget);
    expect(find.text('3명 · 관리자'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('group-room-card-group-1')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('group-room-card-group-1')));
    expect(selected_group?.group_id, 'group-1');
    expect(tester.takeException(), isNull);
  });
}
