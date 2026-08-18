# 가입 프로필 완료 API·백엔드 구현 요구사항

작성일: 2026-08-17
대상: `shift_calendar_server` Express/Sequelize 서버
클라이언트 기준: `shift_calendar` Flutter 앱

## 1. 목적과 출시 전제

가입 프로필을 다음 두 그룹으로 저장한다.

- 기본 정보(필수): 이름, 휴대폰 번호, 타임존
- 근무 정보(선택): 직종, 소속 병원 및 부서

Flutter는 신규 `POST /api/v1/auth/profile/complete`를 호출하도록 구현되어 있다. 따라서 **서버와 DB를 먼저 배포하고 endpoint 동작을 Stage에서 확인한 뒤 Flutter를 배포**해야 한다. 서버 배포 전 Flutter 신규 버전을 배포하면 가입 완료가 404로 실패한다.

## 2. 현재 구현에서 확인한 사실

- `users.phone`은 nullable·unique이며 서버 `POST /api/v1/auth/profile`이 이미 입력을 받는다.
- 현재 서버는 숫자 10~11자리 휴대폰을 하이픈 형식으로 정규화하고 `INVALID_PHONE`, `PHONE_ALREADY_EXISTS`를 반환한다.
- `users`와 프로필 API에는 `job_type`, `workplace`, 영속적인 가입 완료 시각이 없다.
- OAuth 응답의 `is_new_user`는 해당 로그인에서 사용자를 새로 생성했는지만 나타낸다. 신규 사용자가 프로필을 완료하지 않고 앱을 종료한 뒤 재접속하면 가입 화면을 재개할 수 있는 영속 상태가 아니다.
- 기존 `POST /api/v1/auth/profile`은 일반 프로필 수정 계약이므로 유지한다.

## 3. DB 변경

`users`에 아래 컬럼을 추가하는 Sequelize migration을 작성한다.

```sql
ALTER TABLE users
  ADD COLUMN job_type varchar(20),
  ADD COLUMN workplace varchar(100),
  ADD COLUMN profile_completed_at timestamptz;

ALTER TABLE users
  ADD CONSTRAINT ck_users_job_type
    CHECK (job_type IS NULL OR job_type IN ('NURSE', 'DOCTOR', 'EMT', 'OTHER')),
  ADD CONSTRAINT ck_users_workplace
    CHECK (workplace IS NULL OR (char_length(btrim(workplace)) BETWEEN 1 AND 100));
```

- 기존 `phone` 컬럼과 unique 제약은 재사용한다.
- 기존 사용자 backfill은 `name`이 비어 있지 않고, 유효한 `timezone`과 `phone`이 모두 있는 사용자만 `profile_completed_at = COALESCE(created_at, now())`로 설정한다.
- 위 조건을 충족하지 않는 기존 사용자는 null로 유지해 다음 인증 시 가입 프로필 화면으로 보낸다.
- migration은 컬럼 추가 → 제약 추가 → 조건부 backfill 순서로 실행한다.
- 롤백은 세 신규 컬럼과 두 check 제약만 제거한다. 기존 `phone` 데이터와 제약은 변경하지 않는다.

## 4. 가입 완료 API

### 요청

```http
POST /api/v1/auth/profile/complete
Authorization: Bearer <access_token>
Content-Type: application/json
```

```json
{
  "name": "김간호",
  "timezone": "Asia/Seoul",
  "phone": "01012345678",
  "job_type": "NURSE",
  "workplace": "제일병원 중환자실"
}
```

필드 계약:

| 필드 | 필수 | 검증·저장 |
|---|---:|---|
| `name` | 예 | 앞뒤 공백 제거 후 1~50자 |
| `timezone` | 예 | 서버가 지원하는 IANA timezone allowlist 값 |
| `phone` | 예 | 기존 규칙과 동일하게 숫자 10~11자리 검증 후 정규화 |
| `job_type` | 아니요 | `NURSE`, `DOCTOR`, `EMT`, `OTHER` 중 하나 |
| `workplace` | 아니요 | 앞뒤 공백 제거 후 1~100자 |

- 선택 필드는 요청에서 생략할 수 있고 생략 시 null로 저장한다.
- 빈 문자열은 선택값 생략과 동일하게 null로 정규화한다.
- 필수 필드가 없거나 공백뿐이면 저장하지 않고 400을 반환한다.
- endpoint는 인증 사용자의 같은 값 재전송에 성공하는 idempotent 동작이어야 한다.
- 필수값 저장과 `profile_completed_at` 기록은 하나의 DB transaction에서 수행한다.

### 성공 응답

기존 인증 응답 wrapper를 유지하고 최신 사용자와 완료 상태를 반환한다.

```json
{
  "success": true,
  "data": {
    "user_id": "uuid",
    "email": "user@example.com",
    "name": "김간호",
    "timezone": "Asia/Seoul",
    "phone": "010-1234-5678",
    "job_type": "NURSE",
    "workplace": "제일병원 중환자실",
    "requires_profile_setup": false
  }
}
```

HTTP 200을 사용한다. `profile_completed_at` 원문은 클라이언트에 꼭 노출할 필요가 없으며 서버가 계산한 boolean `requires_profile_setup`을 정본으로 제공한다.

## 5. 기존 인증·프로필 응답 변경

- `GET /api/v1/auth/profile`의 사용자 객체에 `phone`, `job_type`, `workplace`, `requires_profile_setup`을 포함한다.
- 카카오·네이버·Google·Apple 로그인 성공 응답에도 `data.requires_profile_setup`을 포함한다.
- 계산 규칙은 `profile_completed_at IS NULL`이면 true, 아니면 false다.
- 신규 OAuth 사용자는 `profile_completed_at = null`로 생성한다.
- 기존 `is_new_user`는 계정 생성 여부의 호환 필드로 유지하되 화면 분기 정본으로 사용하지 않는다.
- 기존 `POST /api/v1/auth/profile`은 일반 편집 endpoint로 유지하고 `job_type`, `workplace` 수정을 지원한다. 요청에서 생략한 필드는 기존 값을 유지한다. 선택값을 지우는 명시적 `null`은 허용한다.
- 일반 편집 endpoint는 필수 프로필이 모두 유효하다는 이유만으로 완료 시각을 임의 생성하지 않는다. 최초 완료는 `/profile/complete`만 담당한다.

## 6. 오류 계약

기존 공통 오류 wrapper와 `request_id`를 유지한다.

| HTTP | code | 조건 |
|---:|---|---|
| 400 | `VALIDATION_ERROR` | 필수값 누락, 길이 위반 |
| 400 | `INVALID_PHONE` | 휴대폰 형식 오류 |
| 400 | `INVALID_TIMEZONE` | 지원하지 않는 timezone |
| 400 | `INVALID_JOB_TYPE` | enum 외 직종 |
| 401 | `UNAUTHORIZED` | 유효한 앱 access token 없음 |
| 409 | `PHONE_ALREADY_EXISTS` | 다른 사용자가 정규화된 번호를 사용 중 |

현재 서버의 `PHONE_ALREADY_EXISTS`가 400이면 신규 계약에서는 409로 변경하고 OpenAPI·테스트도 함께 갱신한다. unique constraint 경쟁 조건도 Sequelize unique 오류를 409로 매핑해야 한다.

## 7. Express 구현 구조

프로젝트 규칙에 따라 다음 흐름을 지킨다.

```text
authRoutes
  → authenticate middleware
  → request validation middleware
  → AuthController.completeProfile
  → AuthService.completeProfile(transaction)
  → User model / PostgreSQL
```

- controller에서 직접 모델을 수정하지 않고 validation과 transaction 로직을 service로 이동한다.
- 사용자 조회 시 soft-delete/계정 상태 정책을 기존 인증 흐름과 동일하게 적용한다.
- 이름·전화번호·소속을 request/SQL/application log에 남기지 않는다.
- `workplace`와 `phone`은 친구 목록, 사용자 검색, 그룹 구성원 응답에 추가하지 않는다. 본인 프로필과 인증 응답에서만 반환한다.
- endpoint에 기존 인증 route와 같은 rate limit 정책을 적용한다.

## 8. OpenAPI와 테스트

OpenAPI에 request schema, enum, optional/null 규칙, 성공 사용자 schema와 모든 오류 예시를 추가한다.

필수 자동 테스트:

- 필수 세 필드만 전송해 200 및 `requires_profile_setup=false`
- 근무 정보까지 전송해 trim·저장·응답 확인
- 선택 필드 생략/빈 문자열이 null로 저장됨
- 필수 누락, 잘못된 전화번호/timezone/job type, 길이 초과가 각각 구조화 오류 반환
- 정규화 후 중복 전화번호가 409 반환
- 같은 요청 재전송이 성공하고 완료 시각이 불필요하게 변경되지 않음
- transaction 실패 시 사용자 필드와 완료 시각이 함께 rollback
- 신규 OAuth 로그인은 true, 완료 후 모든 OAuth 및 GET profile 응답은 false
- 미완료 기존 사용자는 재로그인해도 true
- 친구 검색·그룹 응답에서 phone/workplace가 노출되지 않음
- migration up/down 및 backfill 대상/비대상 검증

## 9. 배포·검증·롤백

1. Stage DB backup 및 중복·비정상 phone/timezone 사전 조회
2. Stage migration 적용 및 backfill 건수 기록
3. 서버 endpoint·OpenAPI 배포
4. 서버 단위/통합 테스트와 네 OAuth 신규·기존 사용자 E2E
5. Flutter Stage 빌드에서 필수값 검증, 선택값 생략, 앱 종료 후 재개 확인
6. Center DB backup → migration → 서버 배포 → smoke test
7. 마지막으로 Flutter Production 배포

롤백 시 Flutter 배포 전이면 서버 route는 호환 목적으로 유지한 채 서버 코드를 이전 버전으로 되돌리지 않는다. 이미 Flutter가 배포된 뒤 endpoint를 제거하면 가입이 차단되므로, 긴급 시 서버는 완료 endpoint를 유지하고 신규 선택 컬럼만 사용하지 않는 호환 구현을 제공한다.

## 10. 완료 조건

- [ ] Sequelize model/migration과 DB 제약 적용
- [ ] `/auth/profile/complete` 인증·validation·service·transaction 구현
- [ ] 기존 profile 및 모든 OAuth 응답에 `requires_profile_setup` 반영
- [ ] 일반 프로필 수정의 생략/명시적 null 규칙 구현
- [ ] 오류 status/code와 unique 경쟁 조건 매핑
- [ ] 개인정보 로그·친구/그룹 응답 비노출 확인
- [ ] OpenAPI 및 자동 테스트 통과
- [ ] Stage 앱 종료 후 미완료 가입 재개 E2E 통과
- [ ] 서버 선배포 후 Flutter 배포 순서 준수
