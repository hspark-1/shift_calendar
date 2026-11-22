// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/data/models/event_api_model.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_schedule_card.dart';

Widget cardApp({bool reduced_motion = false}) => CupertinoApp(
  theme: AppTheme.lightTheme,
  home: MediaQuery(
    data: MediaQueryData(
      size: const Size(390, 844),
      disableAnimations: reduced_motion,
    ),
    child: StatefulBuilder(builder: _cardBuilder()),
  ),
);

StatefulWidgetBuilder _cardBuilder() {
  var visible = true;
  return (context, setState) => Center(
    child: SizedBox(
      height: 300,
      child: !visible
          ? const SizedBox.shrink()
          : CalendarScheduleCard(
              key: const ValueKey('drag-card'),
              selected_date: DateTime(2026, 11, 22),
              work_shift: null,
              events: [
                for (var index = 0; index < 15; index++)
                  EventApiModel(
                    eventId: '$index',
                    title: '일정 $index',
                    allDay: false,
                    startAt: DateTime(2026, 11, 22, index),
                    endAt: DateTime(2026, 11, 22, index + 1),
                    visibilityLevel: 1,
                  ),
              ],
              onClose: () => setState(() => visible = false),
            ),
    ),
  );
}

double dragOffset(WidgetTester tester) => tester
    .widget<Transform>(
      find.byKey(const ValueKey('calendar-schedule-drag-transform')),
    )
    .transform
    .storage[13];

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));
  setUp(() => WidgetController.hitTestWarningShouldBeFatal = true);
  tearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);

  testWidgets('헤더 아래 드래그는 손을 따라 움직이고 짧은 드래그는 복귀한다', (tester) async {
    await tester.pumpWidget(cardApp());
    await tester.pumpAndSettle();
    final header = find.byKey(const ValueKey('selected-day-header'));
    final gesture = await tester.startGesture(
      tester.getTopLeft(header) + const Offset(60, 20),
    );
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(dragOffset(tester), greaterThan(0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drag-card')), findsOneWidget);
    expect(dragOffset(tester), 0);
  });

  for (final reduced in [false, true]) {
    testWidgets('헤더 아래 스와이프는 닫히며 동작 줄이기를 따른다 $reduced', (tester) async {
      await tester.pumpWidget(cardApp(reduced_motion: reduced));
      await tester.pumpAndSettle();
      final header = find.byKey(const ValueKey('selected-day-header'));
      final gesture = await tester.startGesture(
        tester.getTopLeft(header) + const Offset(60, 20),
      );
      await gesture.moveBy(const Offset(0, 20));
      await tester.pump();
      await gesture.moveBy(const Offset(0, 130));
      await tester.pump();
      final before = dragOffset(tester);
      expect(before, greaterThan(90));
      await gesture.up();
      await tester.pump();
      if (!reduced) {
        expect(find.byKey(const ValueKey('drag-card')), findsOneWidget);
        await tester.pump(const Duration(milliseconds: 120));
        expect(dragOffset(tester), greaterThan(before));
      }
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('drag-card')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('목록 스크롤은 유지하고 맨 위에서 아래로 끌면 닫는다', (tester) async {
    await tester.pumpWidget(cardApp());
    await tester.pumpAndSettle();
    final list = find.byType(SingleChildScrollView);
    await tester.drag(list, const Offset(0, -250));
    await tester.pumpAndSettle();
    expect(dragOffset(tester), 0);
    await tester.drag(list, const Offset(0, 100));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drag-card')), findsOneWidget);
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    tester.state<ScrollableState>(scrollable).position.jumpTo(0);
    await tester.pumpAndSettle();
    await tester.drag(list, const Offset(0, 180));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('drag-card')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
