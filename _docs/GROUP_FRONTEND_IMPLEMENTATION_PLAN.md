# 그룹 프론트엔드 구현·출시 계획

## 1. 기준과 목표

- 기준 계약: `_docs/group_api_guide/GROUP_FRONTEND_API_GUIDE.md`
- 구현 대상: Flutter의 그룹 목록·생성·상세·캘린더·초대·알림·역할별 관리
- 기존 개인/친구 캘린더의 동작과 친구별 공개 설정은 변경하지 않는다.
- 그룹은 별도 캘린더를 소유하지 않고, 서버가 멤버 개인 캘린더를 집계한 결과를 표시한다.
- 서버가 제외한 비공개 row의 존재나 개수를 앱이 추정하지 않는다.

## 2. 출시 게이트

| 게이트 | 기본값 | 노출 범위 | 활성화 조건 |
| --- | --- | --- | --- |
| `GROUP_API_ENABLED` | `false` | P0 그룹 목록·생성·상세·캘린더·초대·그룹 알림 | Stage P0 인수 테스트 완료 |
| `GROUP_P1_ENABLED` | `false` | 수정·초대 목록/취소·멤버/역할·탈퇴·소유권·삭제 | Stage P1 인수 테스트 완료 |

로컬 또는 Stage P0 실행 예:

```bash
flutter run --dart-define=GROUP_API_ENABLED=true
```

P1까지 함께 검증할 때만 다음처럼 실행한다.

```bash
flutter run \
  --dart-define=GROUP_API_ENABLED=true \
  --dart-define=GROUP_P1_ENABLED=true
```

플래그를 주지 않으면 기존 결정적 `GroupCalendarPreviewPage`가 rollback/fallback 화면으로 유지된다.

## 3. 아키텍처와 상태 소유권

```text
FriendListPage / NotificationPage
  → Group page
  → Group Notifier (Riverpod)
  → GroupRepository
  → GroupRemoteDataSource
  → Dio → /api/v1/groups, /api/v1/group-invitations
```

- UI state: 선택일, focused month, 입력 컨트롤러, 선택한 친구 ID, 요청 중인 행 ID
- domain state: 그룹 목록/상세, 멤버·역할, 초대 목록, 캘린더 범위, 월별 로딩/완료/오류
- 그룹 캘린더는 멤버별 `owner_user_id`를 보존해야 하므로 단일 소유자용 `CalendarRangeState`를 재사용하지 않는다.
- `work_date`는 날짜 문자열 그대로 배치한다.
- event UTC timestamp는 응답 `group.timezone`의 IANA timezone으로 변환한다.
- 이벤트 종료 시각은 배타적이며, 현지 자정 종료는 전날까지만 표시한다.
- 같은 월 요청은 월별 in-flight Future를 공유하고, 전월 1일~다음월 말일까지 최대 100일 이내로 조회한다.
- 계정 로그인/로그아웃 전환 시 그룹 목록·상세·캘린더·받은 초대 Provider를 모두 무효화한다.

## 4. 단계별 작업 상태

### P0 — 완료

- [x] 그룹 DTO/entity와 안전한 unknown enum 파싱
- [x] 그룹 P0/P1 endpoint DataSource·Repository
- [x] 그룹 목록 page 1 교체, 다음 페이지 append, 당겨서 새로고침
- [x] 그룹 생성과 친구 다중 선택, 소유자를 포함한 20명 UI 제한
- [x] 그룹 상세·캘린더와 공용 월 탐색/날짜 셀 조합
- [x] `SELF`/`VISIBLE` row 표시와 `DENIED` 잠금 표시
- [x] 공개된 실제 row만 근무·일정 수에 포함
- [x] 시작·종료 시간이 없는 근무는 날짜 셀의 근무색 점에서 제외하고 선택일 상세·인원 집계는 유지
- [x] 그룹 시간대 이벤트 날짜/시간 변환과 종료일 배타 처리
- [x] 기존 친구에게 그룹 초대, 선택 메시지 200자 제한
- [x] 받은 초대 목록·페이지네이션·수락/거절·행 단위 중복 탭 방지
- [x] 그룹 알림 타입/아이콘/액션 분기
- [x] 받은 초대 API를 알림 액션 노출의 source of truth로 사용
- [x] 수락 후 그룹 목록 갱신과 그룹 캘린더 이동
- [x] `GROUP_NOT_FOUND`에서 존재 여부를 추정하지 않는 문구로 목록 복귀
- [x] 동시 401 요청이 하나의 refresh Future를 기다리고 원 요청은 1회만 재시도

### P1 — 구현 완료, Stage 확인 전 기본 숨김

- [x] 그룹명/timezone 수정(OWNER, ADMIN)
- [x] 보낸 초대 목록/취소(OWNER, ADMIN)
- [x] MEMBER 제거(OWNER, ADMIN), ADMIN 제거(OWNER)
- [x] ADMIN/MEMBER 역할 변경(OWNER)
- [x] 그룹 나가기(ADMIN, MEMBER)
- [x] 소유권 이전·그룹 삭제(OWNER)
- [x] 요청 중 같은 멤버/초대 행 액션 비활성화
- [x] 권한 실패 후 상세 재조회
- [x] OWNER/ADMIN만 보낸 초대 조회, outgoing notifier dispose 후 비동기 상태 갱신 차단

### Stage 인수 — 서버 환경에서 수행

- [ ] 실제 Stage origin·서버 이미지 버전·DB migration 시각 기록
- [ ] P0 endpoint와 알림 응답을 실제 계정 3개 이상으로 확인
- [ ] `SELF`/`VISIBLE`/`DENIED`와 visibility level 조합 확인
- [ ] Asia/Seoul 외 IANA timezone과 DST 경계 확인
- [ ] 동시 수락, 만료, 정원 20명, 초대 bulk atomic 오류 확인
- [ ] P1 권한 매트릭스와 OWNER 제약 확인
- [ ] 완료 후 `GROUP_API_ENABLED`, 이어서 `GROUP_P1_ENABLED` 배포값 승인

## 5. 화면·API 매핑

| 화면/동작 | API | 성공 후 상태 처리 |
| --- | --- | --- |
| 그룹 방 목록 | `GET /groups` | page 1 교체, 다음 page ID 병합 |
| 그룹 만들기 | `POST /groups` | 목록 재조회 후 상세 이동 |
| 그룹 상세 | `GET /groups/{group_id}` | 역할별 액션 재구성 |
| 그룹 캘린더 | `GET /groups/{group_id}/calendar/range` | 월별 캐시 병합 |
| 친구 초대 | `POST /groups/{group_id}/invitations` | 성공 전체 단위로 완료 처리 |
| 받은 초대 | `GET /group-invitations/received` | 서버 PENDING 목록으로 액션 결정 |
| 수락/거절 | `PUT /group-invitations/{id}/respond` | 카드 terminal 처리, 수락 시 목록 갱신 |
| P1 관리 | 그룹 수정/삭제·초대 취소·멤버·leave·owner endpoint | 상세/목록/캘린더 무효화 또는 갱신 |

## 6. 오류 UX

- 입력 오류와 409 충돌은 서버 `ApiException.message`를 현재 화면에서 안내한다.
- `GROUP_PERMISSION_DENIED`는 권한이 바뀐 것으로 보고 그룹 상세를 다시 조회한다.
- `GROUP_NOT_FOUND`는 삭제/비멤버 여부를 구분하지 않고 그룹 목록으로 돌아간다.
- `GROUP_INVITATION_ALREADY_PROCESSED`, `GROUP_INVITATION_EXPIRED`, `GROUP_INVITATION_NOT_FOUND`는 받은 초대 목록을 다시 조회해 버튼을 제거한다.
- `GROUP_MEMBER_LIMIT_REACHED`는 정원 안내 후 그룹 목록/상세를 갱신한다.
- 로그에는 요청 method/path만 남기며 일정 제목·메모·장소, 초대 메시지를 기록하지 않는다.

## 7. 검증 기준

- Repository 파싱: `owner_user_id`, 색상, UTC, unknown enum 보존
- Notifier: 3개월 범위, 월 요청 중복 방지, IANA timezone 날짜 배치, 종료일 배타 처리
- Widget: 공개 row 집계, `DENIED` 잠금, 미설정 근무 행 숨김, 시간 없는 근무의 날짜 점 제외,
  MEMBER의 관리자 전용 초대 조회 차단
- 알림: PENDING+accept/reject일 때만 버튼, EXPIRED terminal, 그룹 API/친구 API 분기
- 변경 파일 `flutter analyze` 진단 0건
- 신규 그룹·알림 테스트 통과
- 기존 그룹 미리보기 fallback 테스트 통과
- 전체 테스트에서 이 변경으로 생긴 회귀 0건
- `git diff --check` 통과

## 8. 롤백

1. 배포 설정에서 `GROUP_P1_ENABLED=false`로 관리 기능부터 숨긴다.
2. 문제가 지속되면 `GROUP_API_ENABLED=false`로 실제 그룹 진입을 닫고 기존 미리보기로 복귀한다.
3. 코드 롤백이 필요하면 `features/group`, 그룹 알림 분기, API 상수, timezone 초기화와 계정 캐시 무효화를 함께 되돌린다.
4. 플래그 롤백은 서버 데이터나 멤버십을 삭제하지 않는다.
