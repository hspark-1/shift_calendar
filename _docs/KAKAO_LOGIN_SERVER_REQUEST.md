# 카카오 SDK 토큰 로그인 서버 구현 요청서

## 1. 목적과 완료 조건

이 문서는 Flutter 프론트의 카카오 네이티브 SDK 토큰 로그인 계약을 기준으로 Express 서버의
운영 경로를 하나로 정리하기 위한 구현 요청서다.

서버 작업의 완료 조건은 다음과 같다.

- 운영 카카오 로그인 endpoint는 `POST /api/v1/auth/kakao/token` 하나만 제공한다.
- Stage/Production API URL을 카카오 Web Redirect URI로 등록하지 않는다.
- 서버는 받은 Access Token이 ShiftMate 카카오 앱에서 발급됐는지 `app_id`로 검증한다.
- 회원 탈퇴 worker는 같은 카카오 앱의 Admin Key로 연결 해제를 수행한다.
- 과거 Web authorization code 경로와 전용 환경변수·테스트 페이지·문서를 제거한다.
- OpenAPI, 단위·통합 테스트, 환경변수 검증, 배포·롤백 문서를 함께 반영한다.

## 2. 확인한 현재 구조

### Flutter 요청 흐름

```text
LoginPage
  → AuthNotifier.loginWithKakao()
  → AuthRepositoryImpl.loginWithKakao()
  → Kakao Flutter SDK loginWithKakaoTalk()/loginWithKakaoAccount()
  → Kakao OAuthToken.accessToken
  → POST /api/v1/auth/kakao/token
       { "access_token": "<Kakao Access Token>" }
  → ShiftMate access_token/refresh_token 저장
```

확인 파일:

- `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `lib/features/auth/data/repositories/auth_repository_impl.dart`
- `lib/core/constants/api_constants.dart`
- `lib/features/auth/presentation/providers/auth_provider.dart`

Flutter는 `POST /api/v1/auth/kakao`와 authorization code, `redirect_uri`를 사용하지 않는다.

### 플랫폼 식별자

- Android application ID: `com.hspark.shiftmate`
- iOS Bundle ID: `com.hspark.shiftmate`
- Native callback scheme: `kakao${KAKAO_NATIVE_APP_KEY}://oauth`
- Android는 사용하는 빌드 서명 key hash를 Kakao Native App Key의 앱 정보에 등록한다.
- 현재 저장소의 Android Release는 임시로 Debug signing config를 사용한다. 운영 keystore 전환 후
  실제 Release key hash를 추가 등록해야 한다.

### 현재 서버 구현

서버에는 두 경로가 공존한다.

```text
POST /api/v1/auth/kakao
  authorization code + redirect_uri
  → processKakaoLogin()
  → exchangeKakaoToken()

POST /api/v1/auth/kakao/token
  Kakao Access Token
  → getKakaoUserInfo()
```

`/auth/kakao`는 Flutter 앱에서는 사용하지 않지만 개발용
`public/test/kakao-login.html`과 `public/test/callback.html`이 사용한다. 테스트 정적 페이지는
development에서만 노출되지만 API route 자체는 현재 모든 환경에 등록된다.

## 3. 반영 완료된 프론트 작업

### SDK와 키 주입 계약

- `AppConstants`는 두 compile-time `String.fromEnvironment` 값을 보관하고 현재 빌드 모드에
  맞는 `kakao_native_app_key`를 반환한다.
- `.env`에는 Debug(Stage)와 Profile/Release(Production) 키를 각각 둔 뒤 Dart define으로
  전달한다.

```env
KAKAO_NATIVE_APP_KEY_STAGE=<Stage Native App Key>
KAKAO_NATIVE_APP_KEY=<Production Native App Key>
```

```bash
flutter run --dart-define-from-file=.env
```

- Dart define이 비어 있으면 `main.dart`가 모든 빌드 모드에서 `StateError`로 시작을 중단한다.
  Debug 전용 `assert`에는 의존하지 않는다.
- 네이티브 callback scheme은 Dart define과 별도 경로로 같은 키를 주입한다.

```properties
# android/secrets.properties
KAKAO_NATIVE_APP_KEY_STAGE=<Stage Native App Key>
KAKAO_NATIVE_APP_KEY=<Production Native App Key>
```

```text
// ios/Flutter/Secrets.xcconfig
KAKAO_NATIVE_APP_KEY_STAGE=<Stage Native App Key>
KAKAO_NATIVE_APP_KEY=<Production Native App Key>
```

- Debug는 Stage 키, Profile/Release는 Production 키를 선택한다. Android Gradle과 iOS
  xcconfig도 `--dart-define`이 네이티브 build setting을 자동으로 채우지 않는다는 사실에 맞춰
  환경별 callback URL Scheme을 별도로 선택한다.

### 추가한 프론트 회귀 테스트

- `AuthRemoteDataSource.loginWithKakaoToken()`이 정확히
  `POST /auth/kakao/token`을 호출하는지 검증한다.
- 요청 본문이 `{ "access_token": "kakao-access-token" }`인지 검증한다.
- 카카오 사용자와 ShiftMate JWT 응답 파싱을 검증한다.
- token endpoint 실패는 공용 `handleApiError()`로 변환해 구조화된 `error.code`,
  `error.message`, `request_id`를 `ApiException`에 보존한다.
- `KAKAO_TOKEN_APP_MISMATCH` 응답의 코드·사용자 메시지·request ID 회귀 테스트를 추가했다.
- Repository가 SDK Access Token을 datasource로 넘기고 서버 성공 후에만 ShiftMate JWT를
  저장하는지 검증한다.

프론트 변경 파일:

- `lib/main.dart`
- `lib/features/auth/data/datasources/auth_remote_datasource.dart`
- `android/app/build.gradle.kts`
- `test/features/auth/data/datasources/auth_remote_datasource_test.dart`
- `test/features/auth/data/repositories/auth_repository_impl_test.dart`
- `_docs/PROJECT_CONTEXT.md`
- `_docs/DECISIONS.md`의 ADR-0022
- `_docs/KAKAO_LOGIN_SERVER_REQUEST.md`
- `_docs/WORKLOG.md`

## 4. 서버 필수 변경

### 4.1 Access Token 발급 앱 검증

현재 `getKakaoUserInfo()`는 `GET https://kapi.kakao.com/v2/user/me`만 호출한다. 이 호출만으로는
서버가 기대하는 ShiftMate Kakao App ID를 코드에서 고정하지 않는다.

`/v2/user/me`보다 먼저 다음 API를 호출한다.

```http
GET https://kapi.kakao.com/v1/user/access_token_info
Authorization: Bearer <Kakao Access Token>
```

필수 검증:

1. HTTP 요청이 성공해야 한다.
2. 응답 `app_id`를 문자열 또는 안전한 정수로 정규화한다.
3. `app_id`가 서버의 `KAKAO_APP_ID`와 정확히 같아야 한다.
4. `access_token_info.id`와 `/v2/user/me.id`가 정확히 같아야 한다.
5. 하나라도 다르면 사용자 조회·이메일 연결·JWT 발급 전에 거부한다.

권장 오류 계약:

```json
{
  "success": false,
  "error": {
    "code": "KAKAO_TOKEN_APP_MISMATCH",
    "message": "유효하지 않은 카카오 로그인 정보입니다."
  },
  "request_id": "..."
}
```

- 외부 응답 원문, Access Token, 이메일, Kakao user ID는 로그에 남기지 않는다.
- 만료·위조 토큰은 인증 실패로 분류한다.
- timeout, `429`, Kakao `5xx`는 내부 장애와 구분하되 민감정보 없이 구조화 로그를 남긴다.
- 기존 controller는 대부분의 `Error`를 HTTP 400으로 평탄화하므로, 공용 error middleware와
  `ApiError` 계약에 맞춰 상태·코드를 보존한다.

### 4.2 환경변수

Stage와 Production은 서로 다른 카카오 앱을 사용한다. 각 배포 환경에는 해당 앱의 값 하나만
`KAKAO_APP_ID`라는 동일한 변수 이름으로 주입한다.

API 프로세스:

```env
# Stage API
KAKAO_APP_ID=<Stage 숫자형 Kakao App ID>

# Production API
KAKAO_APP_ID=<Production 숫자형 Kakao App ID>
```

회원 탈퇴 worker:

```env
KAKAO_ADMIN_KEY=<현재 배포 환경 Kakao 앱의 Admin Key>
```

규칙:

- `KAKAO_APP_ID`는 `/auth/kakao/token`을 제공하는 API 프로세스의 필수값으로 검증한다.
- `KAKAO_ADMIN_KEY`는 `ACCOUNT_DELETION_WORKER_ENABLED=true`인 worker에서만 필수로 검증한다.
- Admin Key는 Flutter, Git, `feature-flags.env`, 응답, 로그에 포함하지 않는다.
- Kakao Admin Key에 허용 IP를 설정했다면 Stage/Production 탈퇴 worker의 egress IP를 등록한다.
- Native App Key, Admin Key, Kakao App ID는 모두 같은 Kakao 앱에 속해야 한다.

### 4.3 Web authorization code 경로 제거

다른 실제 클라이언트가 없다는 것을 접근 로그와 담당자 확인으로 확정한 뒤 다음을 제거한다.

- `src/routes/authRoutes.ts`
  - `POST /kakao`
  - `kakaoLogin` import
- `src/controllers/authController.ts`
  - `kakaoLogin()`
  - `processKakaoLogin` import
- `src/services/kakaoService.ts`
  - `KakaoTokenResponse`
  - `exchangeKakaoToken()`
  - `processKakaoLogin()`
  - SDK token 경로의 `getKakaoUserInfo()`는 유지하고 App ID 검증을 결합한다.
- `public/test/kakao-login.html`
- `public/test/callback.html`
  - Naver가 함께 사용하므로 파일 전체 삭제가 아니라 Kakao 분기만 제거할지 먼저 확인한다.
- `src/index.ts`
  - Kakao Web 로그인 테스트 URL 로그

Breaking change:

- `/api/v1/auth/kakao`를 호출하던 외부 클라이언트가 있다면 더 이상 로그인할 수 없다.
- 제거 배포 전에 최근 접근 로그에서 endpoint 호출 주체가 개발용 페이지뿐인지 확인한다.
- 불확실하면 첫 배포에서는 production/Stage에서 `410 Gone`과 구조화 로그로 관찰한 뒤 완전
  제거할 수 있지만, 장기 feature flag로 남기지는 않는다.

### 4.4 레거시 환경변수 제거

Web authorization code 경로 제거와 함께 다음을 삭제한다.

```env
KAKAO_CLIENT_ID
KAKAO_CLIENT_SECRET
KAKAO_REDIRECT_URI
```

확인 사항:

- `KAKAO_REDIRECT_URI`는 현재 TypeScript에서도 읽지 않고 문서와 `.env.example`에만 남아 있다.
- `KAKAO_CLIENT_ID`와 `KAKAO_CLIENT_SECRET`은 `exchangeKakaoToken()` 제거 후 사용처가 없다.
- `qs` 패키지는 Naver 서비스 등 다른 사용처를 검색한 뒤 사용처가 없을 때만 제거한다.

### 4.5 중복 provisioning 정리

현재 `kakaoLogin()`과 `kakaoLoginWithToken()`에는 사용자 조회·이메일 연결·기본 템플릿 생성·JWT
발급 코드가 중복되어 있다. Web controller를 제거한 뒤 SDK token controller의 외부 응답은
유지하되 다음 경계를 분리하는 것을 권장한다.

```text
validateKakaoAccessToken()
  → getKakaoUserInfo()
  → provisionKakaoUser()
  → generateTokens()
```

이번 작업에서 기존 이메일 자동 연결 정책 자체를 임의로 변경하지 않는다. 단, App ID 검증은
이메일 조회와 `kakao_id` 저장보다 반드시 먼저 실행한다.

## 5. API 계약

요청:

```http
POST /api/v1/auth/kakao/token
Content-Type: application/json
```

```json
{
  "access_token": "<Kakao Access Token>"
}
```

성공 응답은 현재 Flutter `AuthResponse.fromJson()` 계약을 유지한다.

```json
{
  "success": true,
  "message": "로그인 성공",
  "data": {
    "user": {
      "user_id": "uuid",
      "email": "user@example.com",
      "name": "사용자",
      "kakao_id": "123456789"
    },
    "access_token": "<ShiftMate JWT>",
    "refresh_token": "<ShiftMate Refresh Token>",
    "expires_at": 1786924800000,
    "is_new_user": false
  },
  "request_id": "..."
}
```

`expires_at`은 현재 서버 공통 계약인 Unix epoch milliseconds 또는 기존 Flutter가 수용하는 ISO
8601 중 서버 정본에 맞춘다. 다른 provider와 응답 형식을 통일하되 이번 작업에서 임의로 형식을
바꾸지 않는다.

## 6. 서버 테스트 요구사항

### Service 단위 테스트

- 올바른 `KAKAO_APP_ID`의 token info 성공
- 다른 `app_id`이면 `KAKAO_TOKEN_APP_MISMATCH`
- token info `id`와 user info `id` 불일치 거부
- 만료·유효하지 않은 token 거부
- token info timeout, `429`, `5xx` 오류 매핑
- email 누락 시 기존 명시 오류 유지
- 로그에 Access Token·이메일·외부 응답 원문이 없는지 검증

### Route/controller 테스트

- `POST /auth/kakao/token` validation과 rate limit 유지
- 성공 시 Kakao user와 ShiftMate JWT 응답
- App ID 검증 성공 전에 `User.findOne`, `save`, `create`, `generateTokens`가 호출되지 않음
- `/auth/kakao`가 제거됐거나 확정된 제거 단계의 응답을 반환함

### 회원 탈퇴 테스트

- Kakao 계정이면 `Authorization: KakaoAK <Admin Key>`로 unlink
- `target_id_type=user_id`, 저장된 `kakao_id` 사용
- 응답 ID 불일치 거부
- 공식 already-unlinked 오류는 멱등 성공
- worker 활성화 시 Admin Key 누락 시작 실패, 비활성화 시 API 프로세스와 무관

### 통합·회귀 테스트

- 신규 Kakao 사용자 생성 및 기본 템플릿 생성
- 기존 `kakao_id` 사용자 로그인
- 기존 이메일 연결 회귀는 현재 정책대로 유지하되 App ID 검증 이후에만 실행
- Refresh/logout/profile과 카카오 외 provider 회귀
- Stage iOS/Android 실기기 로그인 후 `/auth/kakao/token`만 호출되는지 확인

## 7. 문서 변경 대상

서버 저장소에서 다음을 갱신한다.

- `_docs/PROJECT_CONTEXT.md`
  - 카카오 인증을 SDK Access Token 단일 흐름으로 변경
  - 환경변수 표와 로컬 실행 예시 갱신
- `_docs/DECISIONS.md`
  - ADR-0007을 직접 삭제하지 않고 상태를 Superseded로 표시
  - SDK 전용 경로와 App ID 검증 ADR 추가
- `_docs/OAUTH_API_GUIDE.md`
  - Web authorization code/Redirect URI 절 제거
  - `/kakao/token`, App ID 검증, 오류 계약만 유지
- `_docs/DEPLOYMENT_GUIDE.md`
  - `KAKAO_APP_ID`, worker 전용 `KAKAO_ADMIN_KEY`와 플랫폼 등록 절차 추가
- `.env.example`
  - Client ID/Secret/Redirect URI 제거, App ID/Admin Key 역할 분리
- `src/openapi.ts` 또는 신규 Kakao OpenAPI JSON
  - `/auth/kakao/token` 요청·응답·오류를 실제 Swagger에 포함
- `_docs/WORKLOG.md`
  - 목적/변경/영향/파일/테스트/롤백/다음 기록

현재 서버 Swagger 조립에는 Kakao endpoint가 포함되지 않으므로 문서 Markdown만 고치는 것으로
완료하지 않는다.

## 8. 배포 순서

1. Kakao Developers에서 동일 앱의 Native App Key, 숫자형 App ID, Admin Key를 확인한다.
2. Native App Key에 Android package/key hash와 iOS Bundle ID를 확인한다.
3. Stage API에 `KAKAO_APP_ID`, 탈퇴 worker에 `KAKAO_ADMIN_KEY`를 주입한다.
4. App ID 검증과 `/auth/kakao/token` 테스트를 배포한다.
5. Stage iOS/Android 실기기 로그인과 카카오 계정 탈퇴 E2E를 통과한다.
6. `/auth/kakao` 접근 로그에 실제 소비자가 없음을 확인하고 레거시 경로를 제거한다.
7. Production API/worker에 같은 앱의 값을 주입하고 서버를 먼저 배포한다.
8. Production signed 앱으로 로그인·refresh·logout·탈퇴 smoke test를 수행한다.

## 9. 롤백

- App ID 검증 장애 시 코드를 제거하지 말고 upstream 응답·환경변수 형식·숫자 정규화 문제를 먼저
  확인한다. 다른 앱 토큰 허용으로 되돌리는 것은 보안 롤백으로 허용하지 않는다.
- 레거시 `/auth/kakao` 제거로 확인된 소비자가 중단되면 직전 서버 commit을 일시 재배포하고
  소비자와 종료 일정을 확정한다. Flutter는 `/auth/kakao/token`을 계속 사용한다.
- Admin Key unlink 장애는 worker retry 상태를 유지하고 API 로그인 경로와 분리한다. 사용자 DB
  purge 전에 provider task가 완료돼야 하는 기존 순서를 바꾸지 않는다.

## 10. 서버 완료 보고에 포함할 증거

- 변경 commit과 변경 파일 목록
- `KAKAO_APP_ID` 검증 성공·불일치 테스트 결과
- 전체 서버 build/test 결과
- `/auth/kakao` 제거 또는 단계적 종료 결과
- Stage 실기기에서 `/auth/kakao/token`만 호출된 요청 로그
- Stage 탈퇴 worker unlink 결과와 민감정보 비노출 확인
- OpenAPI endpoint 확인 링크
- Production 배포·롤백 명령 및 적용 환경변수 이름 목록

실제 키 값, Access Token, Admin Key, 사용자 이메일·Kakao ID는 완료 보고에 포함하지 않는다.

## 11. 공식 참고 문서

- Flutter 로그인 및 네이티브 앱/웹 방식 구분:
  `https://developers.kakao.com/docs/ko/kakaologin/flutter`
- Flutter SDK 초기화와 Native App Key:
  `https://developers.kakao.com/docs/ko/flutter/getting-started`
- Access Token 정보 조회의 `app_id` 및 회원 연결 해제 API:
  `https://developers.kakao.com/docs/ko/kakaologin/rest-api`
- Native App Key별 Android package/key hash와 iOS Bundle ID 설정:
  `https://developers.kakao.com/docs/ko/app-setting/app`
