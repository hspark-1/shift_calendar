// ignore_for_file: non_constant_identifier_names

import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:shift_mate/features/auth/data/services/google_login_service.dart';
import 'package:shift_mate/features/auth/domain/entities/user.dart';
import 'package:shift_mate/features/auth/presentation/pages/login_page.dart';

class _PendingGoogleAuthRepository implements AuthRepository {
  final google_login_completer = Completer<AuthResponse>();

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<User> getProfile() => throw UnimplementedError();

  @override
  Future<bool> isLoggedIn() async => false;

  @override
  Future<AuthResponse> loginWithApple() => throw UnimplementedError();

  @override
  Future<AuthResponse> loginWithGoogle() => google_login_completer.future;

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
  }) => throw UnimplementedError();
}

Future<({int width, int height})> readAssetSize(String asset_path) async {
  final asset_data = await rootBundle.load(asset_path);
  final codec = await ui.instantiateImageCodec(
    asset_data.buffer.asUint8List(
      asset_data.offsetInBytes,
      asset_data.lengthInBytes,
    ),
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final result = (width: image.width, height: image.height);

  image.dispose();
  codec.dispose();
  return result;
}

Finder findAssetImage(String asset_path) {
  return find.byWidgetPredicate(
    (widget) =>
        widget is Image &&
        widget.image is AssetImage &&
        (widget.image as AssetImage).assetName == asset_path,
  );
}

void main() {
  testWidgets('카카오·네이버·Google 원형 아이콘을 순서대로 같은 행에 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: CupertinoApp(home: LoginPage())),
    );
    await tester.pumpAndSettle();

    final kakao_finder = find.byKey(const Key('kakao_login_button'));
    final naver_finder = find.byKey(const Key('naver_login_button'));
    final google_finder = find.byKey(const Key('google_login_button'));

    expect(tester.getSize(kakao_finder), const Size.square(64));
    expect(tester.getSize(naver_finder), const Size.square(64));
    expect(tester.getSize(google_finder), const Size.square(64));
    expect(
      tester.getCenter(kakao_finder).dy,
      tester.getCenter(naver_finder).dy,
    );
    expect(
      tester.getCenter(naver_finder).dy,
      tester.getCenter(google_finder).dy,
    );
    expect(
      tester.getCenter(naver_finder).dx - tester.getCenter(kakao_finder).dx,
      84,
    );
    expect(
      tester.getCenter(google_finder).dx - tester.getCenter(naver_finder).dx,
      84,
    );
    expect(find.byKey(const Key('apple_login_button')), findsNothing);

    final kakao_image = tester.widget<Image>(
      findAssetImage('assets/icons/kakao.png'),
    );
    final naver_image = tester.widget<Image>(
      findAssetImage('assets/icons/naver.png'),
    );
    final google_image = tester.widget<Image>(
      findAssetImage('assets/icons/google.png'),
    );
    expect(kakao_image.fit, BoxFit.cover);
    expect(kakao_image.excludeFromSemantics, isTrue);
    expect(
      tester.getSize(findAssetImage('assets/icons/kakao.png')),
      const Size.square(64),
    );
    expect(naver_image.fit, BoxFit.cover);
    expect(naver_image.excludeFromSemantics, isTrue);
    expect(
      tester.getSize(findAssetImage('assets/icons/naver.png')),
      const Size.square(64),
    );
    expect(google_image.fit, BoxFit.cover);
    expect(google_image.excludeFromSemantics, isTrue);
    expect(
      tester.getSize(findAssetImage('assets/icons/google.png')),
      const Size.square(64),
    );

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('카카오 로그인'), findsOneWidget);
    expect(find.bySemanticsLabel('네이버 로그인'), findsOneWidget);
    expect(find.bySemanticsLabel('Google 로그인'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('390px에서 카카오·네이버·Google·Apple을 한 줄에 순서대로 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: CupertinoApp(home: LoginPage(apple_login_enabled: true)),
      ),
    );
    await tester.pumpAndSettle();

    final kakao_finder = find.byKey(const Key('kakao_login_button'));
    final naver_finder = find.byKey(const Key('naver_login_button'));
    final google_finder = find.byKey(const Key('google_login_button'));
    final apple_finder = find.byKey(const Key('apple_login_button'));
    final button_centers = [
      tester.getCenter(kakao_finder),
      tester.getCenter(naver_finder),
      tester.getCenter(google_finder),
      tester.getCenter(apple_finder),
    ];

    for (final button_finder in [
      kakao_finder,
      naver_finder,
      google_finder,
      apple_finder,
    ]) {
      expect(tester.getSize(button_finder), const Size.square(64));
    }
    expect(button_centers[0].dy, button_centers[1].dy);
    expect(button_centers[1].dy, button_centers[2].dy);
    expect(button_centers[2].dy, button_centers[3].dy);
    expect(button_centers[1].dx - button_centers[0].dx, 84);
    expect(button_centers[2].dx - button_centers[1].dx, 84);
    expect(button_centers[3].dx - button_centers[2].dx, 84);
    expect(findAssetImage('assets/icons/google.png'), findsOneWidget);
    expect(findAssetImage('assets/icons/apple.png'), findsOneWidget);
    expect(
      tester.getSize(findAssetImage('assets/icons/apple.png')),
      const Size.square(64),
    );

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('카카오 로그인'), findsOneWidget);
    expect(find.bySemanticsLabel('네이버 로그인'), findsOneWidget);
    expect(find.bySemanticsLabel('Google 로그인'), findsOneWidget);
    expect(find.bySemanticsLabel('Apple 로그인'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('좁은 화면에서는 순서를 유지해 자동 줄바꿈한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(280, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: CupertinoApp(home: LoginPage(apple_login_enabled: true)),
      ),
    );
    await tester.pumpAndSettle();

    final kakao_center = tester.getCenter(
      find.byKey(const Key('kakao_login_button')),
    );
    final naver_center = tester.getCenter(
      find.byKey(const Key('naver_login_button')),
    );
    final google_center = tester.getCenter(
      find.byKey(const Key('google_login_button')),
    );
    final apple_center = tester.getCenter(
      find.byKey(const Key('apple_login_button')),
    );

    expect(kakao_center.dy, naver_center.dy);
    expect(naver_center.dy, google_center.dy);
    expect(kakao_center.dx, lessThan(naver_center.dx));
    expect(naver_center.dx, lessThan(google_center.dx));
    expect(apple_center.dy, greaterThan(google_center.dy));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Google 로그인 중 모든 소셜 버튼을 비활성화하고 취소 오류는 표시하지 않는다', (tester) async {
    final repository = _PendingGoogleAuthRepository();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: const CupertinoApp(home: LoginPage(apple_login_enabled: true)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('google_login_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));

    for (final button_key in [
      'kakao_login_button',
      'naver_login_button',
      'google_login_button',
      'apple_login_button',
    ]) {
      final button_finder = find.byKey(Key(button_key));
      final button = tester.widget<CupertinoButton>(button_finder);
      final opacity = tester.widget<AnimatedOpacity>(
        find.descendant(
          of: button_finder,
          matching: find.byType(AnimatedOpacity),
        ),
      );
      expect(button.onPressed, isNull);
      expect(opacity.opacity, 0.45);
    }
    expect(find.byType(CupertinoActivityIndicator), findsOneWidget);

    repository.google_login_completer.completeError(
      const GoogleLoginCanceledException(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CupertinoAlertDialog), findsNothing);
    expect(find.byType(CupertinoActivityIndicator), findsNothing);
  });

  test('소셜 로그인 원형 이미지 네 개의 규격을 유지한다', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    for (final asset_path in [
      'assets/icons/kakao.png',
      'assets/icons/naver.png',
      'assets/icons/google.png',
      'assets/icons/apple.png',
    ]) {
      expect(await readAssetSize(asset_path), (width: 176, height: 176));
    }
  });
}
