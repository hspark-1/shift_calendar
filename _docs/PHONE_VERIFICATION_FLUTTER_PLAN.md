# Firebase Phone Auth 휴대폰 인증 Flutter 작업 계획

작성일/개정일: 2026-11-21 · 상태: **모바일 구현·모의 검증 완료 / 서버·실기기 인수 전** · ADR-0088·0089

후속 서버 완료 검토: 로컬 서버 f1664b7의 구현과 앱 실제 HTTP↔Express/PostgreSQL 정상 연동을 확인했다. challenge 응답 유실 후 만료/취소 재시도2건의 보완이 필요하며 [서버 요청서14절](PHONE_VERIFICATION_SERVER_HANDOFF.md#14-서버-완료-후-앱-연동-검토-2026-11-21)·WORKLOG에 재현/검증을 기록했다. 서버 기록상 push/배포·Stage 실문자는 미수행이다. 아래 계획 당시/모바일 구현 당시의 선행 상태는 이력으로 읽는다.

후속 앱 보완 완료(ADR-0090): 확정 실패 뒤 challenge 키를 폐기하고 같은 번호로 새 인증을 시작하도록 수정했다. 타임아웃/통신/5xx·408/425/429는 기존 키와 대기를 보존한다. 기존 만료200 DTO 오류 반복과 명시적410/400·409 복구, 가입 화면 만료/취소 후 재인증을 포함해 인증166개 통과·변경3파일 분석 진단0이다. 코드/테스트 역할은11절과 같고 새 파일/route/native 변경은 없다. 서버도 취소된 세션을200으로 반환하지 않아야 하며 서버 보완·배포/실문자 검증은 이번 앱 작업 결과에 포함하지 않는다. 자세한 계약은 서버 요청서15절을 따른다.

이 문서는 이전 SENS + Redis OTP 계획을 대체한다. SMS 발송·코드 검증은 Firebase Phone Auth, 기존 계정 인증/프로필 저장은 ShiftMate JWT와 Express/PostgreSQL이 담당한다. 서버 계약은 [PHONE_VERIFICATION_SERVER_HANDOFF.md](PHONE_VERIFICATION_SERVER_HANDOFF.md)를 따른다.

## 1. 유지할 요구사항

- 가입: 소셜 로그인에서 받아온 번호라도 휴대폰 인증 후에만 가입 프로필을 완료한다.
- 개인정보 수정: 화면을 열 때 서버에서 조회한 전화번호와 입력 번호가 다르면 새 번호를 인증해야 저장한다. 이름·사진·직종·소속만 변경하면 인증이 필요 없다.
- 번호 비교는 정규화 후 수행한다. 하이픈만 다른 값은 같은 번호다. 최초 번호로 되돌리면 변경 번호 인증 요건을 해제한다.
- 인증 후 다른 번호로 바꾸면 인증 상태/증명을 폐기한다. 다른 번호에서 돌아와도 과거 증명을 복원하지 않는다.
- 서버는 화면의 비교 결과를 신뢰하지 않고 저장 직전 DB 번호와 인증 증명을 확인한다.
- 기존 완료 회원의 일괄 재인증은 이번 이행안에 포함하지 않는다. 미변경 레거시 번호/번호 없는 회원의 타 필드 수정은 유지한다. 이행안은 서버 인수 전에 확정한다.

이 문서의1~10절은 최초 계획/검토 기준이며, 후속 모바일 구현 결과는11절을 따른다. 현재 앱/lock/native 설정은 구현했고 서버·Firebase 콘솔/결제·개인정보 공개 문서·환경변수·DB·배포는 이번 앱 작업에서 변경하지 않았다.

## 2. 계획 당시 확인한 코드와 새 책임

| 파일 | 확인한 사실 / 계획 |
|---|---|
| `pubspec.yaml` | `firebase_core: 4.12.1`, `firebase_messaging: 16.4.3` 사용, `firebase_auth` 없음. 기존 Flutter/Dart/native SDK와 호환되는 버전을 solver·플랫폼 빌드로 검증 후 추가/고정 |
| `lib/core/push/firebase_environment_options.dart` | Debug Stage / Profile·Release 운영 FirebaseOptions를 define으로 주입. Phone Auth도 같은 환경 프로젝트 사용 |
| `lib/core/push/push_coordinator.dart` | 현재 `initializePushFirebase()` 실패는 푸시만 비활성화하고 앱 진행. 인증 초기화 실패는 인증 필요한 저장을 막아야 하므로 별도 준비 상태 필요 |
| `lib/main.dart` | ShiftMate authProvider와 서버 `requires_profile_setup`으로 화면 분기. Firebase Auth 상태로 대체하지 않음 |
| `lib/features/auth/presentation/pages/settings_page.dart` | 캐시 User를 `ProfileSetupPage.edit`에 전달. 편집 시작 시 최신 GET을 추가해야 함 |
| `lib/features/auth/presentation/pages/profile_setup_page.dart` | 공통 가입/편집 폼·전화 숫자 비교·부분 저장·이미지 선택. 인증 UI/SDK 없음 |
| `lib/features/auth/presentation/providers/auth_provider.dart` | 저장 bool·문자열 오류, 가입 성공 시 완료 분기 false. 증명 인자·구조화 오류·서버 완료 boolean 확인 보완 |
| `lib/features/auth/data/repositories/auth_repository_impl.dart`, `data/datasources/auth_remote_datasource.dart` | 기존 `/auth/profile/complete`·`/auth/profile` JSON/multipart, 새 challenge/verify 계약 연결 |
| `lib/features/auth/domain/entities/user.dart` | `phone` 존재, `phone_verified_at` 없음. 본인 응답의 nullable 인증 시각 추가 |
| `lib/core/network/api_client.dart` | ShiftMate JWT/401 refresh·multipart clone. Firebase ID 토큰을 Authorization에 넣지 않음 |
| `ios/Runner/Info.plist`, `Runner.entitlements`, `AppDelegate.swift` | APNs entitlement·remote-notification·FlutterSceneDelegate 존재. Firebase Phone Auth 콜백/콘솔 설정이 완료됐다는 증거는 아님 |
| `android/app/build.gradle.kts` | 패키지 `com.hspark.shiftmate`, minSdk24, 현재 release도 debug signing 설정. 실제 배포 서명 지문을 따로 인수 |

기존 서버에는 FCM용 `firebase-admin`/ADC 초기화가 있지만 Auth ID 토큰 검증은 별도 구현이 필요하다. 기존 [가입](PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md)·[편집](PROFILE_EDIT_SERVER_HANDOFF.md) 문서의 필드/사진/선택값 계약은 유지하고 인증 관련 후속 계약만 바꾼다.

## 3. 새 전체 흐름

```text
기존 소셜 로그인 → ShiftMate JWT → 가입 프로필 또는 개인정보 편집
  → POST /auth/phone/challenges (ShiftMate JWT, 대상 번호, SIGNUP/PHONE_CHANGE)
  → FirebaseAuth.verifyPhoneNumber(E.164 번호)
  → 수동 코드 입력 또는 Android verificationCompleted
  → PhoneAuthCredential → signInWithCredential
  → Firebase ID token
  → POST /auth/phone/verify (ShiftMate JWT, challenge_id, firebase_id_token)
  → 서버 Firebase Admin 검증 + 계정/번호/목적 binding
  → phone_verification_token (ShiftMate 일회용 저장 증명)
  → 기존 profile/complete 또는 profile에 증명 포함 저장
  → PostgreSQL commit된 User → authProvider → 기존 화면 전환
```

`/auth/phone/challenges`는 앱 서버 인증 세션 생성이며 **SMS 발송 API가 아니다**. 이전 `/auth/phone/send`, Redis OTP 생성/검증·SENS SDK/키는 구현하지 않는다. 기존 Redis 근무 캐시 기능은 유지한다.

Firebase Phone Auth의 [공식 Flutter 흐름](https://firebase.google.com/docs/auth/flutter/phone-auth)을 사용한다. SDK의 Firebase 로그인은 번호 확인용 보조 세션이다. ShiftMate 계정의 가입/로그인/소셜 연결을 Firebase로 이전하거나 Firebase UID로 앱 계정을 자동 선택하지 않는다.

## 4. 플랫폼·프로젝트 준비 작업

Firebase/Google Cloud·Apple/Android의 코드 외 작업 순서·담당·설정 경로·완료 증거는 [FIREBASE_PHONE_AUTH_CONSOLE_SETUP.md](FIREBASE_PHONE_AUTH_CONSOLE_SETUP.md)를 따른다. 콘솔에서 바로 할 수 있는 준비와 SDK 구현 후 인수를 구분한다.

| 영역 | 구현 전 확인/작업 |
|---|---|
| Firebase 콘솔 | Stage/운영 각각 Phone 제공자 활성화, 한국 SMS 지역 정책, 결제·할당량·사용량 알림·테스트 번호 분리 |
| Android | 실제 Debug/배포·Google Play App Signing 인증서 SHA-1/SHA-256 등록, Play Integrity 앱 확인과 reCAPTCHA fallback 인수 |
| iOS | 환경별 bundle/app 설정·APNs 키/권한·background mode 확인, silent APNs 및 reCAPTCHA fallback용 Firebase Encoded App ID URL scheme/API key 설정 검증 |
| iOS 콜백 | 기존 FlutterSceneDelegate/카카오·네이버·Google 콜백을 보존. method swizzling 기본 동작을 확인하고 비활성화 시 공식 문서에 따라 APNs/URL 전달 구현 |
| 초기화 | Firebase core 초기화를 푸시 전용 함수와 분리해 공통 initializer로 관리. Phone Auth 준비 실패를 푸시 비활성 boolean으로 숨기지 않음 |
| 의존성 | `firebase_auth` 호환 버전 추가 후 pub/Pod lock·최소 OS·Android 빌드 검증. 호환성 증거 없이 SDK 전체 업그레이드하지 않음 |
| 정보 안내 | 번호가 Google로 전송·저장됨에 대한 안내/적절한 동의, 개인정보처리방침·스토어 공개 항목을 출시 전에 검토/반영 |

공식 근거: [Android 앱 확인/서명](https://firebase.google.com/docs/auth/android/phone-auth), [iOS APNs/reCAPTCHA](https://firebase.google.com/docs/auth/ios/phone-auth), [현재 Firebase Auth 제한](https://firebase.google.com/docs/auth/limits). 실제 SMS는 현재 공식 문서상 Blaze 결제가 필요하다. 구체 단가/쿼터는 출시 시 콘솔과 공식 요금으로 재확인하며 예산 알림을 강제 비용 상한으로 설명하지 않는다.

iOS 전화 인증은 사용자에게 알림 표시 권한을 허용하도록 강제하는 흐름으로 만들지 않는다. silent APNs와 fallback을 실제 알림/백그라운드 설정 조합에서 확인한다. 기존 푸시 알림 권한 요청과 전화번호 인증을 분리한다.

## 5. 번호·SDK·세션 규칙

### 번호 표현

- 화면: 기존 한국 번호 formatter, 예 `010-1234-5678`.
- 기존 서버 요청: 숫자 문자열 `01012345678`, DB/본인 응답은 기존 하이픈 형식.
- Firebase SDK: 국가코드 E.164 `+821012345678`(국내 앞자리0 제거). 서버가 challenge에 반환한 `phone_e164`를 SDK에 사용한다.
- 1차 국내 휴대폰 범위는 현행 Flutter 정규식과 맞추되 해외 지원은 추가하지 않는다. 레거시 01X의 실제 발송 가능성은 별도 Stage 검증이며 형식 통과만으로 지원을 보장하지 않는다.

### SDK 콜백과 인증 완료 기준

| 콜백/단계 | 처리 |
|---|---|
| `codeSent` | Firebase `verificationId`와 선택 resend token을 메모리에 보관하고 코드 입력 표시. 서버 challenge_id와 다른 식별자 |
| `verificationCompleted` | Android 자동/즉시 인증 credential을 수동 입력과 같은 단일 처리 함수에 전달. 서버 증명 교환까지 성공해야 UI 인증 완료 |
| `verificationFailed` | FirebaseAuthException code를 앱의 안전한 오류로 변환. 원문 SDK 문자열/토큰/번호 비노출 |
| `codeAutoRetrievalTimeout` | Android 자동 읽기 대기 종료. **인증번호 만료가 아니므로 수동 입력을 계속 허용** |
| 수동 입력 | `PhoneAuthProvider.credential(verificationId, smsCode)` 후 `signInWithCredential` |
| SDK 로그인 성공 | 반환된 User의 ID token을 받아 서버 verify에 전달. 기존 Firebase `currentUser`만 보고 성공 처리 금지 |
| 서버 verify 성공 | 현재 번호/목적/generation과 맞는 증명/기한을 보관. 실제 프로필 값은 저장 성공 전까지 바꾸지 않음 |

자동·수동 완료가 동시에 와도 SDK 로그인/서버 교환을 한 번만 실행한다. SDK `getIdToken(true)`는 인증 시각을 새로 만드는 동작이 아니므로 기존 세션 토큰 갱신으로 새 번호 인증을 대체하지 않는다. 서버가 확인할 `auth_time`은 실제 phone 인증 세션에 속해야 한다.

Firebase Auth native SDK는 로그인 상태를 기기에 유지할 수 있다. 따라서 인증 시작 전 남은 보조 세션을 정리하고, 서버 증명 교환 성공/복구 불가 실패·화면 종료·ShiftMate 로그아웃/탈퇴·다른 계정 전환에서 Firebase `signOut()`을 처리한다. 일시적 서버 통신 실패는 같은 ID token/key로 재시도할 때까지 해당 화면 세션만 유지한다. 재실행 시 남은 currentUser를 인증 증거로 재사용하지 않는다. 이 세션 정리를 ShiftMate JWT 삭제·FCM token 삭제·Firebase 사용자 삭제와 혼동하지 않는다.

SDK 작업은 취소 후 콜백이 올 수 있다. generation·사용자·번호·challenge를 대조해 늦은 콜백을 버리고, 진행 중 SDK 로그인 완료 후 해당 세션만 정리한다. 오래된 화면의 signOut이 새 화면 세션을 끊지 않도록 서비스 수준으로 작업/정리를 직렬화한다.

## 6. 화면·상태·저장 UX

편집은 최신 `GET /auth/profile` 완료 후 입력/`initial_phone`을 한 번 초기화한다. 조회 중 로딩, 실패 시 재시도/뒤로가기와 저장 차단. 편집 중 서버 재조회로 draft를 덮어쓰지 않는다. 기존 Cupertino route를 유지하고 별도 전화 로그인 화면은 만들지 않는다.

```text
requires_phone_verification = !is_editing || normalized_phone != initial_phone
has_valid_proof = token 존재 && verified_phone == normalized_phone
                  && purpose 일치 && 서버 증명 미만료
can_save = 초기 조회 완료 && 필수값 유효 && !진행 중
           && (!is_editing || has_changes)
           && (!requires_phone_verification || has_valid_proof)
```

- 가입 초기/번호 변경 시 `인증번호 받기` → 코드 입력/`인증하기` → `인증 완료`. 인증 완료는 SDK 성공이 아닌 서버 증명 성공 기준이다.
- 화면 controller/포커스/스크롤/최초값/사진은 UI state, 인증 controller의 SDK 콜백·verificationId·challenge·기한·임시 증명은 화면별 작업 state, 서버 저장 User는 기존 authProvider domain state로 분리한다.
- 인증 controller는 화면 세션별 Riverpod autoDispose. dispose 시 타이머/요청/리스너 정리, 늦은 이벤트 무시. 번호 변경은 입력 코드·현재 증명·challenge·verificationId·resend token을 초기화한다.
- 재발송 UI는60초 대기 제안이며 실제 Firebase throttle을 우선한다. Android `forceResendingToken`은 같은 번호의 SDK callback 값이 있을 때 사용, iOS는 null이므로 재요청을 따로 처리한다. 새 challenge 성공 후 새 SDK 시도에 연결하고 이전 증명을 재사용하지 않는다.
- 앱 서버는 Firebase의 예전 verificationId/code를 취소할 수 없다. 최신 앱 challenge만 승인하고, 사용자가 번호/목적을 바꾸면 이전 완료 콜백을 버린다. Firebase 인증 결과에는 앱 challenge nonce가 포함되지 않는다는 제한은 서버 요청서에 명시한다.
- Firebase 코드 TTL/오답5회/발송당 한도를 앱이 설정할 수 있다고 표시하지 않는다. SDK `timeout`은 자동 읽기 대기 시간이다. 서버 challenge/증명 기한과 재발송 UI 대기는 별도다.
- 서버 challenge600초·저장 증명300초·phone auth freshness300초를 초기 제안으로 두고 서버와 확정한다. 기한은 server_now와 수신 후 단조 경과시간으로 계산, background 복귀 시 재계산한다.
- 숫자6자리 한 입력란·선행0·붙여넣기·oneTimeCode 자동완성, 명시적인 확인 버튼 사용. 자동 인증으로도 가입/프로필 저장을 자동 실행하지 않는다.
- AppTheme·기본 정보 카드·최대폭480·기존52px 주요 버튼/최소44px 터치 유지. 좁은 폭/큰 글자는 인증 버튼을 입력 아래 배치하고 키보드/스크롤·포커스 이동·Semantics liveRegion을 제공한다.
- 저장 실패는 draft/사진 유지. 증명 만료/취소/대상 불일치/사용됨은 재인증. 통신 응답 유실은 동일 Idempotency-Key로 복구한다. 401 refresh의 multipart clone에서도 같은 key/token/파일을 유지한다.
- 가입 완료는 서버 User.requires_profile_setup=false 확인 후 AuthWrapper 이동. 편집은 서버 User 갱신 후 기존 설정으로 pop한다. 무변경/타 필드 변경의 부분 저장·선택값 삭제는 보존한다.

### 오류 구분

| 오류 출처 | 예 | UX |
|---|---|---|
| Firebase SDK | `invalid-phone-number`, `invalid-verification-code`, `session-expired` | 번호/코드 인라인 오류, 만료 시 새 인증 안내 |
| Firebase SDK | `too-many-requests`, `quota-exceeded` | 재요청 자제/나중에 재시도. 확정 retry 시각이 없으면 임의 countdown 보장 금지 |
| Firebase SDK | `network-request-failed`, 앱 확인/설정 실패 | 안전한 네트워크/서비스 안내, code별 진단 메타데이터만 기록 |
| Express | PHONE_FIREBASE_* / PHONE_VERIFICATION_* | 서버 오류 code로 재인증/대기/저장 실패 분기 |
| ShiftMate 세션 | 401/탈퇴 pending | 기존 refresh/로그인·탈퇴 흐름 |

공통 SDK 예외는 서비스에서 ApiException 등 앱 오류로 변환하고 Express 오류는 기존 handleApiError를 사용한다. AuthState에는 선택적인 code/request_id를 보존해 문자열로 오류를 판별하지 않는다.

## 7. 파일별 작업 계획

아래는 최초 파일 분할 계획이며 실제 전용 repository/네이티브 스크립트·검증 파일은11절에 기록했다. 변수 snake_case, 함수 camelCase를 사용하며 기존 auth 폴더 전체 이동/UseCase 계층 신설은 하지 않는다.

| 파일 | 역할·의존성·사용 예 |
|---|---|
| 신규 `lib/core/firebase/firebase_initializer.dart` | 기존 FirebaseEnvironmentOptions 기반 core 초기화/준비 상태 공용화. main·push·phone 서비스가 재사용 |
| 기존 `main.dart`, `core/push/push_coordinator.dart` | 공통 초기화 사용, push 실패와 phone 준비 실패 분리. Firebase auth state로 라우팅하지 않음 |
| 신규 `lib/features/auth/data/services/firebase_phone_auth_service.dart` | firebase_auth SDK adapter, 콜백·credential 로그인·ID token·보조 signOut. 예 `requestCode(phone_e164)`, `confirmCode(...)` |
| 신규 `lib/features/auth/application/phone_verification_controller.dart` | SDK adapter+AuthRepository, 화면별 autoDispose/generation·재발송/증명·중복완료 제어 |
| 신규 `lib/features/auth/application/phone_verification_state.dart` | challenge/SDK/서버 증명 상태와 오류의 임시 모델 |
| 신규 `lib/features/auth/data/models/phone_verification_models.dart` | challenge/verify 수동 DTO 파싱·필수값/UTC 검증. 기존 Apple DTO 방식 재사용 |
| 신규 `lib/features/auth/presentation/widgets/phone_verification_section.dart` | 양쪽 폼에서 공용 입력/버튼/오류·접근성 표시 |
| 기존 profile/settings 페이지 | 최신 GET/최초 번호·SDK 인증 UI·저장 gating·증명 전달 |
| 기존 auth repository/datasource/provider | createPhoneChallenge/verifyFirebasePhone, 증명+idempotency 인자, 구조화 오류/완료 boolean |
| 기존 `user.dart` 및 생성 파일 | nullable phone_verified_at 추가. 현재 입력 인증 상태로 사용하지 않음 |
| 기존 api_constants/exception/error_handler/client | 보호 API 경로·오류 메타데이터, refresh 재시도 오류 보존. raw Firebase token 로그 금지 |
| 기존 pubspec/lock·iOS/Android 설정 | 호환 firebase_auth와 환경별 앱 확인/콜백. 기존 소셜/FCM 회귀 |
| 신규 SDK 서비스/controller 테스트 | fake SDK/clock/repository로 콜백 역전·자동/수동 중복·수명/오류 검증 |
| 기존 auth datasource/repository/provider/profile/settings 테스트 | JSON/multipart/증명·가입/편집·최초 조회·401 회귀. fake 인터페이스도 갱신 |

구현 시 신규 파일의 실제 역할/의존성/사용 예를 PROJECT_CONTEXT·WORKLOG에도 기록한다. Phone Auth 관련 새 route는 두 개 모두 ShiftMate JWT 보호 대상이며 공개 endpoint 목록에 추가하지 않는다.

## 8. 단계와 인수 기준

| 단계 | 작업 | 완료 기준 |
|---|---|---|
| FE-0 | 서버 API/일회성·프로젝트·결제·동의/보관 정책 확정 | OpenAPI/Stage 설정 확인 |
| FE-1 | 공통 Firebase 초기화·firebase_auth·native 설정 | iOS/Android 빌드·FCM/소셜 callback 회귀 |
| FE-2 | SDK adapter·DTO·challenge/verify·증명 저장 인자 | 모의 SDK/Dio 요청·오류 테스트 |
| FE-3 | controller·최신 GET·공통 UI·gating | 가입/편집 위젯·수명/역순/중복 콜백 테스트 |
| FE-4 | Stage 실기기·실문자·서버/DB 재시도 | iOS APNs/reCAPTCHA, Android 자동/수동/앱 확인 인수 |
| FE-5 | 서버 선준비·OTP 대응 앱 제공·구버전 대응·강제 | 무증명 저장 우회 불가, 운영 smoke |

- [ ] 가입 미인증/SDK만 성공/오래된 Firebase currentUser는 가입 불가, 서버 증명 성공만 허용.
- [ ] 편집 최초 GET 실패 차단, A→B 인증 필수, B 인증 후 C 무효화, 최초 A 복귀 시 전화 생략 타 필드 저장.
- [ ] OAuth 번호·선행0·E.164 변환·legacy/null 번호·번호 삭제·중복409.
- [ ] Android 자동 완료와 수동 확인 경합, timeout 후 수동 입력, iOS null resend token·reCAPTCHA 취소.
- [ ] 새 generation/화면 해제/계정 변경 후 늦은 SDK callback·Firebase 보조 세션 정리.
- [ ] 서버 challenge/증명 만료, 이전 Firebase auth_time·다른 프로젝트/번호/계정·증명 재사용 거부.
- [ ] 같은 논리 저장 재시도·401 사진 재전송·응답 유실·다른 기기 최신 DB 경합.
- [ ] SDK 오류/쿼터/네트워크·콘솔 설정 누락, 코드·ID token·번호 로그 없음.
- [ ] 320px·글자 확대·키보드·스크린리더·초 단위 카운트다운 과다 읽기 방지.
- [ ] 재로그인/앱 재실행 최신 번호, 미완료 가입 재개. push 기기 등록 허용/완료 후 재시작 정책도 서버와 인수.

구현 후 실행: 필요한 User 코드 생성 → 관련 Dart 포맷 → `flutter test --no-pub test/features/auth --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` → `flutter analyze --no-pub` → 전체 회귀/플랫폼 빌드·Stage 실기기. Emulator/콘솔 테스트 번호는 실문자 도착·앱 확인 성공 증거와 구분하고 운영 프로젝트에 테스트 우회를 두지 않는다.

## 9. 배포·영향·롤백·문서 사용

Behavior change(모바일 구현, 서버 강제 전): 가입/변경 번호 저장 인증 필수, 편집 최초 조회 추가, Firebase 보조 인증 세션과 Google 번호 처리 추가. 기존 ShiftMate 소셜 로그인/JWT·번호 미변경 부분 저장·사진/근무 정보 계약은 유지한다.

서버 API/migration 선준비 → Stage 양측 인수 → Firebase 대응 앱 스토어 제공 → 기존 API 호환 버전 정책으로 구버전 대응 → 서버 인증 검사 전면 강제. 현재 호환 번호1은 이번 문서 작업에서 변경하지 않으며 새 번호는 출시 때 정한다. 강제 후에는 인증 기능 없는 앱으로 단순 롤백하지 않고 Firebase 대응 수정판으로 복구한다. 장애 때 인증 필요한 저장은 차단하고 기존 타 필드 수정/조회는 보존한다. SENS로 자동 fallback하지 않는다.

- 역할: 모바일 구현 분할·리뷰·QA 기준.
- 의존성: 기존 auth/FCM 코드, Firebase 공식 규격, ADR-0088, 서버 요청서.
- 사용 예: FE-1~FE-5를 작업 이슈로 만들고 Stage 결과를 연결한다. 문서 자체 롤백은 이번 개정분만 되돌리며 SENS 계획을 현행으로 재활성화하지 않는다.

## 10. 사용자 제공 예제 검토 (2026-11-21)

참고: [Velog의 Flutter/Firebase SMS 가입 예제](https://velog.io/@false90/FlutterFirebase%EB%A1%9C-SMS%EC%9D%B8%EC%A6%9D%EC%9D%84-%EB%B0%9B%EC%95%84%EB%B3%B4%EC%9E%90), 작성일2024-08-31. 예제의 서비스 분리·verificationId/코드 사용은 참고하고, 아래 판단은 현행 코드와 공식 문서로 대조했다.

| 검토 항목 | ShiftMate 적용 |
|---|---|
| 번호 변환 | 예제 코드의 국가코드 단순 결합은 국내 앞자리0을 남긴다. 서버 challenge가 반환한 E.164를 사용하고 `01012345678 → +821012345678`을 고정 회귀로 둔다 |
| 계정 생성 순서 | 예제는 이메일 계정 생성 뒤 phone credential을 연결한다. 호출 순서상 연결 실패에도 이메일 계정이 남을 수 있다는 판단이다. 기존 소셜/JWT·Express 가입 완료 흐름을 유지하고 새 이메일 계정/Firestore 저장을 추가하지 않는다 |
| 인증 완료 | credential 객체 생성만으로 성공 처리하지 않는다. SDK 인증과 서버 ID token 검증/증명 교환 후에만 완료 표시 |
| 자동 처리 | 비어 있는 자동 완료 콜백은 채운다. 수동 확인과 동일 함수·중복 실행 방지를 사용 |
| 시간 | 예제의120초는 코드 TTL로 사용하지 않는다. 자동 읽기 종료 후 수동 입력을 유지 |
| 오류 | SDK 원문 toast/print를 복사하지 않고 서비스에서 안전한 code/문구로 변환 |
| 테스트/비용 | 과거 무료 횟수·시뮬레이터 경험을 현재 보장으로 사용하지 않는다. 테스트 번호/Emulator와 Stage 실기기·실문자를 분리 |

근거: [공식 Phone Auth](https://firebase.google.com/docs/auth/flutter/phone-auth), [이메일 계정 생성](https://firebase.google.com/docs/auth/flutter/password-auth), [현재 결제/한도](https://firebase.google.com/docs/auth/limits). 코드120초를 앱 인증번호 만료로 설명하는 주석/안내는 넣지 않는다. 설계 변경 없이 ADR-0088을 유지한다.

추가 인수: 국내 원본/하이픈 입력의 E.164 일치·`+82010…` 거부, 코드 오류/서버 거부 시 가입 미완료 유지, 자동/수동 경합과 자동 읽기 종료 후 수동 성공, 서버 저장 실패 시 기존 프로필 보존. 이는 구현 시 테스트할 항목이며 이번에 앱 실행으로 검증한 결과가 아니다.

## 11. 모바일 구현 결과 (2026-11-21)

사용자가 서버 작업 전임을 확인했다. 요청서 계약으로 앱과 fake SDK/Dio 테스트를 구현했으며 실제 API/실문자 인수 결과로 표시하지 않는다. 신규 API404/501은 준비 중 오류로 처리하며 Firebase SMS 호출 전에 challenge를 요구한다. 앱 배포/서버 강제는8~9절의 잔여 인수를 마친 후 진행한다.

| 신규 파일 | 실제 역할·의존성·사용 예 |
|---|---|
| `lib/core/firebase/firebase_initializer.dart` | FirebaseEnvironmentOptions/core 공통 초기화·환경 대조. FCM과 SDK 서비스에서 `ensureInitialized()` 사용 |
| `lib/features/auth/data/models/phone_verification_models.dart` | ApiException 기반 국내/E.164 변환, challenge/proof wire DTO·UTC/필수값 검증. `PhoneChallenge.fromJson(...)`, `koreanPhoneE164(...)` |
| `lib/features/auth/data/repositories/phone_verification_repository.dart` | 기존 Dio/ApiClient 오류 규칙을 사용한 protected challenge/verify. controller가 `createChallenge`/`verifyFirebasePhone` 호출, 테스트 provider override 가능 |
| `lib/features/auth/data/services/firebase_phone_auth_service.dart` | firebase_auth6.5.6 adapter·안전한 SDK 오류·직렬 보조 세션. `startSession → requestCode → signIn → closeSession`; 주입 가능한 auth_loader는 SDK 테스트 seam이며 앱 확인 우회 아님 |
| `lib/features/auth/application/phone_verification_state.dart` | 인증 단계/오류·잔여시간·메모리 증명 모델. 공통 UI가 state만 표시 |
| `lib/features/auth/application/phone_verification_controller.dart` | 전용 repository+SDK 의존, 화면 scope autoDispose·generation·단조 시계·자동/수동 단일 완료·재시도. Page가 `sendCode`, `verifyCode`, `tokenFor` 사용 |
| `lib/features/auth/presentation/widgets/phone_verification_section.dart` | AppTheme/Cupertino 기반 공용 안내·6자리/oneTimeCode·재발송/확인/완료·inline 오류. 가입/편집 기본 정보 카드에서 사용 |
| `ios/scripts/configure_firebase_phone_auth.py` | Python 표준 라이브러리·Xcode DART_DEFINES 의존. 기존 Thin Binary 단계에서 선택 App ID의 callback scheme만 built Info.plist에 멱등 반영. 원본 plist/OAuth type 보존 |
| `ios/scripts/test_configure_firebase_phone_auth.py` | unittest·임시 plist로 환경 선택/보존/재실행/잘못된 입력 검증. `python3 -m unittest discover -s ios/scripts -p 'test_*.py'` |
| `test/helpers/phone_auth_fakes.dart` | repository/SDK callback·응답 지연/실패 fake. controller/widget 테스트에서 `phoneAuthOverrides(...)` 사용 |
| `test/features/auth/application/phone_verification_controller_test.dart` | fake clock/repository/SDK로 번호 전환·만료·역순/중복·재발송·응답 유실/멱등키 검증. `flutter test --no-pub test/features/auth/application` |
| `test/features/auth/data/repositories/phone_verification_repository_test.dart` | Dio adapter·JWT/header·DTO/오류/미제공/429 검증. 해당 파일을 flutter test로 실행 |
| `test/features/auth/data/services/firebase_phone_auth_service_test.dart` | fake native Auth/User로 signIn/signOut 경합·지연 취소·세션 정리·새 토큰·원문 오류 비노출 검증. 해당 파일을 flutter test로 실행 |
| `artifacts/phone_verification_2026-11-21/render_test.dart` | 기존 AppTheme/프로필 페이지·fake SDK·번들 폰트 의존. `flutter test --no-pub artifacts/phone_verification_2026-11-21/render_test.dart`로 가입/편집18조건 검증/PNG 생성. 기본 출력은 `/private/tmp/shiftmate-phone-auth-20261121/render`, `--dart-define=PHONE_AUTH_RENDER_DIR=...`로 지정 가능 |

기존 파일 변경: main/FCM 공통 초기화 및 재실행 세션 정리, AuthRepository/DataSource/AuthNotifier의 증명·멱등키/구조화 오류·가입 완료 boolean, User nullable phone_verified_at와 생성 파일, API 상수/Retry-After/401 재시도 오류 보존, ProfileSetupPage 최신 GET/저장 gating, 기존 fake/JSON·multipart/화면·provider 테스트다. 이전 프로필 렌더러도 새 repository signature·GET을 반영했다. 기존 Route·접근권한/analytics·계정 JWT·FCM token·선택값/이미지 계약은 유지한다.

- 의존성: firebase_auth6.5.6 정확한 pin, 신규 platform_interface9.0.5/web6.2.5. 기존 core4.12.1·messaging16.4.3·Firebase iOS12.15.0과 다른 lock 버전을 보존했다. 빌드 호환 번호/앱 빌드 번호는 이번 인증 변경으로 올리지 않았다.
- 검증: 실행 명령·결과·기존 실패 구분·로그는 WORKLOG 최상단을 따른다. fake 기반 통과와 실기기 인증 인수를 구분한다.
- 남은 작업: 서버 OpenAPI/구현·Stage 배포·증명 원자 소비/영수증, Blaze, Android SHA, Stage 프로덕션 APNs 필요 여부, 실제 SMS/자동/수동·silent APNs/reCAPTCHA·기존 소셜/FCM, 동의/보관/공개 정책 인수.
- 롤백: 이번 앱 인증 변경·신규 파일·lock/native 설정만 복구하고 pub get/pod install/재빌드한다. 기존 미커밋 가입 UI·출시 변경을 보존하며 서버 강제 후 무인증 저장으로 되돌리지 않는다.

## 12. 인증 입력 UI 개선·Google 안내 이동 검토 (2026-11-22, ADR-0101)

### UI·파일 사용

- 목적/Behavior change: 번호 입력 아래에 발송 버튼·코드 입력·인증 버튼을 누적하던 구성을 단계 교체로 변경했다. `PhoneVerificationSection(phone_input: ..., code_focus: ..., onEditPhone: ..., state: ..., onSend: ..., onVerify: ...)`가 기존 Page의 전화번호 입력 위젯을 받아 표시하고, 발송 성공 후에는 발송한 번호/번호 변경 → 코드/확인 → 재발송으로 교체한다. 가입과 변경번호 편집에 같은 UI를 사용한다. 정상 폭에서는 코드와 확인을 가로 배치하며 내부 폭280미만·14pt가18pt초과로 확대된 경우와 서버 재확인은 세로로 배치한다.
- 번호 변경을 열기만 하면 서버 세션/입력 코드를 유지하고 ‘인증번호 입력으로 돌아가기’로 복귀한다. 실제 번호를 바꾸면 기존 controller의 setPhone이 인증을 초기화한다. 발송/재발송은 이전 코드 입력을 비우고, 발송 완료는 중간 sending 프레임이 생략돼도 OTP 포커스/스크롤을 이동한다. 서버 증명 성공 시 기존 번호 입력과 완료 표시로 복귀한다. 6자리 전 확인 버튼은 비활성화한다. 서버 결과 재확인 중에는 입력/재발송을 막고 동일 ID token/key 복구를 유지한다.
- Google 전송·저장 요약은 최초 발송 전에 그대로 노출하고 자세히에서 Firebase 사용·Google 서비스 전반의 스팸/악용 방지 목적과 기존 개인정보처리방침 링크를 제공한다. 상세창은 고지이며 동의 수집/기록 기능이 아니다. 저장 증명·권한·autoDispose·API/DB·native·route·analytics는 변경하지 않았다.
- 기존 파일 역할: 공용 인증 widget은 AppTheme/Cupertino와 core/utils/privacy_policy.dart의 링크/실패 처리를 재사용한다. Page는 전화번호 controller·전화/OTP focus·기존 포맷터를 소유하고 dispose한다. 이름의 다음 키는 현재 표시된 전화/OTP 입력으로 이동한다. 기존 profile_setup_page_test.dart에 단계 높이·6자리/autofill·자동 포커스·번호 편집/복귀·재발송 코드 초기화·동일 서버 결과 재확인·상세 고지 회귀5개를 보강했다. 재발송 테스트는 controller의 주입 가능한 단조 시계를 사용하며 가짜 Flutter 시간으로 실제 Stopwatch가 흐른다고 가정하지 않는다.
- 기존 `artifacts/phone_verification_2026-11-21/render_test.dart`는 가입/편집18조건 및 초기2조건의 실제 Flutter PNG20개를 생성한다. 역할/의존성과 실행법은11절과 같으며 OTP 입력 후 rebuild를 기다리고 검토 시 기본 정보 카드/현재 입력으로 스크롤한다. `signup_initial.png`, `signup_compact.png`, `signup_large_text.png`는 이 렌더러로 생성한2026-11-22 검토용 PNG이며 runtime 의존성이 없다. 해당 폴더에서 초기/인증/확대 비교에 사용한다.

### 법률·약관 검토 결과와 미확정 사항

후속 공개 문안 보완(2026-11-22): 사용자 요청으로 로컬 privacy.html/PRIVACY_POLICY.md v1.2의2·3·6·7항에 확인된 인증 항목/목적·미국 처리·Firebase 공식 보관·거부 영향과 개정 이력을 추가했다. 아래 ‘누락/HTML 변경 없음’은 최초 UI 작업 당시 이력이며 현재 로컬 문안은 PRIVACY_REVIEW의v1.2 절을 따른다. 실제 계약·동의/삭제 구현·원격 게시 인수는 계속 필요하다.

검토일2026-11-22. **현재 상태에서 ‘일반 이용약관에 옮기면 충분하다’고 판단할 수 없다.** 상세 내용을 별도 문서에 두는 것과 필요한 사전 고지/동의를 확보하는 것은 별개다. 아래는 공개 법령·공식 문서/코드 대조이며 개별 계약에 대한 법적 적합성 확정은 아니다.

| 근거 | 확인 내용·적용 판단 |
|---|---|
| [Firebase Flutter Phone Auth](https://firebase.google.com/docs/auth/flutter/phone-auth) | 전화번호의 Google 전송·저장, Firebase 밖을 포함한 Google 서비스의 스팸/악용 방지 개선 이용과 서비스 사용 전 적절한 이용자 동의 확보를 개발자에게 요구한다. 일반 소셜 로그인 동의를 이 동의로 추정하지 않는다. |
| [Firebase 개인정보·보안](https://firebase.google.com/support/privacy) | Authentication은 미국에서 처리된다. 서비스 안내상 로그 IP는 수 주, 그 외 인증 정보는 고객이 관련 사용자 삭제를 시작할 때까지 보관하며 삭제 요청 후 live/backup 제거에180일 이내가 안내된다. 이는 ShiftMate가 실제로 삭제를 구현했다는 근거가 아니다. 악용 방지 목적의 구체 계약·보관 범위도 대조해야 한다. |
| [현행 개인정보 보호법 제17·22·28조의8](https://www.nhis.or.kr/lm/lmxsrv/law/lawFullContent.do?SEQ=190&SEQ_HISTORY=), [국가법령정보센터 현행본](https://www.law.go.kr/LSW/lsInfoP.do?lsiSeq=283839&efYd=20260911&joNo=002808&urlMode=lsInfoP) | 제28조의8은 별도 국외 이전 동의 외에도 계약 체결/이행에 필요한 처리위탁·보관의 경우 법정 사항을 처리방침에 공개하는 등의 근거를 둔다. 이 요건과 제3자 제공/동의 구분은 별도로 검토해야 한다. Google 자체 서비스 전반 이용까지 단순 위탁으로 확정하지 않는다. |

- 실제 계정 계약의 수신 법인/연락처·이전 항목/국가/시점/방법·목적·보유기간·거부 방법/효과와 적용 법적 근거를 확정한다. 별도 동의 근거를 쓰면 해당 고지와 명시적 동의, 버전/시각 등 입증 가능한 서버 기록을 설계해야 한다. 단순 ‘인증번호 받기’나 고지창 닫기를 법정 동의로 기록하지 않는다.
- 로컬 `app_store_web/privacy.html`/PRIVACY_POLICY에는 FCM/소셜 로그인 항목은 있지만 **Firebase Authentication 휴대폰 인증의 별도 처리 내역이 없다**. 기존 FCM 글로벌 처리 설명을 미국 전용 Authentication 설명으로 대신할 수 없다. 공개 URL은 이번 웹 도구로 접근되지 않아 최신 게시본 일치를 검증하지 못했다.
- 공개 정책2·3·6·7항의 인증 항목/보관/수탁·수신자/국외 이전과 실제 동의 흐름을 함께 보완한 뒤 안내를 약관/정책으로 더 이동할 수 있는지 재평가한다. 현재 자료에 없는 계약/삭제 정책을 만들어 공개 HTML에 넣지 않았으며 원격 게시도 하지 않았다. 기존 연령/항목별 동의 본문은 보존했다.
- 현재 앱 FirebasePhoneAuthService의 signOut/closeSession은 사용자 삭제가 아니다. 서버 요청서에 이미 남아 있는 phone-only Firebase 사용자 보관/소유 확인/탈퇴 정리 절차를 확정해야 한다. ‘인증 직후 폐기’ 또는 ‘탈퇴 시 Google 정보 즉시 삭제’로 고지하지 않는다.
- 롤백: 이번 인증 widget/호출부·화면 회귀·렌더러·검토 PNG/문서만 되돌린다. 기존 인증 필수·서버 증명/수명·다른 미커밋 작업을 보존한다. 검증 수치·실기기 한계는 WORKLOG 최신 항목을 따른다.

## 13. 중복 확인 후 인증 입력 선표시·수신 번호 요약 (2026-11-22, ADR-0102)

이 절은12절의 ‘codeSent 후 입력 표시’와 번호를 라벨 위치에 배치하던 UI를 대체한다. 인증의 실제 성공 기준은 유지한다.

```text
idle → checking (서버 challenge: 번호 중복/목적/계정 확인)
  → sending (인증번호 입력 즉시 표시·포커스, Firebase 세션 준비/발송은 계속 진행)
  → code_sent (SDK verificationId 확보, 6자리 입력이면 확인 활성)
  → verifying (Firebase 확인 + ID token + 서버 저장 증명)
  → verified (서버 증명·기한 확인 후 저장 허용)
확인/발송 실패 → idle + 입력 번호 유지 + 오류/재시도
```

- 확인 근거: 인접 서버 `src/services/phoneVerificationService.ts`의 createChallenge는 신규/멱등 복구 경로 모두 assertPhoneAvailable을 호출하고 다른 사용자의 번호면409/PHONE_ALREADY_EXISTS를 반환한다. 앱은 이 API의 성공·응답 번호/목적/기한 검증까지 기다린다. 중복 확인 성공을 추측하거나 API를 추가하지 않는다. 서버 소스 확인은 원격 배포 버전 인수와 구분한다.
- 상태 변경: 기존 sending을 checking(서버 응답 대기)과 sending(번호 사용 가능 확인 후 SDK 준비/발송 대기)으로 나눴다. sending부터 코드 입력이 보이고 입력도 가능하지만 확인/저장/재발송은 차단한다. SDK codeSent를 받으면 미리 입력한 코드를 유지하며6자리 확인을 활성화한다. sending 상태는 문자 도착 또는 인증 성공의 낙관적 판정이 아니다.
- 실패/경합: 기존90초 발송 timeout의 시작을 SDK 세션 준비 이전으로 옮겨 선표시 후 준비 지연도 제한한다. 준비/발송 실패·timeout은 idle과 오류로 복구하고 늦은 세션·콜백은 generation/기존 native 직렬 경계로 정리한다. 번호 변경도 기존 setPhone으로 이전 인증을 폐기한다. 발송 대기 중에는 번호 편집/같은 코드 입력 복귀가 가능하며 단순 편집 열기는 세션을 폐기하지 않는다. 기존 재발송60초·Retry-After·응답 유실/멱등 복구를 유지한다.
- UI/Behavior change: 기본 정보 카드의 입력 라벨은 ‘인증번호 *’다. 라벨 아래 코드/확인 → 별도 옅은 ‘수신 번호’ 상자의 번호/변경 → 전송 중 상태 또는 재발송 순서다. 전화번호를 입력 라벨로 사용하지 않는다. 작은 폭/큰 글자는 코드/확인을 세로로, 큰 글자의 번호 변경은 상자 아래로 배치한다. 전화번호는 큰 글자에서 하이픈 구간별 줄바꿈과 전체값 접근성 이름으로 마지막 한 자리만 분리되지 않게 한다. 전송 중에도 oneTimeCode/붙여넣기·자동 포커스/스크롤을 유지한다.
- 인증 확인 지연 검토: 앱의 실제 확인 경로는 SDK signInWithCredential → getIdToken(true) → 서버 verify → 증명/목적/기한 대조다. 이번에는 실제 지연 구간을 계측하거나 이 검증을 생략하지 않았다. SDK/native 서비스/서버·보안 토큰 정책·API/DB·임의 낙관적 인증 완료를 바꾸지 않는다. 사용자가 확인 단계 유지를 허용한 범위에서 기존 흐름을 유지한다.
- 파일 역할/의존성/사용: 기존 application의 state는 checking을 추가하고 is_busy에 포함한다. controller.sendCode는 유효한 서버 응답 직후 sending으로 갱신한 뒤 SDK 준비를 await한다. 기존 PhoneVerificationSection는 새 상태를 표시하고 code_sent에서만 onVerify를 활성화하며 Page의 전화 입력/OTP focus를 계속 재사용한다. test/helpers/phone_auth_fakes.dart는 pending_start/start_error로 SDK 준비 지연/실패를 주입한다. 기존 controller 회귀6개·프로필 화면 회귀3개를 보강했고 렌더러는 발송 대기/큰 글자2조건×가입·편집을 추가해 총24PNG를 생성한다.
- 자료: 기존 signup_initial.png·signup_compact.png·signup_large_text.png를 최신 표시로 갱신했다. 새 `artifacts/phone_verification_2026-11-21/signup_sending.png`는 서버 중복 확인 후 SMS 콜백 전에도 입력 가능한 상태를 보여주는 실제 Flutter 검토용 PNG다. 기존 렌더러·AppTheme/폰트·fake SDK에 의존하고 runtime 의존성은 없다. 검토/재생성은11절 명령에 PHONE_AUTH_RENDER_DIR를 지정하고 해당 출력 signup_sending.png를 사용한다.
- 검증/롤백: 인증 관련 회귀136 pass·변경7 Dart파일 분석 진단0·렌더24조건/큰 글자 번호 배치 확인. 최종 명령·로그/제약은 WORKLOG를 따른다. 이번 state/controller/widget·fake/회귀·렌더러/검토 PNG·문서 추가분만 복구하고 이전 UI·정책 HTML 등 다른 미커밋 변경은 보존한다. 실제 SMS/실기기 지연 개선 수치를 이번 결과로 주장하지 않는다.
