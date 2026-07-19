// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_calendar/core/utils/color_parser.dart';
import 'package:shift_calendar/features/calendar/data/models/shift_type_api_model.dart';

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

  group('formatApiColorValue', () {
    test('formats Flutter color ints as server AARRGGBB hex strings', () {
      expect(formatApiColorValue(0xFF0061A4), '#FF0061A4');
      expect(formatApiColorValue(0xFFFF9500), '#FFFF9500');
    });

    test('pads leading zeroes to keep eight hex digits', () {
      expect(formatApiColorValue(0x0000000F), '#0000000F');
    });
  });

  group('ShiftType request color serialization', () {
    test('create request sends color as server AARRGGBB hex string', () {
      final request = CreateShiftTypeRequest(
        code: 'D',
        name: 'Day',
        color: 0xFF0061A4,
      );

      expect(request.toJson()['color'], '#FF0061A4');
    });

    test('update request sends color as server AARRGGBB hex string', () {
      final request = UpdateShiftTypeRequest(color: 0xFFFF9500);

      expect(request.toJson()['color'], '#FFFF9500');
    });

    test(
      'new request sends base color and integer intensity without color',
      () {
        final request = CreateShiftTypeRequest(
          code: 'N',
          name: 'Night',
          baseColor: 0xFF4355B8,
          colorIntensity: 50,
        );

        expect(request.toJson(), {
          'code': 'N',
          'name': 'Night',
          'base_color': '#FF4355B8',
          'color_intensity': 50,
        });
      },
    );

    test('rejects partial or out-of-range color metadata', () {
      expect(
        () => UpdateShiftTypeRequest(baseColor: 0xFF4355B8).toJson(),
        throwsArgumentError,
      );
      expect(
        () => UpdateShiftTypeRequest(
          baseColor: 0xFF4355B8,
          colorIntensity: 101,
        ).toJson(),
        throwsRangeError,
      );
      expect(
        () => UpdateShiftTypeRequest(
          baseColor: 0x804355B8,
          colorIntensity: 50,
        ).toJson(),
        throwsArgumentError,
      );
    });
  });

  group('ShiftType response color metadata parsing', () {
    Map<String, dynamic> buildJson({
      Object? color = '#FFA1AADC',
      Object? base_color = '#FF4355B8',
      Object? color_intensity = 50,
    }) {
      return {
        'shift_type_id': 'shift-type-night',
        'code': 'N',
        'name': '나이트',
        'color': color,
        'base_color': base_color,
        'color_intensity': color_intensity,
        'sort_order': 1,
        'start_time': '22:30:00',
        'end_time': '07:00:00',
        'crosses_midnight': true,
        'duration_minutes': 510,
      };
    }

    test('parses final color, base color, and intensity', () {
      final shift_type = ShiftTypeApiModel.fromJson(buildJson());

      expect(shift_type.color, 0xFFA1AADC);
      expect(shift_type.baseColor, 0xFF4355B8);
      expect(shift_type.colorIntensity, 50);
    });

    test('falls back legacy response to final color and 100 percent', () {
      final json = buildJson()
        ..remove('base_color')
        ..remove('color_intensity');

      final shift_type = ShiftTypeApiModel.fromJson(json);

      expect(shift_type.color, 0xFFA1AADC);
      expect(shift_type.baseColor, 0xFFA1AADC);
      expect(shift_type.colorIntensity, 100);
    });

    test('keeps null color metadata with 100 percent fallback', () {
      final shift_type = ShiftTypeApiModel.fromJson(
        buildJson(color: null, base_color: null, color_intensity: null),
      );

      expect(shift_type.color, isNull);
      expect(shift_type.baseColor, isNull);
      expect(shift_type.colorIntensity, 100);
    });
  });
}
