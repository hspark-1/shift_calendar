# 개인 일정 API 가이드라인

## 개요

### 개인 일정 공개 레벨1~5 (2026-11-12)

- ADR-0055: 개인 일정은 공개/private 모두1~5·기본1이다. 레벨0 친구에게는 근무표만 보여준다. 근무표0·친구0~5·can_view·is_private 독립 정책은 유지한다.
- Flutter는0 버튼을 제거하고 슬라이더/접근성 최소1과 HTTP 전송 전 생성/수정 범위 검증을 적용한다. 기존0 편집은1 이상으로 보정해 저장한다는 안내를 표시하며 저장 전 원본은 유지한다.
- 인접 서버 검증과 기존0→1/default/DB 제약 migration도 로컬 구현/검증했다. 구형0 요청은400이다. 운영 서버 배포 및 증분 SQL 적용이 필요하며 이번 작업에서 원격에 적용하지 않았다. 적용/검증·안전 롤백 정본은 [서버 가이드](../../shift_calendar_server/_docs/EVENT_VISIBILITY_GUIDE.md)를 따른다.

개인 일정 수정은 아래 `PUT` 계약을 사용한다(2026-11-12 로컬 구현·검증, 서버 배포 전).

### 메인 삭제 유예와 되돌리기

- ADR-0053: 개인 일정/근무 삭제는 화면에서 먼저 숨기고3초(접근성 탐색10초) 후 기존 DELETE를 보낸다. 되돌리기는 미전송 묶음을 취소한다. POST로 재생성하거나 복원 API를 호출하지 않으며 ID/private/시간 등 원본 값을 보존한다.
- ADR-0057: 토스트를 아래로 끌거나 접근성 닫기 액션을 실행하면 알림 표시만 숨긴다. 삭제 예약을 취소하거나 즉시 확정하지 않는다. 추가 삭제는 새 알림을 표시하며 되돌리기는 계속 미전송 묶음 전체를 취소한다.
- 성공 후에만 캐시를 제거하고 실패 시 항목을 다시 표시한다. 개인 일정404/잘못된 ID 처리는 기존과 같다. 앱 비활성화/화면 dispose/계정 전환은 미전송 예약을 취소한다. 이미 시작된 서버 삭제는 되돌릴 수 없다. 서버/DB/env/인증 계약 변경은 없다.

### 개인 일정 입력 순서

- ADR-0054: 신규 제목 완료 → 시작 날짜 캘린더(날짜 선택 후 확인으로 확정) → 시작 시간 휠 → 종료 시간 휠 → 공개 범위로 이어진다. 기본 종료일은 같은 날이며 여러 날 일정은 종료일에서 직접 선택한다. 종일은 시작/종료 날짜만 선택한다.
- 직접 날짜 수정은 확인 후 해당 시간만 이어서 열고, 피커 취소/끌어 닫기는 다음 진행을 멈춘다. 날짜/오늘은 임시 선택이며 하단 확인 전에는 폼에 반영하지 않는다. 오늘은 월 내비게이션 오른쪽에 둔다. 날짜/시간 시트는 손잡이·본문 최상단에서120px 이상 아래로 끌면 취소로 닫히며 휠·달력 가로 넘김은 분리한다(ADR-0056). 신규 안내의 시작 시각이 종료 이상이면 종료 기본값은 시작+1시간이며 자정을 넘으면 종료일도 다음 날로 이동한다. 수동 시간의 start<end 검증·종일 배타적 종료·기존 수정 시각 정밀도와 아래 API 계약은 동일하다.

### 개인 일정 전체 수정

- `PUT /api/v1/events/{event_id}`, JWT·JSON 필수. 본인 소유 활성 일정만 변경한다.
- 요청8개 필드 모두 필수: title(string/trim/빈 값 금지), memo/place(string 또는 null), all_day/is_private(실제 boolean), start_at/end_at(UTC ISO·start<end), visibility_level(실제 정수1~5).
- **생성과의 차이**: 수정에서 빈 장소/메모는 명시적 null을 보내 기존 값을 지운다. 생략은400이다. 소유자/생성자/created_at은 요청으로 변경할 수 없다.
- HTTP200 `{success:true,data:EventApiModel,message:"일정이 수정되었습니다."}`. ID/created_at 보존·updated_at 갱신·is_private를 포함한 전체 모델을 반환한다.
- 400: INVALID_EVENT_ID/INVALID_TITLE/INVALID_EVENT_TIME/INVALID_VISIBILITY_LEVEL/INVALID_EVENT_PRIVACY/VALIDATION_ERROR. 401: 인증 실패. 404 EVENT_NOT_FOUND: 미존재/타인/삭제된 일정 공통. 500: INTERNAL_SERVER_ERROR. 기존 `{success:false,error:{code,message}}`를 유지한다.
- Flutter는 ID/private 응답 확인 후 모든 날짜의 기존 ID를 새 기간으로 교체한다. 종일 표시 종료일은 배타적 end_at의 전날이며 저장 시 다음 날 자정으로 변환한다. 제목만 고치면 원본 시각의 초/밀리초를 보존한다.
- 실패 입력 보존/재시도, 응답 확인이 불확실할 때 `목록 다시 확인`,404 안내 후 종료를 제공한다. 마지막 성공 저장 적용 정책이며 충돌 version/Undo API는 없다. DB migration·새 env 없음. 인접 서버 상세: `../shift_calendar_server/_docs/EVENT_EDIT_GUIDE.md`.

메인 캘린더의 `일정 추가하기` 모달에서 개인 일정을 생성하기 위한
프론트-서버 계약입니다.

- **Base URL**: `/api/v1`
- **인증**: Bearer Token (JWT)
- **Content-Type**: `application/json`
- **DB 기준**: 최종 DDL의 `events` 테이블

## 화면 입력값 설계

### 필수 값

| 화면 필드 | 요청 필드 | DB 컬럼 | 설명 |
| --- | --- | --- | --- |
| 제목 | `title` | `events.title` | 공백 제거 후 빈 값이면 저장 불가 |
| 종일 여부 | `all_day` | `events.all_day` | `true`면 날짜 단위 일정 |
| 시작일/시작시간 | `start_at` | `events.start_at` | ISO-8601 UTC 문자열 |
| 종료일/종료시간 | `end_at` | `events.end_at` | ISO-8601 UTC 문자열, `start_at < end_at` |
| 공개 레벨 | `visibility_level` | `events.visibility_level` | 1~5, 기본1·DB CHECK BETWEEN1AND5 |

### 선택 값

| 화면 필드 | 요청 필드 | DB 컬럼 | 설명 |
| --- | --- | --- | --- |
| 장소 | `place` | `events.place` | 빈 문자열이면 보내지 않음 |
| 메모 | `memo` | `events.memo` | 빈 문자열이면 보내지 않음 |
| 나만 보기 | `is_private` | `events.is_private` | JSON boolean. 서버 생략 기본 false, Flutter는 true/false를 명시 전송 |

### 화면 동작과 나만 보기 (2026-11-11)

- 캘린더 위 슬라이드업 모달에서 제목 → 시작/종료 행 → 공개 범위 → 접을 수 있는 장소·메모 → 하단 저장 순서다(ADR-0047/0048). 손잡이·본문 스크롤 최상단 아래 끌기·닫기/OS 복귀는 작성 내용 폐기 확인 없이 닫는다. 저장 중 닫기 차단·키보드 위 저장을 제공한다.
- 반복은 현재 API/DB 필드가 없어 폼에서 제거했다. 시작 전 알림·참석자·일정별 색상도 전송하지 않는다.
- 날짜/시간 헤더의 연도 보조 표시와 종료 아래 기간 합계는 표시하지 않는다. 장소·메모는 기본 펼침이며 접기/입력 보존을 지원한다(ADR-0050). 날짜 선택/시간 검증·종일 배타적 종료는 유지한다.
- 공개 방식은 인라인 친구에게 공개/나만 보기 세그먼트로 고른다. 친구 공개에서만1~5 레벨 슬라이더/숫자 탭과 의미 설명을 제공한다. 드래그는 연속 이동하며 놓으면 정수에 정렬하고 저장은 1~5 정수다. 친구 레벨0은 근무표만 보며 개인 일정에는0을 지정할 수 없다. 레벨5도 나만 보기가 아니다. private 전환 시 이전 레벨을 보존한다. 레벨1~5 설명은 `내가 지정한 레벨이 N 이상인 친구에게 보여요.`로 표시하며 서버의 can_view/레벨 판정은 동일하다.
- 나만 보기를 선택하면 `is_private: true`, 친구 공개는 false를 명시 전송한다. private여도 visibility_level 필수1~5를 유지하며 선택 전 레벨을 보존한다. 응답 is_private 생략은 false로 파싱하여 구형 공개 응답과 호환한다.
- private 생성 응답이 true가 아니면 CalendarService는 EVENT_PRIVACY_NOT_CONFIRMED로 성공 처리를 중단한다. 생성 후 확인이므로 서버 저장을 되돌리거나 타인 필터를 대체하지 않는다. 자동 재요청하지 않으며 일정 목록에서 실제 공개 범위를 확인하도록 안내한다.
- 서버 배포 완료는 사용자 보고와 인접 서버 EVENT_PRIVACY_GUIDE 기록 기준이다. 로컬 모델/route/service/뷰 필터와 대조해 활성화했다. [나만 보기 서버 요청서](PERSONAL_EVENT_PRIVACY_SERVER_HANDOFF.md)의 상단 현황과 서버 정본 가이드를 함께 참고한다. 실제 원격 인증 사용자별/실기기 인수는 별도다.
- 필수 입력은 인접 오류/첫 오류 이동, 서버 오류는 입력을 유지한 하단 다시 저장으로 처리한다. 저장 중 중복 입력/이탈은 막지만, 그 외 닫기는 작성 내용 확인 없이 즉시 처리한다.

### 서버가 채우는 값

| DB 컬럼 | 처리 |
| --- | --- |
| `owner_user_id` | 인증 사용자 `user_id` |
| `created_by_user_id` | 인증 사용자 `user_id` |
| `created_at`, `updated_at` | DB 또는 서버에서 현재 시각 |
| `deleted_at`, `deleted_by_user_id` | 생성 시 `null` |

## 공개 레벨 규칙

- `is_private=true`는 레벨/열람 허용/그룹 역할보다 우선하며 소유자만 조회한다. 본인 조회에는 유지하고 친구·타인 그룹의 DB view에서 전체 행을 제외한다.
- 일정마다 `events.visibility_level`을 저장한다.
- 내 일정을 친구가 조회할 때 서버는 아래 조건을 통과한 일정만 반환한다.
  - `friend_level_settings.owner_user_id = 내 user_id`
  - `friend_level_settings.friend_user_id = 조회자 user_id`
  - `friend_level_settings.can_view = true`
  - `friend_level_settings.friend_level >= events.visibility_level`
- 친구 캘린더 조회에서는 위 규칙의 owner가 조회 대상 친구가 된다.
- `events.visibility_level`은1~5이고 친구 레벨0은 개인 일정을 조회할 수 없다. 근무표의 레벨0은 유지한다.

## 종일 일정 시간 규칙

- `end_at`은 배타적 종료 시각으로 처리한다.
- 하루짜리 종일 일정 예:
  - 사용자가 `2026-07-07`을 선택
  - 프론트 요청: 로컬 `2026-07-07 00:00` ~ `2026-07-08 00:00`을 UTC ISO 문자열로 변환
- 서버도 조회/응답에서 같은 의미를 유지해야 한다.

## API 엔드포인트

### 1. 개인 일정 생성

#### Request

```
POST /api/v1/events
```

**Headers**

```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Body**

```json
{
  "title": "친구 약속",
  "memo": "저녁 식사",
  "place": "서울",
  "all_day": false,
  "start_at": "2026-07-07T10:00:00.000Z",
  "end_at": "2026-07-07T11:00:00.000Z",
  "visibility_level": 1
}
```

#### Response

```json
{
  "success": true,
  "data": {
    "event_id": "uuid",
    "title": "친구 약속",
    "memo": "저녁 식사",
    "place": "서울",
    "all_day": false,
    "start_at": "2026-07-07T10:00:00.000Z",
    "end_at": "2026-07-07T11:00:00.000Z",
    "visibility_level": 1,
    "created_at": "2026-07-07T09:00:00.000Z",
    "updated_at": "2026-07-07T09:00:00.000Z"
  },
  "message": "일정이 생성되었습니다."
}
```

프론트는 `data` 객체를 `EventApiModel`로 파싱해 선택 날짜 일정 목록에 즉시 반영한다.

#### Validation

| 코드 | 조건 | 메시지 예시 |
| --- | --- | --- |
| `INVALID_TITLE` | `title`이 공백 또는 누락 | 제목을 입력해주세요. |
| `INVALID_EVENT_TIME` | `start_at >= end_at` 또는 날짜 파싱 실패 | 일정 시간이 올바르지 않습니다. |
| `INVALID_VISIBILITY_LEVEL` | `visibility_level < 1` 또는 서버 정책 범위 초과 | 공개 레벨이 올바르지 않습니다. |
| `UNAUTHORIZED` | 토큰 없음/만료 | 로그인이 필요합니다. |

## DB/DDL 서버 적용 요청

현재 최종 DDL 기준으로 개인 일정 생성 화면에 필요한 신규 컬럼은 없습니다.
서버 DB가 최종 DDL과 다르면 아래 `events` 구조와 인덱스, 친구 공개 조회 view를
서버 migration에 반영한 뒤 적용해야 합니다.

```sql
CREATE TABLE IF NOT EXISTS events (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id uuid NOT NULL,
  created_by_user_id uuid NOT NULL,
  title text NOT NULL,
  memo text,
  place text,
  all_day boolean NOT NULL DEFAULT false,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  visibility_level smallint NOT NULL DEFAULT 1,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid,
  is_private boolean NOT NULL DEFAULT false,
  CONSTRAINT fk_events_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_events_created_by FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_events_deleted_by FOREIGN KEY (deleted_by_user_id) REFERENCES users(user_id),
  CONSTRAINT ck_events_time CHECK (start_at < end_at),
  CONSTRAINT ck_events_visibility CHECK (visibility_level BETWEEN 1 AND 5)
);

CREATE INDEX IF NOT EXISTS idx_events_owner_start_not_deleted
ON events(owner_user_id, start_at)
WHERE deleted_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_events_owner_visibility_not_deleted
ON events(owner_user_id, visibility_level, start_at)
WHERE deleted_at IS NULL;
```

아래는 구조 참고용이며 배포 DB에 재실행하지 않습니다. 실제 정본/증분 migration은 인접 서버
`migrations/final_schema.sql`, `migrations/add_event_privacy.sql`을 따릅니다. 기존 view의 컬럼 순서와
권한을 보존하기 위해 `e.*` 대신 기존14개 컬럼·viewer_user_id·is_private 순서를 명시합니다.

```sql
CREATE OR REPLACE VIEW v_visible_events_for_friend AS
SELECT
  e.event_id, e.owner_user_id, e.created_by_user_id,
  e.title, e.memo, e.place, e.all_day, e.start_at, e.end_at,
  e.visibility_level, e.created_at, e.updated_at,
  e.deleted_at, e.deleted_by_user_id,
  fls.friend_user_id AS viewer_user_id,
  e.is_private
FROM events e
JOIN friend_level_settings fls
  ON fls.owner_user_id = e.owner_user_id
 AND fls.can_view = true
WHERE e.deleted_at IS NULL
  AND e.is_private = false
  AND EXISTS (
    SELECT 1
    FROM friendships f
    WHERE f.user_id_a = LEAST(e.owner_user_id, fls.friend_user_id)
      AND f.user_id_b = GREATEST(e.owner_user_id, fls.friend_user_id)
  )
  AND fls.friend_level >= e.visibility_level;
```

## 서버 구현 체크리스트

- [ ] `POST /api/v1/events` route + auth middleware + validation 추가
- [ ] controller는 인증 사용자에서 `owner_user_id`, `created_by_user_id` 설정
- [ ] service/repository에서 `events` insert 후 생성된 row 반환
- [ ] `start_at`, `end_at`은 UTC `timestamptz`로 저장
- [ ] `GET /api/v1/calendar/range` 응답에 생성된 이벤트가 포함되는지 확인
- [ ] 친구 캘린더 조회에서 `visibility_level`별 필터링 확인
- [ ] Swagger/OpenAPI 업데이트
