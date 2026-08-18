// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/presentation/pages/profile_setup_page.dart';

class _ProfileSetupAuthRepository implements AuthRepository {
  Map<String, String?>? complete_request;

  @override
  Future<User> completeProfile({
    required String name,
    required String timezone,
    required String phone,
    String? job_type,
    String? workplace,
  }) async {
    complete_request = {
      'name': name,
      'timezone': timezone,
      'phone': phone,
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
    String? phone,
    String? job_type,
    String? workplace,
  }) => throw UnimplementedError();
}

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
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
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

    final button_bottom = tester
        .getBottomLeft(find.byKey(const Key('profile_setup_submit_button')))
        .dy;
    expect(button_bottom, lessThanOrEqualTo(844));
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
      'job_type': null,
      'workplace': null,
    });
    expect(completed, isTrue);
  });

  testWidgets('선택한 직종과 소속 정보를 가입 완료 요청에 포함한다', (tester) async {
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
    await tester.tap(find.byKey(const Key('profile_job_type_field')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('간호사 (RN)'));
    await tester.pumpAndSettle();
    await tester.enterText(
      _textFieldInside(const Key('profile_workplace_field')),
      '제일병원 중환자실',
    );
    await tester.tap(find.byKey(const Key('profile_setup_submit_button')));
    await tester.pumpAndSettle();

    expect(repository.complete_request?['job_type'], 'NURSE');
    expect(repository.complete_request?['workplace'], '제일병원 중환자실');
  });
}
