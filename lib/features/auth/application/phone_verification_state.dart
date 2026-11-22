// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import '../data/models/phone_verification_models.dart';
import '../../../core/network/api_exception.dart';

enum PhoneVerificationStage {
  idle,
  checking,
  sending,
  code_sent,
  verifying,
  verified,
}

class PhoneVerificationState {
  final String phone;
  final PhoneVerificationStage stage;
  final int resend_seconds;
  final int proof_seconds;
  final bool auto_retrieval_finished;
  final bool awaiting_server;
  final ApiException? error;
  final PhoneVerificationProof? proof;

  const PhoneVerificationState({
    this.phone = '',
    this.stage = PhoneVerificationStage.idle,
    this.resend_seconds = 0,
    this.proof_seconds = 0,
    this.auto_retrieval_finished = false,
    this.awaiting_server = false,
    this.error,
    this.proof,
  });

  bool get is_busy =>
      stage == PhoneVerificationStage.checking ||
      stage == PhoneVerificationStage.sending ||
      stage == PhoneVerificationStage.verifying;
  bool get is_verified =>
      stage == PhoneVerificationStage.verified &&
      proof != null &&
      proof_seconds > 0;

  PhoneVerificationState copyWith({
    PhoneVerificationStage? stage,
    int? resend_seconds,
    int? proof_seconds,
    bool? auto_retrieval_finished,
    bool? awaiting_server,
    ApiException? error,
    PhoneVerificationProof? proof,
    bool clear_proof = false,
  }) => PhoneVerificationState(
    phone: phone,
    stage: stage ?? this.stage,
    resend_seconds: resend_seconds ?? this.resend_seconds,
    proof_seconds: proof_seconds ?? this.proof_seconds,
    auto_retrieval_finished:
        auto_retrieval_finished ?? this.auto_retrieval_finished,
    awaiting_server: awaiting_server ?? this.awaiting_server,
    error: error,
    proof: clear_proof ? null : proof ?? this.proof,
  );
}
