// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/application/phone_verification_controller.dart';
import 'package:shift_mate/features/auth/data/repositories/phone_verification_repository.dart';
import 'package:shift_mate/features/auth/data/models/phone_verification_models.dart';
import 'package:shift_mate/features/auth/data/services/firebase_phone_auth_service.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/domain/entities/profile_image_upload.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';
import '../../../../helpers/phone_auth_fakes.dart';

class _ProfileSetupAuthRepository implements AuthRepository {
  Map<String, String?>? complete_request;
  Map<String, Object?>? update_request;
  int update_count = 0;
  Object? update_error;
  Completer<User>? pending_update;
  User profile = _existing_user;
  Object? profile_error;
  Completer<User>? pending_profile;
  int get_count = 0;
  String? last_proof;
  String? last_save_key;

  @override
  Future<User> completeProfile({
    required String name,
    required String timezone,
    required String phone,
    required String phone_verification_token,
    required String idempotency_key,
    ProfileImageUpload? profile_image,
    String? job_type,
    String? workplace,
  }) async {
    last_proof = phone_verification_token;
    last_save_key = idempotency_key;
    complete_request = {
      'name': name,
      'timezone': timezone,
      'phone': phone,
      'profile_image': profile_image?.filename,
      'job_type': job_type,
      'workplace': workplace,
    };
    return User(
      id: 'user-id',
      email: 'user@example.com',
      name: name,
      timezone: timezone,
      phone: '010-1234-5678',
      job_type: job_type,
      workplace: workplace,
      requires_profile_setup: false,
    );
  }

  @override
  Future<void> deleteAccount(User user) async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<User> getProfile() async {
    get_count += 1;
    if (profile_error != null) throw profile_error!;
    if (pending_profile != null) return pending_profile!.future;
    return profile;
  }

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<AuthResponse> loginWithApple() => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithGoogle() => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithKakao() => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithNaver() => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<AuthToken> refreshToken() => throw UnimplementedError();

  @override
  Future<User> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
    ProfileImageUpload? profile_image,
    String? phone,
    String? phone_verification_token,
    String? idempotency_key,
    String? job_type,
    String? workplace,
  }) async {
    last_proof = phone_verification_token;
    last_save_key = idempotency_key;
    update_count += 1;
    update_request = {
      'name': name,
      'timezone': timezone,
      'phone': phone,
      'profile_image_url': profile_image_url,
      'profile_image': profile_image,
      'job_type': job_type,
      'workplace': workplace,
    };
    if (update_error != null) throw update_error!;
    if (pending_update != null) return pending_update!.future;
    return _existing_user.copyWith(name: name ?? _existing_user.name);
  }
}

const _existing_user = User(
  id: 'user-id',
  email: 'user@example.com',
  name: '기존 이름',
  phone: '010-1234-5678',
  timezone: 'America/New_York',
  job_type: 'NURSE',
  workplace: '기존 소속',
  requires_profile_setup: false,
);

Finder _textFieldInside(Key key) {
  return find.descendant(
    of: find.byKey(key),
    matching: find.byType(CupertinoTextField),
  );
}

Future<void> _pumpPage(
  WidgetTester tester,
  _ProfileSetupAuthRepository repository, {
  required VoidCallback on_completed,
  FakePhoneRepository? phone_repository,
  FakeFirebasePhoneService? firebase,
  Future<ProfileImageUpload?> Function()? profile_image_picker,
  Future<String> Function()? timezone_loader,
  Duration Function()? phone_elapsed,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        ...phoneAuthOverrides(repository: phone_repository, firebase: firebase),
        if (phone_elapsed != null)
          phone_verification_controller_provider.overrideWith(
            (ref, scope) => PhoneVerificationController(
              ref.watch(phone_verification_repository_provider),
              ref.watch(firebase_phone_auth_service_provider),
              scope.purpose,
              initial_phone: scope.initial_phone,
              elapsed: phone_elapsed,
            ),
          ),
      ],
      child: CupertinoApp(
        home: ProfileSetupPage(
          user: const User(
            id: 'user-id',
            email: 'user@example.com',
            name: '',
            timezone: 'Asia/Seoul',
          ),
          on_completed: on_completed,
          profile_image_picker: profile_image_picker,
          timezone_loader: timezone_loader ?? () async => 'Asia/Seoul',
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpEditPage(
  WidgetTester tester,
  _ProfileSetupAuthRepository repository, {
  User user = _existing_user,
  VoidCallback? on_completed,
  FakePhoneRepository? phone_repository,
  FakeFirebasePhoneService? firebase,
  Future<ProfileImageUpload?> Function()? profile_image_picker,
  bool as_route = false,
}) async {
  repository.profile = user;
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        ...phoneAuthOverrides(repository: phone_repository, firebase: firebase),
      ],
      child: CupertinoApp(
        home: Builder(
          builder: (context) {
            final page = ProfileSetupPage.edit(
              user: user,
              on_completed: on_completed ?? (as_route ? null : () {}),
              profile_image_picker: profile_image_picker,
            );
            if (!as_route) return page;
            return CupertinoPageScaffold(
              child: Center(
                child: CupertinoButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).push(CupertinoPageRoute<void>(builder: (_) => page)),
                  child: const Text('프로필 열기'),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  if (as_route) {
    await tester.tap(find.text('프로필 열기'));
    await tester.pumpAndSettle();
  }
}

Future<void> _verifyPhone(WidgetTester tester) async {
  final send = find.byKey(const Key('phone_send_button'));
  await tester.ensureVisible(send);
  await tester.pumpAndSettle();
  await tester.tap(send);
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('phone_code_field')), '000123');
  final verify = find.byKey(const Key('phone_verify_button'));
  await tester.ensureVisible(verify);
  await tester.pumpAndSettle();
  await tester.tap(verify);
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('phone_verification_success')), findsOneWidget);
}

void main() {
  testWidgets('중복 확인 후 SDK 준비·문자 콜백을 기다리지 않고 코드 입력을 연다', (tester) async {
    final phone_repository = FakePhoneRepository()
      ..pending_challenge = Completer();
    final firebase = FakeFirebasePhoneService()
      ..pending_start = Completer<void>()
      ..auto_send = false;
    await _pumpPage(
      tester,
      _ProfileSetupAuthRepository(),
      on_completed: () {},
      phone_repository: phone_repository,
      firebase: firebase,
    );
    final phone = _textFieldInside(const Key('profile_phone_field'));
    await tester.enterText(phone, '01012345678');
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump();
    expect(find.text('번호 확인 중'), findsOneWidget);
    expect(find.byKey(const Key('phone_code_field')), findsNothing);
    expect(firebase.start_count, 0);
    phone_repository.pending_challenge!.complete(
      PhoneChallenge(
        challenge_id: 'pending',
        phone: '01012345678',
        phone_e164: '+821012345678',
        purpose: PhoneVerificationPurpose.signup,
        server_now: DateTime.utc(2000),
        expires_at: DateTime.utc(2000, 1, 1, 0, 10),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final code = find.byKey(const Key('phone_code_field'));
    final verify = find.byKey(const Key('phone_verify_button'));
    expect(code, findsOneWidget);
    expect(find.text('인증번호 *'), findsOneWidget);
    expect(find.text('수신 번호'), findsOneWidget);
    expect(find.text('인증번호 전송 중'), findsOneWidget);
    expect(tester.widget<CupertinoTextField>(code).enabled, isTrue);
    expect(tester.widget<CupertinoTextField>(code).focusNode!.hasFocus, isTrue);
    expect(
      tester.getTopLeft(find.byKey(const Key('phone_destination_summary'))).dy,
      greaterThan(tester.getBottomLeft(code).dy),
    );
    await tester.enterText(code, '001234');
    await tester.pump();
    expect(tester.widget<CupertinoButton>(verify).onPressed, isNull);
    expect(firebase.request_count, 0);
    firebase.pending_start!.complete();
    await tester.pump();
    expect(firebase.request_count, 1);
    expect(tester.widget<CupertinoButton>(verify).onPressed, isNull);
    firebase.codeSent!('sent', 7);
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoTextField>(code).controller!.text, '001234');
    expect(tester.widget<CupertinoButton>(verify).onPressed, isNotNull);
    expect(firebase.sign_in_count, 0);
  });

  testWidgets('중복 번호는 코드 입력으로 넘어가지 않고 오류를 표시한다', (tester) async {
    final phone_repository = FakePhoneRepository()
      ..create_error = ApiException(
        code: 'PHONE_ALREADY_EXISTS',
        message: '이미 사용 중인 전화번호입니다.',
        statusCode: 409,
      );
    final firebase = FakeFirebasePhoneService();
    await _pumpPage(
      tester,
      _ProfileSetupAuthRepository(),
      on_completed: () {},
      phone_repository: phone_repository,
      firebase: firebase,
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 전화번호입니다.'), findsOneWidget);
    expect(find.byKey(const Key('phone_code_field')), findsNothing);
    expect(find.byKey(const Key('profile_phone_field')), findsOneWidget);
    expect(firebase.start_count, 0);
  });

  testWidgets('선표시 중 발송 실패는 번호 입력으로 복귀하고 오류·재시도를 제공한다', (tester) async {
    final firebase = FakeFirebasePhoneService()..auto_send = false;
    await _pumpPage(
      tester,
      _ProfileSetupAuthRepository(),
      on_completed: () {},
      firebase: firebase,
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('phone_code_field')), findsOneWidget);
    firebase.failure!(
      ApiException(code: 'PHONE_AUTH_FAILED', message: '전송하지 못했어요.'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone_code_field')), findsNothing);
    expect(find.text('전송하지 못했어요.'), findsOneWidget);
    expect(_textFieldInside(const Key('profile_phone_field')), findsOneWidget);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_setup_submit_button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('발송 후 입력 영역을 교체하고 수신 번호를 입력 라벨과 분리한다', (tester) async {
    final firebase = FakeFirebasePhoneService();
    await _pumpPage(
      tester,
      _ProfileSetupAuthRepository(),
      on_completed: () {},
      firebase: firebase,
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await tester.pumpAndSettle();
    final section = find.byKey(const Key('phone_verification_section'));
    final before_height = tester.getSize(section).height;
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('profile_phone_field')), findsNothing);
    expect(find.text('010-1234-5678'), findsOneWidget);
    expect(
      tester.getSize(section).height,
      lessThanOrEqualTo(before_height + 16),
    );
    final code = find.byKey(const Key('phone_code_field'));
    final code_field = tester.widget<CupertinoTextField>(code);
    expect(code_field.focusNode!.hasFocus, isTrue);
    await tester.showKeyboard(
      _textFieldInside(const Key('profile_name_field')),
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoTextField>(code).focusNode!.hasFocus, isTrue);
    expect(code_field.autofillHints, contains(AutofillHints.oneTimeCode));
    final verify = find.byKey(const Key('phone_verify_button'));
    expect(tester.widget<CupertinoButton>(verify).onPressed, isNull);
    await tester.enterText(code, '12345');
    await tester.pump();
    expect(tester.widget<CupertinoButton>(verify).onPressed, isNull);
    await tester.enterText(code, '001234');
    await tester.pump();
    expect(tester.widget<CupertinoButton>(verify).onPressed, isNotNull);
    expect(tester.widget<CupertinoButton>(send).onPressed, isNull);
    expect(firebase.request_count, 1);
  });

  testWidgets('번호 변경을 열었다 돌아가면 코드를 유지하고 번호를 바꾸면 입력 단계로 초기화한다', (tester) async {
    final firebase = FakeFirebasePhoneService();
    await _pumpPage(
      tester,
      _ProfileSetupAuthRepository(),
      on_completed: () {},
      firebase: firebase,
    );
    final phone = _textFieldInside(const Key('profile_phone_field'));
    await tester.enterText(phone, '01012345678');
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    final code = find.byKey(const Key('phone_code_field'));
    await tester.enterText(code, '001234');
    await tester.pumpAndSettle();
    final change = find.byKey(const Key('phone_change_button'));
    await tester.ensureVisible(change);
    await tester.tap(change);
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoTextField>(phone).focusNode!.hasFocus,
      isTrue,
    );
    await tester.showKeyboard(
      _textFieldInside(const Key('profile_name_field')),
    );
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(
      tester.widget<CupertinoTextField>(phone).focusNode!.hasFocus,
      isTrue,
    );
    final resume = find.byKey(const Key('phone_resume_code_button'));
    await tester.ensureVisible(resume);
    await tester.tap(resume);
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoTextField>(code).controller!.text, '001234');
    expect(firebase.request_count, 1);
    await tester.ensureVisible(change);
    await tester.tap(change);
    await tester.pumpAndSettle();
    await tester.enterText(phone, '01099998888');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone_resume_code_button')), findsNothing);
    expect(code, findsNothing);
    expect(
      tester.widget<CupertinoTextField>(phone).controller!.text,
      '010-9999-8888',
    );
    expect(tester.widget<CupertinoButton>(send).onPressed, isNull);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_setup_submit_button')),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('재발송은 대기 후 가능하고 이전 인증번호를 비운다', (tester) async {
    var elapsed = Duration.zero;
    final firebase = FakeFirebasePhoneService();
    await _pumpPage(
      tester,
      _ProfileSetupAuthRepository(),
      on_completed: () {},
      firebase: firebase,
      phone_elapsed: () => elapsed,
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    final code = find.byKey(const Key('phone_code_field'));
    await tester.enterText(code, '001234');
    elapsed = const Duration(seconds: 61);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(tester.widget<CupertinoButton>(send).onPressed, isNotNull);
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(firebase.request_count, 2);
    expect(tester.widget<CupertinoTextField>(code).controller!.text, isEmpty);
    expect(
      tester
          .widget<CupertinoButton>(find.byKey(const Key('phone_verify_button')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('서버 결과 재확인은 코드를 잠그고 같은 인증 결과로 복구한다', (tester) async {
    final firebase = FakeFirebasePhoneService();
    final phone_repository = FakePhoneRepository()
      ..verify_error = ApiException(
        code: 'NETWORK_ERROR',
        message: '연결을 확인해주세요.',
      );
    await _pumpPage(
      tester,
      _ProfileSetupAuthRepository(),
      on_completed: () {},
      firebase: firebase,
      phone_repository: phone_repository,
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pumpAndSettle();
    final code = find.byKey(const Key('phone_code_field'));
    await tester.enterText(code, '001234');
    await tester.pumpAndSettle();
    final verify = find.byKey(const Key('phone_verify_button'));
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();
    expect(find.text('인증 결과 다시 확인'), findsOneWidget);
    expect(tester.widget<CupertinoTextField>(code).enabled, isFalse);
    expect(tester.widget<CupertinoButton>(send).onPressed, isNull);
    final verify_key = phone_repository.last_verify_key;
    phone_repository.verify_error = null;
    await tester.ensureVisible(verify);
    await tester.tap(verify);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone_verification_success')), findsOneWidget);
    expect(phone_repository.last_verify_key, verify_key);
    expect(firebase.sign_in_count, 1);
  });

  testWidgets('Google 요약 안내와 상세·정책 링크는 문자 발송 전에 확인할 수 있다', (tester) async {
    final firebase = FakeFirebasePhoneService();
    await _pumpPage(
      tester,
      _ProfileSetupAuthRepository(),
      on_completed: () {},
      firebase: firebase,
    );
    expect(find.text('번호가 Google에 전송·저장돼요.'), findsOneWidget);
    final notice = find.byKey(const Key('phone_notice_button'));
    await tester.ensureVisible(notice);
    await tester.tap(notice);
    await tester.pumpAndSettle();
    expect(find.text('휴대폰 인증 안내'), findsOneWidget);
    expect(find.textContaining('Google 서비스의 스팸·악용 방지'), findsOneWidget);
    expect(find.text('개인정보처리방침'), findsOneWidget);
    expect(firebase.request_count, 0);
    await tester.tap(find.text('닫기'));
    await tester.pumpAndSettle();
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });
  testWidgets('가입은 유효한 번호도 서버 증명까지 받아야 저장한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    final phone_repository = FakePhoneRepository();
    final firebase = FakeFirebasePhoneService();
    await _pumpPage(
      tester,
      repository,
      on_completed: () {},
      phone_repository: phone_repository,
      firebase: firebase,
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '홍길동',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await tester.pump();
    final save = find.byKey(const Key('profile_setup_submit_button'));
    expect(tester.widget<CupertinoButton>(save).onPressed, isNull);
    expect(repository.complete_request, isNull);
    await _verifyPhone(tester);
    expect(firebase.last_e164, '+821012345678');
    expect(tester.widget<CupertinoButton>(save).onPressed, isNotNull);
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(repository.last_proof, startsWith('proof-'));
    expect(repository.last_save_key, isNotEmpty);
  });

  testWidgets('번호 인증 후 재수정은 저장을 막고 최초 번호 복귀는 타 필드만 저장한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpEditPage(tester, repository);
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '새 이름',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01099998888',
    );
    await tester.pump();
    await _verifyPhone(tester);
    await tester.ensureVisible(
      _textFieldInside(const Key('profile_phone_field')),
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01088887777',
    );
    await tester.pump();
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_setup_submit_button')),
          )
          .onPressed,
      isNull,
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();
    expect(repository.update_request?['phone'], isNull);
    expect(repository.last_proof, isNull);
    expect(repository.update_request?['name'], '새 이름');
  });

  testWidgets('최초 조회 실패 시 편집을 막고 재시도한 최신 번호를 비교 기준으로 쓴다', (tester) async {
    final repository = _ProfileSetupAuthRepository()
      ..profile_error = ApiException(code: 'NETWORK_ERROR', message: '불러오기 실패');
    await _pumpEditPage(tester, repository);
    expect(find.byKey(const Key('profile_phone_field')), findsNothing);
    expect(find.text('불러오기 실패'), findsOneWidget);
    repository.profile_error = null;
    repository.profile = _existing_user.copyWith(phone: '010-9999-8888');
    await tester.tap(find.byKey(const Key('profile_load_retry')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoTextField>(
            _textFieldInside(const Key('profile_phone_field')),
          )
          .controller!
          .text,
      '010-9999-8888',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '새 이름',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();
    expect(repository.get_count, 2);
    expect(repository.update_request?['phone'], isNull);
    expect(repository.update_count, 1);
  });

  testWidgets('인증 서버가 준비되지 않으면 SDK와 저장을 호출하지 않는다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    final firebase = FakeFirebasePhoneService();
    final phone_repository = FakePhoneRepository()
      ..create_error = ApiException(
        code: 'PHONE_VERIFICATION_UNAVAILABLE',
        message: '휴대폰 인증을 준비 중이에요.',
      );
    await _pumpPage(
      tester,
      repository,
      on_completed: () {},
      firebase: firebase,
      phone_repository: phone_repository,
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '홍길동',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.pumpAndSettle();
    await tester.tap(send);
    await tester.pumpAndSettle();
    expect(find.text('휴대폰 인증을 준비 중이에요.'), findsOneWidget);
    expect(firebase.request_count, 0);
    expect(repository.complete_request, isNull);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_setup_submit_button')),
          )
          .onPressed,
      isNull,
    );
  });

  for (final failure in [
    ApiException(
      code: 'PHONE_CHALLENGE_EXPIRED',
      message: '인증 요청이 만료됐어요.',
      statusCode: 410,
    ),
    ApiException(
      code: 'PHONE_VERIFICATION_INVALID',
      message: '인증 요청이 취소됐어요.',
      statusCode: 400,
    ),
  ]) {
    testWidgets('${failure.code} 뒤 같은 번호로 다시 인증하고 가입한다', (tester) async {
      final repository = _ProfileSetupAuthRepository();
      final phone_repository = FakePhoneRepository()..create_error = failure;
      var completed = false;
      await _pumpPage(
        tester,
        repository,
        phone_repository: phone_repository,
        on_completed: () => completed = true,
      );
      await tester.enterText(
        _textFieldInside(const Key('profile_name_field')),
        '홍길동',
      );
      final phone = _textFieldInside(const Key('profile_phone_field'));
      await tester.enterText(phone, '01012345678');
      final send = find.byKey(const Key('phone_send_button'));
      await tester.ensureVisible(send);
      await tester.pumpAndSettle();
      await tester.tap(send);
      await tester.pumpAndSettle();
      final failed_key = phone_repository.last_challenge_key;
      expect(find.text(failure.message), findsOneWidget);
      final save = find.byKey(const Key('profile_setup_submit_button'));
      expect(tester.widget<CupertinoButton>(save).onPressed, isNull);
      expect(repository.complete_request, isNull);
      phone_repository.create_error = null;
      await _verifyPhone(tester);
      expect(phone_repository.last_challenge_key, isNot(failed_key));
      expect(
        tester.widget<CupertinoTextField>(phone).controller!.text,
        '010-1234-5678',
      );
      expect(tester.widget<CupertinoButton>(save).onPressed, isNotNull);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(completed, isTrue);
      expect(repository.last_proof, isNotNull);
      expect(repository.complete_request?['phone'], '01012345678');
    });
  }

  testWidgets('Google 전화번호는 가입 화면에 미리 채우고 사진 null은 기본 아바타로 표시한다', (
    tester,
  ) async {
    final repository = _ProfileSetupAuthRepository();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(repository),
          ...phoneAuthOverrides(),
        ],
        child: CupertinoApp(
          home: ProfileSetupPage(
            user: const User(
              id: 'google-user',
              email: 'google@example.com',
              name: 'Google 사용자',
              google_id: 'google-subject',
              phone: '010-1234-5678',
              requires_profile_setup: true,
            ),
            timezone_loader: () async => 'Asia/Seoul',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoTextField>(
            _textFieldInside(const Key('profile_phone_field')),
          )
          .controller!
          .text,
      '010-1234-5678',
    );
    expect(find.byType(Image), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const Key('profile_avatar')),
        matching: find.byIcon(CupertinoIcons.person_fill),
      ),
      findsOneWidget,
    );
    expect(repository.complete_request, isNull);
  });

  testWidgets('편집은 기존 정보·레거시 직종을 표시하고 이름 변경만 전송한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    var completed = false;
    await _pumpEditPage(
      tester,
      repository,
      on_completed: () => completed = true,
    );
    expect(find.text('프로필 수정'), findsOneWidget);
    expect(find.text('변경사항 저장'), findsOneWidget);
    expect(find.text('저장하고 시작하기'), findsNothing);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(
            _textFieldInside(const Key('profile_phone_field')),
          )
          .controller!
          .text,
      '010-1234-5678',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '새 이름',
    );
    await tester.pump();
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(repository.update_request, {
      'name': '새 이름',
      'timezone': null,
      'phone': null,
      'profile_image_url': null,
      'profile_image': null,
      'job_type': null,
      'workplace': null,
    });
    expect(repository.complete_request, isNull);
    expect(completed, isTrue);
  });

  testWidgets('변경이 없거나 원래 값으로 되돌리면 저장을 비활성화한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    var completed = false;
    await _pumpEditPage(
      tester,
      repository,
      on_completed: () => completed = true,
    );
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    final save = find.byKey(const Key('profile_setup_submit_button'));
    expect(tester.widget<CupertinoButton>(save).onPressed, isNull);
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '다른 이름',
    );
    await tester.pump();
    expect(tester.widget<CupertinoButton>(save).onPressed, isNotNull);
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '  기존 이름  ',
    );
    await tester.pump();
    expect(tester.widget<CupertinoButton>(save).onPressed, isNull);
    expect(repository.update_count, 0);
    expect(completed, isFalse);
  });

  testWidgets('선택 정보를 비우면 빈 문자열을 보내고 자유 입력 직종을 저장한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpEditPage(tester, repository);
    await tester.drag(
      find.byKey(const Key('profile_setup_scroll_view')),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoTextField>(
            _textFieldInside(const Key('profile_job_type_field')),
          )
          .controller!
          .text,
      '간호사',
    );
    await tester.pump();
    await tester.enterText(
      _textFieldInside(const Key('profile_job_type_field')),
      '',
    );
    await tester.pump();
    await tester.enterText(
      _textFieldInside(const Key('profile_workplace_field')),
      '',
    );
    await tester.pump();
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(repository.update_request?['job_type'], '');
    expect(repository.update_request?['workplace'], '');
    await tester.enterText(
      _textFieldInside(const Key('profile_job_type_field')),
      '서비스 기획자',
    );
    await tester.pump();
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(repository.update_request?['job_type'], '서비스 기획자');
  });

  testWidgets('편집은 변경한 휴대폰만 검증하고 숫자로 전송한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpEditPage(tester, repository);
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '0212345678',
    );
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();
    expect(repository.update_count, 0);
    expect(find.text('한국 휴대폰 번호 형식을 확인해주세요.'), findsOneWidget);
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01099998888',
    );
    await tester.pump();
    await _verifyPhone(tester);
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(repository.update_request?['phone'], '01099998888');
  });

  testWidgets('편집 사진 선택은 미리보기 후 일반 수정 요청에 첨부한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    final selected_image = ProfileImageUpload(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLhCgAAAABJRU5ErkJggg==',
      ),
      filename: 'new-profile.png',
      content_type: 'image/png',
    );
    await _pumpEditPage(
      tester,
      repository,
      profile_image_picker: () async => selected_image,
    );
    await tester.tap(find.byKey(const Key('profile_image_button')));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(repository.update_request?['profile_image'], same(selected_image));
    expect(repository.complete_request, isNull);
  });

  testWidgets('저장 실패는 입력을 유지하고 재시도하며 진행 중 중복 저장을 막는다', (tester) async {
    final repository = _ProfileSetupAuthRepository()
      ..update_error = ApiException(
        code: 'PHONE_ALREADY_EXISTS',
        message: '이미 사용 중인 번호입니다.',
        statusCode: 409,
      );
    await _pumpEditPage(tester, repository);
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '새 이름',
    );
    await tester.pump();
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 번호입니다.'), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.text('다시 저장'), findsOneWidget);
    expect(
      tester
          .widget<CupertinoTextField>(
            _textFieldInside(const Key('profile_name_field')),
          )
          .controller!
          .text,
      '새 이름',
    );
    repository.update_error = null;
    repository.pending_update = Completer<User>();
    await tester.tap(find.text('다시 저장'));
    await tester.pump();
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_setup_submit_button')),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<CupertinoTextField>(
            _textFieldInside(const Key('profile_name_field')),
          )
          .enabled,
      isFalse,
    );
    expect(repository.update_count, 2);
    repository.pending_update!.complete(_existing_user.copyWith(name: '새 이름'));
    await tester.pumpAndSettle();
  });

  testWidgets('편집은 정보를 먼저 배치하고 변경 불가 이메일을 마지막에 표시한다', (tester) async {
    await _pumpEditPage(tester, _ProfileSetupAuthRepository());
    expect(find.text('사진 변경'), findsOneWidget);
    expect(find.text('내 프로필을 수정해요'), findsNothing);
    expect(find.text('인증됨'), findsNothing);
    expect(find.text('이름 *'), findsOneWidget);
    expect(find.text('휴대폰 번호 *'), findsOneWidget);
    expect(find.textContaining('· 필수'), findsNothing);
    expect(find.text('계정 정보'), findsOneWidget);
    final name = find.byKey(const Key('profile_name_field'));
    final phone = find.byKey(const Key('profile_phone_field'));
    final job = find.byKey(const Key('profile_job_type_field'));
    final workplace = find.byKey(const Key('profile_workplace_field'));
    final email = find.byKey(const Key('profile_email_field'));
    for (final entry in {
      'profile_edit_basic_section': [name, phone],
      'profile_edit_work_section': [job, workplace],
      'profile_edit_account_section': [email],
    }.entries) {
      for (final field in entry.value) {
        expect(
          find.descendant(of: find.byKey(Key(entry.key)), matching: field),
          findsOneWidget,
        );
      }
    }
    expect(tester.getTopLeft(name).dy, lessThan(tester.getTopLeft(phone).dy));
    expect(tester.getTopLeft(phone).dy, lessThan(tester.getTopLeft(job).dy));
    expect(
      tester.getTopLeft(workplace).dy,
      lessThan(tester.getTopLeft(email).dy),
    );
    expect(
      tester.getSize(find.byKey(const Key('profile_avatar'))),
      const Size(72, 72),
    );
    expect(
      tester.getSize(_textFieldInside(const Key('profile_name_field'))).height,
      greaterThanOrEqualTo(52),
    );
  });

  testWidgets('포커스 이탈 오류를 표시하고 필수 입력이 잘못되면 저장을 막는다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpEditPage(tester, repository);
    final name = _textFieldInside(const Key('profile_name_field'));
    final phone = _textFieldInside(const Key('profile_phone_field'));
    await tester.enterText(name, '');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(find.text('이름을 입력해주세요.'), findsOneWidget);
    expect(
      tester.widget<CupertinoTextField>(phone).focusNode!.hasFocus,
      isTrue,
    );
    await tester.pump();
    await tester.enterText(phone, '0212345678');
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    expect(find.text('한국 휴대폰 번호 형식을 확인해주세요.'), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const Key('profile_workplace_field')),
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_setup_submit_button')),
          )
          .onPressed,
      isNull,
    );
    expect(repository.update_count, 0);
  });

  testWidgets('미변경 레거시 전화번호가 없어도 이름만 부분 저장한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpEditPage(
      tester,
      repository,
      user: _existing_user.copyWith(phone: null),
    );
    await tester.pump();
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '새 이름',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();
    expect(repository.update_request?['name'], '새 이름');
    expect(repository.update_request?['phone'], isNull);
    expect(find.text('휴대폰 번호를 입력해주세요.'), findsNothing);
  });

  for (final back_action in ['button', 'system', 'swipe']) {
    testWidgets('수정 후 $back_action 뒤로가기는 확인 없이 나가고 미저장 입력을 폐기한다', (
      tester,
    ) async {
      final repository = _ProfileSetupAuthRepository();
      final phone_repository = FakePhoneRepository();
      await _pumpEditPage(
        tester,
        repository,
        as_route: true,
        phone_repository: phone_repository,
      );
      await tester.enterText(
        _textFieldInside(const Key('profile_name_field')),
        '저장 전 이름',
      );
      await tester.enterText(
        _textFieldInside(const Key('profile_phone_field')),
        '01099998888',
      );
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      switch (back_action) {
        case 'button':
          await tester.tap(find.byKey(const Key('profile_edit_back_button')));
        case 'system':
          await Navigator.of(
            tester.element(find.byType(ProfileSetupPage)),
          ).maybePop();
        case 'swipe':
          await tester.dragFrom(const Offset(1, 300), const Offset(350, 0));
      }
      await tester.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsNothing);
      expect(find.byType(ProfileSetupPage), findsNothing);
      expect(find.text('프로필 열기'), findsOneWidget);
      expect(repository.update_count, 0);
      expect(repository.complete_request, isNull);
      expect(phone_repository.create_count, 0);
      await tester.tap(find.text('프로필 열기'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CupertinoTextField>(
              _textFieldInside(const Key('profile_name_field')),
            )
            .controller!
            .text,
        _existing_user.name,
      );
      expect(
        tester
            .widget<CupertinoTextField>(
              _textFieldInside(const Key('profile_phone_field')),
            )
            .controller!
            .text,
        '010-1234-5678',
      );
    });
  }

  testWidgets('인증번호 전송 대기 중 뒤로가기는 저장 없이 인증 세션을 정리한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    final firebase = FakeFirebasePhoneService()..auto_send = false;
    await _pumpEditPage(tester, repository, as_route: true, firebase: firebase);
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01099998888',
    );
    await tester.pumpAndSettle();
    final send = find.byKey(const Key('phone_send_button'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('phone_code_field')), findsOneWidget);
    final late_code_sent = firebase.codeSent!;
    await Navigator.of(
      tester.element(find.byType(ProfileSetupPage)),
    ).maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSetupPage), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(repository.update_count, 0);
    expect(firebase.close_count, 1);
    late_code_sent('late', 7);
    await tester.pump();
    expect(find.text('프로필 열기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('미변경 뒤로가기와 저장 성공은 확인창 없이 이전 화면으로 복귀한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpEditPage(tester, repository, as_route: true);
    await tester.tap(find.byKey(const Key('profile_edit_back_button')));
    await tester.pumpAndSettle();
    expect(find.text('프로필 열기'), findsOneWidget);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    await tester.tap(find.text('프로필 열기'));
    await tester.pumpAndSettle();
    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '새 이름',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();
    expect(repository.update_count, 1);
    expect(find.text('프로필 열기'), findsOneWidget);
    expect(find.byType(ProfileSetupPage), findsNothing);
    expect(find.byType(CupertinoAlertDialog), findsNothing);
  });

  testWidgets('사진 선택 중에는 중복 선택과 저장·뒤로가기를 막고 취소하면 원래 상태다', (tester) async {
    final image_picker = Completer<ProfileImageUpload?>();
    await _pumpEditPage(
      tester,
      _ProfileSetupAuthRepository(),
      profile_image_picker: () => image_picker.future,
    );
    await tester.tap(find.byKey(const Key('profile_edit_photo_button')));
    await tester.pump();
    for (final key in [
      'profile_image_button',
      'profile_edit_photo_button',
      'profile_setup_submit_button',
      'profile_edit_back_button',
    ]) {
      expect(
        tester.widget<CupertinoButton>(find.byKey(Key(key))).onPressed,
        isNull,
      );
    }
    expect(find.text('사진 불러오는 중'), findsOneWidget);
    image_picker.complete(null);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_setup_submit_button')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('사진 변경'), findsOneWidget);
  });

  testWidgets('사진 저장 실패는 미리보기를 보존하고 저장 중 시스템 뒤로가기를 막는다', (tester) async {
    final repository = _ProfileSetupAuthRepository()
      ..update_error = ApiException(
        code: 'UPLOAD_ERROR',
        message: '사진을 저장하지 못했어요.',
        statusCode: 503,
      );
    final selected_image = ProfileImageUpload(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLhCgAAAABJRU5ErkJggg==',
      ),
      filename: 'new-profile.png',
      content_type: 'image/png',
    );
    await _pumpEditPage(
      tester,
      repository,
      as_route: true,
      profile_image_picker: () async => selected_image,
    );
    await tester.tap(find.byKey(const Key('profile_edit_photo_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();
    expect(find.text('사진을 저장하지 못했어요.'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(repository.update_request?['profile_image'], same(selected_image));
    repository.update_error = null;
    repository.pending_update = Completer<User>();
    await tester.tap(find.text('다시 저장'));
    await tester.pump();
    final context = tester.element(find.byType(ProfileSetupPage));
    Navigator.of(context).maybePop();
    await tester.pump();
    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.byType(ProfileSetupPage), findsOneWidget);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_edit_back_button')),
          )
          .onPressed,
      isNull,
    );
    expect(repository.update_count, 2);
    repository.pending_update!.complete(_existing_user);
    await tester.pumpAndSettle();
    expect(find.byType(ProfileSetupPage), findsNothing);
    expect(find.text('프로필 열기'), findsOneWidget);
  });

  test('휴대폰 formatter는 입력 길이에 맞춰 하이픈을 즉시 배치한다', () {
    final formatter = KoreanMobilePhoneInputFormatter();

    TextEditingValue format(String value) {
      return formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(
          text: value,
          selection: TextSelection.collapsed(offset: value.length),
        ),
      );
    }

    expect(format('010').text, '010');
    expect(format('0101').text, '010-1');
    expect(format('0101234567').text, '010-123-4567');
    expect(format('01012345678').text, '010-1234-5678');
    expect(format('010-12a34-56789').text, '010-1234-5678');
  });

  testWidgets('필수 기본 정보와 선택 근무 정보를 구분하고 하단 완료 버튼을 고정한다', (tester) async {
    await _pumpPage(tester, _ProfileSetupAuthRepository(), on_completed: () {});

    expect(find.text('기본 정보'), findsOneWidget);
    expect(find.text('이름 *'), findsOneWidget);
    expect(find.text('휴대폰 번호 *'), findsOneWidget);
    expect(find.text('근무 정보'), findsOneWidget);
    expect(find.text('선택'), findsOneWidget);
    expect(find.textContaining('지금 입력하지 않아도 괜찮아요.'), findsOneWidget);
    expect(
      find.byKey(const Key('profile_setup_submit_button')),
      findsOneWidget,
    );
    expect(find.text('저장하고 시작하기'), findsOneWidget);
    expect(find.text('완료'), findsNothing);
    expect(find.byKey(const Key('profile_image_button')), findsOneWidget);
    expect(find.byKey(const Key('profile_timezone_field')), findsNothing);
    expect(find.text('프로필 설정'), findsOneWidget);
    expect(find.text('내 프로필'), findsOneWidget);
    expect(find.text('사진 변경'), findsOneWidget);
    expect(find.text('소속 · 부서'), findsOneWidget);
    expect(find.text('계정 정보'), findsOneWidget);
    expect(find.text('인증됨'), findsNothing);
    expect(
      tester
          .widget<CupertinoButton>(
            find.byKey(const Key('profile_setup_submit_button')),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('소속 병원 및 부서'), findsNothing);

    final button_bottom = tester
        .getBottomLeft(find.byKey(const Key('profile_setup_submit_button')))
        .dy;
    expect(button_bottom, lessThanOrEqualTo(844));
  });

  testWidgets('화면의 입력 영역 밖을 누르면 키보드 포커스를 해제한다', (tester) async {
    await _pumpPage(tester, _ProfileSetupAuthRepository(), on_completed: () {});

    final name_field = _textFieldInside(const Key('profile_name_field'));
    await tester.tap(name_field);
    await tester.pump();

    final editable_text = find.descendant(
      of: name_field,
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(editable_text).focusNode.hasFocus,
      isTrue,
    );

    await tester.tap(find.text('기본 정보'));
    await tester.pump();

    expect(
      tester.widget<EditableText>(editable_text).focusNode.hasFocus,
      isFalse,
    );
  });

  testWidgets('휴대폰 번호를 한국 형식으로 표시하고 API에는 숫자만 전달한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpPage(tester, repository, on_completed: () {});

    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '홍길동',
    );
    final phone_field = _textFieldInside(const Key('profile_phone_field'));
    await tester.enterText(phone_field, '01012345678');
    await tester.pump();

    expect(
      tester.widget<CupertinoTextField>(phone_field).controller?.text,
      '010-1234-5678',
    );

    await _verifyPhone(tester);
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();

    expect(repository.complete_request?['phone'], '01012345678');
  });

  testWidgets('한국 휴대폰 번호가 아니면 저장을 막고 형식 오류를 표시한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpPage(tester, repository, on_completed: () {});

    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '홍길동',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '0212345678',
    );
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(find.text('한국 휴대폰 번호 형식을 확인해주세요.'), findsOneWidget);
    expect(repository.complete_request, isNull);
  });

  testWidgets('필수값이 없으면 저장하지 않고 이름과 휴대폰 오류를 표시한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpPage(tester, repository, on_completed: () {});

    await tester.tap(_textFieldInside(const Key('profile_name_field')));
    await tester.pump();
    await tester.tap(_textFieldInside(const Key('profile_phone_field')));
    await tester.pump();
    FocusManager.instance.primaryFocus?.unfocus();
    await tester.pump();

    expect(find.text('이름을 입력해주세요.'), findsOneWidget);
    expect(find.text('휴대폰 번호를 입력해주세요.'), findsOneWidget);
    expect(repository.complete_request, isNull);
  });

  testWidgets('근무 정보를 입력하지 않아도 필수값만으로 가입 완료 요청을 보낸다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    var completed = false;
    await _pumpPage(tester, repository, on_completed: () => completed = true);

    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '김간호',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await _verifyPhone(tester);
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();

    expect(repository.complete_request, {
      'name': '김간호',
      'timezone': 'Asia/Seoul',
      'phone': '01012345678',
      'profile_image': null,
      'job_type': null,
      'workplace': null,
    });
    expect(completed, isTrue);
  });

  testWidgets('선택한 프로필 이미지를 미리보고 기기 타임존과 함께 가입 요청에 보낸다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    final image = ProfileImageUpload(
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLhCgAAAABJRU5ErkJggg==',
      ),
      filename: 'profile.png',
      content_type: 'image/png',
    );
    await _pumpPage(
      tester,
      repository,
      on_completed: () {},
      profile_image_picker: () async => image,
      timezone_loader: () async => 'Asia/Tokyo',
    );

    await tester.tap(find.byKey(const Key('profile_image_button')));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);

    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '김간호',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await _verifyPhone(tester);
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();

    expect(repository.complete_request?['profile_image'], 'profile.png');
    expect(repository.complete_request?['timezone'], 'Asia/Tokyo');
  });

  testWidgets('직접 입력한 직종과 회사 정보를 가입 완료 요청에 포함한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpPage(tester, repository, on_completed: () {});

    await tester.enterText(
      _textFieldInside(const Key('profile_name_field')),
      '김간호',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01012345678',
    );
    await tester.drag(
      find.byKey(const Key('profile_setup_scroll_view')),
      const Offset(0, -320),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      _textFieldInside(const Key('profile_job_type_field')),
      '서비스 기획자',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_workplace_field')),
      'ShiftMate 프로덕트팀',
    );
    await _verifyPhone(tester);
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();

    expect(repository.complete_request?['job_type'], '서비스 기획자');
    expect(repository.complete_request?['workplace'], 'ShiftMate 프로덕트팀');
  });

  testWidgets('가입과 편집은 같은 정보 카드와 입력 디자인을 사용하고 근무 플레이스홀더가 없다', (tester) async {
    for (final is_editing in [false, true]) {
      final repository = _ProfileSetupAuthRepository();
      if (is_editing) {
        await _pumpEditPage(tester, repository);
      } else {
        await _pumpPage(tester, repository, on_completed: () {});
      }
      for (final section_key in [
        'profile_edit_basic_section',
        'profile_edit_work_section',
        'profile_edit_account_section',
      ]) {
        final section = tester.widget<Container>(find.byKey(Key(section_key)));
        final decoration = section.decoration! as BoxDecoration;
        expect(decoration.borderRadius, AppTheme.card_border_radius);
        expect(decoration.border, isNotNull);
      }
      for (final field_key in [
        'profile_job_type_field',
        'profile_workplace_field',
      ]) {
        final field = tester.widget<CupertinoTextField>(
          _textFieldInside(Key(field_key)),
        );
        expect(field.placeholder, isNull);
        final decoration = field.decoration!;
        expect(decoration.borderRadius, AppTheme.input_border_radius);
        expect(field.style, AppTheme.body_large);
      }
      final name = find.byKey(const Key('profile_name_field'));
      final email = find.byKey(const Key('profile_email_field'));
      expect(tester.getTopLeft(name).dy, lessThan(tester.getTopLeft(email).dy));
      await tester.ensureVisible(email);
      await tester.pumpAndSettle();
      expect(email.hitTestable(), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    }
  });
}
