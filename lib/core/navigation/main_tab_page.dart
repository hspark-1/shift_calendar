// ignore_for_file: non_constant_identifier_names

import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/app_constants.dart';
import '../push/push_providers.dart';
import '../theme/app_theme.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/friend/presentation/pages/friend_list_page.dart';
import '../../features/friend/presentation/pages/notification_page.dart';
import '../../features/friend/presentation/providers/notification_provider.dart';
import '../../features/group/application/group_providers.dart';
import 'app_navigation.dart';

/// 인증 후 세 영역의 UI state와 각각의 탐색 이력을 보존한다.
class MainTabPage extends ConsumerStatefulWidget {
  const MainTabPage({super.key});

  @override
  ConsumerState<MainTabPage> createState() => _MainTabPageState();
}

class _MainTabPageState extends ConsumerState<MainTabPage> {
  final _navigator_keys = List.generate(3, (_) => GlobalKey<NavigatorState>());
  final _visited_tabs = <int>{0};
  int _selected_tab = 0;
  bool _pending_check_scheduled = false;

  @override
  void initState() {
    super.initState();
    rootNavigationObserver.addListener(_schedulePendingNavigation);
    _schedulePendingNavigation();
  }

  @override
  void dispose() {
    rootNavigationObserver.removeListener(_schedulePendingNavigation);
    super.dispose();
  }

  void _schedulePendingNavigation() {
    if (!mounted || _pending_check_scheduled) return;
    _pending_check_scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pending_check_scheduled = false;
      if (!mounted || ModalRoute.of(context)?.isCurrent != true) return;
      final auth_state = ref.read(authProvider);
      if (auth_state.status != AuthStatus.authenticated ||
          auth_state.requires_profile_setup ||
          !ref.read(pendingPushNotificationNavigationProvider)) {
        return;
      }
      ref.read(pendingPushNotificationNavigationProvider.notifier).state =
          false;
      _selectTab(2);
      _navigator_keys[2].currentState?.popUntil((route) => route.isFirst);
    });
  }

  void _selectTab(int index) {
    final was_visited = _visited_tabs.contains(index);
    final previous_tab = _selected_tab;
    setState(() {
      _selected_tab = index;
      _visited_tabs.add(index);
    });
    if (index == 2 && was_visited) {
      ref.read(notificationProvider.notifier).loadNotifications();
      if (AppConstants.group_api_enabled) {
        ref.read(receivedGroupInvitationsProvider.notifier).load(limit: 100);
      }
    } else if (previous_tab == 2 && index != 2) {
      ref.read(notificationProvider.notifier).fetchUnreadCount();
    }
  }

  Widget _buildTab(int index) {
    if (!_visited_tabs.contains(index)) return const SizedBox.shrink();
    return TickerMode(
      enabled: index == _selected_tab,
      child: NavigatorPopHandler<void>(
        enabled: index == _selected_tab,
        onPopWithResult: (_) => _navigator_keys[index].currentState?.pop(),
        child: Navigator(
          key: _navigator_keys[index],
          onGenerateRoute: (_) => CupertinoPageRoute<void>(
            builder: (_) => switch (index) {
              0 => const CalendarPage(),
              1 => const FriendListPage(),
              _ => const NotificationPage(),
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(pendingPushNotificationNavigationProvider, (_, next) {
      if (next) _schedulePendingNavigation();
    });
    final unread_count = ref.watch(unreadNotificationCountProvider);
    return AppTabNavigation(
      selectTab: _selectTab,
      child: ColoredBox(
        color: CupertinoTheme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeBottom: true,
                child: IndexedStack(
                  index: _selected_tab,
                  children: List.generate(3, _buildTab),
                ),
              ),
            ),
            SafeArea(
              top: false,
              minimum: const EdgeInsets.only(bottom: AppTheme.spacing_sm),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: AppTheme.navigation_max_width,
                    ),
                    child: _buildGlassBar(unread_count),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassBar(int unread_count) {
    final high_contrast = MediaQuery.highContrastOf(context);
    final is_dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final surface_color = is_dark
        ? AppTheme.dark_surface_color
        : AppTheme.surface_color;
    final border_radius = BorderRadius.circular(
      AppTheme.navigation_glass_radius,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: border_radius,
        boxShadow: [
          BoxShadow(
            color: AppTheme.on_surface_color.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: border_radius,
        child: BackdropFilter(
          enabled: !high_contrast,
          filter: ui.ImageFilter.blur(
            sigmaX: AppTheme.navigation_glass_blur,
            sigmaY: AppTheme.navigation_glass_blur,
          ),
          child: DecoratedBox(
            key: const ValueKey('main-glass-tab-bar'),
            decoration: BoxDecoration(
              borderRadius: border_radius,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  surface_color.withValues(alpha: high_contrast ? 1 : 0.94),
                  surface_color.withValues(alpha: high_contrast ? 1 : 0.82),
                ],
              ),
              border: Border.all(
                color: AppTheme.outline_variant_color.withValues(
                  alpha: high_contrast ? 1 : 0.55,
                ),
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Row(
                children: [
                  _buildTabButton(0, CupertinoIcons.calendar, '캘린더'),
                  _buildTabButton(1, CupertinoIcons.person_2, '친구'),
                  _buildTabButton(2, CupertinoIcons.bell, '알림', unread_count),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(
    int index,
    IconData icon,
    String label, [
    int badge_count = 0,
  ]) {
    final selected = index == _selected_tab;
    final is_dark = CupertinoTheme.brightnessOf(context) == Brightness.dark;
    final color = AppTheme.readableForegroundColor(
      is_dark ? AppTheme.dark_surface_color : AppTheme.surface_color,
      preferred_color: selected
          ? AppTheme.primary_color
          : AppTheme.on_surface_variant_color,
    );
    return Expanded(
      child: Semantics(
        selected: selected,
        label: badge_count > 0 ? '$label, 읽지 않은 알림 $badge_count개' : label,
        excludeSemantics: true,
        onTap: () => _selectTab(index),
        button: true,
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.10)
                : AppTheme.primary_color.withValues(alpha: 0),
            borderRadius: BorderRadius.circular(24),
          ),
          child: CupertinoButton(
            key: ValueKey('main-tab-$index'),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            minimumSize: const Size(44, 56),
            onPressed: () => _selectTab(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 64,
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      Icon(icon, size: 24, color: color),
                      if (badge_count > 0)
                        Positioned(
                          top: -3,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.error_text_color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              badge_count > 99 ? '99+' : '$badge_count',
                              textScaler: MediaQuery.textScalerOf(
                                context,
                              ).clamp(maxScaleFactor: 1.2),
                              style: AppTheme.body_small.copyWith(
                                color: AppTheme.surface_color,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: AppTheme.body_small.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
