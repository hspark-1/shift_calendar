import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
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
              : AppTheme.surface_color,
          shape: BoxShape.circle,
          border: Border.all(
            color: is_selected ? color : AppTheme.outline_variant_color,
            width: is_selected ? 2.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              shiftInfo.name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: is_selected ? FontWeight.bold : FontWeight.w500,
                color: is_selected ? color : AppTheme.on_surface_color,
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
    const maxItemsPerRow = 5;
    const buttonWidth = 64.0;

    // 버튼들을 5개씩 나누어서 행으로 구성
    final List<List<String>> rows = [];
    for (int i = 0; i < shiftTypeOrder.length; i += maxItemsPerRow) {
      rows.add(
        shiftTypeOrder.sublist(
          i,
          i + maxItemsPerRow > shiftTypeOrder.length
              ? shiftTypeOrder.length
              : i + maxItemsPerRow,
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        // Container의 padding을 고려한 실제 사용 가능한 너비
        final availableWidth = constraints.maxWidth - 16; // 좌우 padding 8*2

        // 첫 번째 줄의 간격 계산 (spaceEvenly 기준)
        // spaceEvenly는 각 버튼 사이의 간격과 양쪽 여백을 모두 동일하게 만듭니다
        double? firstRowSpacing;
        double? firstRowStartOffset;
        if (rows.isNotEmpty && rows[0].isNotEmpty) {
          final totalButtonWidth = rows[0].length * buttonWidth;
          // spaceEvenly: 양쪽 여백과 버튼 사이 간격이 모두 동일
          // 간격 = (전체 너비 - 버튼 너비 합) / (버튼 개수 + 1)
          firstRowSpacing =
              (availableWidth - totalButtonWidth) / (rows[0].length + 1);
          // 첫 번째 버튼의 시작 위치는 첫 번째 간격만큼
          firstRowStartOffset = firstRowSpacing;
        }

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: rows.asMap().entries.map((entry) {
              final index = entry.key;
              final row = entry.value;
              final isLastRow = index == rows.length - 1;
              final isFirstRow = index == 0;

              return Padding(
                padding: EdgeInsets.only(bottom: isLastRow ? 0 : 8),
                child: Row(
                  mainAxisAlignment: isFirstRow
                      ? MainAxisAlignment.spaceEvenly
                      : MainAxisAlignment.start,
                  children: row.asMap().entries.map((buttonEntry) {
                    final buttonIndex = buttonEntry.key;
                    final code = buttonEntry.value;

                    // 두 번째 줄 이상일 때 첫 번째 줄과 동일한 간격 적용
                    if (!isFirstRow &&
                        firstRowSpacing != null &&
                        firstRowStartOffset != null) {
                      return Padding(
                        padding: EdgeInsets.only(
                          left: buttonIndex == 0
                              ? firstRowStartOffset
                              : firstRowSpacing,
                        ),
                        child: ShiftTypeButton(
                          shift_code: code,
                          is_selected: selected_shift == code,
                          onTap: () => onShiftSelected(code),
                        ),
                      );
                    }

                    return ShiftTypeButton(
                      shift_code: code,
                      is_selected: selected_shift == code,
                      onTap: () => onShiftSelected(code),
                    );
                  }).toList(),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}
