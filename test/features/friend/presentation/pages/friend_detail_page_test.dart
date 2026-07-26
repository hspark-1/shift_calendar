// ignore_for_file: non_constant_identifier_names

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/friend/data/models/friend_model.dart';
import 'package:shift_mate/features/friend/data/services/friend_service.dart';
import 'package:shift_mate/features/friend/presentation/pages/friend_detail_page.dart';

class _FakeFriendService extends FriendService {
  _FakeFriendService() : super(Dio());

  String? friend_user_id;
  int? friend_level;
  bool? can_view;

  @override
  Future<UpdateFriendSettingsResponse> updateFriendSettings({
    required String friendUserId,
    int? friendLevel,
    bool? canView,
  }) async {
    friend_user_id = friendUserId;
    friend_level = friendLevel;
    can_view = canView;

    return UpdateFriendSettingsResponse(
      success: true,
      data: FriendSettingsData(
        ownerUserId: 'owner-1',
        friendUserId: friendUserId,
        friendLevel: friendLevel ?? 0,
        canView: canView ?? true,
        updatedAt: DateTime(2026, 7, 19),
      ),
      message: '설정이 변경되었습니다.',
    );
  }
}

void main() {
  testWidgets('친구 설정 저장이 성공하면 이전 화면으로 이동한다', (tester) async {
    final service = _FakeFriendService();
    FriendDetailResult? route_result;
    final friend = FriendModel(
      userId: 'friend-1',
      name: '친구',
      email: 'friend@example.com',
      friendLevel: 0,
      canView: true,
      createdAt: DateTime(2026, 7, 19),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [friendServiceProvider.overrideWithValue(service)],
        child: CupertinoApp(
          home: Builder(
            builder: (context) => CupertinoPageScaffold(
              child: Center(
                child: CupertinoButton(
                  onPressed: () async {
                    route_result = await Navigator.of(context)
                        .push<FriendDetailResult>(
                          CupertinoPageRoute<FriendDetailResult>(
                            builder: (context) =>
                                FriendDetailPage(friend: friend),
                          ),
                        );
                  },
                  child: const Text('친구 상세 열기'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('친구 상세 열기'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CupertinoSwitch));
    await tester.pump();
    await tester.tap(find.text('저장'));
    await tester.pumpAndSettle();

    expect(find.text('친구 정보'), findsNothing);
    expect(find.text('친구 상세 열기'), findsOneWidget);
    expect(service.friend_user_id, 'friend-1');
    expect(service.friend_level, 0);
    expect(service.can_view, isFalse);
    expect(route_result, FriendDetailResult.saved);
  });
}
