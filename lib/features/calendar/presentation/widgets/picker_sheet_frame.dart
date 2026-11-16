// ignore_for_file: non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import '../../../../core/theme/app_theme.dart';

/// 피커 본문의 최상단 끌기를 시트 이동에 연결하고 하단 액션은 고정한다.
class PickerSheetFrame extends StatefulWidget {
  const PickerSheetFrame({
    super.key,
    required this.key_prefix,
    required this.height,
    required this.body,
    required this.footer,
    required this.onDismiss,
  });

  final String key_prefix;
  final double height;
  final Widget body;
  final Widget footer;
  final VoidCallback onDismiss;

  @override
  State<PickerSheetFrame> createState() => _PickerSheetFrameState();
}

class _PickerSheetFrameState extends State<PickerSheetFrame> {
  final _scroll_controller = ScrollController();
  double _drag_offset = 0;
  double? _handle_start_y;
  bool _dragging = false;
  bool _body_dragging = false;
  bool _dismissing = false;

  @override
  void dispose() {
    _scroll_controller.dispose();
    super.dispose();
  }

  void _finishDrag() {
    if (_dismissing) return;
    if (_drag_offset >= 120) {
      _dismissing = true;
      widget.onDismiss();
      return;
    }
    _restorePosition();
  }

  void _restorePosition() {
    if (_dismissing) return;
    setState(() {
      _drag_offset = 0;
      _dragging = false;
      _body_dragging = false;
      _handle_start_y = null;
    });
  }

  bool _handleScroll(ScrollNotification notification) {
    if (_dismissing ||
        notification.depth != 0 ||
        notification.metrics.axis != Axis.vertical) {
      return false;
    }
    if (notification is OverscrollNotification &&
        notification.dragDetails != null &&
        notification.overscroll < 0 &&
        notification.metrics.pixels <= notification.metrics.minScrollExtent) {
      setState(() {
        _dragging = true;
        _body_dragging = true;
        _drag_offset = (_drag_offset - notification.overscroll).clamp(0, 180);
      });
    } else if (notification is ScrollUpdateNotification &&
        notification.dragDetails != null &&
        _body_dragging &&
        _drag_offset > 0 &&
        (notification.scrollDelta ?? 0) > 0) {
      setState(() {
        _drag_offset = (_drag_offset - notification.scrollDelta!).clamp(0, 180);
      });
    } else if (notification is ScrollEndNotification && _body_dragging) {
      _finishDrag();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return AnimatedContainer(
      duration: _dragging || media.disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 180),
      transform: Matrix4.translationValues(0, _drag_offset, 0),
      constraints: const BoxConstraints(maxWidth: 560),
      child: SizedBox(
        key: ValueKey('${widget.key_prefix}-sheet'),
        width: double.infinity,
        height: math.min(
          widget.height,
          math.max(0, media.size.height - media.padding.top - 12),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: ColoredBox(
            color: AppTheme.surface_color,
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  GestureDetector(
                    key: ValueKey('${widget.key_prefix}-handle'),
                    behavior: HitTestBehavior.opaque,
                    onVerticalDragDown: (details) =>
                        _handle_start_y = details.globalPosition.dy,
                    onVerticalDragStart: (details) => setState(() {
                      _dragging = true;
                      _drag_offset =
                          (details.globalPosition.dy -
                                  (_handle_start_y ??
                                      details.globalPosition.dy))
                              .clamp(0, 180);
                    }),
                    onVerticalDragUpdate: (details) => setState(() {
                      _drag_offset = (_drag_offset + details.delta.dy).clamp(
                        0,
                        180,
                      );
                    }),
                    onVerticalDragEnd: (_) => _finishDrag(),
                    onVerticalDragCancel: () {
                      if (_dragging) _restorePosition();
                    },
                    child: SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: Center(
                        child: ExcludeSemantics(
                          child: Container(
                            width: 38,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppTheme.outline_variant_color,
                              borderRadius: AppTheme.input_border_radius,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: _handleScroll,
                      child: SingleChildScrollView(
                        key: ValueKey('${widget.key_prefix}-scroll'),
                        controller: _scroll_controller,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: ClampingScrollPhysics(),
                        ),
                        child: widget.body,
                      ),
                    ),
                  ),
                  widget.footer,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
