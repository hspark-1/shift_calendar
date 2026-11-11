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
  static const Color error_text_color = Color(0xFFB3261E);
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

  /// 상단 내비게이션의 반투명 재질. 고대비에서는 불투명 표면을 사용한다.
  static const navigation_bar_color =
      CupertinoDynamicColor.withBrightnessAndContrast(
        color: Color(0xE6FFFFFF),
        darkColor: Color(0xE61E212A),
        highContrastColor: surface_color,
        darkHighContrastColor: dark_surface_color,
      );
  static const double navigation_glass_blur = 18;
  static const double navigation_glass_radius = 28;
  static const double navigation_max_width = 480;

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

  /// 앱 기본 폰트와 제목 폰트
  static const String default_font_family = 'Cafe24SsurroundAir';
  static const String heading_font_family = 'Cafe24Ssurround';

  /// 텍스트 스타일
  static const TextStyle heading_large = TextStyle(
    fontFamily: heading_font_family,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle heading_medium = TextStyle(
    fontFamily: heading_font_family,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle heading_small = TextStyle(
    fontFamily: heading_font_family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle body_large = TextStyle(
    fontFamily: default_font_family,
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle body_medium = TextStyle(
    fontFamily: default_font_family,
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.43,
    letterSpacing: 0,
    color: on_surface_color,
    inherit: false,
  );

  static const TextStyle body_small = TextStyle(
    fontFamily: default_font_family,
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

  /// 배경과 최소 대비를 만족하는 전경색을 반환한다.
  ///
  /// 선호 색상이 충분히 읽히면 그대로 유지하고, 그렇지 않으면 공용 밝은색/어두운색 중
  /// 실제 배경과 대비가 더 높은 색을 선택한다.
  static Color readableForegroundColor(
    Color background_color, {
    Color? preferred_color,
    Color canvas_color = surface_color,
    Color light_color = surface_color,
    Color dark_color = on_surface_color,
    double minimum_contrast_ratio = 4.5,
  }) {
    final opaque_background = Color.alphaBlend(background_color, canvas_color);

    if (preferred_color != null) {
      final opaque_preferred = Color.alphaBlend(
        preferred_color,
        opaque_background,
      );
      if (_contrastRatio(opaque_preferred, opaque_background) >=
          minimum_contrast_ratio) {
        return preferred_color;
      }
    }

    final light_contrast = _contrastRatio(light_color, opaque_background);
    final dark_contrast = _contrastRatio(dark_color, opaque_background);
    return dark_contrast >= light_contrast ? dark_color : light_color;
  }

  static double _contrastRatio(Color first_color, Color second_color) {
    final first_luminance = first_color.computeLuminance();
    final second_luminance = second_color.computeLuminance();
    final lighter_luminance = first_luminance >= second_luminance
        ? first_luminance
        : second_luminance;
    final darker_luminance = first_luminance < second_luminance
        ? first_luminance
        : second_luminance;
    return (lighter_luminance + 0.05) / (darker_luminance + 0.05);
  }

  /// Cupertino의 기존 크기와 색상을 유지하며 폰트를 연결한다.
  static CupertinoTextThemeData _buildTextTheme(Color text_color) {
    final defaults = CupertinoTextThemeData(primaryColor: text_color);
    return defaults.copyWith(
      textStyle: body_large,
      navTitleTextStyle: heading_small,
      navLargeTitleTextStyle: heading_large,
      actionTextStyle: defaults.actionTextStyle.copyWith(
        fontFamily: default_font_family,
      ),
      actionSmallTextStyle: defaults.actionSmallTextStyle.copyWith(
        fontFamily: default_font_family,
      ),
      tabLabelTextStyle: defaults.tabLabelTextStyle.copyWith(
        fontFamily: default_font_family,
      ),
      navActionTextStyle: defaults.navActionTextStyle.copyWith(
        fontFamily: default_font_family,
      ),
      pickerTextStyle: defaults.pickerTextStyle.copyWith(
        fontFamily: default_font_family,
      ),
      dateTimePickerTextStyle: defaults.dateTimePickerTextStyle.copyWith(
        fontFamily: default_font_family,
      ),
    );
  }

  /// Cupertino 테마 데이터
  static CupertinoThemeData get lightTheme {
    return CupertinoThemeData(
      brightness: Brightness.light,
      primaryColor: primary_color,
      scaffoldBackgroundColor: background_color,
      barBackgroundColor: navigation_bar_color,
      textTheme: _buildTextTheme(on_surface_color),
    );
  }

  static CupertinoThemeData get darkTheme {
    return CupertinoThemeData(
      brightness: Brightness.dark,
      primaryColor: primary_color,
      scaffoldBackgroundColor: dark_background_color,
      barBackgroundColor: navigation_bar_color,
      textTheme: _buildTextTheme(CupertinoColors.white),
    );
  }
}
