import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import 'shift_badge.dart';
import 'shift_type_button.dart';

/// 근무 입력 바텀시트 (연속 입력 지원)
class ShiftInputSheet extends StatefulWidget {
  const ShiftInputSheet({
    super.key,
    required this.initial_date,
    required this.schedules,
    required this.onScheduleUpdated,
    required this.onSelectedDateChanged,
  });

  final DateTime initial_date;
  final Map<DateTime, String> schedules;
  final Function(Map<DateTime, String>) onScheduleUpdated;
  final Function(DateTime) onSelectedDateChanged;

  @override
  State<ShiftInputSheet> createState() => _ShiftInputSheetState();
}

class _ShiftInputSheetState extends State<ShiftInputSheet> {
  late DateTime _current_date;
  late Map<DateTime, String> _local_schedules;

  @override
  void initState() {
    super.initState();
    _current_date = widget.initial_date;
    _local_schedules = Map.from(widget.schedules);
  }

  /// 날짜 정규화 (시간 제거)
  DateTime _normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// 현재 날짜의 근무 유형 반환
  String? _getCurrentShift() {
    return _local_schedules[_normalizeDate(_current_date)];
  }

  /// 근무 유형 선택 처리
  void _onShiftSelected(String shift_code) {
    setState(() {
      _local_schedules[_normalizeDate(_current_date)] = shift_code;
    });

    // 부모 위젯에 업데이트 알림
    widget.onScheduleUpdated(_local_schedules);

    // 다음 날로 이동
    _moveToNextDay();
  }

  /// 다음 날로 이동
  void _moveToNextDay() {
    final next_day = _current_date.add(const Duration(days: 1));
    setState(() {
      _current_date = next_day;
    });
    widget.onSelectedDateChanged(next_day);
  }

  @override
  Widget build(BuildContext context) {
    final date_format = DateFormat('yyyy.MM.dd', 'ko_KR');
    final current_shift = _getCurrentShift();
    final shift_info = current_shift != null
        ? AppConstants.shift_types[current_shift]
        : null;

    return Container(
      height: 320,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: CupertinoColors.systemGrey5,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '근무 추가',
                    style: AppTheme.heading_small,
                  ),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      '완료',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            // 선택된 날짜 정보
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CupertinoColors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.systemGrey.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    date_format.format(_current_date),
                    style: AppTheme.heading_small,
                  ),
                  const SizedBox(width: 12),
                  if (current_shift != null && shift_info != null) ...[
                    ShiftBadge(
                        shift_type: current_shift, size: 20, show_label: true),
                    const Spacer(),
                    Text(
                      shift_info.timeDisplay,
                      style: AppTheme.body_small.copyWith(
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ] else ...[
                    const Spacer(),
                    Text(
                      '근무를 선택하세요',
                      style: AppTheme.body_medium.copyWith(
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 근무 유형 선택 버튼
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    ShiftTypeButtonGroup(
                      selected_shift: current_shift,
                      onShiftSelected: _onShiftSelected,
                    ),
                    const Spacer(),
                    Text(
                      '버튼을 누르면 다음 날로 자동 이동합니다',
                      style: AppTheme.body_small.copyWith(
                        color: CupertinoColors.systemGrey2,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
