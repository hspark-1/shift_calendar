import 'package:flutter/cupertino.dart';
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
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // 색상 표시
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: shiftType.colorValue ?? CupertinoColors.systemGrey,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 16),
            // 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        shiftType.code,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        shiftType.name,
                        style: const TextStyle(
                          fontSize: 17,
                          color: CupertinoColors.secondaryLabel,
                        ),
                      ),
                    ],
                  ),
                  if (shiftType.startTime != null &&
                      shiftType.endTime != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${shiftType.startTimeDisplay} - ${shiftType.endTimeDisplay}',
                      style: const TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                    ),
                  ] else if (shiftType.startTime == null &&
                      shiftType.endTime == null) ...[
                    const SizedBox(height: 4),
                    const Text(
                      '시간 없음',
                      style: TextStyle(
                        fontSize: 15,
                        color: CupertinoColors.tertiaryLabel,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // 삭제 버튼
            if (onDelete != null)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onDelete,
                minimumSize: Size(0, 0),
                child: const Icon(
                  CupertinoIcons.delete,
                  color: CupertinoColors.destructiveRed,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
