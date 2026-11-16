// ignore_for_file: non_constant_identifier_names

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/calendar/presentation/widgets/calendar_schedule_card.dart';
import 'package:shift_mate/features/friend/presentation/pages/group_calendar_preview_page.dart';

void expectVisibleText(WidgetTester tester, Finder finder, Rect header_rect) {
  final paragraph = tester.renderObject<RenderParagraph>(finder);
  final text = paragraph.text.toPlainText();
  expect(paragraph.didExceedMaxLines, isFalse, reason: text);
  // 줄 끝 공백의 선택 영역은 줄바꿈 경계 밖으로 나갈 수 있어 보이는 글리프만 검사한다.
  final boxes = [
    for (var index = 0; index < text.length; index++)
      if (text[index].trim().isNotEmpty)
        ...paragraph.getBoxesForSelection(
          TextSelection(baseOffset: index, extentOffset: index + 1),
        ),
  ];
  final rect = tester.getRect(finder);
  expect(header_rect.inflate(0.1).contains(rect.topLeft), isTrue, reason: text);
  expect(
    header_rect.inflate(0.1).contains(rect.bottomRight),
    isTrue,
    reason: text,
  );
  for (final box in boxes) {
    expect(box.left, greaterThanOrEqualTo(-0.1), reason: text);
    expect(
      box.right,
      lessThanOrEqualTo(paragraph.size.width + 0.1),
      reason: text,
    );
    expect(box.top, greaterThanOrEqualTo(-0.1), reason: text);
    expect(
      box.bottom,
      lessThanOrEqualTo(paragraph.size.height + 0.1),
      reason: text,
    );
  }
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  final output = Platform.environment['SCHEDULE_HEADER_RENDER_OUTPUT'];
  if (output == null) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final directory = Directory(output)..createSync(recursive: true);
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    File(
      '${directory.path}/$name.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ko_KR');
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
  });

  for (final width in [320.0, 375.0, 390.0, 430.0, 667.0, 768.0]) {
    for (final scale in [1.0, 1.1, 1.25, 2.0, 3.2]) {
      testWidgets('헤더 폭 $width 글자 $scale 에서 날짜·요약·공휴일을 보존한다', (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 667));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final capture_key = GlobalKey();
        for (final holiday in [null, '긴 공휴일 이름 대체공휴일']) {
          await tester.pumpWidget(
            CupertinoApp(
              theme: AppTheme.lightTheme,
              home: MediaQuery(
                data: MediaQueryData(
                  size: Size(width, 667),
                  textScaler: TextScaler.linear(scale),
                  boldText: true,
                  disableAnimations: true,
                ),
                child: CupertinoPageScaffold(
                  child: RepaintBoundary(
                    key: capture_key,
                    child: SingleChildScrollView(
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: AppTheme.cardDecoration(),
                        child: CalendarScheduleHeader(
                          selected_date: DateTime(2026, 11, 12),
                          holiday_name: holiday,
                          summary_chips: const [
                            CalendarScheduleSummaryChip(
                              label: '근무 123명',
                              is_primary: true,
                            ),
                            CalendarScheduleSummaryChip(label: '일정 456개'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final header_rect = tester.getRect(
            find.byKey(const ValueKey('selected-day-header')),
          );
          final title = find.text('11월 12일 목요일');
          for (final label in [
            '11월 12일 목요일',
            '근무 123명',
            '일정 456개',
            if (holiday != null) holiday,
          ]) {
            expectVisibleText(tester, find.text(label), header_rect);
          }
          for (final label in ['근무 123명', '일정 456개']) {
            expect(
              tester.getRect(title).overlaps(tester.getRect(find.text(label))),
              isFalse,
            );
          }
          final paragraph = tester.renderObject<RenderParagraph>(title);
          if (width == 375 && scale == 1 && holiday == null) {
            final boxes = paragraph.getBoxesForSelection(
              const TextSelection(baseOffset: 0, extentOffset: 11),
            );
            expect(boxes.map((box) => box.top).toSet(), hasLength(1));
            expect(
              tester.getRect(find.text('근무 123명')).top,
              greaterThanOrEqualTo(tester.getRect(title).bottom),
            );
          }
          if (width == 768 && scale == 1 && holiday == null) {
            expect(header_rect.height, 44.5);
            expect(
              tester.getRect(find.text('근무 123명')).top,
              lessThan(tester.getRect(title).bottom),
            );
          }
          expect(tester.takeException(), isNull);
          if (width == 375 && [1.0, 3.2].contains(scale)) {
            await capture(
              tester,
              capture_key,
              'header_${width}_${scale}_${holiday == null ? 'plain' : 'holiday'}',
            );
          }
        }
      });
    }
  }

  testWidgets('메인·친구 요약과 근무 완료도 좁은 헤더 안에 표시된다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final scale in [1.0, 1.25, 3.2]) {
      await tester.pumpWidget(
        CupertinoApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(
              size: const Size(320, 568),
              textScaler: TextScaler.linear(scale),
            ),
            child: CupertinoPageScaffold(
              child: SingleChildScrollView(
                child: CalendarScheduleHeader(
                  selected_date: DateTime(2026, 11, 12),
                  total_count: 123,
                  trailing: CupertinoButton(
                    onPressed: () {},
                    child: const Text('완료', style: AppTheme.body_medium),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(
        find.byKey(const ValueKey('selected-day-header')),
      );
      for (final label in ['11월 12일 목요일', '일정 123개', '완료']) {
        expectVisibleText(tester, find.text(label), rect);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('미리보기의 실제 작은 화면에서 날짜 아래 요약과 구성원 스크롤을 유지한다', (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    for (final size in [
      const Size(320, 568),
      const Size(375, 667),
      const Size(667, 375),
    ]) {
      await tester.binding.setSurfaceSize(size);
      final capture_key = GlobalKey();
      await tester.pumpWidget(
        CupertinoApp(
          theme: AppTheme.lightTheme,
          home: RepaintBoundary(
            key: capture_key,
            child: GroupCalendarPreviewPage(
              initial_date: DateTime(2026, 11, 12),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rect = tester.getRect(
        find.byKey(const ValueKey('group-preview-selected-day-header')),
      );
      expectVisibleText(tester, find.text('11월 12일 목요일'), rect);
      await tester.drag(
        find.byKey(const ValueKey('group-preview-member-list')),
        const Offset(0, -120),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await capture(
        tester,
        capture_key,
        'preview_${size.width}_${size.height}',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
