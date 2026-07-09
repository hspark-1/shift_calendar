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

### 현재 화면 표시만 있는 값

| 화면 필드 | 처리 |
| --- | --- |
| 반복 | 현재 API/DB 필드가 없어 `안 함` 고정으로 표시하고 요청에는 포함하지 않음 |

### 서버가 채우는 값

| DB 컬럼 | 처리 |
| --- | --- |
| `owner_user_id` | 인증 사용자 `user_id` |
| `created_by_user_id` | 인증 사용자 `user_id` |
| `created_at`, `updated_at` | DB 또는 서버에서 현재 시각 |
| `deleted_at`, `deleted_by_user_id` | 생성 시 `null` |

## 공개 레벨 규칙

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

`v_visible_events_for_friend`는 최종 DDL의 조건을 유지해야 합니다.

```sql
CREATE OR REPLACE VIEW v_visible_events_for_friend AS
SELECT
  e.*,
  fls.friend_user_id AS viewer_user_id
FROM events e
JOIN friend_level_settings fls
  ON fls.owner_user_id = e.owner_user_id
 AND fls.can_view = true
WHERE e.deleted_at IS NULL
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
