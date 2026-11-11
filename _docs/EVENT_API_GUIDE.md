# 개인 일정 API 가이드라인

## 개요

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
| 공개 레벨 | `visibility_level` | `events.visibility_level` | 0~5, DB 제약은 0 이상 |

### 선택 값

| 화면 필드 | 요청 필드 | DB 컬럼 | 설명 |
| --- | --- | --- | --- |
| 장소 | `place` | `events.place` | 빈 문자열이면 보내지 않음 |
| 메모 | `memo` | `events.memo` | 빈 문자열이면 보내지 않음 |
| 나만 보기 | `is_private` | `events.is_private` | JSON boolean. 서버 생략 기본 false, Flutter는 true/false를 명시 전송 |

### 화면 동작과 나만 보기 (2026-11-11)

- 캘린더 위 슬라이드업 모달에서 제목 → 시작/종료 행 → 공개 범위 → 접을 수 있는 장소·메모 → 하단 저장 순서다(ADR-0047/0048). 손잡이·본문 스크롤 최상단 아래 끌기·닫기/OS 복귀는 작성 내용 폐기 확인 없이 닫는다. 저장 중 닫기 차단·키보드 위 저장을 제공한다.
- 반복은 현재 API/DB 필드가 없어 폼에서 제거했다. 시작 전 알림·참석자·일정별 색상도 전송하지 않는다.
- 공개 방식은 인라인 친구에게 공개/나만 보기 세그먼트로 고른다. 친구 공개에서만0~5 정수 슬라이더/숫자 탭과 의미 설명을 제공한다. 0은 열람 허용된 모든 친구이며 전체 인터넷 공개를 의미하지 않는다. 레벨5도 나만 보기가 아니다. private 전환 시 이전 레벨을 보존한다.
- 나만 보기를 선택하면 `is_private: true`, 친구 공개는 false를 명시 전송한다. private여도 visibility_level 필수0~5를 유지하며 선택 전 레벨을 보존한다. 응답 is_private 생략은 false로 파싱하여 구형 공개 응답과 호환한다.
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
- `visibility_level=0`은 `can_view=true`이고 친구 관계가 있는 기본 레벨 친구에게 공개된다.

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
| `INVALID_VISIBILITY_LEVEL` | `visibility_level < 0` 또는 서버 정책 범위 초과 | 공개 레벨이 올바르지 않습니다. |
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
  visibility_level smallint NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid,
  is_private boolean NOT NULL DEFAULT false,
  CONSTRAINT fk_events_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_events_created_by FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_events_deleted_by FOREIGN KEY (deleted_by_user_id) REFERENCES users(user_id),
  CONSTRAINT ck_events_time CHECK (start_at < end_at),
  CONSTRAINT ck_events_visibility CHECK (visibility_level >= 0)
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
