# Firebase Phone Auth 콘솔·운영 사전 작업 가이드

조사일/개정일: 2026-11-21 (Asia/Seoul) · 상태: **조사 완료·사용자 제공 설정 결과 반영, 실문자 인수 전**
대상: ShiftMate의 Firebase Phone Auth 도입(ADR-0088), Flutter 모바일 + Express/PostgreSQL

## 1. 목적과 사용 범위

코드 구현 외에 Firebase/Google Cloud 콘솔 및 Apple Developer·Google Play·CI/서버 운영에서 준비할 작업을 정리한다. 각 환경을 선택해 아래 순서대로 수행하고 완료 증거를 기록한다. 콘솔 메뉴 이름은 표시 언어/프로젝트 기능에 따라 달라질 수 있으므로 영어 기능명과 공식 링크도 함께 확인한다.

- 모바일 구현: [PHONE_VERIFICATION_FLUTTER_PLAN.md](PHONE_VERIFICATION_FLUTTER_PLAN.md)
- 서버 구현/검증 계약: [PHONE_VERIFICATION_SERVER_HANDOFF.md](PHONE_VERIFICATION_SERVER_HANDOFF.md)
- 기존 Firebase/푸시 환경: [PUSH_NOTIFICATION_GUIDE.md](PUSH_NOTIFICATION_GUIDE.md)

이번 앱 작업에서는 로그인된 콘솔 조회나 결제/설정/IAM/키 변경을 하지 않았다. 후속 사용자 제공 결과를 아래에 구분해 반영했다. 체크되지 않은 항목은 인수 전이며, 실제 금액·권한·비밀값 없이 설정 여부/담당/날짜로 기록한다.

### 사용자 제공 설정 결과 (2026-11-21)

| 항목 | Stage | 운영 |
|---|---|---|
| Project ID | `shift-mate-stage` | `shift-mate-b9e32` |
| Phone 제공자 | 활성화·저장 확인 | 활성화·저장 확인 |
| SMS 지역 | KR만 허용·저장 확인 | KR만 허용·저장 확인 |
| 요금제 | Spark | Spark |
| Android SHA-1/SHA-256 | 미등록 | 미등록 |
| APNs 키 | 개발 등록 | 개발·프로덕션 등록 |

사용자가 약관 동의 후 저장까지 확인했으며 기존 FCM/키를 보존했다고 전달했다. 근거는 사용자 메시지 및 제공한 `firebase-phone-auth-status.txt` 기록이며, 이번 Codex의 직접 콘솔 검증 결과가 아니다. Blaze 전환/결제수단 변경은 수행하지 않았다. 남은 항목은 Blaze·Android 서명 지문·Stage 프로덕션 APNs 필요 여부·서버/실기기 인수다. 모바일 SDK/Debug 빌드·모의 UI 결과는 모바일 계획11절/WORKLOG를 따른다.

### 실기기 실패 후 재확인 (2026-11-21)

- 사용자 확인: 현재 Stage는 **Spark 유지 중**이다. 이번에 Blaze/결제를 변경하지 않았다.
- 실행 확인: 연결된 iPhone Debug에서 Firebase SMS 요청의 verificationFailed가 internal-error를 반환했다. 앱 공통 안내는 이 오류의 매핑 결과다. FlutterFire 변환에서 underlying response가 생략돼 BILLING_NOT_ENABLED 원문까지 확보한 것은 아니다.
- 차단 조건: [공식 FAQ](https://firebase.google.com/docs/auth/faq-and-troubleshooting)·[한도](https://firebase.google.com/docs/auth/limits)에 따라 실문자에 Cloud Billing/Blaze가 필요하다. Stage 결제 연결 후 실기기 전 구간을 다시 인수한다. SMS 없이 흐름을 확인할 때는 콘솔 테스트 번호/고정 코드를 사용하되 실문자 성공과 구분한다.
- 조사/검증/영향/롤백은 [WORKLOG 최상단](WORKLOG.md)에 기록했다. 이번은 진단 문서 추가이며 앱/서버 동작 변경은 없다.

## 2. 최초 조사 시 저장소 확인 상태

| 항목 | 저장소에서 확인한 사실 | 콘솔/운영 확인 필요 |
|---|---|---|
| 프로젝트 분리 | FirebaseEnvironmentOptions가 Debug=Stage, Profile/Release=운영 선택 | 실제 두 Project ID·결제·Phone 활성 상태 |
| 운영 ID | 기존 푸시 가이드에 `shift-mate-b9e32` 기록 | 현 콘솔 Project ID와 재대조. 표시 이름 `shift-mate`와 혼동 금지 |
| Stage ID | 이번 조사에서 실제 값을 읽지 않음 | Stage 프로젝트 선택·ID 기록 |
| 앱 식별자 | Android/iOS 모두 `com.hspark.shiftmate` | 각 Firebase 프로젝트의 Android/iOS 앱 등록 일치 |
| Flutter 구성 | 최초 core/messaging만 존재; 후속 firebase_auth6.5.6 구현·iOS/Android Debug 빌드 성공 | 실제 앱 확인/실문자·콘솔 구성 인수 |
| iOS | aps-environment, fetch/remote-notification, FlutterSceneDelegate 존재 | 유효 APNs 키·Team ID·서명 profile·Auth fallback |
| Android | minSdk24, 현재 release도 debug signing 설정 | 실제 출시 서명 결정·인증서 지문 등록 |
| 서버 | firebase-admin FCM provider·ADC 방식 존재 | **API 프로세스** Auth 조회 권한/credential·project 선택 |

근거 파일: `lib/core/push/firebase_environment_options.dart`, `pubspec.yaml`, `ios/Runner/Info.plist`, `ios/Runner/Runner.entitlements`, `android/app/build.gradle.kts`, 인접 서버 `src/services/firebasePushProvider.ts`·`src/config/environment.ts`. `.env`/개인키 원문은 조사에 출력하지 않았다.

## 3. 수행 순서와 담당

담당 구분은 역할 제안이며 실제 사람/권한은 프로젝트 담당자가 지정한다.

| 순서 | 작업 | 주 담당 | 수행 시점 | 완료 증거 |
|---|---|---|---|---|
| F-01 | Stage/운영 Project·앱 매핑 | Firebase 관리자 + FE | 구현 전 | ID/앱 등록 대조표 |
| F-02 | Blaze/결제·예산 알림 | 결제 관리자 | 실문자 전 | 환경별 결제 연결/수신 담당 |
| F-03 | Phone 제공자·한국 SMS allowlist | Firebase 관리자 | 구현 전 | 설정 화면/적용 날짜 |
| F-04 | 앱 설정/API key·관련 API 확인 | Firebase 관리자 + FE | 구현 전 | 제한 목록·설정자료 전달 |
| F-05 | Android SHA 지문 | Android/배포 담당 | 서명 결정 후 | 서명 종류별 등록 지문 |
| F-06 | iOS APNs/Team·fallback 자료 | Apple/Firebase 관리자 | 구현 전 | 등록 상태·Encoded App ID 전달 |
| F-07 | 서버 ADC/IAM·project | 서버/인프라 담당 | 서버 인수 전 | 최소권한/credential 경로·조회 성공 |
| F-08 | Stage 테스트 번호 | Firebase 관리자 + QA | 개발/QA | 등록 여부, 코드 전달 경로 |
| F-09 | App Check 등 추가 보호 검토 | FE + Firebase 관리자 | 호환 SDK 구현 후 | 모니터링·강제 적용 판단 |
| F-10 | 정보 처리/보관·지원 절차 | 운영/개인정보 담당 | 출시 전 | 안내/보관/정리 정책 검토 기록 |
| F-11 | 실제 빌드·실문자·운영 인수 | FE/BE + QA | 구현 후 | 검증표·출시 전 확인 |

## 4. F-01: 프로젝트·앱 등록 확인

[Firebase Console](https://console.firebase.google.com/) → 프로젝트 선택 → 톱니바퀴 **Project settings → General**.

- [ ] Stage와 운영의 Project ID/Project number를 각각 확인한다. 같은 프로젝트를 두 이름으로 기록하지 않는다.
- [ ] 각 프로젝트에 Android 앱과 iOS 앱이 존재하고 패키지/Bundle ID가 `com.hspark.shiftmate`인지 확인한다.
- [ ] Firebase App ID(예: `1:…:android:…`/`1:…:ios:…`)를 패키지명과 구분해 개발자에게 전달한다.
- [ ] iOS Team ID·앱 표시 정보도 올바른 환경인지 확인한다.
- [ ] 기존 앱 등록이 있으면 재사용하고 동일 식별자의 불필요한 앱/프로젝트를 새로 만들지 않는다.

이 프로젝트는 같은 패키지/Bundle ID를 사용하므로 Stage/운영 앱을 같은 기기에 동시에 설치하지 못한다는 기존 운영 제약이 있다. 환경 전환 QA는 설치 교체와 서버/Firebase project 확인을 함께 기록한다.

공식 설정 자료를 내려받아 개발자에게 전달할 수 있지만 현재 앱은 FirebaseOptions를 직접 주입한다. `google-services.json`/`GoogleService-Info.plist` 복사만으로 완료 처리하지 말고 기존 define·native Auth 콜백에 필요한 자료를 함께 대조한다. Gradle/소스 수정은 별도 구현 작업이다.

## 5. F-02: 결제·요금·예산

Firebase Console **Usage and billing / Upgrade**에서 Cloud Billing 계정 연결과 Blaze 상태를 확인한다. 실제 SMS 서비스에는 Cloud Billing 연결이 필요하다. [공식 Auth FAQ](https://firebase.google.com/docs/auth/faq-and-troubleshooting), [Auth 제한](https://firebase.google.com/docs/auth/limits)

| 조사일 공식 안내 | 준비할 일 |
|---|---|
| 한국(KR) SMS 건당 US$0.01 | 출시 직전 KR 단가/결제 통화 SKU 재확인 |
| 일별 첫10건 미청구 | 무결제 Spark 이용 가능 또는 무제한 무료라는 의미로 사용하지 않음 |
| 발송 SMS 기준 비용 | 재발송·인증 실패까지 포함해 사용량 산정 |

위 단가/미청구 구간은 [Identity Platform 공식 요금표](https://cloud.google.com/identity-platform/pricing)의 조회 결과다. 원화 청구액/세금/환율을 고정하지 않으며 실제 프로젝트 SKU/청구 리포트로 인수한다. 참고 계산으로 미청구 구간을 제외한1,000건은 US$10이다.

조사일 [공식 제한표](https://firebase.google.com/docs/auth/limits)는 기본 Firebase Authentication에 SMS 하루3,000건, IP별50건/분·500건/시간을 안내한다. 프로젝트/번호별 추가 제한과 실제 콘솔 쿼터를 함께 확인한다. 결제 연결만으로 무제한 발송이 되는 것은 아니며, 이 수치를 앱이 설정한 재발송 대기시간과 혼동하지 않는다.

- [ ] Stage와 운영 모두 실문자를 쓸 환경은 결제 연결을 확인한다.
- [ ] Google Cloud Console **Billing → Budgets & alerts**에서 환경/프로젝트별 예산·수신자를 정한다.
- [ ] 예산 금액은 담당자가 정하고50/80/100% 등 알림 기준을 기록한다(비율은 운영 제안).
- [ ] **Alerts-only** 예산은 발송/청구를 자동 중단하지 않으므로 이를 상한으로 오인하지 않는다.
- [ ] 발송 급증·인증 성공률 저하를 확인할 담당자와 전화 제공자 중단/복구 절차를 정한다.

Google Cloud의 별도 Spend cap 기능은 지원 서비스/계정 조건을 확인해야 한다. 이번 조사에서 Auth SMS 비용에 적용 가능한지 입증하지 않았으므로 자동 차단 수단으로 채택하지 않는다. [공식 예산 문서](https://cloud.google.com/billing/docs/how-to/budgets)

## 6. F-03: Phone 제공자·SMS 국가 정책

### 로그인 제공자

Firebase Console **Authentication → Sign-in method → Add new provider → Phone**(또는 기존 Phone 항목) → Enable → Save.

- [x] Stage에서 활성화 후 설정 유지 확인(사용자 제공 결과).
- [x] 운영도 별도로 활성화·저장 확인(사용자 제공 결과).
- [ ] SMS 인증만을 위해 Firebase Email/Password·Google·Apple 등 다른 제공자를 추가 활성화하지 않는다. ShiftMate의 기존 소셜 로그인은 기존 서버 체계를 유지한다.

Phone 제공자 활성화는 [공식 Flutter Phone Auth 안내](https://firebase.google.com/docs/auth/flutter/phone-auth)를 따른다.

### SMS 지역

Firebase Console **Authentication → Settings → SMS region policy** → **Allow → Select regions → South Korea(KR) → Save**.

- [x] 양쪽 환경에서 한국만 허용(사용자 제공 결과).
- [ ] Deny 목록만 두어 나머지 국가 전체를 허용하는 설정과 구분한다.
- [ ] 변경 전 정책을 기록하고 저장 후 allowlist에 KR만 남았는지 재확인한다.
- [ ] 다른 국가가 필요한 요구가 생길 때 명시적으로 추가한다.

정책은 수신 전화번호 국가코드 기준이며, 사용자의 현재 위치/통신사가 한국인지 증명하는 기능은 아니다. KR 허용이 모든 국내 번호의 전달 성공을 보장하지 않는다. tenant를 이미 쓰는 프로젝트라면 tenant별 정책도 별도로 확인한다. [공식 SMS region 설정](https://docs.cloud.google.com/identity-platform/docs/admin/sms-regions)

## 7. F-04: 공개 설정·API key/API 확인

Google Cloud Console **APIs & Services → Credentials** 및 **Enabled APIs & services**에서 실제 앱에 주입하는 key를 선택한다.

- [ ] Firebase App ID·API key·Project ID·Sender ID가 같은 환경 프로젝트에 속하는지 대조한다.
- [ ] Auth용 `identitytoolkit.googleapis.com`(Identity Toolkit API), `securetoken.googleapis.com`(Token Service API)이 key의 API 제한에서 차단되지 않았는지 확인한다. API 활성 상태도 함께 확인한다.
- [ ] 기존 FCM이 쓰는 Firebase Installations/FCM Registration 등 허용 항목을 Auth 준비 중 삭제하지 않는다.
- [ ] 플랫폼별 application restriction과 reCAPTCHA fallback의 실제 허용 조합을 Stage에서 확인한 뒤 운영에 적용한다. 근거 없이 운영 key 전체 제한을 해제하지 않는다.

Firebase client API key는 프로젝트 식별용 공개 설정이며 Admin 개인키와 다르다. API key를 감추는 것만으로 SMS 남용을 막을 수 없고, 허용 API/앱 확인/국가/운영 감시를 함께 사용한다. [Firebase API key 공식 안내](https://firebase.google.com/docs/projects/api-keys)

reCAPTCHA fallback에서는 Firebase가 제공한 실제 `…firebaseapp.com` 호스트/API key 허용 조건을 공식 Android/iOS 문서와 대조한다. 웹 앱을 새로 배포하거나 임의의 ShiftMate API URL을 OAuth redirect로 등록하는 작업으로 대체하지 않는다. 이미 있는 Authorized domains를 무조건 삭제/재생성하지 않는다.

개발/CI에 전달할 값은 기존 다음 이름을 사용한다. 값은 별도 설정 저장소에 보관하고 이 문서에는 붙이지 않는다.

| Stage | 운영 |
|---|---|
| FIREBASE_STAGE_PROJECT_ID | FIREBASE_PROD_PROJECT_ID |
| FIREBASE_STAGE_MESSAGING_SENDER_ID | FIREBASE_PROD_MESSAGING_SENDER_ID |
| FIREBASE_STAGE_ANDROID_API_KEY | FIREBASE_PROD_ANDROID_API_KEY |
| FIREBASE_STAGE_ANDROID_APP_ID | FIREBASE_PROD_ANDROID_APP_ID |
| FIREBASE_STAGE_IOS_API_KEY | FIREBASE_PROD_IOS_API_KEY |
| FIREBASE_STAGE_IOS_APP_ID | FIREBASE_PROD_IOS_APP_ID |

기존 STORAGE_BUCKET은 Auth 때문에 생성/설정할 필요가 없다.

## 8. F-05: Android 등록·서명 지문

Firebase **Project settings → General → Your apps → Android → SHA certificate fingerprints → Add fingerprint**.

| 배포 형태 | 확인할 인증서 |
|---|---|
| 개발 Debug | 실제 개발 빌드의 debug 인증서 |
| 직접 배포 Release | 해당 APK를 서명하는 release 인증서 |
| Google Play 배포 | Play Console **App integrity / App signing**의 App signing 인증서 |
| 업로드 과정 | Upload 인증서는 Play가 사용자에게 배포하는 App signing 인증서와 구분 |

- [ ] 실제 사용 인증서의 SHA-1과 SHA-256을 해당 Firebase 프로젝트에 등록한다.
- [ ] Stage는 Stage QA 빌드, 운영은 실제 배포 빌드 기준으로 확인한다.
- [ ] 지문 등록 후 필요하면 최신 Android 설정자료를 개발자에게 전달한다.
- [ ] 현 저장소의 release debug signing을 실제 출시 서명으로 오인하지 않는다. 서명 확정은 배포 담당/코드 작업과 연결한다.

SHA-256은 Play Integrity 앱 확인, SHA-1은 reCAPTCHA fallback 준비에 필요하다. Firebase Auth의 Play Integrity는 Google 소유 프로젝트를 이용하므로 Phone Auth만을 위해 자체 Google Cloud 프로젝트에 Play Integrity API/서비스 계정을 무조건 추가하지 않는다. [공식 Android Phone Auth](https://firebase.google.com/docs/auth/android/phone-auth)

인수는 Play 배포 경로와 sideload/reCAPTCHA 경로를 나눈다. 지문 등록만으로 앱 확인 성공을 선언하지 않는다.

## 9. F-06: iOS APNs·reCAPTCHA 자료

### Apple/Firebase 관리 작업

- [ ] Apple Developer에서 현재 Team/Bundle ID와 Push Notifications capability를 확인한다.
- [ ] Firebase **Project settings → Cloud Messaging → Apple app configuration → APNs authentication key**에서 유효한 키 등록을 확인한다.
- [ ] 기존 키가 사용 가능하면 재사용하고, 새 발급이 필요할 때만 Apple Developer에서 생성한다. `.p8` 원문은 secret 저장소로 전달한다.
- [ ] Key ID·Team ID·환경별 앱/개발·운영 APNs 구성이 맞는지 확인한다.
- [ ] 서명/provisioning profile에 Push 권한이 반영되는지 iOS 개발자와 인수한다.

### 개발자에게 넘길 설정값

- [ ] Firebase **Project settings → General → Your apps → iOS**의 **Encoded App ID**를 확인해 URL scheme 설정용으로 전달한다.
- [ ] API key의 reCAPTCHA 호스트 허용 조건과 현재 Bundle ID/API key 자료를 함께 전달한다.
- [ ] Background Modes(fetch/remote-notification)·callback URL·swizzling 검증은 기존 앱/FCM 설정을 보존하는 구현 항목으로 연결한다.

silent APNs와 reCAPTCHA fallback 모두 성공해야 한다. iOS 알림 표시 권한을 거절해도 Phone Auth의 silent push 경로는 별개이며, 백그라운드 새로고침을 끈 실기기에서 fallback도 확인한다. Google 소셜 로그인용 reversed client ID와 Phone Auth의 Encoded App ID를 같은 값이라고 가정하지 않는다. [공식 iOS Phone Auth](https://firebase.google.com/docs/auth/ios/phone-auth)

## 10. F-07: 서버 서비스 계정·권한

Google Cloud Console **IAM & Admin → Service Accounts / IAM**에서 API 서버가 실제 사용하는 identity와 권한을 확인한다.

- [ ] FCM worker와 별도로 **Express API 실행 환경**의 ADC/credential 전달 경로를 확인한다.
- [ ] Firebase Admin을 초기화할 project ID가 같은 환경의 앱 project ID와 일치하는지 확인한다.
- [ ] `verifyIdToken(..., true)`가 요구하는 사용자 조회/폐기 확인을 위한 `firebaseauth.users.get` 권한을 부여한다.
- [ ] 관리형 역할 후보는 읽기 전용 `roles/firebaseauth.viewer`. 필요 시 승인된 custom role로 범위를 줄이고 실제 호출로 검증한다.
- [ ] 런타임에 사용자 생성/삭제/설정 변경이 필요하지 않은 현재 계약에서는 프로젝트 Owner/Editor나 Auth Admin 전체 권한을 기본 선택하지 않는다.

콘솔 설정 담당의 Auth 관리 권한과 서버 런타임 조회 권한은 분리한다. FCM 전송 권한만으로 Auth 권한도 충분하다고 가정하지 않는다. [Firebase IAM 역할](https://firebase.google.com/docs/projects/iam/roles-predefined-product), [세션/폐기 확인](https://firebase.google.com/docs/auth/admin/manage-sessions)

Google 외 서버에서 key 파일 방식이 필요하면 기존 secret 배포 절차로 read-only 마운트하고 GOOGLE_APPLICATION_CREDENTIALS 경로를 전달한다. 기존 ADC가 적절하면 새 key를 불필요하게 발급하지 않는다. 개인키는 앱/소스/문서/컨테이너 이미지에 넣지 않는다. [공식 Admin 설정](https://firebase.google.com/docs/admin/setup)

인수 증거는 Stage phone ID token 검증·폐기/비활성 거부·다른 프로젝트 거부 결과와 credential 배포/권한 적용 여부다. raw token/key는 증거에 첨부하지 않는다. 실제 호출은 서버 구현 후 수행한다.

## 11. F-08: 테스트 번호와 실문자 구분

Firebase **Authentication → Sign-in method → Phone → Phone numbers for testing**.

- [ ] Stage에 가상의 테스트 번호와 고정 코드를 등록하고 QA 담당자에게 안전하게 전달한다.
- [ ] 실제 사용자 소유 번호를 테스트 번호로 등록하지 않는다.
- [ ] 테스트 번호/코드는 코드 저장소·화면 캡처·공개 문서에 기록하지 않는다.
- [ ] 운영 프로젝트의 테스트 번호 등록은 비워 두는 이 프로젝트 정책을 적용한다.
- [ ] Auth Emulator와 앱 확인 우회 설정은 격리 local/test 전용으로 관리하고 운영 env에 남지 않게 한다.

콘솔 테스트 번호는 SMS를 보내지 않는다. 테스트 성공만으로 결제/통신사 전달/APNs/Play Integrity 준비 완료를 판정하지 않는다. 테스트 번호의 Firebase 토큰도 정상 서명될 수 있어 운영 증명 검증만으로 테스트 번호를 자동 구분한다고 가정하지 않는다. [Flutter 테스트 방법](https://firebase.google.com/docs/auth/flutter/phone-auth), [테스트 토큰 주의사항](https://firebase.google.com/docs/auth/android/phone-auth)

## 12. F-09: App Check·추가 SMS 방어 (조건부)

현재 코드에는 Phone Auth도 App Check도 구현되지 않았다. 이 절은 **콘솔 선강제 작업이 아니라 구현과 연계한 추가 보호 준비**다.

- [ ] Firebase **App Check → Apps**에서 Android/iOS 앱 등록·지원 provider/실제 SDK 버전을 확인한다.
- [ ] 기본 후보 Android Play Integrity / Apple DeviceCheck·App Attest를 개발자와 정한다. 별도 reCAPTCHA Enterprise는 지원/비용·Preview 조건을 먼저 평가한다.
- [ ] SDK 구현 뒤 **App Check → APIs → Authentication** 지표에서 정상 앱의 검증률을 확인한다.
- [ ] Stage 검증과 대응 앱 제공 후 Authentication Enforce 적용 여부를 결정한다. 지원되지 않는 앱 요청은 거부되므로 미구현 상태에서 전환하지 않는다.
- [ ] debug token은 테스트 환경만 등록하고 운영 일반 앱에 배포하지 않는다.

Auth용 App Check 통합은 공식 문서상 Pre-GA 조건을 확인해야 한다. 보호 대상에는 SMS 발송/phone sign-in 작업도 포함되지만 비용 전체 차단이나 앱 서버 proof 소비를 대신하지 않는다. [Auth App Check 통합](https://docs.cloud.google.com/identity-platform/docs/admin/app-check-integration), [Flutter 설정](https://firebase.google.com/docs/app-check/flutter/default-providers), [강제 적용](https://firebase.google.com/docs/app-check/enable-enforcement)

Identity Platform 업그레이드·reCAPTCHA SMS defense 같은 추가 기능은 현재 프로젝트 지원·추가 과금·코드 호환 확인 후 별도 채택한다. 이 가이드 때문에 일괄 활성화하지 않는다.

## 13. F-10: 운영·개인정보·장애 대응

- [ ] 번호가 Google로 전송·저장되는 처리에 대한 사전 안내/적절한 동의와 개인정보처리방침·스토어 공개 항목을 검토한다. [Firebase 공식 Phone Auth 안내](https://firebase.google.com/docs/auth/flutter/phone-auth)
- [ ] Firebase Authentication Users에 생기는 phone-only 사용자와 ShiftMate DB 계정의 관계/보관·정리 담당을 정한다. signOut이 Google의 사용자 데이터 삭제라는 의미는 아니다.
- [ ] 탈퇴/미완료 가입/번호 변경 때 정리 대상·보관기간을 확정한다. UID만 보고 다른 사용자와 관련된 Firebase 데이터를 즉시 삭제하지 않는다.
- [ ] Firebase Auth Usage 및 Cloud Billing에서 발송량·인증 성공/거부·국가별 이상/비용을 확인할 운영 주기·수신자를 정한다.
- [ ] Auth 한도/발송 제한은 [현재 공식 제한](https://firebase.google.com/docs/auth/limits)과 해당 콘솔을 함께 기록한다. 고정 TTL/오답 횟수를 콘솔에서 임의 조절하는 작업은 없다.
- [ ] 발송 급증 시 Phone 제공자 비활성 또는 지역 차단을 적용할 담당·연락/복구 기준을 정한다. 실제 UI/API·전파 상태를 확인하며 즉시 비용0을 보장하지 않는다.
- [ ] 전체 Cloud Billing 해제/프로젝트 삭제/APNs 키 폐기를 긴급 기본 수단으로 사용하지 않는다. 같은 프로젝트의 기존 FCM 등 영향이 크다.

법적 근거/정확한 보관기간은 이 문서에서 추정하지 않는다. 공개 정책 수정은 별도 검토/게시 작업이며 이번 조사에서 수행하지 않았다.

## 14. F-11: 구현 후 인수표

| 검증 | Stage | 운영 | 완료 증거 |
|---|---|---|---|
| Android 수동 코드/자동 인증 | 미확인 | 미확인 | 빌드/설치 경로·번호 마스킹·성공 시각 |
| Android Play 배포/실제 서명 | 미확인 | 미확인 | 사용 인증서와 Firebase 등록 대조 |
| Android reCAPTCHA fallback | 미확인 | 미확인 | 앱 복귀/취소·오류 처리 |
| iOS silent APNs | 미확인 | 미확인 | 유효 profile/APNs 경로 |
| iOS background refresh off/fallback | 미확인 | 미확인 | reCAPTCHA 후 앱 복귀 |
| 실제 SMS 수신·서버 proof·가입/번호 변경 | 미확인 | 미확인 | 수신/저장/재로그인 유지 |
| 다른 프로젝트 토큰/폐기 토큰 거부 | 미확인 | 미확인 | 안전한 오류 code/request_id |
| 기존 FCM/소셜 로그인 | 미확인 | 미확인 | 기존 기능 회귀 |
| 결제·KR 지역·예산 수신 담당 | 미확인 | 미확인 | 설정값 대신 적용 여부·담당 기록 |
| 운영 테스트 번호/우회 제거 | 해당 없음 | 미확인 | 운영 콘솔/env 확인 |

P0 완료 기준: 프로젝트·Phone·Blaze/지역·앱 등록/지문/APNs·서버 IAM 자료 전달. 최종 출시 기준: 위 인수표와 개인정보/운영 담당 확인 완료. 모바일 구현/Debug 빌드는 완료했으나 서버·실기기·실문자 인증은 아직 인수하지 않았다.

## 15. 전달 자료 템플릿

비밀값은 지정된 secret 저장소로만 전달하고 아래에는 참조/여부만 기록한다.

| 항목 | Stage | 운영 |
|---|---|---|
| 확인 일시/담당 | 미기록 | 미기록 |
| Project ID/앱 ID 대조 | 사용자 확인 Stage ID·앱 ID 추가 인수 | 사용자 확인 운영 ID·앱 ID 추가 인수 |
| Phone/Blaze/KR allowlist | Phone/KR 완료·Spark(사용자 확인) | Phone/KR 완료·Spark(사용자 확인) |
| Android 서명별 SHA-1/SHA-256 | 등록 여부/참조 | 등록 여부/참조 |
| iOS APNs Key ID/Team·Encoded App ID | 확인 여부/참조 | 확인 여부/참조 |
| Firebase 공개 설정의 CI 참조 | 미기록 | 미기록 |
| API service account/권한·credential 참조 | 미기록 | 미기록 |
| 예산·알림 수신/운영 중단 담당 | 미기록 | 미기록 |
| App Check 계획/강제 상태 | 미확인 | 미확인 |
| 실기기/실문자 검증 링크 | 미수행 | 미수행 |

## 16. 범위·파일 역할·롤백

Phone Auth 때문에 Firestore/Realtime Database/Storage/Cloud Functions를 새로 만들거나 Firebase 이메일 계정을 도입할 필요는 현재 ShiftMate 설계에 없다. SENS 서비스/발신번호/OTP Redis도 준비하지 않는다. 전용 Firebase Phone Number Verification 제품·MFA와 이번 Firebase Authentication Phone 제공자를 혼동하지 않는다.

- 파일 역할: 코드 외 Firebase/플랫폼/운영 준비를 담당자가 수행하고 증거를 남기는 실행 가이드.
- 의존성: ADR-0088, 기존 Flutter/서버 계획·FCM 환경 문서, 각 절의 공식 Firebase/Google Cloud 자료.
- 사용 예: F-01~F-11 담당자를 배정하고15절 표를 작성한 뒤 모바일/서버 Stage 인수 이슈에 첨부한다.
- 테스트: 공식 근거와 로컬 설정 대조·문서 링크/형식 검증. 실제 설정/결제/키 발급·앱 실행 검증은 미수행.
- 문서 롤백: 이번 파일과 연결/일지 추가분만 제거한다.
- 추후 설정 롤백: 변경 전 값을 환경별로 보관하고 변경한 Phone/지역/API key/IAM 항목만 영향 확인 후 복원한다. 결제/프로젝트·기존 APNs 키를 통째로 제거하지 않는다. 코드 강제 정책이 활성화된 뒤 인증 우회로 되돌리지 않는다.
