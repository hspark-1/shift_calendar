// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
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
    final color = shiftInfo?.color ?? AppTheme.outline_color;
    final label = shiftInfo?.name ?? shift_type;

    if (show_label) {
      final background_color = color.withValues(alpha: 0.2);

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: background_color,
          borderRadius: BorderRadius.circular(AppTheme.chip_radius),
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
                color: AppTheme.readableForegroundColor(
                  background_color,
                  preferred_color: color,
                ),
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
