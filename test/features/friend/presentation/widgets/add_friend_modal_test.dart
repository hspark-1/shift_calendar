// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/personal_event_form_modal.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/data/models/friend_request_model.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/presentation/providers/friend_provider.dart';
import 'package:shift_mate/features/friend/presentation/widgets/add_friend_modal.dart';

SearchUserModel makeUser({bool is_friend = false, String? direction}) =>
    SearchUserModel(
      userId: 'friend-user-id',
      name: '김하나',
      email: 'hana@example.com',
      isFriend: is_friend,
      hasPendingRequest: direction != null,
      pendingRequestDirection: direction,
    );

class _FakeFriendService extends FriendService {
  _FakeFriendService() : super(Dio());

  final queries = <String>[];
  final sent_user_ids = <String>[];
  SearchUserModel user = makeUser();
  Future<SearchUserResponse> Function(String)? on_search;
  Completer<void>? send_gate;
  bool fail_send = false;
  int sent_load_count = 0;

  @override
  Future<SearchUserResponse> searchUser(String query) async {
    queries.add(query);
    if (on_search != null) return on_search!(query);
    return SearchUserResponse(success: true, user: user);
  }

  @override
  Future<SendFriendRequestResponse> sendFriendRequest({
    required String addresseeUserId,
    String? message,
  }) async {
    sent_user_ids.add(addresseeUserId);
    await send_gate?.future;
    if (fail_send) {
      throw ApiException(code: 'NETWORK_ERROR', message: '연결을 확인한 뒤 다시 보내주세요.');
    }
    return SendFriendRequestResponse(
      success: true,
      data: FriendRequestData(
        requestId: 'request-id',
        requesterUserId: 'owner-id',
        addresseeUserId: addresseeUserId,
        status: FriendRequestStatus.pending,
        createdAt: DateTime.utc(2026, 11, 13),
      ),
      message: '요청 완료',
    );
  }

  @override
  Future<SentRequestsResponse> getSentRequests({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    sent_load_count++;
    return SentRequestsResponse(
      success: true,
      data: SentRequestsData(
        requests: [],
        pagination: PaginationInfo(page: 1, limit: 20, total: 0, totalPages: 1),
      ),
    );
  }
}

Widget _buildTestApp({
  _FakeFriendService? service,
  double keyboard_height = 0,
  Size size = const Size(390, 844),
  double text_scale = 1,
  EdgeInsets view_padding = EdgeInsets.zero,
  Widget? sheet,
  bool dark = false,
  bool reduce_motion = false,
  GlobalKey? capture_key,
  bool popup = false,
  ValueChanged<bool?>? on_close,
}) {
  return ProviderScope(
    overrides: [
      friendServiceProvider.overrideWithValue(service ?? _FakeFriendService()),
    ],
    child: CupertinoApp(
      theme: AppTheme.lightTheme.copyWith(
        brightness: dark ? Brightness.dark : Brightness.light,
      ),
      builder: (context, child) => RepaintBoundary(
        key: capture_key,
        child: MediaQuery(
          data: MediaQueryData(
            size: size,
            viewInsets: EdgeInsets.only(bottom: keyboard_height),
            padding: EdgeInsets.only(top: view_padding.top, bottom: 24),
            viewPadding: view_padding,
            textScaler: TextScaler.linear(text_scale),
            disableAnimations: reduce_motion,
          ),
          child: child!,
        ),
      ),
      home: CupertinoPageScaffold(
        resizeToAvoidBottomInset: false,
        child: popup
            ? Builder(
                builder: (context) => Center(
                  child: CupertinoButton(
                    onPressed: () async {
                      final result = await showCupertinoModalPopup<bool>(
                        context: context,
                        builder: (_) => sheet ?? const AddFriendModal(),
                      );
                      on_close?.call(result);
                    },
                    child: const Text('친구 추가 열기'),
                  ),
                ),
              )
            : Align(
                alignment: Alignment.bottomCenter,
                child: sheet ?? const AddFriendModal(),
              ),
      ),
    ),
  );
}

Finder get searchInput => find.byKey(const ValueKey('add-friend-search-input'));
Finder get searchButton =>
    find.byKey(const ValueKey('add-friend-search-button'));
Finder get sendButton => find.byKey(const ValueKey('add-friend-send-button'));
Finder get contentScroll => find
    .descendant(
      of: find.byKey(const ValueKey('add-friend-content')),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> search(
  WidgetTester tester, [
  String query = 'hana@example.com',
]) async {
  await tester.ensureVisible(searchInput);
  await tester.enterText(searchInput, '');
  await tester.enterText(searchInput, query);
  await tester.pumpAndSettle();
  await tester.ensureVisible(searchButton);
  await tester.tap(searchButton);
  await tester.pumpAndSettle();
}

Future<void> reveal(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 120, scrollable: contentScroll);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
}

Future<void> capture(
  WidgetTester tester,
  GlobalKey capture_key,
  String name,
) async {
  final output_path = Platform.environment['ADD_FRIEND_RENDER_OUTPUT'];
  if (output_path == null) return;
  final boundary =
      capture_key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final output = Directory(output_path)..createSync(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    File(
      '${output.path}/$name.png',
    ).writeAsBytesSync(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
    for (final entry in {
      'Cafe24SsurroundAir': 'assets/fonts/Cafe24SsurroundAir-v1.1.ttf',
      'Cafe24Ssurround': 'assets/fonts/Cafe24Ssurround-v2.0.ttf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
  });

  testWidgets('검색 전에는 입력과 안내만 표시하고 입력/버튼 터치 크기를 확보한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final capture_key = GlobalKey();
    await tester.pumpWidget(_buildTestApp(capture_key: capture_key));
    await tester.pumpAndSettle();
    expect(find.text('이메일 또는 전화번호'), findsOneWidget);
    expect(find.text('검색 결과'), findsNothing);
    expect(find.byKey(const ValueKey('add-friend-profile')), findsNothing);
    expect(find.text('친구 찾기'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('add-friend-sheet'))).height,
      lessThan(400),
    );
    expect(tester.getSize(searchInput).height, greaterThanOrEqualTo(52));
    expect(tester.getSize(searchButton).height, greaterThanOrEqualTo(52));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('add-friend-close-button')))
          .width,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getTopLeft(searchButton).dy,
      greaterThan(tester.getBottomRight(searchInput).dy),
    );
    await capture(tester, capture_key, 'initial_390');
  });

  testWidgets('입력 오류는 필드 아래에 남고 잘못된 입력은 API를 호출하지 않는다', (tester) async {
    final service = _FakeFriendService();
    await tester.pumpWidget(_buildTestApp(service: service));
    await tester.pumpAndSettle();
    await tester.tap(searchButton);
    await tester.pump();
    expect(find.text('이메일 또는 전화번호를 입력해주세요.'), findsOneWidget);
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('add-friend-validation-error')))
          .dy,
      greaterThan(tester.getBottomRight(searchInput).dy),
    );
    await tester.enterText(searchInput, '잘못된 입력');
    await tester.tap(searchButton);
    await tester.pump();
    expect(find.text('이메일 또는 전화번호 형식으로 입력해주세요.'), findsOneWidget);
    expect(service.queries, isEmpty);
    await tester.enterText(searchInput, 'hana@example.com');
    await tester.pump();
    expect(
      find.byKey(const ValueKey('add-friend-validation-error')),
      findsNothing,
    );
  });

  for (final query in ['01012345678', '+82 10-1234-5678', '010-1234-5678']) {
    testWidgets('전화번호 $query 검색은 기존 국내 형식 정규화를 유지한다', (tester) async {
      final service = _FakeFriendService();
      await tester.pumpWidget(_buildTestApp(service: service));
      await tester.pumpAndSettle();
      await search(tester, query);
      expect(service.queries, ['010-1234-5678']);
      expect(find.text('김하나'), findsOneWidget);
    });
  }

  testWidgets('키보드 검색과 지우기, 외부 터치 포커스 해제를 지원한다', (tester) async {
    final service = _FakeFriendService();
    await tester.pumpWidget(_buildTestApp(service: service));
    await tester.pumpAndSettle();
    await tester.enterText(searchInput, 'hana@example.com');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(service.queries, ['hana@example.com']);
    await tester.tap(searchInput);
    await tester.pump();
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.focusNode.hasFocus, isTrue);
    await tester.tap(find.text('이메일 또는 전화번호'));
    await tester.pump();
    expect(editable.focusNode.hasFocus, isFalse);
    await tester.tap(find.byKey(const ValueKey('add-friend-clear-button')));
    await tester.pump();
    expect(editable.controller.text, isEmpty);
    expect(find.text('김하나'), findsNothing);
  });

  testWidgets('입력 수정 후 이전 검색의 늦은 응답과 오류를 표시하지 않는다', (tester) async {
    final service = _FakeFriendService();
    final first = Completer<SearchUserResponse>();
    final second = Completer<SearchUserResponse>();
    service.on_search = (query) =>
        query.startsWith('old') ? first.future : second.future;
    await tester.pumpWidget(_buildTestApp(service: service));
    await tester.pumpAndSettle();
    await tester.enterText(searchInput, 'old@example.com');
    await tester.tap(searchButton);
    await tester.pump();
    expect(tester.widget<CupertinoButton>(searchButton).onPressed, isNull);
    await tester.enterText(searchInput, 'new@example.com');
    await tester.pump();
    await tester.tap(searchButton);
    second.complete(SearchUserResponse(success: true, user: makeUser()));
    await tester.pumpAndSettle();
    first.completeError(
      ApiException(code: 'USER_NOT_FOUND', message: '이전 검색 오류'),
    );
    await tester.pumpAndSettle();
    expect(find.text('김하나'), findsOneWidget);
    expect(find.text('일치하는 사용자가 없어요.'), findsNothing);
    expect(service.queries, ['old@example.com', 'new@example.com']);
  });

  test('검색 초기화와 notifier 해제 뒤 도착한 응답을 버린다', () async {
    final service = _FakeFriendService();
    final pending = Completer<SearchUserResponse>();
    service.on_search = (_) => pending.future;
    final notifier = SearchUserNotifier(service);
    final operation = notifier.searchUser('hana@example.com');
    notifier.reset();
    pending.complete(SearchUserResponse(success: true, user: makeUser()));
    await operation;
    expect(notifier.state.user, isNull);
    expect(notifier.state.hasSearched, isFalse);
    final disposed_pending = Completer<SearchUserResponse>();
    service.on_search = (_) => disposed_pending.future;
    final disposed_operation = notifier.searchUser('hana@example.com');
    notifier.dispose();
    disposed_pending.complete(
      SearchUserResponse(success: true, user: makeUser()),
    );
    await disposed_operation;
  });

  for (final not_found in [true, false]) {
    testWidgets('검색 ${not_found ? '결과 없음' : '통신 실패'}을 구분하고 재검색한다', (
      tester,
    ) async {
      final service = _FakeFriendService();
      service.on_search = (_) async => throw ApiException(
        code: not_found ? 'USER_NOT_FOUND' : 'NETWORK_ERROR',
        message: '연결 확인 안내',
      );
      await tester.pumpWidget(_buildTestApp(service: service));
      await tester.pumpAndSettle();
      await search(tester);
      expect(
        find.text(not_found ? '일치하는 사용자가 없어요.' : '연결 확인 안내'),
        findsOneWidget,
      );
      expect(find.text('다시 시도'), not_found ? findsNothing : findsOneWidget);
      service.on_search = null;
      await tester.tap(not_found ? searchButton : find.text('다시 시도'));
      await tester.pumpAndSettle();
      expect(find.text('김하나'), findsOneWidget);
    });
  }

  testWidgets('요청 중 중복 전송을 막고 단일 완료 버튼으로 바뀐다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeFriendService()..send_gate = Completer<void>();
    final capture_key = GlobalKey();
    await tester.pumpWidget(
      _buildTestApp(service: service, capture_key: capture_key),
    );
    await tester.pumpAndSettle();
    await search(tester);
    await reveal(tester, sendButton);
    await capture(tester, capture_key, 'result_390');
    await tester.tap(sendButton);
    await tester.pump();
    expect(tester.widget<CupertinoButton>(sendButton).onPressed, isNull);
    expect(tester.widget<CupertinoTextField>(searchInput).enabled, isFalse);
    await tester.tap(sendButton);
    expect(service.sent_user_ids, ['friend-user-id']);
    service.send_gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AddFriendModal), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.text('요청을 보냈어요 · 수락 대기 중'), findsOneWidget);
    expect(service.sent_load_count, 1);
    expect(
      tester
          .getBottomRight(find.byKey(const ValueKey('add-friend-done-button')))
          .dy,
      lessThanOrEqualTo(844 - 24),
    );
    expect(
      tester
          .getBottomRight(find.byKey(const ValueKey('add-friend-done-button')))
          .dy,
      lessThanOrEqualTo(
        tester
            .getBottomRight(find.byKey(const ValueKey('add-friend-content')))
            .dy,
      ),
    );
    await capture(tester, capture_key, 'sent_390');
    await tester.ensureVisible(searchInput);
    await search(tester);
    expect(sendButton, findsNothing);
    expect(find.text('요청을 보냈어요 · 수락 대기 중'), findsOneWidget);
  });

  testWidgets('요청 실패 시 상대와 입력을 유지하고 같은 버튼으로 재시도한다', (tester) async {
    final service = _FakeFriendService()..fail_send = true;
    await tester.pumpWidget(_buildTestApp(service: service));
    await tester.pumpAndSettle();
    await search(tester);
    await reveal(tester, sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();
    expect(find.text('연결을 확인한 뒤 다시 보내주세요.'), findsOneWidget);
    expect(find.text('김하나'), findsOneWidget);
    service.fail_send = false;
    await tester.tap(sendButton);
    await tester.pumpAndSettle();
    expect(find.text('요청을 보냈어요 · 수락 대기 중'), findsOneWidget);
    expect(service.sent_user_ids.length, 2);
  });

  for (final direction in ['friend', 'sent', 'received']) {
    testWidgets('$direction 관계를 표시하고 받은 요청 확인은 시트를 닫아 목적지를 반환한다', (
      tester,
    ) async {
      final service = _FakeFriendService()
        ..user = makeUser(
          is_friend: direction == 'friend',
          direction: direction == 'friend' ? null : direction,
        );
      bool? destination;
      await tester.pumpWidget(
        _buildTestApp(
          service: service,
          popup: true,
          on_close: (value) => destination = value,
        ),
      );
      await tester.tap(find.text('친구 추가 열기'));
      await tester.pumpAndSettle();
      await search(tester);
      expect(sendButton, findsNothing);
      if (direction == 'friend') {
        expect(find.text('이미 친구입니다'), findsOneWidget);
      }
      if (direction == 'sent') {
        expect(find.text('요청을 보냈어요 · 수락 대기 중'), findsOneWidget);
      }
      if (direction == 'received') {
        final action = find.byKey(
          const ValueKey('add-friend-received-request-button'),
        );
        await reveal(tester, action);
        await tester.tap(action);
        await tester.pumpAndSettle();
        expect(destination, isTrue);
        expect(find.byType(AddFriendModal), findsNothing);
      }
    });
  }

  testWidgets('요청 중 닫힌 시트는 응답 후 setState나 대화상자를 실행하지 않는다', (tester) async {
    final service = _FakeFriendService()..send_gate = Completer<void>();
    await tester.pumpWidget(_buildTestApp(service: service, popup: true));
    await tester.tap(find.text('친구 추가 열기'));
    await tester.pumpAndSettle();
    await search(tester);
    await reveal(tester, sendButton);
    await tester.tap(sendButton);
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add-friend-close-button')));
    await tester.pumpAndSettle();
    service.send_gate!.complete();
    await tester.pumpAndSettle();
    expect(find.byType(AddFriendModal), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('드래그 프레임 뒤 확대는 즉시 뛰지 않고 중간 높이를 거친다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final capture_key = GlobalKey();
    await tester.pumpWidget(_buildTestApp(capture_key: capture_key));
    await tester.pumpAndSettle();
    final visible = find
        .descendant(
          of: find.byType(AddFriendModal),
          matching: find.byType(AnimatedContainer),
        )
        .first;
    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    final initial = tester.getRect(visible);
    await capture(tester, capture_key, 'motion_before');
    final gesture = await tester.startGesture(tester.getCenter(header));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(tester.getSize(visible).height, closeTo(initial.height, 0.1));
    await capture(tester, capture_key, 'motion_release');
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.getSize(visible).height, greaterThan(initial.height));
    expect(tester.getSize(visible).height, lessThan(844 * 0.88));
    final surface = find.byKey(const ValueKey('add-friend-visible-surface'));
    expect(
      tester.getTopLeft(header).dy,
      closeTo(tester.getTopLeft(surface).dy, 0.1),
    );
    expect(tester.getBottomRight(surface).dy, closeTo(initial.bottom, 0.1));
    await capture(tester, capture_key, 'motion_mid');
    await tester.pumpAndSettle();
    expect(tester.getSize(visible).height, closeTo(844 * 0.88, 0.1));
    await capture(tester, capture_key, 'motion_after');
  });

  testWidgets('키보드가 있어도 단계 전환은 보간하고 키보드 프레임은 즉시 반영한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeFriendService();
    await tester.pumpWidget(
      _buildTestApp(service: service, keyboard_height: 320),
    );
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('add-friend-visible-surface'));
    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    final initial_height = tester.getSize(surface).height;
    final gesture = await tester.startGesture(tester.getCenter(header));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(tester.getSize(surface).height, closeTo(initial_height, 0.1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.getSize(surface).height,
      inExclusiveRange(initial_height, 844 - 320 - 12),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(surface).height, closeTo(844 - 320 - 12, 0.1));
    for (final inset in [280.0, 200.0, 100.0]) {
      await tester.pumpWidget(
        _buildTestApp(service: service, keyboard_height: inset),
      );
      await tester.pump();
      expect(tester.getSize(surface).height, closeTo(844 - inset - 12, 0.1));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('동작 줄이기에서는 실제 드래그 프레임 뒤에도 즉시 단계만 바뀐다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildTestApp(reduce_motion: true));
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    final surface = find.byKey(const ValueKey('add-friend-visible-surface'));
    final initial_height = tester.getSize(surface).height;
    final gesture = await tester.startGesture(tester.getCenter(header));
    await gesture.moveBy(const Offset(0, -20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(tester.getSize(surface).height, closeTo(844 * 0.88, 0.1));
    await tester.drag(header, const Offset(0, 200));
    await tester.pump();
    expect(tester.getSize(surface).height, closeTo(initial_height, 0.1));
    expect(find.byType(AddFriendModal), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('확대 도중 반대 제스처도 현재 높이에서 기본 단계로 부드럽게 돌아온다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    final surface = find.byKey(const ValueKey('add-friend-visible-surface'));
    final initial_height = tester.getSize(surface).height;
    await tester.drag(header, const Offset(0, -100));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    final intermediate = tester.getSize(surface).height;
    expect(intermediate, inExclusiveRange(initial_height, 844 * 0.88));
    final gesture = await tester.startGesture(tester.getCenter(header));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 80));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(tester.getSize(surface).height, closeTo(intermediate, 0.1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.getSize(surface).height,
      inExclusiveRange(initial_height, intermediate),
    );
    await tester.pumpAndSettle();
    expect(tester.getSize(surface).height, closeTo(initial_height, 0.1));
  });

  testWidgets('헤더를 놓으면 기본 또는 최대 높이로만 정착하고 아래로 밀면 닫힌다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final capture_key = GlobalKey();
    await tester.pumpWidget(
      _buildTestApp(popup: true, capture_key: capture_key),
    );
    await tester.tap(find.text('친구 추가 열기'));
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    final sheet = find.byKey(const ValueKey('add-friend-sheet'));
    final initial_height = tester.getSize(sheet).height;
    await tester.fling(header, const Offset(0, 35), 2000);
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(initial_height, 0.1));
    await tester.drag(header, const Offset(0, -35));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(initial_height, 0.1));
    await tester.drag(header, const Offset(0, -100));
    await tester.pumpAndSettle();
    final expanded_height = tester.getSize(sheet).height;
    expect(expanded_height, closeTo(844 * 0.88, 0.1));
    await capture(tester, capture_key, 'expanded_390');
    await tester.drag(header, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(expanded_height, 0.1));
    await tester.drag(header, const Offset(0, 35));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(expanded_height, 0.1));
    await tester.drag(header, const Offset(0, 85));
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(initial_height, 0.1));
    await tester.drag(header, const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.byType(AddFriendModal), findsNothing);
  });

  testWidgets('드래그 중에도 크기를 바꾸지 않고 취소하면 같은 단계로 복귀한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    final sheet = find.byKey(const ValueKey('add-friend-sheet'));
    final initial_height = tester.getSize(sheet).height;
    final gesture = await tester.startGesture(tester.getCenter(header));
    await gesture.moveBy(const Offset(0, -180));
    await tester.pump();
    expect(tester.getSize(sheet).height, closeTo(initial_height, 0.1));
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(initial_height, 0.1));
  });

  testWidgets('최대 높이에서 검색·입력 수정·요청을 해도 최대 단계를 유지한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildTestApp());
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    final sheet = find.byKey(const ValueKey('add-friend-sheet'));
    await tester.drag(header, const Offset(0, -100));
    await tester.pumpAndSettle();
    final expanded_height = tester.getSize(sheet).height;
    await search(tester);
    expect(tester.getSize(sheet).height, closeTo(expanded_height, 0.1));
    await tester.enterText(searchInput, 'other@example.com');
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(expanded_height, 0.1));
    expect(sendButton, findsNothing);
    await search(tester);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();
    expect(tester.getSize(sheet).height, closeTo(expanded_height, 0.1));
    expect(find.text('요청을 보냈어요 · 수락 대기 중'), findsOneWidget);
  });

  testWidgets('최대에서 길게 내려도 먼저 기본으로 접고 다음 제스처에서 닫힌다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_buildTestApp(popup: true));
    await tester.tap(find.text('친구 추가 열기'));
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    await tester.drag(header, const Offset(0, -100));
    await tester.pumpAndSettle();
    final surface = find.byKey(const ValueKey('add-friend-visible-surface'));
    final expanded_height = tester.getSize(surface).height;
    final gesture = await tester.startGesture(tester.getCenter(header));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(tester.getSize(surface).height, closeTo(expanded_height, 0.1));
    await tester.pump(const Duration(milliseconds: 80));
    expect(
      tester.getSize(surface).height,
      inExclusiveRange(400, expanded_height),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AddFriendModal), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('add-friend-sheet'))).height,
      lessThan(400),
    );
    await tester.drag(header, const Offset(0, 200));
    await tester.pumpAndSettle();
    expect(find.byType(AddFriendModal), findsNothing);
  });

  for (final scenario in [
    (size: const Size(390, 844), keyboard: 0.0, top: 44.0),
    (size: const Size(375, 667), keyboard: 0.0, top: 20.0),
    (size: const Size(667, 375), keyboard: 0.0, top: 0.0),
    (size: const Size(390, 844), keyboard: 320.0, top: 44.0),
    (size: const Size(768, 1024), keyboard: 0.0, top: 24.0),
  ]) {
    testWidgets('최대 높이는 개인 일정 추가와 같다: $scenario', (tester) async {
      await tester.binding.setSurfaceSize(scenario.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _buildTestApp(
          size: scenario.size,
          keyboard_height: scenario.keyboard,
          view_padding: EdgeInsets.only(top: scenario.top),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(
        find.byKey(const ValueKey('add-friend-modal-header')),
        const Offset(0, -100),
      );
      await tester.pumpAndSettle();
      final friend_height = tester
          .getSize(find.byKey(const ValueKey('add-friend-sheet')))
          .height;
      await tester.pumpWidget(
        _buildTestApp(
          size: scenario.size,
          keyboard_height: scenario.keyboard,
          view_padding: EdgeInsets.only(top: scenario.top),
          sheet: PersonalEventFormModal(initialDate: DateTime(2026, 11, 13)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const Key('personal-event-sheet'))).height,
        closeTo(friend_height, 0.1),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('키보드가 내려가는 동안 내용 높이 이상으로 커지지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeFriendService();
    final sheet = find.byKey(const ValueKey('add-friend-sheet'));
    await tester.pumpWidget(_buildTestApp(service: service));
    await tester.pumpAndSettle();
    final natural_height = tester.getSize(sheet).height;
    for (final keyboard_height in [480.0, 300.0, 100.0, 0.0]) {
      await tester.pumpWidget(
        _buildTestApp(service: service, keyboard_height: keyboard_height),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(sheet).height,
        lessThanOrEqualTo(natural_height + 0.1),
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('한 계정을 찾으면 버튼을 교체하고 입력 수정 시 확인한 계정을 지운다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeFriendService();
    await tester.pumpWidget(_buildTestApp(service: service));
    await tester.pumpAndSettle();
    final sheet = find.byKey(const ValueKey('add-friend-sheet'));
    final initial_height = tester.getSize(sheet).height;
    await search(tester);
    expect(find.byKey(const ValueKey('add-friend-profile')), findsOneWidget);
    expect(searchButton, findsNothing);
    expect(sendButton, findsOneWidget);
    expect(find.text('검색 결과'), findsNothing);
    expect(find.byKey(const ValueKey('add-friend-user-card')), findsNothing);
    expect(tester.getSize(sheet).height, greaterThan(initial_height));
    expect(tester.getSize(sheet).height, lessThan(600));
    await tester.tap(searchInput);
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();
    expect(service.sent_user_ids, isEmpty);
    expect(service.queries.length, 1);
    await tester.enterText(searchInput, 'other@example.com');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('add-friend-profile')), findsNothing);
    expect(sendButton, findsNothing);
    expect(searchButton, findsOneWidget);
    expect(service.sent_user_ids, isEmpty);
    expect(tester.getSize(sheet).height, closeTo(initial_height, 0.1));
  });

  testWidgets('키보드 높이와 애니메이션 경로가 바뀌어도 입력과 포커스를 보존한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final service = _FakeFriendService();
    await tester.pumpWidget(_buildTestApp(service: service));
    await tester.pumpAndSettle();
    await tester.enterText(searchInput, 'hana@example.com');
    final editable = tester.widget<EditableText>(find.byType(EditableText));
    for (final keyboard_height in [320.0, 100.0, 0.0]) {
      await tester.pumpWidget(
        _buildTestApp(service: service, keyboard_height: keyboard_height),
      );
      await tester.pumpAndSettle();
      final current = tester.widget<EditableText>(find.byType(EditableText));
      expect(current.controller.text, 'hana@example.com');
      expect(current.focusNode, same(editable.focusNode));
      expect(current.focusNode.hasFocus, isTrue);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('요청 완료 후 완료 버튼으로 시트를 닫는다', (tester) async {
    final service = _FakeFriendService();
    await tester.pumpWidget(_buildTestApp(service: service, popup: true));
    await tester.tap(find.text('친구 추가 열기'));
    await tester.pumpAndSettle();
    await search(tester);
    await reveal(tester, sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();
    expect(searchButton, findsNothing);
    expect(sendButton, findsNothing);
    final done = find.byKey(const ValueKey('add-friend-done-button'));
    await reveal(tester, done);
    expect(find.text('김하나'), findsOneWidget);
    expect(find.text('요청을 보냈어요 · 수락 대기 중'), findsOneWidget);
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.byType(AddFriendModal), findsNothing);
    expect(service.sent_user_ids, ['friend-user-id']);
  });

  for (final scenario in [
    (
      name: 'small320',
      size: const Size(320, 568),
      scale: 1.0,
      keyboard: 0.0,
      dark: false,
    ),
    (
      name: 'small375',
      size: const Size(375, 667),
      scale: 1.0,
      keyboard: 0.0,
      dark: false,
    ),
    (
      name: 'normal',
      size: const Size(390, 844),
      scale: 1.0,
      keyboard: 0.0,
      dark: false,
    ),
    (
      name: 'landscape',
      size: const Size(667, 375),
      scale: 1.0,
      keyboard: 0.0,
      dark: false,
    ),
    (
      name: 'tablet',
      size: const Size(768, 1024),
      scale: 1.0,
      keyboard: 0.0,
      dark: false,
    ),
    (
      name: 'large_text',
      size: const Size(375, 667),
      scale: 3.2,
      keyboard: 0.0,
      dark: false,
    ),
    (
      name: 'keyboard',
      size: const Size(390, 844),
      scale: 1.1,
      keyboard: 480.0,
      dark: false,
    ),
    (
      name: 'dark_reduce_motion',
      size: const Size(375, 667),
      scale: 1.0,
      keyboard: 0.0,
      dark: true,
    ),
  ]) {
    testWidgets('${scenario.name}에서 계정 확인·단일 요청·완료에 스크롤로 접근한다', (tester) async {
      await tester.binding.setSurfaceSize(scenario.size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final capture_key = GlobalKey();
      await tester.pumpWidget(
        _buildTestApp(
          size: scenario.size,
          text_scale: scenario.scale,
          keyboard_height: scenario.keyboard,
          dark: scenario.dark,
          reduce_motion: scenario.dark,
          capture_key: capture_key,
        ),
      );
      await tester.pumpAndSettle();
      final header = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('add-friend-header-background')),
      );
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('add-friend-modal-title')),
      );
      final header_color = Color.alphaBlend(
        (header.decoration as BoxDecoration).color!,
        AppTheme.background_color,
      );
      final title_luminance = title.style!.color!.computeLuminance();
      final header_luminance = header_color.computeLuminance();
      final contrast = title_luminance > header_luminance
          ? (title_luminance + 0.05) / (header_luminance + 0.05)
          : (header_luminance + 0.05) / (title_luminance + 0.05);
      expect(contrast, greaterThanOrEqualTo(4.5));
      await reveal(tester, searchInput);
      await tester.enterText(searchInput, 'hana@example.com');
      await reveal(tester, searchButton);
      await tester.tap(searchButton);
      await tester.pumpAndSettle();
      await reveal(tester, sendButton);
      final button_rect = tester.getRect(sendButton);
      final content_rect = tester.getRect(
        find.byKey(const ValueKey('add-friend-content')),
      );
      expect(button_rect.height, greaterThanOrEqualTo(52));
      expect(button_rect.left, greaterThanOrEqualTo(content_rect.left));
      expect(button_rect.right, lessThanOrEqualTo(content_rect.right));
      expect(button_rect.bottom, lessThanOrEqualTo(content_rect.bottom + 0.1));
      await capture(tester, capture_key, scenario.name);
      await tester.tap(sendButton);
      await tester.pumpAndSettle();
      final done = find.byKey(const ValueKey('add-friend-done-button'));
      await reveal(tester, done);
      expect(find.text('요청을 보냈어요 · 수락 대기 중'), findsOneWidget);
      expect(searchButton, findsNothing);
      expect(sendButton, findsNothing);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('add-friend-primary-action')),
          matching: find.byType(CupertinoButton),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
