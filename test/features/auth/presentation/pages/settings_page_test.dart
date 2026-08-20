// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/domain/entities/profile_image_upload.dart';
import 'package:shift_mate/features/auth/presentation/pages/login_page.dart';
import 'package:shift_mate/features/auth/presentation/pages/settings_page.dart';
import 'package:shift_mate/features/auth/presentation/providers/auth_provider.dart';

class _SettingsAuthRepository implements AuthRepository {
  Object? delete_account_error;
  int delete_account_count = 0;

  static const user = User(
    id: 'user-id',
    email: 'user@example.com',
    name: '사용자',
  );

  @override
  Future<bool> isLoggedIn() async => true;

  @override
  Future<User> getProfile() async => user;

  @override
  Future<void> deleteAccount(User user) async {
    delete_account_count += 1;
    final current_error = delete_account_error;
    if (current_error != null) throw current_error;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<AuthResponse> loginWithApple() => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithGoogle() => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithKakao() => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithNaver() => throw UnimplementedError();

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

  @override
  Future<User> completeProfile({
    required String name,
    required String timezone,
    required String phone,
    ProfileImageUpload? profile_image,
    String? job_type,
    String? workplace,
  }) => throw UnimplementedError();
}

Future<void> _pumpSettings(
  WidgetTester tester,
  _SettingsAuthRepository repository,
) async {
  final container = ProviderContainer(
    overrides: [authRepositoryProvider.overrideWithValue(repository)],
  );
  addTearDown(container.dispose);
  await container.read(authProvider.notifier).checkAuthStatus();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const CupertinoApp(home: SettingsPage()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollToDeleteAccount(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.byKey(const Key('delete_account_button')),
    300,
    scrollable: find.byType(Scrollable),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('로그아웃과 회원 탈퇴 버튼을 함께 표시한다', (tester) async {
    await _pumpSettings(tester, _SettingsAuthRepository());
    await _scrollToDeleteAccount(tester);

    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.byKey(const Key('delete_account_button')), findsOneWidget);
    expect(find.text('회원 탈퇴'), findsOneWidget);
  });

  testWidgets('복구 불가 안내 확인 후 탈퇴를 요청하고 로그인 화면으로 이동한다', (tester) async {
    final repository = _SettingsAuthRepository();
    await _pumpSettings(tester, repository);
    await _scrollToDeleteAccount(tester);

    await tester.tap(find.byKey(const Key('delete_account_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('삭제된 데이터는 복구할 수 없습니다'), findsOneWidget);
    await tester.tap(find.widgetWithText(CupertinoDialogAction, '탈퇴'));
    await tester.pumpAndSettle();

    expect(repository.delete_account_count, 1);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('재인증 필요 응답은 설정 화면을 유지하고 다시 로그인을 안내한다', (tester) async {
    final repository = _SettingsAuthRepository()
      ..delete_account_error = ApiException(
        code: 'REAUTHENTICATION_REQUIRED',
        message: '회원 탈퇴를 위해 다시 로그인해주세요.',
        statusCode: 403,
      );
    await _pumpSettings(tester, repository);
    await _scrollToDeleteAccount(tester);

    await tester.tap(find.byKey(const Key('delete_account_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(CupertinoDialogAction, '탈퇴'));
    await tester.pumpAndSettle();

    expect(find.text('다시 로그인이 필요합니다'), findsOneWidget);
    expect(find.text('다시 로그인'), findsOneWidget);
    expect(find.byType(SettingsPage), findsOneWidget);
  });
}
