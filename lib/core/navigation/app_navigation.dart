// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';

/// 루트의 전체 화면 폼/대화상자가 닫히면 보류한 탭 이동을 재평가한다.
class AppRouteObserver extends NavigatorObserver with ChangeNotifier {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    notifyListeners();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    notifyListeners();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    notifyListeners();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    notifyListeners();
  }
}

final rootNavigationObserver = AppRouteObserver();

enum FriendTabSection { friends, groups }

/// 탐색 화면에서 최상위 탭으로 이동할 때 route를 중복 push하지 않는다.
class AppTabNavigation extends InheritedWidget {
  const AppTabNavigation({
    super.key,
    required this.selectTab,
    required this.onOpenFriends,
    required super.child,
  });

  final ValueChanged<int> selectTab;
  final void Function(FriendTabSection section, WidgetBuilder? detail_builder)
  onOpenFriends;

  /// 목록을 목적지로 선택하고 상세 화면도 친구 탭의 탐색 이력에 추가한다.
  void openFriends({
    FriendTabSection section = FriendTabSection.friends,
    WidgetBuilder? detail_builder,
  }) => onOpenFriends(section, detail_builder);

  static AppTabNavigation? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppTabNavigation>();

  @override
  bool updateShouldNotify(AppTabNavigation oldWidget) => false;
}
