// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/group_providers.dart';
import '../../domain/entities/group_models.dart';
import '../widgets/group_timezone_picker.dart';

class GroupEditPage extends ConsumerStatefulWidget {
  const GroupEditPage({super.key, required this.group});

  final GroupDetail group;

  @override
  ConsumerState<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends ConsumerState<GroupEditPage> {
  late final TextEditingController _name_controller;
  late String _selected_timezone;
  String? _name_error;
  bool _is_saving = false;

  @override
  void initState() {
    super.initState();
    _name_controller = TextEditingController(text: widget.group.name);
    _selected_timezone = widget.group.timezone;
  }

  @override
  void dispose() {
    _name_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupDetailProvider(widget.group.group_id));
    return PopScope(
      canPop: !_is_saving,
      child: CupertinoPageScaffold(
        backgroundColor: AppTheme.background_color,
        navigationBar: CupertinoNavigationBar(
          middle: const Text('그룹 정보 수정'),
          trailing: CupertinoButton(
            key: const ValueKey('group-edit-submit-button'),
            padding: EdgeInsets.zero,
            onPressed: _is_saving || state.is_loading ? null : _submit,
            child: _is_saving || state.is_loading
                ? const CupertinoActivityIndicator()
                : const Text('저장'),
          ),
        ),
        child: SafeArea(
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AppTheme.cardDecoration(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('그룹 이름', style: AppTheme.body_medium),
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      key: const ValueKey('group-edit-name-field'),
                      controller: _name_controller,
                      enabled: !_is_saving,
                      maxLength: 50,
                      placeholder: '그룹 이름을 입력하세요',
                      style: AppTheme.body_large,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surface_container_low_color,
                        borderRadius: AppTheme.input_border_radius,
                      ),
                    ),
                    if (_name_error != null)
                      Text(
                        _name_error!,
                        style: AppTheme.body_medium.copyWith(
                          color: AppTheme.accent_red_color,
                        ),
                      ),
                    const SizedBox(height: 24),
                    Text('시간대', style: AppTheme.body_medium),
                    const SizedBox(height: 8),
                    CupertinoButton(
                      key: const ValueKey('group-edit-timezone-field'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      color: AppTheme.surface_container_low_color,
                      borderRadius: AppTheme.input_border_radius,
                      onPressed: _is_saving ? null : _selectTimezone,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              groupTimezoneLabel(_selected_timezone),
                              style: AppTheme.body_large,
                            ),
                          ),
                          const Icon(CupertinoIcons.chevron_right, size: 18),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '캘린더 날짜와 이벤트 시간은 이 시간대를 기준으로 표시됩니다.',
                      style: AppTheme.body_medium.copyWith(
                        color: AppTheme.on_surface_variant_color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectTimezone() async {
    final selected = await Navigator.of(context).push<String>(
      CupertinoPageRoute(
        builder: (_) =>
            GroupTimezonePicker(selected_timezone: _selected_timezone),
      ),
    );
    if (mounted && selected != null) {
      setState(() => _selected_timezone = selected);
    }
  }

  Future<void> _submit() async {
    if (_is_saving) return;
    final name = _name_controller.text.trim();
    final timezone = _selected_timezone;
    if (name.isEmpty || timezone.isEmpty) {
      setState(() => _name_error = '그룹 이름을 입력해주세요.');
      return;
    }
    setState(() {
      _is_saving = true;
      _name_error = null;
    });
    final success = await ref
        .read(groupDetailProvider(widget.group.group_id).notifier)
        .updateGroup(name: name, timezone: timezone);
    if (!mounted) return;
    if (!success) {
      final error = ref.read(groupDetailProvider(widget.group.group_id)).error;
      if (error is ApiException && error.code == 'GROUP_PERMISSION_DENIED') {
        await ref
            .read(groupDetailProvider(widget.group.group_id).notifier)
            .load();
        if (!mounted) return;
      }
      setState(() => _is_saving = false);
      _showError(error is ApiException ? error.message : '그룹 정보를 수정하지 못했습니다.');
      return;
    }
    await ref.read(groupListProvider.notifier).loadGroups();
    if (!mounted) return;
    setState(() => _is_saving = false);
    Navigator.of(context).pop(true);
  }

  void _showError(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('확인'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}
