import 'package:flutter/cupertino.dart';
import '../constants/app_constants.dart';

/// Apple 스타일 테마 설정
class AppTheme {
  AppTheme._();

  /// 기본 컬러
  static const Color primary_color = CupertinoColors.systemBlue;
  static const Color secondary_color = CupertinoColors.systemGrey;
  static const Color background_color = CupertinoColors.systemGroupedBackground;
  static const Color surface_color = CupertinoColors.white;

  /// 텍스트 스타일
  static const TextStyle heading_large = TextStyle(
    fontSize: 34,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
    color: CupertinoColors.label,
  );

  static const TextStyle heading_medium = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.3,
    color: CupertinoColors.label,
  );

  static const TextStyle heading_small = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: CupertinoColors.label,
  );

  static const TextStyle body_large = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.normal,
    color: CupertinoColors.label,
  );

  static const TextStyle body_medium = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.normal,
    color: CupertinoColors.label,
  );

  static const TextStyle body_small = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    color: CupertinoColors.label,
  );

  /// Cupertino 테마 데이터
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: primary_color,
      scaffoldBackgroundColor: background_color,
      barBackgroundColor: CupertinoColors.systemBackground,
      textTheme: CupertinoTextThemeData(
        primaryColor: CupertinoColors.label,
        textStyle: body_large,
        navTitleTextStyle: heading_small,
        navLargeTitleTextStyle: heading_large,
      ),
    );
  }

  static CupertinoThemeData get darkTheme {
    return const CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: primary_color,
      scaffoldBackgroundColor: CupertinoColors.darkBackgroundGray,
      barBackgroundColor: CupertinoColors.darkBackgroundGray,
      textTheme: CupertinoTextThemeData(
        primaryColor: CupertinoColors.white,
        textStyle: body_large,
        navTitleTextStyle: heading_small,
        navLargeTitleTextStyle: heading_large,
      ),
    );
  }

  /// 근무 타입에 따른 색상 반환 (동적으로 AppConstants에서 가져옴)
  static Color getShiftColor(String shift_type) {
    return AppConstants.getShiftColor(shift_type);
  }
}
