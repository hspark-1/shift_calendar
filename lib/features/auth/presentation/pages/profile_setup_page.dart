// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/profile_image.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/profile_image_upload.dart';
import '../providers/auth_provider.dart';
import '../../application/phone_verification_controller.dart';
import '../../application/phone_verification_state.dart';
import '../../data/models/phone_verification_models.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/network/api_exception.dart';
import '../widgets/phone_verification_section.dart';

const Map<String, String> _legacy_job_type_labels = {
  'NURSE': '간호사',
  'DOCTOR': '의사',
  'EMT': '응급구조사',
  'OTHER': '기타',
};

class KoreanMobilePhoneInputFormatter extends TextInputFormatter {
  static String format(String value) {
    final all_digits = value.replaceAll(RegExp('[^0-9]'), '');
    final digits = all_digits.length > 11
        ? all_digits.substring(0, 11)
        : all_digits;

    if (digits.length <= 3) return digits;
    if (digits.length <= 7) {
      return '${digits.substring(0, 3)}-${digits.substring(3)}';
    }
    if (digits.length <= 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-'
          '${digits.substring(6)}';
    }
    return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-'
        '${digits.substring(7)}';
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue old_value,
    TextEditingValue new_value,
  ) {
    final formatted_text = format(new_value.text);
    final base_offset = _formattedOffset(
      formatted_text,
      _digitCountBefore(new_value.text, new_value.selection.baseOffset),
    );
    final extent_offset = _formattedOffset(
      formatted_text,
      _digitCountBefore(new_value.text, new_value.selection.extentOffset),
    );

    return TextEditingValue(
      text: formatted_text,
      selection: TextSelection(
        baseOffset: base_offset,
        extentOffset: extent_offset,
      ),
    );
  }

  int _digitCountBefore(String value, int offset) {
    if (offset < 0) return value.replaceAll(RegExp('[^0-9]'), '').length;
    final safe_offset = offset.clamp(0, value.length);
    return value
        .substring(0, safe_offset)
        .replaceAll(RegExp('[^0-9]'), '')
        .length;
  }

  int _formattedOffset(String value, int digit_count) {
    if (digit_count <= 0) return 0;
    var seen_digits = 0;
    for (var index = 0; index < value.length; index += 1) {
      if (_isDigit(value.codeUnitAt(index))) seen_digits += 1;
      if (seen_digits == digit_count) {
        var offset = index + 1;
        while (offset < value.length && !_isDigit(value.codeUnitAt(offset))) {
          offset += 1;
        }
        return offset;
      }
    }
    return value.length;
  }

  bool _isDigit(int code_unit) => code_unit >= 48 && code_unit <= 57;
}

class ProfileSetupPage extends ConsumerStatefulWidget {
  final User user;
  final bool is_editing;
  final VoidCallback? on_completed;
  final Future<ProfileImageUpload?> Function()? profile_image_picker;
  final Future<String> Function()? timezone_loader;

  const ProfileSetupPage({
    super.key,
    required this.user,
    this.on_completed,
    this.profile_image_picker,
    this.timezone_loader,
  }) : is_editing = false;

  const ProfileSetupPage.edit({
    super.key,
    required this.user,
    this.on_completed,
    this.profile_image_picker,
  }) : is_editing = true,
       timezone_loader = null;

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  late final TextEditingController _name_controller;
  late final TextEditingController _phone_controller;
  late final TextEditingController _job_type_controller;
  late final TextEditingController _workplace_controller;
  late String _initial_job_type_text;
  late User _initial_user;
  late final PhoneVerificationScope _phone_scope;
  bool _profile_loaded = false;
  bool _profile_fetching = false;
  String? _profile_load_error;
  String? _submission_key;
  bool _initializing = true;
  late String _selected_timezone;
  late final Future<void> _timezone_future;
  ProfileImageUpload? _selected_profile_image;
  bool _has_submitted = false;
  bool _is_loading = false;
  bool _is_picking_image = false;
  final FocusNode _name_focus = FocusNode();
  final FocusNode _phone_focus = FocusNode();
  final FocusNode _phone_code_focus = FocusNode();
  final FocusNode _job_focus = FocusNode();
  final FocusNode _workplace_focus = FocusNode();
  final GlobalKey _name_field_key = GlobalKey();
  final GlobalKey _phone_field_key = GlobalKey();
  final GlobalKey _save_error_key = GlobalKey();
  final ScrollController _profile_scroll = ScrollController();
  bool _name_blurred = false;
  bool _phone_blurred = false;
  String? _save_error;

  bool get _is_busy => _is_loading || _is_picking_image;

  @override
  void initState() {
    super.initState();
    _initial_user = widget.user;
    _phone_scope = PhoneVerificationScope(
      widget.user.id,
      widget.is_editing
          ? PhoneVerificationPurpose.phone_change
          : PhoneVerificationPurpose.signup,
      initial_phone: phoneDigits(widget.user.phone ?? ''),
    );
    _profile_loaded = !widget.is_editing;
    _name_controller = TextEditingController(text: _initial_user.name);
    _phone_controller = TextEditingController(
      text: KoreanMobilePhoneInputFormatter.format(_initial_user.phone ?? ''),
    );
    _initial_job_type_text =
        _legacy_job_type_labels[_initial_user.job_type] ??
        _initial_user.job_type ??
        '';
    _job_type_controller = TextEditingController(text: _initial_job_type_text);
    _workplace_controller = TextEditingController(
      text: _initial_user.workplace ?? '',
    );
    _selected_timezone =
        _initial_user.timezone ?? AppConstants.default_timezone;
    _timezone_future = widget.is_editing
        ? Future<void>.value()
        : _loadDeviceTimezone();
    for (final controller in [
      _name_controller,
      _phone_controller,
      _job_type_controller,
      _workplace_controller,
    ]) {
      controller.addListener(_onProfileChanged);
    }
    _name_focus.addListener(_onNameFocusChanged);
    _phone_focus.addListener(_onPhoneFocusChanged);
    _job_focus.addListener(_onProfileFocusChanged);
    _workplace_focus.addListener(_onProfileFocusChanged);
    _initializing = false;
    if (widget.is_editing) Future<void>.microtask(_loadProfile);
  }

  Future<void> _loadProfile() async {
    if (_profile_fetching) return;
    setState(() {
      _profile_fetching = true;
      _profile_load_error = null;
    });
    try {
      final user = await ref.read(authRepositoryProvider).getProfile();
      if (!mounted) return;
      if (user.id != widget.user.id) {
        throw const FormatException('Profile owner mismatch');
      }
      _initializing = true;
      _initial_user = user;
      _name_controller.text = user.name;
      _phone_controller.text = KoreanMobilePhoneInputFormatter.format(
        user.phone ?? '',
      );
      _initial_job_type_text =
          _legacy_job_type_labels[user.job_type] ?? user.job_type ?? '';
      _job_type_controller.text = _initial_job_type_text;
      _workplace_controller.text = user.workplace ?? '';
      _selected_timezone = user.timezone ?? AppConstants.default_timezone;
      ref
          .read(phone_verification_controller_provider(_phone_scope).notifier)
          .setPhone(_phone_digits);
      setState(() {
        _profile_loaded = true;
        _initializing = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _profile_load_error = error is ApiException
              ? error.message
              : '개인정보를 불러오지 못했어요. 다시 시도해주세요.';
        });
      }
    } finally {
      if (mounted) setState(() => _profile_fetching = false);
    }
  }

  bool get _requires_phone_verification =>
      !widget.is_editing || _has_phone_changed;

  bool get _can_save {
    final phone_state = ref.read(
      phone_verification_controller_provider(_phone_scope),
    );
    return _profile_loaded &&
        !_is_busy &&
        !phone_state.is_busy &&
        _is_required_input_valid &&
        (!widget.is_editing || _has_changes) &&
        (!_requires_phone_verification ||
            (phone_state.is_verified && phone_state.phone == _phone_digits));
  }

  @override
  void dispose() {
    _name_controller.dispose();
    _phone_controller.dispose();
    _job_type_controller.dispose();
    _workplace_controller.dispose();
    _name_focus.dispose();
    _phone_focus.dispose();
    _phone_code_focus.dispose();
    _job_focus.dispose();
    _workplace_focus.dispose();
    _profile_scroll.dispose();
    super.dispose();
  }

  void _onProfileChanged() {
    if (_initializing) return;
    _submission_key = null;
    ref
        .read(phone_verification_controller_provider(_phone_scope).notifier)
        .setPhone(_phone_digits);
    setState(() => _save_error = null);
  }

  void _onNameFocusChanged() {
    setState(() {
      if (!_name_focus.hasFocus) _name_blurred = true;
    });
  }

  void _onPhoneFocusChanged() {
    setState(() {
      if (!_phone_focus.hasFocus) _phone_blurred = true;
    });
  }

  void _onProfileFocusChanged() {
    setState(() {});
  }

  bool get _has_changes =>
      _name_controller.text.trim() != _initial_user.name ||
      _has_phone_changed ||
      _job_type_controller.text.trim() != _initial_job_type_text ||
      _workplace_controller.text.trim() != (_initial_user.workplace ?? '') ||
      _selected_profile_image != null;

  String get _phone_digits =>
      _phone_controller.text.replaceAll(RegExp('[^0-9]'), '');

  String? get _name_error {
    if (!_has_submitted && !_name_blurred) return null;
    final name = _name_controller.text.trim();
    if (name.isEmpty) return '이름을 입력해주세요.';
    if (name.length > 50) return '이름은 50자 이하로 입력해주세요.';
    return null;
  }

  String? get _phone_error {
    if (!_has_submitted && !_phone_blurred) return null;
    if (widget.is_editing && !_has_phone_changed) return null;
    if (_phone_digits.isEmpty) return '휴대폰 번호를 입력해주세요.';
    if (!_is_valid_korean_mobile_phone) {
      return '한국 휴대폰 번호 형식을 확인해주세요.';
    }
    return null;
  }

  bool get _is_valid_korean_mobile_phone =>
      RegExp(r'^(?:010[0-9]{8}|01[16789][0-9]{7,8})$').hasMatch(_phone_digits);

  bool get _has_phone_changed =>
      _phone_digits !=
      (_initial_user.phone ?? '').replaceAll(RegExp('[^0-9]'), '');

  bool get _is_required_input_valid =>
      _name_controller.text.trim().isNotEmpty &&
      _name_controller.text.trim().length <= 50 &&
      ((widget.is_editing && !_has_phone_changed) ||
          _is_valid_korean_mobile_phone);

  void _focusFirstError() {
    final focus = _name_error != null ? _name_focus : _phone_focus;
    final field_key = _name_error != null ? _name_field_key : _phone_field_key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focus.requestFocus();
      final field_context = field_key.currentContext;
      if (field_context != null) {
        Scrollable.ensureVisible(
          field_context,
          alignment: 0.15,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 200),
        );
      }
    });
  }

  void _requestLeave() {
    if (_is_busy) return;
    Navigator.of(context).maybePop();
  }

  Future<void> _loadDeviceTimezone() async {
    try {
      final timezone = widget.timezone_loader != null
          ? await widget.timezone_loader!()
          : (await FlutterTimezone.getLocalTimezone()).identifier;
      if (timezone.trim().isNotEmpty) _selected_timezone = timezone;
    } catch (_) {
      // 네이티브 조회 실패 시 서버 값 또는 앱 기본값을 유지한다.
    }
  }

  Future<void> _pickProfileImage() async {
    if (_is_busy) return;
    setState(() => _is_picking_image = true);
    try {
      final selected_image = widget.profile_image_picker != null
          ? await widget.profile_image_picker!()
          : await _pickProfileImageFromGallery();
      if (!mounted || selected_image == null) return;
      if (selected_image.bytes.lengthInBytes > 5 * 1024 * 1024) {
        _showErrorDialog('프로필 이미지는 5MB 이하만 선택할 수 있어요.');
        return;
      }
      setState(() {
        _selected_profile_image = selected_image;
        _submission_key = null;
        _save_error = null;
      });
    } catch (_) {
      if (mounted) _showErrorDialog('사진을 불러오지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _is_picking_image = false);
    }
  }

  Future<ProfileImageUpload?> _pickProfileImageFromGallery() async {
    final selected_file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (selected_file == null) return null;
    return ProfileImageUpload(
      bytes: await selected_file.readAsBytes(),
      filename: selected_file.name,
      content_type: selected_file.mimeType,
    );
  }

  Future<void> _handleSave() async {
    if (_is_busy || !_profile_loaded) return;
    final phone_controller = ref.read(
      phone_verification_controller_provider(_phone_scope).notifier,
    );
    final verification_token = _requires_phone_verification
        ? phone_controller.tokenFor(_phone_digits)
        : null;
    if (_requires_phone_verification && verification_token == null) return;
    if (widget.is_editing && !_has_changes) return;
    setState(() => _has_submitted = true);
    if (!_is_required_input_valid) {
      if (widget.is_editing) _focusFirstError();
      return;
    }

    setState(() {
      _is_loading = true;
      _save_error = null;
    });
    FocusManager.instance.primaryFocus?.unfocus();
    await _timezone_future;
    if (!mounted) return;

    final job_type = _job_type_controller.text.trim();
    final workplace = _workplace_controller.text.trim();
    _submission_key ??= const Uuid().v4();
    final notifier = ref.read(authProvider.notifier);
    final bool success;
    if (widget.is_editing) {
      final name = _name_controller.text.trim();
      final changed_name = name != _initial_user.name ? name : null;
      final changed_phone = _has_phone_changed ? _phone_digits : null;
      final changed_job_type = job_type != _initial_job_type_text
          ? job_type
          : null;
      final changed_workplace = workplace != (_initial_user.workplace ?? '')
          ? workplace
          : null;
      final has_changes =
          changed_name != null ||
          changed_phone != null ||
          changed_job_type != null ||
          changed_workplace != null ||
          _selected_profile_image != null;
      success =
          !has_changes ||
          await notifier.updateProfile(
            name: changed_name,
            phone: changed_phone,
            phone_verification_token: verification_token,
            idempotency_key: _submission_key,
            job_type: changed_job_type,
            workplace: changed_workplace,
            profile_image: _selected_profile_image,
          );
    } else {
      success = await notifier.completeProfileSetup(
        name: _name_controller.text.trim(),
        timezone: _selected_timezone,
        phone: _phone_digits,
        phone_verification_token: verification_token!,
        idempotency_key: _submission_key!,
        profile_image: _selected_profile_image,
        job_type: job_type.isEmpty ? null : job_type,
        workplace: workplace.isEmpty ? null : workplace,
      );
    }

    if (!mounted) return;
    setState(() {
      _is_loading = false;
    });
    if (!success) {
      final error_state = ref.read(authProvider);
      final error = error_state.error;
      final api_error = error_state.api_error;
      if (api_error != null &&
          (api_error.code.startsWith('PHONE_VERIFICATION_') ||
              api_error.code.startsWith('PHONE_FIREBASE_') ||
              api_error.code == 'PHONE_CHALLENGE_EXPIRED' ||
              api_error.code == 'PHONE_ALREADY_EXISTS')) {
        phone_controller.invalidateProof(api_error);
      }
      if (widget.is_editing) {
        setState(() => _save_error = error ?? '저장하지 못했어요. 다시 시도해주세요.');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final error_context = _save_error_key.currentContext;
          if (error_context != null) {
            Scrollable.ensureVisible(
              error_context,
              alignment: 1,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
            );
          }
        });
      } else if (error != null) {
        _showErrorDialog(error);
      }
      return;
    }

    if (widget.on_completed != null) {
      widget.on_completed!();
      return;
    }
    if (widget.is_editing) {
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop();
      return;
    }
    // 가입 완료 화면 전환은 AuthWrapper가 인증 상태로 결정한다.
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('저장하지 못했어요'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone_state = ref.watch(
      phone_verification_controller_provider(_phone_scope),
    );
    ref.listen<PhoneVerificationState>(
      phone_verification_controller_provider(_phone_scope),
      (previous, next) {
        if (previous?.proof != next.proof) _submission_key = null;
      },
    );
    return PopScope<void>(
      canPop: !_is_busy,
      child: CupertinoPageScaffold(
        backgroundColor: AppTheme.surface_color,
        navigationBar: CupertinoNavigationBar(
          backgroundColor: AppTheme.surface_color,
          border: null,
          automaticallyImplyLeading: !widget.is_editing && !_is_busy,
          leading: widget.is_editing
              ? CupertinoButton(
                  key: const Key('profile_edit_back_button'),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(44, 44),
                  onPressed: _is_busy ? null : _requestLeave,
                  child: Semantics(
                    label: '뒤로가기',
                    child: const Icon(
                      CupertinoIcons.chevron_back,
                      size: 26,
                      color: AppTheme.primary_dark_color,
                    ),
                  ),
                )
              : null,
          middle: Text(
            widget.is_editing ? '프로필 수정' : '회원가입',
            style: const TextStyle(fontSize: 18),
          ),
        ),
        child: SafeArea(
          child: !_profile_loaded
              ? Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_profile_fetching || _profile_load_error == null)
                          const CupertinoActivityIndicator()
                        else ...[
                          Text(_profile_load_error ?? '개인정보를 불러오는 중이에요.'),
                          const SizedBox(height: 12),
                          CupertinoButton(
                            key: const Key('profile_load_retry'),
                            onPressed: _loadProfile,
                            child: const Text('다시 불러오기'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final gutter = constraints.maxWidth < 360 ? 20.0 : 24.0;
                    final compact_action =
                        constraints.maxHeight < 360 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20;
                    return Align(
                      alignment: Alignment.topCenter,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 480),
                        child: GestureDetector(
                          key: const Key('profile_setup_keyboard_dismiss_area'),
                          behavior: HitTestBehavior.translucent,
                          onTap: () =>
                              FocusManager.instance.primaryFocus?.unfocus(),
                          child: Column(
                            children: [
                              Expanded(
                                child: SingleChildScrollView(
                                  key: const Key('profile_setup_scroll_view'),
                                  controller: _profile_scroll,
                                  keyboardDismissBehavior:
                                      ScrollViewKeyboardDismissBehavior.onDrag,
                                  padding: EdgeInsets.fromLTRB(
                                    gutter,
                                    16,
                                    gutter,
                                    32,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _buildIdentity(),
                                      const SizedBox(height: 24),
                                      _buildSection(
                                        section_key: const Key(
                                          'profile_edit_basic_section',
                                        ),
                                        title: '기본 정보',
                                        children: [
                                          KeyedSubtree(
                                            key: _name_field_key,
                                            child: _ProfileField(
                                              field_key: const Key(
                                                'profile_name_field',
                                              ),
                                              label: '이름',
                                              required_field: true,
                                              controller: _name_controller,
                                              focus_node: _name_focus,
                                              enabled: !_is_busy,
                                              placeholder: '이름을 입력해주세요',
                                              max_length: 50,
                                              error_text: _name_error,
                                              autofill_hints: const [
                                                AutofillHints.name,
                                              ],
                                              onSubmitted: (_) =>
                                                  _phone_code_focus
                                                          .context
                                                          ?.mounted ==
                                                      true
                                                  ? _phone_code_focus
                                                        .requestFocus()
                                                  : _phone_focus.requestFocus(),
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          PhoneVerificationSection(
                                            code_focus: _phone_code_focus,
                                            phone_input_builder: (action) =>
                                                KeyedSubtree(
                                                  key: _phone_field_key,
                                                  child: _ProfileField(
                                                    field_key: const Key(
                                                      'profile_phone_field',
                                                    ),
                                                    label: '휴대폰 번호',
                                                    trailing: action,
                                                    required_field: true,
                                                    controller:
                                                        _phone_controller,
                                                    focus_node: _phone_focus,
                                                    enabled: !_is_busy,
                                                    placeholder:
                                                        '010-1234-5678',
                                                    keyboard_type:
                                                        TextInputType.phone,
                                                    autofill_hints: const [
                                                      AutofillHints
                                                          .telephoneNumberNational,
                                                    ],
                                                    input_formatters: [
                                                      KoreanMobilePhoneInputFormatter(),
                                                    ],
                                                    error_text: _phone_error,
                                                    onSubmitted: (_) =>
                                                        _job_focus
                                                            .requestFocus(),
                                                  ),
                                                ),
                                            onEditPhone: () =>
                                                _phone_focus.requestFocus(),
                                            state: phone_state,
                                            required_verification:
                                                _requires_phone_verification,
                                            enabled: !_is_busy,
                                            onSend: () => ref
                                                .read(
                                                  phone_verification_controller_provider(
                                                    _phone_scope,
                                                  ).notifier,
                                                )
                                                .sendCode(),
                                            onVerify: (code) => ref
                                                .read(
                                                  phone_verification_controller_provider(
                                                    _phone_scope,
                                                  ).notifier,
                                                )
                                                .verifyCode(code),
                                          ),
                                          if (compact_action &&
                                              _requires_phone_verification &&
                                              !phone_state.is_verified) ...[
                                            const SizedBox(height: 12),
                                            _buildVerificationHint(),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 32),
                                      _buildSection(
                                        section_key: const Key(
                                          'profile_edit_work_section',
                                        ),
                                        title: '근무 정보',
                                        optional: true,
                                        children: [
                                          _ProfileField(
                                            field_key: const Key(
                                              'profile_job_type_field',
                                            ),
                                            label: '직종',
                                            controller: _job_type_controller,
                                            focus_node: _job_focus,
                                            enabled: !_is_busy,
                                            max_length: 20,
                                            onSubmitted: (_) =>
                                                _workplace_focus.requestFocus(),
                                          ),
                                          const SizedBox(height: 20),
                                          _ProfileField(
                                            field_key: const Key(
                                              'profile_workplace_field',
                                            ),
                                            label: '소속 · 부서',
                                            controller: _workplace_controller,
                                            focus_node: _workplace_focus,
                                            enabled: !_is_busy,
                                            max_length: 100,
                                            autofill_hints: const [
                                              AutofillHints.organizationName,
                                            ],
                                            text_input_action:
                                                TextInputAction.done,
                                            onSubmitted: (_) =>
                                                _workplace_focus.unfocus(),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            widget.is_editing
                                                ? '비워두고 저장하면 근무 정보가 삭제돼요.'
                                                : '직종과 소속 정보는 나중에 설정에서 추가할 수 있습니다.',
                                            style: AppTheme.body_medium
                                                .copyWith(
                                                  color: AppTheme
                                                      .on_surface_variant_color,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 24),
                                      _buildAccount(),
                                      if (compact_action &&
                                          _save_error != null) ...[
                                        const SizedBox(height: 16),
                                        _buildSaveError(),
                                      ],
                                      if (!widget.is_editing) ...[
                                        const SizedBox(height: 24),
                                        const _PrivacyNotice(),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                              _buildBottomAction(
                                gutter,
                                compact: compact_action,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Widget _buildIdentity() {
    final image_url = _initial_user.profile_image_url;
    return Container(
      key: const Key('profile_identity_panel'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CupertinoButton(
            key: const Key('profile_image_button'),
            padding: EdgeInsets.zero,
            onPressed: _is_busy ? null : _pickProfileImage,
            child: Semantics(
              label: '프로필 사진 변경',
              child: ExcludeSemantics(
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: Stack(
                    children: [
                      Container(
                        key: const Key('profile_avatar'),
                        width: 72,
                        height: 72,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: AppTheme.surface_container_low_color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.outline_variant_color,
                          ),
                        ),
                        child: _selected_profile_image != null
                            ? Image.memory(
                                _selected_profile_image!.bytes,
                                fit: BoxFit.cover,
                              )
                            : ProfileImage(
                                image_url: image_url ?? '',
                                fallback: const Icon(
                                  CupertinoIcons.person_fill,
                                  size: 30,
                                  color: AppTheme.outline_color,
                                ),
                              ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppTheme.primary_color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.surface_color,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.camera_fill,
                            size: 14,
                            color: AppTheme.surface_color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '프로필 사진',
                  style: AppTheme.body_large.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                CupertinoButton(
                  key: const Key('profile_edit_photo_button'),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(48, 48),
                  onPressed: _is_busy ? null : _pickProfileImage,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_is_picking_image) ...[
                        const ExcludeSemantics(
                          child: CupertinoActivityIndicator(radius: 8),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Text(
                          _is_picking_image ? '사진 불러오는 중' : '사진 변경',
                          style: AppTheme.body_medium.copyWith(
                            color: AppTheme.primary_dark_color,
                          ),
                        ),
                      ),
                      if (!_is_picking_image) ...[
                        const SizedBox(width: 4),
                        const ExcludeSemantics(
                          child: Icon(
                            CupertinoIcons.chevron_right,
                            size: 12,
                            color: AppTheme.primary_dark_color,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required Key section_key,
    required String title,
    bool optional = false,
    required List<Widget> children,
  }) {
    return Column(
      key: section_key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.heading_small.copyWith(fontSize: 18),
                ),
              ),
              if (optional)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.surface_container_low_color,
                    borderRadius: AppTheme.input_border_radius,
                  ),
                  child: Text(
                    '선택',
                    style: AppTheme.body_medium.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(height: 1, color: AppTheme.surface_container_high_color),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }

  Widget _buildAccount() {
    return Container(
      key: const Key('profile_edit_account_section'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface_container_low_color,
        borderRadius: AppTheme.card_border_radius,
      ),
      child: Column(
        key: const Key('profile_email_field'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const ExcludeSemantics(
                child: Icon(
                  CupertinoIcons.lock,
                  size: 16,
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  header: true,
                  child: Text(
                    '계정 정보',
                    style: AppTheme.body_medium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text('이메일', style: AppTheme.body_medium),
          const SizedBox(height: 4),
          Text(_initial_user.email, style: AppTheme.body_large),
          const SizedBox(height: 8),
          Text(
            '로그인에 사용하는 이메일은 변경할 수 없어요.',
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationHint() {
    return Text(
      '휴대폰 인증을 완료하면 저장할 수 있어요.',
      key: const Key('profile_phone_verification_required'),
      textAlign: TextAlign.center,
      style: AppTheme.body_medium.copyWith(
        color: AppTheme.on_surface_variant_color,
      ),
    );
  }

  Widget _buildSaveError() {
    return Semantics(
      key: _save_error_key,
      liveRegion: true,
      child: Text(
        _save_error!,
        key: const Key('profile_edit_save_error'),
        style: AppTheme.body_medium.copyWith(color: AppTheme.error_text_color),
      ),
    );
  }

  Widget _buildBottomAction(double gutter, {required bool compact}) {
    return Container(
      key: const Key('profile_setup_bottom_action'),
      padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface_color,
        border: Border(
          top: BorderSide(color: AppTheme.surface_container_high_color),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact &&
              _requires_phone_verification &&
              !ref
                  .read(phone_verification_controller_provider(_phone_scope))
                  .is_verified) ...[
            _buildVerificationHint(),
            const SizedBox(height: 8),
          ],
          if (!compact && _save_error != null) ...[
            _buildSaveError(),
            const SizedBox(height: 8),
          ],
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: CupertinoButton(
              key: const Key('profile_setup_submit_button'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              color: AppTheme.primary_color,
              disabledColor: _is_loading
                  ? AppTheme.primary_color
                  : AppTheme.surface_container_highest_color,
              borderRadius: AppTheme.input_border_radius,
              onPressed: _can_save ? _handleSave : null,
              child: _is_loading
                  ? Semantics(
                      label: '저장 중',
                      child: const CupertinoActivityIndicator(
                        color: CupertinoColors.white,
                      ),
                    )
                  : Text(
                      widget.is_editing
                          ? (_save_error == null ? '변경사항 저장' : '다시 저장')
                          : '가입 완료',
                      style: AppTheme.body_large.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _can_save || _is_loading
                            ? AppTheme.surface_color
                            : AppTheme.on_surface_variant_color,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  final Key field_key;
  final String label;
  final Widget? trailing;
  final bool required_field;
  final TextEditingController controller;
  final FocusNode focus_node;
  final bool enabled;
  final String? placeholder;
  final int? max_length;
  final String? error_text;
  final TextInputType? keyboard_type;
  final Iterable<String>? autofill_hints;
  final List<TextInputFormatter>? input_formatters;
  final TextInputAction text_input_action;
  final ValueChanged<String> onSubmitted;

  const _ProfileField({
    required this.field_key,
    required this.label,
    this.trailing,
    this.required_field = false,
    required this.controller,
    required this.focus_node,
    required this.enabled,
    this.placeholder,
    this.max_length,
    this.error_text,
    this.keyboard_type,
    this.autofill_hints,
    this.input_formatters,
    this.text_input_action = TextInputAction.next,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final field_label = required_field ? '$label, 필수' : label;
    final input = Semantics(
      label: field_label,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: CupertinoTextField(
          enabled: enabled,
          controller: controller,
          focusNode: focus_node,
          placeholder: placeholder,
          keyboardType: keyboard_type,
          autofillHints: autofill_hints,
          inputFormatters: input_formatters,
          textInputAction: text_input_action,
          onSubmitted: onSubmitted,
          maxLength: max_length,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: focus_node.hasFocus
                ? AppTheme.surface_color
                : AppTheme.surface_container_low_color,
            borderRadius: AppTheme.input_border_radius,
            border: Border.all(
              color: error_text != null
                  ? AppTheme.error_text_color
                  : focus_node.hasFocus
                  ? AppTheme.primary_color
                  : AppTheme.outline_color,
              width: focus_node.hasFocus ? 1.5 : 0.5,
            ),
          ),
          style: AppTheme.body_large,
          placeholderStyle: AppTheme.body_large.copyWith(
            color: AppTheme.outline_color,
          ),
        ),
      ),
    );
    return Column(
      key: field_key,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ExcludeSemantics(
          child: Text.rich(
            TextSpan(
              text: label,
              children: [
                if (required_field)
                  const TextSpan(
                    text: ' *',
                    style: TextStyle(color: AppTheme.error_text_color),
                  ),
              ],
            ),
            style: AppTheme.body_medium.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        if (trailing == null)
          input
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 300 ||
                  MediaQuery.textScalerOf(context).scale(14) > 18) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [input, const SizedBox(height: 8), trailing!],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: input),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth * 0.45,
                    ),
                    child: trailing!,
                  ),
                ],
              );
            },
          ),
        if (error_text != null) ...[
          const SizedBox(height: 6),
          Semantics(
            liveRegion: true,
            child: Text(
              error_text!,
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.error_text_color,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(
              CupertinoIcons.shield_lefthalf_fill,
              size: 18,
              color: AppTheme.on_surface_variant_color,
            ),
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              '입력한 정보는 서비스 제공에 필요한 범위에서만 사용하며 안전하게 보호합니다.',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppTheme.on_surface_variant_color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
