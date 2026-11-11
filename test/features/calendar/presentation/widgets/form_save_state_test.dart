// ignore_for_file: non_constant_identifier_names
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/personal_event_form_modal.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_type_form_modal.dart';

void main() {
  setUpAll(() => initializeDateFormatting('ko_KR'));
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
  testWidgets('개인 일정 저장 실패는 폼을 닫지 않고 제목과 메모를 유지한다', (tester) async {
    final completer = Completer<String?>();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: PersonalEventFormModal(
          initialDate: DateTime(2026, 11, 10),
          onSave: (_) => completer.future,
        ),
      ),
    );
    await tester.enterText(find.byType(CupertinoTextField).first, '야간 근무 후 약속');
    final details = find.byKey(const Key('personal-event-details-toggle'));
    await tester.ensureVisible(details);
    await tester.tap(details);
    await tester.pumpAndSettle();
    final memo = find.byKey(const Key('personal-event-memo-field'));
    await tester.enterText(memo, '보존할 메모');
    await tester.tap(find.text('일정 저장'));
    await tester.pump();
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);
    completer.complete('연결을 확인하고 다시 시도해주세요.');
    await tester.pumpAndSettle();
    expect(find.text('연결을 확인하고 다시 시도해주세요.'), findsOneWidget);
    expect(find.text('다시 저장'), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(
      tester
          .widget<CupertinoTextField>(find.byType(CupertinoTextField).first)
          .controller!
          .text,
      '야간 근무 후 약속',
    );
    expect(
      tester
          .widget<CupertinoTextField>(find.byType(CupertinoTextField).last)
          .controller!
          .text,
      '보존할 메모',
    );
  });
}
