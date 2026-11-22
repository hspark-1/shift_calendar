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
    this.bottom_inset = 0,
    required super.child,
  });

  /// 플로팅 탭의 실제 높이와 하단 안전영역을 포함한 콘텐츠 예약 공간.
  final double bottom_inset;

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
  bool updateShouldNotify(AppTabNavigation oldWidget) =>
      bottom_inset != oldWidget.bottom_inset;
}

/// 화면 배경은 전체 route를 채우고, 본문만 플로팅 탭 위에 배치한다.
/// 루트 Navigator에서 단독으로 여는 화면에는 추가 여백을 만들지 않는다.
class AppTabBody extends StatelessWidget {
  const AppTabBody({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(
      bottom: AppTabNavigation.maybeOf(context)?.bottom_inset ?? 0,
    ),
    child: child,
  );
}
