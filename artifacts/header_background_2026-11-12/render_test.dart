// ignore_for_file: non_constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/data/models/shift_type_api_model.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_color_picker_page.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/shift_type_form_modal.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_detail_page.dart';
import 'package:shift_mate/features/friend/presentation/widgets/add_friend_modal.dart';

void main() {
  testWidgets('흰색 헤더 전환과 모달 표시를 렌더한다', (tester) async {
    final output = Directory('artifacts/header_background_2026-11-12');
    final measurements = <String, Object>{};
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
    final friend = FriendModel(
      userId: 'header-example',
      name: '친구',
      email: 'friend@example.com',
      friendLevel: 2,
      canView: true,
      createdAt: DateTime(2026, 11, 12),
    );
    final shift_type = ShiftTypeApiModel(
      shiftTypeId: 'header-example',
      code: 'N',
      name: '야간',
      color: const Color(0xFF4355B8).toARGB32(),
      startTime: '22:00:00',
      endTime: '07:00:00',
      crossesMidnight: true,
      durationMinutes: 540,
    );
    final pages = <String, Widget>{
      'friend_detail': FriendDetailPage(friend: friend),
      'shift_edit': ShiftTypeFormModal(
        shiftType: shift_type,
        existingTypes: [shift_type],
      ),
      'shift_create': const ShiftTypeFormModal(existingTypes: []),
      'color': const ShiftColorPickerPage(initial_color: Color(0xFF4355B8)),
      'custom_color': const ShiftCustomColorPickerPage(
        initial_color: Color(0xFF4355B8),
      ),
      'add_friend': const Align(
        alignment: Alignment.bottomCenter,
        child: AddFriendModal(),
      ),
    };
    for (final scenario in [
      (name: 'small', size: const Size(375, 667)),
      (name: 'landscape', size: const Size(667, 375)),
    ]) {
      await tester.binding.setSurfaceSize(scenario.size);
      for (final entry in pages.entries) {
        // ignore: invalid_use_of_visible_for_testing_member
        SharedPreferences.setMockInitialValues({});
        final capture_key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: capture_key,
            child: ProviderScope(
              child: CupertinoApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: scenario.size,
                    padding: const EdgeInsets.only(top: 20, bottom: 34),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: entry.value,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final name = '${entry.key}_${scenario.name}';
        Future<void> capture(String suffix) async {
          final boundary =
              capture_key.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          await tester.runAsync(() async {
            output.createSync(recursive: true);
            final picture = await boundary.toImage(pixelRatio: 2);
            final bytes = await picture.toByteData(
              format: ui.ImageByteFormat.png,
            );
            await File(
              '${output.path}/${name}_$suffix.png',
            ).writeAsBytes(bytes!.buffer.asUint8List());
            picture.dispose();
          });
        }

        final nav = find.byType(CupertinoNavigationBar);
        final colors = <int>[];
        double? scroll_extent;
        BoxDecoration? headerDecoration() {
          if (nav.evaluate().isEmpty) return null;
          final background = find
              .descendant(
                of: nav,
                matching: find.byWidgetPredicate(
                  (widget) =>
                      widget is DecoratedBox &&
                      widget.decoration is BoxDecoration &&
                      (widget.decoration as BoxDecoration).color != null,
                ),
              )
              .first;
          return tester.widget<DecoratedBox>(background).decoration
              as BoxDecoration;
        }

        final before = headerDecoration();
        if (before != null) {
          colors.add(before.color!.toARGB32());
          expect(before.color, AppTheme.background_color);
          expect(before.border, isNull);
        }
        await capture('top');
        if (before != null) {
          final scrollables = find.byWidgetPredicate(
            (widget) =>
                widget is Scrollable &&
                widget.axisDirection == AxisDirection.down,
          );
          final positions =
              tester
                  .stateList<ScrollableState>(scrollables)
                  .map((state) => state.position)
                  .toList()
                ..sort(
                  (a, b) => b.maxScrollExtent.compareTo(a.maxScrollExtent),
                );
          final position = positions.first;
          scroll_extent = position.maxScrollExtent;
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          final after = headerDecoration()!;
          colors.add(after.color!.toARGB32());
          expect(
            after.color,
            scroll_extent >= 10 && entry.key != 'custom_color'
                ? const Color(0xE6FFFFFF)
                : before.color,
          );
          expect(after.border, isNull);
          await capture('scrolled');
          position.jumpTo(0);
          await tester.pumpAndSettle();
          expect(headerDecoration(), before);
        }
        expect(tester.takeException(), isNull, reason: name);
        measurements[name] = {
          'header_argb_before_after': colors,
          'scroll_extent': scroll_extent,
          'framework_errors': 0,
        };
        await tester.pumpWidget(const SizedBox());
        await tester.pumpAndSettle();
      }
    }
    await tester.binding.setSurfaceSize(null);
    await tester.runAsync(() async {
      await File(
        '${output.path}/measurements.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(measurements));
    });
  });
}
