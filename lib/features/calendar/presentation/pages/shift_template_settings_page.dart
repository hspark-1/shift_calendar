// ignore_for_file: non_constant_identifier_names

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
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
  static const int _maxShiftTypes = 10;

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
    if (state.shiftTypes.length >= _maxShiftTypes) {
      _showErrorDialog('근무 타입은 최대 $_maxShiftTypes개까지 설정할 수 있습니다.');
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
      final updated_shift_type = await ref
          .read(shiftTemplateSettingsProvider.notifier)
          .updateShiftType(shiftType.shiftTypeId, result);

      if (mounted) {
        if (updated_shift_type != null) {
          ref
              .read(shiftTypeDisplayUpdatesProvider.notifier)
              .applyUpdate(
                previous_type: shiftType,
                updated_type: updated_shift_type,
              );
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(shiftTemplateSettingsProvider);
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;
    final showsShiftTypeList =
        !(state.is_loading && state.shiftTypes.isEmpty) &&
        !(state.error != null && state.shiftTypes.isEmpty);
    final hasReachedMaxShiftTypes = state.shiftTypes.length >= _maxShiftTypes;

    return CupertinoPageScaffold(
      backgroundColor: AppTheme.background_color,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: AppTheme.background_color,
        border: const Border(
          bottom: BorderSide(color: AppTheme.outline_variant_color, width: 1),
        ),
        middle: Text(
          '근무 패턴 설정',
          style: AppTheme.heading_small.copyWith(
            color: AppTheme.on_surface_color,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: state.is_loading && state.shiftTypes.isEmpty
                  ? const Center(child: CupertinoActivityIndicator())
                  : state.error != null && state.shiftTypes.isEmpty
                  ? _buildErrorState(state.error)
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                      children: [
                        _buildShiftTypeHeader(state.shiftTypes.length),
                        const SizedBox(height: 10),
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
            if (showsShiftTypeList)
              Padding(
                padding: EdgeInsets.fromLTRB(16, 12, 16, bottomSafeArea + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildAddButton(state),
                    if (hasReachedMaxShiftTypes) ...[
                      const SizedBox(height: 10),
                      Text(
                        '근무 타입은 최대 $_maxShiftTypes개까지 설정할 수 있습니다.\n기존 타입을 삭제하면 다시 추가할 수 있어요.',
                        style: AppTheme.body_small.copyWith(
                          color: AppTheme.on_surface_variant_color,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(dynamic error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _getErrorMessage(error),
              style: const TextStyle(color: CupertinoColors.destructiveRed),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CupertinoButton(
              onPressed: () {
                ref.read(shiftTemplateSettingsProvider.notifier).loadData();
              },
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTypeHeader(int count) {
    return Row(
      children: [
        Text(
          '근무 타입',
          style: AppTheme.body_large.copyWith(
            color: AppTheme.on_surface_variant_color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primary_color,
            borderRadius: BorderRadius.circular(AppTheme.chip_radius),
          ),
          child: Text(
            '$count개 설정됨',
            style: AppTheme.body_small.copyWith(
              color: AppTheme.surface_color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(ShiftTemplateSettingsState state) {
    final isDisabled =
        state.is_loading || state.shiftTypes.length >= _maxShiftTypes;
    final backgroundColor = isDisabled
        ? AppTheme.surface_container_highest_color
        : AppTheme.primary_dark_color;
    final foregroundColor = isDisabled
        ? AppTheme.on_surface_variant_color
        : AppTheme.surface_color;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      color: backgroundColor,
      disabledColor: AppTheme.surface_container_highest_color,
      borderRadius: BorderRadius.circular(AppTheme.card_radius),
      onPressed: isDisabled ? null : _addShiftType,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.add, size: 30, color: foregroundColor),
            const SizedBox(width: 12),
            Text(
              '근무 타입 추가',
              style: AppTheme.body_large.copyWith(
                color: foregroundColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
