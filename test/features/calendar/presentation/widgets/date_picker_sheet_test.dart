// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_calendar/features/calendar/presentation/widgets/date_picker_sheet.dart';

void main() {
  testWidgets('초기 날짜를 보여주고 선택한 날짜를 반환한다', (tester) async {
    DateTime? selected_date;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Builder(
            builder: (context) {
              return Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selected_date = await showDatePickerSheet(
                      context: context,
                      title: '시작일 선택',
                      initial_date: DateTime(2026, 8, 15),
                      minimum_date: DateTime(2000, 1, 1),
                      maximum_date: DateTime(2050, 12, 31),
                    );
                  },
                  child: const Text('날짜 선택'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('날짜 선택'));
    await tester.pumpAndSettle();

    expect(find.text('시작일 선택'), findsOneWidget);
    expect(find.text('2026년 8월 15일 (토)'), findsOneWidget);
    expect(find.text('오늘'), findsOneWidget);
    expect(find.text('선택한 날짜 적용'), findsOneWidget);

    await tester.tap(find.text('선택한 날짜 적용'));
    await tester.pumpAndSettle();

    expect(selected_date, DateTime(2026, 8, 15));
  });

  testWidgets('취소하면 선택값을 반환하지 않는다', (tester) async {
    DateTime? selected_date;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Builder(
            builder: (context) {
              return Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selected_date = await showDatePickerSheet(
                      context: context,
                      title: '종료일 선택',
                      initial_date: DateTime(2026, 8, 15),
                      minimum_date: DateTime(2000, 1, 1),
                      maximum_date: DateTime(2050, 12, 31),
                    );
                  },
                  child: const Text('날짜 선택'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('날짜 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(selected_date, isNull);
    expect(find.text('종료일 선택'), findsNothing);
  });
}
