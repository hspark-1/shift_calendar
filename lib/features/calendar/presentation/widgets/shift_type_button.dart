import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shift_types_provider.dart';

/// 근무 유형 선택 버튼 위젯
class ShiftTypeButton extends ConsumerWidget {
  const ShiftTypeButton({
    super.key,
    required this.shift_code,
    this.is_selected = false,
    this.onTap,
  });

  final String shift_code;
  final bool is_selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftTypesMap = ref.watch(shiftTypesMapProvider);
    final shiftInfo = shiftTypesMap[shift_code];
    if (shiftInfo == null) return const SizedBox.shrink();

    final color = shiftInfo.color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: is_selected
              ? color.withValues(alpha: 0.2)
              : CupertinoColors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: is_selected ? color : CupertinoColors.systemGrey4,
            width: is_selected ? 2.5 : 1,
          ),
          boxShadow: is_selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              shiftInfo.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: is_selected ? FontWeight.bold : FontWeight.w500,
                color: is_selected ? color : CupertinoColors.label,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 근무 유형 버튼 그룹 위젯
class ShiftTypeButtonGroup extends ConsumerWidget {
  const ShiftTypeButtonGroup({
    super.key,
    this.selected_shift,
    required this.onShiftSelected,
  });

  final String? selected_shift;
  final Function(String) onShiftSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftTypeOrder = ref.watch(shiftTypeOrderProvider);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: shiftTypeOrder.map((code) {
          return ShiftTypeButton(
            shift_code: code,
            is_selected: selected_shift == code,
            onTap: () => onShiftSelected(code),
          );
        }).toList(),
      ),
    );
  }
}
