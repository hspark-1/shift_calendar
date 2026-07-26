// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/time_picker_sheet.dart';

void main() {
  testWidgets('초기 시간을 보여주고 선택한 시간을 반환한다', (tester) async {
    Duration? selected_time;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Builder(
            builder: (context) {
              return Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selected_time = await showTimePickerSheet(
                      context: context,
                      title: '시작시간 선택',
                      initial_time: const Duration(hours: 9),
                    );
                  },
                  child: const Text('시간 선택'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('시간 선택'));
    await tester.pumpAndSettle();

    expect(find.text('시작시간 선택'), findsOneWidget);
    expect(find.text('오전 09:00'), findsOneWidget);
    expect(find.text('지금'), findsOneWidget);
    expect(find.text('선택한 시간 적용'), findsOneWidget);

    await tester.tap(find.text('선택한 시간 적용'));
    await tester.pumpAndSettle();

    expect(selected_time, const Duration(hours: 9));
  });

  testWidgets('취소하면 선택값을 반환하지 않는다', (tester) async {
    Duration? selected_time;

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          child: Builder(
            builder: (context) {
              return Center(
                child: CupertinoButton(
                  onPressed: () async {
                    selected_time = await showTimePickerSheet(
                      context: context,
                      title: '종료시간 선택',
                      initial_time: const Duration(hours: 18, minutes: 30),
                    );
                  },
                  child: const Text('시간 선택'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('시간 선택'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('취소'));
    await tester.pumpAndSettle();

    expect(selected_time, isNull);
    expect(find.text('종료시간 선택'), findsNothing);
  });
}
