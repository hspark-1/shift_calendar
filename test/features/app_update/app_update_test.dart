// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shift_mate/core/network/api_client.dart';
import 'package:shift_mate/features/app_update/application/app_update_controller.dart';
import 'package:shift_mate/features/app_update/data/app_update_repository.dart';
import 'package:shift_mate/features/app_update/domain/app_update_policy.dart';
import 'package:shift_mate/features/app_update/presentation/app_update_gate.dart';

const store_url = 'https://apps.apple.com/kr/app/id6831957246';

Map<String, dynamic> policyJson(int minimum) => {
  'schema_version': 1,
  'platform': 'IOS',
  'minimum_compatibility_version': minimum,
  'update_url': store_url,
  'message': '계속 사용하려면 업데이트해 주세요.',
};

AppUpdatePolicy policy(int minimum) =>
    AppUpdatePolicy.fromJson(policyJson(minimum), expected_platform: 'IOS');

class MemoryPolicyRepository extends AppUpdateRepository {
  AppUpdatePolicy? cached;
  Future<AppUpdatePolicy> Function() loader;
  int request_count = 0;
  bool cache_write_fails = false;

  MemoryPolicyRepository({required this.loader, this.cached})
    : super(dio: Dio(), platform: 'IOS');

  @override
  Future<AppUpdatePolicy?> readCachedPolicy() async => cached;

  @override
  Future<void> savePolicy(AppUpdatePolicy policy) async {
    if (cache_write_fails) throw StateError('cache unavailable');
    cached = policy;
  }

  @override
  Future<AppUpdatePolicy> fetchPolicy() {
    request_count++;
    return loader();
  }
}

class PolicyAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  dynamic body;

  PolicyAdapter(this.body);

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? request_stream,
    Future<void>? cancel_future,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('호환 번호가 최소값 미만일 때만 차단하고 스토어 버전과 독립적이다', () {
    final current_policy = policy(2);
    expect(current_policy.requiresUpdate(1), isTrue);
    expect(current_policy.requiresUpdate(2), isFalse);
    expect(current_policy.requiresUpdate(10), isFalse);
    expect(policy(0).requiresUpdate(1), isFalse);
  });

  test('스키마·플랫폼·정수 범위를 검증하고 다른 앱 주소는 거부한다', () {
    final invalid = [
      {...policyJson(2), 'schema_version': 2},
      {...policyJson(2), 'platform': 'ANDROID'},
      {...policyJson(2), 'minimum_compatibility_version': '2'},
      {...policyJson(2), 'minimum_compatibility_version': -1},
      {...policyJson(2), 'minimum_compatibility_version': 2147483648},
      {...policyJson(2), 'update_url': null},
      {
        ...policyJson(2),
        'update_url': 'https://apps.apple.com.evil.test/app/id6831957246',
      },
      {...policyJson(2), 'update_url': 'https://apps.apple.com/app/id123'},
      {
        ...policyJson(2),
        'update_url': 'http://apps.apple.com/app/id6831957246',
      },
      {
        ...policyJson(2),
        'update_url': 'https://user@古apps.apple.com/app/id6831957246',
      },
    ];
    for (final data in invalid) {
      expect(
        () => AppUpdatePolicy.fromJson(data, expected_platform: 'IOS'),
        throwsFormatException,
      );
    }
    expect(
      AppUpdatePolicy.fromJson({
        ...policyJson(0),
        'update_url': null,
      }, expected_platform: 'IOS').requiresUpdate(1),
      isFalse,
    );
    expect(
      AppUpdatePolicy.fromJson({
        ...policyJson(2),
        'platform': 'ANDROID',
        'update_url':
            'https://play.google.com/store/apps/details?id=com.hspark.shiftmate',
      }, expected_platform: 'ANDROID').requiresUpdate(1),
      isTrue,
    );
  });

  test('정책은 로그인 토큰·refresh 없이 올바른 플랫폼으로 조회한다', () async {
    FlutterSecureStorage.setMockInitialValues({
      'access_token': 'private-test-token',
      'refresh_token': 'private-test-refresh',
      'expires_at': '2000-01-01T00:00:00Z',
    });
    final dio = ApiClient.createDio();
    final adapter = PolicyAdapter({'success': true, 'data': policyJson(2)});
    dio.httpClientAdapter = adapter;
    final repository = AppUpdateRepository(dio: dio, platform: 'IOS');
    expect((await repository.fetchPolicy()).requiresUpdate(1), isTrue);
    expect(adapter.requests, hasLength(1));
    final request = adapter.requests.single;
    expect(request.path, '/app/version-policy');
    expect(request.queryParameters, {'platform': 'IOS'});
    expect(request.headers.containsKey('Authorization'), isFalse);
    expect(request.followRedirects, isFalse);
    adapter.body = {
      'success': true,
      'data': {'minimum_compatibility_version': 0},
    };
    await expectLater(repository.fetchPolicy(), throwsFormatException);
  });

  test('정책 캐시는 환경별·플랫폼별 격리 및 손상 복구를 지원한다', () async {
    final source = AppUpdateRepository(
      dio: Dio(BaseOptions(baseUrl: 'https://api.shiftmate.co.kr/api/v1')),
      platform: 'IOS',
    );
    await source.savePolicy(policy(2));
    expect((await source.readCachedPolicy())!.requiresUpdate(1), isTrue);
    final stage_source = AppUpdateRepository(
      dio: Dio(
        BaseOptions(baseUrl: 'https://stage-api.shiftmate.co.kr/api/v1'),
      ),
      platform: 'IOS',
    );
    expect(await stage_source.readCachedPolicy(), isNull);
    final android_source = AppUpdateRepository(
      dio: source.dio,
      platform: 'ANDROID',
    );
    expect(await android_source.readCachedPolicy(), isNull);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(source.cache_key, '{invalid');
    expect(await source.readCachedPolicy(), isNull);
    expect(preferences.containsKey(source.cache_key), isFalse);
  });

  test('동시 확인은 요청을 합치며 정책 완화는 저장된 차단을 해제한다', () async {
    final pending = Completer<AppUpdatePolicy>();
    final repository = MemoryPolicyRepository(loader: () => pending.future);
    final controller = AppUpdateController(repository: repository);
    addTearDown(controller.dispose);
    final first = controller.check();
    final second = controller.check();
    expect(identical(first, second), isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(repository.request_count, 1);
    pending.complete(policy(2));
    await first;
    expect(controller.state.update_required, isTrue);
    repository.loader = () async => policy(0);
    await controller.check();
    expect(controller.state.update_required, isFalse);
    expect(repository.cached!.minimum_compatibility_version, 0);
  });

  test('조회 실패 시 이미 확인한 차단을 유지하고 최초 미확인만 허용한다', () async {
    for (final cached in [policy(2), null]) {
      final controller = AppUpdateController(
        repository: MemoryPolicyRepository(
          cached: cached,
          loader: () async => throw const FormatException('offline'),
        ),
      );
      await controller.check();
      expect(controller.state.initialized, isTrue);
      expect(controller.state.check_failed, isTrue);
      expect(controller.state.update_required, cached != null);
      controller.dispose();
    }
  });

  test('캐시 쓰기 실패가 새 차단 정책을 무효화하지 않는다', () async {
    final repository = MemoryPolicyRepository(loader: () async => policy(2))
      ..cache_write_fails = true;
    final controller = AppUpdateController(repository: repository);
    addTearDown(controller.dispose);
    await controller.check();
    expect(controller.state.update_required, isTrue);
    expect(controller.state.check_failed, isFalse);
  });

  test('dispose 뒤 도착한 응답은 상태를 갱신하지 않는다', () async {
    final pending = Completer<AppUpdatePolicy>();
    final controller = AppUpdateController(
      repository: MemoryPolicyRepository(loader: () => pending.future),
    );
    final check = controller.check();
    await Future<void>.delayed(Duration.zero);
    controller.dispose();
    pending.complete(policy(2));
    await check;
  });

  testWidgets('최초 검사 전 화면 진입을 보류하고 스토어 실패·복귀에도 차단한다', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final pending = Completer<AppUpdatePolicy>();
    final repository = MemoryPolicyRepository(loader: () => pending.future);
    final controller = AppUpdateController(repository: repository);
    Uri? opened_url;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateControllerProvider.overrideWith((ref) => controller),
        ],
        child: CupertinoApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(1.5)),
            child: AppUpdateGate(
              launch_update_url: (url) async {
                opened_url = url;
                return false;
              },
              child: child!,
            ),
          ),
          home: const CupertinoPageScaffold(
            child: Center(child: Text('기존 앱 화면')),
          ),
        ),
      ),
    );
    expect(find.text('기존 앱 화면'), findsNothing);
    await tester.pump();
    pending.complete(policy(2));
    await tester.pumpAndSettle();
    expect(find.text('업데이트가 필요해요'), findsOneWidget);
    expect(find.text('기존 앱 화면'), findsNothing);
    await tester.ensureVisible(find.text('업데이트'));
    await tester.tap(find.text('업데이트'));
    await tester.pumpAndSettle();
    expect(opened_url, Uri.parse(store_url));
    expect(find.text('스토어를 열지 못했어요. 잠시 후 다시 시도해 주세요.'), findsOneWidget);
    repository.loader = () async => throw StateError('network unavailable');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(controller.state.update_required, isTrue);
    repository.loader = () async => policy(0);
    await tester.ensureVisible(find.text('다시 확인'));
    await tester.tap(find.text('다시 확인'));
    await tester.pumpAndSettle();
    expect(find.text('기존 앱 화면'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 열린 하위 화면과 다이얼로그도 정책 차단 뒤 노출되지 않는다', (tester) async {
    final repository = MemoryPolicyRepository(loader: () async => policy(0));
    final controller = AppUpdateController(repository: repository);
    final navigator_key = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appUpdateControllerProvider.overrideWith((ref) => controller),
        ],
        child: CupertinoApp(
          navigatorKey: navigator_key,
          builder: (context, child) => AppUpdateGate(child: child!),
          home: const CupertinoPageScaffold(child: Text('홈 화면')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      navigator_key.currentState!.push(
        CupertinoPageRoute<void>(
          builder: (_) => const CupertinoPageScaffold(child: Text('설정 상세')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    unawaited(
      showCupertinoDialog<void>(
        context: navigator_key.currentContext!,
        builder: (_) => const CupertinoAlertDialog(title: Text('열려 있던 대화상자')),
      ),
    );
    await tester.pumpAndSettle();
    repository.loader = () async => policy(2);
    await controller.check();
    await tester.pumpAndSettle();
    expect(find.text('업데이트가 필요해요'), findsOneWidget);
    expect(find.text('설정 상세'), findsNothing);
    expect(find.text('열려 있던 대화상자'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
