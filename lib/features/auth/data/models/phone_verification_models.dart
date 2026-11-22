// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import '../../../../core/network/api_exception.dart';

enum PhoneVerificationPurpose {
  signup('SIGNUP'),
  phone_change('PHONE_CHANGE');

  final String api_value;
  const PhoneVerificationPurpose(this.api_value);

  static PhoneVerificationPurpose parse(Object? value) => values.firstWhere(
    (purpose) => purpose.api_value == value,
    orElse: () => throw const FormatException('Invalid verification purpose'),
  );
}

String phoneDigits(String? value) =>
    (value ?? '').replaceAll(RegExp('[^0-9]'), '');

bool isKoreanMobilePhone(String digits) =>
    RegExp(r'^(?:010[0-9]{8}|01[16789][0-9]{7,8})$').hasMatch(digits);

String koreanPhoneE164(String digits) {
  if (!isKoreanMobilePhone(digits)) {
    throw ApiException(code: 'INVALID_PHONE', message: '한국 휴대폰 번호 형식을 확인해주세요.');
  }
  return '+82${digits.substring(1)}';
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw const FormatException('Invalid phone verification response');
  }
  return value;
}

DateTime _utcTime(Map<String, dynamic> json, String key) {
  final value = _requiredText(json, key);
  if (!RegExp(r'(Z|[+-][0-9]{2}:[0-9]{2})$').hasMatch(value)) {
    throw const FormatException('Timezone required');
  }
  return DateTime.parse(value).toUtc();
}

class PhoneChallenge {
  final String challenge_id;
  final String phone;
  final String phone_e164;
  final PhoneVerificationPurpose purpose;
  final DateTime server_now;
  final DateTime expires_at;

  const PhoneChallenge({
    required this.challenge_id,
    required this.phone,
    required this.phone_e164,
    required this.purpose,
    required this.server_now,
    required this.expires_at,
  });

  factory PhoneChallenge.fromJson(Map<String, dynamic> json) {
    final phone = _requiredText(json, 'phone');
    final phone_e164 = _requiredText(json, 'phone_e164');
    final server_now = _utcTime(json, 'server_now');
    final expires_at = _utcTime(json, 'expires_at');
    if (!isKoreanMobilePhone(phone) ||
        phone_e164 != koreanPhoneE164(phone) ||
        !expires_at.isAfter(server_now)) {
      throw const FormatException('Invalid challenge');
    }
    return PhoneChallenge(
      challenge_id: _requiredText(json, 'challenge_id'),
      phone: phone,
      phone_e164: phone_e164,
      purpose: PhoneVerificationPurpose.parse(json['purpose']),
      server_now: server_now,
      expires_at: expires_at,
    );
  }
}

class PhoneVerificationProof {
  final String token;
  final String phone;
  final PhoneVerificationPurpose purpose;
  final DateTime server_now;
  final DateTime expires_at;

  const PhoneVerificationProof({
    required this.token,
    required this.phone,
    required this.purpose,
    required this.server_now,
    required this.expires_at,
  });

  factory PhoneVerificationProof.fromJson(Map<String, dynamic> json) {
    final phone = _requiredText(json, 'phone');
    final server_now = _utcTime(json, 'server_now');
    final expires_at = _utcTime(json, 'expires_at');
    if (!isKoreanMobilePhone(phone) || !expires_at.isAfter(server_now)) {
      throw const FormatException('Invalid proof');
    }
    return PhoneVerificationProof(
      token: _requiredText(json, 'phone_verification_token'),
      phone: phone,
      purpose: PhoneVerificationPurpose.parse(json['purpose']),
      server_now: server_now,
      expires_at: expires_at,
    );
  }
}
