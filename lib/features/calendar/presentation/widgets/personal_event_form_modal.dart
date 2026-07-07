import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/event_api_model.dart';

/// 개인 일정 추가 모달
class PersonalEventFormModal extends StatefulWidget {
  const PersonalEventFormModal({super.key, required this.initialDate});

  final DateTime initialDate;

  @override
  State<PersonalEventFormModal> createState() => _PersonalEventFormModalState();
}

class _PersonalEventFormModalState extends State<PersonalEventFormModal> {
  late final TextEditingController _titleController;
  late final TextEditingController _placeController;
  late final TextEditingController _memoController;
  late final ScrollController _scrollController;

  late DateTime _startDate;
  late DateTime _endDate;

  bool _allDay = false;
  Duration _startTime = const Duration(hours: 9);
  Duration _endTime = const Duration(hours: 10);
  int _visibilityLevel = 0;
  double _downDragDistance = 0;

  @override
  void initState() {
    super.initState();
    final initialDate = _dateOnly(widget.initialDate);
    _titleController = TextEditingController();
    _placeController = TextEditingController();
    _memoController = TextEditingController();
    _scrollController = ScrollController();
    _startDate = initialDate;
    _endDate = initialDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    _memoController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  DateTime _combineDateTime(DateTime date, Duration time) {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time.inHours,
      time.inMinutes.remainder(60),
    );
  }

  DateTime _buildStartAt() {
    if (_allDay) {
      return _dateOnly(_startDate);
    }
    return _combineDateTime(_startDate, _startTime);
  }

  DateTime _buildEndAt() {
    if (_allDay) {
      return _dateOnly(_endDate).add(const Duration(days: 1));
    }
    return _combineDateTime(_endDate, _endTime);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd', 'ko_KR').format(date);
  }

  String _formatTime(Duration time) {
    final hour = time.inHours.toString().padLeft(2, '0');
    final minute = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String? _emptyToNull(String value) {
    final trimmedValue = value.trim();
    return trimmedValue.isEmpty ? null : trimmedValue;
  }

  void _showInputError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('입력 오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate({required bool isStartDate}) async {
    final currentDate = isStartDate ? _startDate : _endDate;
    DateTime selectedDate = currentDate;

    final result = await showCupertinoModalPopup<DateTime>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  _buildPickerHeader(
                    title: isStartDate ? '시작일 선택' : '종료일 선택',
                    onConfirm: () => Navigator.pop(context, selectedDate),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: currentDate,
                      minimumYear: 2000,
                      maximumYear: 2050,
                      onDateTimeChanged: (date) {
                        setModalState(() {
                          selectedDate = _dateOnly(date);
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (isStartDate) {
        _startDate = result;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = result;
        if (_endDate.isBefore(_startDate)) {
          _startDate = _endDate;
        }
      }
    });
  }

  Future<void> _selectTime({required bool isStartTime}) async {
    final currentTime = isStartTime ? _startTime : _endTime;
    Duration selectedTime = currentTime;

    final result = await showCupertinoModalPopup<Duration>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: 300,
              decoration: const BoxDecoration(
                color: CupertinoColors.systemBackground,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  _buildPickerHeader(
                    title: isStartTime ? '시작시간 선택' : '종료시간 선택',
                    onConfirm: () => Navigator.pop(context, selectedTime),
                  ),
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: DateTime(
                        2026,
                        1,
                        1,
                        currentTime.inHours,
                        currentTime.inMinutes.remainder(60),
                      ),
                      use24hFormat: true,
                      onDateTimeChanged: (date) {
                        setModalState(() {
                          selectedTime = Duration(
                            hours: date.hour,
                            minutes: date.minute,
                          );
                        });
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    setState(() {
      if (isStartTime) {
        _startTime = result;
      } else {
        _endTime = result;
      }
    });
  }

  Widget _buildPickerHeader({
    required String title,
    required VoidCallback onConfirm,
  }) {
    return Container(
      height: 44,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemGrey6,
        border: Border(
          bottom: BorderSide(color: CupertinoColors.separator, width: 0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          Text(title, style: AppTheme.heading_small),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            onPressed: onConfirm,
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showInputError('제목을 입력해주세요.');
      return;
    }

    final startAt = _buildStartAt();
    final endAt = _buildEndAt();
    if (!endAt.isAfter(startAt)) {
      _showInputError('종료 시각은 시작 시각보다 늦어야 합니다.');
      return;
    }

    Navigator.pop(
      context,
      CreateEventRequest(
        title: title,
        memo: _emptyToNull(_memoController.text),
        place: _emptyToNull(_placeController.text),
        allDay: _allDay,
        startAt: startAt,
        endAt: endAt,
        visibilityLevel: _visibilityLevel,
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    _downDragDistance = 0;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    final isAtTop =
        !_scrollController.hasClients || _scrollController.offset <= 0;
    final delta = event.delta.dy;

    if (isAtTop && delta > 0) {
      _downDragDistance += delta;
    } else if (delta < 0) {
      _downDragDistance = 0;
    }
  }

  void _handlePointerUp(PointerUpEvent event) {
    final shouldDismiss = _downDragDistance > 90;
    _downDragDistance = 0;

    if (shouldDismiss) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final keyboardHeight = mediaQuery.viewInsets.bottom;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: (_) {
        _downDragDistance = 0;
      },
      child: MediaQuery(
        data: mediaQuery.copyWith(viewInsets: EdgeInsets.zero),
        child: CupertinoPageScaffold(
          resizeToAvoidBottomInset: false,
          backgroundColor: CupertinoColors.systemGroupedBackground,
          navigationBar: CupertinoNavigationBar(
            middle: const Text('개인 일정 추가'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _save,
              child: const Text(
                '저장',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(bottom: keyboardHeight + 24),
              children: [
                const SizedBox(height: 16),
                _buildBasicSection(),
                _buildTimeSection(),
                _buildVisibilitySection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicSection() {
    final fieldWidth = MediaQuery.of(context).size.width * 0.56;

    return CupertinoListSection.insetGrouped(
      header: const Text('기본 정보'),
      children: [
        CupertinoListTile(
          title: const Text('제목'),
          trailing: SizedBox(
            width: fieldWidth,
            child: CupertinoTextField(
              controller: _titleController,
              placeholder: '일정 제목',
              textAlign: TextAlign.right,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
        ),
        CupertinoListTile(
          title: const Text('장소'),
          trailing: SizedBox(
            width: fieldWidth,
            child: CupertinoTextField(
              controller: _placeController,
              placeholder: '선택',
              textAlign: TextAlign.right,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
          child: CupertinoTextField(
            controller: _memoController,
            placeholder: '메모',
            minLines: 3,
            maxLines: 5,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('일시'),
      children: [
        CupertinoListTile(
          title: const Text('종일'),
          trailing: CupertinoSwitch(
            value: _allDay,
            onChanged: (value) {
              setState(() {
                _allDay = value;
              });
            },
          ),
        ),
        _buildPickerTile(
          title: '시작일',
          value: _formatDate(_startDate),
          icon: CupertinoIcons.calendar,
          onTap: () => _selectDate(isStartDate: true),
        ),
        if (!_allDay)
          _buildPickerTile(
            title: '시작시간',
            value: _formatTime(_startTime),
            icon: CupertinoIcons.time,
            onTap: () => _selectTime(isStartTime: true),
          ),
        _buildPickerTile(
          title: '종료일',
          value: _formatDate(_endDate),
          icon: CupertinoIcons.calendar,
          onTap: () => _selectDate(isStartDate: false),
        ),
        if (!_allDay)
          _buildPickerTile(
            title: '종료시간',
            value: _formatTime(_endTime),
            icon: CupertinoIcons.time,
            onTap: () => _selectTime(isStartTime: false),
          ),
      ],
    );
  }

  Widget _buildPickerTile({
    required String title,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return CupertinoListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppTheme.body_medium.copyWith(color: CupertinoColors.label),
          ),
          const SizedBox(width: 8),
          Icon(icon, size: 18, color: AppTheme.primary_color),
        ],
      ),
      onTap: onTap,
    );
  }

  void _updateVisibilityLevelFromDrag({
    required Offset localPosition,
    required double trackWidth,
  }) {
    if (trackWidth <= 0) return;

    final clampedX = localPosition.dx.clamp(0.0, trackWidth).toDouble();
    final ratio = clampedX / trackWidth;
    final nextLevel = (ratio * 5).round().clamp(0, 5).toInt();

    if (nextLevel == _visibilityLevel) return;

    setState(() {
      _visibilityLevel = nextLevel;
    });
  }

  Widget _buildVisibilityLevelDragSelector() {
    const selectorHeight = 56.0;
    const thumbSize = 42.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final levelRatio = _visibilityLevel / 5;
        final thumbTravel = trackWidth - thumbSize;
        final thumbLeft = thumbTravel <= 0 ? 0.0 : thumbTravel * levelRatio;
        final fillWidth = trackWidth * levelRatio;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (details) {
            _updateVisibilityLevelFromDrag(
              localPosition: details.localPosition,
              trackWidth: trackWidth,
            );
          },
          onHorizontalDragUpdate: (details) {
            _updateVisibilityLevelFromDrag(
              localPosition: details.localPosition,
              trackWidth: trackWidth,
            );
          },
          child: SizedBox(
            height: selectorHeight,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGrey5,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  width: fillWidth,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.primary_color.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                Row(
                  children: [
                    for (int level = 0; level <= 5; level++)
                      Expanded(
                        child: Center(
                          child: Text(
                            '$level',
                            style: AppTheme.body_small.copyWith(
                              color: level == _visibilityLevel
                                  ? CupertinoColors.white
                                  : CupertinoColors.secondaryLabel,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 90),
                  curve: Curves.easeOut,
                  left: thumbLeft,
                  width: thumbSize,
                  height: thumbSize,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary_color,
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: CupertinoColors.black.withValues(alpha: 0.16),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$_visibilityLevel',
                        style: AppTheme.body_medium.copyWith(
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVisibilitySection() {
    return CupertinoListSection.insetGrouped(
      header: const Text('공개 레벨 설정'),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
          child: _buildVisibilityLevelDragSelector(),
        ),
      ],
    );
  }
}
