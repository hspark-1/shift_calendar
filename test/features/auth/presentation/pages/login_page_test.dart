// ignore_for_file: non_constant_identifier_names

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/auth/presentation/pages/login_page.dart';

Future<({int width, int height, List<int> sample_rgba})> readAssetPixel(
  String asset_path, {
  required int sample_x,
  required int sample_y,
}) async {
  final asset_data = await rootBundle.load(asset_path);
  final codec = await ui.instantiateImageCodec(
    asset_data.buffer.asUint8List(
      asset_data.offsetInBytes,
      asset_data.lengthInBytes,
    ),
  );
  final frame = await codec.getNextFrame();
  final image = frame.image;
  final raw_data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

  if (raw_data == null) {
    image.dispose();
    codec.dispose();
    throw StateError('$asset_path 픽셀 데이터를 읽을 수 없습니다.');
  }

  final sample_offset = (sample_y * image.width + sample_x) * 4;
  final rgba = raw_data.buffer.asUint8List(
    raw_data.offsetInBytes + sample_offset,
    4,
  );
  final result = (
    width: image.width,
    height: image.height,
    sample_rgba: rgba.toList(),
  );

  image.dispose();
  codec.dispose();
  return result;
}

void main() {
  testWidgets('카카오와 네이버 로그인 이미지를 같은 크기의 버튼으로 표시한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(child: CupertinoApp(home: LoginPage())),
    );
    await tester.pumpAndSettle();

    final kakao_image = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/icons/kakao_login_img.png',
      ),
    );
    final naver_image = tester.widget<Image>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/icons/naver_login_img.png',
      ),
    );

    expect(kakao_image.fit, BoxFit.contain);
    expect(kakao_image.excludeFromSemantics, isTrue);
    expect(naver_image.fit, BoxFit.contain);
    expect(naver_image.excludeFromSemantics, isTrue);

    expect(
      tester.getSize(find.byKey(const Key('kakao_login_button'))),
      const Size(342, 54),
    );
    expect(
      tester.getSize(find.byKey(const Key('naver_login_button'))),
      const Size(342, 54),
    );

    final semantics = tester.ensureSemantics();
    expect(find.bySemanticsLabel('카카오 로그인'), findsOneWidget);
    expect(find.bySemanticsLabel('네이버 로그인'), findsOneWidget);
    expect(
      tester.getSize(find.bySemanticsLabel('카카오 로그인')),
      const Size(342, 54),
    );
    expect(
      tester.getSize(find.bySemanticsLabel('네이버 로그인')),
      const Size(342, 54),
    );
    semantics.dispose();
  });

  test('로그인 이미지 규격과 브랜드 배경색을 유지한다', () async {
    TestWidgetsFlutterBinding.ensureInitialized();

    final kakao_asset = await readAssetPixel(
      'assets/icons/kakao_login_img.png',
      sample_x: 120,
      sample_y: 45,
    );
    final naver_asset = await readAssetPixel(
      'assets/icons/naver_login_img.png',
      sample_x: 120,
      sample_y: 45,
    );

    expect((kakao_asset.width, kakao_asset.height), (600, 90));
    expect(kakao_asset.sample_rgba, [254, 229, 0, 255]);
    expect((naver_asset.width, naver_asset.height), (600, 90));
    expect(naver_asset.sample_rgba, [3, 169, 77, 255]);
  });
}
