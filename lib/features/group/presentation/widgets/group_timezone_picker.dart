// ignore_for_file: non_constant_identifier_names, constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/theme/app_theme.dart';

const _city_names = <String, String>{
  'Asia/Seoul': '서울',
  'Asia/Tokyo': '도쿄',
  'Asia/Shanghai': '상하이',
  'Asia/Hong_Kong': '홍콩',
  'Asia/Singapore': '싱가포르',
  'Asia/Bangkok': '방콕',
  'Asia/Dubai': '두바이',
  'Europe/London': '런던',
  'Europe/Paris': '파리',
  'Europe/Berlin': '베를린',
  'America/New_York': '뉴욕',
  'America/Chicago': '시카고',
  'America/Los_Angeles': '로스앤젤레스',
  'Pacific/Honolulu': '호놀룰루',
  'Australia/Sydney': '시드니',
  'Pacific/Auckland': '오클랜드',
  'UTC': '협정 세계시',
};

void _ensureTimezones() {
  if (tz.timeZoneDatabase.locations.isEmpty) {
    timezone_data.initializeTimeZones();
  }
}

String groupTimezoneLabel(String identifier) {
  _ensureTimezones();
  final location = tz.timeZoneDatabase.locations[identifier];
  if (location == null) return '현재 시간대 ($identifier)';
  final city =
      _city_names[identifier] ??
      identifier.split('/').last.replaceAll('_', ' ');
  final offset = tz.TZDateTime.now(location).timeZoneOffset;
  final minutes = offset.inMinutes.abs();
  final sign = offset.isNegative ? '-' : '+';
  final hours_text = (minutes ~/ 60).toString().padLeft(2, '0');
  final minutes_text = (minutes % 60).toString().padLeft(2, '0');
  return '$city (UTC$sign$hours_text:$minutes_text)';
}

class GroupTimezonePicker extends StatefulWidget {
  const GroupTimezonePicker({super.key, required this.selected_timezone});
  final String selected_timezone;

  @override
  State<GroupTimezonePicker> createState() => _GroupTimezonePickerState();
}

class _GroupTimezonePickerState extends State<GroupTimezonePicker> {
  String _query = '';
  late final List<String> _timezones;

  @override
  void initState() {
    super.initState();
    _ensureTimezones();
    final remaining =
        tz.timeZoneDatabase.locations.keys
            .where((name) => name.contains('/') || name == 'UTC')
            .toList()
          ..sort();
    _timezones = {
      widget.selected_timezone,
      ..._city_names.keys,
      ...remaining,
    }.toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _timezones
        .where(
          (name) => '$name ${groupTimezoneLabel(name)}'.toLowerCase().contains(
            _query.toLowerCase(),
          ),
        )
        .toList();
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: const CupertinoNavigationBar(middle: Text('시간대 선택')),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: CupertinoSearchTextField(
                placeholder: '도시 또는 시간대 검색',
                onChanged: (value) => setState(() => _query = value.trim()),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '현재 UTC 시차입니다. 서머타임에 따라 달라질 수 있어요.',
                style: AppTheme.body_medium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: results.isEmpty
                  ? const Center(child: Text('검색 결과가 없습니다'))
                  : ListView.builder(
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final name = results[index];
                        return CupertinoButton(
                          key: ValueKey('group-timezone-$name'),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          onPressed: () => Navigator.of(context).pop(name),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  groupTimezoneLabel(name),
                                  style: AppTheme.body_large,
                                ),
                              ),
                              if (name == widget.selected_timezone)
                                const Icon(CupertinoIcons.check_mark, size: 20),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
