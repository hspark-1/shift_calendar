// ignore_for_file: non_constant_identifier_names

import 'dart:ui';

class ShiftColorSelection {
  final int final_color;
  final int base_color;
  final int color_intensity;

  const ShiftColorSelection({
    required this.final_color,
    required this.base_color,
    required this.color_intensity,
  });
}

int _mixColorChannel(int channel, int color_intensity) {
  return (255 + (channel - 255) * color_intensity / 100).round();
}

Color calculateShiftColor(Color base_color, int color_intensity) {
  final normalized_intensity = color_intensity.clamp(0, 100).toInt();
  final argb = base_color.toARGB32();
  final red = (argb >> 16) & 0xff;
  final green = (argb >> 8) & 0xff;
  final blue = argb & 0xff;

  return Color.fromARGB(
    255,
    _mixColorChannel(red, normalized_intensity),
    _mixColorChannel(green, normalized_intensity),
    _mixColorChannel(blue, normalized_intensity),
  );
}
