// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/auth/data/models/apple_auth_models.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/data/services/google_login_service.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/domain/entities/profile_image_upload.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/calendar/domain/entities/shift_type_info.dart';
import 'package:shift_mate/features/calendar/presentation/providers/shift_types_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  Object? apple_login_error;
  Object? google_login_error;
  AuthResponse? google_login_response;
  Object? delete_account_error;
  int delete_account_count = 0;
  bool is_logged_in = false;
  User? profile;
  User? completed_profile;
  Map<String, String?>? completed_profile_request;

  @override
  Future<bool> isLoggedIn() async => is_logged_in;

  @override
  Future<AuthResponse> loginWithApple() async {
    final current_error = apple_login_error;
    if (current_error != null) throw current_error;
    throw UnimplementedError();
  }

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<User> getProfile() async => profile!;

  @override
  Future<AuthResponse> loginWithKakao() => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithGoogle() async {
    final current_error = google_login_error;
    if (current_error != null) throw current_error;
    return google_login_response!;
  }

  @override
  Future<AuthResponse> loginWithNaver() => throw UnimplementedError();

  @override
  Future<AuthToken> refreshToken() => throw UnimplementedError();

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteAccount(User user) async {
    delete_account_count += 1;
    final current_error = delete_account_error;
    if (current_error != null) throw current_error;
  }

  @override
  Future<User> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
    String? phone,
    String? job_type,
    String? workplace,
  }) => throw UnimplementedError();

  @override
  Future<User> completeProfile({
    required String name,
    required String timezone,
    required String phone,
    ProfileImageUpload? profile_image,
    String? job_type,
    String? workplace,
  }) async {
    completed_profile_request = {
      'name': name,
      'timezone': timezone,
      'phone': phone,
      'profile_image': profile_image?.filename,
      'job_type': job_type,
      'workplace': workplace,
    };
    return completed_profile!;
  }
}

List<Override> _overrides(_FakeAuthRepository repository) => [
  authRepositoryProvider.overrideWithValue(repository),
  shiftTypesProvider.overrideWith((ref) async => const <ShiftTypeInfo>[]),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Apple 사용자 취소는 로그인 오류로 노출하지 않는다', () async {
    final repository = _FakeAuthRepository()
      ..apple_login_error = const AppleLoginCanceledException();
    final container = ProviderContainer(overrides: _overrides(repository));
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.checkAuthStatus();
    final success = await notifier.loginWithApple();

    expect(success, isFalse);
    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    expect(container.read(authProvider).is_loading, isFalse);
    expect(container.read(authProvider).error, isNull);
  });

  test('Google 사용자 취소는 로그인 오류로 노출하지 않는다', () async {
    final repository = _FakeAuthRepository()
      ..google_login_error = const GoogleLoginCanceledException();
    final container = ProviderContainer(overrides: _overrides(repository));
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.checkAuthStatus();
    final success = await notifier.loginWithGoogle();

    expect(success, isFalse);
    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    expect(container.read(authProvider).is_loading, isFalse);
    expect(container.read(authProvider).error, isNull);
  });

  test('Google 성공 응답의 requires_profile_setup을 인증 상태에 유지한다', () async {
    final repository = _FakeAuthRepository()
      ..google_login_response = AuthResponse(
        user: const User(
          id: 'google-user-id',
          email: 'google@example.com',
          name: 'Google 사용자',
          google_id: 'google-subject',
        ),
        access_token: 'access-token',
        refresh_token: 'refresh-token',
        expires_at: DateTime.utc(2026, 8, 11),
        requires_profile_setup: true,
      );
    final container = ProviderContainer(overrides: _overrides(repository));
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .loginWithGoogle();
    final state = container.read(authProvider);

    expect(success, isTrue);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.google_id, 'google-subject');
    expect(state.requires_profile_setup, isTrue);
    expect(state.error, isNull);
  });

  test('저장된 프로필이 미완료이면 앱 재시작 인증에서도 설정 화면 상태를 유지한다', () async {
    const user = User(
      id: 'user-id',
      email: 'user@example.com',
      name: '사용자',
      timezone: 'Asia/Seoul',
      phone: null,
      requires_profile_setup: true,
    );
    final repository = _FakeAuthRepository()
      ..is_logged_in = true
      ..profile = user;
    final container = ProviderContainer(overrides: _overrides(repository));
    addTearDown(container.dispose);

    await container.read(authProvider.notifier).checkAuthStatus();

    expect(container.read(authProvider).status, AuthStatus.authenticated);
    expect(container.read(authProvider).requires_profile_setup, isTrue);
  });

  test('가입 완료 성공 시 선택 정보를 전달하고 설정 필요 상태를 해제한다', () async {
    const completed_user = User(
      id: 'user-id',
      email: 'user@example.com',
      name: '김간호',
      timezone: 'Asia/Seoul',
      phone: '010-1234-5678',
      job_type: 'NURSE',
      workplace: '제일병원 중환자실',
      requires_profile_setup: false,
    );
    final repository = _FakeAuthRepository()
      ..completed_profile = completed_user;
    final container = ProviderContainer(overrides: _overrides(repository));
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .completeProfileSetup(
          name: '김간호',
          timezone: 'Asia/Seoul',
          phone: '01012345678',
          job_type: 'NURSE',
          workplace: '제일병원 중환자실',
        );

    expect(success, isTrue);
    expect(repository.completed_profile_request, {
      'name': '김간호',
      'timezone': 'Asia/Seoul',
      'phone': '01012345678',
      'profile_image': null,
      'job_type': 'NURSE',
      'workplace': '제일병원 중환자실',
    });
    expect(container.read(authProvider).user, completed_user);
    expect(container.read(authProvider).requires_profile_setup, isFalse);
    expect(container.read(authProvider).is_loading, isFalse);
  });

  test('탈퇴 접수 성공 시 계정 상태를 비인증으로 전환한다', () async {
    const user = User(id: 'user-id', email: 'user@example.com', name: '사용자');
    final repository = _FakeAuthRepository()
      ..is_logged_in = true
      ..profile = user;
    final container = ProviderContainer(overrides: _overrides(repository));
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.checkAuthStatus();
    final result = await notifier.deleteAccount();

    expect(result, AccountDeletionResult.accepted);
    expect(repository.delete_account_count, 1);
    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
  });

  test('재인증 필요 시 인증 상태를 유지하고 별도 결과를 반환한다', () async {
    const user = User(id: 'user-id', email: 'user@example.com', name: '사용자');
    final repository = _FakeAuthRepository()
      ..is_logged_in = true
      ..profile = user
      ..delete_account_error = ApiException(
        code: 'REAUTHENTICATION_REQUIRED',
        message: '다시 로그인해주세요.',
        statusCode: 403,
        request_id: 'request-id',
      );
    final container = ProviderContainer(overrides: _overrides(repository));
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.checkAuthStatus();
    final result = await notifier.deleteAccount();

    expect(result, AccountDeletionResult.reauthentication_required);
    expect(container.read(authProvider).status, AuthStatus.authenticated);
    expect(container.read(authProvider).is_loading, isFalse);
    expect(container.read(authProvider).error, isNull);
  });
}
