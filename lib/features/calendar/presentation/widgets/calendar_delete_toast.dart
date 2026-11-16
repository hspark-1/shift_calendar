// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';

/// 메인 일정 삭제 유예 중 표시하며, 실제 삭제 예약은 페이지가 소유한다.
class CalendarDeleteToast extends StatelessWidget {
  const CalendarDeleteToast({
    super.key,
    required this.count,
    required this.onUndo,
    required this.onDismiss,
  });

  final int count;
  final VoidCallback onUndo;

  /// 알림 표시만 닫으며 페이지의 삭제 예약은 유지한다.
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final background_color = AppTheme.on_surface_color;
    final foreground_color = AppTheme.surface_color;
    final message = count == 1 ? '일정을 삭제했어요.' : '일정 $count개를 삭제했어요.';
    final message_widget = Semantics(
      liveRegion: true,
      child: Text(
        message,
        style: AppTheme.body_medium.copyWith(color: foreground_color),
      ),
    );
    final undo_button = CupertinoButton(
      key: const ValueKey('calendar-delete-undo'),
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onPressed: onUndo,
      child: Text(
        '되돌리기',
        style: AppTheme.body_medium.copyWith(
          color: foreground_color,
          fontWeight: FontWeight.w700,
          decoration: TextDecoration.underline,
          decorationColor: foreground_color,
        ),
      ),
    );

    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Dismissible(
          key: const ValueKey('calendar-delete-toast-swipe'),
          direction: DismissDirection.down,
          resizeDuration: null,
          movementDuration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          dismissThresholds: const {DismissDirection.down: 0.5},
          onDismissed: (_) => onDismiss(),
          child: Semantics(
            key: const ValueKey('calendar-delete-toast-semantics'),
            container: true,
            explicitChildNodes: true,
            label: '일정 삭제 알림',
            onDismiss: onDismiss,
            child: DecoratedBox(
              key: const ValueKey('calendar-delete-toast'),
              decoration: BoxDecoration(
                color: background_color,
                borderRadius: AppTheme.card_border_radius,
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 4, 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 280 ||
                        MediaQuery.textScalerOf(context).scale(14) > 20) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, right: 12),
                            child: message_widget,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: undo_button,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: message_widget),
                        const SizedBox(width: 8),
                        undo_button,
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
