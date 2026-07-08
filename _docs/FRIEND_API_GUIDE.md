# 친구 관리 API 가이드라인

## 개요

이 문서는 친구 관리 기능의 백엔드 API 구현을 위한 가이드라인입니다.

### 기본 정보

- **Base URL**: `/api/v1`
- **인증**: Bearer Token (JWT)
- **Content-Type**: `application/json`

### 응답 형식

```typescript
// 성공 응답
{
  "success": true,
  "data": { ... },
  "message": "성공 메시지"
}

// 실패 응답
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "사용자 친화적 에러 메시지"
  }
}
```

---

## API 엔드포인트

### 1. 친구 목록 조회

내 친구 목록을 조회합니다.

#### Request

```
GET /api/v1/friends
```

**Headers**

```
Authorization: Bearer {access_token}
```

**Query Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `page` | number | N | 페이지 번호 (기본값: 1) |
| `limit` | number | N | 페이지당 항목 수 (기본값: 20, 최대: 100) |

#### Response

```json
{
  "success": true,
  "data": {
    "friends": [
      {
        "user_id": "uuid",
        "name": "홍길동",
        "email": "hong@email.com",
        "phone": null,
        "profile_image_url": "https://...",
        "friend_level": 2,
        "can_view": true,
        "created_at": "2026-01-04T12:00:00Z"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 5,
      "total_pages": 1
    }
  }
}
```

#### 구현 참고

```sql
-- 친구 목록 조회 쿼리
SELECT
  u.user_id,
  u.name,
  u.email,
  u.phone,
  u.profile_image_url,
  fls.friend_level,
  fls.can_view,
  f.created_at
FROM friendships f
JOIN users u ON (
  (f.user_id_a = :my_user_id AND f.user_id_b = u.user_id)
  OR
  (f.user_id_b = :my_user_id AND f.user_id_a = u.user_id)
)
JOIN friend_level_settings fls ON (
  fls.owner_user_id = :my_user_id
  AND fls.friend_user_id = u.user_id
)
ORDER BY u.name ASC
LIMIT :limit OFFSET :offset;
```

---

### 2. 친구 캘린더 기간 조회

친구 목록에서 친구를 선택했을 때 조회할 읽기 전용 캘린더 데이터를 반환합니다.
서버는 친구가 현재 사용자에게 설정한 `can_view`와 `friend_level`을 기준으로
근무표와 개인 일정을 필터링합니다.

#### Request

```
GET /api/v1/friends/:friend_user_id/calendar/range
```

**Headers**

```
Authorization: Bearer {access_token}
```

**Path Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `friend_user_id` | uuid | Y | 조회할 친구 사용자 ID |

**Query Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `start_date` | string | Y | 조회 시작일, `YYYY-MM-DD` |
| `end_date` | string | Y | 조회 종료일, `YYYY-MM-DD` |

#### Response

```json
{
  "success": true,
  "data": {
    "work_shifts": [
      {
        "work_shift_id": "uuid",
        "work_date": "2026-07-05",
        "shift_type_code": "D",
        "shift_type_name": "데이",
        "shift_type_color": "#FF34C759",
        "start_time": "07:00",
        "end_time": "15:00",
        "note": null,
        "created_at": "2026-07-01T00:00:00Z",
        "updated_at": "2026-07-01T00:00:00Z"
      }
    ],
    "events": [
      {
        "event_id": "uuid",
        "title": "약속",
        "memo": null,
        "place": "서울",
        "all_day": false,
        "start_at": "2026-07-05T10:00:00Z",
        "end_at": "2026-07-05T11:00:00Z",
        "visibility_level": 1
      }
    ]
  }
}
```

#### 공개 레벨 규칙

- 조회자: 현재 인증 사용자(`viewer_user_id`)
- 캘린더 소유자: `friend_user_id`
- 접근 설정: `friend_level_settings.owner_user_id = :friend_user_id`
  AND `friend_level_settings.friend_user_id = :viewer_user_id`
- 근무표 노출: `can_view = true`인 친구 관계이면 조회 가능
  (`work_shifts.visibility_level = 0`)
- 개인 일정 노출: `can_view = true`
  AND `friend_level_settings.friend_level >= events.visibility_level`
- 응답에는 조건을 통과한 데이터만 포함하고, 프론트는 추가 필터링을 하지 않습니다.

#### 구현 참고

```sql
-- 친구가 현재 사용자에게 공개한 개인 일정
SELECT *
FROM v_visible_events_for_friend
WHERE owner_user_id = :friend_user_id
  AND viewer_user_id = :viewer_user_id
  AND start_at < (:end_date::date + interval '1 day')
  AND end_at >= :start_date::date
ORDER BY start_at ASC;

-- 친구가 현재 사용자에게 공개한 근무표
SELECT *
FROM v_visible_work_shifts_for_friend
WHERE owner_user_id = :friend_user_id
  AND viewer_user_id = :viewer_user_id
  AND work_date BETWEEN :start_date::date AND :end_date::date
ORDER BY work_date ASC;
```

#### Error Codes

| 코드 | 메시지 | 설명 |
|------|--------|------|
| `FRIEND_NOT_FOUND` | 친구 관계를 찾을 수 없습니다. | 친구가 아니거나 존재하지 않는 사용자 |
| `CALENDAR_ACCESS_DENIED` | 친구 캘린더를 볼 수 없습니다. | 친구가 현재 사용자에게 `can_view=false`로 설정 |
| `INVALID_DATE_RANGE` | 조회 기간이 올바르지 않습니다. | 날짜 형식 오류 또는 시작일이 종료일보다 늦음 |

---

### 3. 사용자 검색 (친구 추가용)

이메일 또는 전화번호로 사용자를 검색합니다.
이메일과 전화번호는 사용자 식별용 유니크 값이므로 성공 응답은 항상 `data.user`
단일 객체 1개를 반환합니다. 검색 결과가 없으면 빈 배열이 아니라
`USER_NOT_FOUND` 에러를 반환합니다.

#### Request

```
GET /api/v1/users/search
```

**Headers**

```
Authorization: Bearer {access_token}
```

**Query Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `query` | string | Y | 이메일 또는 전화번호 |

프론트엔드는 API 호출 전에 이메일 형식 또는 전화번호 형식인지 먼저 검증합니다.
전화번호는 E.164(`+821012345678`) 또는 국내 입력형(`010-1234-5678`,
`01012345678`)을 허용합니다. 전화번호 검색 요청은 API 호출 직전에
`000-0000-0000` 또는 `000-000-0000` 형식으로 정규화합니다. 형식이 맞지
않으면 검색창 아래 말풍선으로 안내하고 API를 호출하지 않습니다.

#### Response

```json
{
  "success": true,
  "data": {
    "user": {
      "user_id": "uuid",
      "name": "홍길동",
      "email": "hong@email.com",
      "profile_image_url": "https://...",
      "is_friend": false,
      "has_pending_request": false,
      "pending_request_direction": null
    }
  }
}
```

**필드 설명**
| 필드 | 타입 | 설명 |
|------|------|------|
| `is_friend` | boolean | 이미 친구 관계인지 여부 |
| `has_pending_request` | boolean | 대기중인 요청이 있는지 여부 |
| `pending_request_direction` | string? | 대기중인 요청 방향 ("sent" / "received" / null) |

#### Error Codes

| 코드             | 메시지                                      | 설명                    |
| ---------------- | ------------------------------------------- | ----------------------- |
| `USER_NOT_FOUND` | 해당 사용자를 찾을 수 없습니다.             | 검색 결과 없음          |
| `INVALID_QUERY`  | 올바른 이메일 또는 전화번호를 입력해주세요. | 입력값 유효성 검증 실패 |

---

### 4. 친구 요청 보내기

새로운 친구 요청을 생성합니다.

#### Request

```
POST /api/v1/friend-requests
```

**Headers**

```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Body**

```json
{
  "addressee_user_id": "uuid",
  "message": "친구가 되어주세요!" // 선택
}
```

#### Response

```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "requester_user_id": "uuid",
    "addressee_user_id": "uuid",
    "status": "PENDING",
    "message": "친구가 되어주세요!",
    "created_at": "2026-01-04T12:00:00Z"
  },
  "message": "친구 요청을 보냈습니다."
}
```

#### Error Codes

| 코드                     | 메시지                                      | 설명                 |
| ------------------------ | ------------------------------------------- | -------------------- |
| `SELF_REQUEST`           | 자기 자신에게 친구 요청을 보낼 수 없습니다. | 자기 자신에게 요청   |
| `ALREADY_FRIENDS`        | 이미 친구 관계입니다.                       | 이미 친구인 사용자   |
| `PENDING_REQUEST_EXISTS` | 이미 대기 중인 요청이 있습니다.             | 중복 요청            |
| `USER_NOT_FOUND`         | 해당 사용자를 찾을 수 없습니다.             | 존재하지 않는 사용자 |

#### 구현 참고

```typescript
// 비즈니스 로직 순서
1. 자기 자신 체크 (requester_user_id !== addressee_user_id)
2. 대상 사용자 존재 체크
3. 이미 친구인지 체크 (friendships 테이블)
4. 대기중인 요청 있는지 체크 (양방향)
5. friend_requests INSERT
```

---

### 5. 받은 친구 요청 목록 조회

내가 받은 친구 요청 목록을 조회합니다.

#### Request

```
GET /api/v1/friend-requests/received
```

**Headers**

```
Authorization: Bearer {access_token}
```

**Query Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `status` | string | N | 필터링할 상태 (PENDING / ACCEPTED / REJECTED) |
| `page` | number | N | 페이지 번호 (기본값: 1) |
| `limit` | number | N | 페이지당 항목 수 (기본값: 20) |

#### Response

```json
{
  "success": true,
  "data": {
    "requests": [
      {
        "request_id": "uuid",
        "requester": {
          "user_id": "uuid",
          "name": "박철수",
          "email": "park@email.com",
          "profile_image_url": "https://..."
        },
        "status": "PENDING",
        "message": "친구가 되어주세요!",
        "created_at": "2026-01-04T12:00:00Z",
        "responded_at": null
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 3,
      "total_pages": 1
    }
  }
}
```

---

### 6. 보낸 친구 요청 목록 조회

내가 보낸 친구 요청 목록을 조회합니다.

#### Request

```
GET /api/v1/friend-requests/sent
```

**Headers**

```
Authorization: Bearer {access_token}
```

**Query Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `status` | string | N | 필터링할 상태 (PENDING / ACCEPTED / REJECTED / CANCELED) |
| `page` | number | N | 페이지 번호 (기본값: 1) |
| `limit` | number | N | 페이지당 항목 수 (기본값: 20) |

#### Response

```json
{
  "success": true,
  "data": {
    "requests": [
      {
        "request_id": "uuid",
        "addressee": {
          "user_id": "uuid",
          "name": "이영수",
          "email": "lee@email.com",
          "profile_image_url": "https://..."
        },
        "status": "PENDING",
        "message": null,
        "created_at": "2026-01-04T12:00:00Z",
        "responded_at": null
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 2,
      "total_pages": 1
    }
  }
}
```

---

### 7. 친구 요청 응답 (수락/거절)

받은 친구 요청에 대해 수락 또는 거절합니다.

#### Request

```
PUT /api/v1/friend-requests/:request_id/respond
```

**Headers**

```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Path Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `request_id` | uuid | Y | 요청 ID |

**Body**

```json
{
  "action": "accept"
}
```

| 필드     | 타입   | 필수 | 설명                    |
| -------- | ------ | ---- | ----------------------- |
| `action` | string | Y    | `"accept"` 또는 `"reject"` |

#### Response (수락 시)

```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "status": "ACCEPTED",
    "responded_at": "2026-01-04T12:30:00.000Z",
    "friendship": {
      "user_id_a": "uuid",
      "user_id_b": "uuid",
      "created_at": "2026-01-04T12:30:00.000Z"
    },
    "notification": {
      "notification_id": "uuid",
      "notification_type": "FRIEND_REQUEST_ACCEPTED",
      "title": "친구 요청 수락",
      "body": "박철수님의 친구 요청을 수락했습니다.",
      "payload": {
        "related_user_id": "uuid",
        "request_id": "uuid",
        "user_name": "박철수",
        "profile_image_url": "https://...",
        "request_status": "ACCEPTED",
        "responded_at": "2026-01-04T12:30:00.000Z"
      },
      "actions": [],
      "is_read": true,
      "read_at": "2026-01-04T12:30:00.000Z",
      "created_at": "2026-01-04T12:00:00.000Z"
    }
  },
  "message": "친구 요청을 수락했습니다."
}
```

#### Response (거절 시)

```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "status": "REJECTED",
    "responded_at": "2026-01-04T12:30:00.000Z",
    "notification": {
      "notification_id": "uuid",
      "notification_type": "FRIEND_REQUEST_REJECTED",
      "title": "친구 요청 거절",
      "body": "박철수님의 친구 요청을 거절했습니다.",
      "payload": {
        "related_user_id": "uuid",
        "request_id": "uuid",
        "user_name": "박철수",
        "profile_image_url": "https://...",
        "request_status": "REJECTED",
        "responded_at": "2026-01-04T12:30:00.000Z"
      },
      "actions": [],
      "is_read": true,
      "read_at": "2026-01-04T12:30:00.000Z",
      "created_at": "2026-01-04T12:00:00.000Z"
    }
  },
  "message": "친구 요청을 거절했습니다."
}
```

응답의 `data.notification`은 수신자 알림 목록에 있던 원본 `FRIEND_REQUEST` 알림을
갱신한 결과다. 프론트엔드는 이 객체로 기존 알림 카드를 즉시 교체할 수 있고,
알림 목록을 다시 조회해도 같은 처리 완료 상태가 반환되어야 한다.

#### Error Codes

| 코드                | 메시지                            | 설명                 |
| ------------------- | --------------------------------- | -------------------- |
| `REQUEST_NOT_FOUND` | 친구 요청을 찾을 수 없습니다.     | 존재하지 않는 요청   |
| `NOT_ADDRESSEE`     | 이 요청에 응답할 권한이 없습니다. | 요청 수신자가 아님   |
| `NOT_PENDING`       | 이미 처리된 요청입니다.           | PENDING 상태가 아님  |
| `INVALID_ACTION`    | 올바른 응답을 선택해주세요.       | accept/reject가 아님 |

#### 구현 참고

```typescript
// 비즈니스 로직 순서
1. request_id로 요청 조회
2. 현재 사용자가 addressee_user_id인지 확인
3. 상태가 PENDING인지 확인
4. 상태 업데이트 (DB 트리거가 friendships, friend_level_settings 자동 생성)
```

---

### 8. 친구 요청 취소

내가 보낸 친구 요청을 취소합니다.

#### Request

```
PUT /api/v1/friend-requests/:request_id/cancel
```

**Headers**

```
Authorization: Bearer {access_token}
```

**Path Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `request_id` | uuid | Y | 요청 ID |

#### Response

```json
{
  "success": true,
  "data": {
    "request_id": "uuid",
    "status": "CANCELED",
    "responded_at": "2026-01-04T12:30:00Z"
  },
  "message": "친구 요청을 취소했습니다."
}
```

#### Error Codes

| 코드                | 메시지                            | 설명                |
| ------------------- | --------------------------------- | ------------------- |
| `REQUEST_NOT_FOUND` | 친구 요청을 찾을 수 없습니다.     | 존재하지 않는 요청  |
| `NOT_REQUESTER`     | 이 요청을 취소할 권한이 없습니다. | 요청 발신자가 아님  |
| `NOT_PENDING`       | 이미 처리된 요청입니다.           | PENDING 상태가 아님 |

---

### 9. 친구 레벨 설정 변경

특정 친구의 레벨 설정을 변경합니다.

#### Request

```
PUT /api/v1/friends/:friend_user_id/settings
```

**Headers**

```
Authorization: Bearer {access_token}
Content-Type: application/json
```

**Path Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `friend_user_id` | uuid | Y | 친구 사용자 ID |

**Body**

```json
{
  "friend_level": 3, // 선택: 0~5
  "can_view": true // 선택: 내 캘린더 공유 여부
}
```

#### Response

```json
{
  "success": true,
  "data": {
    "owner_user_id": "uuid",
    "friend_user_id": "uuid",
    "friend_level": 3,
    "can_view": true,
    "updated_at": "2026-01-04T12:30:00Z"
  },
  "message": "친구 설정을 변경했습니다."
}
```

#### Error Codes

| 코드            | 메시지                           | 설명           |
| --------------- | -------------------------------- | -------------- |
| `NOT_FRIENDS`   | 친구 관계가 아닙니다.            | 친구 관계 없음 |
| `INVALID_LEVEL` | 친구 레벨은 0~5 사이여야 합니다. | 레벨 범위 초과 |

---

### 10. 친구 삭제

친구 관계를 삭제합니다.

#### Request

```
DELETE /api/v1/friends/:friend_user_id
```

**Headers**

```
Authorization: Bearer {access_token}
```

**Path Parameters**
| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `friend_user_id` | uuid | Y | 친구 사용자 ID |

#### Response

```json
{
  "success": true,
  "data": null,
  "message": "친구를 삭제했습니다."
}
```

#### Error Codes

| 코드          | 메시지                | 설명           |
| ------------- | --------------------- | -------------- |
| `NOT_FRIENDS` | 친구 관계가 아닙니다. | 친구 관계 없음 |

#### 구현 참고

```sql
-- 친구 삭제 순서 (트랜잭션 필요)
BEGIN;

-- 1. friend_level_settings 삭제 (양방향)
DELETE FROM friend_level_settings
WHERE (owner_user_id = :my_user_id AND friend_user_id = :friend_user_id)
   OR (owner_user_id = :friend_user_id AND friend_user_id = :my_user_id);

-- 2. friendships 삭제
DELETE FROM friendships
WHERE (user_id_a = LEAST(:my_user_id, :friend_user_id)
   AND user_id_b = GREATEST(:my_user_id, :friend_user_id));

COMMIT;
```

---

## 라우터 설정

```typescript
// routes/friendRoutes.ts
import { Router } from "express";
import { authMiddleware } from "../middlewares/auth";
import * as friendController from "../controllers/friendController";

const router = Router();

// 모든 라우트에 인증 필요
router.use(authMiddleware);

// 친구 목록
router.get("/friends", friendController.getFriends);

// 친구 캘린더 조회
router.get(
  "/friends/:friend_user_id/calendar/range",
  friendController.getFriendCalendarRange
);

// 친구 설정 변경
router.put(
  "/friends/:friend_user_id/settings",
  friendController.updateFriendSettings
);

// 친구 삭제
router.delete("/friends/:friend_user_id", friendController.deleteFriend);

// 사용자 검색 (친구 추가용)
router.get("/users/search", friendController.searchUser);

// 친구 요청
router.post("/friend-requests", friendController.sendFriendRequest);
router.get("/friend-requests/received", friendController.getReceivedRequests);
router.get("/friend-requests/sent", friendController.getSentRequests);
router.put(
  "/friend-requests/:request_id/respond",
  friendController.respondToRequest
);
router.put(
  "/friend-requests/:request_id/cancel",
  friendController.cancelRequest
);

export default router;
```

---

## 프론트엔드 서비스 연결

```dart
// FriendService
Future<CalendarRangeResponse> getFriendCalendarRange({
  required String friendUserId,
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final path = '${ApiConstants.friends}/$friendUserId/calendar/range';
  final response = await _dio.get(
    path,
    queryParameters: {
      'start_date': _formatDate(startDate),
      'end_date': _formatDate(endDate),
    },
  );
  return CalendarRangeResponse.fromJson(response.data);
}
```

---

## 테스트 케이스 체크리스트

### 친구 요청 보내기

- [ ] 정상 요청 (새로운 사용자에게 요청)
- [ ] 자기 자신에게 요청 → `SELF_REQUEST` 에러
- [ ] 이미 친구인 사용자에게 요청 → `ALREADY_FRIENDS` 에러
- [ ] 이미 PENDING 요청이 있는 경우 → `PENDING_REQUEST_EXISTS` 에러
- [ ] 존재하지 않는 사용자에게 요청 → `USER_NOT_FOUND` 에러

### 친구 요청 응답

- [ ] 정상 수락 → `ACCEPTED` + friendships/friend_level_settings 생성
- [ ] 정상 거절 → `REJECTED`
- [ ] 본인이 받은 요청이 아닌 경우 → `NOT_ADDRESSEE` 에러
- [ ] 이미 처리된 요청 → `NOT_PENDING` 에러

### 친구 요청 취소

- [ ] 정상 취소 → `CANCELED`
- [ ] 본인이 보낸 요청이 아닌 경우 → `NOT_REQUESTER` 에러
- [ ] 이미 처리된 요청 → `NOT_PENDING` 에러

### 친구 설정 변경

- [ ] 레벨만 변경 (0~5)
- [ ] can_view만 변경
- [ ] 둘 다 변경
- [ ] 범위 벗어난 레벨 → `INVALID_LEVEL` 에러

### 친구 캘린더 조회

- [ ] 친구가 현재 사용자에게 `can_view=true` 설정 → 근무표 조회 가능
- [ ] 친구가 현재 사용자에게 `can_view=false` 설정 → `CALENDAR_ACCESS_DENIED` 에러
- [ ] `friend_level >= visibility_level`인 개인 일정만 응답
- [ ] `work_shifts.visibility_level=0` 근무표는 `can_view=true`이면 응답
- [ ] 친구가 아닌 사용자 조회 → `FRIEND_NOT_FOUND` 에러

### 친구 삭제

- [ ] 정상 삭제 → friendships + friend_level_settings 모두 삭제
- [ ] 친구가 아닌 경우 → `NOT_FRIENDS` 에러

---

## 추가 고려사항

### 보안

- 모든 엔드포인트는 JWT 인증 필수
- 친구 설정/삭제는 본인의 친구에 대해서만 가능
- 요청 응답/취소는 해당 요청의 당사자만 가능
- 친구 캘린더 조회는 DB의 visible view 또는 동일 조건 쿼리로 서버에서 필터링하고, 프론트에 비공개 일정을 내려보내지 않음

### 성능

- 친구 목록 페이지네이션 적용
- 인덱스 활용 (idx_friendships_user_a, idx_friendships_user_b, idx_fls_owner)
- 친구 캘린더 조회는 월 이동 시 3개월 범위로 요청하므로 `owner_user_id + date/start_at` 인덱스를 사용

### 확장성

- 추후 푸시 알림 연동 시 친구 요청/수락 이벤트 발행 고려
- 전화번호 검색 시 E.164 형식으로 정규화 권장
