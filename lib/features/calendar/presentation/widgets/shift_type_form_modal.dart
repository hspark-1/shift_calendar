import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../data/models/shift_type_api_model.dart';

/// 근무 타입 추가/편집 모달
class ShiftTypeFormModal extends StatefulWidget {
  final ShiftTypeApiModel? shiftType; // null이면 추가, 있으면 편집
  final List<ShiftTypeApiModel> existingTypes; // 코드 중복 체크용

  const ShiftTypeFormModal({
    super.key,
    this.shiftType,
    required this.existingTypes,
  });

  @override
  State<ShiftTypeFormModal> createState() => _ShiftTypeFormModalState();
}

class _ShiftTypeFormModalState extends State<ShiftTypeFormModal> {
  late TextEditingController _codeController;
  late TextEditingController _nameController;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  Color _selectedColor = CupertinoColors.systemBlue;

  @override
  void initState() {
    super.initState();
    final shiftType = widget.shiftType;
    _codeController = TextEditingController(text: shiftType?.code ?? '');
    _nameController = TextEditingController(text: shiftType?.name ?? '');

    if (shiftType != null) {
      if (shiftType.color != null) {
        _selectedColor = Color(shiftType.color!);
      }
      if (shiftType.startTime != null) {
        final parts = shiftType.startTime!.split(':');
        _startTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      if (shiftType.endTime != null) {
        final parts = shiftType.endTime!.split(':');
        _endTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    }

    // 코드 입력 시 대문자 변환
    _codeController.addListener(() {
      final text = _codeController.text.toUpperCase();
      if (_codeController.text != text) {
        _codeController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  /// TimeOfDay를 "HH:mm:ss" 형식으로 변환
  String _timeOfDayToTimeString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}:00';
  }

  /// TimeOfDay를 "HH:mm" 형식으로 표시
  String _timeOfDayToDisplayString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  /// 색상 선택
  Future<void> _selectColor() async {
    final colors = [
      CupertinoColors.systemBlue,
      CupertinoColors.systemGreen,
      CupertinoColors.systemOrange,
      const Color(0xFFF5A623), // 오렌지
      CupertinoColors.systemRed,
      CupertinoColors.systemPurple,
      CupertinoColors.systemYellow,
      CupertinoColors.systemTeal,
      CupertinoColors.systemIndigo,
      CupertinoColors.systemPink,
      CupertinoColors.systemGrey,
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('색상 선택'),
        actions: colors.map((color) {
          return CupertinoActionSheetAction(
            onPressed: () {
              setState(() {
                _selectedColor = color;
              });
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: _selectedColor == color
                    ? Border.all(color: CupertinoColors.systemBlue, width: 3)
                    : null,
              ),
            ),
          );
        }).toList(),
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
      ),
    );
  }

  /// 시간 선택
  Future<void> _selectTime(bool isStartTime) async {
    final initialTime = isStartTime ? _startTime : _endTime;
    TimeOfDay? selectedTime = initialTime;

    await showCupertinoModalPopup(
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
                  // 헤더
                  Container(
                    height: 44,
                    decoration: const BoxDecoration(
                      color: CupertinoColors.systemGrey6,
                      border: Border(
                        bottom: BorderSide(
                          color: CupertinoColors.separator,
                          width: 0.5,
                        ),
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
                        Text(
                          isStartTime ? '시작시간 선택' : '종료시간 선택',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          onPressed: () {
                            Navigator.pop(context, selectedTime);
                          },
                          child: const Text('확인'),
                        ),
                      ],
                    ),
                  ),
                  // 피커
                  Expanded(
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.time,
                      initialDateTime: DateTime(
                        2024,
                        1,
                        1,
                        initialTime?.hour ?? 0,
                        initialTime?.minute ?? 0,
                      ),
                      use24hFormat: true,
                      onDateTimeChanged: (date) {
                        setModalState(() {
                          selectedTime = TimeOfDay(
                            hour: date.hour,
                            minute: date.minute,
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
    ).then((result) {
      if (result != null && result is TimeOfDay) {
        setState(() {
          if (isStartTime) {
            _startTime = result;
          } else {
            _endTime = result;
          }
        });
      }
    });
  }

  /// 시간 제거
  void _clearTime(bool isStartTime) {
    setState(() {
      if (isStartTime) {
        _startTime = null;
        // 시작시간이 없으면 종료시간도 제거
        if (_endTime != null) {
          _endTime = null;
        }
      } else {
        _endTime = null;
        // 종료시간이 없으면 시작시간도 제거
        if (_startTime != null) {
          _startTime = null;
        }
      }
    });
  }

  /// 유효성 검사
  String? _validate() {
    if (_codeController.text.trim().isEmpty) {
      return '코드를 입력해주세요.';
    }
    if (_nameController.text.trim().isEmpty) {
      return '이름을 입력해주세요.';
    }

    // 코드 중복 체크 (편집 모드에서는 자기 자신 제외)
    final code = _codeController.text.trim().toUpperCase();
    final isDuplicate = widget.existingTypes.any((type) {
      if (widget.shiftType != null &&
          type.shiftTypeId == widget.shiftType!.shiftTypeId) {
        return false; // 자기 자신은 제외
      }
      return type.code.toUpperCase() == code;
    });

    if (isDuplicate) {
      return '이미 사용 중인 코드입니다.';
    }

    // 시간 검증: 둘 다 있거나 둘 다 없어야 함
    if ((_startTime != null && _endTime == null) ||
        (_startTime == null && _endTime != null)) {
      return '시작시간과 종료시간을 모두 입력하거나 모두 비워주세요.';
    }

    return null;
  }

  /// 저장
  void _save() {
    final error = _validate();
    if (error != null) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('입력 오류'),
          content: Text(error),
          actions: [
            CupertinoDialogAction(
              child: const Text('확인'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    final code = _codeController.text.trim().toUpperCase();
    final name = _nameController.text.trim();
    final color = _selectedColor.value;
    final startTime = _startTime != null
        ? _timeOfDayToTimeString(_startTime!)
        : null;
    final endTime = _endTime != null ? _timeOfDayToTimeString(_endTime!) : null;

    if (widget.shiftType == null) {
      // 추가 모드
      Navigator.pop(
        context,
        CreateShiftTypeRequest(
          code: code,
          name: name,
          color: color,
          startTime: startTime,
          endTime: endTime,
        ),
      );
    } else {
      // 편집 모드
      Navigator.pop(
        context,
        UpdateShiftTypeRequest(
          code: code,
          name: name,
          color: color,
          startTime: startTime,
          endTime: endTime,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.shiftType != null;

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(isEdit ? '근무 타입 편집' : '근무 타입 추가'),
        leading: CupertinoNavigationBarBackButton(
          onPressed: () => Navigator.pop(context),
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
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // 입력 폼
            CupertinoListSection.insetGrouped(
              children: [
                // 코드
                CupertinoListTile(
                  title: const Text('코드'),
                  trailing: SizedBox(
                    width: 100,
                    child: CupertinoTextField(
                      controller: _codeController,
                      placeholder: '예: D, E, N',
                      enabled: true,
                      textAlign: TextAlign.right,
                      textCapitalization: TextCapitalization.characters,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                // 이름
                CupertinoListTile(
                  title: const Text('이름'),
                  trailing: SizedBox(
                    width: 100,
                    child: CupertinoTextField(
                      controller: _nameController,
                      placeholder: '예: 데이',
                      textAlign: TextAlign.right,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
                // 색상
                CupertinoListTile(
                  title: const Text('색상'),
                  leading: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '#${_selectedColor.value.toRadixString(16).substring(2).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 15,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const CupertinoListTileChevron(),
                    ],
                  ),
                  onTap: _selectColor,
                ),
                // 시작시간
                CupertinoListTile(
                  title: const Text('시작시간'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_startTime != null)
                        Text(
                          _timeOfDayToDisplayString(_startTime!),
                          style: const TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.label,
                          ),
                        )
                      else
                        const Text(
                          '시간 선택',
                          style: TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.tertiaryLabel,
                          ),
                        ),
                      if (_startTime != null) ...[
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _clearTime(true),
                          minimumSize: Size(0, 0),
                          child: const Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: CupertinoColors.destructiveRed,
                            size: 20,
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Icon(
                        CupertinoIcons.time,
                        size: 20,
                        color: CupertinoColors.systemBlue,
                      ),
                    ],
                  ),
                  onTap: () => _selectTime(true),
                ),
                // 종료시간
                CupertinoListTile(
                  title: const Text('종료시간'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_endTime != null)
                        Text(
                          _timeOfDayToDisplayString(_endTime!),
                          style: const TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.label,
                          ),
                        )
                      else
                        const Text(
                          '시간 선택',
                          style: TextStyle(
                            fontSize: 15,
                            color: CupertinoColors.tertiaryLabel,
                          ),
                        ),
                      if (_endTime != null) ...[
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _clearTime(false),
                          minimumSize: Size(0, 0),
                          child: const Icon(
                            CupertinoIcons.clear_circled_solid,
                            color: CupertinoColors.destructiveRed,
                            size: 20,
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      const Icon(
                        CupertinoIcons.time,
                        size: 20,
                        color: CupertinoColors.systemBlue,
                      ),
                    ],
                  ),
                  onTap: () => _selectTime(false),
                ),
              ],
            ),
            // 안내 텍스트
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Text(
                '시간을 입력하지 않으면 휴가, 오프 등 시간이 없는 타입으로 설정됩니다.',
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.tertiaryLabel.resolveFrom(context),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
