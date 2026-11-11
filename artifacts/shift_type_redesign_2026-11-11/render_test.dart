// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/data/models/shift_type_api_model.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_type_form_modal.dart';

void main() {
  testWidgets('근무 타입 재설계의 화면 크기와 입력 접근을 검증한다', (tester) async {
    final output = Directory('artifacts/shift_type_redesign_2026-11-11');
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
      (name: 'normal', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (
        name: 'normal_bottom',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'no_time', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (name: 'create', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
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
        name: 'large_text_bottom',
        size: const Size(390, 844),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'small_large_text_bottom',
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
      await tester.binding.setSurfaceSize(scenario.size);
      final capture_key = GlobalKey();
      final no_time = scenario.name == 'no_time';
      final shift_type = ShiftTypeApiModel(
        shiftTypeId: 'sample-night',
        code: no_time ? 'OFF' : 'N',
        name: no_time ? '오프' : '야간',
        color: const Color(0xFF4355B8).toARGB32(),
        startTime: no_time ? null : '22:00:00',
        endTime: no_time ? null : '07:00:00',
        crossesMidnight: !no_time,
        durationMinutes: no_time ? 0 : 540,
      );
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
            home: ShiftTypeFormModal(
              shiftType: scenario.name == 'create' ? null : shift_type,
              existingTypes: [shift_type],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CupertinoSwitch>(
              find.byKey(const Key('shift_type_has_time_switch')),
            )
            .value,
        !no_time,
      );
      expect(find.byIcon(CupertinoIcons.chevron_back), findsOneWidget);
      final save = find.byKey(const Key('shift_type_complete_button'));
      final save_before = tester.getRect(save);
      expect(save.hitTestable(), findsOneWidget);
      expect(save_before.height, greaterThanOrEqualTo(52));
      expect(
        save_before.bottom,
        lessThanOrEqualTo(scenario.size.height - scenario.keyboard - 34),
      );
      if (scenario.name.endsWith('bottom')) {
        await tester.ensureVisible(
          find.byKey(const Key('shift_type_duration_summary')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('shift_type_duration_summary')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.getRect(save), save_before);
      }
      if (scenario.keyboard > 0) {
        final field = find.byKey(const Key('shift_type_code_field'));
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        expect(field.hitTestable(), findsOneWidget);
        final field_rect = tester.getRect(field);
        expect(field_rect.bottom, lessThanOrEqualTo(save_before.top - 12));
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
        'save_height': save_before.height,
        'save_bottom': save_before.bottom,
        'framework_errors': errors,
      };
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
