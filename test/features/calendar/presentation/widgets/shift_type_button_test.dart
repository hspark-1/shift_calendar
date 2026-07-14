// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_calendar/features/calendar/domain/entities/shift_type_info.dart';
import 'package:shift_calendar/features/calendar/presentation/widgets/shift_type_button.dart';

List<ShiftTypeInfo> buildShiftTypes(int count) {
  return List.generate(count, (index) {
    final number = index + 1;
    return ShiftTypeInfo(
      code: 'T$number',
      name: '근무 $number',
      color: const Color(0xFF0061A4),
      sort_order: index,
    );
  });
}

Widget buildTestApp({
  required int count,
  ValueChanged<String>? onShiftSelected,
}) {
  return CupertinoApp(
    home: CupertinoPageScaffold(
      child: Center(
        child: SizedBox(
          key: const ValueKey('grid_bounds'),
          width: 320,
          height: 128,
          child: ShiftTypeSelectionGrid(
            shift_types: buildShiftTypes(count),
            selected_shift: count > 0 ? 'T1' : null,
            onShiftSelected: onShiftSelected ?? (_) {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('근무 타입 1개부터 10개까지 스크롤 없이 표시한다', (tester) async {
    for (var count = 1; count <= 10; count++) {
      await tester.pumpWidget(buildTestApp(count: count));
      await tester.pumpAndSettle();

      for (var index = 1; index <= count; index++) {
        expect(find.byKey(ValueKey('shift_type_T$index')), findsOneWidget);
      }
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('근무 타입 10개를 5개씩 두 행에 배치하고 선택 콜백을 전달한다', (tester) async {
    String? selected_code;
    await tester.pumpWidget(
      buildTestApp(count: 10, onShiftSelected: (code) => selected_code = code),
    );
    await tester.pumpAndSettle();

    final first_row_y = tester
        .getCenter(find.byKey(const ValueKey('shift_type_T1')))
        .dy;
    final second_row_y = tester
        .getCenter(find.byKey(const ValueKey('shift_type_T6')))
        .dy;

    for (var index = 1; index <= 5; index++) {
      expect(
        tester.getCenter(find.byKey(ValueKey('shift_type_T$index'))).dy,
        first_row_y,
      );
    }
    for (var index = 6; index <= 10; index++) {
      expect(
        tester.getCenter(find.byKey(ValueKey('shift_type_T$index'))).dy,
        second_row_y,
      );
    }
    expect(second_row_y, greaterThan(first_row_y));

    await tester.tap(find.byKey(const ValueKey('shift_type_T10')));
    expect(selected_code, 'T10');
    expect(tester.takeException(), isNull);
  });
}
