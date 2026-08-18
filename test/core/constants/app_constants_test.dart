// ignore_for_file: constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/core/constants/app_constants.dart';

void main() {
  test('Debug 빌드는 Stage Kakao Native App Key를 선택한다', () {
    const expected_stage_key = String.fromEnvironment(
      'KAKAO_NATIVE_APP_KEY_STAGE',
    );

    expect(expected_stage_key, isNotEmpty);
    expect(AppConstants.kakao_native_app_key, expected_stage_key);
    expect(
      AppConstants.kakao_native_app_key_define_name,
      'KAKAO_NATIVE_APP_KEY_STAGE',
    );
  });
}
