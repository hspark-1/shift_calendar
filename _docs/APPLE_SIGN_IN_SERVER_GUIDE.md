# Apple 소셜 로그인 서버 구현 가이드

## 1. 문서 상태와 범위

- 작성일: 2026-08-06
- 대상 서버: `../shift_calendar_server` Express 4 + TypeScript + Sequelize + PostgreSQL 16
- 대상 앱: 현재 Flutter 저장소의 Apple 로그인 구현
- 상태: Flutter 요청 계약 확정, 서버 구현 전
- 목표: Apple authorization code를 서버가 직접 교환·검증한 뒤 기존 ShiftMate Access/Refresh Token을 발급한다.
- 비목표: 클라이언트가 Apple identity token의 payload만 디코딩해 사용자를 신뢰하는 방식, 이메일만으로 기존 계정을 자동 연결하는 방식

현재 서버의 `users.apple_id`, Sequelize `User.apple_id`, partial unique index
`idx_users_apple_id`는 이미 존재한다. 다만 실제 Stage/Center DB가 DDL과 일치하는지는 migration 전
preflight로 다시 확인한다. 프론트 저장소의 `schema.drawio`는 `calendars/calendar_shares`가 남은
이전 구조이므로 이 기능의 DB 정본으로 사용하지 않는다.

## 2. 확정된 전체 흐름

```text
Flutter LoginPage
  → POST /api/v1/auth/apple/challenge { platform }
  → 서버가 일회성 nonce/state와 플랫폼별 client_id/redirect_uri 반환
  → iOS: AuthenticationServices 네이티브 인증
  → Android: Apple 웹 인증 + 서버 callback + 고정 intent callback
  → Flutter가 authorization_code/state/nonce를 POST /api/v1/auth/apple로 전달
  → 서버가 challenge를 원자적으로 1회 소비
  → Apple /auth/token으로 authorization code 교환
  → Apple JWKS로 id_token 서명과 iss/aud/exp/nonce 검증
  → users.apple_id 기준 사용자 조회 또는 신규 생성
  → Apple refresh token 암호화 저장
  → 기존 generateTokens()로 ShiftMate JWT 발급
  → Flutter Secure Storage 저장
```

신뢰 경계는 서버다. Flutter가 보내는 `identity_token`, 이름, 플랫폼 문자열은 요청 자료일 뿐이며,
사용자 식별자와 이메일은 Apple token endpoint 결과의 검증된 `id_token`을 기준으로 확정한다.

## 3. Flutter와 고정한 HTTP 계약

### 3.1 Challenge 발급

```http
POST /api/v1/auth/apple/challenge
Content-Type: application/json
```

요청:

```json
{
  "platform": "ios"
}
```

`platform` 허용값은 소문자 `ios`, `android`뿐이다.

iOS 성공 응답:

```json
{
  "success": true,
  "data": {
    "nonce": "base64url-random-value",
    "state": "base64url-random-value",
    "client_id": "com.hspark.shiftmate",
    "redirect_uri": null,
    "expires_at": "2026-08-06T00:05:00.000Z"
  }
}
```

Android 성공 응답:

```json
{
  "success": true,
  "data": {
    "nonce": "base64url-random-value",
    "state": "base64url-random-value",
    "client_id": "APPLE_SERVICE_ID 환경변수 값",
    "redirect_uri": "https://stage-api.shiftmate.co.kr/api/v1/auth/apple/callback",
    "expires_at": "2026-08-06T00:05:00.000Z"
  }
}
```

규칙:

- nonce와 state는 각각 최소 32바이트의 `crypto.randomBytes()`를 base64url로 인코딩한다.
- DB에는 원문을 저장하지 않고 SHA-256 hash만 저장한다.
- 유효시간은 5분이다.
- `client_id`와 `redirect_uri`는 클라이언트 입력을 반사하지 않고 서버 환경설정으로 결정한다.
- route에 기존 `authRateLimitMiddleware`를 적용한다.
- `APPLE_AUTH_ENABLED=false`이면 `503 APPLE_AUTH_DISABLED`를 반환한다.

### 3.2 Apple 로그인 완료

```http
POST /api/v1/auth/apple
Content-Type: application/json
```

요청:

```json
{
  "platform": "ios",
  "authorization_code": "Apple authorization code",
  "identity_token": "클라이언트가 받은 token, 선택",
  "state": "challenge에서 받은 원문",
  "nonce": "challenge에서 받은 원문",
  "given_name": "길동",
  "family_name": "홍"
}
```

필드 규칙:

| 필드 | 필수 | 서버 규칙 |
| --- | --- | --- |
| `platform` | Y | `ios` 또는 `android` |
| `authorization_code` | Y | 비어 있지 않은 문자열, 최대 길이 제한 적용 |
| `identity_token` | N | 있으면 별도로 검증하고 교환 결과 token과 `sub`/`nonce`가 같아야 함 |
| `state` | Y | 저장된 SHA-256 hash와 정확히 일치해야 함 |
| `nonce` | Y | 저장된 hash 및 검증된 id_token의 nonce claim과 모두 일치 |
| `given_name` | N | 최초 인증 때만 올 수 있음. trim 후 1~100자만 프로필 후보로 사용 |
| `family_name` | N | 최초 인증 때만 올 수 있음. trim 후 1~100자만 프로필 후보로 사용 |

클라이언트의 이메일은 받지 않는다. Apple이 검증된 id_token에 넣은 이메일만 사용한다.

성공 응답:

```json
{
  "success": true,
  "message": "회원가입이 완료되었습니다.",
  "data": {
    "user": {
      "user_id": "uuid",
      "email": "relay@privaterelay.appleid.com",
      "name": "홍 길동",
      "profile_image_url": null,
      "timezone": "Asia/Seoul",
      "apple_id": "verified-apple-subject",
      "created_at": "2026-08-06T00:00:00.000Z"
    },
    "access_token": "ShiftMate JWT",
    "refresh_token": "ShiftMate JWT refresh token",
    "expires_at": 1785978000000,
    "is_new_user": true
  }
}
```

`is_new_user`는 반드시 `data.is_new_user` boolean으로 반환한다. 기존 Flutter는 메시지 fallback도
유지하지만 Apple 구현은 메시지 문구로 상태를 추론하지 않는다.

### 3.3 Android/Web callback

```http
POST /api/v1/auth/apple/callback
Content-Type: application/x-www-form-urlencoded
```

Apple이 `code`, `id_token`, `state`, 선택적인 `user` 또는 `error`를 form body로 전달한다.

서버 처리:

1. `state` hash로 만료되지 않고 소비되지 않은 Android challenge를 조회한다.
2. state가 없거나 틀리면 앱으로 redirect하지 않고 400을 반환한다.
3. 허용 필드 `code`, `id_token`, `state`, `user`, `error`만 URL encode한다.
4. 아래의 고정된 intent URL로 303 redirect한다.

```text
intent://callback?<allowlisted-parameters>#Intent;package=com.hspark.shiftmate;scheme=signinwithapple;end
```

package, scheme, path를 request 값으로 만들지 않는다. callback에서는 앱 세션을 생성하거나
challenge를 소비하지 않는다. 실제 소비와 Apple code 교환은 앱이 다시 호출하는
`POST /auth/apple`에서만 수행한다.

## 4. 서버 파일별 구현 위치

권장 변경:

```text
src/
├── config/environment.ts
├── controllers/authController.ts
├── models/
│   ├── OAuthAuthorization.ts
│   ├── OAuthLoginChallenge.ts
│   └── index.ts
├── openapi/
│   └── appleAuthOpenApi.json
├── openapi.ts
├── routes/authRoutes.ts
└── services/
    └── appleService.ts

migrations/
├── apple_auth_preflight.sql
├── add_apple_auth_support.sql
├── apple_auth_postflight.sql
└── rollback_apple_auth_support.sql

test/
├── appleAuth.test.cjs
└── appleAuthIntegration.test.cjs
```

- `authRoutes.ts`: 세 endpoint의 rate limit과 `express-validator` 검증만 담당한다.
- `authController.ts`: HTTP status/response 변환, device info 전달만 담당한다.
- `appleService.ts`: challenge, callback state 확인, client secret, token 교환, JWKS 검증,
  계정 생성/조회, Apple token 암호화를 담당한다.
- `OAuthLoginChallenge.ts`: pre-auth 일회성 challenge와 소비 상태를 관리한다.
- `OAuthAuthorization.ts`: 계정 삭제 시 사용할 Apple refresh token을 암호화해 보관한다.
- `appleAuthOpenApi.json`: 세 endpoint와 공통 오류 schema를 정의하고 `openapi.ts`에서 병합한다.

카카오·네이버 controller의 중복 provisioning을 이번 변경에서 함께 리팩터링하지 않는다. Apple은
별도 service로 추가하고, 공통화는 전체 소셜 로그인 회귀 테스트가 준비된 후 별도 ADR로 진행한다.

## 5. Apple 서비스 구현 규칙

### 5.1 플랫폼별 고정 설정

```typescript
function resolveAppleClient(platform: "ios" | "android") {
  if (platform === "ios") {
    return {
      client_id: getRequiredEnvironmentVariable("APPLE_IOS_CLIENT_ID"),
      redirect_uri: null,
    };
  }

  return {
    client_id: getRequiredEnvironmentVariable("APPLE_SERVICE_ID"),
    redirect_uri: getRequiredEnvironmentVariable("APPLE_REDIRECT_URI"),
  };
}
```

요청의 임의 `client_id`와 `redirect_uri`를 사용하지 않는다. iOS token 교환에는 redirect URI를
넣지 않고 Android 교환에는 challenge 생성 시 저장한 redirect URI를 정확히 넣는다.

### 5.2 Challenge 원자적 소비

Apple HTTP 호출 중 DB transaction과 row lock을 오래 유지하지 않는다. 먼저 다음 조건의 단일
`UPDATE ... RETURNING`으로 challenge를 소비한다.

```sql
UPDATE oauth_login_challenges
SET consumed_at = now()
WHERE provider = 'APPLE'
  AND platform = :platform
  AND state_hash = :state_hash
  AND nonce_hash = :nonce_hash
  AND consumed_at IS NULL
  AND expires_at > now()
RETURNING *;
```

반환 행이 없으면 `APPLE_INVALID_CHALLENGE`다. Apple upstream 장애가 발생하더라도 소비 상태는
되돌리지 않고 앱이 새 challenge부터 재시도하게 한다. 이 방식이 code/state 재사용을 명확히 막는다.

### 5.3 Apple client secret

- 알고리즘: ES256
- header `kid`: `APPLE_KEY_ID`
- issuer: `APPLE_TEAM_ID`
- subject: 현재 challenge의 `client_id`
- audience: `https://appleid.apple.com`
- 만료: 발급 후 5분
- private key: `APPLE_PRIVATE_KEY_PATH` 파일을 프로세스 시작 시 읽어 캐시

현재 의존성의 `jsonwebtoken`과 Node `crypto`로 구현할 수 있다. private key 원문, client secret,
authorization code는 로그에 남기지 않는다.

### 5.4 Authorization code 교환

```http
POST https://appleid.apple.com/auth/token
Content-Type: application/x-www-form-urlencoded
```

```text
client_id=<challenge client id>
client_secret=<ES256 client secret>
code=<authorization code>
grant_type=authorization_code
redirect_uri=<Android에서만 challenge에 저장된 exact URL>
```

응답의 `id_token`을 인증 정본으로 사용한다. `refresh_token`은 계정 삭제 시 Apple revoke를 수행할
수 있도록 암호화 저장한다. Apple 오류의 원문 token/code는 버리고 `error` 종류만 내부 코드로 매핑한다.

교환 응답에 새 `refresh_token`이 있으면 해당 subject/client ID authorization의 암호문을 upsert한다.
반복 로그인에서 refresh token이 없고 기존 활성 authorization이 있으면 기존 암호문을 유지한다.
신규 subject/client ID인데 refresh token도 기존 authorization도 없으면 계정 삭제/revoke를 보장할 수
없으므로 `APPLE_REFRESH_TOKEN_UNAVAILABLE`로 로그인 transaction을 완료하지 않는다.

### 5.5 JWKS와 identity token 검증

JWKS endpoint는 `GET https://appleid.apple.com/auth/keys`다.

검증 순서:

1. JWT header에서 `alg=RS256`, `kid`를 읽는다.
2. 메모리 cache에서 kid를 찾고 없을 때 JWKS를 한 번 강제 갱신한다.
3. `crypto.createPublicKey({ key: jwk, format: "jwk" })`로 public key를 만든다.
4. `jsonwebtoken.verify()`에 issuer, audience, algorithm을 명시한다.
5. `exp`, `iat`, `sub`, `nonce`를 검증한다.
6. 신규 사용자 이메일은 `email_verified`가 boolean true 또는 문자열 `"true"`일 때만 사용한다.
7. 클라이언트 `identity_token`이 있으면 동일하게 검증하고 교환 결과와 `sub`/`nonce`가 같은지 확인한다.

필수 claim:

```text
iss = https://appleid.apple.com
aud = challenge.client_id
exp > now
sub = non-empty string
nonce = challenge의 raw nonce
```

JWKS는 `Cache-Control`을 존중하되 최대 24시간까지만 cache한다. 알 수 없는 kid에서는 cache를
무조건 한 번 새로 받은 뒤에도 없으면 `APPLE_INVALID_TOKEN`으로 종료한다.

## 6. 사용자 생성과 계정 연결 정책

처리 순서:

1. 검증된 `sub`로 `users.apple_id`를 조회한다.
2. 존재하면 해당 사용자를 로그인시키며 기존 email/name을 자동 변경하지 않는다.
3. 존재하지 않으면 검증된 Apple email을 확인한다.
4. 같은 email의 기존 사용자가 있으면 Apple ID를 자동 연결하지 않고 `409 ACCOUNT_LINK_REQUIRED`를 반환한다.
5. 같은 email이 없으면 transaction 안에서 신규 사용자를 만든다.
6. 같은 transaction에서 `ensureDefaultTemplate(user_id, transaction)`, Apple authorization 저장,
   `generateTokens(user, { device_info, transaction })`를 수행한다.

Apple 비공개 relay email도 검증된 고유 이메일이면 신규 계정 이메일로 사용할 수 있다. 하지만
relay 주소를 실제 이메일과 같다고 추정하거나 다른 provider 이메일에 자동 병합하지 않는다.

신규 사용자에서 검증된 email이 없으면 `APPLE_EMAIL_UNAVAILABLE`을 반환한다. `users.email`이
NOT NULL/UNIQUE인 현재 DB에서 가짜 이메일을 생성하지 않는다. 기존 `apple_id` 사용자에게는
token에 email이 빠져도 저장된 계정으로 로그인할 수 있다.

이름은 보안 식별자가 아니다. 최초 로그인에서 받은 `family_name`, `given_name`을 길이 검증 후
조합하고 둘 다 없으면 `Apple 사용자`를 사용한다. Flutter 신규 사용자 흐름에서 이름을 다시
편집할 수 있다.

동시 최초 로그인은 `idx_users_apple_id`, `uq_users_email`의 unique conflict를 처리해야 한다.
conflict 후 같은 `apple_id` 사용자를 재조회해 로그인하거나, 이메일 충돌이면
`ACCOUNT_LINK_REQUIRED`로 결정한다. `created_at < 1초`로 신규 사용자를 추정하지 말고 transaction
내 `created_user` boolean을 그대로 `data.is_new_user`에 넣는다.

## 7. DB expand migration

기존 `users.apple_id`는 유지하고 다음 두 테이블을 추가한다.

```sql
BEGIN;

SET LOCAL lock_timeout = '5s';
SET LOCAL search_path = public, pg_catalog;

CREATE TABLE oauth_login_challenges (
  challenge_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  provider text NOT NULL,
  platform text NOT NULL,
  state_hash char(64) NOT NULL,
  nonce_hash char(64) NOT NULL,
  client_id text NOT NULL,
  redirect_uri text,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT ck_oauth_challenge_provider CHECK (provider = 'APPLE'),
  CONSTRAINT ck_oauth_challenge_platform CHECK (platform IN ('ios', 'android')),
  CONSTRAINT ck_oauth_challenge_state_hash CHECK (state_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_oauth_challenge_nonce_hash CHECK (nonce_hash ~ '^[0-9a-f]{64}$'),
  CONSTRAINT ck_oauth_challenge_expiry CHECK (expires_at > created_at),
  CONSTRAINT ck_oauth_challenge_redirect CHECK (
    (platform = 'ios' AND redirect_uri IS NULL)
    OR (platform = 'android' AND redirect_uri IS NOT NULL)
  )
);

CREATE UNIQUE INDEX uq_oauth_login_challenges_state
ON oauth_login_challenges(state_hash);

CREATE INDEX idx_oauth_login_challenges_cleanup
ON oauth_login_challenges(expires_at)
WHERE consumed_at IS NULL;

CREATE TABLE oauth_authorizations (
  authorization_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL,
  provider text NOT NULL,
  provider_subject text NOT NULL,
  client_id text NOT NULL,
  refresh_token_ciphertext bytea NOT NULL,
  refresh_token_iv bytea NOT NULL,
  refresh_token_auth_tag bytea NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz,

  CONSTRAINT fk_oauth_authorizations_user
    FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
  CONSTRAINT ck_oauth_authorizations_provider CHECK (provider = 'APPLE'),
  CONSTRAINT uq_oauth_authorizations_subject_client
    UNIQUE (provider, provider_subject, client_id)
);

CREATE INDEX idx_oauth_authorizations_user_active
ON oauth_authorizations(user_id, provider)
WHERE revoked_at IS NULL;

COMMENT ON TABLE oauth_login_challenges IS
  '소셜 로그인 전 일회성 state/nonce hash. 원문 credential은 저장하지 않는다.';
COMMENT ON TABLE oauth_authorizations IS
  '외부 OAuth 연결과 계정 삭제용 refresh token 암호문. 앱 JWT refresh_tokens와 분리한다.';

COMMIT;
```

`oauth_authorizations`의 encrypted refresh token은 기존 `refresh_tokens.token_hash`에 넣지 않는다.
ShiftMate refresh token은 검증 시 hash 조회가 목적이지만 Apple refresh token은 revoke 요청을 위해
원문 복구가 필요하다.

암호화는 AES-256-GCM을 사용한다. `APPLE_TOKEN_ENCRYPTION_KEY`는 base64 decode 결과가 정확히
32바이트여야 하며, 행마다 12바이트 random IV와 auth tag를 저장한다. 복호화 실패는 로그인 성공으로
무시하지 말고 운영 경보 대상 `APPLE_TOKEN_DECRYPT_FAILED`로 처리한다.

### Migration preflight

Stage/Center 각각 다음을 확인한다.

- PostgreSQL 16, writable primary, `pgcrypto` 존재
- `public.users.apple_id`가 text nullable인지
- `idx_users_apple_id`가 unique/valid/ready이고 `apple_id IS NOT NULL` partial predicate인지
- 두 신규 테이블·인덱스 이름이 기존 object와 충돌하지 않는지
- 백업 식별자와 대상 DB 이름이 승인값과 일치하는지

`migrations/final_schema.sql`은 `DROP SCHEMA`가 있으므로 Stage/Center에 절대 실행하지 않는다.

### Postflight

- 전체 컬럼 타입/nullability, FK/check/unique, partial index, COMMENT를 카탈로그에서 검증한다.
- 테스트 challenge를 transaction 안에서 insert/rollback해 DDL 동작을 확인한다.
- 앱 배포 전 신규 authorization/challenge 테이블 row 수가 0인지 기록한다.

## 8. 환경변수와 시작 검증

```dotenv
APPLE_AUTH_ENABLED=false
APPLE_TEAM_ID=
APPLE_KEY_ID=
APPLE_IOS_CLIENT_ID=com.hspark.shiftmate
APPLE_SERVICE_ID=
APPLE_REDIRECT_URI=https://stage-api.shiftmate.co.kr/api/v1/auth/apple/callback
APPLE_PRIVATE_KEY_PATH=/run/secrets/apple_signin.p8
APPLE_TOKEN_ENCRYPTION_KEY=
APPLE_CHALLENGE_TTL_SECONDS=300
APPLE_JWKS_CACHE_SECONDS=21600
```

`environment.ts` 규칙:

- `APPLE_AUTH_ENABLED`를 공통 boolean parser로 검증한다.
- false일 때 Apple secret은 필수로 만들지 않는다.
- true일 때 위 설정을 모두 필수 검증한다.
- iOS Client ID는 정확히 `com.hspark.shiftmate`인지 검사한다.
- redirect URI는 HTTPS이며 path가 `/api/v1/auth/apple/callback`인지 검사한다.
- private key path 파일이 존재하고 프로세스가 읽을 수 있는지 startup에서 확인한다.
- encryption key는 base64 decode 32바이트인지 확인한다.
- challenge TTL은 60~600초 범위로 제한한다.

`.p8` 파일과 encryption key는 이미지, Git, 로그, `.env.example` 실제값에 넣지 않는다. Stage와
Center는 별도 암호화 키와 별도 Service ID/redirect URI를 사용하고 Apple Developer에서 각각
허용한다.

## 9. 오류 계약

Flutter의 `handleApiError()`가 읽을 수 있도록 실패 응답은 다음 형식을 사용한다.

```json
{
  "success": false,
  "error": {
    "code": "APPLE_INVALID_CHALLENGE",
    "message": "Apple 로그인 요청이 만료되었습니다. 다시 시도해주세요."
  },
  "request_id": "uuid"
}
```

| HTTP | code | 조건 |
| --- | --- | --- |
| 400 | `APPLE_INVALID_PLATFORM` | ios/android 이외 값 |
| 400 | `APPLE_INVALID_CHALLENGE` | state/nonce 불일치, 만료, 이미 소비됨 |
| 400 | `APPLE_INVALID_TOKEN` | 서명/issuer/audience/nonce/claim 오류 |
| 400 | `APPLE_CODE_INVALID` | 만료·재사용·잘못된 authorization code |
| 400 | `APPLE_EMAIL_UNAVAILABLE` | 신규 계정인데 검증된 이메일 없음 |
| 400 | `APPLE_REFRESH_TOKEN_UNAVAILABLE` | 신규 authorization인데 refresh token 없음 |
| 409 | `ACCOUNT_LINK_REQUIRED` | 검증된 이메일이 기존 계정과 충돌 |
| 429 | `AUTH_RATE_LIMIT_EXCEEDED` | 기존 auth rate limit 초과 |
| 502 | `APPLE_UPSTREAM_UNAVAILABLE` | Apple token/JWKS 일시 장애 |
| 503 | `APPLE_AUTH_DISABLED` | 기능 플래그 비활성 |

사용자 취소는 서버 오류가 아니다. iOS는 Flutter plugin의 canceled exception, Android는 callback의
`error=user_cancelled_authorize`가 plugin 취소 예외로 변환되며 Flutter는 실패 다이얼로그를 띄우지 않는다.

## 10. 로깅과 보안

로그 허용값:

```text
request_id, provider=APPLE, platform, user_id, error_code,
challenge 결과(success/expired/replayed), upstream status, duration_ms
```

로그 금지값:

```text
authorization_code, identity_token, access_token, refresh_token,
raw nonce/state, client secret, .p8 내용, relay email 전체값
```

- callback query/body를 morgan URL 로그에 포함하지 않는다. 현재 safe-path 방식은 query를 버리므로 유지한다.
- Apple HTTP timeout을 connect/response 합계 5초 수준으로 명시하고 무제한 재시도하지 않는다.
- token endpoint는 동일 로그인 안에서 자동 재시도하지 않는다. authorization code 중복 사용 위험이 있다.
- callback은 고정 intent target과 allowlist parameter만 사용해 open redirect를 차단한다.
- challenge cleanup은 만료 또는 소비 후 24시간이 지난 행을 batch 삭제한다.

## 11. Apple refresh token과 계정 삭제

앱에서 계정을 생성할 수 있으므로 App Store 제출 전 앱 내 계정 삭제가 필요하다. Apple 연결 계정은
삭제 처리 중 활성 `oauth_authorizations`를 모두 복호화해 다음 endpoint로 revoke한다.

```http
POST https://appleid.apple.com/auth/revoke
Content-Type: application/x-www-form-urlencoded
```

```text
client_id=<authorization.client_id>
client_secret=<해당 client_id로 만든 ES256 secret>
token=<decrypted refresh token>
token_type_hint=refresh_token
```

revoke 성공 후 `revoked_at`을 설정하고 ShiftMate JWT·기기 연결을 모두 무효화한다. 사용자 데이터의
실제 삭제/익명화 방식은 현재 FK와 보존 정책을 별도 감사해 구현해야 하며, Apple 버튼을 Production에
노출하기 전 `DELETE /api/v1/auth/account`와 Flutter 설정 화면 진입을 함께 완료한다.

Apple server-to-server notification endpoint는 2차 hardening으로 추가한다. authorization revoked,
account disabled 등 Apple 상태 변경 시 로컬 authorization/JWT를 무효화하며 payload 서명을 동일한
JWKS 규칙으로 검증한다.

## 12. Apple Developer 설정

1. App ID `com.hspark.shiftmate`에 Sign in with Apple을 primary App ID로 활성화한다.
2. capability 변경 뒤 Development/Distribution provisioning profile을 다시 생성한다.
3. Sign in with Apple key를 만들고 Team ID, Key ID, 1회 다운로드 `.p8`를 Secret Manager에 저장한다.
4. Android용 Service ID를 primary App ID에 연결한다.
5. Stage와 Center HTTPS domain/return URL을 정확히 등록한다. localhost와 IP는 사용하지 않는다.
6. 비공개 이메일 relay 발송 도메인에 SPF/DKIM을 설정한다.
7. 이메일 분류는 `privaterelay.appleid.com`, `private.icloud.com`을 모두 수용하되 domain 문자열만으로
   계정을 자동 연결하지 않는다.

## 13. 테스트 계획

### 단위 테스트

- client secret의 ES256, iss/sub/aud/kid/exp
- platform별 client ID와 redirect URI 선택
- state/nonce 생성 길이와 hash, 만료, 1회 소비
- JWKS cache hit, unknown kid 강제 갱신, 여전히 없는 kid 실패
- id_token의 잘못된 iss/aud/alg/exp/nonce/sub/email_verified
- client identity token과 교환 identity token의 sub 불일치
- AES-GCM 암호화/복호화, 다른 key/tag에서 실패
- 오류가 credential 원문 없이 공통 code로 매핑되는지

### HTTP 테스트

- 세 endpoint에 rate limit/validation 적용
- iOS/Android challenge 응답 차이
- callback의 잘못된 state 400
- callback의 고정 package/scheme/path와 parameter allowlist
- 첫 Apple 로그인 `200 + is_new_user=true`
- 반복 로그인 `200 + is_new_user=false`
- 이름 없는 최초 로그인
- relay email 최초 로그인
- 기존 email 충돌 `409 ACCOUNT_LINK_REQUIRED`
- 신규 사용자 email 없음 `400 APPLE_EMAIL_UNAVAILABLE`
- 같은 state/code replay 실패
- 로그/응답에 Apple credential이 없는지

### PostgreSQL 통합 테스트

- 동시 최초 로그인에서 사용자와 기본 템플릿이 각각 하나만 생성되는지
- challenge의 atomic consume 경쟁에서 하나만 성공하는지
- 사용자 생성/기본 템플릿/OAuth authorization/JWT refresh token 중 하나가 실패하면 전체 rollback되는지
- 같은 subject의 iOS/Android authorization row가 client ID별로 보존되는지
- 계정 삭제 시 모든 authorization revoke 후 JWT/device가 무효화되는지

### 실제 Stage E2E

- iOS 실기기: 이메일 공유/가리기, 최초/반복, 취소, 앱 재설치
- Android 실기기: Chrome Custom Tab 성공, 취소, 뒤로가기, callback 복귀
- Apple 설정에서 앱 연결 해제 후 재로그인
- 5분 경과 challenge와 authorization code 재사용 실패
- Stage/Center Service ID와 redirect URI 교차 사용 실패
- 계정 삭제 후 Apple authorization revoke 확인

## 14. 배포와 롤백 순서

1. Apple Developer App ID/key/Service ID/relay 설정
2. Stage DB 백업과 preflight
3. DB expand migration과 strict postflight
4. `APPLE_AUTH_ENABLED=false` 서버 이미지 배포
5. Stage secret 주입 후 서버 flag만 true
6. curl/자동 테스트로 challenge와 callback 검증
7. Flutter Stage 빌드에 `--dart-define=APPLE_LOGIN_ENABLED=true` 적용
8. iOS/Android 실제 계정 E2E
9. 계정 삭제/revoke까지 통과 후 Center DB·서버·앱 순으로 활성화

애플리케이션 롤백:

- Flutter `APPLE_LOGIN_ENABLED=false`로 버튼을 먼저 숨긴다.
- 서버 `APPLE_AUTH_ENABLED=false`로 신규 challenge/login을 중단한다.
- 기존 `oauth_authorizations`와 `users.apple_id`는 보존해 계정 삭제/revoke를 계속 수행한다.
- add-only DB 테이블은 즉시 drop하지 않는다.
- `.p8` key revoke는 모든 활성 authorization의 처리 전략을 확인한 뒤 마지막에 수행한다.

DB rollback은 활성 row가 0이고 명시적 승인 변수가 있을 때만 신규 두 테이블을 제거한다.
`users.apple_id`와 기존 unique index는 이번 변경 이전부터 존재하므로 rollback 대상이 아니다.

## 15. 완료 조건

- [ ] 실제 Stage/Center의 `users.apple_id`와 partial unique index preflight 통과
- [ ] challenge/login/callback 세 endpoint 및 OpenAPI 구현
- [ ] code 교환과 모든 token claim 검증
- [ ] 일회성 challenge atomic consume와 replay 테스트 통과
- [ ] 이메일 충돌 자동 연결 금지
- [ ] Apple refresh token AES-256-GCM 저장과 revoke 구현
- [ ] 명시적인 `data.is_new_user` 반환
- [ ] Flutter 단위 테스트와 서버 단위/통합 테스트 통과
- [ ] iOS/Android Stage 실기기 E2E 통과
- [ ] 앱 내 계정 삭제와 Apple revoke 통과
- [ ] 로그 credential 비노출 감사 통과
- [ ] Stage/Center feature flag 롤백 리허설 완료

## 16. 공식 참고자료

- Apple 사용자 인증: <https://developer.apple.com/documentation/signinwithapple/authenticating-users-with-sign-in-with-apple>
- 사용자 token 검증: <https://developer.apple.com/documentation/signinwithapple/verifying-a-user>
- token 생성/교환: <https://developer.apple.com/documentation/signinwithapplerestapi/generate-and-validate-tokens>
- JWKS: <https://developer.apple.com/documentation/signinwithapplerestapi/fetch-apple%27s-public-key-for-verifying-token-signature>
- token revoke: <https://developer.apple.com/documentation/signinwithapplerestapi/revoke-tokens>
- 웹/Android Service ID: <https://developer.apple.com/help/account/capabilities/configure-sign-in-with-apple-for-the-web>
- 앱 내 계정 삭제: <https://developer.apple.com/support/offering-account-deletion-in-your-app/>
- private email relay: <https://developer.apple.com/help/account/capabilities/configure-private-email-relay-service>
- private relay domain 변경 공지: <https://developer.apple.com/news/?id=sus6t6ab>
- Flutter plugin 7.0.1: <https://pub.dev/packages/sign_in_with_apple/versions/7.0.1>
