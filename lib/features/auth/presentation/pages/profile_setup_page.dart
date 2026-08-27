// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../domain/entities/user.dart';
import '../../domain/entities/profile_image_upload.dart';
import '../providers/auth_provider.dart';

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
  final VoidCallback? on_completed;
  final Future<ProfileImageUpload?> Function()? profile_image_picker;
  final Future<String> Function()? timezone_loader;

  const ProfileSetupPage({
    super.key,
    required this.user,
    this.on_completed,
    this.profile_image_picker,
    this.timezone_loader,
  });

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  late final TextEditingController _name_controller;
  late final TextEditingController _phone_controller;
  late final TextEditingController _job_type_controller;
  late final TextEditingController _workplace_controller;
  late String _selected_timezone;
  late final Future<void> _timezone_future;
  ProfileImageUpload? _selected_profile_image;
  bool _has_submitted = false;
  bool _is_loading = false;

  @override
  void initState() {
    super.initState();
    _name_controller = TextEditingController(text: widget.user.name);
    _phone_controller = TextEditingController(
      text: KoreanMobilePhoneInputFormatter.format(widget.user.phone ?? ''),
    );
    _job_type_controller = TextEditingController(
      text:
          _legacy_job_type_labels[widget.user.job_type] ??
          widget.user.job_type ??
          '',
    );
    _workplace_controller = TextEditingController(
      text: widget.user.workplace ?? '',
    );
    _selected_timezone = widget.user.timezone ?? AppConstants.default_timezone;
    _timezone_future = _loadDeviceTimezone();
  }

  @override
  void dispose() {
    _name_controller.dispose();
    _phone_controller.dispose();
    _job_type_controller.dispose();
    _workplace_controller.dispose();
    super.dispose();
  }

  String get _phone_digits =>
      _phone_controller.text.replaceAll(RegExp('[^0-9]'), '');

  String? get _name_error {
    if (!_has_submitted) return null;
    final name = _name_controller.text.trim();
    if (name.isEmpty) return '이름을 입력해주세요.';
    if (name.length > 50) return '이름은 50자 이하로 입력해주세요.';
    return null;
  }

  String? get _phone_error {
    if (!_has_submitted) return null;
    if (_phone_digits.isEmpty) return '휴대폰 번호를 입력해주세요.';
    if (!_is_valid_korean_mobile_phone) {
      return '한국 휴대폰 번호 형식을 확인해주세요.';
    }
    return null;
  }

  bool get _is_valid_korean_mobile_phone =>
      RegExp(r'^(?:010[0-9]{8}|01[16789][0-9]{7,8})$').hasMatch(_phone_digits);

  bool get _is_required_input_valid =>
      _name_controller.text.trim().isNotEmpty &&
      _name_controller.text.trim().length <= 50 &&
      _is_valid_korean_mobile_phone;

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
    try {
      final selected_image = widget.profile_image_picker != null
          ? await widget.profile_image_picker!()
          : await _pickProfileImageFromGallery();
      if (!mounted || selected_image == null) return;
      if (selected_image.bytes.lengthInBytes > 5 * 1024 * 1024) {
        _showErrorDialog('프로필 이미지는 5MB 이하만 선택할 수 있어요.');
        return;
      }
      setState(() => _selected_profile_image = selected_image);
    } catch (_) {
      if (mounted) _showErrorDialog('사진을 불러오지 못했어요. 다시 시도해주세요.');
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
    if (_is_loading) return;
    setState(() => _has_submitted = true);
    if (!_is_required_input_valid) return;

    await _timezone_future;
    if (!mounted) return;

    final job_type = _job_type_controller.text.trim();
    final workplace = _workplace_controller.text.trim();
    setState(() => _is_loading = true);
    final success = await ref
        .read(authProvider.notifier)
        .completeProfileSetup(
          name: _name_controller.text.trim(),
          timezone: _selected_timezone,
          phone: _phone_digits,
          profile_image: _selected_profile_image,
          job_type: job_type.isEmpty ? null : job_type,
          workplace: workplace.isEmpty ? null : workplace,
        );

    if (!mounted) return;
    setState(() => _is_loading = false);
    if (!success) {
      final error = ref.read(authProvider).error;
      if (error != null) _showErrorDialog(error);
      return;
    }

    if (widget.on_completed != null) {
      widget.on_completed!();
      return;
    }
    Navigator.of(context).pushReplacement(
      CupertinoPageRoute<void>(builder: (_) => const CalendarPage()),
    );
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
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: const CupertinoNavigationBar(middle: Text('프로필 설정')),
      child: SafeArea(
        child: GestureDetector(
          key: const Key('profile_setup_keyboard_dismiss_area'),
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  key: const Key('profile_setup_scroll_view'),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  children: [
                    _buildIntro(),
                    const SizedBox(height: 28),
                    _buildBasicSection(),
                    const SizedBox(height: 28),
                    _buildWorkSection(),
                    const SizedBox(height: 24),
                    const _PrivacyNotice(),
                  ],
                ),
              ),
              _buildBottomAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIntro() {
    final image_url = widget.user.profile_image_url;
    final has_image = image_url != null && image_url.isNotEmpty;
    return Row(
      children: [
        CupertinoButton(
          key: const Key('profile_image_button'),
          minimumSize: Size.zero,
          padding: EdgeInsets.zero,
          onPressed: _is_loading ? null : _pickProfileImage,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                key: const Key('profile_avatar'),
                width: 72,
                height: 72,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppTheme.surface_container_color,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.outline_variant_color),
                ),
                child: _selected_profile_image != null
                    ? Image.memory(
                        _selected_profile_image!.bytes,
                        fit: BoxFit.cover,
                      )
                    : has_image
                    ? Image.network(
                        image_url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(
                          CupertinoIcons.person_fill,
                          size: 34,
                          color: AppTheme.outline_color,
                        ),
                      )
                    : const Icon(
                        CupertinoIcons.person_fill,
                        size: 34,
                        color: AppTheme.outline_color,
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppTheme.primary_color,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.surface_color, width: 2),
                  ),
                  child: const Icon(
                    CupertinoIcons.camera_fill,
                    size: 14,
                    color: CupertinoColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ShiftMate에 오신 걸 환영해요',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.on_surface_color,
                ),
              ),
              SizedBox(height: 5),
              Text(
                '프로필을 설정하고 나만의\n일정 관리를 시작해보세요.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: CupertinoIcons.person_fill,
          title: '기본 정보',
          badge: '필수',
          required_section: true,
        ),
        const SizedBox(height: 6),
        const Text(
          '계정 생성과 서비스 이용에 필요한 정보예요.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.on_surface_variant_color,
          ),
        ),
        const SizedBox(height: 12),
        _ProfileInformationCard(
          key: const Key('basic_information_card'),
          child: Column(
            children: [
              _ReadonlyEmailRow(email: widget.user.email),
              const _RowDivider(),
              _ProfileTextFieldRow(
                field_key: const Key('profile_name_field'),
                label: '이름',
                required_field: true,
                icon: CupertinoIcons.person_crop_rectangle,
                controller: _name_controller,
                placeholder: '이름을 입력해주세요',
                text_input_action: TextInputAction.next,
                max_length: 50,
                error_text: _name_error,
                onChanged: (_) {
                  if (_has_submitted) setState(() {});
                },
              ),
              const _RowDivider(),
              _ProfileTextFieldRow(
                field_key: const Key('profile_phone_field'),
                label: '휴대폰 번호',
                required_field: true,
                icon: CupertinoIcons.phone_fill,
                controller: _phone_controller,
                placeholder: '010-1234-5678',
                keyboard_type: TextInputType.phone,
                text_input_action: TextInputAction.next,
                input_formatters: [KoreanMobilePhoneInputFormatter()],
                error_text: _phone_error,
                onChanged: (_) {
                  if (_has_submitted) setState(() {});
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWorkSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          icon: CupertinoIcons.briefcase_fill,
          title: '근무 정보',
          badge: '선택',
        ),
        const SizedBox(height: 10),
        const _OptionalNotice(),
        const SizedBox(height: 12),
        _ProfileInformationCard(
          key: const Key('work_information_card'),
          child: Column(
            children: [
              _ProfileTextFieldRow(
                field_key: const Key('profile_job_type_field'),
                label: '직종',
                icon: CupertinoIcons.briefcase_fill,
                controller: _job_type_controller,
                placeholder: '예: 간호사, 개발자, 디자이너',
                text_input_action: TextInputAction.next,
                max_length: 20,
              ),
              const _RowDivider(),
              _ProfileTextFieldRow(
                field_key: const Key('profile_workplace_field'),
                label: '재직 중인 회사·기관 및 부서',
                icon: CupertinoIcons.building_2_fill,
                controller: _workplace_controller,
                placeholder: '예: ShiftMate 프로덕트팀',
                text_input_action: TextInputAction.done,
                max_length: 100,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    return Container(
      key: const Key('profile_setup_bottom_action'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppTheme.background_color,
        border: Border(
          top: BorderSide(color: AppTheme.outline_variant_color, width: 0.5),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: CupertinoButton.filled(
          key: const Key('profile_setup_submit_button'),
          padding: EdgeInsets.zero,
          borderRadius: BorderRadius.circular(14),
          onPressed: _is_loading ? null : _handleSave,
          child: _is_loading
              ? const CupertinoActivityIndicator(color: CupertinoColors.white)
              : const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '저장하고 시작하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6),
                    Icon(CupertinoIcons.arrow_right, size: 18),
                  ],
                ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String badge;
  final bool required_section;

  const _SectionTitle({
    required this.icon,
    required this.title,
    required this.badge,
    this.required_section = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 21, color: AppTheme.primary_color),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppTheme.on_surface_color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: required_section
                ? const Color(0xFFE8F2FF)
                : AppTheme.surface_container_highest_color,
            borderRadius: BorderRadius.circular(AppTheme.chip_radius),
          ),
          child: Text(
            badge,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: required_section
                  ? AppTheme.primary_dark_color
                  : AppTheme.on_surface_variant_color,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReadonlyEmailRow extends StatelessWidget {
  final String email;
  const _ReadonlyEmailRow({required this.email});

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('profile_email_field'),
      color: AppTheme.surface_container_low_color,
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                '이메일 계정 *',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.on_surface_variant_color,
                ),
              ),
              Spacer(),
              Icon(
                CupertinoIcons.check_mark_circled_solid,
                size: 15,
                color: Color(0xFF2F7D45),
              ),
              SizedBox(width: 4),
              Text(
                '인증됨',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2F7D45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(
                CupertinoIcons.lock_fill,
                size: 18,
                color: AppTheme.outline_color,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.on_surface_variant_color,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTextFieldRow extends StatelessWidget {
  final Key field_key;
  final String label;
  final bool required_field;
  final IconData icon;
  final TextEditingController controller;
  final String placeholder;
  final TextInputType? keyboard_type;
  final TextInputAction? text_input_action;
  final List<TextInputFormatter>? input_formatters;
  final int? max_length;
  final String? error_text;
  final ValueChanged<String>? onChanged;

  const _ProfileTextFieldRow({
    required this.field_key,
    required this.label,
    required this.icon,
    required this.controller,
    required this.placeholder,
    this.required_field = false,
    this.keyboard_type,
    this.text_input_action,
    this.input_formatters,
    this.max_length,
    this.error_text,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      key: field_key,
      color: error_text == null
          ? AppTheme.surface_color
          : const Color(0xFFFFF8F7),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            required_field ? '$label *' : label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: error_text == null
                  ? AppTheme.on_surface_variant_color
                  : CupertinoColors.systemRed,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: error_text == null
                    ? AppTheme.outline_color
                    : CupertinoColors.systemRed,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: CupertinoTextField(
                  controller: controller,
                  placeholder: placeholder,
                  keyboardType: keyboard_type,
                  textInputAction: text_input_action,
                  inputFormatters: input_formatters,
                  maxLength: max_length,
                  onChanged: onChanged,
                  padding: EdgeInsets.zero,
                  decoration: const BoxDecoration(),
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.on_surface_color,
                  ),
                  placeholderStyle: const TextStyle(
                    fontSize: 16,
                    color: AppTheme.outline_color,
                  ),
                ),
              ),
            ],
          ),
          if (error_text != null) ...[
            const SizedBox(height: 5),
            Text(
              error_text!,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemRed,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileInformationCard extends StatelessWidget {
  final Widget child;

  const _ProfileInformationCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      foregroundDecoration: BoxDecoration(
        borderRadius: AppTheme.card_border_radius,
        border: Border.all(color: AppTheme.outline_variant_color, width: 1),
      ),
      child: ClipRRect(
        borderRadius: AppTheme.card_border_radius,
        clipBehavior: Clip.antiAlias,
        child: ColoredBox(color: AppTheme.surface_color, child: child),
      ),
    );
  }
}

class _OptionalNotice extends StatelessWidget {
  const _OptionalNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('optional_work_information_notice'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F2FF),
        borderRadius: BorderRadius.circular(AppTheme.input_radius),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.clock,
            size: 18,
            color: AppTheme.primary_dark_color,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '지금 입력하지 않아도 괜찮아요.\n',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '앱을 시작한 뒤 설정에서 언제든 추가할 수 있어요.'),
                ],
              ),
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: AppTheme.primary_dark_color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppTheme.surface_container_low_color,
        border: Border.all(color: AppTheme.surface_container_high_color),
        borderRadius: BorderRadius.circular(AppTheme.input_radius),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            CupertinoIcons.shield_lefthalf_fill,
            size: 18,
            color: AppTheme.outline_color,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              '입력한 정보는 서비스 제공에 필요한 범위에서만 사용하며 안전하게 보호합니다.',
              style: TextStyle(
                fontSize: 12,
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

class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 0.5,
      child: ColoredBox(color: AppTheme.surface_container_high_color),
    );
  }
}
