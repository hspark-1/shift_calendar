// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/personal_event_form_modal.dart';

void main() {
  testWidgets('개인 일정 재설계의 화면·글자·키보드와 입력 접근을 검증한다', (tester) async {
    await initializeDateFormatting('ko_KR');
    final output = Directory('artifacts/personal_event_redesign_2026-11-11');
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
      (name: 'details', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (name: 'all_day', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (
        name: 'save_error',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'small', size: const Size(320, 568), scale: 1.0, keyboard: 0.0),
      (
        name: 'small_details',
        size: const Size(320, 568),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'phone375', size: const Size(375, 812), scale: 1.0, keyboard: 0.0),
      (
        name: 'large_text',
        size: const Size(390, 844),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'large_text_details',
        size: const Size(390, 844),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'small_large_details',
        size: const Size(320, 568),
        scale: 2.0,
        keyboard: 0.0,
      ),
      (
        name: 'keyboard_title',
        size: const Size(320, 568),
        scale: 1.0,
        keyboard: 240.0,
      ),
      (
        name: 'keyboard_memo',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 300.0,
      ),
      (
        name: 'landscape',
        size: const Size(844, 390),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'tablet', size: const Size(768, 1024), scale: 1.0, keyboard: 0.0),
      (
        name: 'visibility',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (
        name: 'visibility_large',
        size: const Size(320, 568),
        scale: 2.0,
        keyboard: 0.0,
      ),
    ]) {
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
            home: PersonalEventFormModal(
              initialDate: DateTime(2026, 11, 11),
              onSave: (_) async => '연결을 확인하고 다시 시도해주세요.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('personal-event-save-button'));
      final save_before = tester.getRect(save);
      expect(save.hitTestable(), findsOneWidget);
      expect(save_before.height, greaterThanOrEqualTo(52));
      expect(
        save_before.bottom,
        lessThanOrEqualTo(scenario.size.height - scenario.keyboard - 34),
      );
      Rect? focused_rect;
      if (scenario.name.contains('details') ||
          scenario.name == 'keyboard_memo') {
        final details = find.byKey(const Key('personal-event-details-toggle'));
        await tester.ensureVisible(details);
        await tester.pumpAndSettle();
        await tester.tap(details);
        await tester.pumpAndSettle();
        final memo = find.byKey(const Key('personal-event-memo-field'));
        await tester.ensureVisible(memo);
        await tester.pumpAndSettle();
        expect(memo.hitTestable(), findsOneWidget);
        if (scenario.keyboard > 0) {
          await tester.tap(memo);
          await tester.pumpAndSettle();
        }
        focused_rect = tester.getRect(memo);
        expect(focused_rect.bottom, lessThanOrEqualTo(save_before.top));
        expect(tester.getRect(save), save_before);
      }
      if (scenario.name == 'keyboard_title') {
        final title = find.byKey(const Key('personal-event-title-field'));
        await tester.tap(title);
        await tester.pumpAndSettle();
        focused_rect = tester.getRect(title);
        expect(focused_rect.bottom, lessThanOrEqualTo(save_before.top));
      }
      if (scenario.name == 'all_day') {
        await tester.tap(find.byKey(const Key('personal-event-all-day')));
        await tester.pumpAndSettle();
      }
      if (scenario.name == 'save_error') {
        await tester.enterText(
          find.byKey(const Key('personal-event-title-field')),
          '친구와 저녁 약속',
        );
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.text('다시 저장'), findsOneWidget);
        expect(save.hitTestable(), findsOneWidget);
      }
      if (scenario.name.startsWith('visibility')) {
        final visibility = find.byKey(const Key('personal-event-visibility'));
        await tester.ensureVisible(visibility);
        await tester.pumpAndSettle();
        await tester.tap(visibility);
        await tester.pumpAndSettle();
        final unavailable = find.byKey(const Key('event-private-unavailable'));
        await tester.ensureVisible(unavailable);
        await tester.pumpAndSettle();
        expect(unavailable.hitTestable(), findsOneWidget);
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
        'save_top': save_before.top,
        'save_bottom': save_before.bottom,
        if (focused_rect != null) 'focused_field_bottom': focused_rect.bottom,
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
