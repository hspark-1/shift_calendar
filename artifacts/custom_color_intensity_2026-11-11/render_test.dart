// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_color_picker_page.dart';

void main() {
  testWidgets('커스텀 색상 재디자인 화면 검증', (tester) async {
    final output = Directory('artifacts/custom_color_intensity_2026-11-11');
    output.createSync(recursive: true);
    for (final entry in {
      'Cafe24SsurroundAir': 'assets/fonts/Cafe24SsurroundAir-v1.1.ttf',
      'Cafe24Ssurround': 'assets/fonts/Cafe24Ssurround-v2.0.ttf',
      'packages/cupertino_icons/CupertinoIcons':
          'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    final measurements = <String, Object>{};
    for (final scenario in [
      (name: 'preset', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (
        name: 'intensity_bottom',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'normal', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (name: 'small', size: const Size(320, 568), scale: 1.0, keyboard: 0.0),
      (
        name: 'small_bottom',
        size: const Size(320, 568),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (
        name: 'large_text',
        size: const Size(390, 844),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'small_large_text',
        size: const Size(320, 568),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'keyboard',
        size: const Size(320, 568),
        scale: 1.0,
        keyboard: 240.0,
      ),
      (
        name: 'landscape',
        size: const Size(844, 390),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'tablet', size: const Size(768, 1024), scale: 1.0, keyboard: 0.0),
    ]) {
      // test/ 밖에 보관한 검토용 Flutter 테스트에서만 사용하는 모의 저장소다.
      // ignore: invalid_use_of_visible_for_testing_member
      SharedPreferences.setMockInitialValues({
        'shift_custom_recent_colors_v1': [
          'FF9500',
          'E85F80',
          '0061A4',
          '448F53',
          '713700',
          'BA1A1A',
        ],
      });
      await tester.binding.setSurfaceSize(scenario.size);
      final capture_key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture_key,
          child: CupertinoApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                size: scenario.size,
                padding: const EdgeInsets.only(top: 47, bottom: 34),
                textScaler: TextScaler.linear(scenario.scale),
                viewInsets: EdgeInsets.only(bottom: scenario.keyboard),
                disableAnimations: true,
              ),
              child: child!,
            ),
            home: scenario.name == 'preset'
                ? const ShiftColorPickerPage(
                    initial_color: Color(0xFFA1AADC),
                    initial_base_color: Color(0xFF4355B8),
                    initial_color_intensity: 50,
                  )
                : const ShiftCustomColorPickerPage(
                    initial_color: Color(0xFFA1AADC),
                    initial_base_color: Color(0xFF4355B8),
                    initial_color_intensity: 50,
                  ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (scenario.name.endsWith('bottom')) {
        await tester.dragFrom(const Offset(8, 400), const Offset(0, -1200));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('shift_custom_color_recent_5')).hitTestable(),
          findsOneWidget,
        );
      }
      if (scenario.keyboard > 0) {
        final field = find.byKey(const Key('shift_custom_color_hex_field'));
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        expect(field.hitTestable(), findsOneWidget);
      }
      final errors = <String>[];
      Object? error;
      while ((error = tester.takeException()) != null) {
        errors.add(error.toString());
      }
      measurements[scenario.name] = {
        'size': '${scenario.size.width}x${scenario.size.height}',
        'scale': scenario.scale,
        'keyboard_inset': scenario.keyboard,
        'framework_errors': errors,
      };
      if (scenario.name == 'preset') {
        final card = tester.getRect(
          find.byKey(const Key('shift_color_preset_card')),
        );
        final first = tester.getRect(
          find.byKey(const Key('shift_color_swatch_0')),
        );
        final last = tester.getRect(
          find.byKey(const Key('shift_color_swatch_8')),
        );
        final top_gap = first.top - card.top;
        final bottom_gap = card.bottom - last.bottom;
        (measurements[scenario.name] as Map<String, Object>)['card_spacing'] = {
          'top': top_gap,
          'bottom': bottom_gap,
        };
        expect(bottom_gap, closeTo(top_gap, 0.01));
      }
      final boundary =
          capture_key.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final capture = await boundary.toImage(pixelRatio: 2);
        final bytes = await capture.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '${output.path}/${scenario.name}.png',
        ).writeAsBytes(bytes!.buffer.asUint8List());
        capture.dispose();
      });
      expect(errors, isEmpty, reason: scenario.name);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
    await tester.binding.setSurfaceSize(null);
    await tester.runAsync(() async {
      await File(
        '${output.path}/measurements.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(measurements));
    });
  });
}
