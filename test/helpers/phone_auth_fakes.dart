// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shift_mate/core/network/api_exception.dart';
import 'package:shift_mate/features/auth/data/models/phone_verification_models.dart';
import 'package:shift_mate/features/auth/data/repositories/phone_verification_repository.dart';
import 'package:shift_mate/features/auth/data/services/firebase_phone_auth_service.dart';

class FakePhoneRepository implements PhoneVerificationRepository {
  PhoneChallenge? challenge;
  int create_count = 0;
  int verify_count = 0;
  Object? create_error;
  Object? verify_error;
  Completer<PhoneChallenge>? pending_challenge;
  Completer<PhoneVerificationProof>? pending_proof;
  String? last_phone;
  String? last_challenge_key;
  String? last_verify_key;
  String? last_id_token;

  @override
  Future<PhoneChallenge> createChallenge({
    required String phone,
    required PhoneVerificationPurpose purpose,
    required String idempotency_key,
  }) async {
    create_count += 1;
    last_phone = phone;
    last_challenge_key = idempotency_key;
    if (create_error != null) throw create_error!;
    if (pending_challenge != null) return pending_challenge!.future;
    return challenge = PhoneChallenge(
      challenge_id: 'challenge-$create_count',
      phone: phone,
      phone_e164: koreanPhoneE164(phone),
      purpose: purpose,
      server_now: DateTime.utc(2000),
      expires_at: DateTime.utc(2000).add(const Duration(minutes: 10)),
    );
  }

  @override
  Future<PhoneVerificationProof> verifyFirebasePhone({
    required String challenge_id,
    required String firebase_id_token,
    required String idempotency_key,
  }) async {
    verify_count += 1;
    last_verify_key = idempotency_key;
    last_id_token = firebase_id_token;
    if (verify_error != null) throw verify_error!;
    if (pending_proof != null) return pending_proof!.future;
    return PhoneVerificationProof(
      token: 'proof-$challenge_id',
      phone: challenge!.phone,
      purpose: challenge!.purpose,
      server_now: DateTime.utc(2000),
      expires_at: DateTime.utc(2000).add(const Duration(minutes: 5)),
    );
  }
}

class FakeFirebasePhoneService implements FirebasePhoneAuthService {
  Object? active_session;
  int start_count = 0;
  int request_count = 0;
  int sign_in_count = 0;
  int close_count = 0;
  int clear_count = 0;
  String? last_e164;
  String? last_code;
  int? last_resend_token;
  bool auto_send = true;
  Object? sign_in_error;
  Object? start_error;
  Completer<void>? pending_start;
  Completer<String>? pending_sign_in;
  void Function(String, int?)? codeSent;
  void Function(PhoneAuthCredential)? automatic;
  void Function()? retrievalTimeout;
  void Function(ApiException)? failure;

  @override
  Future<Object> startSession() async {
    start_count += 1;
    if (start_error != null) throw start_error!;
    if (pending_start != null) await pending_start!.future;
    return active_session = Object();
  }

  @override
  Future<void> requestCode({
    required Object session,
    required String phone_e164,
    int? resend_token,
    required void Function(String, int?) onCodeSent,
    required void Function(PhoneAuthCredential) onAutomatic,
    required void Function() onAutoRetrievalTimeout,
    required void Function(ApiException) onError,
  }) async {
    request_count += 1;
    last_e164 = phone_e164;
    last_resend_token = resend_token;
    codeSent = onCodeSent;
    automatic = onAutomatic;
    retrievalTimeout = onAutoRetrievalTimeout;
    failure = onError;
    if (auto_send) codeSent!('verification-$request_count', 7);
  }

  @override
  Future<String> signIn({
    required Object session,
    PhoneAuthCredential? credential,
    String? verification_id,
    String? code,
  }) async {
    sign_in_count += 1;
    last_code = code;
    if (sign_in_error != null) throw sign_in_error!;
    if (pending_sign_in != null) return pending_sign_in!.future;
    return 'firebase-id-token';
  }

  @override
  Future<void> closeSession(Object session) async {
    if (identical(active_session, session)) {
      close_count += 1;
      active_session = null;
    }
  }

  @override
  Future<void> clearSessions() async {
    clear_count += 1;
    active_session = null;
  }
}

List<Override> phoneAuthOverrides({
  FakePhoneRepository? repository,
  FakeFirebasePhoneService? firebase,
}) => [
  phone_verification_repository_provider.overrideWithValue(
    repository ?? FakePhoneRepository(),
  ),
  firebase_phone_auth_service_provider.overrideWithValue(
    firebase ?? FakeFirebasePhoneService(),
  ),
];
