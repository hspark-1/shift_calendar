// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'package:home_widget/home_widget.dart';

abstract interface class HomeWidgetStore {
  Future<String?> read();
  Future<void> write(String? snapshot);
  Future<void> reload();
}

class IosHomeWidgetStore implements HomeWidgetStore {
  static const app_group = 'group.com.hspark.shiftmate';
  static const snapshot_key = 'shiftmate_widget_snapshot_v1';
  static const widget_kind = 'ShiftMateShiftWidget';
  static const tomorrow_widget_kind = 'ShiftMateTomorrowShiftWidget';
  static const widget_kinds = [widget_kind, tomorrow_widget_kind];

  @override
  Future<String?> read() =>
      HomeWidget.getWidgetData<String>(snapshot_key, appGroupId: app_group);

  @override
  Future<void> write(String? snapshot) async {
    final saved = await HomeWidget.saveWidgetData<String>(
      snapshot_key,
      snapshot,
      deleteFile: false,
      appGroupId: app_group,
    );
    if (saved != true) throw StateError('위젯 데이터 저장 실패');
  }

  @override
  Future<void> reload() async {
    var failed = false;
    for (final kind in widget_kinds) {
      try {
        if (await HomeWidget.updateWidget(iOSName: kind) != true) failed = true;
      } catch (_) {
        failed = true;
      }
    }
    if (failed) throw StateError('위젯 갱신 요청 실패');
  }
}
