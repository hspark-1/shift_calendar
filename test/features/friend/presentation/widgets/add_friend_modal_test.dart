// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_calendar/core/theme/app_theme.dart';
import 'package:shift_calendar/features/friend/data/services/friend_service.dart';
import 'package:shift_calendar/features/friend/presentation/widgets/add_friend_modal.dart';

class _FakeFriendService extends FriendService {
  _FakeFriendService() : super(Dio());
}

Widget buildTestApp({
  required double keyboard_height,
  TextScaler text_scaler = TextScaler.noScaling,
}) {
  return ProviderScope(
    overrides: [friendServiceProvider.overrideWithValue(_FakeFriendService())],
    child: CupertinoApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(390, 844),
          viewInsets: EdgeInsets.only(bottom: keyboard_height),
          textScaler: text_scaler,
        ),
        child: const Align(
          alignment: Alignment.bottomCenter,
          child: AddFriendModal(),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('헤더는 본문 비율에 맞는 높이와 제목 크기를 사용한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(
        keyboard_height: 0,
        text_scaler: const TextScaler.linear(1.1176470588235294),
      ),
    );
    await tester.pumpAndSettle();

    final header = find.byKey(const ValueKey('add-friend-modal-header'));
    final title = tester.widget<Text>(
      find.byKey(const ValueKey('add-friend-modal-title')),
    );

    expect(tester.getSize(header).height, closeTo(66, 0.1));
    expect(title.style?.fontSize, AppTheme.body_large.fontSize);
  });

  testWidgets('검증 말풍선은 결과 영역을 밀지 않고 검색창 위에 그린다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(keyboard_height: 0));
    await tester.pump();

    final result_message = find.text('친구의 이메일 또는 전화번호를\n입력해주세요');
    final result_top_before = tester.getTopLeft(result_message).dy;

    await tester.tap(find.byKey(const ValueKey('add-friend-search-button')));
    await tester.pump();

    final bubble = find.byKey(const ValueKey('add-friend-validation-bubble'));
    final result_top_after = tester.getTopLeft(result_message).dy;

    expect(bubble, findsOneWidget);
    expect(
      find.ancestor(
        of: bubble,
        matching: find.byType(CompositedTransformFollower),
      ),
      findsOneWidget,
    );
    expect(result_top_after, closeTo(result_top_before, 0.1));
  });

  testWidgets('키보드가 표시된 작은 결과 영역에서도 세로 오버플로가 발생하지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestApp(
        keyboard_height: 480,
        text_scaler: const TextScaler.linear(1.1176470588235294),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('검색창 밖을 터치하면 검색창 포커스가 해제된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(keyboard_height: 0));
    await tester.pump();

    await tester.tap(find.byType(CupertinoSearchTextField));
    await tester.pump();

    final editable_text = tester.widget<EditableText>(
      find.descendant(
        of: find.byType(CupertinoSearchTextField),
        matching: find.byType(EditableText),
      ),
    );
    expect(editable_text.focusNode.hasFocus, isTrue);

    await tester.tap(find.text('친구의 이메일 또는 전화번호를\n입력해주세요'));
    await tester.pump();

    expect(editable_text.focusNode.hasFocus, isFalse);
  });

  testWidgets('키보드가 내려가는 동안 시트가 기본 높이를 넘어 확장되지 않는다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(buildTestApp(keyboard_height: 300));
    await tester.pump();

    await tester.pumpWidget(buildTestApp(keyboard_height: 100));
    await tester.pump();

    final sheet = tester.widget<AnimatedContainer>(
      find.byType(AnimatedContainer),
    );
    final target_height = sheet.constraints?.maxHeight;
    final initial_height = 844 * 0.68;

    expect(target_height, isNotNull);
    expect(target_height!, lessThanOrEqualTo(initial_height));
  });
}
