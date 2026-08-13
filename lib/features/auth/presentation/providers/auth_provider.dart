// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/network/api_exception.dart';
import '../../../calendar/presentation/providers/calendar_range_provider.dart';
import '../../../calendar/presentation/providers/shift_template_settings_provider.dart';
import '../../../calendar/presentation/providers/shift_types_provider.dart';
import '../../../friend/presentation/providers/friend_calendar_range_provider.dart';
import '../../../friend/presentation/providers/friend_provider.dart';
import '../../../friend/presentation/providers/notification_provider.dart';
import '../../../group/application/group_calendar_provider.dart';
import '../../../group/application/group_providers.dart';
import '../../data/models/apple_auth_models.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/services/google_login_service.dart';
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

enum AccountDeletionResult {
  accepted,
  reauthentication_required,
  session_ended,
  failed,
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
  return AuthNotifier(repository, ref);
});

/// 인증 상태 Notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;

  AuthNotifier(this._repository, this._ref) : super(const AuthState());

  void _invalidateAccountScopedProviders() {
    _ref.invalidate(calendarRangeProvider);
    _ref.invalidate(friendCalendarRangeProvider);
    _ref.invalidate(shiftTypesProvider);
    _ref.invalidate(shiftTypeDisplayUpdatesProvider);
    _ref.invalidate(effectiveShiftTypesProvider);
    _ref.invalidate(shiftTypesMapProvider);
    _ref.invalidate(shiftTypeOrderProvider);
    _ref.invalidate(shiftTemplateSettingsProvider);
    _ref.invalidate(friendListProvider);
    _ref.invalidate(searchUserProvider);
    _ref.invalidate(friendRequestsProvider);
    _ref.invalidate(notificationProvider);
    _ref.invalidate(groupListProvider);
    _ref.invalidate(groupDetailProvider);
    _ref.invalidate(groupCalendarRangeProvider);
    _ref.invalidate(receivedGroupInvitationsProvider);
  }

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

      _invalidateAccountScopedProviders();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        is_new_user: authResponse.is_new_user,
      );

      return true;
    } catch (e) {
      final errorMessage = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(is_loading: false, error: errorMessage);
      return false;
    }
  }

  /// 네이버 로그인
  Future<bool> loginWithNaver() async {
    state = state.copyWith(is_loading: true, error: null);

    try {
      final authResponse = await _repository.loginWithNaver();

      _invalidateAccountScopedProviders();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        is_new_user: authResponse.is_new_user,
      );

      return true;
    } catch (e) {
      final errorMessage = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(is_loading: false, error: errorMessage);
      return false;
    }
  }

  /// Google 로그인
  Future<bool> loginWithGoogle() async {
    state = state.copyWith(is_loading: true, error: null);

    try {
      final authResponse = await _repository.loginWithGoogle();

      _invalidateAccountScopedProviders();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        is_new_user: authResponse.is_new_user,
      );

      return true;
    } on GoogleLoginCanceledException {
      state = state.copyWith(is_loading: false, error: null);
      return false;
    } catch (e) {
      final errorMessage = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(is_loading: false, error: errorMessage);
      return false;
    }
  }

  /// Apple 로그인
  Future<bool> loginWithApple() async {
    state = state.copyWith(is_loading: true, error: null);

    try {
      final authResponse = await _repository.loginWithApple();

      _invalidateAccountScopedProviders();

      state = AuthState(
        status: AuthStatus.authenticated,
        user: authResponse.user,
        is_new_user: authResponse.is_new_user,
      );

      return true;
    } on AppleLoginCanceledException {
      state = state.copyWith(is_loading: false, error: null);
      return false;
    } catch (e) {
      final errorMessage = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(is_loading: false, error: errorMessage);
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
      final errorMessage = e is ApiException
          ? e.message
          : e.toString().replaceAll('Exception: ', '');
      state = state.copyWith(is_loading: false, error: errorMessage);
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

    _invalidateAccountScopedProviders();

    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  /// 소셜 연결 해제와 서버 탈퇴 접수를 순차적으로 실행한다.
  Future<AccountDeletionResult> deleteAccount() async {
    final user = state.user;
    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return AccountDeletionResult.session_ended;
    }

    state = state.copyWith(is_loading: true, error: null);

    try {
      await _repository.deleteAccount(user);
      _invalidateAccountScopedProviders();
      state = const AuthState(status: AuthStatus.unauthenticated);
      return AccountDeletionResult.accepted;
    } on ApiException catch (error) {
      if (error.request_id != null) {
        debugPrint('회원 탈퇴 실패 request_id=${error.request_id}');
      }

      if (error.code == 'REAUTHENTICATION_REQUIRED') {
        state = state.copyWith(is_loading: false, error: null);
        return AccountDeletionResult.reauthentication_required;
      }

      if (error.statusCode == 401 ||
          error.code == 'ACCOUNT_DELETION_IN_PROGRESS') {
        _invalidateAccountScopedProviders();
        state = const AuthState(status: AuthStatus.unauthenticated);
        return AccountDeletionResult.session_ended;
      }

      state = state.copyWith(is_loading: false, error: error.message);
      return AccountDeletionResult.failed;
    } catch (error) {
      state = state.copyWith(
        is_loading: false,
        error: error.toString().replaceAll('Exception: ', ''),
      );
      return AccountDeletionResult.failed;
    }
  }

  /// 에러 초기화
  void clearError() {
    state = state.copyWith(error: null);
  }
}
