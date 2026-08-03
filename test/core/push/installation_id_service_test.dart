// ignore_for_file: non_constant_identifier_names

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/push/installation_id_service.dart';
import 'package:uuid/uuid.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('설치 UUID를 한 번 생성하고 로그아웃과 무관하게 재사용한다', () async {
    final service = InstallationIdService();

    final first_id = await service.getOrCreate();
    final second_id = await service.getOrCreate();

    expect(Uuid.isValidUUID(fromString: first_id), isTrue);
    expect(second_id, first_id);
  });

  test('손상된 저장값은 새 UUID로 교체한다', () async {
    FlutterSecureStorage.setMockInitialValues({
      'push_installation_id': 'invalid',
    });
    final service = InstallationIdService();

    final installation_id = await service.getOrCreate();

    expect(Uuid.isValidUUID(fromString: installation_id), isTrue);
    expect(installation_id, isNot('invalid'));
  });
}
