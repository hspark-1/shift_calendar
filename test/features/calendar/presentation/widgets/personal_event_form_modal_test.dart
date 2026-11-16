// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:table_calendar/table_calendar.dart';
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
  EventApiModel? initial_event,
  Future<EventEditSaveResult> Function(UpdateEventRequest)? on_update,
  Future<String?> Function()? on_refresh,
  bool disable_animations = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    CupertinoApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: disable_animations),
        child: child!,
      ),
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
                        initial_event: initial_event,
                        onUpdate: on_update,
                        onRefresh: on_refresh,
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
      .widget<TableCalendar>(find.byKey(const ValueKey('date-picker-calendar')))
      .onDaySelected!(date, date);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
  await tester.pumpAndSettle();
  // 날짜 확정 후 자동 열린 시간 선택은 취소해 날짜만 바꾸는 회귀를 유지한다.
  if (find.byType(TimePickerSheet).evaluate().isNotEmpty) {
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();
  }
}

Future<void> expectShortFlingToRestore(
  WidgetTester tester, {
  required bool use_handle,
}) async {
  await openForm(tester);
  await tester.enterText(find.byKey(title_key), '짧은 끌기 입력');
  tester.widget<CupertinoTextField>(find.byKey(title_key)).focusNode!.unfocus();
  await tester.pumpAndSettle();
  final scroll = find.byKey(const Key('personal-event-scroll'));
  tester.widget<SingleChildScrollView>(scroll).controller!.jumpTo(0);
  await tester.pumpAndSettle();
  final sheet = find.byKey(const Key('personal-event-sheet'));
  final original_top = tester.getTopLeft(sheet).dy;
  final rect = tester.getRect(scroll);
  final origin = use_handle
      ? tester.getCenter(find.byKey(const Key('personal-event-sheet-handle')))
      : Offset(rect.left + 8, rect.center.dy);
  await tester.flingFrom(origin, const Offset(0, 70), 2000);
  await tester.pumpAndSettle();
  expect(find.byType(PersonalEventFormModal), findsOneWidget);
  expect(tester.getTopLeft(sheet).dy, closeTo(original_top, 1));
  expect(
    tester.widget<CupertinoTextField>(find.byKey(title_key)).controller?.text,
    '짧은 끌기 입력',
  );
}

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));

  EventApiModel editEvent({bool all_day = false}) => EventApiModel(
    eventId: 'edit',
    title: '기존 일정',
    memo: '기존 메모',
    place: '기존 장소',
    allDay: all_day,
    startAt: all_day
        ? DateTime(2026, 11, 11)
        : DateTime(2026, 11, 11, 18, 30, 25, 123),
    endAt: all_day
        ? DateTime(2026, 11, 14)
        : DateTime(2026, 11, 12, 1, 30, 45, 456),
    visibilityLevel: 3,
    isPrivate: true,
  );

  Future<void> applyVisibleTime(
    WidgetTester tester,
    int hour,
    int minute,
  ) async {
    tester
        .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
        .onDateTimeChanged(DateTime(2026, 11, 11, hour, minute));
    await tester.pump();
    await tester.tap(find.text('선택한 시간 적용'));
    await tester.pumpAndSettle();
  }

  testWidgets('제목 완료부터 날짜·시작시간·종료시간·공개 범위까지 이어지고 저장값을 보존한다', (tester) async {
    CreateEventRequest? saved;
    await openForm(tester, on_result: (result) => saved = result);
    await tester.enterText(find.byKey(title_key), '저녁 약속');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerSheet), findsOneWidget);
    expect(find.text('시작일 선택'), findsOneWidget);
    expect(find.byType(TimePickerSheet), findsNothing);
    await tester.tap(find.byKey(const ValueKey('date-picker-day-2026-11-12')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerSheet), findsOneWidget);
    expect(find.byType(TimePickerSheet), findsNothing);
    await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerSheet), findsNothing);
    expect(find.text('시작시간 선택'), findsOneWidget);
    await applyVisibleTime(tester, 18, 30);
    expect(find.text('종료시간 선택'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .initialDateTime,
      DateTime(2026, 1, 1, 19, 30),
    );
    await applyVisibleTime(tester, 20, 0);
    expect(find.byType(TimePickerSheet), findsNothing);
    expect(find.text('친구에게 공개').hitTestable(), findsOneWidget);
    await tapVisible(tester, find.byKey(save_key));
    expect(saved?.title, '저녁 약속');
    expect(saved?.startAt, DateTime(2026, 11, 12, 18, 30));
    expect(saved?.endAt, DateTime(2026, 11, 12, 20));
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 제목 완료는 제목 오류와 포커스를 유지하고 피커를 열지 않는다', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byKey(title_key), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('일정 제목을 입력해주세요.'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(find.byKey(title_key))
          .focusNode!
          .hasFocus,
      isTrue,
    );
    expect(find.byType(DatePickerSheet), findsNothing);
  });

  for (final cancel_date in [true, false]) {
    testWidgets('${cancel_date ? '날짜' : '시간'} 취소는 자동 진행을 멈추고 제목 입력을 보존한다', (
      tester,
    ) async {
      await openForm(tester);
      await tester.enterText(find.byKey(title_key), '보존할 제목');
      final submit = tester
          .widget<CupertinoTextField>(find.byKey(title_key))
          .onSubmitted!;
      submit('보존할 제목');
      submit('보존할 제목');
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerSheet), findsOneWidget);
      if (!cancel_date) {
        await tester.tap(
          find.byKey(const ValueKey('date-picker-day-2026-11-11')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
        await tester.pumpAndSettle();
        expect(find.text('시작시간 선택'), findsOneWidget);
      }
      await tester.ensureVisible(find.text('취소'));
      await tester.tap(find.text('취소'));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerSheet), findsNothing);
      expect(find.byType(TimePickerSheet), findsNothing);
      expect(
        tester
            .widget<CupertinoTextField>(find.byKey(title_key))
            .controller!
            .text,
        '보존할 제목',
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final time_picker in [false, true]) {
    testWidgets('${time_picker ? '시간' : '날짜'} 시트를 끌어 닫으면 다음 피커 없이 폼으로 돌아온다', (
      tester,
    ) async {
      CreateEventRequest? saved;
      await openForm(tester, on_result: (result) => saved = result);
      await tester.enterText(find.byKey(title_key), '끌기 취소 일정');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('date-picker-day-2026-11-12')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TimePickerSheet), findsNothing);
      if (time_picker) {
        await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
        await tester.pumpAndSettle();
        tester
            .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
            .onDateTimeChanged(DateTime(2026, 1, 1, 15, 30));
        await tester.pump();
      }
      final prefix = time_picker ? 'time-picker' : 'date-picker';
      await tester.drag(
        find.byKey(ValueKey('$prefix-handle')),
        const Offset(0, 170),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerSheet), findsNothing);
      expect(find.byType(TimePickerSheet), findsNothing);
      expect(find.byType(PersonalEventFormModal), findsOneWidget);
      expect(
        tester
            .widget<CupertinoTextField>(find.byKey(title_key))
            .controller!
            .text,
        '끌기 취소 일정',
      );
      await tapVisible(tester, find.byKey(save_key));
      expect(saved?.startAt, DateTime(2026, 11, time_picker ? 12 : 11, 9));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('종일 제목 완료는 시작일·종료일만 선택하고 시간 휠을 건너뛴다', (tester) async {
    CreateEventRequest? saved;
    await openForm(tester, on_result: (result) => saved = result);
    await tapVisible(tester, find.byKey(all_day_key));
    await tester.enterText(find.byKey(title_key), '휴가');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-picker-day-2026-11-12')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('종료일 선택'), findsOneWidget);
    expect(find.byType(TimePickerSheet), findsNothing);
    await tester.tap(find.byKey(const ValueKey('date-picker-day-2026-11-14')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerSheet), findsNothing);
    await tapVisible(tester, find.byKey(save_key));
    expect(saved?.startAt, DateTime(2026, 11, 12));
    expect(saved?.endAt, DateTime(2026, 11, 15));
    expect(saved?.allDay, isTrue);
  });

  testWidgets('수정 중 날짜 선택은 해당 시간만 열고 신규 입력 전체 흐름으로 이어지지 않는다', (tester) async {
    await openForm(tester, initial_event: editEvent());
    await tapVisible(tester, find.byKey(const ValueKey('event-date-종료')));
    await tester.tap(find.byKey(const ValueKey('date-picker-day-2026-11-13')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('종료시간 선택'), findsOneWidget);
    await tester.tap(find.text('선택한 시간 적용'));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerSheet), findsNothing);
    expect(find.byType(TimePickerSheet), findsNothing);
    expect(find.byType(PersonalEventFormModal), findsOneWidget);
  });

  testWidgets('신규 입력 안내에서 늦은 시작시간의 종료 기본값은 다음 날로 보정한다', (tester) async {
    CreateEventRequest? saved;
    await openForm(tester, on_result: (result) => saved = result);
    await tester.enterText(find.byKey(title_key), '야간 약속');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-picker-day-2026-11-11')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('date-picker-confirm')));
    await tester.pumpAndSettle();
    await applyVisibleTime(tester, 23, 30);
    expect(
      tester
          .widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker))
          .initialDateTime,
      DateTime(2026, 1, 1, 0, 30),
    );
    await tester.tap(find.text('선택한 시간 적용'));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byKey(save_key));
    expect(saved?.startAt, DateTime(2026, 11, 11, 23, 30));
    expect(saved?.endAt, DateTime(2026, 11, 12, 0, 30));
  });

  testWidgets('수정 원본/공개/레벨을 복원하고 무변경을 막으며 제목만 변경하면 정확한 시간을 보존한다', (
    tester,
  ) async {
    final event = editEvent();
    UpdateEventRequest? saved;
    await openForm(
      tester,
      initial_event: event,
      on_update: (request) async {
        saved = request;
        return const EventEditSaveResult(EventEditSaveStatus.saved);
      },
    );
    expect(find.text('개인 일정 수정'), findsOneWidget);
    expect(
      tester.widget<CupertinoButton>(find.byKey(save_key)).onPressed,
      isNull,
    );
    expect(
      tester.widget<CupertinoTextField>(find.byKey(memo_key)).controller!.text,
      event.memo,
    );
    expect(
      tester.widget<CupertinoTextField>(find.byKey(place_key)).controller!.text,
      event.place,
    );
    await tester.enterText(find.byKey(title_key), '수정 제목');
    await tapVisible(tester, find.byKey(save_key));
    expect(saved?.title, '수정 제목');
    expect(saved?.startAt, event.startAt);
    expect(saved?.endAt, event.endAt);
    expect(saved?.isPrivate, true);
    expect(saved?.visibilityLevel, 3);
    expect(find.byType(PersonalEventFormModal), findsNothing);
  });

  testWidgets('종일 수정은 배타적 종료를 표시용 종료일로 복원하고 장소/메모 삭제는 null로 보낸다', (
    tester,
  ) async {
    final event = editEvent(all_day: true);
    UpdateEventRequest? saved;
    await openForm(
      tester,
      initial_event: event,
      on_update: (request) async {
        saved = request;
        return const EventEditSaveResult(EventEditSaveStatus.saved);
      },
    );
    expect(find.textContaining('11월 13일'), findsOneWidget);
    await tester.ensureVisible(find.byKey(place_key));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(place_key), '');
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(memo_key));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(memo_key), '');
    await tapVisible(tester, find.byKey(save_key));
    expect(saved?.memo, isNull);
    expect(saved?.place, isNull);
    expect(saved?.startAt, event.startAt);
    expect(saved?.endAt, DateTime(2026, 11, 14));
  });

  testWidgets('수정 저장 중 중복/이탈을 막고 실패 입력을 보존해 재시도한다', (tester) async {
    final pending = Completer<EventEditSaveResult>();
    var calls = 0;
    await openForm(
      tester,
      initial_event: editEvent(),
      on_update: (request) {
        calls++;
        return calls == 1
            ? pending.future
            : Future.value(
                const EventEditSaveResult(EventEditSaveStatus.saved),
              );
      },
    );
    await tester.enterText(find.byKey(title_key), '실패 보존');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(save_key));
    await tester.pump();
    expect(
      tester.widget<CupertinoButton>(find.byKey(save_key)).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(back_key));
    await tester.pump();
    expect(find.byType(PersonalEventFormModal), findsOneWidget);
    expect(calls, 1);
    pending.complete(
      const EventEditSaveResult(EventEditSaveStatus.failed, message: '서버 오류'),
    );
    await tester.pumpAndSettle();
    expect(find.text('서버 오류'), findsOneWidget);
    expect(
      tester.widget<CupertinoTextField>(find.byKey(title_key)).controller!.text,
      '실패 보존',
    );
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byType(PersonalEventFormModal), findsNothing);
  });

  testWidgets('수정 404는 안내 후 닫고 실패 뒤 목록 확인은 재조회 완료 후 닫는다', (tester) async {
    await openForm(
      tester,
      initial_event: editEvent(),
      on_update: (_) async =>
          const EventEditSaveResult(EventEditSaveStatus.notFound),
    );
    await tester.enterText(find.byKey(title_key), '삭제된 일정');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(save_key));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('이미 삭제되었거나 수정할 수 없는 일정입니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.byType(PersonalEventFormModal), findsNothing);
    var refreshed = false;
    await openForm(
      tester,
      initial_event: editEvent(),
      on_update: (_) async => const EventEditSaveResult(
        EventEditSaveStatus.failed,
        message: '저장 결과 확인 필요',
      ),
      on_refresh: () async {
        refreshed = true;
        return null;
      },
    );
    await tester.enterText(find.byKey(title_key), '재조회');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    await tester.tap(find.text('목록 다시 확인'));
    await tester.pumpAndSettle();
    expect(refreshed, true);
    expect(find.byType(PersonalEventFormModal), findsNothing);
  });

  testWidgets('제목·일시·공개·선택정보 순서와 단일 하단 저장을 사용한다', (tester) async {
    await openForm(tester);
    expect(find.text('기본 정보'), findsNothing);
    expect(find.text('반복'), findsNothing);
    expect(find.text('일정 저장'), findsOneWidget);
    expect(find.byKey(memo_key), findsOneWidget);
    expect(find.byKey(place_key), findsOneWidget);
    expect(find.text('친구에게 공개'), findsOneWidget);
    expect(find.byType(CupertinoSlider), findsOneWidget);
    expect(find.text('2026년'), findsNothing);
    expect(find.text('1시간'), findsNothing);
    expect(find.byKey(const Key('personal-event-duration')), findsNothing);
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
    expect(result?.visibilityLevel, 1);
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

  testWidgets('공개 범위 1~5만 선택해 공개로 저장한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    expect(find.byKey(const ValueKey('event-visibility-0')), findsNothing);
    expect(find.text('모든 친구에게 보여요.'), findsNothing);
    expect(tester.widget<CupertinoSlider>(find.byType(CupertinoSlider)).min, 1);
    for (var level = 1; level <= 5; level++) {
      await tapVisible(tester, find.byKey(ValueKey('event-visibility-$level')));
      expect(
        tester.widget<CupertinoSlider>(find.byType(CupertinoSlider)).value,
        level.toDouble(),
      );
      if (level > 0) {
        expect(find.text('내가 지정한 레벨이 $level 이상인 친구에게 보여요.'), findsOneWidget);
      }
      expect(find.textContaining('열람을 허용한 친구 중'), findsNothing);
    }
    await tester.enterText(find.byKey(title_key), '레벨5 일정');
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.visibilityLevel, 5);
    expect(result?.toJson()['is_private'], false);
  });

  testWidgets('슬라이더 접근성 감소는1에서 멈추고0으로 내려가지 않는다', (tester) async {
    await openForm(tester);
    final slider = find.byKey(const Key('personal-event-level-slider'));
    final semantics = tester.widget<Semantics>(
      find.ancestor(of: slider, matching: find.byType(Semantics)).first,
    );
    expect(semantics.properties.value, '1');
    expect(semantics.properties.onDecrease, isNull);
    expect(semantics.properties.decreasedValue, isNull);
    await tapVisible(tester, find.byKey(const ValueKey('event-visibility-2')));
    final updated = tester.widget<Semantics>(
      find.ancestor(of: slider, matching: find.byType(Semantics)).first,
    );
    updated.properties.onDecrease!();
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoSlider>(slider).value, 1);
  });

  testWidgets('기존 레벨0 일정은 안내와 레벨1을 표시하고 저장할 때만1로 보정한다', (tester) async {
    final now = DateTime(2026, 11, 11);
    final old = EventApiModel(
      eventId: 'legacy-zero',
      title: '기존 일정',
      allDay: false,
      startAt: now.add(const Duration(hours: 9)),
      endAt: now.add(const Duration(hours: 10)),
      visibilityLevel: 0,
      isPrivate: true,
    );
    UpdateEventRequest? saved;
    await openForm(
      tester,
      initial_event: old,
      on_update: (request) async {
        saved = request;
        return const EventEditSaveResult(EventEditSaveStatus.saved);
      },
    );
    expect(saved, isNull);
    expect(old.visibilityLevel, 0);
    await tester.ensureVisible(find.text('기존 레벨 0 일정은 저장할 때 레벨 1 이상으로 변경돼요.'));
    await tester.pumpAndSettle();
    expect(find.text('기존 레벨 0 일정은 저장할 때 레벨 1 이상으로 변경돼요.'), findsOneWidget);
    await tapVisible(tester, find.byKey(save_key));
    expect(saved?.visibilityLevel, 1);
    expect(saved?.isPrivate, isTrue);
    expect(saved?.startAt, old.startAt);
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

  for (final disable_animations in [false, true]) {
    testWidgets('슬라이더는 연속 이동 후 정수로 저장한다 (동작 줄이기: $disable_animations)', (
      tester,
    ) async {
      CreateEventRequest? result;
      await openForm(
        tester,
        on_result: (value) => result = value,
        disable_animations: disable_animations,
      );
      final slider = find.byKey(const Key('personal-event-level-slider'));
      await tester.ensureVisible(slider);
      await tester.pumpAndSettle();
      final rect = tester.getRect(slider);
      final gesture = await tester.startGesture(
        Offset(rect.left + 12, rect.center.dy),
      );
      await gesture.moveBy(const Offset(36, 0));
      await tester.pump();
      await gesture.moveBy(Offset(rect.width * 0.43, 0));
      await tester.pump();
      final first_value = tester.widget<CupertinoSlider>(slider).value;
      expect(first_value, isNot(first_value.roundToDouble()));
      await gesture.moveBy(const Offset(2, 0));
      await tester.pump();
      final dragged_value = tester.widget<CupertinoSlider>(slider).value;
      final selected_level = dragged_value.round();
      expect(dragged_value, greaterThan(first_value));
      expect(dragged_value - first_value, lessThan(0.1));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final settling_value = tester.widget<CupertinoSlider>(slider).value;
      if (disable_animations) {
        expect(settling_value, selected_level.toDouble());
      } else {
        expect(settling_value, isNot(selected_level.toDouble()));
        expect(
          (settling_value - selected_level).abs(),
          lessThan((dragged_value - selected_level).abs()),
        );
      }
      await tester.pumpAndSettle();
      expect(
        tester.widget<CupertinoSlider>(slider).value,
        selected_level.toDouble(),
      );
      expect(find.byType(PersonalEventFormModal), findsOneWidget);
      await tester.enterText(find.byKey(title_key), '레벨 슬라이드');
      await tester.tap(find.byKey(save_key));
      await tester.pumpAndSettle();
      expect(result?.visibilityLevel, selected_level);
    });
  }

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
    await gesture.moveBy(const Offset(0, 140));
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
    await gesture.moveBy(const Offset(0, 140));
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

  testWidgets('손잡이의 짧고 빠른 끌기는 닫지 않고 입력을 유지한다', (tester) async {
    await expectShortFlingToRestore(tester, use_handle: true);
  });
  testWidgets('본문 상단의 짧고 빠른 끌기는 닫지 않고 입력을 유지한다', (tester) async {
    await expectShortFlingToRestore(tester, use_handle: false);
  });
  for (final use_handle in [true, false]) {
    for (final distance in [119.0, 121.0]) {
      testWidgets(
        '${use_handle ? '손잡이' : '본문 상단'} 이동거리 $distance px의 닫기 경계를 확인한다',
        (tester) async {
          await openForm(tester);
          final scroll = find.byKey(const Key('personal-event-scroll'));
          tester.widget<SingleChildScrollView>(scroll).controller!.jumpTo(0);
          await tester.pumpAndSettle();
          final sheet = find.byKey(const Key('personal-event-sheet'));
          final original_top = tester.getTopLeft(sheet).dy;
          final rect = tester.getRect(scroll);
          final origin = use_handle
              ? tester.getCenter(
                  find.byKey(const Key('personal-event-sheet-handle')),
                )
              : Offset(rect.left + 8, rect.center.dy);
          final gesture = await tester.startGesture(origin);
          await gesture.moveBy(const Offset(0, 24));
          await tester.pump(const Duration(milliseconds: 100));
          final initial_offset = tester.getTopLeft(sheet).dy - original_top;
          await gesture.moveBy(Offset(0, distance - initial_offset));
          await tester.pump(const Duration(milliseconds: 300));
          expect(
            tester.getTopLeft(sheet).dy - original_top,
            closeTo(distance, 1),
          );
          await gesture.up();
          await tester.pumpAndSettle();
          expect(
            find.byType(PersonalEventFormModal),
            distance >= 120 ? findsNothing : findsOneWidget,
          );
        },
      );
    }
  }

  testWidgets('변경 없는 손잡이 드래그는 확인 없이 닫힌다', (tester) async {
    await openForm(tester);
    await tester.drag(
      find.byKey(const Key('personal-event-sheet-handle')),
      const Offset(0, 200),
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
    expect(find.text('1시간 30분'), findsNothing);
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
    expect(find.text('종일 · 1일'), findsNothing);
    await chooseDate(tester, '종료', DateTime(2026, 11, 13));
    expect(find.text('종일 · 3일'), findsNothing);
    await tester.tap(find.byKey(save_key));
    await tester.pumpAndSettle();
    expect(result?.allDay, true);
    expect(result?.startAt, DateTime(2026, 11, 11));
    expect(result?.endAt, DateTime(2026, 11, 14));
  });

  testWidgets('기간 설명 없이 다음 날 종료와 종일 전환 전 시간을 보존한다', (tester) async {
    CreateEventRequest? result;
    await openForm(tester, on_result: (value) => result = value);
    await chooseDate(tester, '종료', DateTime(2026, 11, 12));
    await chooseTime(tester, '시작', 22, 0);
    await chooseTime(tester, '종료', 7, 0);
    expect(find.text('다음 날 종료 · 9시간'), findsNothing);
    await tapVisible(tester, find.byKey(all_day_key));
    expect(find.text('종일 · 2일'), findsNothing);
    await tapVisible(tester, find.byKey(all_day_key));
    expect(find.text('오후 10:00'), findsOneWidget);
    expect(find.text('오전 7:00'), findsOneWidget);
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
      const Offset(0, 200),
    );
    await tester.pump();
    final scroll_rect = tester.getRect(
      find.byKey(const Key('personal-event-scroll')),
    );
    await tester.dragFrom(
      Offset(scroll_rect.left + 8, scroll_rect.center.dy),
      const Offset(0, 200),
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
