// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/domain/entities/profile_image_upload.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';

const _preview_user = User(
  id: 'preview-user',
  name: '김하루',
  email: 'haru@example.com',
  phone: '010-1234-5678',
  job_type: '간호사',
  workplace: '하루병원 응급실',
  timezone: 'Asia/Seoul',
  requires_profile_setup: false,
);

class _PreviewRepository implements AuthRepository {
  @override
  Future<User> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
    ProfileImageUpload? profile_image,
    String? phone,
    String? job_type,
    String? workplace,
  }) async => throw ApiException(
    code: 'NETWORK_ERROR',
    message: '저장하지 못했어요. 연결 상태를 확인하고 다시 시도해주세요.',
    statusCode: 503,
  );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('프로필 수정의 화면 크기·글자 확대·키보드·스크롤을 검증한다', (tester) async {
    final output = Directory('artifacts/profile_edit_redesign_2026-11-11');
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
      (name: 'edited', size: const Size(390, 844), scale: 1.0, keyboard: 0.0),
      (
        name: 'save_error',
        size: const Size(390, 844),
        scale: 1.0,
        keyboard: 0.0,
      ),
      (name: 'small', size: const Size(320, 568), scale: 1.0, keyboard: 0.0),
      (
        name: 'small_bottom',
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
        name: 'keyboard_workplace',
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_PreviewRepository()),
          ],
          child: RepaintBoundary(
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
              home: ProfileSetupPage.edit(user: _preview_user),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final save = find.byKey(const Key('profile_setup_submit_button'));
      final save_before = tester.getRect(save);
      expect(save_before.height, greaterThanOrEqualTo(52));
      expect(
        save_before.bottom,
        lessThanOrEqualTo(scenario.size.height - scenario.keyboard - 34),
      );
      if (scenario.name == 'edited' || scenario.name == 'save_error') {
        final name = find.descendant(
          of: find.byKey(const Key('profile_name_field')),
          matching: find.byType(CupertinoTextField),
        );
        await tester.enterText(name, '김가을');
        await tester.pumpAndSettle();
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        if (scenario.name == 'save_error') {
          await tester.tap(save);
          await tester.pumpAndSettle();
          expect(
            find.byKey(const Key('profile_edit_save_error')),
            findsOneWidget,
          );
        }
      }
      if (scenario.name.endsWith('bottom')) {
        final email = find.byKey(const Key('profile_email_field'));
        await tester.ensureVisible(email);
        await tester.pumpAndSettle();
        expect(email.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(email).bottom,
          lessThanOrEqualTo(save_before.top - 12),
        );
        expect(tester.getRect(save), save_before);
      }
      if (scenario.keyboard > 0) {
        final field = find.descendant(
          of: find.byKey(
            Key(
              scenario.name == 'keyboard'
                  ? 'profile_name_field'
                  : 'profile_workplace_field',
            ),
          ),
          matching: find.byType(CupertinoTextField),
        );
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        expect(field.hitTestable(), findsOneWidget);
        expect(
          tester.getRect(field).bottom,
          lessThanOrEqualTo(save_before.top - 12),
        );
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
        'save_height': tester.getSize(save).height,
        'save_bottom': tester.getRect(save).bottom,
        'save_enabled': tester.widget<CupertinoButton>(save).onPressed != null,
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
