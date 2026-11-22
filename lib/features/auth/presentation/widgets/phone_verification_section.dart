// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/privacy_policy.dart';
import '../../application/phone_verification_state.dart';
import '../../data/models/phone_verification_models.dart';

class PhoneVerificationSection extends StatefulWidget {
  final Widget phone_input;
  final FocusNode code_focus;
  final PhoneVerificationState state;
  final bool required_verification;
  final bool enabled;
  final VoidCallback onEditPhone;
  final VoidCallback onSend;
  final ValueChanged<String> onVerify;

  const PhoneVerificationSection({
    super.key,
    required this.phone_input,
    required this.code_focus,
    required this.state,
    required this.required_verification,
    required this.enabled,
    required this.onEditPhone,
    required this.onSend,
    required this.onVerify,
  });

  @override
  State<PhoneVerificationSection> createState() =>
      _PhoneVerificationSectionState();
}

class _PhoneVerificationSectionState extends State<PhoneVerificationSection> {
  final _code_controller = TextEditingController();
  FocusNode get _code_focus => widget.code_focus;
  bool _editing_phone = false;
  bool _code_step = false;

  @override
  void initState() {
    super.initState();
    _code_step = _showsCode(widget.state);
  }

  bool _showsCode(PhoneVerificationState state) =>
      state.stage == PhoneVerificationStage.sending ||
      state.stage == PhoneVerificationStage.code_sent ||
      state.stage == PhoneVerificationStage.verifying;

  void _focusCode() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          !_code_step ||
          _editing_phone ||
          widget.state.is_verified) {
        return;
      }
      _code_focus.requestFocus();
      final field_context = _code_focus.context;
      if (field_context != null) {
        Scrollable.ensureVisible(field_context, alignment: 0.3);
      }
    });
  }

  @override
  void didUpdateWidget(covariant PhoneVerificationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state.phone != widget.state.phone) {
      _code_controller.clear();
      _editing_phone = false;
      _code_step = false;
    }
    if (oldWidget.state.stage != widget.state.stage) {
      if (widget.state.stage == PhoneVerificationStage.checking) {
        _code_controller.clear();
      } else if (_showsCode(widget.state)) {
        _code_step = true;
        if (!_showsCode(oldWidget.state)) {
          _editing_phone = false;
          _focusCode();
        }
      } else {
        _code_step = false;
        _code_focus.unfocus();
      }
    }
  }

  @override
  void dispose() {
    _code_controller.dispose();
    super.dispose();
  }

  Widget _message(String message, {bool error = false}) => Semantics(
    liveRegion: true,
    child: Text(
      message,
      style: AppTheme.body_medium.copyWith(
        color: error
            ? AppTheme.error_text_color
            : AppTheme.on_surface_variant_color,
      ),
    ),
  );

  void _showNotice() {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialog_context) => CupertinoAlertDialog(
        title: const Text('휴대폰 인증 안내'),
        content: const Text(
          '휴대폰 인증에 Firebase Authentication을 사용해요. '
          '전화번호는 Google에 전송·저장되며, Firebase를 포함한 '
          'Google 서비스의 스팸·악용 방지 개선에도 사용됩니다.',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => openPrivacyPolicy(dialog_context),
            child: const Text('개인정보처리방침'),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.of(dialog_context).pop(),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
  }

  void _sendCode() {
    setState(() => _code_controller.clear());
    widget.onSend();
  }

  Widget _sendButton({required bool can_send, required bool show_code}) {
    final state = widget.state;
    return CupertinoButton(
      key: const Key('phone_send_button'),
      minimumSize: const Size(44, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: show_code ? null : AppTheme.surface_container_low_color,
      disabledColor: AppTheme.surface_container_low_color,
      borderRadius: AppTheme.input_border_radius,
      onPressed: can_send ? _sendCode : null,
      child:
          state.stage == PhoneVerificationStage.checking ||
              state.stage == PhoneVerificationStage.sending
          ? Semantics(
              liveRegion: true,
              child: Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  const ExcludeSemantics(
                    child: CupertinoActivityIndicator(radius: 8),
                  ),
                  Text(
                    state.stage == PhoneVerificationStage.checking
                        ? '번호 확인 중'
                        : '인증번호 전송 중',
                    style: AppTheme.body_medium.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                ],
              ),
            )
          : Text(
              state.resend_seconds > 0
                  ? '${state.resend_seconds}초 후 다시 받기'
                  : show_code
                  ? '인증번호 다시 받기'
                  : '인증번호 받기',
              textAlign: TextAlign.center,
              style: AppTheme.body_medium.copyWith(
                color: can_send
                    ? AppTheme.primary_dark_color
                    : AppTheme.on_surface_variant_color,
              ),
            ),
    );
  }

  Widget _codeInput() {
    final state = widget.state;
    final can_verify =
        widget.enabled &&
        state.stage == PhoneVerificationStage.code_sent &&
        (state.awaiting_server || _code_controller.text.length == 6);
    final code_field = Semantics(
      label: '인증번호 6자리',
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: CupertinoTextField(
          key: const Key('phone_code_field'),
          controller: _code_controller,
          focusNode: _code_focus,
          enabled:
              widget.enabled &&
              (state.stage == PhoneVerificationStage.sending ||
                  state.stage == PhoneVerificationStage.code_sent) &&
              !state.awaiting_server,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          textInputAction: TextInputAction.done,
          placeholder: '6자리 숫자',
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.background_color,
            borderRadius: AppTheme.input_border_radius,
            border: Border.all(color: AppTheme.outline_variant_color),
          ),
          style: AppTheme.body_large,
          onChanged: (_) => setState(() {}),
          onSubmitted: can_verify ? widget.onVerify : null,
        ),
      ),
    );
    final verify_button = CupertinoButton(
      key: const Key('phone_verify_button'),
      minimumSize: const Size(44, 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      borderRadius: AppTheme.input_border_radius,
      color: AppTheme.primary_color,
      disabledColor: state.stage == PhoneVerificationStage.verifying
          ? AppTheme.primary_color
          : AppTheme.surface_container_highest_color,
      onPressed: can_verify
          ? () => widget.onVerify(_code_controller.text)
          : null,
      child: state.stage == PhoneVerificationStage.verifying
          ? Semantics(
              label: '인증 확인 중',
              child: const CupertinoActivityIndicator(
                color: AppTheme.surface_color,
              ),
            )
          : Text(
              state.awaiting_server ? '인증 결과 다시 확인' : '인증하기',
              textAlign: TextAlign.center,
              style: AppTheme.body_medium.copyWith(
                color: can_verify
                    ? AppTheme.surface_color
                    : AppTheme.on_surface_variant_color,
              ),
            ),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 280 ||
            MediaQuery.textScalerOf(context).scale(14) > 18 ||
            state.awaiting_server) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [code_field, const SizedBox(height: 8), verify_button],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: code_field),
            const SizedBox(width: 8),
            verify_button,
          ],
        );
      },
    );
  }

  Widget _phoneDestination() {
    final state = widget.state;
    return Container(
      key: const Key('phone_destination_summary'),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.surface_container_low_color,
        borderRadius: AppTheme.input_border_radius,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final large_text = MediaQuery.textScalerOf(context).scale(14) > 18;
          final formatted_phone = _formattedPhone();
          final parts = formatted_phone.split('-');
          final Widget phone_value = large_text && parts.length == 3
              ? Semantics(
                  label: formatted_phone,
                  child: ExcludeSemantics(
                    child: Wrap(
                      key: const Key('phone_destination_number'),
                      children: [
                        for (var index = 0; index < parts.length; index += 1)
                          Text(
                            index < parts.length - 1
                                ? '${parts[index]}-'
                                : parts[index],
                            style: AppTheme.body_medium,
                          ),
                      ],
                    ),
                  ),
                )
              : Text(
                  formatted_phone,
                  key: const Key('phone_destination_number'),
                  style: AppTheme.body_medium,
                );
          final destination = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '수신 번호',
                style: AppTheme.body_medium.copyWith(
                  fontSize: 12,
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
              phone_value,
            ],
          );
          final change_button = CupertinoButton(
            key: const Key('phone_change_button'),
            minimumSize: const Size(44, 44),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed:
                widget.enabled &&
                    state.stage != PhoneVerificationStage.checking &&
                    state.stage != PhoneVerificationStage.verifying
                ? () {
                    setState(() => _editing_phone = true);
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) widget.onEditPhone();
                    });
                  }
                : null,
            child: Text(
              '번호 변경',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.primary_dark_color,
              ),
            ),
          );
          if (large_text) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                destination,
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: change_button,
                ),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: destination),
              const SizedBox(width: 8),
              change_button,
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final show_code = _code_step && !_editing_phone;
    final can_send =
        widget.enabled &&
        !state.is_busy &&
        !state.awaiting_server &&
        isKoreanMobilePhone(state.phone) &&
        state.resend_seconds == 0;
    return Column(
      key: const Key('phone_verification_section'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!show_code) widget.phone_input,
        if (widget.required_verification && state.is_verified) ...[
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                const ExcludeSemantics(
                  child: Icon(
                    CupertinoIcons.checkmark_circle_fill,
                    color: AppTheme.primary_dark_color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '휴대폰 인증 완료',
                    key: const Key('phone_verification_success'),
                    style: AppTheme.body_medium.copyWith(
                      color: AppTheme.primary_dark_color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ] else if (widget.required_verification && show_code) ...[
          ExcludeSemantics(
            child: Text.rich(
              key: const Key('phone_code_label'),
              const TextSpan(
                text: '인증번호',
                children: [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.error_text_color),
                  ),
                ],
              ),
              style: AppTheme.body_medium.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          _codeInput(),
          const SizedBox(height: 8),
          _phoneDestination(),
          _sendButton(can_send: can_send, show_code: true),
        ] else if (widget.required_verification) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '번호가 Google에 전송·저장돼요.',
                  style: AppTheme.body_medium.copyWith(
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ),
              CupertinoButton(
                key: const Key('phone_notice_button'),
                minimumSize: const Size(44, 44),
                padding: const EdgeInsets.only(left: 8),
                onPressed: _showNotice,
                child: Text(
                  '자세히',
                  style: AppTheme.body_medium.copyWith(
                    color: AppTheme.primary_dark_color,
                  ),
                ),
              ),
            ],
          ),
          if (_editing_phone && _showsCode(state))
            CupertinoButton(
              key: const Key('phone_resume_code_button'),
              minimumSize: const Size(44, 48),
              padding: const EdgeInsets.all(12),
              onPressed:
                  widget.enabled &&
                      state.stage != PhoneVerificationStage.verifying
                  ? () {
                      setState(() => _editing_phone = false);
                      _focusCode();
                    }
                  : null,
              child: Text('인증번호 입력으로 돌아가기', style: AppTheme.body_medium),
            )
          else
            _sendButton(can_send: can_send, show_code: false),
        ],
        if (widget.required_verification && state.error != null) ...[
          const SizedBox(height: 8),
          _message(state.error!.message, error: true),
        ],
      ],
    );
  }

  String _formattedPhone() {
    final phone = widget.state.phone;
    if (phone.length == 10 || phone.length == 11) {
      final split = phone.length - 4;
      return '${phone.substring(0, 3)}-${phone.substring(3, split)}-'
          '${phone.substring(split)}';
    }
    return phone;
  }
}
