import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/main.dart';

void main() {
  testWidgets('ShiftMate 앱 제목과 초기 브랜드명을 표시한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: ShiftMateApp()));

    final app = tester.widget<CupertinoApp>(find.byType(CupertinoApp));
    expect(app.title, 'ShiftMate');
    expect(find.text('ShiftMate'), findsOneWidget);
  });
}
