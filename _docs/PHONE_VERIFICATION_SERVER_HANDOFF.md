# 서버 요청: Firebase Phone Auth 기반 휴대폰 인증

작성/개정일: 2026-11-21 · 대상: Express/TypeScript + Sequelize/PostgreSQL 서버
상태: **로컬 서버·정상 앱 연동 확인 및 앱 재시도 보완 완료 / 서버 응답 보완·실문자 인수 전** · ADR-0088·0090 · 이전 SENS + Redis OTP 명세 대체

2026-11-21 후속: 최초 앱 구현은 사용자 확인에 따라 서버 작업 전 상태에서 진행했습니다. 이후 서버 완료 요청을 받아 clean HEAD f1664b7의 challenge/verify·Admin·DB 증명/영수증/최신 번호 비교를 확인하고 실제 앱 HTTP/DTO/controller와 로컬 Express/PostgreSQL을 연결해 검증했습니다. 정상 흐름은 일치하며 예외2건은14절을 따릅니다. 서버 작업 기록에는 push/배포·Stage 실문자 미수행으로 적혀 있습니다. 원격 완료로 간주하지 않으며 신규 API 미제공이면 앱은 인증 필요한 저장을 차단합니다.

## 1. 전달할 요청

SMS 발송/인증번호 검증을 Firebase Phone Auth에 맡기고, 서버는 Firebase Admin으로 인증 결과를 검증해 기존 프로필 저장과 연결해 주세요.

1. 가입 완료(`/auth/profile/complete`)는 인증 필수. 소셜 로그인 시 번호를 받았더라도 면제하지 않습니다.
2. 개인정보 수정(`/auth/profile`)은 저장 직전 DB 번호와 다른 번호를 저장할 때만 새 번호 인증이 필요합니다. phone 생략/동일 번호에서 타 필드 수정은 유지합니다.
3. 기존 ShiftMate JWT를 계속 앱 인증에 사용합니다. Firebase ID 토큰은 번호 확인 증거이며 앱 로그인/계정 선택·자동 연결에 사용하지 않습니다.
4. 서버 challenge 생성 → Flutter Firebase 인증 → Firebase ID 토큰 검증/저장용 증명 교환 → 기존 프로필 저장 흐름을 추가합니다.
5. SENS 호출·문자 발신번호/키·서버 OTP 생성/해시/오답 검증·Redis OTP는 구현하지 않습니다. 기존 Redis 근무 캐시는 유지합니다.

신규 API/필드/DB·초기 시간값은 구현 요청안입니다. OpenAPI·Stage 인수로 확정해 주세요. 이번에 운영 DB/Firebase 콘솔/서버 배포는 확인하거나 변경하지 않았습니다. [모바일 계획](PHONE_VERIFICATION_FLUTTER_PLAN.md)과 함께 사용합니다.

## 2. 현행 코드에서 확인한 사실

| 코드 | 확인 내용 / 변경 지점 |
|---|---|
| `src/routes/authRoutes.ts` | JWT 보호 profile complete/update POST·이미지 middleware. 신규 phone API 없음 |
| `src/controllers/authController.ts` | profile controller → mutateProfile, 신규 사용자 JWT/미완료 프로필 분기 |
| `src/services/profileService.ts` | Sequelize transaction/User row lock·전화 unique409·profile_completed_at 저장 |
| `src/services/profileMutationService.ts` | JSON/multipart·이미지 account lock/정리. 신규 인증 필드를 명시적 allowlist에 전달해야 함 |
| `src/models/User.ts`, `src/utils/phone.ts` | phone nullable/unique·하이픈 정규화·완료 boolean. 인증 시각 없음, prefix 검증 별도 필요 |
| `src/services/googleService.ts`, `naverService.ts` | OAuth 번호 미리 채움/저장이 존재하며 SMS 인증으로 간주할 수 없음 |
| `src/services/firebasePushProvider.ts` | 기존 firebase-admin의 named app·ADC·FIREBASE_PROJECT_ID로 FCM 전송. Auth 검증 service는 없음 |
| `src/config/environment.ts` | Firebase 설정 검증이 현재 push worker 활성 조건에 연결돼 있음. Auth는 API 프로세스에서 독립 검증 필요 |
| `src/middlewares/auth.ts`, `rateLimit.ts` | 앱 JWT/활성 계정, 프로세스별 IP rate limit. Firebase token 검증/분산 인증 제한과 별개 |
| `src/utils/accountDataLock.ts` | 이미지 변경/탈퇴 관련 PostgreSQL session lock. 외부 I/O 중 DB transaction을 열지 않는 구조 |
| `src/openapi/profileAuthOpenApi.json`, `src/openapi.ts` | 기존 프로필 스펙·조합 지점. API_DOCS_ENABLED 시 Swagger/JSON 노출 |
| Flutter `firebase_environment_options.dart`, `pubspec.yaml` | Stage/운영 FCM 프로젝트 분리, firebase_core/messaging 존재, firebase_auth 없음 |

기존 phone migration/index를 재사용합니다. AGENTS.md 및 schema.drawio/visibility_flow.drawio는 이전 조사에서 읽었으며 그림의 calendars/calendar_shares 모델은 현행 phone 확장을 담지 않습니다. 실제 model/migration과 대조하고 캘린더/ACL 구조는 바꾸지 않습니다. 전체 schema 삭제 DDL은 사용하지 않습니다.

## 3. 인증 책임과 API 흐름

```text
Flutter → POST /auth/phone/challenges (앱 JWT, phone, purpose)
        ← challenge_id / phone_e164 / 앱 인증 세션 기한
Flutter → Firebase verifyPhoneNumber → SMS 또는 Android 자동/즉시 인증
        → signInWithCredential → Firebase ID token
Flutter → POST /auth/phone/verify (앱 JWT, challenge_id, firebase_id_token)
Express → Firebase Admin verifyIdToken(token, true)
        → phone provider / 번호 / 프로젝트 / 최근 auth_time 검증
        → DB에서 challenge 소유자·목적 확인 + 인증 이벤트 일회성 claim
        ← phone_verification_token (앱 계정·번호·목적에 묶인 저장 권한)
Flutter → 기존 profile/complete 또는 profile (앱 JWT + 저장 증명)
Express → User row lock·증명 소비·프로필·영수증 같은 DB transaction
```

- 서버 challenge는 SMS 발송 요청이 아닙니다. Firebase 발송은 client SDK가 직접 수행하므로 서버의 사전 challenge 제한만으로 Firebase SMS 비용/발송 횟수 전체를 통제할 수 없습니다.
- Firebase ID 토큰 자체는 ShiftMate 사용자/목적/challenge nonce를 포함하지 않습니다. 앱 JWT+서버 challenge와 검증된 번호를 대조하고 **서버 교환 시점에** 저장용 증명을 해당 사용자/번호/목적에 귀속시킵니다.
- Firebase UID는 보조 번호 인증 identity이며 users.user_id와 같다고 가정하지 않습니다. Firebase UID/이메일로 ShiftMate 계정을 찾거나 자동 로그인·연결하지 않습니다. 별도 custom token/linkWithCredential 기반 계정 통합은 이번 설계에 추가하지 않습니다.
- bearer 토큰의 비밀성을 전제로 하며 앱 ID 토큰을 로그/URL/analytics에 노출하지 않습니다. SDK ID 토큰을 nonce가 있는 앱 전용 attestation으로 설명하지 않습니다.

## 4. 정책

| 항목 | 요청 규칙 |
|---|---|
| 목적 | SIGNUP / PHONE_CHANGE, 서버의 프로필 완료 상태와 대조 |
| 기존 완료 회원 | 일괄 재인증하지 않는 이행안, phone_verified_at=null만으로 로그인/타 필드 저장 차단 금지 |
| 가입 | 미완료 사용자에게 SIGNUP 증명 필수, OAuth 번호도 동일 |
| 편집 | phone 생략/정규화 동일은 증명 불필요. 다른 번호는 PHONE_CHANGE 증명 필수 |
| 번호 삭제 | null/빈 phone 요청은 INVALID_PHONE. 생략은 기존 값 유지 |
| 번호 형식 | 앱/기존 API는 국내 숫자, Firebase는 E.164, DB/본인 응답은 기존 하이픈. 서버에서 서로 변환·대조 |
| 해외 지원 | 이번에 추가하지 않음. 현행 한국 휴대폰 정규식과 일치시키되 01X 실제 지원은 별도 검증 |
| OTP TTL/오답 횟수 | Firebase가 관리. 이전180초/5회 정책을 서버에서 강제한다고 약속하지 않음 |
| 앱 재발송 UI | 60초 제안. Firebase 실제 throttle/쿼터와 별개이며 SMS1회 보장 아님 |
| 서버 challenge | 600초 제안. 사용자별 최신 challenge만 활성, 새 세션은 기존 proof도 취소 |
| Firebase 최근 인증 | 검증 시 now-auth_time ≤300초, auth_time ≥ challenge.created_at(초 단위 비교, 최대5초 서버 시각 오차 허용) |
| 저장 증명 | 서버 검증 성공부터300초 제안. challenge/사용자/번호/목적/단일 소비에 binding |
| 인증 이벤트/영수증 | 24시간 보관 제안, 허용 freshness보다 길게 보관해 재사용 방지 |

Firebase SDK의 자동 읽기 timeout은 코드 만료가 아닙니다. Android는 SMS 수신 없이 instant verification이 성공할 수도 있으며 Firebase가 승인한 번호 인증 결과로 수용합니다. 매 시도 실문자1건 발송이라는 보장은 하지 않습니다.

## 5. API 요청/응답

prefix `/api/v1`, 기존 `{success,data,error,request_id}`, `Cache-Control: no-store` 사용. 신규 두 API는 **ShiftMate Bearer JWT 필수**입니다. Firebase ID token은 verify 요청 body의 별도 필드이며 앱 Authorization을 대체하지 않습니다.

변경 요청에는 `Idempotency-Key: <UUID>`를 받습니다. 같은 사용자/작업/key/정규화 본문은 동일 결과 복구, 같은 key의 다른 본문은409입니다. verify의 논리 fingerprint는 검증된 project/uid/auth_time/번호/challenge를 사용해 같은 Firebase 세션의 토큰 refresh 문자열 변화가 중복 교환이 되지 않게 합니다. 미변경 번호의 기존 타 필드 수정은 구형 key 없는 요청도 유지할 수 있으나 인증 필요한 저장은 key 필수입니다.

### 5.1 POST /auth/phone/challenges

```json
{
  "phone": "01012345678",
  "purpose": "SIGNUP"
}
```

```json
{
  "success": true,
  "data": {
    "challenge_id": "opaque-random-id",
    "phone": "01012345678",
    "phone_e164": "+821012345678",
    "purpose": "SIGNUP",
    "server_now": "2026-11-21T03:00:00Z",
    "expires_at": "2026-11-21T03:10:00Z"
  },
  "request_id": "request-id"
}
```

200, SMS 접수/도착 성공 필드는 반환하지 않습니다. 서버는 활성 계정·목적·번호·중복을 확인하고 사용자별 generation을 증가시켜 이전 challenge/proof를 취소합니다. 같은 key 재시도는 원래 challenge/기한을 반환하고 연장하지 않습니다. 클라이언트는 성공 후 Firebase SDK를 호출합니다. PHONE_CHANGE는 완료 계정에서 사용합니다.

### 5.2 POST /auth/phone/verify

```json
{
  "challenge_id": "opaque-random-id",
  "firebase_id_token": "firebase-id-token"
}
```

서버는 앱 JWT의 사용자가 소유한 최신 challenge를 조회하고 Firebase 검증 뒤 같은 challenge row lock/활성 상태를 다시 확인합니다. 클라이언트의 uid/번호/is_verified를 본문으로 받지 않습니다.

```json
{
  "success": true,
  "data": {
    "phone_verification_token": "opaque-shiftmate-proof",
    "phone": "01012345678",
    "purpose": "SIGNUP",
    "server_now": "2026-11-21T03:01:00Z",
    "expires_at": "2026-11-21T03:06:00Z"
  },
  "request_id": "request-id"
}
```

200. 같은 인증 이벤트를 다른 challenge·앱 계정·목적으로 다시 교환할 수 없게 합니다. 동일 key 재시도는 같은 증명/원래 기한만 복구하며 만료/취소된 증명을 새로 발급하지 않습니다. 이 단계는 User.phone/phone_verified_at/profile_completed_at을 수정하지 않습니다.

### 5.3 기존 프로필 저장 확장

```json
{
  "name": "홍길동",
  "timezone": "Asia/Seoul",
  "phone": "01012345678",
  "phone_verification_token": "opaque-shiftmate-proof"
}
```

- `/auth/profile/complete`: 미완료 계정+SIGNUP 증명 필수, phone/인증 시각/완료 시각을 같은 transaction으로 저장합니다. 완료 계정의 새로운 complete mutation은409 PROFILE_ALREADY_COMPLETED, 이미 성공한 key 재시도만 복구합니다.
- `/auth/profile`: 생략 phone은 유지, row lock 안에서 정규화 동일 phone은 인증 시각도 유지. 다른 phone은 PHONE_CHANGE proof가 필요합니다. 미완료 계정의 번호 저장은 완료 endpoint로 안내하며 일반 수정으로 완료 시각을 만들지 않습니다.
- JSON/multipart 양쪽 모두 `phone_verification_token` 검사. 이미지는 기존 profile_image part1개. 전화 증명 실패 시 다른 필드/사진도 함께 저장하지 않습니다.
- 이름/선택값/타임존/사진 validation·생략/삭제·고아 이미지 정리와 기존 전화 unique409는 유지합니다.
- GET profile·OAuth 본인 User·저장 응답에 nullable ISO8601 `phone_verified_at`을 추가하고 requires_profile_setup은 기존 완료 시각에서 계산합니다. 친구/검색/그룹 응답에 전화/인증 시각/증명을 추가하지 않습니다.

## 6. Firebase Admin 검증 요구

1. API 프로세스에서 환경별 허용 Firebase project ID로 named Admin app/Auth를 초기화합니다. 기존 FCM용 admin/ADC 패턴을 재사용하되 push worker flag에 종속시키지 않습니다. Stage/운영 프로젝트 교차 토큰은 거부합니다.
2. `getAuth(firebase_app).verifyIdToken(firebase_id_token, true)`로 서명·aud/iss/exp 및 폐기/비활성 계정 검사를 수행합니다. 단순 decode나 Firebase 사용자 조회의 phoneNumber만으로 승인하지 않습니다. checkRevoked에 필요한 Auth 조회 권한과 네트워크 실패를 인수합니다.
3. `firebase.sign_in_provider === 'phone'`, 비어 있지 않은 sub/uid, 유효한 phone_number, auth_time/freshness를 확인합니다. Google ID token·custom token·FCM token·anonymous/다른 provider 토큰은 거부합니다.
4. `phone_number`를 신뢰 가능한 서버 변환기로 정규화해 challenge.phone_e164와 일치시킵니다. `iat`가 새롭다는 이유로 최근 phone 인증이라고 판정하지 않습니다. SDK의 token refresh는 auth_time을 바꾸지 않습니다.
5. 인증 이벤트 식별자는 **project_id + uid + auth_time**의 keyed HMAC으로 만들고 전 사용자/challenge에 unique claim을 둡니다. raw ID token hash만으로 막으면 refresh된 토큰으로 우회할 수 있으므로 충분하지 않습니다. 동일 초의 같은 UID 인증은 보수적으로 하나로 취급하고 새 인증이 필요하다고 안내합니다.
6. 검증 중 새 challenge/탈퇴/번호 중복이 발생할 수 있으므로 DB transaction에서 최신 상태를 재검사합니다. Firebase 호출 중 DB transaction/row lock을 길게 유지하지 않습니다.
7. Firebase SDK/콘솔이 승인하는 테스트 번호도 유효한 토큰을 만들 수 있습니다. 운영 프로젝트에 테스트 번호·app verification 우회·Auth emulator를 설정하지 않습니다. 운영 API에 FIREBASE_AUTH_EMULATOR_HOST가 있으면 시작을 거부합니다. Emulator 토큰 검증은 격리된 테스트에서만 사용합니다.
8. ID token/refresh token 원문은 DB·Redis·로그에 저장하지 않습니다. 검증 실패 상세는 사용자에게 노출하지 않고 안정적인 앱 오류로 매핑합니다. 서명키/Auth 네트워크 장애는503이며 인증 우회로 통과시키지 않습니다.

공식 근거: [Admin ID token 검증](https://firebase.google.com/docs/auth/admin/verify-id-tokens), [DecodedIdToken auth_time/provider/번호](https://firebase.google.com/docs/reference/admin/node/firebase-admin.auth.decodedidtoken). Firebase ID 토큰 검증이 앱 업무 권한까지 부여하는 것은 아닙니다.

## 7. DB·일회용 증명·재시도

이 계획은 **앱 challenge/저장 권한을 PostgreSQL에서 관리**합니다. Redis OTP 의존성을 새로 추가하지 않습니다. 필요하다면 기존 Redis를 API rate limit 보조 저장소로 쓸 수 있지만 인증 상태/소비의 정본은 DB입니다.

### Migration 요청안

| 대상 | 필드/제약·역할 |
|---|---|
| users | 기존 phone/index 유지, nullable phone_verified_at timestamptz 추가. 기존 번호/완료 시각으로 인증 시각 backfill 금지 |
| 신규 phone_verifications | challenge_id(PK 랜덤), user_id(FK), purpose, 정규화 phone, generation, created_at/expires_at, cancelled_at, firebase_auth_event_hash(nullable unique), verified_at, proof_id(랜덤), proof_token_hash, proof_key_version, proof_expires_at, consumed_at, 요청 idempotency/fingerprint |
| 신규 profile_mutation_receipts | (user_id,idempotency_key) PK, operation, request_fingerprint, nullable verification_id(unique), created_at/retained_until. 저장 commit/응답 유실 복구 |

인증 이벤트 hash unique는 앱 계정별이 아니라 전체 이벤트에 적용합니다. active challenge 교체·verify 승인·소비는 User→challenge 순서 등 일관된 row lock 순서를 정해 직렬화합니다. 취소/만료 challenge와 소비 이벤트는24시간 보관 후 정리하되 허용 auth_time/freshness보다 짧게 지우지 않습니다. 생성 시각/generation 정렬과 만료 정리 index를 추가합니다. 신규 seed는 불필요하며 기존 phone/완료 회원 데이터를 지우지 않습니다.

challenge 생성과 verify 교환의 idempotency key/fingerprint는 각각 보관하고 `(user_id, operation, idempotency_key)` unique를 보장합니다. 인증 이벤트 HMAC 키 교체 시 아직 유효한 이벤트를 이전 key digest로도 조회해 같은 이벤트가 새 digest로 재승인되지 않게 합니다.

proof는 랜덤 proof_id와 서버 secret의 HMAC으로 재현 가능한 opaque token을 만들고 DB에는 digest/key version만 보관하는 방안을 제안합니다. 같은 key 응답 유실 복구 시 같은 token을 돌려줄 수 있어야 하며 원래 기한을 연장하지 않습니다. secret 교체 시 살아 있는 증명/응답 복구 기간의 이전 key를 지원합니다. UUID 단독/예측 가능한 문자열을 저장 권한으로 쓰지 않습니다. 다른 방식을 택하면 동등한 비밀성/복구를 ADR에 설명해 주세요.

### 저장 transaction

1. 앱 JWT·입력/사진 사전 검증 후 같은 key의 commit된 영수증을 조회합니다. 동일 fingerprint면 재저장/재업로드 없이 최신 본인 프로필을 응답합니다. 다른 본문은409입니다.
2. 없는 영수증이면 User와 challenge/proof를 잠그고 최신 DB 번호·목적·소유자·활성/만료/소비·중복을 검사합니다. 이미지를 준비하는 경로와 계정 잠금 순서를 통일합니다.
3. User.phone/phone_verified_at, 가입이면 profile_completed_at, proof.consumed_at, 영수증 INSERT를 **하나의 PostgreSQL transaction**에서 commit합니다.
4. DB 실패면 번호/인증 시각/완료/소비/영수증 모두 rollback, 살아 있는 proof로 같은 요청 재시도 가능. 이번 업로드는 기존 cleanup 경로로 정리합니다.
5. commit 후 응답 유실/프로세스 종료에도 영수증으로 복구합니다. 같은 proof를 다른 key에 쓰면 거부합니다. 동시 두 계정 같은 번호는 기존 unique index로 한 건만 성공합니다.
6. 소비된 proof를 포함한 새로운 mutation을 동일 번호라는 이유로 허용하지 않습니다. 기존 번호와 같고 proof를 **보내지 않은** 타 필드 부분 수정은 계속 허용합니다.

Firebase와 DB의 분산 transaction을 만들지 않습니다. Firebase SDK 로그인을 성공시켰다고 DB 번호가 바뀐 것으로 보지 않으며, Firebase signOut이나 계정 삭제를 DB commit 보장의 일부로 만들지 않습니다. Firebase phone-only 사용자는 서버의 가입 계정과 별개로 생길 수 있으므로 보관/정리 정책을 출시 전에 정합니다. signOut은 해당 Firebase 사용자를 삭제하지 않습니다. ShiftMate 탈퇴 시 Firebase UID를 근거 없이 동일 앱 사용자로 보고 삭제하지 말고 소유/다른 사용 영향·Google 보관 정책을 확인한 정리 절차를 별도 문서화합니다.

## 8. Express 구조·오류 계약

```text
Router → 기존 IP 제한/authMiddleware → express-validator
  → PhoneVerificationController → PhoneVerificationService
  → FirebasePhoneTokenVerifier + Sequelize repository
기존 profile Router → auth/multipart/validation → Controller
  → ProfileMutationService → ProfileService(증명 확인·소비+User transaction)
```

controller 직접 모델/SDK 호출을 피하고 내부 승인 객체는 HTTP body에서 받지 않습니다. 각 route/schema/JSON/multipart를 OpenAPI에 갱신합니다. 본문에 토큰이 있으므로 proxy/APM request body 수집도 끕니다.

| HTTP | code | 조건/앱 동작 |
|---|---|---|
| 400 | VALIDATION_ERROR / INVALID_PHONE | 필드·번호 변환 오류 |
| 400 | PHONE_VERIFICATION_PURPOSE_INVALID | 계정 완료 상태와 목적 불일치 |
| 400 | PHONE_FIREBASE_TOKEN_INVALID | 서명/프로젝트/provider/claim/번호 불일치·폐기/비활성 Firebase 사용자 포함, 재인증 |
| 410 | PHONE_FIREBASE_AUTH_TOO_OLD | auth_time이 오래됐거나 challenge 이전 인증, 새 phone 인증 |
| 410 | PHONE_CHALLENGE_EXPIRED | challenge 만료, 새 시도 |
| 409 | PHONE_FIREBASE_AUTH_REUSED | 같은 Firebase 인증 이벤트가 다른 challenge/사용자에 이미 claim됨 |
| 400 | PHONE_VERIFICATION_REQUIRED / PHONE_VERIFICATION_INVALID | proof 누락/위조/대상·소유자·목적·세대 불일치 |
| 410 | PHONE_VERIFICATION_EXPIRED | 앱 저장 proof 만료 |
| 409 | PHONE_VERIFICATION_USED | 소비된 proof의 새 mutation |
| 409 | PHONE_ALREADY_EXISTS | 발급/저장 시 다른 계정 중복·DB unique 경쟁 |
| 409 | IDEMPOTENCY_KEY_REUSED / PROFILE_ALREADY_COMPLETED | 같은 key 다른 본문 / 완료 endpoint 새 mutation |
| 400 | PROFILE_SETUP_REQUIRED | 미완료 가입의 일반 번호 수정·업무 API 우회 |
| 429 | PHONE_VERIFICATION_RATE_LIMITED | 서버 challenge/교환 한도, Retry-After/오류 retry_after_seconds |
| 401 | UNAUTHORIZED | ShiftMate JWT 실패에만 사용, 기존 앱 refresh |
| 409 | ACCOUNT_DELETION_IN_PROGRESS | 기존 탈퇴 처리 |
| 503 | PHONE_VERIFICATION_UNAVAILABLE | Firebase Admin/Auth/DB 의존성/설정 장애, 잠시 후 재시도 |

Firebase 자체 토큰 실패를401로 그대로 내려 앱 JWT refresh/logout을 유발하지 않습니다. Flutter SDK의 invalid-verification-code/session-expired/too-many-requests/quota-exceeded는 클라이언트에서 처리하며 Express가 코드6자리를 받아 직접 검증하지 않습니다. 기존 이미지/필드 오류 code/wrapper/request_id는 유지합니다.

## 9. 운영 설정·남용 방지·정보 처리

콘솔 결제/Phone·SMS 지역·API key·플랫폼 등록·서버 ADC/IAM 준비의 실행 체크리스트는 [FIREBASE_PHONE_AUTH_CONSOLE_SETUP.md](FIREBASE_PHONE_AUTH_CONSOLE_SETUP.md)를 따른다. 본 요청서의 env/API 구현과 실제 콘솔 설정 완료는 별도로 인수한다.

| 설정 | 요구사항 |
|---|---|
| 기존 FIREBASE_PROJECT_ID 또는 신규 PHONE_AUTH_FIREBASE_PROJECT_ID | Auth API에서 허용 project를 명시. Stage/운영 독립. push와 같다면 실제 일치 확인 |
| ADC / GOOGLE_APPLICATION_CREDENTIALS | API 프로세스에도 Admin Auth 검증/폐기 조회 권한 제공. 기존 push worker의 파일을 무조건 공유하지 않음 |
| PHONE_VERIFICATION_HMAC_KEY_FILE | 앱 proof/인증 이벤트·fingerprint용 secret 파일 제안, 키 용도 분리/파생·version/교체 정책 |
| PHONE_CHALLENGE_TTL_SECONDS | 제안600, 양의 정수 |
| PHONE_FIREBASE_AUTH_MAX_AGE_SECONDS | 제안300 |
| PHONE_FIREBASE_AUTH_CLOCK_SKEW_SECONDS | 제안5, 서버 시간 동기화 |
| PHONE_PROOF_TTL_SECONDS | 제안300 |
| PHONE_CHALLENGE_PER_USER_HOUR / PHONE_CHALLENGE_PER_IP_HOUR | 제안10/30, 서버 세션 생성 한도이며 실제 Firebase SMS 한도 아님 |
| PHONE_EXCHANGE_PER_USER_WINDOW / PHONE_EXCHANGE_PER_IP_WINDOW | 10분당 제안30/100, 다중 인스턴스 공통 카운터 |
| FIREBASE_AUTH_EMULATOR_HOST | local 격리 테스트만 허용, Stage/운영 설정 시 거부 |
| Firebase 콘솔 | Phone 제공자·Blaze/지역/할당량·남용 방어·사용량/예산 알림·운영 테스트 번호 제거 |

환경변수 이름/기본값은 서버 OpenAPI/구현 PR에서 확정하고 .env.example·시작 검증에 추가합니다. Stage/운영 secret은 문서·Flutter define에 넣지 않습니다. 클라이언트의 Firebase 공개 설정과 Admin credential을 구분합니다.

직접 SDK 발송을 서버 Redis 한도로 강제 통제할 수 있다고 기록하지 않습니다. Firebase의 앱 확인(Play Integrity/reCAPTCHA, iOS APNs/fallback)·SMS 지역 정책/쿼터·실사용 모니터링을 필수 인수하고, Firebase Authentication의 App Check 지원/강제 여부는 실제 SDK/프로젝트 지원을 확인한 뒤 추가합니다. 앱 서버 App Check만으로 Firebase SMS 발송 전체가 제한된다고 가정하지 않습니다. 예산 알림은 자동 비용 차단 보장이 아닙니다.

기존 authRateLimit은 프로세스별 Map이므로 서버 신규 endpoint에는 다중 인스턴스 공통 제한을 추가합니다. Redis 사용 시 캐시 flag off·장애 fallback 정책을 명시하고 제한 실패를 무제한 허용하지 않습니다. 메인 인증 상태/소비는 DB라서 캐시 재시작/정리에 영향을 받지 않아야 합니다. proxy 신뢰 범위를 확인하고 위조 X-Forwarded-For로 제한을 우회하지 못하게 합니다.

Google로 전화번호가 전송·저장되므로 사전 안내/적절한 동의·수탁/국외 처리·보관·탈퇴/미완료 세션·phone-only Firebase 계정 정리·스토어 공개사항을 담당 검토 후 기존 개인정보 문서에 반영합니다. 법적 근거/기간을 추정하지 않습니다. 로그는 안정된 code/request_id·집계 지표만 남기며 번호·코드·ID/refresh/proof token·UID 원문·credential/secret은 남기지 않습니다.

## 10. 기존 가입·업무 API 우회와 배포 호환

- OAuth 번호 writer는 SMS 검증 시각을 만들거나 검증된 기존 번호를 덮어쓰지 않습니다. 기존 사용자의 phone_verified_at을 임의 backfill하지 않습니다.
- `/auth/register`/소셜 로그인은 계정/JWT를 먼저 만들더라도 미완료 상태를 유지합니다. 미완료 사용자 업무 API 접근을 PROFILE_SETUP_REQUIRED로 차단하고 phone challenge/verify·GET/complete·refresh·logout/탈퇴 등 필요한 allowlist를 문서화합니다.
- Flutter의 authenticated 전환에서 시작하는 push 기기 등록을 미완료에게 허용할지 완료 후 재시작할지 합의합니다. 푸시 실패가 가입을 막지 않도록 양쪽 회귀를 확인합니다.
- 친구 정확 일치 검색·unique·전화 비노출 계약은 유지합니다. 검증된 번호만 검색/미완료 계정 검색 제외 정책은 별도 결정 사항입니다.
- 현재 앱은 proof를 보내지 않으므로 서버 준비 → Stage 연동 → Firebase 대응 앱 실제 제공 → 기존 호환 버전 정책으로 구버전 대응 → 서버 전면 강제 순서입니다. client 버전/flag만 믿어 인증을 면제하지 않습니다.

## 11. 서버 산출물·검증·롤백

예상 변경: auth routes/controllers·새 FirebasePhoneTokenVerifier/PhoneVerificationService·DB 세션/receipt model과 migration·profile mutation/service·User serializer·Admin 환경검증·분산 제한·cleanup·OpenAPI·테스트·문서. 신규 파일의 실제 역할/의존성/사용 예를 서버 PROJECT_CONTEXT/ADR/WORKLOG에 기록합니다.

- [ ] 서명/aud/iss/exp·폐기/비활성·다른 project/provider·phone mismatch·과거 auth_time·미래 시각 거부.
- [ ] getIdToken(true)로 바뀐 문자열도 같은 uid/auth_time 이벤트면 중복 교환 불가.
- [ ] 사용자/번호/목적/challenge generation 불일치·새 세션 경합·동일 이벤트 다른 계정 교환 거부.
- [ ] 가입 OAuth 번호도 인증 필요, 타 필드 부분 수정/동일 번호는 유지, phone null 삭제는 거부.
- [ ] JSON/multipart·이미지 실패/401 재전송·선택값 삭제·저장 응답 유실·동시번호 unique409.
- [ ] 같은 key 재시도/다른 본문409·proof 소비와 User/receipt 원자성·DB rollback/commit 직후 종료 복구.
- [ ] API 프로세스 ADC/프로젝트 설정 실패·Firebase 인증 서버/서명키 조회 장애·분산 rate limit 실패에서 우회 없음.
- [ ] 인증 이벤트/세션/receipt 만료 정리·탈퇴/미완료 계정과 Firebase phone-only 사용자 보관 정책.
- [ ] 기존 회원·소셜/FCM/근무 캐시/친구/그룹 회귀, 미완료 가입 업무 API allowlist.
- [ ] Stage iOS APNs/reCAPTCHA·Android 자동/수동/앱 확인, 실문자→증명→가입/변경 저장→재로그인.
- [ ] 운영 emulator/test 번호/검증 우회 없음, 데이터/비밀 로그 없음, 동의/정책/결제/쿼터 인수.

단위/HTTP 테스트는 fake Admin verifier, 격리 통합은 Auth Emulator+PostgreSQL로 수행하고 실제 서명/앱 확인/실문자는 Stage 실기기에서 따로 검증합니다. 현 서버 `npm run build`, `npm test`와 신규 통합 테스트 재현 명령/결과를 제공하며 운영 DB reset 명령은 사용하지 않습니다.

Breaking/Behavior change(계획): 가입/변경번호 저장 proof 필수·완료 계정의 새 complete mutation 제한·Google 번호 처리 추가. SENS/Redis OTP 명세의 send API·고정 OTP TTL/오답 정책은 폐기합니다.

장애 시 인증 검사 해제/SENS fallback으로 복구하지 않습니다. 가입/번호 변경은 재시도 가능한 오류로 막고 기존 데이터/조회/미변경 번호의 타 필드 수정은 보존합니다. Firebase 대응 서버/앱 수정판으로 복구합니다. additive migration 철회는 소비 코드/데이터 영향 확인 후 신규 컬럼/테이블만 대상으로 하며 기존 phone/index/완료 시각을 삭제하지 않습니다. 강제 이후 검증 데이터/영수증을 버리거나 인증 없는 앱으로 단순 롤백하지 않습니다.

서버 회신 요청: 확정 OpenAPI/시각/한도·Admin project/권한(비밀값 제외)·migration/rollback·실제 커밋·Firebase/DB 경계·이벤트 재사용 차단·기존 회원/업무 allowlist·phone-only Firebase 계정/개인정보 정리 정책·Stage 배포/자동·실문자 인수 결과·운영 앱/강제 전환 순서.

## 12. 문서 역할·공식 근거

- 역할: 서버 작업 이슈 첨부용 API·DB·운영·인수 계약.
- 의존성: 현행 Express/auth/FCM 코드, 모바일 계획, ADR-0088, 기존 가입/편집 계약.
- 사용 예: 서버 이슈 첨부 → OpenAPI/운영 미확정 항목 회신 → Stage 인수. 이번에 담당자 전송·구현/콘솔/배포를 수행하지 않았습니다.
- 추가 공식 자료: [Flutter Phone Auth](https://firebase.google.com/docs/auth/flutter/phone-auth), [Authentication 제한](https://firebase.google.com/docs/auth/limits), [Flutter Auth 시작/세션](https://firebase.google.com/docs/auth/flutter/start).

## 13. 사용자 제공 Flutter 예제 검토 후 확인 조건

사용자 제공 글의 비교 결과는 [모바일 계획 10절](PHONE_VERIFICATION_FLUTTER_PLAN.md#10-사용자-제공-예제-검토-2026-11-21)에 기록했다. 기존 서버 계약/ADR-0088은 유지하며 인수 시 다음을 명시적으로 확인한다.

- `01012345678`의 Firebase 번호는 `+821012345678`이며 국내0을 남긴 `+82010…`은 거부한다. claim의 phone_number와 challenge 번호도 같은 서버 변환 규칙으로 대조한다.
- Flutter가 credential 객체만 만들거나 Firebase 이메일 계정/Firestore 문서를 생성해도 ShiftMate 가입 완료 증거로 인정하지 않는다. 인증된 phone ID token 검증·증명 소비·프로필 transaction이 완료 조건이다.
- SDK 자동 읽기120초와 서버 challenge/proof 기한을 혼동하지 않는다. 테스트 번호/Emulator 결과는 실제 SMS 발송/전달 성공을 증명하지 않는다.

## 14. 서버 완료 후 앱 연동 검토 (2026-11-21)

대상은 인접 서버 clean HEAD `f1664b7`이다. 검토 목적은 기존 앱과의 계약/재시도 호환성 확인이며 코드·운영 DB/설정·배포는 변경하지 않았다. 이 절과 WORKLOG는 검토 기록이며 위의 미구현 시점 요청 문구와 구분한다. 이번 검토에 따른 새 ADR/제품 파일은 없다.

확인한 정상 계약: ShiftMate JWT, 신규 API2개, UUID Idempotency-Key, SIGNUP/PHONE_CHANGE, 국내/E.164 번호, 서버 상대 시각/TTL, User.phone_verified_at/requires_profile_setup, JSON/multipart 증명 저장, 최신 DB 번호 비교·증명 원자 소비·저장 영수증·미완료 업무 gate·가입 중 push/아바타 허용이 일치한다.

### P2: 만료된 challenge 요청 키가 앱에서 계속 재사용된다

재현 순서: 서버 challenge 생성 commit → 앱에서 응답 유실 처리 → 세션 만료(기본600초에 해당하는 DB 시각만 테스트에서 변경) → 같은 번호로 재시도. 서버 `src/services/phoneVerificationService.ts:93`의 기존 key 분기가 만료된 세션도200으로 반환한다. 앱 DTO는 server_now보다 과거인 expires_at을 거부해 PHONE_VERIFICATION_INVALID_RESPONSE로 변환한다. controller `phone_verification_controller.dart:198`/`_sendFailed`는 이전 _send_key를 유지하여 최초 요청과 재시도2회가 같은 키를 사용하고 만료 후 재시도는 같은 만료 세션으로 실패한다. 번호 수정/화면 재진입 전까지 해당 폼에서 인증을 재시작하지 못한다.

보완 요청: 서버는 기존 challenge의 만료/활성 상태를 검사해410 PHONE_CHALLENGE_EXPIRED 등 명시적 복구 불가 응답을 사용한다. 앱은 응답 유실/일시적 통신 오류에는 같은 키를 유지하되 만료/취소/잘못된 응답 등 확정 실패에는 키를 폐기하여 새 challenge를 만들 수 있어야 한다. 새 key로 이전 증명/세션을 부활시키지 않는다.

### P2: 취소된 challenge가200으로 반환되어 SDK 발송 경로에 진입한다

재현 순서: 첫 challenge 응답 유실 → 다른 요청이 새 challenge 생성/기존 세션 취소 → 첫 키 재시도. 기존 key 분기가 cancelled_at/purpose/consumed 상태 검사 전 반환하므로 앱 DTO는 유효한 기한/번호로 받아 requestCode를 호출한다. 그 뒤 verify는400 PHONE_VERIFICATION_INVALID로 거절한다. 실제 SMS를 발송하지 않았으며 fake SDK requestCode1회·실제 Express verify400을 확인했다. 해당 번호의 인증을 완료할 수 없는 발송 요청이 발생하는 경로다.

보완 요청: 서버는 기존 key 재응답 전에 취소/소비/가입 상태/목적을 확인한다. 최신 유효 세션만 성공으로 복구하고, 취소된 시도는 명시적 오류로 종료해 앱이 새 key로 다시 시작하도록 계약을 맞춘다. 이 분기는 최초 challenge 생성과 verify의 보호 조건을 우회한 성공 응답을 만들면 안 된다.

검증: 앱 기존 인증155 pass, 서버 strict TypeScript build·단위5 pass·일회용 PostgreSQL16 통합19 pass. 추가 실제 앱 HTTP/controller/DTO↔Express/DB4개는 정상 가입(이미지 포함)/편집2개와 위 결함 동작 재현2개다. 정상 저장은 같은 key 재시도·번호 생략 부분 수정·인증 시각 보존·이미지 재업로드 없음도 확인했다. Firebase SDK/Admin 외부 I/O·S3는 fake이며 실기기/실문자·실제 ADC/IAM·원격 배포/실제 서명 검증은 별도다. 임시 검증 코드/로그의 역할·의존성·명령과 컨테이너/credential 정리는 WORKLOG 최상단을 따른다.

영향/다음/롤백: 두 문제는 응답 유실과 세션 수명/동시 시도가 겹칠 때 발생한다. 검토 결과를 무조건 출시 가능 판단으로 사용하지 않는다. 앱/서버 보완 후 같은 재현을 성공/명시적 재시작 회귀로 바꾸고 Stage/실문자를 인수한다. 문서 롤백은 이번 검토 추가분만 제거하며 기존 구현/사용자 변경은 보존한다.

## 15. 앱 재시도 보완 완료 (2026-11-21, ADR-0090)

14절의 검토 뒤 사용자 요청으로 앱 controller를 수정했다. 신규 제품 파일/화면/API/native/서버 변경은 없다. 기존 PhoneVerificationController의 오류 처리에서 키 수명만 변경하고 기존 controller/widget 테스트를 확장했다. 사용 예는 같은 번호로 `인증번호 받기`를 다시 누르는 기존 흐름이다.

| challenge 실패 | 다음 사용자 발송 시도 |
|---|---|
| PHONE_CHALLENGE_EXPIRED / PHONE_VERIFICATION_INVALID_RESPONSE | 이전 키 폐기, 새 UUID로 새 challenge |
| HTTP4xx 확정 실패(408/425/429 제외), 예:400 PHONE_VERIFICATION_INVALID·409 IDEMPOTENCY_KEY_REUSED·410 만료 | 이전 키 폐기, 새 UUID로 새 challenge |
| 타임아웃/통신 등 상태 없는 불확실 실패·5xx·408/425/429 | 같은 요청 키로 복구, Retry-After/대기 유지 |

오류 직후 새 요청/SMS를 자동 실행하지 않는다. 기존 번호/입력을 유지하고 다음 사용자 동작으로 새 시도를 시작한다. 실패 상태 및 새 SDK 코드 수신만으로 저장/가입을 허용하지 않는다. 서버 verify 증명 성공이 계속 필수다. verify/최종 프로필 저장의 ID token/키·영수증 재시도는 변경하지 않았다.

기존 만료200도 DTO가 거부한 후 다음 시도는 새 키를 사용한다. 그러나 **취소된 challenge를200 유효 응답으로 반환하면 앱은 취소 상태를 알 수 없으므로 서버의14절 보완이 필요**하다. 서버는 종료 세션 재응답을4xx/410과 명시적 앱 code로 구분해야 하며, 종료 세션 오류를503 일시 장애로 반환하면 앱은 같은 키로 복구를 시도한다.

검증: 수정 전 controller 회귀5개 실패를 확인하고 debugger에서 만료 응답 거부 뒤 challenge=null·이전 키 유지 상태를 확인했다. 수정 후 기존/추가 controller9개·가입 화면2개를 포함한 인증166개 통과, 변경3파일 정적 분석 진단0. 같은 번호 유지/재인증·가입, 확정 실패 새 키, 통신/503/408/429의 같은 키·429 대기, 만료200 이후 새 키/SDK 진입을 확인했다. fake SDK/Dio 기반이며 이번 작업에서 서버/실문자/배포·플랫폼 빌드는 다시 수행하지 않았다. 영향/롤백은 이번 controller 분기·테스트/문서 추가분만 복원하며 기존 구현/사용자 변경을 보존한다.
