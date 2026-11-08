// ignore_for_file: non_constant_identifier_names

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../application/app_update_controller.dart';

typedef UpdateUrlLauncher = Future<bool> Function(Uri url);

Future<bool> openUpdateStore(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

/// Navigator 전체를 감싸 깊은 화면·다이얼로그 위에서도 구버전 이용을 막는다.
class AppUpdateGate extends ConsumerStatefulWidget {
  final Widget child;
  final UpdateUrlLauncher launch_update_url;

  const AppUpdateGate({
    super.key,
    required this.child,
    this.launch_update_url = openUpdateStore,
  });

  @override
  ConsumerState<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends ConsumerState<AppUpdateGate>
    with WidgetsBindingObserver {
  bool _opening_store = false;
  bool _store_failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(_check);
  }

  Future<void> _check() {
    if (!mounted) return Future<void>.value();
    return ref.read(appUpdateControllerProvider.notifier).check();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_check());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _openStore(Uri url) async {
    if (_opening_store) return;
    setState(() {
      _opening_store = true;
      _store_failed = false;
    });
    var opened = false;
    try {
      opened = await widget.launch_update_url(url);
    } on Object {
      opened = false;
    }
    if (!mounted) return;
    setState(() {
      _opening_store = false;
      _store_failed = !opened;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appUpdateControllerProvider);
    if (!state.initialized) {
      return const ColoredBox(
        color: AppTheme.background_color,
        child: Center(child: CupertinoActivityIndicator()),
      );
    }
    final blocked = state.update_required;
    return Stack(
      fit: StackFit.expand,
      children: [
        Offstage(
          offstage: blocked,
          child: ExcludeFocus(excluding: blocked, child: widget.child),
        ),
        if (blocked)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              child: CupertinoPageScaffold(
                backgroundColor: AppTheme.background_color,
                child: SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTheme.spacing_lg),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight - AppTheme.spacing_lg * 2,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Icon(
                                CupertinoIcons.arrow_down_circle,
                                color: AppTheme.primary_color,
                                size: 64,
                              ),
                              const SizedBox(height: AppTheme.spacing_lg),
                              const Text(
                                '업데이트가 필요해요',
                                textAlign: TextAlign.center,
                                style: AppTheme.heading_medium,
                              ),
                              const SizedBox(height: AppTheme.spacing_md),
                              Text(
                                state.policy!.message,
                                textAlign: TextAlign.center,
                                style: AppTheme.body_large,
                              ),
                              const SizedBox(height: AppTheme.spacing_xl),
                              CupertinoButton.filled(
                                onPressed:
                                    _opening_store ||
                                        state.policy!.update_url == null
                                    ? null
                                    : () =>
                                          _openStore(state.policy!.update_url!),
                                child: _opening_store
                                    ? const CupertinoActivityIndicator()
                                    : const Text('업데이트'),
                              ),
                              CupertinoButton(
                                onPressed: state.checking ? null : _check,
                                child: state.checking
                                    ? const CupertinoActivityIndicator()
                                    : const Text('다시 확인'),
                              ),
                              if (state.check_failed || _store_failed)
                                Text(
                                  _store_failed
                                      ? '스토어를 열지 못했어요. 잠시 후 다시 시도해 주세요.'
                                      : '업데이트 정보를 확인하지 못했어요. 네트워크 연결 후 다시 확인해 주세요.',
                                  textAlign: TextAlign.center,
                                  style: AppTheme.body_medium,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
