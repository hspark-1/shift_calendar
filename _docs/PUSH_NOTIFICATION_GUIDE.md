# Flutter FCM 푸시 알림 가이드

## 1. 지원 범위와 의존성

- iOS 15 이상
- Android API 24 이상
- Flutter 3.38.5 / Dart 3.10.4
- `firebase_core 4.12.1`
- `firebase_messaging 16.4.3`
- `flutter_local_notifications 22.2.0`
- `package_info_plus 10.2.1`
- `uuid 4.5.2`
- 설치 UUID 보관용 `flutter_secure_storage 10.3.1`

버전은 `pubspec.yaml`에 정확히 고정합니다.

## 2. Firebase 환경 분리

Debug 빌드는 Stage Firebase와 Stage API를, Profile/Release는 Production Firebase와 Production API를 사용합니다. application ID와 bundle ID는 모두 `com.hspark.shiftmate`로 유지하므로 두 환경 앱을 같은 기기에 동시에 설치하는 것은 지원하지 않습니다.

`FirebaseEnvironmentOptions`는 빌드 모드와 아래 `--dart-define`을 조합해 명시적 `FirebaseOptions`를 만듭니다.

```text
FIREBASE_STAGE_PROJECT_ID
FIREBASE_STAGE_MESSAGING_SENDER_ID
FIREBASE_STAGE_ANDROID_API_KEY
FIREBASE_STAGE_ANDROID_APP_ID
FIREBASE_STAGE_IOS_API_KEY
FIREBASE_STAGE_IOS_APP_ID
FIREBASE_STAGE_STORAGE_BUCKET

FIREBASE_PROD_PROJECT_ID
FIREBASE_PROD_MESSAGING_SENDER_ID
FIREBASE_PROD_ANDROID_API_KEY
FIREBASE_PROD_ANDROID_APP_ID
FIREBASE_PROD_IOS_API_KEY
FIREBASE_PROD_IOS_APP_ID
FIREBASE_PROD_STORAGE_BUCKET
```

실제 값은 Firebase Console에서 각 환경 앱을 등록한 후 로컬/CI secret으로 주입합니다. 저장소에는 임의 project ID, API key, `google-services.json`, `GoogleService-Info.plist`, APNs key를 커밋하지 않습니다. 현재 구현은 명시적 `FirebaseOptions`로 native default app을 초기화하므로 설정이 없으면 앱은 정상 실행하되 push 기능만 비활성화합니다.

## 3. 앱 흐름

```text
main
  → Firebase 환경 설정이 있으면 initialize + background handler 등록
  → AuthWrapper
     → 로그인 완료: PushCoordinator.startAuthenticated()
        → OS 알림 권한 요청
        → iOS APNs token 준비 확인
        → FCM token + 설치 UUID + 앱 버전 PUT /devices/current
        → onTokenRefresh / onMessage / onMessageOpenedApp 구독
     → foreground 복귀: 5분 debounce 기기 동기화
     → 로그아웃: 구독·pending route·중복 ID 상태 해제
```

기기 동기화 실패는 로그인 성공을 되돌리지 않습니다.

## 4. 설치 UUID와 기기 API

`InstallationIdService`는 RFC 4122 UUID를 secure storage에 생성·보관합니다. 손상된 값은 새 UUID로 교체하며 로그아웃 뒤에도 유지합니다.

```http
PUT /api/v1/devices/current
Authorization: Bearer <access_token>
```

```json
{
  "installation_id": "<uuid>",
  "platform": "ANDROID | IOS",
  "provider_target": "<FCM token> | null",
  "push_permission_enabled": true,
  "app_version": "1.0.0+1"
}
```

권한 거부나 token 미발급도 `null/false`로 동기화합니다. 로그아웃은 기존 body에 `installation_id`를 함께 보내며, 설치 UUID 자체는 삭제하지 않습니다.

## 5. 수신과 UI 상태

### Foreground

- Firebase의 OS 자동 foreground 표시를 끔
- schema v1, `destination=NOTIFICATIONS` payload만 수용
- 최근 `notification_id` 50개를 SharedPreferences에 저장해 중복 표시 방지
- 알림 미읽음 count를 새로고침
- `shiftmate_high` high-importance 채널과 기본 sound로 local notification 표시
- local notification 탭은 `NotificationPage`로 이동

### Background/종료

- top-level `firebaseMessagingBackgroundHandler`
- `getInitialMessage()`로 종료 상태 탭 처리
- `onMessageOpenedApp`으로 background 탭 처리
- 세부 도메인 화면으로 직접 가지 않고 항상 `NotificationPage`로 이동

`rootNavigatorKey`와 pending destination 상태를 사용합니다. 로그아웃 상태나 신규 사용자 프로필 설정 중 탭했다면 인증과 프로필 완료 후 이동합니다.

## 6. 네이티브 설정

### iOS

- Podfile, Runner project, RunnerTests deployment target: 15.0
- `Runner.entitlements`: `aps-environment=$(APS_ENVIRONMENT)`
- Debug: development APNs, Profile/Release: production APNs
- `Info.plist` background modes: `remote-notification`, `fetch`
- Firebase Messaging method swizzling은 비활성화하지 않으므로 기본 활성
- Xcode Signing & Capabilities에서 Push Notifications와 Background Modes가 실제 provisioning profile에 포함되어야 함

### Android

- `minSdk=24`. 계획의 API 23은 고정 의존성 `flutter_local_notifications 22.2.0`이 공식적으로 API 24 이상을 요구하므로 적용할 수 없습니다. manifest 강제 override는 사용하지 않습니다.
- `POST_NOTIFICATIONS` 선언, Android 13 이상은 Firebase permission 요청을 통해 런타임 권한 처리
- manifest 기본 채널: `shiftmate_high`
- channel importance high, 기본 sound

## 7. 파일 역할

- `lib/core/push/firebase_environment_options.dart`: 빌드 모드별 Stage/Production 옵션 선택
- `lib/core/push/installation_id_service.dart`: 설치 UUID 영속화
- `lib/core/push/device_remote_datasource.dart`: 인증 기기 API 호출
- `lib/core/push/push_coordinator.dart`: 권한/token/lifecycle/수신/local banner/중복 제거
- `lib/core/push/push_providers.dart`: coordinator와 pending navigation Riverpod 연결
- `lib/main.dart`: Firebase 초기화, background handler, 인증·lifecycle·root navigation 조정
- `test/core/push/**`: 설치 UUID와 payload/중복 제거 단위 테스트

## 8. 테스트와 실기기 인수

```bash
flutter pub get
flutter analyze --no-fatal-infos lib/main.dart lib/core/push test/core/push
flutter test test/core/push
```

Stage 실기기에서는 Android/iOS 각각 권한 허용/거부, token refresh, foreground local banner, background/종료 탭, 로그인 대기 route, logout 해제, 최신 활성 기기 전환, 6개 알림 타입을 확인합니다. APNs/FCM 실제 전달은 Firebase 프로젝트·APNs key·service account와 실기기가 필요한 외부 인수 단계입니다.

## 9. 롤백

서버 enqueue/worker를 먼저 끕니다. 앱은 Firebase 설정이 없거나 초기화가 실패하면 push만 비활성화하고 기존 인증·인앱 알림을 유지합니다. 완전 코드 rollback은 `core/push`, Firebase 의존성, `main.dart` 연결과 네이티브 entitlement/channel 설정을 이전 버전으로 되돌립니다.
