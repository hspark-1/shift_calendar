// ignore_for_file: non_constant_identifier_names

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
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';

import '../../test/helpers/phone_auth_fakes.dart';

const _user = User(
  id: 'preview',
  email: 'haru@example.com',
  name: '김하루',
  job_type: '간호사',
  workplace: '하루병원 응급실',
  phone: '01012345678',
  requires_profile_setup: false,
);

class _Repository implements AuthRepository {
  @override
  Future<User> getProfile() async => _user;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _capture(
  WidgetTester tester,
  GlobalKey capture,
  String path,
) async {
  final boundary =
      capture.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final rendered = await boundary.toImage(pixelRatio: 1);
    final bytes = await rendered.toByteData(format: ui.ImageByteFormat.png);
    await File(path).writeAsBytes(bytes!.buffer.asUint8List());
    rendered.dispose();
  });
}

void main() {
  testWidgets('가입·편집 인증 입력의 화면 크기·글자·키보드·실패·완료를 렌더 검증한다', (tester) async {
    final output = Directory(
      const String.fromEnvironment(
        'PHONE_AUTH_RENDER_DIR',
        defaultValue: '/private/tmp/shiftmate-phone-auth-20261121/render',
      ),
    )..createSync(recursive: true);
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
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    for (final editing in [false, true]) {
      for (final scenario in [
        (
          name: 'normal',
          size: const Size(390, 844),
          scale: 1.0,
          keyboard: 0.0,
          state: 'sent',
        ),
        (
          name: 'sending',
          size: const Size(390, 844),
          scale: 1.0,
          keyboard: 0.0,
          state: 'sending',
        ),
        (
          name: 'sending_large_text',
          size: const Size(320, 568),
          scale: 2.0,
          keyboard: 0.0,
          state: 'sending',
        ),
        (
          name: 'small',
          size: const Size(320, 568),
          scale: 1.0,
          keyboard: 0.0,
          state: 'sent',
        ),
        (
          name: 'phone375',
          size: const Size(375, 812),
          scale: 1.0,
          keyboard: 0.0,
          state: 'sent',
        ),
        (
          name: 'large_text',
          size: const Size(320, 568),
          scale: 2.0,
          keyboard: 0.0,
          state: 'sent',
        ),
        (
          name: 'largest_text',
          size: const Size(320, 568),
          scale: 3.2,
          keyboard: 0.0,
          state: 'sent',
        ),
        (
          name: 'dark_system',
          size: const Size(390, 844),
          scale: 1.0,
          keyboard: 0.0,
          state: 'sent',
        ),
        (
          name: 'keyboard',
          size: const Size(320, 568),
          scale: 1.0,
          keyboard: 240.0,
          state: 'sent',
        ),
        (
          name: 'landscape',
          size: const Size(844, 390),
          scale: 1.0,
          keyboard: 0.0,
          state: 'sent',
        ),
        (
          name: 'tablet',
          size: const Size(768, 1024),
          scale: 1.0,
          keyboard: 0.0,
          state: 'sent',
        ),
        (
          name: 'verified',
          size: const Size(390, 844),
          scale: 1.0,
          keyboard: 0.0,
          state: 'verified',
        ),
        (
          name: 'error',
          size: const Size(390, 844),
          scale: 1.0,
          keyboard: 0.0,
          state: 'error',
        ),
      ]) {
        await tester.binding.setSurfaceSize(scenario.size);
        final capture = GlobalKey();
        final is_sending = scenario.state == 'sending';
        final firebase = FakeFirebasePhoneService()..auto_send = !is_sending;
        if (scenario.state == 'error') {
          firebase.sign_in_error = ApiException(
            code: 'PHONE_AUTH_invalid-verification-code',
            message: '인증번호가 맞지 않아요. 다시 입력해주세요.',
          );
        }
        await tester.pumpWidget(
          ProviderScope(
            key: UniqueKey(),
            overrides: [
              authRepositoryProvider.overrideWithValue(_Repository()),
              ...phoneAuthOverrides(firebase: firebase),
            ],
            child: RepaintBoundary(
              key: capture,
              child: CupertinoApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.lightTheme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    size: scenario.size,
                    padding: const EdgeInsets.only(top: 47, bottom: 34),
                    platformBrightness: scenario.name == 'dark_system'
                        ? Brightness.dark
                        : Brightness.light,
                    textScaler: TextScaler.linear(scenario.scale),
                    viewInsets: EdgeInsets.only(bottom: scenario.keyboard),
                    disableAnimations: true,
                  ),
                  child: child!,
                ),
                home: editing
                    ? ProfileSetupPage.edit(user: _user)
                    : ProfileSetupPage(
                        user: _user.copyWith(requires_profile_setup: true),
                        timezone_loader: () async => 'Asia/Seoul',
                      ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${editing ? 'edit' : 'signup'}_${scenario.name}_initial',
        );
        if (scenario.name == 'normal') {
          await _capture(
            tester,
            capture,
            '${output.path}/${editing ? 'edit' : 'signup'}_top.png',
          );
          final email = find.byKey(const Key('profile_email_field'));
          await tester.ensureVisible(email);
          await tester.pumpAndSettle();
          expect(find.text(_user.email).hitTestable(), findsOneWidget);
          final footer_top = tester
              .getTopLeft(find.byKey(const Key('profile_setup_bottom_action')))
              .dy;
          expect(tester.getBottomLeft(email).dy, lessThanOrEqualTo(footer_top));
          await _capture(
            tester,
            capture,
            '${output.path}/${editing ? 'edit' : 'signup'}_bottom.png',
          );
        }
        final phone = find.descendant(
          of: find.byKey(const Key('profile_phone_field')),
          matching: find.byType(CupertinoTextField),
        );
        expect(
          phone,
          findsOneWidget,
          reason: '${editing ? "edit" : "signup"}_${scenario.name}',
        );
        await tester.ensureVisible(phone);
        await tester.enterText(phone, editing ? '01099998888' : '01012345678');
        await tester.pumpAndSettle();
        if (scenario.name == 'normal') {
          await tester.ensureVisible(
            find.byKey(const Key('profile_edit_basic_section')),
          );
          await tester.pumpAndSettle();
          await _capture(
            tester,
            capture,
            '${output.path}/${editing ? 'edit' : 'signup'}_initial.png',
          );
        }
        final send = find.byKey(const Key('phone_send_button'));
        await tester.ensureVisible(send);
        await tester.tap(send);
        if (is_sending) {
          await tester.pump(const Duration(milliseconds: 300));
        } else {
          await tester.pumpAndSettle();
        }
        final code = find.byKey(const Key('phone_code_field'));
        await tester.ensureVisible(code);
        await tester.enterText(code, '012345');
        if (is_sending) {
          await tester.pump(const Duration(milliseconds: 300));
        } else {
          await tester.pumpAndSettle();
        }
        final verify = find.byKey(const Key('phone_verify_button'));
        await tester.ensureVisible(verify);
        if (scenario.state == 'verified' || scenario.state == 'error') {
          await tester.tap(verify);
          if (is_sending) {
            await tester.pump(const Duration(milliseconds: 300));
          } else {
            await tester.pumpAndSettle();
          }
        }
        if (scenario.state == 'verified') {
          expect(
            find.byKey(const Key('phone_verification_success')),
            findsOneWidget,
          );
          await tester.ensureVisible(
            find.byKey(const Key('profile_phone_field')),
          );
        } else {
          expect(tester.getSize(verify).height, greaterThanOrEqualTo(48));
        }
        if (scenario.scale == 1 && scenario.keyboard == 0) {
          await tester.ensureVisible(
            find.byKey(const Key('profile_edit_basic_section')),
          );
        } else if (scenario.state != 'verified') {
          await tester.ensureVisible(code);
        }
        if (is_sending) {
          await tester.pump(const Duration(milliseconds: 300));
        } else {
          await tester.pumpAndSettle();
        }
        final save = find.byKey(const Key('profile_setup_submit_button'));
        expect(tester.getSize(save).height, greaterThanOrEqualTo(52));
        expect(
          tester.getBottomLeft(save).dy,
          lessThanOrEqualTo(scenario.size.height - scenario.keyboard - 34),
        );
        expect(
          tester.widget<CupertinoButton>(save).onPressed != null,
          scenario.state == 'verified',
        );
        if (scenario.scale == 2 && scenario.state != 'verified') {
          final destination = find.byKey(const Key('phone_destination_number'));
          expect(tester.getSize(destination).height, lessThanOrEqualTo(80));
          expect(
            tester.getSize(find.text('수신 번호')).height,
            lessThanOrEqualTo(34),
          );
        }
        if (is_sending) {
          expect(find.text('인증번호 전송 중'), findsOneWidget);
          expect(tester.widget<CupertinoTextField>(code).enabled, isTrue);
          expect(tester.widget<CupertinoButton>(verify).onPressed, isNull);
        }
        final framework_error = tester.takeException();
        final save_rect = tester.getRect(save);
        final scroll_rect = tester.getRect(
          find.byKey(const Key('profile_setup_scroll_view')),
        );
        measurements['${editing ? 'edit' : 'signup'}_${scenario.name}'] = {
          'width': scenario.size.width,
          'height': scenario.size.height,
          'text_scale': scenario.scale,
          'keyboard_inset': scenario.keyboard,
          'save_height': save_rect.height,
          'save_bottom': save_rect.bottom,
          'scroll_height': scroll_rect.height,
          'save_enabled':
              tester.widget<CupertinoButton>(save).onPressed != null,
          'framework_error': framework_error?.toString(),
        };
        await _capture(
          tester,
          capture,
          '${output.path}/${editing ? 'edit' : 'signup'}_${scenario.name}.png',
        );
        expect(
          framework_error,
          isNull,
          reason: '${editing ? 'edit' : 'signup'}_${scenario.name}',
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
      }
    }
    await tester.runAsync(() async {
      await File(
        '${output.path}/measurements.json',
      ).writeAsString(const JsonEncoder.withIndent('  ').convert(measurements));
    });
    await tester.binding.setSurfaceSize(null);
  });
}
