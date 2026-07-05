import 'package:flutter_test/flutter_test.dart';
import 'package:shift_calendar/core/utils/color_parser.dart';

void main() {
  group('parseApiColorValue', () {
    test('parses server AARRGGBB hex strings', () {
      expect(parseApiColorValue('#FF007AFF'), 0xFF007AFF);
      expect(parseApiColorValue('#FF34C759'), 0xFF34C759);
      expect(parseApiColorValue('#FFFF9500'), 0xFFFF9500);
      expect(parseApiColorValue('#FFF5A623'), 0xFFF5A623);
    });

    test('parses RRGGBB hex strings with opaque alpha', () {
      expect(parseApiColorValue('#007AFF'), 0xFF007AFF);
    });

    test('parses existing int and decimal string values', () {
      expect(parseApiColorValue(0xFF007AFF), 0xFF007AFF);
      expect(parseApiColorValue('4278221567'), 0xFF007AFF);
    });

    test('returns null for invalid values', () {
      expect(parseApiColorValue(null), isNull);
      expect(parseApiColorValue(''), isNull);
      expect(parseApiColorValue('#FFF'), isNull);
      expect(parseApiColorValue('not-a-color'), isNull);
    });
  });
}
