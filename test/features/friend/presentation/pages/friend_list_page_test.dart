// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/constants/app_constants.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_list_page.dart';
import 'package:shift_mate/features/friend/presentation/widgets/add_friend_modal.dart';
import 'package:shift_mate/features/group/application/group_providers.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';
import 'package:shift_mate/features/group/domain/repositories/group_repository.dart';

class _FriendService extends FriendService {
  _FriendService({
    this.empty = false,
    this.fail = false,
    this.friend_count = 20,
  }) : super(Dio());

  bool empty;
  bool fail;
  final int friend_count;
  Completer<void>? pending_load;
  int load_count = 0;

  @override
  Future<FriendsResponse> getFriends({int page = 1, int limit = 20}) async {
    load_count++;
    await pending_load?.future;
    if (fail) throw StateError('친구 목록을 불러올 수 없습니다. 다시 시도해주세요.');
    return FriendsResponse(
      success: true,
      data: FriendsData(
        friends: List.generate(
          empty ? 0 : friend_count,
          (index) => FriendModel(
            userId: 'friend-$index',
            name: '친구 $index',
            email: '$index@example.com',
            friendLevel: 1,
            canView: true,
            createdAt: DateTime.utc(2026, 11, 12),
          ),
        ),
        pagination: PaginationInfo(
          page: 1,
          limit: 20,
          total: 20,
          totalPages: 1,
        ),
      ),
    );
  }
}

class _GroupRepository implements GroupRepository {
  _GroupRepository({this.empty = false});

  final bool empty;
  int load_count = 0;

  @override
  Future<PaginatedGroups> getGroups({int page = 1, int limit = 20}) async {
    load_count++;
    return (
      groups: List.generate(
        empty ? 0 : 20,
        (index) => GroupSummary(
          group_id: 'group-$index',
          name: '그룹 $index',
          timezone: 'Asia/Seoul',
          my_role: GroupRole.member,
          member_count: 3,
          members_preview: const [],
          created_at: DateTime.utc(2026, 11, 12),
          updated_at: DateTime.utc(2026, 11, 12),
        ),
      ),
      pagination: GroupPagination(
        page: 1,
        limit: 20,
        total: 20,
        total_pages: 1,
      ),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

BoxDecoration _headerBackground(WidgetTester tester) {
  final background = find
      .descendant(
        of: find.byType(CupertinoNavigationBar),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is DecoratedBox &&
              widget.decoration is BoxDecoration &&
              (widget.decoration as BoxDecoration).color != null,
        ),
      )
      .first;
  return tester.widget<DecoratedBox>(background).decoration as BoxDecoration;
}

int _selectedSectionIndex(WidgetTester tester) {
  final control = tester.widget<CupertinoSlidingSegmentedControl>(
    find.byWidgetPredicate(
      (widget) => widget is CupertinoSlidingSegmentedControl,
    ),
  );
  return (control.groupValue as Enum).index;
}

void main() {
  if (AppConstants.group_api_enabled) {
    testWidgets('빈 친구·그룹 탭의 여백을 당겨도 각각 새로고침하고 선택 탭을 유지한다', (tester) async {
      final service = _FriendService(empty: true);
      final repository = _GroupRepository(empty: true);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendServiceProvider.overrideWithValue(service),
            groupRepositoryProvider.overrideWithValue(repository),
          ],
          child: const CupertinoApp(home: FriendListPage()),
        ),
      );
      await tester.pumpAndSettle();
      final pages = find.byKey(const ValueKey('friend-group-page-view'));
      final controller = tester.widget<PageView>(pages).controller!;
      final friends = tester.getRect(
        find.byType(CustomScrollView).hitTestable(),
      );
      await tester.dragFrom(
        friends.topLeft + const Offset(24, 32),
        const Offset(0, 320),
      );
      await tester.pumpAndSettle();
      expect(service.load_count, 2);
      expect(repository.load_count, 0);
      expect(controller.page, 0);

      await tester.tap(find.byKey(const ValueKey('group-room-footer-button')));
      await tester.pumpAndSettle();
      expect(repository.load_count, 1);
      final groups = tester.getRect(
        find.byKey(const ValueKey('group-room-api-list')),
      );
      await tester.dragFrom(
        groups.topLeft + const Offset(24, 32),
        const Offset(0, 320),
      );
      await tester.pumpAndSettle();
      expect(repository.load_count, 2);
      expect(service.load_count, 2);
      expect(controller.page, 1);

      await tester.drag(pages, const Offset(640, 0));
      await tester.pumpAndSettle();
      expect(controller.page, 0);
      expect(find.text('아직 친구가 없습니다').hitTestable(), findsOneWidget);
      expect(service.load_count, 2);
      expect(repository.load_count, 2);
      expect(tester.takeException(), isNull);
    });
  }

  for (final empty in [true, false]) {
    testWidgets('빈 친구·짧은 친구 목록을 당기면 새로고침한다 $empty', (tester) async {
      final service = _FriendService(empty: empty, friend_count: 1);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [friendServiceProvider.overrideWithValue(service)],
          child: const CupertinoApp(home: FriendListPage()),
        ),
      );
      await tester.pumpAndSettle();
      expect(service.load_count, 1);
      await tester.drag(
        find.text(empty ? '아직 친구가 없습니다' : '친구 0'),
        const Offset(0, 320),
      );
      await tester.pumpAndSettle();
      expect(service.load_count, 2);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('빈 친구 새로고침은 요청 중 컨트롤을 유지하고 중복 없이 새 목록을 표시한다', (tester) async {
    final service = _FriendService(empty: true, friend_count: 1);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [friendServiceProvider.overrideWithValue(service)],
        child: const CupertinoApp(home: FriendListPage()),
      ),
    );
    await tester.pumpAndSettle();
    final pending_load = Completer<void>();
    service.pending_load = pending_load;
    await tester.drag(find.text('아직 친구가 없습니다'), const Offset(0, 320));
    await tester.pump(const Duration(milliseconds: 500));
    expect(service.load_count, 2);
    expect(find.byType(CupertinoSliverRefreshControl), findsOneWidget);
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 320));
    await tester.pump(const Duration(milliseconds: 500));
    expect(service.load_count, 2);
    service.empty = false;
    pending_load.complete();
    await tester.pumpAndSettle();
    expect(find.text('친구 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 친구 오류 화면도 당겨 재시도하고 빈 목록으로 복구한다', (tester) async {
    final service = _FriendService(empty: true, fail: true);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [friendServiceProvider.overrideWithValue(service)],
        child: const CupertinoApp(home: FriendListPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('다시 시도'), findsOneWidget);
    service.fail = false;
    await tester.drag(find.text('다시 시도'), const Offset(0, 320));
    await tester.pumpAndSettle();
    expect(service.load_count, 2);
    expect(find.text('아직 친구가 없습니다'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final scenario in [
    (size: const Size(568, 320), scale: 1.0),
    (size: const Size(667, 375), scale: 1.0),
    (size: const Size(320, 568), scale: 2.0),
    (size: const Size(320, 568), scale: 3.2),
  ]) {
    for (final fail in [false, true]) {
      testWidgets('빈 친구·오류 화면은 작은 높이와 큰 글자에서도 액션에 접근한다 $scenario $fail', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(scenario.size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final service = _FriendService(empty: true, fail: fail);
        await tester.pumpWidget(
          ProviderScope(
            overrides: [friendServiceProvider.overrideWithValue(service)],
            child: CupertinoApp(
              theme: AppTheme.lightTheme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  size: scenario.size,
                  textScaler: TextScaler.linear(scenario.scale),
                  padding: const EdgeInsets.only(top: 20, bottom: 34),
                  viewPadding: const EdgeInsets.only(top: 20, bottom: 34),
                ),
                child: child!,
              ),
              home: const FriendListPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final action = find.text(fail ? '다시 시도' : '친구 추가하기');
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        expect(action.hitTestable(), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(action);
        await tester.pumpAndSettle();
        if (fail) {
          expect(service.load_count, 2);
        } else {
          expect(find.byType(AddFriendModal), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  }

  for (final size in [
    const Size(390, 800),
    const Size(375, 667),
    const Size(844, 390),
  ]) {
    testWidgets('친구·그룹 양방향 스와이프와 탭 전환은 목록 위치를 보존한다: $size', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = _GroupRepository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            friendServiceProvider.overrideWithValue(_FriendService()),
            groupRepositoryProvider.overrideWithValue(repository),
          ],
          child: CupertinoApp(
            theme: AppTheme.lightTheme,
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: const FriendListPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pages = find.byKey(const ValueKey('friend-group-page-view'));
      final page_controller = tester.widget<PageView>(pages).controller!;
      final friend_list = find.byType(CustomScrollView).hitTestable();
      final friend_position = tester
          .state<ScrollableState>(
            find.descendant(of: friend_list, matching: find.byType(Scrollable)),
          )
          .position;
      await tester.drag(friend_list, const Offset(0, -180));
      await tester.pumpAndSettle();
      final friend_offset = friend_position.pixels;
      expect(friend_offset, greaterThan(0));
      expect(page_controller.page, 0);
      expect(repository.load_count, 0);

      await tester.drag(pages, Offset(-size.width * 0.8, 0));
      await tester.pumpAndSettle();
      expect(page_controller.page, 1);
      expect(find.text('그룹 방'), findsOneWidget);
      expect(find.byKey(const ValueKey('add-friend-button')), findsNothing);
      expect(_selectedSectionIndex(tester), 1);
      expect(repository.load_count, AppConstants.group_api_enabled ? 1 : 0);
      expect(
        find.byKey(const ValueKey('create-group-button')),
        AppConstants.group_api_enabled ? findsOneWidget : findsNothing,
      );

      ScrollPosition? group_position;
      double? group_offset;
      if (AppConstants.group_api_enabled) {
        final groups = find.byKey(const ValueKey('group-room-api-list'));
        group_position = tester
            .state<ScrollableState>(
              find.descendant(of: groups, matching: find.byType(Scrollable)),
            )
            .position;
        await tester.drag(groups, const Offset(0, -180));
        await tester.pumpAndSettle();
        group_offset = group_position.pixels;
        expect(group_offset, greaterThan(0));
        expect(page_controller.page, 1);
      }

      await tester.drag(pages, Offset(size.width * 0.8, 0));
      await tester.pumpAndSettle();
      expect(page_controller.page, 0);
      expect(friend_position.pixels, friend_offset);
      expect(find.byKey(const ValueKey('add-friend-button')), findsOneWidget);
      expect(_selectedSectionIndex(tester), 0);

      await tester.tap(find.byKey(const ValueKey('group-room-footer-button')));
      await tester.pumpAndSettle();
      expect(page_controller.page, 1);
      if (group_position != null) expect(group_position.pixels, group_offset);
      expect(repository.load_count, AppConstants.group_api_enabled ? 1 : 0);
      await tester.tap(find.byKey(const ValueKey('friend-list-footer-button')));
      await tester.pumpAndSettle();
      expect(page_controller.page, 0);
      expect(friend_position.pixels, friend_offset);
      expect(_headerBackground(tester).color, AppTheme.background_color);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('동작 줄이기에서 세그먼트는 즉시 전환하고 스와이프도 유지한다', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendServiceProvider.overrideWithValue(_FriendService()),
          groupRepositoryProvider.overrideWithValue(_GroupRepository()),
        ],
        child: CupertinoApp(
          theme: AppTheme.darkTheme,
          home: const MediaQuery(
            data: MediaQueryData(
              size: Size(800, 600),
              disableAnimations: true,
              textScaler: TextScaler.linear(2),
            ),
            child: FriendListPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final pages = find.byKey(const ValueKey('friend-group-page-view'));
    final page_controller = tester.widget<PageView>(pages).controller!;
    await tester.tap(find.byKey(const ValueKey('group-room-footer-button')));
    await tester.pump();
    expect(page_controller.page, 1);
    await tester.pumpAndSettle();
    await tester.drag(pages, const Offset(640, 0));
    await tester.pumpAndSettle();
    expect(page_controller.page, 0);
    expect(find.byKey(const ValueKey('add-friend-button')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('친구·그룹 목록 스크롤과 세그먼트 전환에도 헤더 배경을 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          friendServiceProvider.overrideWithValue(_FriendService()),
          groupRepositoryProvider.overrideWithValue(_GroupRepository()),
        ],
        child: CupertinoApp(
          theme: AppTheme.lightTheme,
          home: const MediaQuery(
            data: MediaQueryData(size: Size(390, 800)),
            child: FriendListPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final initial_background = _headerBackground(tester);
    expect(initial_background.color, AppTheme.background_color);
    expect(initial_background.border, isNull);
    final friends = find.byType(CustomScrollView);
    final friend_position = tester
        .state<ScrollableState>(
          find.descendant(of: friends, matching: find.byType(Scrollable)),
        )
        .position;
    await tester.drag(friends, const Offset(0, -180));
    await tester.pumpAndSettle();
    final friend_offset = friend_position.pixels;
    expect(friend_offset, greaterThan(0));
    expect(_headerBackground(tester), initial_background);

    await tester.tap(find.byKey(const ValueKey('group-room-footer-button')));
    await tester.pumpAndSettle();
    expect(find.text('그룹 방'), findsOneWidget);
    expect(_headerBackground(tester), initial_background);
    final groups = find.byKey(
      ValueKey(
        AppConstants.group_api_enabled
            ? 'group-room-api-list'
            : 'group-room-list',
      ),
    );
    if (AppConstants.group_api_enabled) {
      final group_position = tester
          .state<ScrollableState>(
            find.descendant(of: groups, matching: find.byType(Scrollable)),
          )
          .position;
      await tester.drag(groups, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(group_position.pixels, greaterThan(0));
      expect(_headerBackground(tester), initial_background);
      group_position.jumpTo(0);
      await tester.pumpAndSettle();
    } else {
      expect(
        find.byKey(const ValueKey('group-room-preview-card')),
        findsOneWidget,
      );
      await tester.drag(groups, const Offset(0, -180));
      await tester.pumpAndSettle();
    }
    expect(_headerBackground(tester), initial_background);

    await tester.tap(find.byKey(const ValueKey('friend-list-footer-button')));
    await tester.pumpAndSettle();
    expect(friend_position.pixels, friend_offset);
    expect(_headerBackground(tester), initial_background);
    friend_position.jumpTo(0);
    await tester.pumpAndSettle();
    expect(_headerBackground(tester), initial_background);
    expect(tester.takeException(), isNull);
  });
}
