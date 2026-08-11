// ignore_for_file: non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/auth/data/models/apple_auth_models.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/data/services/google_login_service.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  Object? apple_login_error;
  Object? google_login_error;
  AuthResponse? google_login_response;

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<AuthResponse> loginWithApple() async {
    final current_error = apple_login_error;
    if (current_error != null) throw current_error;
    throw UnimplementedError();
  }

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<User> getProfile() => throw UnimplementedError();

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
  Future<User> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
  }) => throw UnimplementedError();
}

void main() {
  test('Apple 사용자 취소는 로그인 오류로 노출하지 않는다', () async {
    final repository = _FakeAuthRepository()
      ..apple_login_error = const AppleLoginCanceledException();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
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
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final notifier = container.read(authProvider.notifier);
    await notifier.checkAuthStatus();
    final success = await notifier.loginWithGoogle();

    expect(success, isFalse);
    expect(container.read(authProvider).status, AuthStatus.unauthenticated);
    expect(container.read(authProvider).is_loading, isFalse);
    expect(container.read(authProvider).error, isNull);
  });

  test('Google 성공 응답의 is_new_user를 인증 상태에 유지한다', () async {
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
        is_new_user: true,
      );
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final success = await container
        .read(authProvider.notifier)
        .loginWithGoogle();
    final state = container.read(authProvider);

    expect(success, isTrue);
    expect(state.status, AuthStatus.authenticated);
    expect(state.user?.google_id, 'google-subject');
    expect(state.is_new_user, isTrue);
    expect(state.error, isNull);
  });
}
