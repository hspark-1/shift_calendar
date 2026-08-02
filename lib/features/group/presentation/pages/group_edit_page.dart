// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../application/group_providers.dart';
import '../../domain/entities/group_models.dart';

class GroupEditPage extends ConsumerStatefulWidget {
  const GroupEditPage({super.key, required this.group});

  final GroupDetail group;

  @override
  ConsumerState<GroupEditPage> createState() => _GroupEditPageState();
}

class _GroupEditPageState extends ConsumerState<GroupEditPage> {
  late final TextEditingController _name_controller;
  late final TextEditingController _timezone_controller;

  @override
  void initState() {
    super.initState();
    _name_controller = TextEditingController(text: widget.group.name);
    _timezone_controller = TextEditingController(text: widget.group.timezone);
  }

  @override
  void dispose() {
    _name_controller.dispose();
    _timezone_controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(groupDetailProvider(widget.group.group_id));
    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        middle: const Text('그룹 정보 수정'),
        trailing: CupertinoButton(
          key: const ValueKey('group-edit-submit-button'),
          padding: EdgeInsets.zero,
          onPressed: state.is_loading ? null : _submit,
          child: state.is_loading
              ? const CupertinoActivityIndicator()
              : const Text('저장'),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing_md),
          children: [
            Text('그룹 이름', style: AppTheme.body_small),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: const ValueKey('group-edit-name-field'),
              controller: _name_controller,
              maxLength: 50,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: AppTheme.spacing_md),
            Text('IANA 시간대', style: AppTheme.body_small),
            const SizedBox(height: 6),
            CupertinoTextField(
              key: const ValueKey('group-edit-timezone-field'),
              controller: _timezone_controller,
              placeholder: 'Asia/Seoul',
              autocorrect: false,
              padding: const EdgeInsets.all(12),
            ),
            const SizedBox(height: 8),
            Text(
              '캘린더 날짜와 이벤트 시간은 이 시간대를 기준으로 표시됩니다.',
              style: AppTheme.body_small.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final name = _name_controller.text.trim();
    final timezone = _timezone_controller.text.trim();
    if (name.isEmpty || timezone.isEmpty) {
      _showError('그룹 이름과 시간대를 모두 입력해주세요.');
      return;
    }
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
      _showError(error is ApiException ? error.message : '그룹 정보를 수정하지 못했습니다.');
      return;
    }
    await ref.read(groupListProvider.notifier).loadGroups();
    if (!mounted) return;
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
