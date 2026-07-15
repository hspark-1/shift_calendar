import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../data/models/event_api_model.dart';
import 'date_picker_sheet.dart';
import 'time_picker_sheet.dart';

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

  String _formatDisplayDate(DateTime date) {
    return DateFormat('yyyy년 M월 d일 (E)', 'ko_KR').format(date);
  }

  String _formatDisplayTime(Duration time) {
    final hour24 = time.inHours.remainder(24);
    final period = hour24 < 12 ? '오전' : '오후';
    final hour12Value = hour24.remainder(12);
    final hour12 = hour12Value == 0 ? 12 : hour12Value;
    final hour = hour12.toString().padLeft(2, '0');
    final minute = time.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '$period $hour:$minute';
  }

  String _visibilityDescription() {
    if (_visibilityLevel == 0) {
      return '레벨 0: 열람 허용된 기본 친구에게 공개됩니다.';
    }
    return '레벨 $_visibilityLevel: 친구 레벨 $_visibilityLevel 이상에게 공개됩니다.';
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

  Future<void> _editPlace() async {
    final controller = TextEditingController(text: _placeController.text);
    final result = await showCupertinoDialog<String>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('장소'),
          content: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: CupertinoTextField(
              controller: controller,
              autofocus: true,
              placeholder: '장소를 입력하세요',
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('취소'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext, ''),
              child: const Text('삭제'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () => Navigator.pop(dialogContext, controller.text),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    controller.dispose();

    if (result == null) return;

    setState(() {
      _placeController.text = result.trim();
    });
  }

  void _showRepeatInfo() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('반복'),
        content: const Text('반복 일정은 아직 지원하지 않습니다.'),
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
    final result = await showDatePickerSheet(
      context: context,
      title: isStartDate ? '시작일 선택' : '종료일 선택',
      initial_date: currentDate,
      minimum_date: DateTime(2000, 1, 1),
      maximum_date: DateTime(2050, 12, 31),
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
    final result = await showTimePickerSheet(
      context: context,
      title: isStartTime ? '시작시간 선택' : '종료시간 선택',
      initial_time: currentTime,
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
          backgroundColor: AppTheme.background_color,
          navigationBar: CupertinoNavigationBar(
            backgroundColor: AppTheme.background_color,
            border: const Border(
              bottom: BorderSide(
                color: AppTheme.outline_variant_color,
                width: 0.5,
              ),
            ),
            middle: const Text('개인 일정 추가'),
            leading: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
              child: const Text(
                '취소',
                style: TextStyle(
                  color: AppTheme.primary_color,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _save,
              child: const Text(
                '저장',
                style: TextStyle(
                  color: AppTheme.primary_color,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: _scrollController,
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.fromLTRB(24, 28, 24, keyboardHeight + 48),
              children: [
                _buildBasicSection(),
                const SizedBox(height: 28),
                _buildTimeSection(),
                const SizedBox(height: 28),
                _buildVisibilitySection(),
                // const SizedBox(height: 28),
                // _buildPreviewSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 14),
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.on_surface_variant_color,
              fontSize: 16,
              fontWeight: FontWeight.w500,
              height: 1.25,
            ),
          ),
        ),
        child,
      ],
    );
  }

  Widget _buildFormCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: AppTheme.cardDecoration(),
      child: child,
    );
  }

  Widget _buildBasicSection() {
    final placeText = _placeController.text.trim();

    return _buildSection(
      title: '기본 정보',
      child: _buildFormCard(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '일정 제목 (필수)',
              style: TextStyle(
                color: AppTheme.on_surface_variant_color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _titleController,
              placeholder: '일정 제목을 입력하세요',
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: AppTheme.outline_variant_color,
                    width: 1,
                  ),
                ),
              ),
              padding: const EdgeInsets.only(bottom: 12),
              style: const TextStyle(
                color: AppTheme.on_surface_color,
                fontSize: 20,
                fontWeight: FontWeight.w400,
                height: 1.25,
              ),
              placeholderStyle: const TextStyle(
                color: AppTheme.outline_color,
                fontSize: 20,
                fontWeight: FontWeight.w400,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 18),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: _editPlace,
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.location,
                    color: AppTheme.outline_color,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      placeText.isEmpty ? '장소 선택 (선택)' : placeText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: placeText.isEmpty
                            ? AppTheme.outline_color
                            : AppTheme.on_surface_color,
                        fontSize: 19,
                        fontWeight: FontWeight.w400,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const Icon(
                    CupertinoIcons.chevron_forward,
                    color: AppTheme.outline_color,
                    size: 20,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '메모 (선택)',
              style: TextStyle(
                color: AppTheme.on_surface_variant_color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            CupertinoTextField(
              controller: _memoController,
              placeholder: '메모를 입력하세요',
              minLines: 4,
              maxLines: 6,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface_container_low_color,
                borderRadius: AppTheme.input_border_radius,
              ),
              style: const TextStyle(
                color: AppTheme.on_surface_color,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
              placeholderStyle: const TextStyle(
                color: AppTheme.outline_color,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    return _buildSection(
      title: '일시',
      child: _buildFormCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.clock,
                    color: AppTheme.outline_color,
                    size: 28,
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      '종일',
                      style: TextStyle(
                        color: AppTheme.on_surface_color,
                        fontSize: 19,
                        fontWeight: FontWeight.w500,
                        height: 1.25,
                      ),
                    ),
                  ),
                  CupertinoSwitch(
                    value: _allDay,
                    onChanged: (value) {
                      setState(() {
                        _allDay = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            _buildDivider(),
            _buildDateTimeRow(
              label: '시작',
              date: _startDate,
              time: _startTime,
              onDateTap: () => _selectDate(isStartDate: true),
              onTimeTap: () => _selectTime(isStartTime: true),
            ),
            _buildDivider(),
            _buildDateTimeRow(
              label: '종료',
              date: _endDate,
              time: _endTime,
              onDateTap: () => _selectDate(isStartDate: false),
              onTimeTap: () => _selectTime(isStartTime: false),
            ),
            _buildDivider(),
            _buildRepeatRow(),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(height: 0.5, color: AppTheme.outline_variant_color);
  }

  Widget _buildDateTimeRow({
    required String label,
    required DateTime date,
    required Duration time,
    required VoidCallback onDateTap,
    required VoidCallback onTimeTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              alignment: Alignment.centerLeft,
              onPressed: onDateTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppTheme.on_surface_variant_color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDisplayDate(date),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.on_surface_color,
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!_allDay) ...[
            const SizedBox(width: 12),
            CupertinoButton(
              minimumSize: Size.zero,
              padding: EdgeInsets.zero,
              onPressed: onTimeTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.surface_container_low_color,
                  borderRadius: AppTheme.input_border_radius,
                ),
                child: Text(
                  _formatDisplayTime(time),
                  style: const TextStyle(
                    color: AppTheme.primary_color,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRepeatRow() {
    return CupertinoButton(
      minimumSize: Size.zero,
      padding: EdgeInsets.zero,
      onPressed: _showRepeatInfo,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        child: Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '반복',
                    style: TextStyle(
                      color: AppTheme.on_surface_variant_color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '안 함',
                    style: TextStyle(
                      color: AppTheme.on_surface_color,
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.surface_container_low_color,
                borderRadius: AppTheme.input_border_radius,
              ),
              child: const Text(
                '안 함',
                style: TextStyle(
                  color: AppTheme.primary_color,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              CupertinoIcons.chevron_forward,
              color: AppTheme.outline_color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _updateVisibilityLevelFromPosition({
    required Offset localPosition,
    required double trackWidth,
  }) {
    if (trackWidth <= 0) return;

    final clampedX = localPosition.dx.clamp(0.0, trackWidth).toDouble();
    final segmentWidth = trackWidth / 6;
    final nextLevel = (clampedX / segmentWidth).floor().clamp(0, 5).toInt();

    if (nextLevel == _visibilityLevel) return;

    setState(() {
      _visibilityLevel = nextLevel;
    });
  }

  Widget _buildVisibilityLevelSelector() {
    const selectorHeight = 56.0;
    const selectorPadding = 4.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final innerWidth = trackWidth - (selectorPadding * 2);
        final segmentWidth = innerWidth <= 0 ? 0.0 : innerWidth / 6;
        final indicatorLeft =
            selectorPadding + (segmentWidth * _visibilityLevel);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _updateVisibilityLevelFromPosition(
              localPosition: details.localPosition,
              trackWidth: trackWidth,
            );
          },
          onHorizontalDragStart: (details) {
            _updateVisibilityLevelFromPosition(
              localPosition: details.localPosition,
              trackWidth: trackWidth,
            );
          },
          onHorizontalDragUpdate: (details) {
            _updateVisibilityLevelFromPosition(
              localPosition: details.localPosition,
              trackWidth: trackWidth,
            );
          },
          child: Container(
            height: selectorHeight,
            decoration: BoxDecoration(
              color: AppTheme.surface_container_color,
              borderRadius: AppTheme.input_border_radius,
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  top: selectorPadding,
                  bottom: selectorPadding,
                  left: indicatorLeft,
                  width: segmentWidth,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.primary_color,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: selectorPadding,
                  ),
                  child: Row(
                    children: [
                      for (int level = 0; level <= 5; level++)
                        Expanded(
                          child: Center(
                            child: Text(
                              '$level',
                              style: TextStyle(
                                color: level == _visibilityLevel
                                    ? CupertinoColors.white
                                    : AppTheme.on_surface_color,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ),
                    ],
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
    return _buildSection(
      title: '공개 설정',
      child: _buildFormCard(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '공개 레벨 설정 (0~5)',
              style: TextStyle(
                color: AppTheme.outline_color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 14),
            _buildVisibilityLevelSelector(),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  CupertinoIcons.info_circle,
                  color: AppTheme.on_surface_variant_color,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _visibilityDescription(),
                    style: const TextStyle(
                      color: AppTheme.on_surface_variant_color,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
