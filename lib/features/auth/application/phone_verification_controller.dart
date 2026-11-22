// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/api_exception.dart';
import '../data/models/phone_verification_models.dart';
import '../data/repositories/phone_verification_repository.dart';
import '../data/services/firebase_phone_auth_service.dart';
import 'phone_verification_state.dart';

/// 객체 identity로 화면마다 별도 provider 수명을 갖는다.
class PhoneVerificationScope {
  final String user_id;
  final PhoneVerificationPurpose purpose;
  final String initial_phone;
  PhoneVerificationScope(this.user_id, this.purpose, {this.initial_phone = ''});
}

final phone_verification_controller_provider = StateNotifierProvider.autoDispose
    .family<
      PhoneVerificationController,
      PhoneVerificationState,
      PhoneVerificationScope
    >(
      (ref, scope) => PhoneVerificationController(
        ref.watch(phone_verification_repository_provider),
        ref.watch(firebase_phone_auth_service_provider),
        scope.purpose,
        initial_phone: scope.initial_phone,
      ),
    );

class PhoneVerificationController
    extends StateNotifier<PhoneVerificationState> {
  final PhoneVerificationRepository _repository;
  final FirebasePhoneAuthService _firebase;
  final PhoneVerificationPurpose purpose;
  final Duration Function() _elapsed;
  final bool _use_timer;
  final Stopwatch _clock;
  Timer? _ticker;
  Timer? _send_timeout;
  int _generation = 0;
  Object? _session;
  PhoneChallenge? _challenge;
  Duration? _challenge_deadline;
  Duration? _proof_deadline;
  Duration? _resend_deadline;
  String? _verification_id;
  int? _resend_token;
  String? _send_key;
  String? _verify_key;
  String? _firebase_id_token;
  bool _completing = false;

  PhoneVerificationController(
    this._repository,
    this._firebase,
    this.purpose, {
    String initial_phone = '',
    Duration Function()? elapsed,
    bool use_timer = true,
  }) : _clock = Stopwatch()..start(),
       _elapsed = elapsed ?? (() => Duration.zero),
       _use_timer = use_timer,
       super(PhoneVerificationState(phone: initial_phone)) {
    _external_clock = elapsed != null;
  }

  late final bool _external_clock;
  Duration get _now => _external_clock ? _elapsed() : _clock.elapsed;
  bool _current(int generation) => mounted && _generation == generation;
  int _seconds(Duration? deadline) => deadline == null
      ? 0
      : ((deadline - _now).inMilliseconds / 1000).ceil().clamp(0, 86400);

  void setPhone(String phone) {
    if (state.phone == phone) return;
    _reset();
    state = PhoneVerificationState(
      phone: phone,
      resend_seconds: _seconds(_resend_deadline),
    );
  }

  void _closeSession() {
    final session = _session;
    _session = null;
    if (session != null) {
      unawaited(_firebase.closeSession(session).catchError((Object _) {}));
    }
  }

  void _reset() {
    _generation += 1;
    _send_timeout?.cancel();
    _closeSession();
    _challenge = null;
    _challenge_deadline = null;
    _proof_deadline = null;
    _verification_id = null;
    _resend_token = null;
    _send_key = null;
    _verify_key = null;
    _firebase_id_token = null;
    _completing = false;
  }

  void invalidateProof(ApiException error) {
    _reset();
    state = PhoneVerificationState(
      phone: state.phone,
      resend_seconds: _seconds(_resend_deadline),
      error: error,
    );
  }

  String? tokenFor(String phone) {
    refreshTime();
    return state.phone == phone &&
            state.is_verified &&
            state.proof?.purpose == purpose
        ? state.proof!.token
        : null;
  }

  void _startTicker() {
    if (!_use_timer || _ticker != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => refreshTime());
  }

  void refreshTime() {
    if (!mounted) return;
    final resend_seconds = _seconds(_resend_deadline);
    final proof_seconds = _seconds(_proof_deadline);
    if (state.proof != null && proof_seconds == 0) {
      invalidateProof(
        ApiException(
          code: 'PHONE_VERIFICATION_EXPIRED',
          message: '인증 유효시간이 지났어요. 다시 인증해주세요.',
        ),
      );
    } else if (_challenge != null &&
        state.proof == null &&
        _seconds(_challenge_deadline) == 0) {
      invalidateProof(
        ApiException(
          code: 'PHONE_CHALLENGE_EXPIRED',
          message: '인증 시간이 지났어요. 인증번호를 다시 받아주세요.',
        ),
      );
    } else if (state.resend_seconds != resend_seconds ||
        state.proof_seconds != proof_seconds) {
      state = state.copyWith(
        resend_seconds: resend_seconds,
        proof_seconds: proof_seconds,
        error: state.error,
      );
    }
    if (resend_seconds == 0 && _challenge == null && state.proof == null) {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  Future<void> sendCode() async {
    refreshTime();
    if (state.is_busy || state.resend_seconds > 0 || state.is_verified) return;
    final phone = state.phone;
    if (!isKoreanMobilePhone(phone)) {
      state = state.copyWith(
        error: ApiException(
          code: 'INVALID_PHONE',
          message: '한국 휴대폰 번호 형식을 확인해주세요.',
        ),
      );
      return;
    }
    final previous_resend_token = _resend_token;
    _generation += 1;
    final generation = _generation;
    _closeSession();
    _verification_id = null;
    _firebase_id_token = null;
    _verify_key = null;
    _challenge = null;
    _challenge_deadline = null;
    _proof_deadline = null;
    _completing = false;
    state = PhoneVerificationState(
      phone: phone,
      stage: PhoneVerificationStage.checking,
    );
    final request_started = _now;
    _send_key ??= const Uuid().v4();
    try {
      final challenge = await _repository.createChallenge(
        phone: phone,
        purpose: purpose,
        idempotency_key: _send_key!,
      );
      if (!_current(generation)) return;
      if (challenge.phone != phone ||
          challenge.purpose != purpose ||
          challenge.phone_e164 != koreanPhoneE164(phone)) {
        throw ApiException(
          code: 'PHONE_VERIFICATION_INVALID_RESPONSE',
          message: '인증 대상 번호를 확인하지 못했어요.',
        );
      }
      _challenge = challenge;
      _challenge_deadline =
          request_started +
          challenge.expires_at.difference(challenge.server_now);
      if (_seconds(_challenge_deadline) == 0) {
        throw ApiException(
          code: 'PHONE_CHALLENGE_EXPIRED',
          message: '인증번호를 다시 받아주세요.',
        );
      }
      _send_key = null;
      state = state.copyWith(stage: PhoneVerificationStage.sending);
      _send_timeout?.cancel();
      _send_timeout = Timer(const Duration(seconds: 90), () {
        if (_current(generation) &&
            state.stage == PhoneVerificationStage.sending) {
          _sendFailed(
            generation,
            ApiException(
              code: 'PHONE_AUTH_TIMEOUT',
              message: '인증번호 요청을 확인하지 못했어요. 다시 시도해주세요.',
            ),
          );
        }
      });
      final session = await _firebase.startSession();
      if (!_current(generation)) {
        await _firebase.closeSession(session);
        return;
      }
      _session = session;
      _resend_deadline = _now + const Duration(seconds: 60);
      _startTicker();
      state = state.copyWith(resend_seconds: 60);
      await _firebase.requestCode(
        session: session,
        phone_e164: challenge.phone_e164,
        resend_token: previous_resend_token,
        onCodeSent: (verification_id, resend_token) {
          if (!_current(generation) || _completing || state.is_verified) return;
          _send_timeout?.cancel();
          _verification_id = verification_id;
          _resend_token = resend_token;
          state = state.copyWith(stage: PhoneVerificationStage.code_sent);
        },
        onAutomatic: (credential) {
          if (_current(generation)) {
            unawaited(_complete(generation, credential: credential));
          }
        },
        onAutoRetrievalTimeout: () {
          if (_current(generation) && !state.is_verified) {
            state = state.copyWith(
              auto_retrieval_finished: true,
              error: state.error,
            );
          }
        },
        onError: (error) => _sendFailed(generation, error),
      );
    } catch (error) {
      _sendFailed(generation, phoneAuthError(error));
    }
  }

  void _sendFailed(int generation, ApiException error) {
    if (!_current(generation) || state.is_verified || _completing) return;
    _generation += 1;
    _send_timeout?.cancel();
    _closeSession();
    _challenge = null;
    _challenge_deadline = null;
    final status = error.statusCode;
    // 응답 유실/일시 장애는 기존 요청을 복구하지만, 종료된 세션이나
    // 잘못된 응답의 키는 다음 수동 시도에서 새 challenge를 만들도록 폐기한다.
    if (error.code == 'PHONE_CHALLENGE_EXPIRED' ||
        error.code == 'PHONE_VERIFICATION_INVALID_RESPONSE' ||
        (status != null &&
            status >= 400 &&
            status < 500 &&
            status != 408 &&
            status != 425 &&
            status != 429)) {
      _send_key = null;
    }
    final retry = error.retry_after_seconds;
    if (retry != null) {
      _resend_deadline = _now + Duration(seconds: retry);
      _startTicker();
    }
    state = state.copyWith(
      stage: PhoneVerificationStage.idle,
      resend_seconds: _seconds(_resend_deadline),
      error: error,
    );
  }

  Future<void> verifyCode(String code) async {
    refreshTime();
    if (state.stage != PhoneVerificationStage.code_sent || _completing) return;
    if (_firebase_id_token == null && !RegExp(r'^[0-9]{6}$').hasMatch(code)) {
      state = state.copyWith(
        error: ApiException(
          code: 'INVALID_PHONE_CODE',
          message: '인증번호 6자리를 입력해주세요.',
        ),
      );
      return;
    }
    await _complete(_generation, code: code);
  }

  Future<void> _complete(
    int generation, {
    PhoneAuthCredential? credential,
    String? code,
  }) async {
    if (!_current(generation) ||
        _completing ||
        state.is_verified ||
        _session == null ||
        _challenge == null) {
      return;
    }
    _completing = true;
    _send_timeout?.cancel();
    state = state.copyWith(stage: PhoneVerificationStage.verifying);
    try {
      _firebase_id_token ??= await _firebase.signIn(
        session: _session!,
        credential: credential,
        verification_id: _verification_id,
        code: code,
      );
      if (!_current(generation)) return;
      _verify_key ??= const Uuid().v4();
      final request_started = _now;
      final proof = await _repository.verifyFirebasePhone(
        challenge_id: _challenge!.challenge_id,
        firebase_id_token: _firebase_id_token!,
        idempotency_key: _verify_key!,
      );
      if (!_current(generation)) return;
      if (proof.phone != state.phone || proof.purpose != purpose) {
        throw ApiException(
          code: 'PHONE_VERIFICATION_INVALID_RESPONSE',
          message: '인증 결과의 번호를 확인하지 못했어요.',
        );
      }
      _proof_deadline =
          request_started + proof.expires_at.difference(proof.server_now);
      if (_seconds(_proof_deadline) == 0) {
        throw ApiException(
          code: 'PHONE_VERIFICATION_EXPIRED',
          message: '인증 유효시간이 지났어요. 다시 인증해주세요.',
        );
      }
      _challenge = null;
      _firebase_id_token = null;
      _verification_id = null;
      state = state.copyWith(
        stage: PhoneVerificationStage.verified,
        proof: proof,
        proof_seconds: _seconds(_proof_deadline),
      );
      _closeSession();
    } catch (error) {
      if (!_current(generation)) return;
      final failure = phoneAuthError(error);
      final retryable =
          failure.statusCode == null || (failure.statusCode ?? 0) >= 500;
      if ((_firebase_id_token != null && !retryable) ||
          failure.code == 'PHONE_AUTH_session-expired' ||
          failure.code == 'PHONE_AUTH_invalid-verification-id' ||
          failure.code == 'PHONE_VERIFICATION_EXPIRED' ||
          failure.code == 'PHONE_VERIFICATION_INVALID_RESPONSE') {
        invalidateProof(failure);
      } else {
        state = state.copyWith(
          stage: PhoneVerificationStage.code_sent,
          error: failure,
          awaiting_server: _firebase_id_token != null,
        );
      }
    } finally {
      if (_current(generation)) _completing = false;
    }
  }

  @override
  void dispose() {
    _reset();
    _ticker?.cancel();
    _clock.stop();
    super.dispose();
  }
}
