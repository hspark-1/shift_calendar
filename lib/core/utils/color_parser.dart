/// API 색상 값을 Flutter `Color` 정수값으로 변환한다.
///
/// 서버 응답은 DB 정수값, 10진수 문자열, `#AARRGGBB`, `#RRGGBB`,
/// `0xAARRGGBB` 형태가 섞여 들어올 수 있다.
int? parseApiColorValue(dynamic colorValue) {
  if (colorValue == null) return null;
  if (colorValue is int) return colorValue;

  if (colorValue is String) {
    final normalizedColor = colorValue.trim();
    if (normalizedColor.isEmpty) return null;

    if (normalizedColor.startsWith('#')) {
      return _parseHexColor(normalizedColor.substring(1));
    }

    final lowerColor = normalizedColor.toLowerCase();
    if (lowerColor.startsWith('0x')) {
      return _parseHexColor(normalizedColor.substring(2));
    }

    return int.tryParse(normalizedColor);
  }

  return null;
}

int? _parseHexColor(String hexColor) {
  final normalizedHex = hexColor.trim();
  if (normalizedHex.length == 6) {
    return int.tryParse('FF$normalizedHex', radix: 16);
  }
  if (normalizedHex.length == 8) {
    return int.tryParse(normalizedHex, radix: 16);
  }
  return null;
}
