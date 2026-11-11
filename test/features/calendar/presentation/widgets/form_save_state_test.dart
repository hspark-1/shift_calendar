// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_type_form_modal.dart';

void main() {
  testWidgets('근무 타입 저장 중 중복 요청을 막고 실패 후 입력을 유지한다', (tester) async {
    final completer = Completer<String?>();
    var calls = 0;
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: ShiftTypeFormModal(
          existingTypes: [],
          onCreate: (_) {
            calls++;
            return completer.future;
          },
        ),
      ),
    );
    await tester.enterText(find.byKey(const Key('shift_type_code_field')), 'D');
    await tester.enterText(
      find.byKey(const Key('shift_type_name_field')),
      '데이',
    );
    final toggle = find.byKey(const Key('shift_type_has_time_switch'));
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('shift_type_complete_button')));
    await tester.pump();
    expect(calls, 1);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_back_button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<PopScope<dynamic>>(find.byType(PopScope).first).canPop,
      isFalse,
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_complete_button')),
          )
          .onPressed,
      isNull,
    );
    completer.complete('저장 실패, 다시 시도해주세요.');
    await tester.pumpAndSettle();
    expect(find.text('저장 실패, 다시 시도해주세요.'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(
            find.byKey(const Key('shift_type_name_field')),
          )
          .controller!
          .text,
      '데이',
    );
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('shift_type_complete_button')),
          )
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });
}
