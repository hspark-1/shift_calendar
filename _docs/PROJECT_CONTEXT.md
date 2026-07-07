# 프로젝트 컨텍스트

## 프로젝트 개요

**Shift Calendar**는 교대 근무 일정 관리 및 공유를 위한 Flutter 모바일 애플리케이션입니다.

### 주요 기능

- 교대 근무 일정 관리 (데이/이브닝/나이트 등)
- 캘린더 기반 일정 조회 및 편집
- 친구 간 일정 공유
- 카카오 OAuth 로그인

### 기술 스택

- **프레임워크**: Flutter (Cupertino 디자인)
- **상태관리**: Flutter Riverpod 2.6.1
- **네트워크**: Dio 5.7.0
- **인증**: 카카오 Flutter SDK
- **로컬 저장소**: Flutter Secure Storage, Shared Preferences
- **코드 생성**: Freezed, JSON Serializable, Riverpod Generator

### 아키텍처 개요

```
Page (UI)
  ↓
Provider/Notifier (State Management)
  ↓
Repository (Domain Interface)
  ↓
Service/DataSource (Data Layer)
  ↓
Dio (HTTP Client)
  ↓
API Server
```

**에러 처리 흐름**:

```
DioException → handleApiError() → ApiException → UI (CupertinoAlertDialog)
```

### 메인 캘린더 조회/표시 흐름

```
CalendarPage
  → CalendarService.getCalendarRange()
  → GET /api/v1/calendar/range
  → CalendarRangeResponse(work_shifts, events)
  → WorkShiftApiModel / EventApiModel 날짜별 맵
  → TableCalendar + 선택 날짜 일정 카드
```

- 메인 캘린더의 저장된 근무표 표시는 서버가 반환한 `WorkShiftApiModel`을 기준으로 한다.
- `work_shifts` 응답의 `shift_type_code`, `shift_type_name`, `shift_type_color`,
  `start_time`, `end_time`은 저장된 근무표 표시용 스냅샷이다.
- `shiftTypesProvider`는 현재 계정의 근무 타입 설정 조회 및 근무 입력 버튼 표시용으로만 사용한다.
- 저장된 근무표를 화면에 그릴 때는 `shiftTypesProvider`의 코드별 캐시로 색상/이름/시간을 재해석하지 않는다.
- 로그인/로그아웃으로 계정이 바뀌면 근무 타입, 근무 템플릿 설정, 친구, 알림 Provider 캐시를 무효화한다.

### 개인 일정 생성/표시 흐름

```
CalendarPage
  → PersonalEventFormModal
  → CalendarService.createEvent()
  → POST /api/v1/events
  → EventApiModel
  → 선택 날짜 일정 목록에 즉시 반영
```

- 메인 캘린더 선택일 카드의 `일정 추가하기...`는 개인 일정 추가 모달을 띄운다.
- 입력 필수값은 `title`, `all_day`, `start_at`, `end_at`, `visibility_level`이다.
- 선택값은 `place`, `memo`이며, 빈 문자열은 요청에서 제외한다.
- `owner_user_id`, `created_by_user_id`는 서버가 인증 사용자 기준으로 채운다.
- 프론트는 로컬 `DateTime`을 UTC ISO 문자열로 변환해 요청하고, 응답의 `start_at`/`end_at`은 로컬 시간으로 파싱해 표시한다.
- 종일 일정은 `end_at`을 배타적 종료 시각으로 사용한다. 하루짜리 종일 일정은 선택일 00:00부터 다음 날 00:00까지로 저장한다.
- 공개 판단은 서버 책임이다. 내 일정을 친구가 볼 때 서버는 `friend_level_settings.owner_user_id = 내 user_id`,
  `friend_level_settings.friend_user_id = 조회자 user_id`, `can_view=true`,
  `friend_level >= events.visibility_level` 조건을 적용한다.
- API 서버 요청 문서는 `_docs/EVENT_API_GUIDE.md`에 둔다.
- 파일 역할/의존성/사용 예:
  - `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`:
    개인 일정 입력 모달. `CalendarPage`에서 `showCupertinoModalPopup`으로 호출하고
    저장 시 `CreateEventRequest`를 반환한다. 모달은 전체 화면 고정 높이로 표시하고,
    키보드 표시 시 모달 자체를 리사이즈하지 않는다. 리스트가 맨 위에 있을 때 아래로
    스와이프하면 닫힌다. 공개 레벨은 0~5 버튼 클릭이 아니라 좌우 드래그 트랙으로
    선택한다.
  - `_docs/EVENT_API_GUIDE.md`: 개인 일정 생성 API, 입력 필수/선택값,
    공개 레벨 규칙, 서버 DDL 확인 요청을 정리한 서버 구현 문서다.

### 친구 캘린더 조회 흐름

```
FriendListPage
  → FriendCalendarPage
  → FriendService.getFriendCalendarRange()
  → GET /api/v1/friends/:friend_user_id/calendar/range
  → API Server
  → v_visible_work_shifts_for_friend / v_visible_events_for_friend
```

- 친구 목록 항목 선택 시 기존 `FriendDetailPage`가 아니라 `FriendCalendarPage`로 진입한다.
- `FriendCalendarPage` 오른쪽 설정 버튼은 기존 `FriendDetailPage`로 이동한다.
- 친구 캘린더 응답은 기존 `CalendarRangeResponse` 형식(`work_shifts`, `events`)을 재사용한다.
- 공개 판단은 서버 책임이다. 서버는 `friend_level_settings.owner_user_id = friend_user_id`,
  `friend_level_settings.friend_user_id = viewer_user_id`, `can_view=true`,
  `friend_level >= events.visibility_level` 조건을 적용한 결과만 반환한다.
- 친구 근무표 색상/이름/시간은 현재 사용자 템플릿 Provider가 아니라
  `WorkShiftApiModel` 응답 필드를 직접 사용한다.

# 사용하는 DB Schema

아래는 **PostgreSQL 기준으로 "바로 실행 가능한 DDL"**이야.
그리고 DDL 안에 COMMENT ON ...으로 테이블/컬럼 역할 설명까지 같이 넣었어(=DB에서 바로 의미 확인 가능).

전제

- UUID 사용 (RDS Postgres에서 흔히 사용)
- 시간은 timestamptz로 UTC 저장을 권장
- Soft delete는 deleted_at 기준

/\* =========================================================
FINAL SCHEMA (PostgreSQL) — Single-calendar-per-user
요구사항 반영 요약

- 사용자 1명 = 캘린더 1개 (calendars 테이블 제거)
- 공유 = "내 캘린더를 친구에게 열람 허용" (calendar_shares 제거)
- 친구별 설정 = friend_level_settings에서 일괄 관리
  - can_view (내 캘린더 열람 허용/차단)
  - friend_level (레벨 비교로 일정 노출)
- 노출 규칙:
  - (can_view = true) AND (friend_level >= visibility_level)
  - work_shifts.visibility_level = 0 고정
- UUID 사용: pgcrypto + gen_random_uuid()
- 시간: timestamptz (UTC 저장 권장)
- Soft delete: deleted_at

※ 참고: "UTC 저장"은 컬럼 타입(timestamptz) + DB/세션 timezone 설정으로 보장 권장
========================================================= \*/

-- =========================================================
-- 0) PUBLIC SCHEMA 삭제 및 재생성
-- ⚠️ 경고: 기존 모든 데이터가 삭제됩니다!
-- =========================================================
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- =========================================================
-- 1) Extensions
-- =========================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- 2) USERS
-- =========================================================
CREATE TABLE users (
user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
email text NOT NULL,
name text NOT NULL,
profile_image_url text,
timezone text, -- 예: 'Asia/Seoul'
kakao_id text, -- 카카오 OAuth 사용자 ID
apple_id text, -- 애플 OAuth 사용자 sub
password text, -- 패스워드 인증용 bcrypt 해시 (OAuth 사용자는 null)
created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT uq_users_email UNIQUE (email)
);

-- 카카오/애플 OAuth ID 인덱스
CREATE UNIQUE INDEX idx_users_kakao_id ON users(kakao_id) WHERE kakao_id IS NOT NULL;
CREATE UNIQUE INDEX idx_users_apple_id ON users(apple_id) WHERE apple_id IS NOT NULL;

COMMENT ON TABLE users IS '앱 사용자. 사용자 1명당 캘린더 1개(=모든 일정/근무 owner_user_id=user_id)';
COMMENT ON COLUMN users.user_id IS '사용자 PK(UUID)';
COMMENT ON COLUMN users.email IS '로그인/식별용 이메일(유니크)';
COMMENT ON COLUMN users.timezone IS '사용자 선호 타임존(렌더링용)';
COMMENT ON COLUMN users.kakao_id IS '카카오 OAuth 사용자 ID';
COMMENT ON COLUMN users.apple_id IS '애플 OAuth 사용자 sub';
COMMENT ON COLUMN users.password IS '패스워드 인증용 bcrypt 해시 (OAuth 사용자는 null)';

-- =========================================================
-- 3) FRIEND REQUESTS (요청/수락 플로우)
-- =========================================================
CREATE TABLE friend_requests (
request_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
requester_user_id uuid NOT NULL,
addressee_user_id uuid NOT NULL,
status text NOT NULL DEFAULT 'PENDING', -- PENDING | ACCEPTED | REJECTED | CANCELED
message text,
created_at timestamptz NOT NULL DEFAULT now(),
responded_at timestamptz,

CONSTRAINT fk_friend_requests_requester FOREIGN KEY (requester_user_id) REFERENCES users(user_id),
CONSTRAINT fk_friend_requests_addressee FOREIGN KEY (addressee_user_id) REFERENCES users(user_id),
CONSTRAINT ck_friend_requests_status CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELED')),
CONSTRAINT ck_friend_requests_not_self CHECK (requester_user_id <> addressee_user_id)
);

-- 같은 두 사람 사이에 "대기중(PENDING)" 요청 1개만 허용(방향 포함)
CREATE UNIQUE INDEX uq_friend_requests_pending_pair
ON friend_requests (requester_user_id, addressee_user_id)
WHERE status = 'PENDING';

-- 받은 요청함
CREATE INDEX idx_friend_requests_addressee_status
ON friend_requests (addressee_user_id, status, created_at DESC);

-- 보낸 요청함
CREATE INDEX idx_friend_requests_requester_status
ON friend_requests (requester_user_id, status, created_at DESC);

COMMENT ON TABLE friend_requests IS '친구 요청/수락. ACCEPTED 시 friendships + friend_level_settings(양방향) 자동 생성';

-- =========================================================
-- 4) FRIENDSHIPS (수락된 친구 관계, 대칭 1건)
-- - user_id_a < user_id_b 규칙으로 중복 저장 방지
-- =========================================================
CREATE TABLE friendships (
user_id_a uuid NOT NULL,
user_id_b uuid NOT NULL,
created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT pk_friendships PRIMARY KEY (user_id_a, user_id_b),
CONSTRAINT fk_friendships_a FOREIGN KEY (user_id_a) REFERENCES users(user_id),
CONSTRAINT fk_friendships_b FOREIGN KEY (user_id_b) REFERENCES users(user_id),
CONSTRAINT ck_friendships_order CHECK (user_id_a < user_id_b)
);

-- 친구 목록 조회는 양방향 모두 필요
CREATE INDEX idx_friendships_user_a ON friendships(user_id_a);
CREATE INDEX idx_friendships_user_b ON friendships(user_id_b);

COMMENT ON TABLE friendships IS '수락된 친구 관계(대칭). user_id_a < user_id_b로 1건만 저장';

-- =========================================================
-- 5) FRIEND LEVEL SETTINGS (owner -> friend 방향성)
-- - can_view: 내 캘린더 열람 허용 여부(ACL)
-- - friend_level: 레벨 기반 노출 판단값
-- =========================================================
CREATE TABLE friend_level_settings (
owner_user_id uuid NOT NULL,
friend_user_id uuid NOT NULL,

can_view boolean NOT NULL DEFAULT true, -- 내 캘린더를 이 친구에게 보여줄지
friend_level smallint NOT NULL DEFAULT 0, -- 0 이상

created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT pk_friend_level_settings PRIMARY KEY (owner_user_id, friend_user_id),
CONSTRAINT fk_fls_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
CONSTRAINT fk_fls_friend FOREIGN KEY (friend_user_id) REFERENCES users(user_id),
CONSTRAINT ck_fls_level CHECK (friend_level >= 0),
CONSTRAINT ck_fls_not_self CHECK (owner_user_id <> friend_user_id)
);

-- "내가 설정한 친구 목록" / "내 캘린더 열람 허용된 친구"
CREATE INDEX idx_fls_owner ON friend_level_settings(owner_user_id);

-- 정렬/필터(레벨 기반 노출 판단용) 최적화
CREATE INDEX idx_fls_owner_can_view_level
ON friend_level_settings(owner_user_id, can_view, friend_level DESC);

COMMENT ON TABLE friend_level_settings IS '친구별 열람 설정(ACL + 레벨). 노출 조건: can_view=true AND friend_level>=visibility_level';

-- =========================================================
-- 6) SHIFT TEMPLATES / VERSIONS / TYPES / SCHEDULES
-- - 사용자별(=owner_user_id)로 템플릿 관리
-- =========================================================
CREATE TABLE shift_templates (
template_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
owner_user_id uuid NOT NULL,

name text NOT NULL,
created_at timestamptz NOT NULL DEFAULT now(),
deleted_at timestamptz,

CONSTRAINT fk_shift_templates_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
CONSTRAINT uq_shift_templates_name UNIQUE (owner_user_id, name)
);

CREATE INDEX idx_shift_templates_owner
ON shift_templates(owner_user_id)
WHERE deleted_at IS NULL;

COMMENT ON TABLE shift_templates IS '근무 템플릿(사용자 단위). 예: 기본 3교대';

CREATE TABLE shift_template_versions (
template_version_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
template_id uuid NOT NULL,

version_no int NOT NULL,
effective_from date NOT NULL DEFAULT CURRENT_DATE, -- 사용자 timezone 기준 해석은 앱에서
created_by_user_id uuid NOT NULL,
created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT fk_shift_versions_template FOREIGN KEY (template_id) REFERENCES shift_templates(template_id),
CONSTRAINT fk_shift_versions_creator FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
CONSTRAINT uq_shift_versions_no UNIQUE (template_id, version_no),
CONSTRAINT uq_shift_versions_effective UNIQUE (template_id, effective_from),
CONSTRAINT ck_shift_versions_no CHECK (version_no > 0)
);

CREATE INDEX idx_shift_versions_template_effective
ON shift_template_versions(template_id, effective_from DESC);

COMMENT ON TABLE shift_template_versions IS '템플릿 시간표 버전 스냅샷. 설정 변경은 UPDATE가 아니라 버전 INSERT';

CREATE TABLE shift_types (
shift_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
template_id uuid NOT NULL,

code text NOT NULL, -- 예: 'D', 'E', 'N', 'OFF', 'VAC' 등 사용자 정의
name text NOT NULL, -- 예: '데이'
color int, -- 예: 0xFFF5A623 (앱과 동일하게 사용)
sort_order smallint,

created_at timestamptz NOT NULL DEFAULT now(),
deleted_at timestamptz,

CONSTRAINT fk_shift_types_template FOREIGN KEY (template_id) REFERENCES shift_templates(template_id)
);

CREATE INDEX idx_shift_types_template
ON shift_types(template_id)
WHERE deleted_at IS NULL;

COMMENT ON TABLE shift_types IS '근무 타입(사용자 정의). code/name/color 지원. (template_id, code) 중복 허용';

CREATE TABLE shift_type_schedules (
schedule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
shift_type_id uuid NOT NULL,
template_version_id uuid NOT NULL,

start_time time,
end_time time,
crosses_midnight boolean NOT NULL DEFAULT false,
duration_minutes int NOT NULL DEFAULT 0,

created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT fk_shift_schedules_type FOREIGN KEY (shift_type_id) REFERENCES shift_types(shift_type_id),
CONSTRAINT fk_shift_schedules_version FOREIGN KEY (template_version_id) REFERENCES shift_template_versions(template_version_id),
CONSTRAINT uq_shift_schedules UNIQUE (template_version_id, shift_type_id),

-- 시간 있는 타입은 start/end 필수, OFF류는 null 허용
CONSTRAINT ck_shift_schedule_time_required CHECK (
(start_time IS NULL AND end_time IS NULL)
OR
(start_time IS NOT NULL AND end_time IS NOT NULL)
),
CONSTRAINT ck_shift_schedule_duration CHECK (duration_minutes >= 0)
);

CREATE INDEX idx_shift_schedules_version
ON shift_type_schedules(template_version_id);

CREATE INDEX idx_shift_schedules_type
ON shift_type_schedules(shift_type_id);

COMMENT ON TABLE shift_type_schedules IS '버전별 근무 시간표 스냅샷(시작/종료/자정넘김/시간(분))';

### 근무 타입 색상 파싱 규칙

- DB 문서상 `shift_types.color`는 Flutter `Color` 정수값(`0xAARRGGBB`) 기준이다.
- 실제 API 응답은 정수 또는 문자열(`#AARRGGBB`, `#RRGGBB`, `0xAARRGGBB`, 10진수 문자열)로 들어올 수 있다.
- 클라이언트는 `lib/core/utils/color_parser.dart`의 `parseApiColorValue()`로 응답 색상을 정규화한다.
- 사용 예: `ShiftTypeApiModel.color`, `WorkShiftApiModel.shiftTypeColor` 파싱 시 공통 사용한다.

-- =========================================================
-- 7) EVENTS (개인 일정)
-- - owner_user_id가 곧 "내 캘린더"의 소유자
-- =========================================================
CREATE TABLE events (
event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

owner_user_id uuid NOT NULL, -- 캘린더 소유자(사용자 1명=캘린더 1개)
created_by_user_id uuid NOT NULL, -- 생성자(사실상 owner=created_by가 일반적)

title text NOT NULL,
memo text,
place text,

all_day boolean NOT NULL DEFAULT false,
start_at timestamptz NOT NULL,
end_at timestamptz NOT NULL,

visibility_level smallint NOT NULL DEFAULT 0, -- 0 이상
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

-- 월/주/일 뷰 핵심 인덱스: owner + 기간 + not deleted
CREATE INDEX idx_events_owner_start_not_deleted
ON events(owner_user_id, start_at)
WHERE deleted_at IS NULL;

-- visibility_level 조건까지 자주 타면(친구 조회)
CREATE INDEX idx_events_owner_visibility_not_deleted
ON events(owner_user_id, visibility_level, start_at)
WHERE deleted_at IS NULL;

COMMENT ON TABLE events IS '개인 일정. 노출 조건: (친구 설정 can_view=true) AND (friend_level >= visibility_level)';

-- =========================================================
-- 8) WORK SHIFTS (근무표: visibility_level=0 고정)
-- =========================================================
CREATE TABLE work_shifts (
work_shift_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

owner_user_id uuid NOT NULL, -- 사용자 1명=캘린더 1개
work_date date NOT NULL, -- 사용자 timezone 기준 해석은 앱에서

schedule_id uuid NOT NULL, -- 버전 포함 스냅샷
note text,

visibility_level smallint NOT NULL DEFAULT 0, -- 항상 0
created_by_user_id uuid NOT NULL,
created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz NOT NULL DEFAULT now(),

deleted_at timestamptz,
deleted_by_user_id uuid,

CONSTRAINT fk_work_shifts_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
CONSTRAINT fk_work_shifts_schedule FOREIGN KEY (schedule_id) REFERENCES shift_type_schedules(schedule_id),
CONSTRAINT fk_work_shifts_created_by FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
CONSTRAINT fk_work_shifts_deleted_by FOREIGN KEY (deleted_by_user_id) REFERENCES users(user_id),

CONSTRAINT uq_work_shifts_one_per_day UNIQUE (owner_user_id, work_date),
CONSTRAINT ck_work_shifts_visibility_fixed CHECK (visibility_level = 0)
);

CREATE INDEX idx_work_shifts_owner_date_not_deleted
ON work_shifts(owner_user_id, work_date)
WHERE deleted_at IS NULL;

COMMENT ON TABLE work_shifts IS '근무표(날짜 기반). visibility_level=0 고정 → can_view=true인 친구는 모두 열람 가능';

-- =========================================================
-- 9) REFRESH TOKENS (JWT Refresh Token 관리)
-- - 로그아웃 및 토큰 무효화를 위한 테이블
-- =========================================================
CREATE TABLE refresh_tokens (
token_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
user_id uuid NOT NULL,
token_hash text NOT NULL, -- refresh_token의 SHA-256 해시
device_info text, -- 디바이스 정보 (선택)
expires_at timestamptz NOT NULL, -- 토큰 만료 시점
revoked_at timestamptz, -- 무효화 시점 (null이면 유효)
created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT fk_refresh_tokens_user
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 사용자별 유효한 토큰 조회 최적화
CREATE INDEX idx_refresh_tokens_user
ON refresh_tokens(user_id) WHERE revoked_at IS NULL;

-- 토큰 해시로 조회 (갱신/검증 시)
CREATE UNIQUE INDEX idx_refresh_tokens_hash
ON refresh_tokens(token_hash) WHERE revoked_at IS NULL;

-- 만료된 토큰 정리용 (배치 작업)
CREATE INDEX idx_refresh_tokens_expires
ON refresh_tokens(expires_at) WHERE revoked_at IS NULL;

COMMENT ON TABLE refresh_tokens IS 'JWT Refresh Token 저장. 로그아웃 시 revoked_at 설정으로 무효화';
COMMENT ON COLUMN refresh_tokens.token_hash IS 'refresh_token의 SHA-256 해시값';
COMMENT ON COLUMN refresh_tokens.device_info IS '토큰 발급 디바이스 정보 (User-Agent 등)';
COMMENT ON COLUMN refresh_tokens.revoked_at IS '토큰 무효화 시점. null이면 유효한 토큰';

-- =========================================================
-- 10) TRIGGER: friend_requests ACCEPTED → friendships + friend_level_settings(양방향)
-- =========================================================
CREATE OR REPLACE FUNCTION fn_on_friend_request_status_change()
RETURNS TRIGGER AS $$
DECLARE
v_user_a uuid;
v_user_b uuid;
BEGIN
-- 응답 시각 자동 기록(처음 1회)
IF NEW.status IS DISTINCT FROM OLD.status
AND OLD.status = 'PENDING'
AND NEW.status IN ('ACCEPTED', 'REJECTED', 'CANCELED')
AND NEW.responded_at IS NULL THEN
NEW.responded_at := now();
END IF;

-- 수락 처리 시 자동 생성
IF NEW.status = 'ACCEPTED' AND OLD.status = 'PENDING' THEN
v_user_a := LEAST(NEW.requester_user_id, NEW.addressee_user_id);
v_user_b := GREATEST(NEW.requester_user_id, NEW.addressee_user_id);

    INSERT INTO friendships (user_id_a, user_id_b)
    VALUES (v_user_a, v_user_b)
    ON CONFLICT DO NOTHING;

    -- 양방향 기본 설정: can_view=true, friend_level=0
    INSERT INTO friend_level_settings (owner_user_id, friend_user_id, can_view, friend_level)
    VALUES
      (NEW.requester_user_id, NEW.addressee_user_id, true, 0),
      (NEW.addressee_user_id, NEW.requester_user_id, true, 0)
    ON CONFLICT (owner_user_id, friend_user_id) DO NOTHING;

END IF;

RETURN NEW;
END;

$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_friend_request_status_change
BEFORE UPDATE ON friend_requests
FOR EACH ROW
EXECUTE FUNCTION fn_on_friend_request_status_change();

-- =========================================================
-- 11) VIEWS: 친구 열람용 (can_view + 레벨 비교 + friendships 존재)
-- =========================================================

-- 11-1) 친구가 볼 수 있는 events
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

-- 11-2) 친구가 볼 수 있는 work_shifts (visibility_level=0 고정)
CREATE OR REPLACE VIEW v_visible_work_shifts_for_friend AS
SELECT
  ws.*,
  fls.friend_user_id AS viewer_user_id
FROM work_shifts ws
JOIN friend_level_settings fls
  ON fls.owner_user_id = ws.owner_user_id
 AND fls.can_view = true
WHERE ws.deleted_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM friendships f
    WHERE f.user_id_a = LEAST(ws.owner_user_id, fls.friend_user_id)
      AND f.user_id_b = GREATEST(ws.owner_user_id, fls.friend_user_id)
  )
  AND fls.friend_level >= ws.visibility_level; -- 항상 0

/* =========================================================
   (OPTIONAL) 운영 권장: DB timezone을 UTC로
   ALTER DATABASE your_db_name SET timezone TO 'UTC';
   ========================================================= */
$$
