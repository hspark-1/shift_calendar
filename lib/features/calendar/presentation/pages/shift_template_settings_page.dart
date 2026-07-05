import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/models/shift_type_api_model.dart';
import '../providers/shift_template_settings_provider.dart';
import '../providers/shift_types_provider.dart';
import '../widgets/shift_type_card.dart';
import '../widgets/shift_type_form_modal.dart';

/// 근무 템플릿 설정 페이지
class ShiftTemplateSettingsPage extends ConsumerStatefulWidget {
  const ShiftTemplateSettingsPage({super.key});

  @override
  ConsumerState<ShiftTemplateSettingsPage> createState() =>
      _ShiftTemplateSettingsPageState();
}

class _ShiftTemplateSettingsPageState
    extends ConsumerState<ShiftTemplateSettingsPage> {
  @override
  void initState() {
    super.initState();
    // 페이지 진입 시 데이터 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(shiftTemplateSettingsProvider.notifier).loadData();
    });
  }

  /// 에러 메시지 변환
  String _getErrorMessage(dynamic error) {
    if (error is ApiException) {
      // 서버에서 전달받은 message를 그대로 반환
      return error.message;
    }
    // ApiException이 아닌 경우 기본 메시지 반환
    return '알 수 없는 오류가 발생했습니다.';
  }

  /// 에러 다이얼로그 표시
  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('확인'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// 근무 타입 추가
  Future<void> _addShiftType() async {
    final state = ref.read(shiftTemplateSettingsProvider);

    // 최대 10개 제한 체크
    const maxShiftTypes = 10;
    if (state.shiftTypes.length >= maxShiftTypes) {
      _showErrorDialog('근무 타입은 최대 $maxShiftTypes개까지 설정할 수 있습니다.');
      return;
    }

    final result = await Navigator.push<CreateShiftTypeRequest>(
      context,
      CupertinoPageRoute(
        builder: (context) =>
            ShiftTypeFormModal(existingTypes: state.shiftTypes),
      ),
    );

    if (result != null && mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const CupertinoAlertDialog(content: CupertinoActivityIndicator()),
      );

      final success = await ref
          .read(shiftTemplateSettingsProvider.notifier)
          .createShiftType(result);

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        if (success) {
          // 근무 타입 목록 새로고침
          ref.invalidate(shiftTypesProvider);
        } else {
          final errorState = ref.read(shiftTemplateSettingsProvider);
          _showErrorDialog(_getErrorMessage(errorState.error));
        }
      }
    }
  }

  /// 근무 타입 편집
  Future<void> _editShiftType(ShiftTypeApiModel shiftType) async {
    final state = ref.read(shiftTemplateSettingsProvider);
    final result = await Navigator.push<UpdateShiftTypeRequest>(
      context,
      CupertinoPageRoute(
        builder: (context) => ShiftTypeFormModal(
          shiftType: shiftType,
          existingTypes: state.shiftTypes,
        ),
      ),
    );

    if (result != null && mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const CupertinoAlertDialog(content: CupertinoActivityIndicator()),
      );

      final success = await ref
          .read(shiftTemplateSettingsProvider.notifier)
          .updateShiftType(shiftType.shiftTypeId, result);

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        if (success) {
          // 근무 타입 목록 새로고침
          ref.invalidate(shiftTypesProvider);
        } else {
          final errorState = ref.read(shiftTemplateSettingsProvider);
          _showErrorDialog(_getErrorMessage(errorState.error));
        }
      }
    }
  }

  /// 근무 타입 삭제
  Future<void> _deleteShiftType(ShiftTypeApiModel shiftType) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('삭제 확인'),
        content: Text('${shiftType.name}(${shiftType.code})를 삭제하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('삭제'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const CupertinoAlertDialog(content: CupertinoActivityIndicator()),
      );

      final success = await ref
          .read(shiftTemplateSettingsProvider.notifier)
          .deleteShiftType(shiftType.shiftTypeId);

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        if (success) {
          // 근무 타입 목록 새로고침
          ref.invalidate(shiftTypesProvider);
        } else {
          final errorState = ref.read(shiftTemplateSettingsProvider);
          _showErrorDialog(_getErrorMessage(errorState.error));
        }
      }
    }
  }

  /// 템플릿 이름 변경
  Future<void> _updateTemplateName() async {
    final state = ref.read(shiftTemplateSettingsProvider);
    final currentName = state.templateName ?? '';

    final newName = await showCupertinoDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: currentName);
        return CupertinoAlertDialog(
          title: const Text('템플릿 이름 변경'),
          content: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: CupertinoTextField(
              controller: controller,
              placeholder: '템플릿 이름',
              autofocus: true,
            ),
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('취소'),
              onPressed: () => Navigator.pop(context),
            ),
            CupertinoDialogAction(
              child: const Text('저장'),
              onPressed: () => Navigator.pop(context, controller.text),
            ),
          ],
        );
      },
    );

    if (newName != null && newName.trim().isNotEmpty && mounted) {
      showCupertinoDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) =>
            const CupertinoAlertDialog(content: CupertinoActivityIndicator()),
      );

      final success = await ref
          .read(shiftTemplateSettingsProvider.notifier)
          .updateTemplateName(newName.trim());

      if (mounted) {
        Navigator.pop(context); // 로딩 다이얼로그 닫기
        if (!success) {
          final errorState = ref.read(shiftTemplateSettingsProvider);
          _showErrorDialog(_getErrorMessage(errorState.error));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftTemplateSettingsProvider);

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      child: SafeArea(
        child: state.is_loading && state.shiftTypes.isEmpty
            ? const Center(child: CupertinoActivityIndicator())
            : state.error != null && state.shiftTypes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _getErrorMessage(state.error),
                      style: const TextStyle(
                        color: CupertinoColors.destructiveRed,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CupertinoButton(
                      onPressed: () {
                        ref
                            .read(shiftTemplateSettingsProvider.notifier)
                            .loadData();
                      },
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              )
            : CustomScrollView(
                slivers: [
                  // 템플릿 정보 섹션
                  CupertinoSliverNavigationBar(
                    largeTitle: Text(state.templateName ?? '템플릿'),
                    trailing: state.is_loading
                        ? const CupertinoActivityIndicator()
                        : CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _updateTemplateName,
                            child: const Text('이름 변경'),
                          ),
                    border: null,
                    stretch: true,
                    backgroundColor: CupertinoColors.systemGroupedBackground,
                  ),
                  // SliverToBoxAdapter(
                  //   child: Padding(
                  //     padding: const EdgeInsets.all(16),
                  //     child: Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //         if (state.templateId != null) ...[
                  //           Text(
                  //             '템플릿 ID: ${state.templateId}',
                  //             style: const TextStyle(
                  //               fontSize: 13,
                  //               color: CupertinoColors.tertiaryLabel,
                  //             ),
                  //           ),
                  //           const SizedBox(height: 8),
                  //         ],
                  //       ],
                  //     ),
                  //   ),
                  // ),
                  // 근무 타입 목록
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              '근무 타입',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ...state.shiftTypes.map(
                            (shiftType) => ShiftTypeCard(
                              shiftType: shiftType,
                              onTap: () => _editShiftType(shiftType),
                              onDelete: () => _deleteShiftType(shiftType),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 추가 버튼
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CupertinoButton.filled(
                            onPressed: state.is_loading ? null : _addShiftType,
                            child: const Text('+ 근무 타입 추가'),
                          ),
                          if (state.shiftTypes.length >= 10)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '근무 타입은 최대 10개까지 설정할 수 있습니다.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: CupertinoColors.tertiaryLabel,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
