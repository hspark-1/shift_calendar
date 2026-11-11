# 개인 일정 나만 보기 서버 구현 요청서

작성일: 2026-11-11 (Asia/Seoul)
대상: `shift_calendar_server` Express/Sequelize 서버 담당자
상태: **서버 구현·배포 완료 사용자 확인 / Flutter 연동 완료.** 로컬 서버 코드와 [서버 정본 가이드](../../shift_calendar_server/_docs/EVENT_PRIVACY_GUIDE.md)를 대조했다. 서버 가이드에는 Stage/운영 배포·DB 검사·격리 PostgreSQL 검증 완료가 기록돼 있다. 이 Flutter 작업에서 원격 인증 사용자별 실응답/실기기 인수를 수행한 것은 아니다. 외부 이슈 등록이나 담당자 메시지 발송 없이 문서를 제공한다는 사용자 지시를 따른다.

## 후속 현황 (2026-11-11)

- Flutter 공개 범위에서 나만 보기를 실제 선택할 수 있다. `CreateEventRequest.isPrivate`는 JSON is_private boolean을 명시 전송하고 기존 레벨을 보존한다.
- `EventApiModel.isPrivate`, 그룹 응답 `GroupCalendarEvent.is_private`는 생략 필드를 false로 복원하여 기존 공개 응답과 호환한다.
- private 생성 응답에 true가 없으면 EVENT_PRIVACY_NOT_CONFIRMED로 성공 처리를 중단한다. 생성 후 확인이므로 저장 취소/서버 공개 필터를 대체하지 않으며 목록에서 실제 공개 범위를 확인하도록 안내한다. 자동 재요청하지 않는다.
- 최신 UI는 ADR-0047/0048의 슬라이드업 모달/인라인 공개 방식·레벨 슬라이더와 확인 없는 닫기이며 재현/검증은 PROJECT_CONTEXT/WORKLOG를 따른다. 아래 본문은 당시 전달용 요청과 인수 기준의 기록이며 서버 재배포나 migration 재실행 지시가 아니다.

## 전달할 요청

개인 일정에 레벨 공개와 독립적인 `is_private` boolean을 추가해 주세요. `true`인 일정은 소유자만 조회할 수 있어야 하며 친구 레벨·열람 허용·그룹 가입 여부로 우회할 수 없어야 합니다. 기존 요청에서 필드를 생략하면 `false`로 저장하여 기존 공개 동작을 유지합니다. 근무표의 공개 정책은 변경하지 않습니다.

요청 당시 Flutter는 `나만 보기 · 서버 지원 준비 중`으로 선택을 차단했습니다. 서버 배포 완료 확인 후 현재는 상단 후속 현황처럼 실제 boolean 계약을 연결했습니다. **레벨 5나 범위 밖의 숫자를 나만 보기로 사용하지 않습니다.** 반복·시작 전 알림·참석자·색상은 이 요청에 포함하지 않습니다.

## 직접 확인한 구조와 변경 위치

근거는 로컬 `../shift_calendar_server`의 실제 소스다. `schema.drawio`와 `visibility_flow.drawio`는 calendars/calendar_shares 중심의 구형 모델이며 현행 단일 캘린더 DDL과 다르다. 변경 시 서버 정본 DDL·AGENTS·도면을 실제 결과에 맞춰 함께 갱신한다.

| 파일 | 확인한 사실 / 구현 요청 |
|---|---|
| `src/models/Event.ts` | Sequelize/PostgreSQL, `events.visibility_level`만 존재한다. attributes/creation optional/declare/init에 `is_private` boolean, NOT NULL, default false 추가 |
| `src/routes/calendarRoutes.ts` | `authMiddleware` 뒤 `POST /events`에 express-validator 사용. `visibility_level`은 0~5다. 생략 허용·실제 JSON boolean만 허용하는 `is_private` 검증 추가 |
| `src/controllers/calendarController.ts` | `getCreateEventValidationError` 및 `createEvent`가 검증 오류를 공통 wrapper로 매핑하고 인증 user_id와 req.body를 service에 전달. private 검증 오류 매핑 추가 |
| `src/services/calendarService.ts` | `CreateEventInput`, `EventApiModel`, `createEvent`, `toEventApiModel` 수정. owner `getEvents`/`getDaySchedule`에는 private 제외 조건을 넣지 않는다. `/calendar/range`는 getEvents를 사용한다 |
| `src/services/friendService.ts` | 친구관계·can_view 확인 뒤 `v_visible_events_for_friend`를 raw SQL로 조회. SELECT 목록/응답 타입에 `is_private` 추가, 값은 항상 false여야 한다 |
| `src/services/groupService.ts` | `getGroupCalendarRange`의 `visible_events` CTE가 본인 `events`와 타인 `v_visible_events_for_friend`를 UNION ALL한다. 양쪽 SELECT·CalendarEventRow·응답 매핑에 같은 순서로 is_private 추가. 본인 private는 보존, 타인은 뷰에서 제외 |
| `src/types/group.ts` | `GroupCalendarEvent`에 is_private boolean 추가 |
| `migrations/final_schema.sql` | events와 `v_visible_events_for_friend` 정의를 신규 설치용으로 갱신. 배포 DB에는 별도 증분 migration 필요 |
| `src/openapi/calendarOpenApi.json`, `src/openapi/groupOpenApi.json` | 요청/본인·친구·그룹 응답과 오류, 생략 default false 문서화. 친구 OpenAPI가 사용하는 이벤트 스키마도 검색해 반영 |
| `src/openapi.ts` | `/api-docs`, `/api-docs/openapi.json`으로 병합 스펙을 제공하므로 최종 병합 결과 확인 |

요청 처리 흐름은 `Router → auth/validation → Controller → Service → Sequelize/PostgreSQL → DTO`다. 공개 판단은 서버가 수행하며 Flutter에서만 숨기는 구현은 허용하지 않는다. 현재 확인한 서비스의 개인 일정 SELECT는 DB 직접 조회다. 근무표 월 캐시를 private 일정 필터로 대체하거나 변경하지 않는다. 배포 환경에 추가 캐시가 있다면 데이터 응답 전체 경로와 캐시 무효화를 별도 확인한다.

## 데이터와 API 계약

```json
{
  "title": "개인 약속",
  "all_day": false,
  "start_at": "2026-11-11T00:00:00.000Z",
  "end_at": "2026-11-11T01:00:00.000Z",
  "visibility_level": 0,
  "is_private": true
}
```

- `POST /api/v1/events`, 기존 JWT/Content-Type/HTTP 201/`{success,data,message}` wrapper를 유지한다.
- `is_private`는 생략 시 false, boolean true/false만 허용한다. null, 문자열 `"true"`/`"false"`, 숫자/배열/객체는 HTTP 400 `INVALID_EVENT_PRIVACY`로 거부한다. 기존 `.isBoolean().toBoolean()`만 복사하여 문자열을 허용하지 않는다.
- controller 검증과 service 직접 호출 모두 타입 검증을 수행한다. `Boolean(value)`는 문자열 false도 true로 만들므로 사용하지 않는다.
- `visibility_level`은 private여도 기존 필수 0~5를 유지한다. private true는 그 값보다 우선한다. 이후 공개 범위 편집을 추가할 때 기존 레벨을 복원할 수 있다.
- owner_user_id/created_by_user_id는 인증 사용자에서 채운다. 클라이언트 소유자 ID로 저장/조회 대상을 바꾸지 않는다.
- `place`/`memo` trim·빈 값 처리, UTC ISO 형식과 배타적 종료, 기존 soft delete/소유자 삭제 정책은 유지한다.
- 생성과 모든 본인 일정 응답에 `is_private`를 포함한다. 친구·타인 그룹 응답에는 private row 자체가 없어야 한다. 공개 row에는 false를 포함한다.
- 기존 `EventApiModel`의 required 필드는 바꾸지 않으며 신규 Flutter 응답 파서는 필드 생략을 false로 해석하도록 후속 변경한다. 기존 앱은 추가 JSON 필드를 무시하여 호환된다.
- 새로운 env는 요구하지 않는다. 서버 DB 전환·API·인수 후 Flutter 활성화를 별도 진행한다.

오류 예:

```json
{
  "success": false,
  "error": {
    "code": "INVALID_EVENT_PRIVACY",
    "message": "공개 범위가 올바르지 않습니다."
  }
}
```

## 공개 판정과 인수 기준

```text
본인: owner_user_id == viewer_user_id → 활성 일정 조회(나만 보기 포함)
타인: is_private == false
      AND 친구 관계 존재
      AND owner → viewer can_view == true
      AND friend_level >= visibility_level
```

| 조회자/상태 | is_private=false | is_private=true |
|---|---|---|
| 소유자 본인 | 본인 목록/기간/날짜/그룹의 본인 행에서 보임 | 같은 경로에서 보임 |
| 열람 허용된 친구, 충분한 레벨 | 보임 | 보이지 않음 |
| 열람 허용된 레벨5 친구 | 레벨 조건 충족 시 보임 | 보이지 않음 |
| 열람 차단/친구 아님 | 보이지 않음 | 보이지 않음 |
| 같은 그룹의 다른 사용자 | 기존 친구·열람·레벨 조건 충족 시만 보임 | 보이지 않음 |

단순 제목 마스킹이 아니라 event_id/title/memo/place/start/end를 포함한 전체 private row를 타인 응답에서 제외한다. 타인이 보는 일정 수·날짜 마커도 필터된 결과를 사용해야 한다. 미래 상세/검색/공유/수정 endpoint가 추가될 때도 동일 정책을 적용한다.

## PostgreSQL 증분 migration 지침

목적은 기존 행을 false로 보존하면서 private 일정의 타인 조회를 DB view에서 차단하는 것이다. 새 설치 DDL에도 같은 컬럼과 조건을 반영한다.

사전 점검:

```sql
SELECT column_name, data_type, is_nullable, column_default, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'events'
ORDER BY ordinal_position;

SELECT pg_get_viewdef('public.v_visible_events_for_friend'::regclass, true);

SELECT column_name, ordinal_position
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'v_visible_events_for_friend'
ORDER BY ordinal_position;
```

현재 view는 `e.*` 뒤에 viewer_user_id를 둔다. 테이블에 컬럼을 추가한 뒤 단순 `SELECT e.*, viewer_user_id`로 CREATE OR REPLACE하면 기존 viewer_user_id 위치에 새 컬럼이 끼어 PostgreSQL의 컬럼 이름/순서 제약을 위반할 수 있다. **기존 view 컬럼 이름/타입/순서를 그대로 두고 새 컬럼을 마지막에 추가한다.** 실제 배포 schema와 비교한 뒤 적용하며 운영 view를 DROP CASCADE하지 않는다.

아래 SELECT 목록은 로컬 final_schema.sql의 events 순서 기준이다. 운영 view에 다른 컬럼이 있으면 해당 컬럼과 순서도 보존한 migration을 작성한다.

```sql
BEGIN;
ALTER TABLE public.events
  ADD COLUMN is_private boolean NOT NULL DEFAULT false;
COMMENT ON COLUMN public.events.is_private IS
  'true면 소유자만 조회 가능. 친구 레벨/열람/그룹보다 우선';

CREATE OR REPLACE VIEW public.v_visible_events_for_friend AS
SELECT
  e.event_id, e.owner_user_id, e.created_by_user_id,
  e.title, e.memo, e.place, e.all_day, e.start_at, e.end_at,
  e.visibility_level, e.created_at, e.updated_at,
  e.deleted_at, e.deleted_by_user_id,
  fls.friend_user_id AS viewer_user_id,
  e.is_private
FROM public.events e
JOIN public.friend_level_settings fls
  ON fls.owner_user_id = e.owner_user_id
 AND fls.can_view = true
WHERE e.deleted_at IS NULL
  AND e.is_private = false
  AND EXISTS (
    SELECT 1 FROM public.friendships f
    WHERE f.user_id_a = LEAST(e.owner_user_id, fls.friend_user_id)
      AND f.user_id_b = GREATEST(e.owner_user_id, fls.friend_user_id)
  )
  AND fls.friend_level >= e.visibility_level;
COMMIT;
```

`ADD COLUMN`은 중복 실행 시 실패하게 두고 migration 이력으로 재실행을 관리한다. 기존 동명 컬럼이 있으면 타입/NULL/default·실제 의미를 확인하며 무조건 IF NOT EXISTS로 넘어가지 않는다. 기존 행 false 보존·private false 필터·view 순서·권한/의존성을 점검한다. 새 인덱스는 EXPLAIN/데이터 규모 근거 없이 추가하지 않는다.

## 테스트·배포·Flutter 활성화 순서

1. 서비스/route 테스트: 기존 요청 생략=false, true/false 생성과 응답, 잘못된 타입 400, owner 위조 불가, 기존 시간/레벨/삭제 계약 회귀. `test/*.test.cjs`와 기존 npm test 구조를 따른다.
2. PostgreSQL 통합: 실제 테이블/view를 사용하여 위 표의 전 조합과 다일/종일/soft delete를 검증한다. 본인 조회 `GET /events`, `/calendar/day`, `/calendar/range`; 친구 `/friends/:friend_user_id/calendar/range`; 그룹 `/groups/:group_id/calendar/range` 모두 확인한다. `/calendar/day`의 현재 시작일 기준 조회 의미는 이번 변경에서 확대하지 않는다.
3. migration을 기존 데이터·view가 있는 DB와 신규 설치 schema에서 각각 적용한다. viewer_user_id 순서/타입 유지·필요 권한·기존 행 false를 확인한다.
4. `npm test`, 별도 안전한 테스트 DB의 통합 테스트, `/api-docs/openapi.json` 검증 후 Stage에 서버/migration 선배포한다. 테스트를 운영 DB에서 수행하지 않는다.
5. Stage에서 A가 private를 생성하고 A/친구B/동일그룹C 각각 조회한다. 높은 친구 레벨·can_view=true여도 B/C 응답 어디에도 private ID가 없는지 확인한다. 새 생성 응답에 true가 돌아오는 것만으로 공개 필터 완료를 판정하지 않는다.
6. 운영 서버와 DB/모든 조회 경로 반영이 확인된 후 Flutter 후속 변경으로 `isPrivate` 요청/응답 필드와 활성 선택을 추가한다. 생략 false·true 명시 전송·응답 true 확인과 입력 보존을 테스트한다. 구형 서버는 모르는 필드를 무시할 수 있으므로 프론트에 필드만 추가해 먼저 배포하지 않는다. 응답 확인은 저장 후 유출을 예방하는 수단이 아니므로 선배포/인수 순서를 반드시 지킨다.
7. 서버 인수 담당자는 적용 커밋/증분 migration 이름·Stage/운영 반영 상태·본인/친구/그룹 테스트 결과를 이 요청서에 회신한다. 그 결과를 근거로 프론트 선택을 활성화한다.

로그는 기존 request id와 구조화된 오류 정책을 유지하고 title/memo/place·토큰을 로그에 추가하지 않는다.

## 롤백

Flutter 화면 변경은 해당 폼/테스트/문서만 되돌린다. 이번 Flutter에는 private 저장이 활성화되지 않아 DB 작업이 없다.

서버 배포 후 private 행이 존재한다면 **공개 필터를 제거하거나 컬럼을 삭제하는 다운 migration은 사용하지 않는다.** 나만 보기 일정이 다시 공유되는 결과를 만든다. 신규 private 생성만 차단하고 DB 컬럼·뷰의 private 차단 조건을 유지한다. 필요하면 private 동작을 유지하는 호환 서버 버전을 배포한다. 복원/삭제가 필요할 때는 소유자 데이터 보존·명시적 정책에 따른 별도 작업으로 처리한다.

## 완료 기록

- [x] 현재 서버 모델·생성/본인 조회·친구/그룹 SQL·정본 view·OpenAPI 구조 확인
- [x] Flutter 기존 공개 저장 호환 유지, 서버 준비 전 선택 차단 후 활성화
- [x] 서버 증분 migration / 정본 DDL·AGENTS·도면 동기화(사용자 완료 보고·서버 가이드)
- [x] 모델·검증·생성·응답·친구/그룹 SELECT 반영(로컬 코드 확인)
- [x] 단위·PostgreSQL 통합·구버전 호환 테스트 및 OpenAPI 반영(서버 가이드 기록)
- [x] Stage/운영 선배포 완료(사용자 확인·서버 가이드 기록)
- [x] Flutter 요청/응답 필드 및 나만 보기 활성화
- [ ] 실제 인증 사용자별 원격 실응답·실기기 인수
