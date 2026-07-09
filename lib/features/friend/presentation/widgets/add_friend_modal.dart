import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_exception.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/models/friend_model.dart';
import '../providers/friend_provider.dart';

/// 친구 추가 모달
class AddFriendModal extends ConsumerStatefulWidget {
  const AddFriendModal({super.key});

  @override
  ConsumerState<AddFriendModal> createState() => _AddFriendModalState();
}

class _AddFriendModalState extends ConsumerState<AddFriendModal> {
  static const double _sheetTopGapFactor = 0.08;
  static const double _minSheetHeightFactor = 0.42;
  static const double _initialSheetHeightFactor = 0.68;
  static const double _maxSheetHeightFactor = 1.0 - _sheetTopGapFactor;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isSending = false;
  bool _isDraggingSheet = false;
  double _sheetHeightFactor = _initialSheetHeightFactor;
  String? _validationMessage;

  @override
  void initState() {
    super.initState();
    // 초기 상태 리셋
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchUserProvider.notifier).reset();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchUserProvider);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final keyboardHeight = mediaQuery.viewInsets.bottom;
    final isKeyboardVisible = keyboardHeight > 0;
    final topGap = screenHeight * _sheetTopGapFactor;
    final sheetHeight = isKeyboardVisible
        ? screenHeight - keyboardHeight - topGap
        : screenHeight * _sheetHeightFactor;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: AnimatedContainer(
        duration: _isDraggingSheet
            ? Duration.zero
            : const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        height: sheetHeight,
        decoration: const BoxDecoration(
          color: AppTheme.surface_color,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppTheme.card_radius),
          ),
        ),
        child: Column(
          children: [
            _buildDraggableHeader(),
            Container(height: 1, color: AppTheme.outline_variant_color),
            // 검색 필드
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '이메일 또는 전화번호로 친구를 찾아보세요',
                    style: AppTheme.body_small.copyWith(
                      color: AppTheme.on_surface_variant_color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoSearchTextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          placeholder: '이메일 또는 전화번호 입력',
                          onSubmitted: (value) => _searchUser(),
                          onChanged: (value) {
                            // 이메일/전화번호 검색은 최대 1명만 표시하므로 입력이
                            // 바뀌면 이전 단일 결과를 즉시 숨긴다.
                            ref.read(searchUserProvider.notifier).reset();
                            if (_validationMessage != null) {
                              setState(() => _validationMessage = null);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppTheme.primary_color,
                          borderRadius: AppTheme.input_border_radius,
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _searchUser,
                          child: const Icon(
                            CupertinoIcons.search,
                            size: 20,
                            color: CupertinoColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_validationMessage != null)
                    _buildValidationBubble(_validationMessage!),
                ],
              ),
            ),
            // 검색 결과
            Expanded(child: _buildSearchResult(searchState)),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableHeader() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragStart: (_) {
        setState(() => _isDraggingSheet = true);
      },
      onVerticalDragUpdate: (details) {
        final screenHeight = MediaQuery.of(context).size.height;
        setState(() {
          final nextHeightFactor =
              _sheetHeightFactor - details.primaryDelta! / screenHeight;
          _sheetHeightFactor = nextHeightFactor.clamp(
            _minSheetHeightFactor,
            _maxSheetHeightFactor,
          );
        });
      },
      onVerticalDragEnd: (details) {
        _settleSheet(details.primaryVelocity ?? 0);
      },
      onVerticalDragCancel: () {
        setState(() => _isDraggingSheet = false);
      },
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.outline_variant_color,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('취소'),
                ),
                Text('친구 추가', style: AppTheme.heading_small),
                const SizedBox(width: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResult(SearchUserState state) {
    if (state.isLoading) {
      return const Center(child: CupertinoActivityIndicator());
    }

    if (state.error != null) {
      final message = state.error is ApiException
          ? (state.error as ApiException).message
          : '사용자를 찾을 수 없습니다.';

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_badge_minus,
              size: 48,
              color: AppTheme.outline_variant_color,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (!state.hasSearched) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.search,
              size: 48,
              color: AppTheme.outline_variant_color,
            ),
            const SizedBox(height: 16),
            Text(
              '친구의 이메일 또는 전화번호를\n입력해주세요',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    if (state.user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.person_badge_minus,
              size: 48,
              color: AppTheme.outline_variant_color,
            ),
            const SizedBox(height: 16),
            Text(
              '사용자를 찾을 수 없습니다',
              style: AppTheme.body_medium.copyWith(
                color: AppTheme.on_surface_variant_color,
              ),
            ),
          ],
        ),
      );
    }

    final user = state.user!;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _buildUserCard(user),
    );
  }

  Widget _buildUserCard(SearchUserModel user) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 280),
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.surface_container_color,
                  image: user.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.profileImageUrl == null
                    ? const Icon(
                        CupertinoIcons.person_fill,
                        size: 30,
                        color: AppTheme.outline_color,
                      )
                    : null,
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: AppTheme.body_large.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      user.email,
                      style: AppTheme.body_medium.copyWith(
                        color: AppTheme.on_surface_variant_color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _buildActionSection(user),
        ],
      ),
    );
  }

  Widget _buildActionSection(SearchUserModel user) {
    // 이미 친구인 경우
    if (user.isFriend) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.checkmark_circle_fill,
              size: 20,
              color: CupertinoColors.systemGreen,
            ),
            const SizedBox(width: 8),
            Text(
              '이미 친구입니다',
              style: AppTheme.body_medium.copyWith(
                color: CupertinoColors.systemGreen,
              ),
            ),
          ],
        ),
      );
    }

    // 대기 중인 요청이 있는 경우
    if (user.hasPendingRequest) {
      final isSent = user.pendingRequestDirection == 'sent';
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSent
                  ? CupertinoIcons.paperplane_fill
                  : CupertinoIcons.envelope_fill,
              size: 20,
              color: CupertinoColors.systemOrange,
            ),
            const SizedBox(width: 8),
            Text(
              isSent ? '이미 친구 요청을 보냈습니다' : '친구 요청을 받았습니다',
              style: AppTheme.body_medium.copyWith(
                color: CupertinoColors.systemOrange,
              ),
            ),
          ],
        ),
      );
    }

    // 친구 요청 보내기 버튼
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton.filled(
        padding: const EdgeInsets.symmetric(vertical: 12),
        onPressed: _isSending ? null : () => _sendFriendRequest(user.userId),
        child: _isSending
            ? const CupertinoActivityIndicator(color: CupertinoColors.white)
            : const Text('친구 요청 보내기'),
      ),
    );
  }

  Widget _buildValidationBubble(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, left: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(10, 5),
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                width: 10,
                height: 10,
                color: CupertinoColors.systemRed,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: CupertinoColors.systemRed,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              message,
              style: AppTheme.body_small.copyWith(
                color: CupertinoColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _settleSheet(double velocity) {
    if (!mounted) return;

    if (velocity > 900 || _sheetHeightFactor <= _minSheetHeightFactor + 0.02) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isDraggingSheet = false;

      if (_sheetHeightFactor >= 0.84) {
        _sheetHeightFactor = _maxSheetHeightFactor;
      } else if (_sheetHeightFactor <= 0.55) {
        _sheetHeightFactor = _minSheetHeightFactor;
      } else {
        _sheetHeightFactor = _initialSheetHeightFactor;
      }
    });
  }

  void _searchUser() {
    final query = _controller.text.trim();
    final validationMessage = _validateSearchQuery(query);

    if (validationMessage != null) {
      setState(() => _validationMessage = validationMessage);
      ref.read(searchUserProvider.notifier).reset();
      return;
    }

    _focusNode.unfocus();
    setState(() => _validationMessage = null);
    final normalizedQuery = _normalizeSearchQuery(query);

    if (normalizedQuery != query) {
      _controller.value = TextEditingValue(
        text: normalizedQuery,
        selection: TextSelection.collapsed(offset: normalizedQuery.length),
      );
    }

    ref.read(searchUserProvider.notifier).searchUser(normalizedQuery);
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
    final emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailPattern.hasMatch(query);
  }

  bool _isValidPhoneNumber(String query) {
    return _normalizePhoneNumber(query) != null;
  }

  String _normalizeSearchQuery(String query) {
    if (_isValidEmail(query)) {
      return query;
    }

    final normalizedPhoneNumber = _normalizePhoneNumber(query);
    return normalizedPhoneNumber ?? query;
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

  Future<void> _sendFriendRequest(String userId) async {
    setState(() => _isSending = true);

    final success = await ref
        .read(friendRequestsProvider.notifier)
        .sendFriendRequest(addresseeUserId: userId);

    setState(() => _isSending = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      _showSuccessDialog();
    } else if (mounted) {
      final error = ref.read(friendRequestsProvider).error;
      _showErrorDialog(getErrorMessage(error));
    }
  }

  void _showSuccessDialog() {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('친구 요청 완료'),
        content: const Text('친구 요청을 보냈습니다.\n상대방이 수락하면 친구가 됩니다.'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog<void>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('오류'),
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
