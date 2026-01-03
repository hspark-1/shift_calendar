import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/shift_types_provider.dart';

/// 근무 타입 배지 위젯
class ShiftBadge extends ConsumerWidget {
  const ShiftBadge({
    super.key,
    required this.shift_type,
    this.size = 16,
    this.show_label = false,
  });

  final String shift_type;
  final double size;
  final bool show_label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftTypesMap = ref.watch(shiftTypesMapProvider);
    final shiftInfo = shiftTypesMap[shift_type];
    final color = shiftInfo?.color ?? CupertinoColors.systemGrey;
    final label = shiftInfo?.name ?? shift_type;

    if (show_label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size * 0.6,
              height: size * 0.6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: size * 0.7,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
