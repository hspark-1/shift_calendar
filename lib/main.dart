import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/theme/app_theme.dart';
import 'features/calendar/presentation/pages/calendar_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 한국어 로케일 데이터 초기화
  await initializeDateFormatting('ko_KR', null);
  runApp(
    const ProviderScope(
      child: ShiftCalendarApp(),
    ),
  );
}

/// 메인 앱 위젯
class ShiftCalendarApp extends StatelessWidget {
  const ShiftCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Shift Calendar',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CalendarPage(),
    );
  }
}
