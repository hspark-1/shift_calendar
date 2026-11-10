// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/theme/app_theme.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/domain/entities/profile_image_upload.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';

class _ProfileSetupAuthRepository implements AuthRepository {
  Map<String, String?>? complete_request;
  Map<String, Object?>? update_request;
  int update_count = 0;
  Object? update_error;
  Completer<User>? pending_update;

  @override
  Future<User> completeProfile({
    required String name,
    required String timezone,
    required String phone,
    ProfileImageUpload? profile_image,
    String? job_type,
    String? workplace,
  }) async {
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
  Future<User> getProfile() => throw UnimplementedError();

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
    String? job_type,
    String? workplace,
  }) async {
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
  Future<ProfileImageUpload?> Function()? profile_image_picker,
  Future<String> Function()? timezone_loader,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
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
  Future<ProfileImageUpload?> Function()? profile_image_picker,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
      child: CupertinoApp(
        home: ProfileSetupPage.edit(
          user: user,
          on_completed: on_completed ?? () {},
          profile_image_picker: profile_image_picker,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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

  testWidgets('변경 없는 저장은 요청하지 않고 편집을 완료한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    var completed = false;
    await _pumpEditPage(
      tester,
      repository,
      on_completed: () => completed = true,
    );
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(repository.update_count, 0);
    expect(completed, isTrue);
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
    await tester.enterText(
      _textFieldInside(const Key('profile_job_type_field')),
      '',
    );
    await tester.enterText(
      _textFieldInside(const Key('profile_workplace_field')),
      '',
    );
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(repository.update_request?['job_type'], '');
    expect(repository.update_request?['workplace'], '');
    await tester.enterText(
      _textFieldInside(const Key('profile_job_type_field')),
      '서비스 기획자',
    );
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
    await tester.tap(find.text('변경사항 저장'));
    await tester.pump();
    expect(repository.update_count, 0);
    expect(find.text('한국 휴대폰 번호 형식을 확인해주세요.'), findsOneWidget);
    await tester.enterText(
      _textFieldInside(const Key('profile_phone_field')),
      '01099998888',
    );
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
    await tester.tap(find.text('변경사항 저장'));
    await tester.pumpAndSettle();
    expect(find.text('이미 사용 중인 번호입니다.'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
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
    await tester.tap(find.text('변경사항 저장'));
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
    expect(find.text('필수'), findsOneWidget);
    expect(find.text('근무 정보'), findsOneWidget);
    expect(find.text('선택'), findsOneWidget);
    expect(
      find.byKey(const Key('optional_work_information_notice')),
      findsOneWidget,
    );
    expect(find.textContaining('지금 입력하지 않아도 괜찮아요.'), findsOneWidget);
    expect(
      find.byKey(const Key('profile_setup_submit_button')),
      findsOneWidget,
    );
    expect(find.text('저장하고 시작하기'), findsOneWidget);
    expect(find.text('완료'), findsNothing);
    expect(find.byKey(const Key('profile_image_button')), findsOneWidget);
    expect(find.byKey(const Key('profile_timezone_field')), findsNothing);
    expect(find.text('ShiftMate에 오신 걸 환영해요'), findsOneWidget);
    expect(find.textContaining('나만의\n일정 관리를 시작해보세요.'), findsOneWidget);
    expect(find.text('재직 중인 회사·기관 및 부서'), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pump();

    expect(find.text('한국 휴대폰 번호 형식을 확인해주세요.'), findsOneWidget);
    expect(repository.complete_request, isNull);
  });

  testWidgets('필수값이 없으면 저장하지 않고 이름과 휴대폰 오류를 표시한다', (tester) async {
    final repository = _ProfileSetupAuthRepository();
    await _pumpPage(tester, repository, on_completed: () {});

    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
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
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();

    expect(repository.complete_request?['job_type'], '서비스 기획자');
    expect(repository.complete_request?['workplace'], 'ShiftMate 프로덕트팀');
  });

  testWidgets('기본·근무 정보 카드는 둥근 모서리를 클립하고 테두리를 위에 그린다', (tester) async {
    await _pumpPage(tester, _ProfileSetupAuthRepository(), on_completed: () {});

    for (final card_key in const [
      Key('basic_information_card'),
      Key('work_information_card'),
    ]) {
      final card = find.byKey(card_key);
      final clip = find.descendant(of: card, matching: find.byType(ClipRRect));
      final outer_container = find.descendant(
        of: card,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container && widget.foregroundDecoration != null,
        ),
      );

      expect(clip, findsOneWidget);
      expect(
        tester.widget<ClipRRect>(clip).borderRadius,
        AppTheme.card_border_radius,
      );
      expect(outer_container, findsOneWidget);
      final decoration =
          tester.widget<Container>(outer_container).foregroundDecoration
              as BoxDecoration;
      expect(decoration.borderRadius, AppTheme.card_border_radius);
      expect(decoration.border, isNotNull);
    }
  });
}
