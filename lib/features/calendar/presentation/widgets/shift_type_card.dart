import 'package:flutter/cupertino.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/shift_type_api_model.dart';

/// 근무 타입 카드 위젯
class ShiftTypeCard extends StatelessWidget {
  final ShiftTypeApiModel shiftType;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const ShiftTypeCard({
    super.key,
    required this.shiftType,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface_color,
          borderRadius: AppTheme.card_border_radius,
          border: Border.all(
            color: AppTheme.outline_variant_color.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: shiftType.colorValue ?? CupertinoColors.systemGrey,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: CupertinoColors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: Text(
                    shiftType.code,
                    style: AppTheme.body_large.copyWith(
                      color: AppTheme.surface_color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shiftType.name,
                    style: AppTheme.body_large.copyWith(
                      color: AppTheme.on_surface_color,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (shiftType.startTime != null &&
                      shiftType.endTime != null) ...[
                    const SizedBox(height: 2),
                    _ShiftTypeTimeRow(
                      icon: CupertinoIcons.clock,
                      text:
                          '${shiftType.startTimeDisplay} - ${shiftType.endTimeDisplay}',
                    ),
                  ] else if (shiftType.startTime == null &&
                      shiftType.endTime == null) ...[
                    const SizedBox(height: 2),
                    const _ShiftTypeTimeRow(
                      icon: CupertinoIcons.calendar_badge_minus,
                      text: '시간 없음',
                      isItalic: true,
                    ),
                  ],
                ],
              ),
            ),
            if (onDelete != null)
              CupertinoButton(
                padding: const EdgeInsets.all(4),
                onPressed: onDelete,
                minimumSize: const Size(32, 32),
                child: const Icon(
                  CupertinoIcons.trash,
                  color: AppTheme.outline_color,
                  size: 22,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ShiftTypeTimeRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isItalic;

  const _ShiftTypeTimeRow({
    required this.icon,
    required this.text,
    this.isItalic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.on_surface_variant_color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: AppTheme.body_medium.copyWith(
              color: AppTheme.on_surface_variant_color,
              fontWeight: FontWeight.w600,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
