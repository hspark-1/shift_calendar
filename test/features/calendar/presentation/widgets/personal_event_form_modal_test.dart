// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/personal_event_form_modal.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/time_picker_sheet.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/date_picker_sheet.dart';

const title_key = Key('personal-event-title-field');
const place_key = Key('personal-event-place-field');
const memo_key = Key('personal-event-memo-field');
const save_key = Key('personal-event-save-button');
const back_key = Key('personal-event-back-button');
const details_key = Key('personal-event-details-toggle');
const visibility_key = Key('personal-event-visibility');
const all_day_key = Key('personal-event-all-day');

Future<void> openForm(
  WidgetTester tester, {
  Future<String?> Function(CreateEventRequest)? on_save,
  ValueChanged<CreateEventRequest?>? on_result,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    CupertinoApp(
      theme: AppTheme.lightTheme,
      home: CupertinoPageScaffold(
        child: Builder(
          builder: (context) => Center(
            child: CupertinoButton(
              child: const Text('일정 열기'),
              onPressed: () async {
                final result =
                    await showCupertinoModalPopup<CreateEventRequest>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => PersonalEventFormModal(
                        initialDate: DateTime(2026, 11, 11),
                        onSave: on_save,
                      ),
                    );
                on_result?.call(result);
              },
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('일정 열기'));
  await tester.pumpAndSettle();
}

Future<void> tapVisible(WidgetTester tester, Finder target) async {
  await tester.pumpAndSettle();
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> chooseTime(
  WidgetTester tester,
  String label,
  int hour,
  int minute,
) async {
  await tapVisible(tester, find.byKey(ValueKey('event-time-$label')));
  tester
      .widget<CupertinoDatePicker>(
        find.descendant(
          of: find.byType(TimePickerSheet),
          matching: find.byType(CupertinoDatePicker),
        ),
      )
      .onDateTimeChanged(DateTime(2026, 11, 11, hour, minute));
  await tester.pump();
  await tester.tap(find.text('선택한 시간 적용'));
  await tester.pumpAndSettle();
}

Future<void> chooseDate(
  WidgetTester tester,
  String label,
  DateTime date,
) async {
  await tapVisible(tester, find.byKey(ValueKey('event-date-$label')));
  tester
      .widget<CupertinoDatePicker>(
        find.descendant(
          of: find.byType(DatePickerSheet),
          matching: find.byType(CupertinoDatePicker),
        ),
      )
      .onDateTimeChanged(date);
  await tester.pump();
  await tester.tap(find.text('선택한 날짜 적용'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  testWidgets('제목·일시·공개·선택정보 순서와 단일 하단 저장을 사용한다', (tester) async {
    await openForm(tester);
    expect(find.text('기본 정보'), findsNothing);
    expect(find.text('반복'), findsNothing);
    expect(find.text('일정 저장'), findsOneWidget);
    expect(find.byKey(memo_key), findsNothing);
    expect(find.byKey(place_key), findsNothing);
    expect(find.text('친구에게 공개'), findsOneWidget);
    expect(find.byType(CupertinoSlider), findsOneWidget);
    expect(find.text('1시간'), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(title_key)).dy,
      lessThan(tester.getTopLeft(find.text('날짜와 시간')).dy),
    );
    expect(
      tester.getTopLeft(find.text('날짜와 시간')).dy,
      lessThan(tester.getTopLeft(find.byKey(visibility_key)).dy),
    );
    expect(
      tester.getSize(find.byKey(save_key)).height,
      greaterThanOrEqualTo(52),
    );
    expect(
      tester.widget<CupertinoTextField>(find.byKey(title_key)).style?.fontSize,
      26,
    );
  });

  testWidgets('기본 생성은 제목을 trim하고 기존 계약과 선택일을 유지한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await tester.enterText(find.byKey(title_key), '  저녁 약속  ');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.title, '저녁 약속');
    expect(result?.startAt, DateTime(2026, 11, 11, 9));
    expect(result?.endAt, DateTime(2026, 11, 11, 10));
    expect(result?.allDay, false);
    expect(result?.visibilityLevel, 0);
    expect(result?.toJson().containsKey('place'), false);
    expect(result?.toJson().containsKey('memo'), false);
    expect(result?.toJson()['is_private'], false);
    expect(find.byType(PersonalEventFormModal), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('선택 정보를 접었다 펴도 보존하며 trim한 값만 저장한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await tester.enterText(find.byKey(title_key), '약속');
    await tapVisible(tester, find.byKey(details_key));
    await tester.enterText(find.byKey(place_key), '  강남역  ');
    await tester.enterText(find.byKey(memo_key), '  예약 확인  ');
    await tapVisible(tester, find.byKey(details_key));
    expect(find.byKey(memo_key), findsNothing);
    await tapVisible(tester, find.byKey(details_key));
    expect(
      tester.widget<CupertinoTextField>(find.byKey(place_key)).controller?.text,
      '  강남역  ',
    );
    expect(
      tester.widget<CupertinoTextField>(find.byKey(memo_key)).controller?.text,
      '  예약 확인  ',
    );
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.place, '강남역');
    expect(result?.memo, '예약 확인');
  });

  testWidgets('공개 범위 0~5를 선택해 공개로 저장한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    for (var level = 0; level <= 5; level++) {
      await tapVisible(tester, find.byKey(ValueKey('event-visibility-$level')));
      expect(
        tester.widget<CupertinoSlider>(find.byType(CupertinoSlider)).value,
        level.toDouble(),
      );
    }
    await tester.enterText(find.byKey(title_key), '레벨5 일정');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.visibilityLevel, 5);
    expect(result?.toJson()['is_private'], false);
  });

  testWidgets('나만 보기는 별도 boolean으로 저장하며 기존 레벨을 보존한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await tapVisible(tester, find.byKey(const ValueKey('event-visibility-3')));
    await tapVisible(tester, find.byKey(const Key('event-visibility-private')));
    expect(find.text('나만 보기'), findsOneWidget);
    expect(find.text('친구와 그룹에 공개되지 않아요.'), findsOneWidget);
    expect(find.textContaining('서버 지원 준비 중'), findsNothing);
    await tester.enterText(find.byKey(title_key), '개인 약속');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.isPrivate, true);
    expect(result?.visibilityLevel, 3);
    expect(result?.toJson()['is_private'], true);
  });

  testWidgets('친구 공개와 나만 보기를 전환하면 기존 레벨을 복원한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await tapVisible(tester, find.byKey(const ValueKey('event-visibility-4')));
    await tapVisible(tester, find.byKey(const Key('event-visibility-private')));
    expect(find.byType(CupertinoSlider), findsNothing);
    await tapVisible(tester, find.byKey(const Key('event-visibility-friends')));
    expect(
      tester.widget<CupertinoSlider>(find.byType(CupertinoSlider)).value,
      4,
    );
    await tapVisible(tester, find.byKey(const ValueKey('event-visibility-2')));
    await tester.enterText(find.byKey(title_key), '친구 공개');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.isPrivate, false);
    expect(result?.visibilityLevel, 2);
  });

  testWidgets('슬라이더 드래그가 정수 레벨로 저장되고 본문은 닫히지 않는다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    final slider = find.byKey(const Key('personal-event-level-slider'));
    await tester.ensureVisible(slider);
    await tester.pumpAndSettle();
    final rect = tester.getRect(slider);
    final gesture = await tester.startGesture(
      Offset(rect.left + 12, rect.center.dy),
    );
    await gesture.moveBy(const Offset(36, 0));
    await tester.pump();
    await gesture.moveTo(Offset(rect.right - 8, rect.center.dy));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSlider>(slider).value, 5);
    expect(find.byType(PersonalEventFormModal), findsOneWidget);
    await tester.enterText(find.byKey(title_key), '레벨 슬라이드');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.visibilityLevel, 5);
  });

  testWidgets('시트는 화면 아래에서 올라오고 바깥 탭으로 사라지지 않는다', (tester) async {
    await openForm(tester);
    final sheet = tester.getRect(find.byKey(const Key('personal-event-sheet')));
    expect(sheet.top, greaterThan(60));
    expect(sheet.bottom, closeTo(844, 1));
    expect(find.byIcon(CupertinoIcons.chevron_back), findsNothing);
    expect(find.byIcon(CupertinoIcons.xmark), findsOneWidget);
    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsOneWidget);
  });

  testWidgets('손잡이는 아래 드래그를 따라가고 작성한 내용도 확인 없이 닫는다', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(title_key), '작성 중인 일정');
    await tester.pumpAndSettle();
    final sheet = find.byKey(const Key('personal-event-sheet'));
    final original_top = tester.getTopLeft(sheet).dy;
    final handle = find.byKey(const Key('personal-event-sheet-handle'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 90));
    await tester.pump();
    expect(tester.getTopLeft(sheet).dy, greaterThan(original_top + 40));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('본문 스크롤 상단의 아래 드래그도 작성 여부와 무관하게 닫는다', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(title_key), '본문에서 닫기');
    tester
        .widget<CupertinoTextField>(find.byKey(title_key))
        .focusNode!
        .unfocus();
    await tester.pumpAndSettle();
    final scroll = find.byKey(const Key('personal-event-scroll'));
    final controller = tester.widget<SingleChildScrollView>(scroll).controller!;
    controller.jumpTo(0);
    await tester.pumpAndSettle();
    final rect = tester.getRect(scroll);
    final gesture = await tester.startGesture(
      Offset(rect.left + 8, rect.center.dy),
    );
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 110));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('본문 상단의 짧은 아래 드래그는 원위치로 복귀하고 입력을 유지한다', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(title_key), '유지할 입력');
    tester
        .widget<CupertinoTextField>(find.byKey(title_key))
        .focusNode!
        .unfocus();
    await tester.pumpAndSettle();
    final sheet = find.byKey(const Key('personal-event-sheet'));
    final original_top = tester.getTopLeft(sheet).dy;
    final scroll = find.byKey(const Key('personal-event-scroll'));
    tester.widget<SingleChildScrollView>(scroll).controller!.jumpTo(0);
    await tester.pumpAndSettle();
    final rect = tester.getRect(scroll);
    final gesture = await tester.startGesture(
      Offset(rect.left + 8, rect.center.dy),
    );
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(0, 24));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsOneWidget);
    expect(tester.getTopLeft(sheet).dy, closeTo(original_top, 1));
    expect(
      tester.widget<CupertinoTextField>(find.byKey(title_key)).controller?.text,
      '유지할 입력',
    );
  });

  testWidgets('본문이 중간까지 스크롤됐으면 아래 드래그는 목록만 이동한다', (tester) async {
    await openForm(tester);
    await tapVisible(tester, find.byKey(details_key));
    await tester.enterText(
      find.byKey(memo_key),
      List.filled(30, '긴 메모').join('\n'),
    );
    tester
        .widget<CupertinoTextField>(find.byKey(memo_key))
        .focusNode!
        .unfocus();
    await tester.pumpAndSettle();
    final scroll = find.byKey(const Key('personal-event-scroll'));
    final controller = tester.widget<SingleChildScrollView>(scroll).controller!;
    controller.jumpTo(220);
    await tester.pumpAndSettle();
    final sheet = find.byKey(const Key('personal-event-sheet'));
    final original_top = tester.getTopLeft(sheet).dy;
    final rect = tester.getRect(scroll);
    await tester.dragFrom(
      Offset(rect.left + 8, rect.center.dy),
      const Offset(0, 90),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsOneWidget);
    expect(controller.offset, greaterThan(0));
    expect(controller.offset, lessThan(220));
    expect(tester.getTopLeft(sheet).dy, closeTo(original_top, 1));
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('변경 없는 손잡이 드래그는 확인 없이 닫힌다', (tester) async {
    await openForm(tester);
    await tester.drag(
      find.byKey(const Key('personal-event-sheet-handle')),
      const Offset(0, 140),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('제목 오류는 인접 표시하고 첫 필드에 포커스하며 입력 후 해제한다', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(title_key), '  ');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(find.text('일정 제목을 입력해주세요.'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(find.byKey(title_key))
          .focusNode
          ?.hasFocus,
      true,
    );
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    await tester.enterText(find.byKey(title_key), '정상 제목');
    await tester.pump();
    expect(find.text('일정 제목을 입력해주세요.'), findsNothing);
  });

  testWidgets('같은 시작/종료와 역전 시간을 차단하고 시간 수정 후 저장한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await tester.enterText(find.byKey(title_key), '일정');
    for (final hour in [9, 8]) {
      await chooseTime(tester, '종료', hour, 0);
      await tester.tap(find.byKey(save_key));
      await tester.pumpAndSettle();
      expect(find.text('종료 시각은 시작 시각보다 늦어야 합니다.'), findsOneWidget);
      expect(
        find.text('종료 시각은 시작 시각보다 늦어야 합니다.').hitTestable(),
        findsOneWidget,
      );
      expect(result, isNull);
    }
    await chooseTime(tester, '종료', 10, 30);
    expect(find.text('종료 시각은 시작 시각보다 늦어야 합니다.'), findsNothing);
    expect(find.text('1시간 30분'), findsOneWidget);
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.endAt, DateTime(2026, 11, 11, 10, 30));
  });

  testWidgets('종일은 선택한 종료일까지 포함하고 다음 날 자정으로 저장한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await tester.enterText(find.byKey(title_key), '여행');
    await tapVisible(tester, find.byKey(all_day_key));
    expect(find.byKey(const ValueKey('event-time-시작')), findsNothing);
    expect(find.text('종일 · 1일'), findsOneWidget);
    await chooseDate(tester, '종료', DateTime(2026, 11, 13));
    expect(find.text('종일 · 3일'), findsOneWidget);
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.allDay, true);
    expect(result?.startAt, DateTime(2026, 11, 11));
    expect(result?.endAt, DateTime(2026, 11, 14));
  });

  testWidgets('다음 날 종료를 설명하고 종일 전환 전 시간을 복원한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await chooseDate(tester, '종료', DateTime(2026, 11, 12));
    await chooseTime(tester, '시작', 22, 0);
    await chooseTime(tester, '종료', 7, 0);
    expect(find.text('다음 날 종료 · 9시간'), findsOneWidget);
    await tapVisible(tester, find.byKey(all_day_key));
    expect(find.text('종일 · 2일'), findsOneWidget);
    await tapVisible(tester, find.byKey(all_day_key));
    expect(find.text('다음 날 종료 · 9시간'), findsOneWidget);
    await tester.enterText(find.byKey(title_key), '야간 약속');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.startAt, DateTime(2026, 11, 11, 22));
    expect(result?.endAt, DateTime(2026, 11, 12, 7));
  });

  testWidgets('날짜가 반대편을 넘으면 기존 선후 보정을 유지한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await chooseDate(tester, '시작', DateTime(2026, 11, 20));
    expect(find.text('11월 20일 (금)'), findsNWidgets(2));
    await chooseDate(tester, '종료', DateTime(2026, 11, 10));
    expect(find.text('11월 10일 (화)'), findsNWidgets(2));
    await tester.enterText(find.byKey(title_key), '날짜 보정');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.startAt, DateTime(2026, 11, 10, 9));
    expect(result?.endAt, DateTime(2026, 11, 10, 10));
  });

  for (final os_back in [false, true]) {
    testWidgets('작성 후 ${os_back ? 'OS 복귀' : '닫기 버튼'}는 저장/폐기 확인 없이 닫는다', (
      tester,
    ) async {
      var save_calls = 0;
      await openForm(
        tester,
        on_save: (_) async {
          save_calls++;
          return null;
        },
      );
      await tester.enterText(find.byKey(title_key), '작성 중');
      if (os_back) {
        await Navigator.of(
          tester.element(find.byType(PersonalEventFormModal)),
        ).maybePop();
      } else {
        await tester.tap(find.byKey(back_key));
      }
      await tester.pumpAndSettle();
      expect(find.byType(PersonalEventFormModal), findsNothing);
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(save_calls, 0);
    });
  }

  testWidgets('실질 변경을 원래대로 돌리면 확인 없이 닫힌다', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(title_key), '작성');
    await tester.enterText(find.byKey(title_key), '');
    await tester.tap(find.byKey(back_key));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('저장 중 중복·이탈을 막고 예외 후 입력 보존과 재시도를 제공한다', (tester) async {
    final pending = Completer<String?>();
    var calls = 0;
    await openForm(
      tester,
      on_save: (_) {
        calls++;
        return calls == 1 ? pending.future : Future.value(null);
      },
    );
    await tester.enterText(find.byKey(title_key), '입력 보존');
    await tester.tap(find.byKey(save_key));
    await tester.pump();
    expect(calls, 1);
    expect(
      tester.widget<CupertinoButton>(find.byKey(save_key)).onPressed,
      isNull,
    );
    expect(
      tester.widget<CupertinoButton>(find.byKey(back_key)).onPressed,
      isNull,
    );
    await tester.drag(
      find.byKey(const Key('personal-event-sheet-handle')),
      const Offset(0, 140),
    );
    await tester.pump();
    final scroll_rect = tester.getRect(
      find.byKey(const Key('personal-event-scroll')),
    );
    await tester.dragFrom(
      Offset(scroll_rect.left + 8, scroll_rect.center.dy),
      const Offset(0, 140),
    );
    await tester.pump();
    await Navigator.of(
      tester.element(find.byType(PersonalEventFormModal)),
    ).maybePop();
    await tester.pump();
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.byType(PersonalEventFormModal), findsOneWidget);
    pending.completeError(StateError('network failure'));
    await tester.pumpAndSettle();
    expect(find.text('일정을 저장하지 못했습니다. 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('다시 저장'), findsOneWidget);
    expect(
      tester.widget<CupertinoTextField>(find.byKey(title_key)).controller?.text,
      '입력 보존',
    );
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(PersonalEventFormModal), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
