// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';
import 'package:shift_mate/features/group/presentation/widgets/group_room_list_view.dart';

class _FakeGroupRepository implements GroupRepository {
  _FakeGroupRepository({this.empty = false, this.fail = false});
  bool empty;
  bool fail;
  Completer<void>? pending_load;
  int load_count = 0;

  @override
  Future<PaginatedGroups> getGroups({int page = 1, int limit = 20}) async {
    load_count++;
    await pending_load?.future;
    if (fail) throw StateError('그룹 목록 오류');
    return (
      groups: [
        if (!empty)
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
  Future<void> pumpList(
    WidgetTester tester,
    _FakeGroupRepository repository,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [groupRepositoryProvider.overrideWithValue(repository)],
        child: CupertinoApp(
          home: CupertinoPageScaffold(
            child: GroupRoomListView(onGroupTap: (_) {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final empty in [true, false]) {
    testWidgets('빈 그룹·짧은 그룹 목록을 당기면 새로고침한다 $empty', (tester) async {
      final repository = _FakeGroupRepository(empty: empty);
      await pumpList(tester, repository);
      expect(repository.load_count, 1);
      await tester.drag(
        find.text(empty ? '참여 중인 그룹이 없습니다' : '응급실 A팀'),
        const Offset(0, 320),
      );
      await tester.pumpAndSettle();
      expect(repository.load_count, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('빈 그룹 새로고침은 요청 중 컨트롤을 유지하고 중복 없이 새 목록을 표시한다', (tester) async {
    final repository = _FakeGroupRepository(empty: true);
    await pumpList(tester, repository);
    final pending_load = Completer<void>();
    repository.pending_load = pending_load;
    await tester.drag(find.text('참여 중인 그룹이 없습니다'), const Offset(0, 320));
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.load_count, 2);
    expect(find.byType(CupertinoSliverRefreshControl), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 320));
    await tester.pump(const Duration(milliseconds: 500));
    expect(repository.load_count, 2);
    repository.empty = false;
    pending_load.complete();
    await tester.pumpAndSettle();
    expect(find.text('응급실 A팀'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 그룹 오류 화면도 당겨 재시도하고 빈 목록으로 복구한다', (tester) async {
    final repository = _FakeGroupRepository(empty: true, fail: true);
    await pumpList(tester, repository);
    repository.fail = false;
    await tester.drag(find.text('다시 시도'), const Offset(0, 320));
    await tester.pumpAndSettle();
    expect(repository.load_count, 2);
    expect(find.text('참여 중인 그룹이 없습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final fail in [false, true]) {
    testWidgets('그룹 빈 목록·오류는 낮은 본문에서 스크롤한다 $fail', (tester) async {
      final repository = _FakeGroupRepository(empty: true, fail: fail);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [groupRepositoryProvider.overrideWithValue(repository)],
          child: CupertinoApp(
            home: CupertinoPageScaffold(
              child: MediaQuery(
                data: const MediaQueryData(
                  size: Size(320, 568),
                  textScaler: TextScaler.linear(2),
                ),
                child: SizedBox(
                  height: 160,
                  width: 320,
                  child: GroupRoomListView(onGroupTap: (_) {}),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final target = find.text(fail ? '다시 시도' : '새 그룹을 만들거나 받은 초대를 확인해보세요');
      await tester.ensureVisible(target);
      await tester.pumpAndSettle();
      expect(target.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (fail) {
        await tester.tap(target);
        await tester.pumpAndSettle();
        expect(repository.load_count, 2);
      }
    });
  }

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
