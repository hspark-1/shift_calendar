// ignore_for_file: constant_identifier_names, non_constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/profile_image.dart';
import '../../data/models/friend_model.dart';
import '../providers/friend_provider.dart';

/// 정확히 일치하는 계정 한 명을 확인하고 요청한다. true는 받은 요청 확인이다.
class AddFriendModal extends ConsumerStatefulWidget {
  const AddFriendModal({super.key});

  @override
  ConsumerState<AddFriendModal> createState() => _AddFriendModalState();
}

class _AddFriendModalState extends ConsumerState<AddFriendModal> {
  static const _sheet_radius = BorderRadius.vertical(top: Radius.circular(24));
  final _sheet_key = GlobalKey();
  final _controller = TextEditingController();
  final _focus_node = FocusNode();
  final _sent_user_ids = <String>{};
  bool _is_sending = false;
  bool _is_dragging_sheet = false;
  bool _is_expanded = false;
  double _drag_distance = 0;
  double _sheet_drag_offset = 0;
  String? _validation_message;
  String? _request_error;

  @override
  void initState() {
    super.initState();
    _focus_node.addListener(_handleFocusChange);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(searchUserProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus_node.removeListener(_handleFocusChange);
    _focus_node.dispose();
    super.dispose();
  }

  double get _expandedHeight {
    final media_query = MediaQuery.of(context);
    final keyboard_height = media_query.viewInsets.bottom;
    final max_height =
        (media_query.size.height -
                media_query.viewPadding.top -
                keyboard_height -
                12)
            .clamp(0.0, media_query.size.height)
            .toDouble();
    return keyboard_height > 0
        ? max_height
        : (media_query.size.height * 0.88).clamp(0.0, max_height).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final search_state = ref.watch(searchUserProvider);
    final user = search_state.user;
    final media_query = MediaQuery.of(context);
    final keyboard_height = media_query.viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard_height),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.min(media_query.size.width, 560),
          maxHeight: _expandedHeight,
        ),
        child: _buildSheetTransition(
          animate: !media_query.disableAnimations,
          child: KeyedSubtree(
            key: _sheet_key,
            child: SizedBox(
              key: const ValueKey('add-friend-sheet'),
              width: double.infinity,
              height: _is_expanded ? _expandedHeight : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildDraggableHeader(),
                  Flexible(
                    fit: _is_expanded ? FlexFit.tight : FlexFit.loose,
                    child: SingleChildScrollView(
                      key: const ValueKey('add-friend-content'),
                      padding: EdgeInsets.fromLTRB(
                        24,
                        24,
                        24,
                        24 + media_query.padding.bottom,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSearchInput(),
                          if (user == null &&
                              (_validation_message != null ||
                                  search_state.error != null)) ...[
                            const SizedBox(height: 8),
                            _buildInputMessage(search_state),
                          ],
                          if (user != null) ...[
                            const SizedBox(height: 24),
                            _buildProfile(user),
                          ],
                          if (_request_error != null) ...[
                            const SizedBox(height: 12),
                            _buildError(_request_error!),
                          ],
                          const SizedBox(height: 24),
                          KeyedSubtree(
                            key: const ValueKey('add-friend-primary-action'),
                            child: _buildPrimaryAction(search_state),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheetTransition({required bool animate, required Widget child}) {
    return AnimatedContainer(
      duration: animate && !_is_dragging_sheet
          ? const Duration(milliseconds: 260)
          : Duration.zero,
      curve: Curves.easeOutCubic,
      transform: Matrix4.translationValues(0, _sheet_drag_offset, 0),
      child: Container(
        key: const ValueKey('add-friend-visible-surface'),
        clipBehavior: Clip.antiAlias,
        decoration: const BoxDecoration(
          color: AppTheme.surface_color,
          borderRadius: _sheet_radius,
        ),
        child: animate
            ? AnimatedSize(
                // 키보드의 매 프레임은 즉시 반영하고 같은 inset의 단계 전환은 보간한다.
                key: ValueKey(MediaQuery.viewInsetsOf(context).bottom),
                alignment: Alignment.topCenter,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                child: child,
              )
            : child,
      ),
    );
  }

  TextStyle get _supportingStyle =>
      AppTheme.body_medium.copyWith(color: AppTheme.on_surface_variant_color);

  Widget _buildSearchInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('이메일 또는 전화번호', style: AppTheme.body_medium),
        const SizedBox(height: 8),
        TapRegion(
          onTapOutside: (_) => _focus_node.unfocus(),
          child: Semantics(
            label: '이메일 또는 전화번호',
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controller,
              builder: (context, value, child) => CupertinoTextField(
                key: const ValueKey('add-friend-search-input'),
                controller: _controller,
                focusNode: _focus_node,
                enabled: !_is_sending,
                placeholder: '입력해주세요',
                style: AppTheme.body_large,
                placeholderStyle: AppTheme.body_large.copyWith(
                  color: AppTheme.outline_color,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.search,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                decoration: BoxDecoration(
                  color: AppTheme.surface_container_low_color,
                  borderRadius: AppTheme.input_border_radius,
                  border: Border.all(
                    color: _validation_message != null
                        ? AppTheme.error_text_color
                        : _focus_node.hasFocus
                        ? AppTheme.primary_color
                        : AppTheme.surface_container_low_color,
                  ),
                ),
                onSubmitted: (_) => _searchUser(),
                onChanged: (_) => _resetSearch(),
                suffix: value.text.isEmpty
                    ? null
                    : CupertinoButton(
                        key: const ValueKey('add-friend-clear-button'),
                        minimumSize: const Size(44, 44),
                        padding: const EdgeInsets.all(12),
                        onPressed: _is_sending
                            ? null
                            : () {
                                _controller.clear();
                                _resetSearch();
                                _focus_node.requestFocus();
                              },
                        child: Semantics(
                          label: '입력 지우기',
                          child: const ExcludeSemantics(
                            child: Icon(
                              CupertinoIcons.xmark_circle_fill,
                              size: 20,
                              color: AppTheme.on_surface_variant_color,
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

  Widget _buildInputMessage(SearchUserState state) {
    if (_validation_message != null) {
      return _buildError(
        _validation_message!,
        key: const ValueKey('add-friend-validation-error'),
      );
    }
    final error = state.error;
    if (error != null) {
      final not_found = error is ApiException && error.code == 'USER_NOT_FOUND';
      return Semantics(
        liveRegion: true,
        child: Text(
          not_found
              ? '일치하는 사용자가 없어요.'
              : error is ApiException
              ? error.message
              : '연결 상태를 확인하고 다시 시도해주세요.',
          style: _supportingStyle,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildError(String message, {Key? key}) {
    return Semantics(
      liveRegion: true,
      child: Text(
        message,
        key: key,
        style: AppTheme.body_medium.copyWith(color: AppTheme.error_text_color),
      ),
    );
  }

  Widget _buildDraggableHeader() {
    return DecoratedBox(
      key: const ValueKey('add-friend-header-background'),
      decoration: const BoxDecoration(color: AppTheme.surface_color),
      child: Listener(
        onPointerCancel: (_) => _cancelSheetDrag(),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (_) => setState(() {
            _is_dragging_sheet = true;
            _drag_distance = 0;
            _sheet_drag_offset = 0;
          }),
          onVerticalDragUpdate: (details) => setState(() {
            _drag_distance += details.primaryDelta!;
            _sheet_drag_offset = _drag_distance.clamp(0.0, 180.0);
          }),
          onVerticalDragEnd: (_) => _settleSheet(),
          onVerticalDragCancel: _cancelSheetDrag,
          child: Column(
            key: const ValueKey('add-friend-modal-header'),
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.outline_variant_color,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                child: Row(
                  children: [
                    const SizedBox(width: 44),
                    Expanded(
                      child: Text(
                        '친구 추가',
                        key: const ValueKey('add-friend-modal-title'),
                        textAlign: TextAlign.center,
                        style: AppTheme.heading_small,
                      ),
                    ),
                    CupertinoButton(
                      key: const ValueKey('add-friend-close-button'),
                      minimumSize: const Size(44, 44),
                      padding: EdgeInsets.zero,
                      onPressed: () => Navigator.of(context).pop(),
                      child: Semantics(
                        label: '친구 추가 닫기',
                        child: const ExcludeSemantics(
                          child: Icon(
                            CupertinoIcons.xmark,
                            size: 20,
                            color: AppTheme.on_surface_variant_color,
                          ),
                        ),
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

  Widget _buildProfile(SearchUserModel user) {
    return Column(
      key: const ValueKey('add-friend-profile'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ExcludeSemantics(
            child: SizedBox(
              width: 64,
              height: 64,
              child: ClipOval(
                child: ColoredBox(
                  color: AppTheme.surface_container_color,
                  child: ProfileImage(
                    image_url: user.profileImageUrl ?? '',
                    fallback: const Icon(
                      CupertinoIcons.person_fill,
                      size: 30,
                      color: AppTheme.outline_color,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          user.name,
          textAlign: TextAlign.center,
          style: AppTheme.heading_small,
        ),
        const SizedBox(height: 4),
        Text(user.email, textAlign: TextAlign.center, style: _supportingStyle),
        if (_accountStatus(user) case final String status) ...[
          const SizedBox(height: 16),
          Semantics(
            liveRegion: true,
            child: Text(
              status,
              textAlign: TextAlign.center,
              style: _supportingStyle,
            ),
          ),
        ],
      ],
    );
  }

  String? _accountStatus(SearchUserModel user) {
    if (user.isFriend) return '이미 친구입니다';
    if (_sent_user_ids.contains(user.userId) ||
        (user.hasPendingRequest && user.pendingRequestDirection == 'sent')) {
      return '요청을 보냈어요 · 수락 대기 중';
    }
    if (user.hasPendingRequest) {
      return user.pendingRequestDirection == 'received'
          ? '받은 친구 요청이 있어요'
          : '친구 요청이 대기 중이에요';
    }
    return null;
  }

  Widget _buildPrimaryAction(SearchUserState state) {
    final user = state.user;
    if (user == null) {
      final error = state.error;
      final can_retry =
          error != null &&
          !(error is ApiException && error.code == 'USER_NOT_FOUND');
      return _buildButton(
        key: const ValueKey('add-friend-search-button'),
        label: can_retry ? '다시 시도' : '친구 찾기',
        on_pressed: state.isLoading ? null : _searchUser,
        loading_label: state.isLoading ? '친구 확인 중' : null,
      );
    }
    if (user.isFriend ||
        _sent_user_ids.contains(user.userId) ||
        (user.hasPendingRequest &&
            user.pendingRequestDirection != 'received')) {
      return _buildButton(
        key: const ValueKey('add-friend-done-button'),
        label: '완료',
        on_pressed: () => Navigator.of(context).pop(),
      );
    }
    if (user.hasPendingRequest) {
      return _buildButton(
        key: const ValueKey('add-friend-received-request-button'),
        label: '받은 요청 확인',
        on_pressed: () => Navigator.of(context).pop(true),
      );
    }
    return _buildButton(
      key: const ValueKey('add-friend-send-button'),
      label: '친구 요청 보내기',
      on_pressed: _is_sending ? null : () => _sendFriendRequest(user.userId),
      loading_label: _is_sending ? '친구 요청 보내는 중' : null,
    );
  }

  Widget _buildButton({
    required Key key,
    required String label,
    required VoidCallback? on_pressed,
    String? loading_label,
  }) {
    return CupertinoButton(
      key: key,
      minimumSize: const Size(52, 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      color: AppTheme.primary_color,
      disabledColor: AppTheme.primary_color,
      borderRadius: AppTheme.input_border_radius,
      onPressed: on_pressed,
      child: loading_label == null
          ? Text(
              label,
              textAlign: TextAlign.center,
              style: AppTheme.body_large.copyWith(
                color: AppTheme.surface_color,
                fontWeight: FontWeight.w600,
              ),
            )
          : Semantics(
              liveRegion: true,
              label: loading_label,
              child: const CupertinoActivityIndicator(
                color: AppTheme.surface_color,
              ),
            ),
    );
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  void _resetSearch() {
    ref.read(searchUserProvider.notifier).reset();
    setState(() {
      _validation_message = null;
      _request_error = null;
    });
  }

  void _cancelSheetDrag() {
    if (!mounted || !_is_dragging_sheet) return;
    setState(() {
      _is_dragging_sheet = false;
      _drag_distance = 0;
      _sheet_drag_offset = 0;
    });
  }

  void _settleSheet() {
    if (!mounted || !_is_dragging_sheet) return;
    if (!_is_expanded && _drag_distance >= 120) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      if (_drag_distance <= -48) {
        _is_expanded = true;
      } else if (_drag_distance >= 48) {
        _is_expanded = false;
      }
      _is_dragging_sheet = false;
      _drag_distance = 0;
      _sheet_drag_offset = 0;
    });
  }

  void _searchUser() {
    final state = ref.read(searchUserProvider);
    if (_is_sending || state.isLoading) return;
    if (state.user != null) {
      _focus_node.unfocus();
      return;
    }
    final query = _controller.text.trim();
    final validation_message = _validateSearchQuery(query);
    if (validation_message != null) {
      ref.read(searchUserProvider.notifier).reset();
      setState(() => _validation_message = validation_message);
      _focus_node.requestFocus();
      return;
    }
    _focus_node.unfocus();
    setState(() {
      _validation_message = null;
      _request_error = null;
    });
    final normalized_query = _normalizeSearchQuery(query);
    if (normalized_query != _controller.text) {
      _controller.value = TextEditingValue(
        text: normalized_query,
        selection: TextSelection.collapsed(offset: normalized_query.length),
      );
    }
    ref.read(searchUserProvider.notifier).searchUser(normalized_query);
  }

  String? _validateSearchQuery(String query) {
    if (query.isEmpty) {
      return '이메일 또는 전화번호를 입력해주세요.';
    }

    if (_isValidEmail(query) || _isValidPhoneNumber(query)) {
      return null;
    }

    return '이메일 또는 전화번호 형식으로 입력해주세요.';
  }

  bool _isValidEmail(String query) {
    final email_pattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return email_pattern.hasMatch(query);
  }

  bool _isValidPhoneNumber(String query) {
    return _normalizePhoneNumber(query) != null;
  }

  String _normalizeSearchQuery(String query) {
    if (_isValidEmail(query)) {
      return query;
    }

    final normalized_phone_number = _normalizePhoneNumber(query);
    return normalized_phone_number ?? query;
  }

  String? _normalizePhoneNumber(String query) {
    if (!RegExp(r'^\+?[0-9\s()-]+$').hasMatch(query)) {
      return null;
    }

    if (query.startsWith('+') && !query.startsWith('+82')) {
      return null;
    }

    final digits = query.startsWith('+82')
        ? '0${query.substring(3).replaceAll(RegExp(r'[^0-9]'), '')}'
        : query.replaceAll(RegExp(r'[^0-9]'), '');

    if (digits.length == 10) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 6)}-${digits.substring(6)}';
    }

    if (digits.length == 11) {
      return '${digits.substring(0, 3)}-${digits.substring(3, 7)}-${digits.substring(7)}';
    }

    return null;
  }

  Future<void> _sendFriendRequest(String user_id) async {
    if (_is_sending || _sent_user_ids.contains(user_id)) return;
    setState(() {
      _is_sending = true;
      _request_error = null;
    });
    final success = await ref
        .read(friendRequestsProvider.notifier)
        .sendFriendRequest(addresseeUserId: user_id);
    if (!mounted) return;
    setState(() {
      _is_sending = false;
      if (success) {
        _sent_user_ids.add(user_id);
      } else {
        _request_error = getErrorMessage(
          ref.read(friendRequestsProvider).error,
        );
      }
    });
  }
}
