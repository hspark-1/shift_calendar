// ignore_for_file: non_constant_identifier_names
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/group/presentation/widgets/group_timezone_picker.dart';

void main() {
  test('서울은 읽을 수 있는 도시와 UTC 시차를 표시하고 미등록 값은 보존한다', () {
    expect(groupTimezoneLabel('Asia/Seoul'), '서울 (UTC+09:00)');
    expect(groupTimezoneLabel('Custom/Existing'), '현재 시간대 (Custom/Existing)');
  });
  testWidgets('도시 이름 검색으로 기존 IANA 식별자를 반환한다', (tester) async {
    String? selected;
    await tester.pumpWidget(
      CupertinoApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => CupertinoPageScaffold(
            child: Center(
              child: CupertinoButton(
                onPressed: () async {
                  selected = await Navigator.of(context).push<String>(
                    CupertinoPageRoute(
                      builder: (_) => const GroupTimezonePicker(
                        selected_timezone: 'Custom/Existing',
                      ),
                    ),
                  );
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();
    expect(find.text('현재 시간대 (Custom/Existing)'), findsOneWidget);
    await tester.enterText(find.byType(CupertinoSearchTextField), '서울');
    await tester.pumpAndSettle();
    expect(find.text('서울 (UTC+09:00)'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('group-timezone-Asia/Seoul')));
    await tester.pumpAndSettle();
    expect(selected, 'Asia/Seoul');
  });
}
