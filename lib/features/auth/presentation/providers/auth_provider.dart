import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/user.dart';

/// 인증 상태
enum AuthStatus {
  /// 초기 상태 (로딩 중)
  initial,

  /// 인증됨 (로그인 상태)
  authenticated,

  /// 인증 안됨 (로그아웃 상태)
  unauthenticated,
}

/// 인증 상태 모델
class AuthState {
  final AuthStatus status;
  final User? user;
  final bool is_new_user;
  final String? error;
  final bool is_loading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.is_new_user = false,
    this.error,
    this.is_loading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    bool? is_new_user,
    String? error,
    bool? is_loading,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      is_new_user: is_new_user ?? this.is_new_user,
      error: error,
      is_loading: is_loading ?? this.is_loading,
    );
  }
}

/// 인증 상태 Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});

/// 인증 상태 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AuthState());

  /// 초기 인증 상태 확인
  Future<void> checkAuthStatus() async {
    state = state.copyWith(is_loading: true);

    try {
      final isLoggedIn = await _repository.isLoggedIn();

      if (isLoggedIn) {
        final user = await _repository.getProfile();
        state = AuthState(
          status: AuthStatus.authenticated,
          user: user,
          is_new_user: false,
        );
      } else {
        state = const AuthState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  /// 카카오 로그인
  Future<bool> loginWithKakao() async {
    state = state.copyWith(is_loading: true, error: null);

    try {
      final authResponse = await _repository.loginWithKakao();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        is_new_user: authResponse.is_new_user,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        is_loading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 프로필 수정
  Future<bool> updateProfile({
    String? name,
    String? timezone,
    String? profile_image_url,
  }) async {
    state = state.copyWith(is_loading: true, error: null);

    try {
      final updatedUser = await _repository.updateProfile(
        name: name,
        timezone: timezone,
        profile_image_url: profile_image_url,
      );

      state = state.copyWith(
        user: updatedUser,
        is_new_user: false,
        is_loading: false,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        is_loading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
      return false;
    }
  }

  /// 프로필 설정 완료 (신규 사용자 플래그 해제)
  void completeProfileSetup() {
    state = state.copyWith(is_new_user: false);
  }

  /// 로그아웃
  Future<void> logout() async {
    state = state.copyWith(is_loading: true);

    try {
      await _repository.logout();
    } catch (e) {
      // 로그아웃 실패해도 로컬 상태는 초기화
    }

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}
