# Google 소셜 로그인 서버 구현 요구문서

## 1. 문서 상태와 범위

- 상태: **결정 완료 / Express 후속 구현 대기**
- Flutter 계약 기준일: 2026-08-11
- 서버 대상: `../shift_calendar_server`의 Express 4 + TypeScript + Sequelize 6 + PostgreSQL 16
- 이 문서는 Google ID Token을 검증해 ShiftMate JWT를 발급하는 서버 구현 계약이다.
- 이번 Flutter 작업에서는 Express 코드와 운영 DB를 변경하지 않는다.
- Google Drive 등 추가 API scope, Google access token, authorization code, 계정 연결 UI/API는 범위 밖이다.

## 2. 전체 인증 흐름

```text
LoginPage 사용자 탭
  → google_sign_in authenticate()
  → Google ID Token
  → POST /api/v1/auth/google/token
  → authRateLimitMiddleware
  → express-validator + validateRequestMiddleware
  → authController.googleLoginWithToken()
  → googleService.completeLogin()
     → google-auth-library verifyIdToken()
     → google_id 또는 검증 이메일 정책 적용
     → 신규 사용자 + 기본 근무 템플릿 + refresh token transaction
  → ShiftMate access_token / refresh_token
  → 기존 ProfileSetupPage 또는 CalendarPage
```

Flutter는 Google ID Token 외의 사용자 ID·이메일·이름·사진을 서버에 보내지 않는다. 서버는
Google이 서명한 ID Token claim만 신원 판단의 근거로 사용한다.

## 3. 확정 API 계약

### 3.1 요청

- Method: `POST`
- Path: `/api/v1/auth/google/token`
- 인증: ShiftMate JWT 불필요
- Rate limit: 기존 `authRateLimitMiddleware` 적용
- Content-Type: `application/json`

```json
{
  "id_token": "google-issued-id-token"
}
```

검증 규칙:

- `id_token`: 필수 string, trim 후 1~16384자
- 알 수 없는 필드는 신원 정보로 사용하지 않는다.
- 유효성 실패는 HTTP 400과 공통 오류 형식으로 반환한다.

### 3.2 성공 응답

- 기존 사용자: HTTP 200
- 신규 사용자: HTTP 201
- `expires_at`: Unix epoch **milliseconds** 정수
- `is_new_user`: 메시지 추론이 아닌 명시적 boolean이며 `data` 안에 둔다.

```json
{
  "success": true,
  "message": "Google 로그인 성공",
  "data": {
    "user": {
      "user_id": "7d8e4fd8-4c63-4f3d-80f8-5c2bba18e5de",
      "email": "user@example.com",
      "name": "Google 사용자",
      "profile_image_url": "https://lh3.googleusercontent.com/...",
      "timezone": "Asia/Seoul",
      "google_id": "google-subject"
    },
    "access_token": "shiftmate-access-token",
    "refresh_token": "shiftmate-refresh-token",
    "expires_at": 1786460400000,
    "is_new_user": false
  }
}
```

신규 사용자 메시지는 `회원가입이 완료되었습니다.`, 기존 사용자는 `Google 로그인 성공`을 사용한다.
클라이언트 분기는 반드시 `data.is_new_user`를 기준으로 한다.

### 3.3 실패 응답

모든 실패는 아래 공통 형식을 사용하고 `request_id`를 빠뜨리지 않는다.

```json
{
  "success": false,
  "error": {
    "code": "GOOGLE_INVALID_TOKEN",
    "message": "Google 인증 정보를 확인할 수 없습니다."
  },
  "request_id": "request-id"
}
```

| HTTP | code | 고정 의미 |
|---|---|---|
| 400 | `VALIDATION_ERROR` | `id_token` 형식이 요청 계약과 다름 |
| 401 | `GOOGLE_INVALID_TOKEN` | 서명, audience, issuer, 만료 또는 필수 claim 검증 실패 |
| 400 | `GOOGLE_EMAIL_UNAVAILABLE` | 확인된 유효 이메일을 얻을 수 없음 |
| 409 | `ACCOUNT_LINK_REQUIRED` | 신규 `sub`의 이메일이 기존 ShiftMate 계정과 충돌 |
| 429 | `AUTH_RATE_LIMIT_EXCEEDED` | 인증 rate limit 초과 |
| 503 | `GOOGLE_UPSTREAM_UNAVAILABLE` | Google 키/검증 upstream의 일시 장애 |
| 503 | `GOOGLE_AUTH_DISABLED` | 서버 기능 플래그 비활성 |
| 500 | `INTERNAL_SERVER_ERROR` | 분류되지 않은 서버 오류 |

`ACCOUNT_LINK_REQUIRED`의 사용자 메시지는 아래 문장으로 고정한다.

> 이미 다른 로그인 방식으로 가입된 이메일입니다. 기존 로그인 방식으로 로그인해주세요.

토큰 자체가 잘못된 경우와 Google upstream 장애를 구분한다. 네트워크·Google 공개키 조회 장애는
`GOOGLE_UPSTREAM_UNAVAILABLE`, 검증 결과가 거부된 경우는 `GOOGLE_INVALID_TOKEN`이다.

## 4. Google ID Token 검증 규칙

서버 의존성에 `google-auth-library`를 추가하고, 전용 `OAuth2Client`를 프로세스에서 재사용한다.

```ts
const ticket = await oauth_client.verifyIdToken({
  idToken: id_token,
  audience: getRequiredEnvironmentVariable("GOOGLE_SERVER_CLIENT_ID"),
});
const payload = ticket.getPayload();
```

구현은 다음을 모두 만족해야 한다.

1. `verifyIdToken()`이 Google 서명, `aud`, `iss`, `exp`를 검증하도록 한다.
2. audience는 Web application OAuth client인 `GOOGLE_SERVER_CLIENT_ID` 하나로 고정한다.
3. 검증된 `sub`를 `users.google_id`로 사용한다. 요청 본문의 사용자 ID는 받거나 신뢰하지 않는다.
4. `email_verified === true`이고 trim/lowercase 후 유효한 이메일만 허용한다.
5. `sub`, 이메일, 이름, 사진 claim을 ID Token 검증 전에 읽어 계정 조회·생성에 사용하지 않는다.
6. access token이나 authorization code를 대체 입력으로 허용하지 않는다.
7. 오류 객체나 로그에 ID Token 원문 및 decoded payload 전체를 남기지 않는다.

검증된 `name`은 trim 후 1~100자인 경우만 초기 이름으로 사용한다. 없으면 검증 이메일의 local-part를
100자 이내로 사용한다. `picture`는 유효한 HTTPS URL이고 2048자 이하일 때만 초기
`profile_image_url`로 저장한다. 이 값들은 신규 사용자의 초기값일 뿐 신원 키가 아니다.

## 5. 사용자 조회·생성 정책

### 5.1 기존 Google 사용자

- 검증된 `sub`와 같은 `users.google_id`가 있으면 그 사용자로 로그인한다.
- Google claim이 달라져도 저장된 `email`, `name`, `profile_image_url`, `timezone`을 자동 갱신하지 않는다.
- ShiftMate refresh token만 새로 발급한다.

### 5.2 신규 Google subject

한 DB transaction에서 다음 순서를 수행한다.

1. provider와 `sub`를 기준으로 동시 로그인 경쟁을 직렬화한다.
2. `google_id`를 다시 조회한다.
3. `lower(email)` 기준으로 기존 사용자를 조회한다.
4. 이메일 충돌이면 어떤 provider ID도 수정하지 않고 transaction을 종료한 뒤
   HTTP 409 `ACCOUNT_LINK_REQUIRED`를 반환한다.
5. 충돌이 없으면 검증 claim으로 `User`를 생성한다.
6. `ensureDefaultTemplate(user.user_id, transaction)`으로 기본 근무 템플릿을 생성한다.
7. `generateTokens(user, { device_info, transaction })`으로 refresh token row까지 생성한다.
8. commit된 뒤에만 성공 응답을 반환한다.

`google_id` unique 경쟁은 Sequelize `UniqueConstraintError`를 처리해 재조회한다. 이메일 충돌로 판정된
경우 절대로 기존 `kakao_id`, `naver_id`, `apple_id`, `google_id`를 자동 연결하지 않는다.

신규 사용자 기본값:

- `email`: 검증 이메일을 trim/lowercase한 값
- `name`: 위의 검증된 이름 규칙
- `profile_image_url`: 유효한 검증 `picture` 또는 null
- `timezone`: 현재 신규 소셜 사용자 정책과 같은 `Asia/Seoul`
- `google_id`: 검증된 `sub`
- `password`: null

## 6. DB 변경 요구

정본 DDL은 아래와 같다.

```sql
ALTER TABLE users ADD COLUMN google_id text;

CREATE UNIQUE INDEX idx_users_google_id
ON users(google_id)
WHERE google_id IS NOT NULL;

COMMENT ON COLUMN users.google_id IS 'Google OIDC subject(sub). 검증된 ID Token에서만 저장';
```

다음 migration 파일을 서버 저장소에 추가한다.

- `migrations/google_auth_preflight.sql`
- `migrations/add_google_auth_support.sql`
- `migrations/google_auth_postflight.sql`
- `migrations/rollback_google_auth_support.sql`
- `migrations/stage_google_auth_apply_pgadmin.sql`
- `migrations/center_google_auth_apply_pgadmin.sql`

preflight는 PostgreSQL 16, 쓰기 가능한 primary, `public.users`, `pgcrypto`, ALTER/CREATE 권한,
기존 `google_id` 컬럼·`idx_users_google_id` 이름 충돌을 읽기 전용으로 검사한다. apply는
`ON_ERROR_STOP`, `lock_timeout`, 명시적 transaction을 사용한다. postflight는 다음을 엄격히 검사한다.

- `users.google_id`가 nullable text인지
- `idx_users_google_id`가 valid/ready/unique partial index인지
- predicate가 `google_id IS NOT NULL`인지
- column COMMENT가 존재하는지
- 실제 non-null 중복이 0건인지

rollback은 `GOOGLE_AUTH_ENABLED=false`와 이전 서버 이미지 배포가 먼저다. `google_id IS NOT NULL` row가
한 건이라도 있으면 파괴적 rollback을 중단하고 컬럼을 유지한다. 0건이며 명시적 확인 변수가 있을 때만
index와 column을 제거한다.

아래 정본도 같은 PR에서 동기화해야 한다.

- `migrations/final_schema.sql`
- 서버 `AGENTS.md`의 users DDL, index와 COMMENT
- `schema.drawio`의 users 속성
- 필요하면 `visibility_flow.drawio`의 인증 진입 설명. 캘린더 공개 규칙 자체는 변경하지 않는다.

## 7. Express 코드 변경 요구

현재 서버 구조를 유지해 다음을 구현한다.

| 위치 | 변경 |
|---|---|
| `package.json` / lockfile | `google-auth-library` 런타임 의존성 추가 |
| `src/models/User.ts` | attributes, creation optional, declare, `User.init`에 nullable `google_id` 추가 |
| `src/services/googleService.ts` | 기능 플래그, ID Token 검증, claim 정규화, 계정 정책, transaction 구현 |
| `src/controllers/authController.ts` | `googleLoginWithToken`과 공통 Google 오류 응답/구조화 로그 추가 |
| `src/routes/authRoutes.ts` | `/google/token`, auth rate limit, `express-validator`, 공통 validation 연결 |
| `src/config/environment.ts` | Google 플래그와 client ID 시작 시 검증 |
| `src/openapi/googleAuthOpenApi.json` | 요청·성공·오류 schema와 예시 추가 |
| `src/openapi.ts` | Google tag/path/schema/response 병합 |

요청 흐름은 프로젝트 규칙대로 다음 순서를 고정한다.

```text
Router → rate limit/validation middleware → Controller → GoogleService
       → Sequelize transaction → User/default template/refresh_tokens
```

Controller는 HTTP 변환과 `request_id` 로그만 담당한다. Google token 검증, 사용자 정책과 transaction은
전용 service에 둔다. 기존 `generateTokens(..., transaction)`과
`ensureDefaultTemplate(..., transaction)`을 재사용한다.

## 8. 환경변수와 시작 시 검증

| 변수 | 서버 | Flutter/네이티브 | 규칙 |
|---|---:|---:|---|
| `GOOGLE_AUTH_ENABLED` | 필수 | 아니오 | `true`/`false`, 기본 false |
| `GOOGLE_SERVER_CLIENT_ID` | 활성 시 필수 | Dart define | Web application OAuth client ID, 양쪽 값 동일 |
| `GOOGLE_IOS_CLIENT_ID` | 아니오 | Dart define | iOS application OAuth client ID |
| `GOOGLE_REVERSED_CLIENT_ID` | 아니오 | iOS xcconfig | iOS client ID의 reversed URL scheme |

`validateEnvironment()`는 `GOOGLE_AUTH_ENABLED`를 boolean으로 검증한다. true이면
`GOOGLE_SERVER_CLIENT_ID`가 비어 있지 않고 `*.apps.googleusercontent.com` 형태인지 확인하고,
Google service singleton을 초기화한다. false이면 endpoint는 503 `GOOGLE_AUTH_DISABLED`를 반환한다.
환경변수 값 자체는 시작 로그에 출력하지 않는다.

## 9. Google Cloud 및 앱 설정

한 Google Cloud 프로젝트에서 동의 화면과 아래 OAuth client를 준비한다.

1. Web application client
   - 이 client ID가 서버와 앱의 `GOOGLE_SERVER_CLIENT_ID`다.
   - ID Token audience 검증에 사용한다.
2. iOS client
   - Bundle ID: `com.hspark.shiftmate`
   - client ID를 `GOOGLE_IOS_CLIENT_ID`, reversed 값은 `GOOGLE_REVERSED_CLIENT_ID`로 주입한다.
3. Android client
   - Package name: `com.hspark.shiftmate`
   - Debug, Stage, Release/Play App Signing 각각의 SHA-1과 SHA-256을 등록한다.
   - 저장소에 `google-services.json`을 추가하지 않는다. Flutter는 Web client ID를
     `serverClientId`로 전달한다.

OAuth 동의 화면은 앱 이름, 지원 이메일, 개인정보처리방침/서비스 약관 도메인을 실제 서비스와
일치시킨다. External 테스트 상태라면 Stage E2E 계정을 테스트 사용자로 등록한다. 이번 로그인은
기본 OIDC 프로필만 사용하므로 Google Drive 등 추가 scope를 요청하지 않는다.

## 10. 보안·로깅·모니터링

- Google ID Token, ShiftMate access/refresh token은 응답 외 로그·APM breadcrumb·오류 details에 남기지 않는다.
- 구조화 로그 허용 필드: `request_id`, `action=google_login`, `result`, `error_code`, `duration_ms`,
  성공 시 내부 `user_id`. email, Google `sub`, token, 전체 claim은 기록하지 않는다.
- 클라이언트 오류에는 Google library의 원문 exception이나 OAuth client ID를 노출하지 않는다.
- rate limit은 기존 인증 endpoint 정책을 재사용한다.
- 지표: 성공/신규/기존/409/invalid/upstream/disabled/429 건수와 latency를 집계한다.
- `GOOGLE_UPSTREAM_UNAVAILABLE` 급증 시 신규 배포와 Google 상태를 함께 확인한다.

## 11. 테스트 완료 조건

### 단위 테스트

- `verifyIdToken()`에 정확한 ID Token과 audience 전달
- 유효한 `sub`, `email_verified`, email, name, picture 정규화
- 잘못된 서명/aud/iss/exp → `GOOGLE_INVALID_TOKEN`
- `email_verified` false·이메일 누락/형식 오류 → `GOOGLE_EMAIL_UNAVAILABLE`
- 기존 `google_id` 로그인 시 저장 프로필 미변경
- 기존 이메일 충돌 → 409와 고정 메시지, provider ID 미변경
- 신규 사용자 transaction 성공과 각 단계 실패 rollback
- 동시 동일 `sub` 요청에서 사용자 1명만 생성
- disabled/upstream/rate limit 및 토큰 비로그 검증

### route/OpenAPI 테스트

- 정확한 endpoint, body validation, status와 공통 오류 wrapper
- 기존/신규 성공의 `is_new_user` boolean과 millisecond `expires_at`
- `googleAuthOpenApi.json` 병합 및 JSON/OpenAPI 파싱

### DB 통합 테스트

- preflight → apply → postflight
- `google_id` null 다수 허용, 동일 non-null 값 거부
- 사용자·기본 템플릿·refresh token 원자성
- 데이터가 생긴 뒤 destructive rollback 차단

## 12. 배포 및 롤백 순서

1. Google Cloud 동의 화면과 Web/iOS/Android client를 준비한다.
2. Stage DB에서 preflight → apply → postflight를 실행하고 시각·DB 이름·결과를 기록한다.
3. Stage 서버에 환경변수를 주입하되 먼저 `GOOGLE_AUTH_ENABLED=false`로 배포한다.
4. 서버 health, 기존 카카오·네이버·Apple 인증 회귀 후 true로 전환한다.
5. Stage iOS/Android 실기기에서 신규, 기존 Google 사용자, 이메일 충돌, 취소, 토큰 오류,
   로그아웃을 E2E 검증한다. Android는 각 실제 서명 인증서 빌드로 확인한다.
6. Center DB preflight → apply → postflight 후 Google 지원 서버를 먼저 배포·활성화한다.
7. Google 버튼이 항상 보이는 Flutter 빌드를 배포한다.

장애 시 순서:

1. `GOOGLE_AUTH_ENABLED=false`로 신규 Google 로그인을 즉시 차단한다.
2. Google 지원 전 서버 이미지로 롤백하되 nullable column/index는 유지한다.
3. 앱은 Google 버튼이 항상 보이므로 503 사용자 메시지와 고객 안내를 확인한다.
4. `google_id` 데이터가 있으면 DB column을 삭제하지 않는다.
5. 데이터가 0건이고 명시적 승인·대상 DB guard를 통과한 경우에만 rollback SQL을 실행한다.

## 13. 서버 구현 체크리스트

- [ ] route + validation + rate limit + controller/service 분리
- [ ] `google-auth-library.verifyIdToken()`과 audience 고정
- [ ] 이메일 자동 연결 금지 및 409 고정 메시지
- [ ] 신규 사용자 transaction과 동시성 테스트
- [ ] User 모델, migration, 정본 DDL, AGENTS/diagram 동기화
- [ ] 공통 오류 wrapper와 request ID
- [ ] OpenAPI 병합
- [ ] 환경변수 fail-fast 및 secret 비로그
- [ ] preflight/apply/postflight/rollback 리허설
- [ ] Stage iOS/Android 실기기 E2E 후 Center 적용

## 14. 구현 기준 문서

- Flutter `google_sign_in`: <https://pub.dev/packages/google_sign_in>
- Flutter Android 설정: <https://pub.dev/packages/google_sign_in_android>
- Flutter iOS 설정: <https://pub.dev/packages/google_sign_in_ios>
- Google ID Token 서버 검증: <https://developers.google.com/identity/gsi/web/guides/verify-google-id-token>
- Android 앱의 백엔드 인증 흐름: <https://developers.google.com/identity/sign-in/android/backend-auth>
- Node.js `google-auth-library`: <https://github.com/googleapis/google-auth-library-nodejs>
