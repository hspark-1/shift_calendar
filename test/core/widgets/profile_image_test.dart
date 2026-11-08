import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/constants/api_constants.dart';
import 'package:shift_mate/core/network/api_client.dart';
import 'package:shift_mate/core/widgets/profile_image.dart';

class ImageAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromBytes(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=',
      ),
      200,
      headers: {
        Headers.contentTypeHeader: ['image/png'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('관리 이미지 상대 URL은 Bearer 인증으로 조회하고 표시한다', (tester) async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'test-token',
      'expires_at': DateTime.now()
          .add(const Duration(hours: 1))
          .toIso8601String(),
    });
    final dio = ApiClient.createDio();
    final adapter = ImageAdapter();
    dio.httpClientAdapter = adapter;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const CupertinoApp(
          home: ProfileImage(
            image_url: '/api/v1/profile-images/123',
            fallback: Icon(CupertinoIcons.person),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(adapter.requests, hasLength(1));
    expect(
      adapter.requests.single.uri.origin,
      Uri.parse(ApiConstants.base_url).origin,
    );
    expect(
      adapter.requests.single.headers['Authorization'],
      'Bearer test-token',
    );
    expect(adapter.requests.single.followRedirects, isFalse);
    expect(find.byType(Image), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 이미지 URL은 네트워크 요청 없이 기본 아이콘을 표시한다', (tester) async {
    final dio = ApiClient.createDio();
    final adapter = ImageAdapter();
    dio.httpClientAdapter = adapter;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const CupertinoApp(
          home: ProfileImage(
            image_url: '',
            fallback: Icon(CupertinoIcons.person),
          ),
        ),
      ),
    );
    expect(adapter.requests, isEmpty);
    expect(find.byIcon(CupertinoIcons.person), findsOneWidget);
  });
}
