# 그룹 기능 서버 개발 요청서

## 1. 문서 목적

현재 Flutter의 그룹 방 목록과 `GroupCalendarPreviewPage`는 고정된 더미 데이터로 동작한다.
이 문서는 해당 화면을 실제 서버 데이터로 전환하기 위해 필요한 그룹 도메인, DB migration,
REST API, 권한·공개 규칙, 오류 코드, 테스트와 배포 조건을 서버 개발 요청 단위로 정의한다.

- Base URL: `/api/v1`
- 인증: Bearer JWT
- Content-Type: `application/json`
- 성공 응답: `{ "success": true, "data": ..., "message": "..." }`
- 실패 응답:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "사용자 친화적 오류 메시지"
  }
}
```

이 문서는 구현 요청 초안이다. 아래에서 `확정`으로 표시한 내용은 현재 Flutter/DB 계약에
근거하며, `기본안`은 서버 구현 시 우선 적용할 권장안, `협의 필요`는 제품 정책 확정이 필요한
항목이다.

---

## 2. 현재 확인된 상태

### 2.1 확정된 현재 계약

- 사용자 1명은 캘린더 1개를 소유한다.
  - 별도 `calendars` 테이블 없이 `events.owner_user_id`,
    `work_shifts.owner_user_id`가 소유자를 나타낸다.
- 친구 캘린더 공개는 서버가 아래 조건으로 판정한다.
  - `friendships`에 두 사용자의 친구 관계가 존재한다.
  - `friend_level_settings.owner_user_id = 일정 소유자`
  - `friend_level_settings.friend_user_id = 조회자`
  - `can_view = true`
  - 개인 일정은 `friend_level >= events.visibility_level`
  - 근무는 `work_shifts.visibility_level = 0`
- 친구 공개 조회용 DB view는 다음 두 개다.
  - `v_visible_events_for_friend`
  - `v_visible_work_shifts_for_friend`
- 메인·친구 캘린더의 기존 범위 응답은 `work_shifts`, `events` 배열을 반환한다.
- 그룹 화면은 구성원별 아래 정보를 필요로 한다.
  - 사용자 ID, 이름, 프로필 이미지
  - 날짜별 근무 코드·이름·색상·시간
  - 공개가 허용된 개인 일정
  - 그룹명, 구성원 수, 구성원 미리보기

### 2.2 다이어그램 사용 시 주의

`schema.drawio`와 `visibility_flow.drawio`에는 과거의 `calendars`,
`calendar_shares` 구조가 남아 있다. 서버 migration의 기준은 해당 다이어그램이 아니라
`AGENTS.md`와 `_docs/PROJECT_CONTEXT.md`에 기록된 최종 단일 캘린더 DDL이다.

이번 그룹 migration 적용 후 아래 문서도 실제 schema에 맞게 후속 갱신해야 한다.

- `schema.drawio`
- `visibility_flow.drawio`
- 서버 Swagger/OpenAPI

---

## 3. 서버 구현 범위

### 3.1 P0 — Flutter 더미 데이터를 실제 데이터로 전환하는 데 필수

| 기능 | Method | Endpoint |
| --- | --- | --- |
| 그룹 생성 | `POST` | `/api/v1/groups` |
| 내 그룹 목록 | `GET` | `/api/v1/groups` |
| 그룹 상세 | `GET` | `/api/v1/groups/:group_id` |
| 그룹 캘린더 범위 | `GET` | `/api/v1/groups/:group_id/calendar/range` |
| 그룹 초대 생성 | `POST` | `/api/v1/groups/:group_id/invitations` |
| 받은 그룹 초대 목록 | `GET` | `/api/v1/group-invitations/received` |
| 그룹 초대 응답 | `PUT` | `/api/v1/group-invitations/:invitation_id/respond` |

### 3.2 P1 — 실제 운영 관리에 필요

| 기능 | Method | Endpoint |
| --- | --- | --- |
| 그룹 정보 수정 | `PATCH` | `/api/v1/groups/:group_id` |
| 그룹 삭제 | `DELETE` | `/api/v1/groups/:group_id` |
| 그룹 초대 목록 | `GET` | `/api/v1/groups/:group_id/invitations` |
| 그룹 초대 취소 | `PUT` | `/api/v1/group-invitations/:invitation_id/cancel` |
| 그룹 멤버 제거 | `DELETE` | `/api/v1/groups/:group_id/members/:user_id` |
| 그룹 멤버 역할 변경 | `PATCH` | `/api/v1/groups/:group_id/members/:user_id` |
| 그룹 나가기 | `POST` | `/api/v1/groups/:group_id/leave` |
| 그룹 소유권 이전 | `PUT` | `/api/v1/groups/:group_id/owner` |

### 3.3 이번 범위에 포함하지 않는 기능

- 그룹이 소유하는 별도 일정/근무 데이터
- 그룹 채팅
- 공개 검색 가능한 그룹
- 가입 코드/링크
- 그룹별 별도 캘린더 공개 레벨
- 반복 일정

MVP 그룹 캘린더는 그룹 구성원의 기존 개인 캘린더를 조회자 권한에 맞게 모아 보여주는
aggregate view다.

---

## 4. 권장 도메인 정책

### 4.1 그룹 역할

| 역할 | 설명 |
| --- | --- |
| `OWNER` | 그룹 삭제, 소유권 이전, 모든 관리 작업 가능 |
| `ADMIN` | 그룹 수정, 초대, 일반 멤버 제거 가능 |
| `MEMBER` | 그룹 조회, 캘린더 조회, 본인 그룹 나가기 가능 |

### 4.2 캘린더 공개 기본안

그룹 멤버십 자체가 다른 사용자의 캘린더 공개 권한을 생성하거나 확대하지 않는다.

- 내 데이터: 그룹 캘린더 응답에 모두 포함
- 다른 멤버 데이터:
  - 기존 친구 관계와 `friend_level_settings` 조건을 그대로 적용
  - `can_view=false`이면 근무·일정 모두 미노출
  - 이벤트는 조회자의 `friend_level`보다 높은 `visibility_level`이면 미노출
- 그룹 가입/탈퇴는 `friendships`, `friend_level_settings`를 생성·수정·삭제하지 않음
- 친구 관계가 나중에 삭제되더라도 그룹 멤버십은 유지하되 해당 사용자의 캘린더 데이터는
  `DENIED` 상태로 반환

이 정책을 사용하면 그룹 기능이 기존 친구 공개 설정을 우회하지 않는다.

### 4.3 초대 기본안

- 그룹 생성자는 즉시 `OWNER` 멤버가 된다.
- 생성 요청의 `invitee_user_ids`는 즉시 멤버로 추가하지 않고 `PENDING` 초대를 만든다.
- 초대받은 사용자가 수락할 때 `group_members`에 추가한다.
- MVP 초대 대상은 생성자/관리자와 수락된 친구 관계인 사용자로 제한한다.
- 같은 그룹·사용자에 활성 멤버십 또는 대기 초대가 있으면 중복 생성하지 않는다.

### 4.4 협의 필요 항목과 권장값

| 항목 | 권장 기본값 | 협의가 필요한 이유 |
| --- | --- | --- |
| 최대 활성 멤버 | 20명 | 3개월 aggregate 응답 크기와 화면 가독성 |
| 초대 만료 | 7일 | 만료 알림·재초대 정책 |
| 그룹명 길이 | 공백 제거 후 1~50자 | UI 한 줄 말줄임과 DB validation |
| 초대 대상 | 수락된 친구만 | 기존 공개 ACL을 재사용하기 위한 조건 |
| 그룹 timezone | 생성자 timezone, 없으면 `Asia/Seoul` | 날짜별 aggregate 기준 |
| 그룹 가입이 캘린더 공개 권한을 부여하는지 | 부여하지 않음 | 기존 사용자 공개 설정 보호 |
| 관리자 제거 권한 | `MEMBER`만 제거 | 관리자 간 권한 충돌 방지 |

그룹 가입만으로 모든 멤버의 캘린더를 공개해야 한다는 제품 결정이 내려지면 이 문서의
기본안으로 구현하면 안 된다. 이 경우 `group_calendar_permissions`와 같은 별도 ACL을 먼저
설계하고 ADR로 확정해야 한다.

---

## 5. DB migration 요청

현재 최종 DDL에 그룹 관련 테이블은 없다. 아래 3개 테이블을 추가하는 방안을 요청한다.

### 5.1 제안 DDL

```sql
-- =========================================================
-- GROUPS
-- =========================================================
CREATE TABLE groups (
  group_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  timezone text NOT NULL,
  created_by_user_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  deleted_by_user_id uuid,

  CONSTRAINT fk_groups_created_by
    FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_groups_deleted_by
    FOREIGN KEY (deleted_by_user_id) REFERENCES users(user_id),
  CONSTRAINT ck_groups_name
    CHECK (char_length(btrim(name)) BETWEEN 1 AND 50)
);

CREATE INDEX idx_groups_created_by_active
ON groups(created_by_user_id, created_at DESC)
WHERE deleted_at IS NULL;

COMMENT ON TABLE groups IS '그룹 방. 캘린더를 별도 소유하지 않고 구성원 개인 캘린더를 aggregate 조회한다.';
COMMENT ON COLUMN groups.timezone IS '그룹 캘린더 날짜 범위 해석에 사용하는 IANA timezone';

-- =========================================================
-- GROUP MEMBERS
-- =========================================================
CREATE TABLE group_members (
  group_member_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL,
  user_id uuid NOT NULL,
  role text NOT NULL DEFAULT 'MEMBER',
  added_by_user_id uuid NOT NULL,
  joined_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  removed_at timestamptz,
  removed_by_user_id uuid,

  CONSTRAINT fk_group_members_group
    FOREIGN KEY (group_id) REFERENCES groups(group_id),
  CONSTRAINT fk_group_members_user
    FOREIGN KEY (user_id) REFERENCES users(user_id),
  CONSTRAINT fk_group_members_added_by
    FOREIGN KEY (added_by_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_group_members_removed_by
    FOREIGN KEY (removed_by_user_id) REFERENCES users(user_id),
  CONSTRAINT ck_group_members_role
    CHECK (role IN ('OWNER', 'ADMIN', 'MEMBER'))
);

CREATE UNIQUE INDEX uq_group_members_active_user
ON group_members(group_id, user_id)
WHERE removed_at IS NULL;

CREATE UNIQUE INDEX uq_group_members_active_owner
ON group_members(group_id)
WHERE role = 'OWNER' AND removed_at IS NULL;

CREATE INDEX idx_group_members_user_active
ON group_members(user_id, joined_at DESC)
WHERE removed_at IS NULL;

CREATE INDEX idx_group_members_group_active
ON group_members(group_id, joined_at ASC)
WHERE removed_at IS NULL;

COMMENT ON TABLE group_members IS '그룹 활성/과거 멤버십과 OWNER/ADMIN/MEMBER 역할';

-- =========================================================
-- GROUP INVITATIONS
-- =========================================================
CREATE TABLE group_invitations (
  invitation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id uuid NOT NULL,
  inviter_user_id uuid NOT NULL,
  invitee_user_id uuid NOT NULL,
  status text NOT NULL DEFAULT 'PENDING',
  message text,
  expires_at timestamptz NOT NULL DEFAULT (now() + interval '7 days'),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  responded_at timestamptz,

  CONSTRAINT fk_group_invitations_group
    FOREIGN KEY (group_id) REFERENCES groups(group_id),
  CONSTRAINT fk_group_invitations_inviter
    FOREIGN KEY (inviter_user_id) REFERENCES users(user_id),
  CONSTRAINT fk_group_invitations_invitee
    FOREIGN KEY (invitee_user_id) REFERENCES users(user_id),
  CONSTRAINT ck_group_invitations_status
    CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELED', 'EXPIRED')),
  CONSTRAINT ck_group_invitations_not_self
    CHECK (inviter_user_id <> invitee_user_id)
);

CREATE UNIQUE INDEX uq_group_invitations_pending
ON group_invitations(group_id, invitee_user_id)
WHERE status = 'PENDING';

CREATE INDEX idx_group_invitations_received
ON group_invitations(invitee_user_id, status, created_at DESC);

CREATE INDEX idx_group_invitations_group
ON group_invitations(group_id, status, created_at DESC);

COMMENT ON TABLE group_invitations IS '그룹 가입 초대. ACCEPTED 시 group_members 활성 row를 생성한다.';
```

### 5.2 서비스 계층에서 보장해야 하는 DB invariant

DB CHECK/index만으로 전부 보장할 수 없으므로 아래 작업은 transaction에서 처리한다.

- 그룹 생성
  - `groups` insert
  - 생성자의 `OWNER` 멤버십 insert
  - 초대 요청이 있으면 `group_invitations` insert
- 초대 수락
  - invitation row `FOR UPDATE`
  - `PENDING`, 미만료, 그룹 활성 상태 확인
  - 초대자와 초대 대상의 친구 관계가 아직 유효한지 재확인
  - 최대 멤버 수 확인
  - `group_members` insert
  - invitation을 `ACCEPTED`로 변경
- 초대 생성/재초대
  - 같은 그룹·대상의 만료된 `PENDING` row를 먼저 `EXPIRED`로 변경
  - 활성 멤버와 실제 `PENDING` 초대가 없을 때 새 초대 insert
- 소유권 이전
  - 기존 owner와 새 owner 멤버십을 잠금
  - 기존 owner를 `ADMIN`, 새 owner를 `OWNER`로 변경
  - 한 transaction 안에서 owner가 최대 1명인 상태 유지
- 그룹 삭제
  - group soft delete
  - 활성 멤버십 `removed_at` 처리
  - 대기 초대를 `CANCELED` 처리
- 초대 만료
  - 읽기/응답 시 `expires_at <= now()`이면 `EXPIRED`로 간주
  - 필요하면 정기 batch로 status 정리

### 5.3 별도 테이블을 만들지 않는 항목

- `group_calendars`: 만들지 않음
- `group_events`: MVP에는 만들지 않음
- `group_calendar_shares`: 기존 친구 ACL을 사용하므로 만들지 않음

---

## 6. 공통 응답 객체

### 6.1 GroupSummary

```json
{
  "group_id": "2b1fdc0b-4240-4e6e-95f5-cdbed7530a2f",
  "name": "우리 병동",
  "timezone": "Asia/Seoul",
  "my_role": "OWNER",
  "member_count": 4,
  "members_preview": [
    {
      "user_id": "uuid-1",
      "name": "박현서",
      "profile_image_url": "https://..."
    },
    {
      "user_id": "uuid-2",
      "name": "김민수",
      "profile_image_url": null
    }
  ],
  "created_at": "2026-07-29T01:00:00.000Z",
  "updated_at": "2026-07-29T01:00:00.000Z"
}
```

- `members_preview`는 최대 4명만 반환한다.
- 이메일·전화번호는 그룹 목록/상세 응답에 포함하지 않는다.
- 정렬은 `OWNER → ADMIN → MEMBER`, 같은 역할은 `joined_at ASC`를 기본으로 한다.

### 6.2 GroupDetail

```json
{
  "group_id": "2b1fdc0b-4240-4e6e-95f5-cdbed7530a2f",
  "name": "우리 병동",
  "timezone": "Asia/Seoul",
  "my_role": "OWNER",
  "member_count": 4,
  "members": [
    {
      "user_id": "uuid-1",
      "name": "박현서",
      "profile_image_url": "https://...",
      "role": "OWNER",
      "joined_at": "2026-07-29T01:00:00.000Z"
    }
  ],
  "created_by_user_id": "uuid-1",
  "created_at": "2026-07-29T01:00:00.000Z",
  "updated_at": "2026-07-29T01:00:00.000Z"
}
```

### 6.3 GroupInvitation

```json
{
  "invitation_id": "invitation-uuid",
  "group": {
    "group_id": "group-uuid",
    "name": "우리 병동",
    "member_count": 4
  },
  "inviter": {
    "user_id": "inviter-uuid",
    "name": "박현서",
    "profile_image_url": null
  },
  "invitee_user_id": "invitee-uuid",
  "status": "PENDING",
  "message": "우리 병동 그룹에 참여해주세요.",
  "expires_at": "2026-08-05T01:00:00.000Z",
  "created_at": "2026-07-29T01:00:00.000Z",
  "responded_at": null
}
```

---

## 7. API 상세

### 7.1 그룹 생성

```
POST /api/v1/groups
```

#### Request

```json
{
  "name": "우리 병동",
  "timezone": "Asia/Seoul",
  "invitee_user_ids": [
    "31d1890d-c132-4668-8daf-bff2942b4ac0",
    "8e0781cc-7994-4556-813a-e89bb7cb54db"
  ]
}
```

| 필드 | 타입 | 필수 | 규칙 |
| --- | --- | --- | --- |
| `name` | string | Y | trim 후 1~50자 |
| `timezone` | string | N | 유효한 IANA timezone, 기본 생성자 timezone |
| `invitee_user_ids` | uuid[] | N | 중복·본인 제외, 수락된 친구만 허용 |

#### Response — `201 Created`

```json
{
  "success": true,
  "data": {
    "group": {
      "group_id": "group-uuid",
      "name": "우리 병동",
      "timezone": "Asia/Seoul",
      "my_role": "OWNER",
      "member_count": 1,
      "members": [
        {
          "user_id": "owner-uuid",
          "name": "박현서",
          "profile_image_url": null,
          "role": "OWNER",
          "joined_at": "2026-07-29T01:00:00.000Z"
        }
      ],
      "created_by_user_id": "owner-uuid",
      "created_at": "2026-07-29T01:00:00.000Z",
      "updated_at": "2026-07-29T01:00:00.000Z"
    },
    "invitations": [
      {
        "invitation_id": "invitation-uuid",
        "invitee_user_id": "31d1890d-c132-4668-8daf-bff2942b4ac0",
        "status": "PENDING",
        "expires_at": "2026-08-05T01:00:00.000Z"
      }
    ]
  },
  "message": "그룹이 생성되었습니다."
}
```

초대 대상 중 하나라도 validation에 실패하면 그룹까지 생성하지 않는 원자적 요청을 기본안으로
한다. 부분 성공을 허용하려면 서버/Flutter가 사용자별 실패 결과를 별도로 처리해야 하므로
MVP에서는 권장하지 않는다.

---

### 7.2 내 그룹 목록 조회

```
GET /api/v1/groups?page=1&limit=20
```

#### Query

| 필드 | 타입 | 필수 | 기본/제한 |
| --- | --- | --- | --- |
| `page` | integer | N | 기본 1, 최소 1 |
| `limit` | integer | N | 기본 20, 최대 100 |

#### Response — `200 OK`

```json
{
  "success": true,
  "data": {
    "groups": [
      {
        "group_id": "group-uuid",
        "name": "우리 병동",
        "timezone": "Asia/Seoul",
        "my_role": "OWNER",
        "member_count": 4,
        "members_preview": [
          {
            "user_id": "owner-uuid",
            "name": "박현서",
            "profile_image_url": null
          }
        ],
        "created_at": "2026-07-29T01:00:00.000Z",
        "updated_at": "2026-07-29T01:00:00.000Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "total_pages": 1
    }
  }
}
```

#### 조회 조건

- 인증 사용자의 `group_members.removed_at IS NULL`
- `groups.deleted_at IS NULL`
- 기본 정렬: `groups.updated_at DESC, groups.group_id DESC`
- `member_count`는 활성 멤버만 집계
- N+1 없이 group summary와 최대 4명 preview를 조회

---

### 7.3 그룹 상세 조회

```
GET /api/v1/groups/:group_id
```

#### Response — `200 OK`

```json
{
  "success": true,
  "data": {
    "group": {
      "group_id": "group-uuid",
      "name": "우리 병동",
      "timezone": "Asia/Seoul",
      "my_role": "MEMBER",
      "member_count": 4,
      "members": [
        {
          "user_id": "owner-uuid",
          "name": "박현서",
          "profile_image_url": null,
          "role": "OWNER",
          "joined_at": "2026-07-29T01:00:00.000Z"
        },
        {
          "user_id": "viewer-uuid",
          "name": "김민수",
          "profile_image_url": null,
          "role": "MEMBER",
          "joined_at": "2026-07-29T02:00:00.000Z"
        }
      ],
      "created_by_user_id": "owner-uuid",
      "created_at": "2026-07-29T01:00:00.000Z",
      "updated_at": "2026-07-29T02:00:00.000Z"
    }
  }
}
```

활성 멤버가 아닌 사용자의 요청은 그룹 존재 여부를 노출하지 않도록 `404 GROUP_NOT_FOUND`로
통일한다.

---

### 7.4 그룹 정보 수정

```
PATCH /api/v1/groups/:group_id
```

#### 권한

- `OWNER`, `ADMIN`

#### Request

```json
{
  "name": "응급실 A팀",
  "timezone": "Asia/Seoul"
}
```

- 최소 한 필드가 있어야 한다.
- `null`로 이름/timezone을 삭제할 수 없다.
- 응답은 갱신된 `GroupDetail`을 반환한다.

---

### 7.5 그룹 삭제

```
DELETE /api/v1/groups/:group_id
```

#### 권한

- `OWNER`만 가능

#### Response — `200 OK`

```json
{
  "success": true,
  "data": {
    "group_id": "group-uuid",
    "deleted_at": "2026-07-29T03:00:00.000Z"
  },
  "message": "그룹이 삭제되었습니다."
}
```

물리 삭제하지 않고 그룹·멤버십을 soft delete하며 대기 초대를 취소한다.

---

### 7.6 그룹 초대 생성

```
POST /api/v1/groups/:group_id/invitations
```

#### 권한

- `OWNER`, `ADMIN`

#### Request

```json
{
  "invitee_user_ids": [
    "31d1890d-c132-4668-8daf-bff2942b4ac0"
  ],
  "message": "우리 병동 그룹에 참여해주세요."
}
```

#### Response — `201 Created`

```json
{
  "success": true,
  "data": {
    "invitations": [
      {
        "invitation_id": "invitation-uuid",
        "invitee_user_id": "31d1890d-c132-4668-8daf-bff2942b4ac0",
        "status": "PENDING",
        "expires_at": "2026-08-05T01:00:00.000Z"
      }
    ]
  },
  "message": "그룹 초대를 보냈습니다."
}
```

그룹 생성과 동일하게 MVP에서는 전체 성공/전체 실패 transaction을 사용한다.

---

### 7.7 받은 그룹 초대 목록

```
GET /api/v1/group-invitations/received?status=PENDING&page=1&limit=20
```

#### Response

```json
{
  "success": true,
  "data": {
    "invitations": [
      {
        "invitation_id": "invitation-uuid",
        "group": {
          "group_id": "group-uuid",
          "name": "우리 병동",
          "member_count": 4
        },
        "inviter": {
          "user_id": "owner-uuid",
          "name": "박현서",
          "profile_image_url": null
        },
        "invitee_user_id": "viewer-uuid",
        "status": "PENDING",
        "message": null,
        "expires_at": "2026-08-05T01:00:00.000Z",
        "created_at": "2026-07-29T01:00:00.000Z",
        "responded_at": null
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 1,
      "total_pages": 1
    }
  }
}
```

#### status

- `PENDING`
- `ACCEPTED`
- `REJECTED`
- `CANCELED`
- `EXPIRED`

---

### 7.8 그룹 초대 응답

```
PUT /api/v1/group-invitations/:invitation_id/respond
```

#### Request

```json
{
  "action": "accept"
}
```

- `action`: `accept | reject`
- 초대받은 인증 사용자만 응답 가능
- `accept` 시 transaction에서 활성 멤버십 생성
- `reject` 시 멤버십을 생성하지 않음

#### Response

```json
{
  "success": true,
  "data": {
    "invitation": {
      "invitation_id": "invitation-uuid",
      "status": "ACCEPTED",
      "responded_at": "2026-07-29T02:00:00.000Z"
    },
    "group": {
      "group_id": "group-uuid",
      "name": "우리 병동",
      "timezone": "Asia/Seoul",
      "my_role": "MEMBER",
      "member_count": 2
    }
  },
  "message": "그룹 초대를 수락했습니다."
}
```

동일 초대의 동시 수락은 row lock과 unique index로 한 번만 성공해야 한다.

#### 그룹 초대 알림 연동

기존 친구 요청 알림과 같은 액션형 알림을 사용할 경우 서버는 다음 타입을 지원해야 한다.

- `GROUP_INVITATION`
- `GROUP_INVITATION_ACCEPTED`
- `GROUP_INVITATION_REJECTED`
- `GROUP_INVITATION_CANCELED`

`GROUP_INVITATION` payload 기본안:

```json
{
  "invitation_id": "invitation-uuid",
  "group_id": "group-uuid",
  "group_name": "우리 병동",
  "inviter_user_id": "owner-uuid",
  "inviter_name": "박현서",
  "profile_image_url": null,
  "invitation_status": "PENDING",
  "expires_at": "2026-08-05T01:00:00.000Z"
}
```

- 초대 생성 transaction 완료 후 수신자 알림을 생성한다.
- 수락/거절 응답에는 처리 완료된 notification 객체를 함께 반환하는 방안을 권장한다.
- 같은 초대의 원본 notification을 완료 상태로 갱신해 중복 카드가 생기지 않게 한다.
- push 발송 실패가 초대 DB transaction을 rollback시키지는 않는다.
- push 재시도는 같은 `invitation_id`를 idempotency key로 사용한다.
- 알림 연동이 P0에서 제외되더라도 `GET /group-invitations/received`가 source of truth여야 한다.
- 현재 Flutter `NotificationType`에는 그룹 타입이 없으므로 서버 타입 배포와 함께 프론트 enum,
  payload parser, accept/reject action routing을 추가해야 한다.

---

### 7.9 그룹 초대 목록/취소

```
GET /api/v1/groups/:group_id/invitations?status=PENDING&page=1&limit=20
PUT /api/v1/group-invitations/:invitation_id/cancel
```

- 조회/취소 권한: `OWNER`, `ADMIN`
- `PENDING` 초대만 취소 가능
- 취소 응답은 변경된 invitation의 `status=CANCELED`, `responded_at`을 반환

---

### 7.10 그룹 멤버 제거

```
DELETE /api/v1/groups/:group_id/members/:user_id
```

#### 권한 기본안

- `OWNER`: `OWNER` 자신을 제외한 `ADMIN`, `MEMBER` 제거 가능
- `ADMIN`: `MEMBER`만 제거 가능
- `MEMBER`: 다른 멤버 제거 불가

#### Response

```json
{
  "success": true,
  "data": {
    "group_id": "group-uuid",
    "user_id": "member-uuid",
    "removed_at": "2026-07-29T03:00:00.000Z"
  },
  "message": "그룹 멤버가 제거되었습니다."
}
```

멤버 제거는 친구 관계와 `friend_level_settings`를 변경하지 않는다.

---

### 7.11 그룹 멤버 역할 변경

```
PATCH /api/v1/groups/:group_id/members/:user_id
```

#### 권한

- `OWNER`만 가능

#### Request

```json
{
  "role": "ADMIN"
}
```

- 허용 값: `ADMIN`, `MEMBER`
- 대상은 같은 그룹의 활성 멤버여야 한다.
- 현재 `OWNER` 역할은 이 endpoint로 변경할 수 없다.
- `OWNER` 변경은 소유권 이전 endpoint만 사용한다.
- 응답은 변경된 member 객체와 그룹 `updated_at`을 반환한다.

---

### 7.12 그룹 나가기

```
POST /api/v1/groups/:group_id/leave
```

- `MEMBER`, `ADMIN`은 본인 활성 멤버십을 soft delete한다.
- `OWNER`는 바로 나갈 수 없다.
  - 다른 활성 멤버에게 소유권 이전 후 나가기
  - 또는 그룹 삭제

---

### 7.13 그룹 소유권 이전

```
PUT /api/v1/groups/:group_id/owner
```

#### 권한

- 현재 `OWNER`

#### Request

```json
{
  "new_owner_user_id": "member-uuid"
}
```

- 새 owner는 같은 그룹의 활성 멤버여야 한다.
- 기존 owner의 새 역할은 `ADMIN`을 기본으로 한다.
- 응답은 갱신된 `GroupDetail`을 반환한다.

---

## 8. 그룹 캘린더 범위 조회

```
GET /api/v1/groups/:group_id/calendar/range
  ?start_date=2026-06-01
  &end_date=2026-08-31
```

### 8.1 접근 조건

- 조회자는 그룹의 활성 멤버여야 한다.
- 그룹이 soft delete 상태면 조회할 수 없다.
- 조회 기간은 `YYYY-MM-DD`, 양 끝 포함이다.
- 최대 범위는 100일을 권장한다.
  - Flutter의 전월 1일~다음월 말일 조회를 수용한다.

### 8.2 응답 구조

멤버 정보를 날짜마다 반복하지 않는 정규화 응답을 사용한다.

```json
{
  "success": true,
  "data": {
    "group": {
      "group_id": "group-uuid",
      "name": "우리 병동",
      "timezone": "Asia/Seoul"
    },
    "range": {
      "start_date": "2026-06-01",
      "end_date": "2026-08-31"
    },
    "members": [
      {
        "user_id": "viewer-uuid",
        "name": "박현서",
        "profile_image_url": null,
        "role": "OWNER",
        "joined_at": "2026-07-01T00:00:00.000Z",
        "calendar_access": "SELF"
      },
      {
        "user_id": "friend-uuid",
        "name": "김민수",
        "profile_image_url": "https://...",
        "role": "MEMBER",
        "joined_at": "2026-07-02T00:00:00.000Z",
        "calendar_access": "VISIBLE"
      },
      {
        "user_id": "hidden-uuid",
        "name": "이지연",
        "profile_image_url": null,
        "role": "MEMBER",
        "joined_at": "2026-07-03T00:00:00.000Z",
        "calendar_access": "DENIED"
      }
    ],
    "work_shifts": [
      {
        "owner_user_id": "friend-uuid",
        "work_shift_id": "work-shift-uuid",
        "work_date": "2026-07-29",
        "shift_type_code": "D",
        "shift_type_name": "데이",
        "shift_type_color": "#FFFF9500",
        "start_time": "07:00",
        "end_time": "15:00",
        "note": null,
        "created_at": "2026-07-01T00:00:00.000Z",
        "updated_at": "2026-07-01T00:00:00.000Z"
      }
    ],
    "events": [
      {
        "owner_user_id": "friend-uuid",
        "event_id": "event-uuid",
        "title": "병원 예약",
        "memo": null,
        "place": "서울",
        "all_day": false,
        "start_at": "2026-07-29T00:30:00.000Z",
        "end_at": "2026-07-29T01:30:00.000Z",
        "visibility_level": 1
      }
    ]
  }
}
```

### 8.3 `calendar_access`

| 값 | 의미 |
| --- | --- |
| `SELF` | 조회자 본인. 본인 데이터 전체 반환 |
| `VISIBLE` | 기존 친구 ACL을 통과. 허용된 데이터만 반환 |
| `DENIED` | 친구 관계 없음 또는 `can_view=false`. 데이터 배열에 해당 owner 항목 없음 |

`DENIED` 멤버를 members 배열에서 제거하지 않는다. Flutter는 멤버가 그룹에 존재하지만
캘린더를 공유하지 않는 상태와 실제 휴무/일정 없음 상태를 구분해야 한다.

- `VISIBLE`인데 해당 날짜의 근무 row가 없음: 근무 미등록/휴무로 표현 가능
- `DENIED`: 근무 없음으로 오해하지 않고 `공개 안 함` 또는 잠금 상태로 표현

### 8.4 공개 데이터 계산

#### 본인

- `work_shifts.owner_user_id = viewer_user_id`
- `events.owner_user_id = viewer_user_id`
- soft delete 제외

#### 다른 그룹 멤버

- `v_visible_work_shifts_for_friend`
  - `owner_user_id = member_user_id`
  - `viewer_user_id = authenticated_user_id`
- `v_visible_events_for_friend`
  - 같은 owner/viewer 조건

#### 날짜 범위

- 근무:

```sql
work_date BETWEEN :start_date::date AND :end_date::date
```

- 이벤트:

```sql
start_at < (
  (:end_date::date + 1)::timestamp
  AT TIME ZONE :group_timezone
)
AND end_at > (
  :start_date::date::timestamp
  AT TIME ZONE :group_timezone
)
```

`events.end_at`은 exclusive이므로 시작일 00:00에 끝난 일정은 범위에 포함하지 않는다.
`work_shifts.work_date`는 최종 DDL의 사용자 timezone 기준 날짜를 변환하지 않고 그대로 반환한다.
서로 다른 timezone 사용자가 한 그룹에 참여할 수 있어야 한다면 근무 날짜를 그룹 timezone으로
재배치할지 여부를 제품 정책으로 먼저 확정해야 한다.

### 8.5 집계 규칙

- 서버는 숨겨진 근무/일정의 개수도 노출하지 않는다.
- Flutter의 `근무 N명`은 응답에 포함된 visible work shift 기준으로 계산한다.
- Flutter의 `일정 N개`는 응답에 포함된 visible event 기준으로 계산한다.
- hidden row의 존재 여부를 추론할 수 있는 `actual_working_count`,
  `hidden_event_count` 같은 필드는 반환하지 않는다.
- 정렬:
  - `members`: 조회자 본인 먼저, 이후 `OWNER → ADMIN → MEMBER`, `joined_at ASC`
  - `work_shifts`: `work_date ASC`, `owner_user_id ASC`
  - `events`: `start_at ASC`, `event_id ASC`

### 8.6 성능 요구

- 활성 멤버 조회 후 멤버마다 API/SQL을 반복하는 N+1 구현 금지
- 멤버 목록, visible shifts, visible events를 고정된 소수 쿼리로 조회
- 최대 멤버 20명·최대 100일 범위를 기준으로 Stage 응답 시간 측정
- 압축 전 응답 크기와 DB query time 로깅
- 다음 기존 인덱스를 활용
  - `idx_work_shifts_owner_date_not_deleted`
  - `idx_events_owner_start_not_deleted`
  - `idx_events_owner_visibility_not_deleted`
  - `idx_fls_owner_can_view_level`
- 실제 실행 계획에서 필요하면 group member용 제안 인덱스를 보완

---

## 9. 권한 매트릭스

| 작업 | OWNER | ADMIN | MEMBER | 비멤버 |
| --- | --- | --- | --- | --- |
| 그룹 목록에서 본인 그룹 조회 | O | O | O | X |
| 그룹 상세 조회 | O | O | O | X |
| 그룹 캘린더 조회 | O | O | O | X |
| 이름/timezone 수정 | O | O | X | X |
| 초대 생성/목록/취소 | O | O | X | X |
| ADMIN 역할 부여/해제 | O | X | X | X |
| MEMBER 제거 | O | O | X | X |
| ADMIN 제거 | O | X | X | X |
| 그룹 나가기 | 이전/삭제 후 | O | O | X |
| 소유권 이전 | O | X | X | X |
| 그룹 삭제 | O | X | X | X |

모든 actor ID는 요청 body가 아니라 JWT 인증 사용자에서 가져온다.

---

## 10. Validation 및 오류 코드

| HTTP | 코드 | 조건 |
| --- | --- | --- |
| 400 | `INVALID_GROUP_NAME` | 이름 누락, trim 후 빈 값, 길이 초과 |
| 400 | `INVALID_GROUP_TIMEZONE` | 지원하지 않는 IANA timezone |
| 400 | `INVALID_DATE_RANGE` | 날짜 파싱 실패 또는 시작일이 종료일보다 늦음 |
| 400 | `GROUP_CALENDAR_RANGE_TOO_LARGE` | 최대 허용 기간 초과 |
| 400 | `INVALID_GROUP_INVITATION_ACTION` | `accept/reject` 외 값 |
| 400 | `INVALID_GROUP_MEMBER_ROLE` | `ADMIN/MEMBER` 외 역할 변경 값 |
| 401 | `UNAUTHORIZED` | 인증 토큰 없음/만료 |
| 403 | `GROUP_PERMISSION_DENIED` | 멤버지만 해당 관리 역할이 없음 |
| 404 | `GROUP_NOT_FOUND` | 그룹 없음, 삭제됨, 조회 권한 없는 비멤버 |
| 404 | `GROUP_MEMBER_NOT_FOUND` | 대상 활성 멤버 없음 |
| 404 | `GROUP_INVITATION_NOT_FOUND` | 초대 없음 또는 조회자와 무관 |
| 409 | `GROUP_MEMBER_ALREADY_EXISTS` | 이미 활성 멤버 |
| 409 | `GROUP_INVITATION_ALREADY_PENDING` | 같은 그룹·사용자 대기 초대 존재 |
| 409 | `GROUP_INVITATION_ALREADY_PROCESSED` | 이미 응답/취소된 초대 |
| 409 | `GROUP_INVITATION_EXPIRED` | 초대 만료 |
| 409 | `GROUP_INVITEE_NOT_FRIEND` | 초대자와 대상이 수락된 친구가 아님 |
| 409 | `GROUP_MEMBER_LIMIT_REACHED` | 최대 활성 멤버 수 도달 |
| 409 | `GROUP_OWNER_CANNOT_LEAVE` | 소유권 이전/삭제 전 owner 나가기 |
| 409 | `GROUP_OWNER_CANNOT_BE_REMOVED` | owner 제거 요청 |
| 409 | `INVALID_GROUP_OWNER_TRANSFER` | 새 owner가 활성 멤버가 아님 |

에러 응답은 기존 `handleApiError()`가 파싱할 수 있도록 반드시 공통 실패 형식을 유지한다.

---

## 11. Express 구현 구조 요청

서버 실제 폴더 규칙에 맞추되 책임은 아래처럼 분리한다.

```text
Router
  → auth middleware
  → request validation
  → GroupController
  → GroupService
  → GroupRepository / DB
```

권장 역할:

- route
  - path/method 등록
  - auth middleware 연결
  - validation middleware 연결
- validation
  - body/path/query 타입, UUID, 날짜, timezone, 배열 중복 검증
- controller
  - 인증 사용자 ID와 검증된 입력을 service에 전달
  - 공통 성공 응답 형식 생성
- service
  - 역할/멤버십/친구 관계/공개 정책 판정
  - transaction 경계
  - 도메인 오류를 공통 AppError로 변환
- repository
  - SQL/ORM query
  - soft delete 조건
  - N+1 없는 aggregate 조회

---

## 12. 로깅·모니터링

- 모든 요청에 기존 request ID를 유지한다.
- 구조화 로그 필드:
  - `request_id`
  - `actor_user_id`
  - `group_id`
  - `action`
  - `result`
  - `duration_ms`
  - calendar range 조회 시 `member_count`, `range_days`, `row_count`
- 일정 제목, 메모, 장소와 초대 메시지는 로그에 남기지 않는다.
- 권한 거절은 warning, 예상 validation 오류는 info, transaction/DB 오류는 error로 구분한다.

---

## 13. 환경변수 제안

| 변수 | 필수 | 기본값 | 설명 |
| --- | --- | --- | --- |
| `GROUP_MEMBER_LIMIT` | N | `20` | 그룹 최대 활성 멤버 |
| `GROUP_INVITATION_TTL_DAYS` | N | `7` | 초대 만료 일수 |
| `GROUP_CALENDAR_MAX_RANGE_DAYS` | N | `100` | 그룹 캘린더 최대 조회 일수 |

기본값을 코드와 OpenAPI에 동일하게 기록하고 Stage/Production 차이가 있으면 서버 배포 문서에
명시한다.

---

## 14. 서버 테스트 요청

### 14.1 단위 테스트

- 그룹명/timezone/date range validation
- 역할별 permission matrix
- `ADMIN/MEMBER` 역할 변경과 `OWNER` 직접 변경 차단
- 초대 가능 친구 관계 판정
- `calendar_access` 계산
- event visibility level 비교

### 14.2 repository/integration 테스트

- 그룹 생성 시 group + owner + invitations 원자적 생성
- 중복 활성 멤버/대기 초대 unique index
- 동시 초대 수락 시 멤버십 1건만 생성
- soft delete 그룹이 목록/상세/캘린더에서 제외
- pagination total/total_pages 정확성
- 그룹 상세의 이메일/전화번호 미노출

### 14.3 공개 규칙 회귀

한 그룹 안에 아래 사용자를 함께 구성해 검증한다.

1. 조회자 본인
   - 본인 근무·일정 전체 노출
2. `can_view=true`, `friend_level=2`
   - 근무 노출
   - `visibility_level=0~2` 이벤트 노출
   - `visibility_level=3` 이벤트 미노출
3. `can_view=false`
   - members에는 `DENIED`
   - work_shifts/events에는 해당 owner row 없음
4. 친구 관계 없음
   - members에는 `DENIED`
   - 데이터 미노출
5. soft deleted 근무/일정
   - 응답 제외

### 14.4 날짜/시간 테스트

- 월 경계를 포함한 전월~다음월 최대 3개월
- 윤년 2월
- 이벤트의 범위 겹침
- `end_at` exclusive
- group timezone과 UTC event timestamp
- `work_date`의 날짜 문자열 보존

### 14.5 API 계약 테스트

- 모든 성공 응답에 `success=true`, `data`
- 모든 실패 응답에 `success=false`, `error.code`, `error.message`
- 기존 Flutter color parser가 처리할 수 있는 `shift_type_color`
- `owner_user_id`가 모든 그룹 calendar shift/event row에 존재
- list/detail/calendar response에서 null 가능 필드의 타입 안정성

---

## 15. Swagger/OpenAPI 요청

아래 schema를 재사용 가능한 component로 등록한다.

- `GroupSummary`
- `GroupDetail`
- `GroupMember`
- `GroupInvitation`
- `GroupCalendarRange`
- `GroupCalendarMember`
- `GroupCalendarWorkShift`
- `GroupCalendarEvent`
- `Pagination`
- 공통 error schema

각 endpoint에 200/201, 400, 401, 403, 404, 409 예시와 role requirement를 기록한다.

---

## 16. Flutter 연동 계약

서버 구현 완료 후 Flutter에서 아래 작업이 이어진다.

```text
FriendListPage
  → GET /groups
  → GroupSummary 목록
  → 그룹 카드 선택
  → GET /groups/:group_id
  → GET /groups/:group_id/calendar/range
  → GroupCalendarRangeState
  → CalendarDayPresentation
  → CalendarViewport / CalendarMonthView
```

필요한 신규 Flutter 모델:

- `GroupSummaryApiModel`
- `GroupDetailApiModel`
- `GroupMemberApiModel`
- `GroupInvitationApiModel`
- `GroupCalendarRangeResponse`
- `GroupCalendarMemberApiModel`

기존 `CalendarRangeState`는 한 사용자만 표현하므로 그룹 aggregate에 그대로 사용하지 않는다.
`owner_user_id`와 멤버 접근 상태를 보존하는 별도 `GroupCalendarRangeState`가 필요하다.

서버가 준비되기 전까지 현재 더미 생성기는 유지한다. Stage API가 배포되고 계약 테스트가
통과한 뒤 더미 데이터를 제거한다.

---

## 17. 구현 순서

1. 제품 정책 확정
   - 그룹 가입이 캘린더 공개 권한을 부여하는지
   - 최대 멤버/초대 만료/timezone/관리자 권한
2. DB migration
   - `groups`
   - `group_members`
   - `group_invitations`
   - 인덱스/COMMENT
3. 그룹 생성·목록·상세
4. 초대 생성·목록·응답
5. 수정·삭제·멤버 역할 변경·제거·나가기·소유권 이전
6. 그룹 calendar range aggregate
7. unit/integration/API 계약 테스트
8. Swagger 및 schema/visibility 다이어그램 갱신
9. Stage 배포
10. Flutter 실제 API 연동

---

## 18. 완료 조건

- [ ] P0 endpoint 구현 및 Swagger 반영
- [ ] P1 endpoint 구현 또는 후속 배포 범위·일정 확정
- [ ] 제안 migration의 apply/rollback 스크립트 제공
- [ ] 그룹 생성자는 정확히 한 명의 active `OWNER`
- [ ] 그룹 목록은 active membership만 반환하고 pagination 지원
- [ ] 그룹 상세는 비멤버에게 노출되지 않음
- [ ] 초대 수락은 transaction과 동시성 테스트 통과
- [ ] 그룹 캘린더가 본인/친구 ACL/비공개 멤버를 구분
- [ ] 숨겨진 근무·일정의 존재나 개수를 노출하지 않음
- [ ] 20명·100일 기준 N+1 없이 성능 검증
- [ ] 공통 성공/실패 응답 형식 준수
- [ ] request ID·구조화 로그·오류 레벨 적용
- [ ] 환경변수와 Stage/Production 차이 문서화
- [ ] `schema.drawio`, `visibility_flow.drawio`를 최종 구조로 갱신
- [ ] Flutter 연동용 Stage endpoint와 예시 응답 전달

---

## 19. 서버팀 확인 요청

구현 시작 전 아래 항목에 답변이 필요하다.

1. 그룹 가입만으로 멤버 캘린더 공개를 허용할지, 기존 친구 ACL을 유지할지
2. 초대 대상을 수락된 친구로 제한할지
3. 최대 멤버 수와 초대 만료 기간
4. `OWNER/ADMIN/MEMBER` 3단계 역할을 사용할지
5. 그룹 timezone을 저장할지, 모든 그룹을 `Asia/Seoul`로 고정할지
6. calendar range 최대 100일을 수용할 수 있는지
7. 응답 color가 현재와 같은 `#AARRGGBB` 문자열인지
8. migration·Swagger·Stage 배포 예상 일정
