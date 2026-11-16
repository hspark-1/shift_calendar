// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';

/// 선택값의 읽을 공간을 우선하고 빠른 선택 버튼은 통째로 다음 줄로 옮긴다.
class PickerSelectionSummary extends StatelessWidget {
  const PickerSelectionSummary({
    super.key,
    required this.icon,
    required this.value,
    required this.action_label,
    required this.onAction,
  });

  final IconData icon;
  final String value;
  final String action_label;
  final VoidCallback? onAction;

  double _textWidth(BuildContext context, String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: MediaQuery.boldTextOf(context)
            ? style.copyWith(fontWeight: FontWeight.bold)
            : style,
      ),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width.ceilToDouble();
    painter.dispose();
    return width;
  }

  @override
  Widget build(BuildContext context) {
    final value_style = AppTheme.body_large.copyWith(
      fontWeight: FontWeight.w700,
      color: AppTheme.primary_dark_color,
    );
    final action_style = AppTheme.body_large.copyWith(
      color: AppTheme.primary_color,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primary_color.withValues(alpha: 0.08),
        borderRadius: AppTheme.input_border_radius,
        border: Border.all(
          color: AppTheme.primary_color.withValues(alpha: 0.22),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final value_width = _textWidth(context, value, value_style);
          final action_width = math.max(
            48.0,
            _textWidth(context, action_label, action_style) + 24,
          );
          final inline =
              constraints.maxWidth >= 50 + value_width + 12 + action_width;
          final value_text = Text(value, style: value_style);
          final value_widget = constraints.maxWidth >= 50 + value_width
              ? Row(
                  children: [
                    ExcludeSemantics(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: AppTheme.primary_color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          icon,
                          size: 21,
                          color: AppTheme.primary_color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: value_text),
                  ],
                )
              : value_text;
          final action = CupertinoButton(
            minimumSize: const Size(48, 48),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            color: AppTheme.surface_color,
            borderRadius: BorderRadius.circular(AppTheme.chip_radius),
            onPressed: onAction,
            child: Text(action_label, style: action_style),
          );
          return inline
              ? Row(
                  children: [
                    Expanded(child: value_widget),
                    const SizedBox(width: 12),
                    action,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    value_widget,
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: action,
                    ),
                  ],
                );
        },
      ),
    );
  }
}
