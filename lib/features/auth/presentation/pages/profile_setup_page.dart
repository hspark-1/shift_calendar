import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../calendar/presentation/pages/calendar_page.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

/// 지원하는 타임존 목록
const List<String> _supported_timezones = [
  'Asia/Seoul',
  'Asia/Tokyo',
  'Asia/Shanghai',
  'Asia/Singapore',
  'America/New_York',
  'America/Los_Angeles',
  'America/Chicago',
  'Europe/London',
  'Europe/Paris',
  'Europe/Berlin',
  'Australia/Sydney',
  'Pacific/Auckland',
];

/// 타임존 표시 이름
String _getTimezoneDisplayName(String timezone) {
  switch (timezone) {
    case 'Asia/Seoul':
      return '서울 (GMT+9)';
    case 'Asia/Tokyo':
      return '도쿄 (GMT+9)';
    case 'Asia/Shanghai':
      return '상하이 (GMT+8)';
    case 'Asia/Singapore':
      return '싱가포르 (GMT+8)';
    case 'America/New_York':
      return '뉴욕 (GMT-5)';
    case 'America/Los_Angeles':
      return '로스앤젤레스 (GMT-8)';
    case 'America/Chicago':
      return '시카고 (GMT-6)';
    case 'Europe/London':
      return '런던 (GMT+0)';
    case 'Europe/Paris':
      return '파리 (GMT+1)';
    case 'Europe/Berlin':
      return '베를린 (GMT+1)';
    case 'Australia/Sydney':
      return '시드니 (GMT+11)';
    case 'Pacific/Auckland':
      return '오클랜드 (GMT+13)';
    default:
      return timezone;
  }
}

/// 프로필 설정 페이지 (신규 가입 시)
class ProfileSetupPage extends ConsumerStatefulWidget {
  final User user;

  const ProfileSetupPage({super.key, required this.user});

  @override
  ConsumerState<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends ConsumerState<ProfileSetupPage> {
  late TextEditingController _name_controller;
  late String _selected_timezone;
  bool _is_loading = false;

  @override
  void initState() {
    super.initState();
    _name_controller = TextEditingController(text: widget.user.name);
    _selected_timezone = widget.user.timezone ?? AppConstants.default_timezone;
  }

  @override
  void dispose() {
    _name_controller.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final name = _name_controller.text.trim();

    if (name.isEmpty) {
      _showErrorDialog('이름을 입력해주세요.');
      return;
    }

    setState(() {
      _is_loading = true;
    });

    final success = await ref
        .read(authProvider.notifier)
        .updateProfile(name: name, timezone: _selected_timezone);

    if (!mounted) return;

    setState(() {
      _is_loading = false;
    });

    if (success) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const CalendarPage()),
      );
    } else {
      final error = ref.read(authProvider).error;
      if (error != null) {
        _showErrorDialog(error);
      }
    }
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  void _showTimezonePicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 300,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            // 헤더
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.separator.resolveFrom(context),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text('취소'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text('완료'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // 피커
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                scrollController: FixedExtentScrollController(
                  initialItem: _supported_timezones.indexOf(_selected_timezone),
                ),
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selected_timezone = _supported_timezones[index];
                  });
                },
                children: _supported_timezones.map((tz) {
                  return Center(
                    child: Text(
                      _getTimezoneDisplayName(tz),
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('프로필 설정'),
        trailing: _is_loading
            ? const CupertinoActivityIndicator()
            : CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _handleSave,
                child: const Text(
                  '완료',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
      ),
      child: SafeArea(
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // 프로필 이미지
            _buildProfileImage(),
            const SizedBox(height: 32),
            // 입력 폼
            _buildFormSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Center(
      child: Column(
        children: [
          // 프로필 이미지
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.systemGrey5,
              image: widget.user.profile_image_url != null
                  ? DecorationImage(
                      image: NetworkImage(widget.user.profile_image_url!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: widget.user.profile_image_url == null
                ? const Icon(
                    CupertinoIcons.person_fill,
                    size: 50,
                    color: CupertinoColors.systemGrey,
                  )
                : null,
          ),
          const SizedBox(height: 8),
          Text(
            '카카오 프로필',
            style: TextStyle(
              fontSize: 13,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('기본 정보'),
      children: [
        // 이메일 (readonly)
        CupertinoListTile(
          title: const Text('이메일'),
          additionalInfo: Text(
            widget.user.email,
            style: TextStyle(
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ),
        ),
        // 이름
        CupertinoListTile(
          title: const Text('이름'),
          trailing: SizedBox(
            width: 200,
            child: CupertinoTextField(
              controller: _name_controller,
              placeholder: '이름을 입력하세요',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(),
              textAlign: TextAlign.end,
              style: AppTheme.body_medium,
            ),
          ),
        ),
        // 타임존
        CupertinoListTile(
          title: const Text('타임존'),
          additionalInfo: Text(_getTimezoneDisplayName(_selected_timezone)),
          trailing: const CupertinoListTileChevron(),
          onTap: _showTimezonePicker,
        ),
      ],
    );
  }
}
