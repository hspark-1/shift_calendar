// ignore_for_file: non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:shift_mate/features/group/data/datasources/group_remote_datasource.dart';
import 'package:shift_mate/features/group/data/repositories/group_repository_impl.dart';
import 'package:shift_mate/features/group/domain/entities/group_models.dart';

class _FakeGroupRemoteDataSource implements GroupRemoteDataSource {
  String? requested_start_date;
  String? requested_end_date;

  @override
  Future<Map<String, dynamic>> getGroupCalendarRange({
    required String group_id,
    required String start_date,
    required String end_date,
  }) async {
    requested_start_date = start_date;
    requested_end_date = end_date;
    return {
      'success': true,
      'data': {
        'group': {
          'group_id': group_id,
          'name': '우리 병동',
          'timezone': 'Asia/Seoul',
        },
        'range': {'start_date': start_date, 'end_date': end_date},
        'members': [
          {
            'user_id': 'owner',
            'name': '박현서',
            'profile_image_url': null,
            'role': 'OWNER',
            'joined_at': '2026-08-01T03:00:00.000Z',
            'calendar_access': 'SELF',
          },
          {
            'user_id': 'hidden',
            'name': '비공개',
            'profile_image_url': null,
            'role': 'MEMBER',
            'joined_at': '2026-08-01T04:00:00.000Z',
            'calendar_access': 'DENIED',
          },
        ],
        'work_shifts': [
          {
            'owner_user_id': 'owner',
            'work_shift_id': 'shift-1',
            'work_date': '2026-08-02',
            'shift_type_code': 'D',
            'shift_type_name': '데이',
            'shift_type_color': '#FFFF9500',
            'start_time': '07:00:00',
            'end_time': '15:00:00',
            'note': null,
            'created_at': '2026-08-01T03:00:00.000Z',
            'updated_at': '2026-08-01T03:00:00.000Z',
          },
        ],
        'events': [
          {
            'owner_user_id': 'owner',
            'event_id': 'event-1',
            'title': '병원 예약',
            'memo': null,
            'place': '서울',
            'all_day': false,
            'start_at': '2026-08-01T15:30:00.000Z',
            'end_at': '2026-08-01T16:30:00.000Z',
            'visibility_level': 1,
          },
        ],
      },
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('그룹 캘린더 응답에서 소유자·공개 상태·색상·UTC를 보존한다', () async {
    final data_source = _FakeGroupRemoteDataSource();
    final repository = GroupRepositoryImpl(data_source);

    final result = await repository.getGroupCalendarRange(
      group_id: 'group-1',
      start_date: DateTime(2026, 7, 1),
      end_date: DateTime(2026, 9, 30),
    );

    expect(data_source.requested_start_date, '2026-07-01');
    expect(data_source.requested_end_date, '2026-09-30');
    expect(result.members[1].calendar_access, CalendarAccess.denied);
    expect(result.work_shifts.single.owner_user_id, 'owner');
    expect(result.work_shifts.single.shift_type_color, 0xFFFF9500);
    expect(result.events.single.owner_user_id, 'owner');
    expect(result.events.single.start_at.isUtc, isTrue);
    expect(result.events.single.start_at, DateTime.utc(2026, 8, 1, 15, 30));
  });

  test('알 수 없는 서버 enum은 안전한 unknown 값으로 파싱한다', () {
    expect(GroupRole.fromJson('SUPER_ADMIN'), GroupRole.unknown);
    expect(
      GroupInvitationStatus.fromJson('ARCHIVED'),
      GroupInvitationStatus.unknown,
    );
    expect(CalendarAccess.fromJson('MASKED'), CalendarAccess.unknown);
  });
}
