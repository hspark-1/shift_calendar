# 친구 관리 기능 설계 문서

## 1. 기능 개요

### 1.1 요구사항 요약

1. **친구 추가**: 이메일 또는 전화번호로 친구 추가
2. **친구 신청 알림**:
   - 보낸 사람: 보낸 요청 확인, 취소 가능
   - 받은 사람: 받은 요청 확인, 수락/거절 가능
3. **친구 목록**: 좌측 하단 버튼(현재 "메모")을 통해 친구 리스트 확인
   - 프로필 사진
   - 이름
   - 내가 설정한 친구 레벨

### 1.2 관련 DB 테이블

| 테이블                  | 용도                                                          |
| ----------------------- | ------------------------------------------------------------- |
| `users`                 | 사용자 정보 (email, name, profile_image_url, phone 추가 필요) |
| `friend_requests`       | 친구 요청 관리 (PENDING, ACCEPTED, REJECTED, CANCELED)        |
| `friendships`           | 수락된 친구 관계 (대칭 1건)                                   |
| `friend_level_settings` | 친구별 레벨/열람 설정                                         |

---

## 2. 시스템 아키텍처

### 2.1 전체 흐름

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           프론트엔드 (Flutter)                            │
├─────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐   ┌─────────────┐   ┌─────────────┐   ┌─────────────┐ │
│  │ 친구 목록   │   │ 친구 추가   │   │ 알림 (보낸) │   │ 알림 (받은) │ │
│  │    Page     │   │   Modal     │   │    Tab      │   │    Tab      │ │
│  └─────────────┘   └─────────────┘   └─────────────┘   └─────────────┘ │
│         │                │                 │                 │         │
│         └────────────────┴─────────────────┴─────────────────┘         │
│                                   │                                     │
│                          FriendProvider                                 │
│                                   │                                     │
│                          FriendService                                  │
└───────────────────────────────────┬─────────────────────────────────────┘
                                    │
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                           백엔드 (Express)                              │
├─────────────────────────────────────────────────────────────────────────┤
│  FriendRouter → FriendController → FriendService → FriendRepository     │
│                                                            │            │
│                                                    PostgreSQL DB        │
└─────────────────────────────────────────────────────────────────────────┘
```

### 2.2 친구 요청 상태 흐름

```
                    ┌──────────┐
         요청 생성   │ PENDING  │
             ───────▶│  (대기)  │
                    └────┬─────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
          ▼              ▼              ▼
    ┌──────────┐  ┌──────────┐  ┌──────────┐
    │ CANCELED │  │ ACCEPTED │  │ REJECTED │
    │  (취소)   │  │  (수락)   │  │  (거절)   │
    └──────────┘  └────┬─────┘  └──────────┘
                       │
                       ▼
              ┌───────────────────┐
              │   friendships     │
              │ (친구 관계 생성)   │
              └────────┬──────────┘
                       │
                       ▼
              ┌───────────────────┐
              │ friend_level_     │
              │ settings (양방향)  │
              └───────────────────┘
```

---

## 3. UI/UX 설계

### 3.1 UI 변경 사항

#### BottomActionBar 변경

- **현재**: 메모 버튼 (doc_text 아이콘)
- **변경**: 친구 버튼 (person_2 아이콘)

```dart
// AS-IS
_buildActionButton(
  icon: CupertinoIcons.doc_text,
  label: '메모',
  onTap: onMemoTap,
)

// TO-BE
_buildActionButton(
  icon: CupertinoIcons.person_2,
  label: '친구',
  onTap: onFriendTap,
)
```

### 3.2 화면 구성

#### 3.2.1 친구 목록 페이지 (`FriendListPage`)

```
┌──────────────────────────────────────────┐
│  ← 친구                          [+] 추가 │  ← NavigationBar
├──────────────────────────────────────────┤
│  ┌────────────────────────────────────┐  │
│  │ 🔍 친구 검색                        │  │  ← 검색바 (선택)
│  └────────────────────────────────────┘  │
│                                          │
│  ┌──────┐                                │
│  │ 프로필│  홍길동           레벨 ★★★   │  ← 친구 Row
│  │ 이미지│  hong@email.com               │
│  └──────┘                          [>]   │
│  ──────────────────────────────────────  │
│  ┌──────┐                                │
│  │ 프로필│  김영희           레벨 ★★    │
│  │ 이미지│  kim@email.com                │
│  └──────┘                          [>]   │
│  ──────────────────────────────────────  │
│                                          │
└──────────────────────────────────────────┘
```

#### 3.2.2 친구 추가 모달 (`AddFriendModal`)

```
┌──────────────────────────────────────────┐
│              친구 추가                    │
├──────────────────────────────────────────┤
│                                          │
│  이메일 또는 전화번호로 친구를 찾아보세요   │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 이메일 또는 전화번호 입력        [🔍] │  │
│  └────────────────────────────────────┘  │
│       ▲ 올바른 형식 안내 말풍선            │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │  프로필   이름                       │  │  ← 검색 성공 시 단일 결과 카드
│  │          email@example.com           │  │
│  │                                    │  │
│  │  [        친구 요청 보내기        ]  │  │
│  └────────────────────────────────────┘  │
│                                          │
└──────────────────────────────────────────┘
```

- 이메일/전화번호는 유니크 값이므로 검색 성공 결과는 최대 1명이다.
- UI는 리스트가 아니라 단일 사용자 카드 1개만 표시한다.
- 결과가 없으면 사용자 카드 대신 `USER_NOT_FOUND` 메시지를 표시한다.
- 검색은 키보드 엔터와 검색 아이콘 버튼으로 실행한다.
- 이메일/전화번호 형식이 아니면 API 호출 전에 검색창 아래 말풍선으로 안내한다.
- 전화번호는 검색 실행 시 `000-0000-0000` 또는 `000-000-0000` 형식으로 정규화한 뒤 API 요청에 사용한다.
- 상단 핸들을 위로 끌면 iOS sheet 최대 높이까지 확장하고, 아래로 빠르게 끌거나 최소 높이 이하로 끌면 모달을 닫는다.
- 키보드가 올라오면 `MediaQuery.viewInsets.bottom`을 모달 하단 패딩과 높이에 반영해 모달이 키보드 위 전체 가용 영역으로 이동한다.
- 모달 최대 확장 높이는 Flutter `CupertinoSheetRoute`의 기본 `topGap`과 같은 화면 높이의 8% 상단 여백을 남긴다.

#### 3.2.3 알림 페이지 (`NotificationPage`)

```
┌──────────────────────────────────────────┐
│  ← 알림                                  │
├──────────────────────────────────────────┤
│  ┌─────────────┬─────────────┐           │
│  │   받은 요청  │   보낸 요청  │           │  ← SegmentedControl
│  └─────────────┴─────────────┘           │
│                                          │
│  [받은 요청 탭]                           │
│  ┌──────┐                                │
│  │ 프로필│  박철수님이 친구 요청을 보냈습니다│
│  │ 이미지│  2분 전                        │
│  └──────┘  [수락]  [거절]                 │
│  ──────────────────────────────────────  │
│                                          │
│  [보낸 요청 탭]                           │
│  ┌──────┐                                │
│  │ 프로필│  이영수님에게 친구 요청 보냄    │
│  │ 이미지│  5분 전                        │
│  └──────┘  [요청 취소]                    │
│  ──────────────────────────────────────  │
│                                          │
└──────────────────────────────────────────┘
```

#### 3.2.4 친구 상세/설정 페이지 (`FriendDetailPage`)

```
┌──────────────────────────────────────────┐
│  ←              친구 정보          Save  │
├──────────────────────────────────────────┤
│              ┌────────┐                  │
│              │ 프로필  │                  │
│              └────────┘                  │
│              홍길동                       │
│           hong@email.com                 │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 친구 레벨 설정                      │  │
│  │ 0  1  2  3  4  5  ← 탭/드래그 트랙 │  │
│  │ i 레벨이 높을수록 더 많은 일정 공유 │  │
│  │   레벨 0: 근무표만 공유             │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 내 캘린더 공유             [toggle] │  │
│  │ 비활성화하면 이 친구가 내 캘린더를  │  │
│  │ 볼 수 없습니다.                    │  │
│  └────────────────────────────────────┘  │
│                                          │
│  [사람- 아이콘  친구 삭제]                │  ← Destructive Button
│                                          │
└──────────────────────────────────────────┘
```

- 화면 요소는 최초 디자인 시안 대비 약 75% 크기의 컴팩트 밀도를 기본으로 한다.
- 프로필 사진 옆 편집 아이콘은 표시하지 않는다.
- 레벨 세그먼트와 캘린더 공유 토글은 로컬 UI 상태만 먼저 변경한다.
- 레벨 세그먼트는 개인 일정 추가 모달의 공개 레벨 선택과 같은 탭/드래그 트랙 패턴을 사용한다.
- 상단 `Save`를 누르면 `PUT /api/v1/friends/:friend_user_id/settings`에
  `friend_level`, `can_view`를 함께 보내고, 성공 시 현재 선택값을 저장된 값으로 확정한다.
- 친구 삭제 성공 시에는 `Navigator.pop(true)`로 삭제 결과를 반환해 친구 캘린더 화면까지 닫는다.

#### 3.2.5 친구 캘린더 조회 페이지 (`FriendCalendarPage`)

```
┌──────────────────────────────────────────┐
│  ← 박현서                         [설정] │
├──────────────────────────────────────────┤
│  프로필  박현서                           │
│        ssp8585@naver.com                 │
│                                          │
│          2026.07                         │
│       <              >                   │
│  일 월 화 수 목 금 토                     │
│   1  2  3  4  5  6  7                    │
│      D     N     OFF                     │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ 2026.07.05                 2개의 일정 │
│  ├────────────────────────────────────┤  │
│  │ 데이       07:00 - 15:00             │
│  │ 약속       10:00 - 11:00 서울         │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
```

- 친구 목록 Row를 누르면 이 페이지로 이동한다.
- 오른쪽 설정 버튼은 기존 `FriendDetailPage`로 이동한다.
- 달력에는 친구의 `work_shifts`를 날짜별 근무 코드/색상으로 표시한다.
- 날짜를 선택하면 하단에 해당 날짜의 근무표와 친구가 공개한 개인 일정을 표시한다.
- 공개 판단은 서버가 `friend_level_settings.owner_user_id = 친구`,
  `friend_level_settings.friend_user_id = 현재 사용자` 기준으로 수행한다.
- 근무표는 `work_shifts.visibility_level=0`이므로 친구가 현재 사용자에게
  `can_view=true`로 열람을 허용한 경우 표시한다.
- 개인 일정은 `friend_level >= events.visibility_level` 조건을 통과한 결과만 표시한다.

---

## 4. 프론트엔드 구현 계획

### 4.1 폴더 구조

```
lib/features/friend/
├── data/
│   ├── models/
│   │   ├── friend_model.dart              # 친구 정보 모델
│   │   ├── friend_request_model.dart      # 친구 요청 모델
│   │   └── friend_level_setting_model.dart # 친구 레벨 설정 모델
│   └── services/
│       └── friend_service.dart            # API 통신 서비스
├── presentation/
│   ├── pages/
│   │   ├── friend_list_page.dart          # 친구 목록 페이지
│   │   ├── friend_calendar_page.dart      # 친구 캘린더 조회 페이지
│   │   ├── friend_detail_page.dart        # 친구 상세 페이지
│   │   └── notification_page.dart         # 알림 페이지
│   ├── widgets/
│   │   ├── friend_list_item.dart          # 친구 리스트 아이템
│   │   ├── friend_request_item.dart       # 친구 요청 아이템
│   │   ├── add_friend_modal.dart          # 친구 추가 모달
│   │   └── friend_level_selector.dart     # 친구 레벨 선택기
│   └── providers/
│       └── friend_provider.dart           # 상태 관리
```

### 4.2 데이터 모델

```dart
// friend_model.dart
class FriendModel {
  final String userId;
  final String name;
  final String email;
  final String? phone;
  final String? profileImageUrl;
  final int friendLevel;        // 내가 설정한 친구 레벨
  final bool canView;           // 내 캘린더 공유 여부
  final DateTime createdAt;     // 친구 관계 생성일
}

// friend_request_model.dart
class FriendRequestModel {
  final String requestId;
  final String requesterUserId;
  final String addresseeUserId;
  final String requesterName;
  final String addresseeName;
  final String? requesterProfileImageUrl;
  final String? addresseeProfileImageUrl;
  final String status;           // PENDING, ACCEPTED, REJECTED, CANCELED
  final String? message;
  final DateTime createdAt;
  final DateTime? respondedAt;
}
```

---

## 5. 백엔드 구현 계획

### 5.1 폴더 구조

```
src/
├── routes/
│   └── friendRoutes.ts           # 친구 관련 라우트
├── controllers/
│   └── friendController.ts       # 친구 관련 컨트롤러
├── services/
│   └── friendService.ts          # 친구 관련 비즈니스 로직
├── repositories/
│   └── friendRepository.ts       # 친구 관련 DB 접근
├── models/
│   └── friend.ts                 # 친구 관련 타입 정의
└── validators/
    └── friendValidator.ts        # 친구 관련 입력 검증
```

### 5.2 DB 스키마 변경 (선택)

```sql
-- users 테이블에 phone 컬럼 추가 (전화번호 검색용)
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone text;
CREATE UNIQUE INDEX IF NOT EXISTS idx_users_phone
ON users(phone) WHERE phone IS NOT NULL;

COMMENT ON COLUMN users.phone IS '전화번호 (친구 검색용, E.164 형식 권장)';
```

---

## 6. 구현 우선순위

### Phase 1: 기본 친구 기능 (MVP)

1. [BE] 친구 목록 조회 API
2. [BE] 친구 요청 보내기 API
3. [BE] 받은 요청 목록 조회 API
4. [BE] 보낸 요청 목록 조회 API
5. [BE] 친구 요청 수락/거절 API
6. [BE] 친구 요청 취소 API
7. [FE] 친구 목록 페이지
8. [FE] 친구 추가 모달
9. [FE] 알림 페이지 (받은/보낸 요청)

### Phase 2: 친구 설정 기능

1. [BE] 친구 레벨 설정 API
2. [BE] 친구 열람 설정 API
3. [BE] 친구 삭제 API
4. [FE] 친구 상세 페이지
5. [FE] 친구 레벨 설정 UI

### Phase 3: 고급 기능 (선택)

1. 친구 검색 기능
2. [FE] 친구 캘린더 열람 페이지
3. [BE] 친구 캘린더 기간 조회 API
4. 전화번호 검색 기능 (DB 스키마 변경 필요)
5. 푸시 알림 연동

---

## 7. 참고 사항

### 7.1 친구 요청 비즈니스 규칙

1. 자기 자신에게 친구 요청 불가 (`requester_user_id <> addressee_user_id`)
2. 이미 친구인 사용자에게 요청 불가
3. 이미 PENDING 상태의 요청이 있으면 중복 요청 불가
4. 수락 시 `friendships` + `friend_level_settings` 자동 생성 (DB 트리거)

### 7.2 친구 레벨 설명

- 레벨 0: 기본 (근무표만 공유)
- 레벨 1~5: 일정 공유 레벨 (event의 visibility_level과 비교)

### 7.3 열람 설정 (`can_view`)

- `true`: 해당 친구가 내 캘린더를 볼 수 있음
- `false`: 해당 친구가 내 캘린더를 볼 수 없음 (친구 관계는 유지)

### 7.4 친구 캘린더 조회 규칙

- 조회 대상 친구가 현재 사용자에게 설정한 `can_view`와 `friend_level`을 사용한다.
- API는 `GET /api/v1/friends/:friend_user_id/calendar/range`를 사용한다.
- 응답 형식은 기존 `CalendarRangeResponse`와 동일하게 `work_shifts`, `events`를 반환한다.
- 프론트는 친구 근무 타입 목록을 별도 조회하지 않고 `work_shifts` 응답의
  `shift_type_code`, `shift_type_name`, `shift_type_color`, `start_time`, `end_time`을 사용한다.
