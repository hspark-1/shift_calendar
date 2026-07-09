// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';

/// Shift Harmony 디자인 토큰 기반 Cupertino 테마 설정
class AppTheme {
  AppTheme._();

  /// Shift Harmony 컬러 토큰
  static const Color primary_color = Color(0xFF0061A4);
  static const Color primary_dark_color = Color(0xFF00497D);
  static const Color secondary_color = CupertinoColors.systemGrey;
  static const Color accent_red_color = Color(0xFFE53935);
  static const Color background_color = Color(0xFFF8F9FB);
  static const Color surface_color = Color(0xFFFFFFFF);
  static const Color surface_container_low_color = Color(0xFFF2F4F6);
  static const Color surface_container_color = Color(0xFFECEEF0);
  static const Color surface_container_high_color = Color(0xFFE6E8EA);
  static const Color surface_container_highest_color = Color(0xFFE0E3E5);
  static const Color on_surface_color = Color(0xFF191C1E);
  static const Color on_surface_variant_color = Color(0xFF414750);
  static const Color outline_color = Color(0xFF717782);
  static const Color outline_variant_color = Color(0xFFC1C7D2);
  static const Color dark_background_color = Color(0xFF12141C);
  static const Color dark_surface_color = Color(0xFF1E212A);

  /// 형태/간격 토큰
  static const double radius_sm = 4;
  static const double radius_md = 8;
  static const double input_radius = 12;
  static const double card_radius = 16;
  static const double chip_radius = 16;
  static const double spacing_xs = 4;
  static const double spacing_sm = 8;
  static const double spacing_md = 16;
  static const double spacing_lg = 24;
  static const double spacing_xl = 32;

  /// 텍스트 스타일
  static const TextStyle heading_large = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle heading_medium = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle heading_small = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle body_large = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle body_medium = TextStyle(
    fontFamily: 'Plus Jakarta Sans',
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.43,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle body_small = TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.33,
    letterSpacing: 0,
    color: on_surface_variant_color,
    inherit: false,
  );

  static BorderRadius get card_border_radius {
    return BorderRadius.circular(card_radius);
  }

  static BorderRadius get input_border_radius {
    return BorderRadius.circular(input_radius);
  }

  static BorderSide get subtle_border {
    return const BorderSide(color: outline_variant_color, width: 1);
  }

  static BoxDecoration cardDecoration({
    Color color = surface_color,
    double radius = card_radius,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: outline_variant_color, width: 1),
    );
  }

  /// Cupertino 테마 데이터
  static CupertinoThemeData get lightTheme {
    return const CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: primary_color,
      scaffoldBackgroundColor: background_color,
      barBackgroundColor: surface_color,
      textTheme: CupertinoTextThemeData(
        primaryColor: on_surface_color,
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
      scaffoldBackgroundColor: dark_background_color,
      barBackgroundColor: dark_surface_color,
      textTheme: CupertinoTextThemeData(
        primaryColor: CupertinoColors.white,
        textStyle: body_large,
        navTitleTextStyle: heading_small,
        navLargeTitleTextStyle: heading_large,
      ),
    );
  }
}
