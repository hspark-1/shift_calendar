// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/year_month_picker_sheet.dart';

void main() {
  testWidgets('초기 연월을 보여주고 선택한 달을 반환한다', (tester) async {
    DateTime? selected_date;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Builder(
            builder: (context) {
              return Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selected_date = await showYearMonthPickerSheet(
                      context: context,
                      initial_date: DateTime(2026, 8, 15),
                      first_year: 2000,
                      last_year: 2050,
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

    expect(find.text('날짜 이동'), findsOneWidget);
    expect(find.text('2026년 8월'), findsOneWidget);
    expect(find.text('이번 달'), findsOneWidget);
    expect(find.text('선택한 달로 이동'), findsOneWidget);

    await tester.tap(find.text('선택한 달로 이동'));
    await tester.pumpAndSettle();

    expect(selected_date, DateTime(2026, 8, 1));
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
                    selected_date = await showYearMonthPickerSheet(
                      context: context,
                      initial_date: DateTime(2026, 8),
                      first_year: 2000,
                      last_year: 2050,
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
    expect(find.text('날짜 이동'), findsNothing);
  });
}
