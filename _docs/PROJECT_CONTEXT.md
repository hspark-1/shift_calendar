# 프로젝트 컨텍스트

## 작업별 커밋 정리·검증·푸시 (2026-11-16)

- 사용자 요청으로 누적 변경을 그룹 nullable·피커·일정 편집/삭제/캘린더 배치·색상/헤더·친구/그룹 탐색·설정·웹 정책·Google 탈퇴·출시 빌드·UIScene·방향 설정·네이버 오류·SDK·로컬 API의14개 커밋으로 분리했다. 원격의 기존 Google 전화번호850e45d를 보존하며 각 작업에 관련 컨텍스트·ADR·일지를 함께 넣었다. 이 최종 기록과 기존 정책 설명 정합성은 후속 문서 커밋으로 보존한다.
- 검증: 전체 Flutter559 pass/기존 skip1, 실제 그룹 API/P1 활성 회귀45 pass, 분석 error/warning0·기존 미변경 naming info26건, Dart72개 포맷 변경0건·측정JSON9개/PNG232개 기본 구조·diff 검사 통과. 초기 코드/테스트/native/package 변경 보존을 patch check로 확인했다. vendor 원본의 줄 끝 공백만 정리한 예외와 출처는 ADR-0085/내부 README를 따른다.
- 푸시/영향:14개 작업 커밋을 origin/develop에 일반 push했고4d5edf1에서 로컬/원격 일치를 확인했다. 최종 문서 커밋도 같은 브랜치에 추가 push한다. 새 기능 구현·서버/스토어 배포·main 병합·실기기/Release 재빌드는 이번 작업에 없다. 최종 커밋과 상세 명령/한계는 WORKLOG를 따른다.
- 역할/사용 예/롤백: 이번 신규 영구 파일은 없으며 기존 PROJECT_CONTEXT·WORKLOG의 정합성만 갱신한다. 임시 분리 스크립트/로그/원본 patch는 /private/tmp/shiftmate-commit-split-20261116에 있으며 Git/Python3·기존 Flutter SDK에 의존한다. 일반 검증 명령은 WORKLOG를 따르며 이 기록을 근거로 작업 커밋을 선택해 git revert한다.

## 네이버 탈퇴 후 반복 재가입의 네이티브 SDK 수정 (2026-11-16, ADR-0085)

- 실제 재현: 사용자 탈퇴 성공 확인 후 NaverLoginService55행에서 sdk_status=error/Access Token 없음/Code=-1005/네이버 token endpoint를 확인했다. 이번 실패는 Repository126행의 SDK await에서 발생해 서버 로그인129행 이전이다. 서버 삭제 대기409와 이 SDK 실패를 구분한다.
- 공식 근거: 네이버 공식 issue6과5.2.0 릴리스는 네이버앱 복귀 직후 -1005를 다룬다. 기존iOS SDK5.1.0→수정포함5.2.1로 고정한다. plugin4.0.0이Flutter>=3.44를 요구하므로 Flutter3.38.5에서 공식3.0.4의 Dart/Android/Swift bridge를 보존한 path dependency를 사용한다. 앱의 기존 최소iOS15와 일치한다.
- 새 third_party/naver_login_flutter의 역할/의존성/사용 예는 내부 README.shiftmate.md에 기록한다. lib/**는Dart API/MethodChannel/DTO, ios/**는 podspec/SPM/Swift bridge·privacy manifest, android/**는 기존 Gradle/R8/manifest/Kotlin bridge, bin/**는 기존 선택 설정CLI, LICENSE/pubspec/analysis_options/.gitignore는 배포 출처·로컬 패키지/분석/생성물 제외다. 정리 전 원본 소스21개 동일 확인. 커밋 정리 과정에서 Android Gradle·Swift 3파일의 줄 끝 공백14곳만 제거했으며 줄 끝 공백을 제외한 원본 소스는 동일하다. iOS15/SDK5.2.1 및 메타데이터 변경 외 동작 수정은 없다. 원본 샘플·standalone Gradle wrapper·Android 테스트는 앱 빌드 대상이 아니어서 제외했다. native framework/credential은 저장소에 넣지 않는다.
- 사용: `flutter pub get`, `cd ios && pod update NidThirdPartyLogin naver_login_flutter`, 기존 방식의 전체 iOS build/설치. Dart 호출은 기존 FlutterNaverLogin.logIn을 유지한다. 오류 안내는ADR-0084 그대로이며 자동 인증 반복·서버/DB/탈퇴 worker·Flutter SDK/환경·화면을 변경하지 않는다. 의존성 변경은 네이버 path/Pod lock에 한정한다.
- 검증 완료: 인증125개·전체 analyze error/warning0(기존 naming info26개)·실제 iOS Debug build 및 앱의 SDK5.2.1/iOS15를 확인했다. 같은 iPhone의 새 로컬 디버그 앱 실행 후 사용자가 재가입 문제 해결을 확인했다. 다른 기기/여러 회차/Release·스토어 배포는 별도다. 상세 경과는 WORKLOG를 따른다.
- 상태/롤백:  구현/모의 테스트 통과를 실제 재가입 성공으로 표현하지 않는다. 이전 hosted3.0.4와 lock/Nid5.1.0을 복구하고 전체 rebuild하면 롤백되며 기존 -1005도 돌아올 수 있다. 향후 Flutter>=3.44 업그레이드 때 공식 플러그인으로 복귀한다.

## 네이버 재가입 SDK 네트워크 오류 처리 (2026-11-16, ADR-0084)

- 사용자 캡처는 nid.naver.com/oauth2.0/token의 NSURLErrorDomain -1005 연결 유실이다. 서버409와 발생 경계가 다르다. 설치 naver_login_flutter3.0.4/NidThirdPartyLogin5.1.0의 native requestLogin 실패→error.localizedDescription→errorMessage→Dart service→Repository→AuthNotifier→LoginPage 오류 다이얼로그 경로를 직접 확인했다. -1005는 진행 중 연결 유실이라는 Apple QA1941 설명과 일치한다. 네트워크가 끊긴 이유·탈퇴와의 인과관계는 캡처만으로 확정하지 않는다.
- **Behavior change**: 기존 NaverLoginService는 SDK error 결과/PlatformException을 공통 ApiException으로 변환한다. 네트워크는 NAVER_NETWORK_ERROR와 “네이버에 연결할 수 없습니다. 네트워크 상태를 확인한 후 다시 시도해주세요.”, 취소는 NAVER_LOGIN_CANCELLED, 빈 토큰은 NAVER_TOKEN_UNAVAILABLE, 기타 오류는 NAVER_LOGIN_FAILED다. SDK 진단 문자열/URL/token 원문을 UI로 전달하지 않는다. 로그인 실패 시 기존 Provider/페이지가 로딩을 해제하고 수동 재시도를 허용한다.
- 흐름/범위: 로그인 SDK 경계의 오류만 수정하며 성공 token 교환→서버409/프로필 분기·라우트/권한·Riverpod 상태 수명·Dio/interceptor·가입/탈퇴 정책은 유지한다. 새로운 자동 인증/토큰 교환 재시도·로그아웃/연결 해제·SDK/lock/native 설정/의존성/env 변경은 없다. 오류 원문을 저장하거나 새 로그로 출력하지 않는다.
- 파일 역할/사용 예: 기존 lib/features/auth/data/services/naver_login_service.dart가 ApiException에 의존해 SDK 실패를 분류한다. 기존 naver_login_service_test.dart는 SDK 결과/PlatformException 주입, login_page_test.dart는 MethodChannel→실제 서비스→Provider→다이얼로그의 원문 비노출·로딩 해제·수동 재시도를 검증한다. `flutter test test/features/auth`로 실행한다. 새 영구 파일은 없다.
- 검증/롤백: 수정 전 실제 서비스에 동일 문자열을 주입해 원문 전달을 확인했다. 결과/실행 한계는 WORKLOG를 따른다. 원문 비노출·안내 개선과 실제 네트워크 원인 해결/실계정 재가입 성공은 구분한다. 이번 서비스·회귀·문서 diff만 되돌리며 이전 Google/네이티브/배포/기타 미커밋 작업은 보존한다. 앱 재실행/빌드에 수정 소스를 반영해야 한다.

## iPhone·iPad 세로 방향 고정 (2026-11-16, ADR-0083)

- 사용자 확정/Behavior change: iPhone과 iPad 모두 portrait만 지원한다. 기존 `ios/Runner/Info.plist`의 UISupportedInterfaceOrientations와UISupportedInterfaceOrientations~ipad를 UIInterfaceOrientationPortrait 한 개로 제한하고 UIRequiresFullScreen=true를 추가했다. landscape·upside-down을 제거했다. 기존 UIApplicationSceneManifest/FlutterSceneDelegate·기기군[1]·최소iOS15·Dart route/state/API/Android·SDK/lock은 유지한다.
- 창 동작: 최신OS의 resizable 환경에서 orientation 배열만으로 고정 창 크기를 보장할 수 없으므로 Apple 공식 호환 설정을 사용한다. UIRequiresFullScreen은deprecated이며 iOS27에서는 방향을 존중하는discrete resize 방식이고 창 손잡이/resize 자체의 완전 차단이 아니다. 이전iPad 멀티태스킹 제한과 미래OS 지원 변화는 ADR-0083의 재평가 대상이다.
- 검증: Release AOT 빌드6 재빌드(17.5초)·서명·bundle의두 방향 배열/scene/profile·plist lint/공백 검사 통과. 연결된 iPadOS26.5.2에 업데이트 설치/실행 후 사용자가 가로 resize에서도 세로 유지됨을 확인했고 캡처의 세로 로그인 UI/PID717도 확인했다. iPhone 실제 회전 및 심사OS27.3 실물resize는 이번에 수행하지 않았다. 앞선 로그인/세션 복원 기록과 이번 방향 검증을 구분한다.
- 파일 역할/의존성/사용 예: 기존Info.plist가 네이티브 방향/호환 모드를 선언한다. 새 영구 파일은 없다. 동일 `.env`/개발 서명의 `build/ios/Release-iphoneos/Runner.app`을 기존USB 절의 devicectl install/launch 명령으로 재현한다. `/private/tmp/shiftmate_portrait_20261116/`의 설정/앱 백업·빌드/설치/실행검증·캡처 역할은 WORKLOG를 따른다. 개인정보가 있을 수 있는 기기 자료는Git에 추가하지 않는다.
- 배포/롤백: pubspec은5, 로컬USB 앱만CLI override6이다. 기존 App Store IPA/Archive는수정전5이므로 재제출용 새 Archive/IPA가 필요하다. 이번orientation 배열/UIRequiresFullScreen만 변경 전값으로 복원하면 롤백된다. UIScene 크래시 수정과 사용자 데이터는 유지한다.

## USB iPad Release 실행 확인 (2026-11-16)

- 사용자 요청에 따라 개발자 모드를 켠 iPad Pro12.9형5세대 / iPadOS26.5.2에 현재 UIScene 수정본을 개발 서명의 Release AOT 1.0.0(6)으로 설치했다. CLI 빌드 번호만6이며 pubspec은1.0.0+5, 기존 App Store Archive/IPA는 빌드5 그대로다. **현재 기존 IPA를 다시 업로드하면 UIScene 수정본이 아니다.** 재제출용 새 Archive/IPA 생성이 필요하다.
- 동작 확인: 앱 시작→사용자 직접 네이버 인증→캘린더 표시→devicectl 완전 종료/새 프로세스 재실행→로그인 상태와 실제 캘린더 복원을 확인했다. 첫PID571, 재실행PID668이며 캡처/기기 앱 목록으로 설치 버전6을 확인했다. 앱/서버 데이터 삭제와 소스/SDK/lock·기기군 변경은 없다.
- 빌드/설치 규칙: 기존 `.env`의 운영 define으로 `flutter build ios --release --no-pub --dart-define-from-file=.env --build-name=1.0.0 --build-number=6` 실행 후, 신규 iPad가 빠진 일반 개발 profile을 대상UDID의 `xcodebuild build ... -destination 'id=<UDID>' -allowProvisioningUpdates -allowProvisioningDeviceRegistration`로 갱신했다. 검증한 `build/ios/Release-iphoneos/Runner.app`만 devicectl로 설치한다. 단일FlutterSceneDelegate·AOT instruction·서명/profile 기기 포함·기존 Archive/IPA 보존을 확인했다.
- 산출물 역할/의존성/사용 예: 위 Runner.app은USB 실기기용 개발 서명 AOT 앱이며 현재 소스·.env define·Xcode 개발 profile에 의존한다. `xcrun devicectl device install app --device <UDID> build/ios/Release-iphoneos/Runner.app`, 이어 `device process launch --device <UDID> --terminate-existing com.hspark.shiftmate`로 재현한다. 로컬 `/private/tmp/shiftmate_ipad_release_20261116/`의 빌드 로그·검증/설치/실행JSON·재실행 캡처 역할은 WORKLOG를 따른다. 계정/기기 진단 자료는 Git에 추가하지 않는다.
- 한계/롤백: 개발 서명이므로 APNs는development며 App Store Distribution과 다르다. 심사OS27.3 실기기·나머지OAuth·푸시·홈 복귀·새IPA/업로드/재제출은 미완료다. 기존iOS27.0 시뮬레이터 결과와 이번26.5.2 실물 결과를 구분한다. 설계 변경/신규 영구 소스 파일은 없다. 이번 로컬build6/문서만 제거하면 작업 롤백되며 소스와 사용자 데이터는 유지한다. 기기 앱 복원이 필요하면 이전 개발 서명 앱을 재설치한다.

## 빌드 5 실행 크래시 원인과 UIScene 전환 (2026-11-16, ADR-0082)

- 원본 근거: 사용자가 제공한 Downloads의 `crashlog-7C82B0B2-7971-4881-86D0-C4B22FD5FBD1.ips`와 `crashlog-31BF3142-134C-459B-8D43-0F43E155D995.ips`는1.0.0(5)/iPad15,3/iPhone OS27.3 Beta(24C5037i)다. 두 건 모두 main thread의 `___UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption_block_invoke`에서 EXC_BREAKPOINT/SIGTRAP이며 Runner UUID는 보관 Archive와 일치한다. 원본은 읽기 전용으로 유지한다. 아래 로그 미확보 절은 첨부 전의1차 조사 이력이다.
- 심볼리케이션: Xcode CrashSymbolicator.py와 기존dSYMs로 두 보고서의 Runner 프레임을 AppDelegate.main까지 복원했다. `UIKitCore +3526812` 시스템 프레임1곳은 해당OS 심볼이 없어 남았으며 완전 심볼리케이션이라고 표시하지 않는다. 크래시 최상단 검사 함수는 원본부터 식별된다. Dart App.framework가 로드되기 전 네이티브 시작 단계에서 종료되었다.
- 재현: 수정 전 네이티브 앱을iOS27.0/iPad Air11-inch(M4) 시뮬레이터에서 실행해 `Application failed to launch: UIScene life cycle is required for apps built with this SDK`를 확인했다. 실제 심사27.3/M3 기기와는 구분한다.
- **Behavior change**: `Info.plist`의 UIApplicationSceneManifest → 단일 UIWindowScene / FlutterSceneDelegate / Main storyboard → implicit Flutter engine → AppDelegate.didInitializeImplicitFlutterEngine(engine_bridge) → GeneratedPluginRegistrant → 기존 Dart main 순서로 시작한다. Flutter3.38.5 내장 API와 공식 migration을 사용한다. FlutterAppDelegate.super의 앱 이벤트 전달은 유지한다. 기기군[1]·최소iOS15·SDK/lock/env/버전·Dart route/provider/API/DB 변경은 없다.
- 파일 역할/의존성/사용 예: 기존 `ios/Runner/Info.plist`는UIKit Scene 설정, `ios/Runner/AppDelegate.swift`는엔진 생성 후 플러그인 등록을 담당한다. 별도SceneDelegate/영구 신규 파일은 없다. 기존 `ios/RunnerTests/RunnerTests.swift`의 자리표시자 테스트를 실제 UIWindowScene·FlutterViewController·주요8개 플러그인 등록 검사로 교체했다. `xcodebuild test -workspace ios/Runner.xcworkspace -scheme Runner -destination 'platform=iOS Simulator,id=<UDID>' -only-testing:RunnerTests`로 실행한다. define/빌드 경로는 기존iOS 실행 규칙에 맞춘다.
- callback 검토: 설치된 네이버/Google 플러그인은addSceneDelegate로등록한다. Kakao의기존AppDelegate openURL은Flutter3.38.5 엔진의sceneFallbackOpenURLContexts가 전달한다. 수동중복 전달/패키지수정은 추가하지 않았다. 실제OAuth/알림/복귀 인수는 별도로 남는다.
- 검증: 동일 iOS27.0 iPad 시뮬레이터의 수정 후 네이티브 테스트 1개(실제 Scene/엔진과 8개 플러그인 등록) / 0 failures, Dart 시작과 version-policy 응답200을 확인했다. 관련 Flutter 시작/푸시/공휴일/업데이트 회귀 16 pass, Info.plist lint·코드/문서 공백 검사 통과. 최초 홈 화면 캡처는 앱 화면 검증 증거로 사용하지 않는다. 전체 명령/자료와 디스크 부족 중 임시 빌드 캐시 정리 이력은 WORKLOG를 따른다.
- 배포/롤백: 심사 OS27.3 Release 실기기·실계정 로그인/푸시·새 IPA/업로드/재제출은 아직 미완료다. 기존 빌드5 Archive/IPA를 보존한다. 이번 AppDelegate/scene manifest/네이티브 테스트·문서만 되돌릴 수 있으나 원래 크래시도 재발한다.

## 빌드 5 App Review 실행 크래시 통지 (2026-11-16)

- 사용자 전달 심사 메시지: 제출 ID `b445e709-c2ae-4c17-ba7d-f3f476305e13`, 버전1.0(5), iPad Air 11-inch(M3) / iPadOS27.3에서 실행 직후 크래시로 Guideline2.1(a) 검토 불가. 포털을 직접 조회한 결과는 아니다. 아래11-14의 패키징 검증 통과는 실행 크래시 해결을 의미하지 않는다.
- 로컬 근거: 보관 Archive의1.0.0(5)·SDK27.1·최소iOS15·UIDeviceFamily=[1], IPA24,755,597bytes·기존SHA-256 일치·flutter_assets/.env 존재를 다시 확인했다. Runner UUID=`F20B9F47-6145-3218-92C9-D9CCB7DFAB87`, App UUID=`1A05136D-860B-3261-844C-163EFEBACF84`이며 각 바이너리와 기존dSYM이 일치한다. 역할/의존성/사용 예는 아래 빌드5 절과 동일하다. 해당 Archive를 보존하고 원본 심사 로그의UUID와 대조해야 한다.
- 조사 범위/한계: AppDelegate의 플러그인 등록과main의env→Kakao→locale/timezone→공휴일 캐시→Firebase→runApp 경로를 읽었다. 대화에 원본 로그가 없고 작업 폴더 전체의.ips/.crash 검색 결과도0건이다. 종료 스택·예외·원인은 미확정이며 코드/설정/버전은 변경하지 않았다. 로컬 기기 목록에 심사OS27.3은 없으며 이번에 앱 실행·실기기 설치·심볼리케이션은 수행하지 않았다.
- 후속: 원본 로그 확보→UUID 대조/심볼리케이션→재현/수정→iPad 호환 실행을 포함한Release 실기기 확인→새 빌드 제출. ADR-0030의iPhone 전용은iPad 호환 실행 차단을 뜻하지 않는다. 설계/정책 변경과 신규 파일은 없으며 롤백은 이번 조사 문서 추가분만 제거한다.

## 심사 재제출용 iOS 빌드 5 (2026-11-14)

- 사용자 요청으로 현재 작업 트리의 기존 미커밋 변경을 포함한 App Store용 1.0.0(5)를 생성했다. 현재 `pubspec.yaml`은 `1.0.0+5`, Release API 호환 번호는 기존 `1`이다. 빌드 번호 증가 외 이번 작업의 앱 기능/설계 변경은 없고 새 ADR은 추가하지 않는다. 아래 빌드 4 절은 당시 이력이다.
- 실행: `flutter build ipa --release --no-pub --dart-define-from-file=.env --build-name=1.0.0 --build-number=5 --export-method=app-store`. Flutter3.38.5/Dart3.10.4·Xcode27.1/iOS SDK27.1·기존 lock/native 설정을 사용했다. Release 운영 API·Production Firebase/OAuth 및 기존 그룹/Apple 활성화 define을 확인했다. 서버 배포 상태/실계정 인수를 새로 검증한 것은 아니다.
- 산출물 역할/의존성/사용 예: `build/ios/archive/Runner.xcarchive`는 Release 앱·Runner/App dSYM·메타데이터이며 Xcode Validate/배포에 사용한다. `build/ios/ipa/ShiftMate.ipa`는 위 Archive와 App Store provisioning에 의존하는 Apple Distribution 서명 IPA로 Transporter 업로드에 사용한다. `ExportOptions.plist`는 재내보내기 설정, `DistributionSummary.plist`/`Packaging.log`는 로컬 패키징 진단 자료다. 비밀값이 있을 수 있는 진단 파일과 환경·빌드 산출물은 커밋하지 않는다. 기존 빌드4의 동일 산출물은 `build/ios/releases/1.0.0-4/ipa/`·`Runner.xcarchive`에 보존했다.
- 검증: 전체 테스트551 pass·기존 skip1, 전체 analyze error/warning0·미변경4파일의 기존 naming info26건. IPA ZIP CRC·deep/strict 배포 서명·App Store profile·production APNs/Apple 로그인·URL scheme 치환·운영 API/Firebase/OAuth·Stage/로컬 API 부재·1.0.0(5)/Bundle ID/iPhone전용/iOS15/SDK27.1 검증을 통과했다. IPA 24,755,597bytes, SHA-256 `23d38e5dbf81bd4a268785f5608c46d81d7d9d92588d8c05fc7642caa2295204`. 기존 기본 LaunchImage placeholder 안내1건은 유지한다.
- 상태/영향/롤백: 로컬 빌드 생성/검증 완료이며 업로드·Connect 처리/빌드 선택·심사 재제출·실기기 인수는 수행하지 않았다. 기존 빌드4 포털 상태도 재조회하지 않았다. 이번 버전5·문서 추가분만 되돌리고 새 산출물을 제거하면 롤백된다. 기존 미커밋 소스와 보존한 빌드4는 유지한다.


## Google 사진 수집 중단·선택 전화번호 (2026-11-13)

- **Behavior change / ADR-0081**: GoogleLoginService는 ID Token과 선택 전화번호 access token을 GoogleLoginCredential로 반환한다. NativeGoogleSignInSdk는 authenticate 계정의 authorizationClient에서 기본 OIDC/user.phonenumbers.read 승인을 확인하고 필요하면 동의를 요청한다. 기본 인증 취소는 기존 취소, 선택 동의 취소/권한 오류·미지원은 access_token=null로 기본 로그인을 유지한다.
- 흐름: 로그인 탭 → SDK 인증/선택 동의 → Repository → AuthRemoteDataSource.loginWithGoogleIdToken(id_token, google_access_token: ...) → 기존 /auth/google/token → 서버의 userinfo.sub 대조/People API PROFILE phoneNumbers → User.phone → 기존 ProfileSetupPage 미리 채움이다. SDK 사진을 읽거나 서버에 전달하지 않으며 신규 서버 사진은 null이다. 기존/업로드 사진과 기존 번호는 보존한다.
- 상태/UX: Google 토큰은 교환 요청까지 메모리에만 두고 앱 JWT만 저장한다. 로그아웃/해제 시 SDK 계정 참조를 지운다. 선택 정보가 없으면 기존 직접 입력·null 사진 기본 아바타를 사용한다. route/접근권한·Riverpod 수명·공용 위젯/테마·로딩/오류 화면은 변경하지 않는다. 서버401/409는 기존 ApiException 처리와 실패 시 Google 로컬 세션 정리를 따른다.
- 파일 역할/의존성/사용 예: 기존 google_login_service.dart의 GoogleLoginCredential·authorizePhoneAccessToken, auth_repository_impl.dart의 credential 전달, auth_remote_datasource.dart의 선택 body 필드와 기존3개 테스트/가입 위젯 회귀를 수정했다. 고정 google_sign_in7.2.0·기존 Dio/User 모델을 사용하며 새 파일/패키지/앱 env/DB migration은 없다. 실제 body는 `{id_token, access_token?}`이며 구형 ID Token 전용 요청도 지원한다.
- 계약·배포/롤백: `_docs/GOOGLE_SIGN_IN_SERVER_GUIDE.md`의 현행 절과 인접 서버 가이드 상단을 따른다. 서버를 먼저 배포한 뒤 앱을 재빌드한다. 실제 Google iOS/Android 동의·번호 수신/취소·가입·로그아웃/탈퇴는 Stage 인수 대상이다. 최종 WORKLOG의 로컬 검증과 구분한다. rollback은 이번 Google 변경만 복구하고 기존 미커밋 변경·사용자 번호/사진을 유지한다.

## Google 회원 탈퇴 iOS HTTP 400 보완 (2026-11-13)

- 확인된 경로: SettingsPage → AuthNotifier → AuthRepositoryImpl의 Google disconnect → Naver disconnect → 서버 DELETE. 기존 Google SDK 예외는 서버 요청 전 전파되고 AuthNotifier가 toString으로 원문을 표시한다. 보관한 실제 수정 전 서비스에 제보와 같은 PlatformException을 주입해 원문 전파를 재현한다. 캡처만으로 실제 Google 응답 body·토큰 만료/폐기 여부는 확정할 수 없다.
- SDK 근거: 고정 google_sign_in7.2.0/google_sign_in_ios6.3.0 및 설치된 GIDSignIn.m의 disconnect는 현재/키체인 토큰으로 revoke하고 선행 갱신하지 않는다. attemptLightweightAuthentication은 iOS restorePreviousSignIn으로 이어져 필요 시 토큰을 갱신한다. Google 공식 [세션 복원](https://developers.google.com/identity/sign-in/ios/sign-in)·[연결 해제](https://developers.google.com/identity/sign-in/ios/disconnect) 문서도 함께 확인했다. 사용자 기기의 원격 token 상태를 직접 조회하지 않았다.
- **Behavior change / ADR-0080**: iOS는 연결 해제 직전 SDK 세션을 복원·갱신하고 계정 ID가 서버 User.google_id와 같은지 확인한다. 세션 부재/계정 불일치 또는 원시 com.google.HTTPStatus: 400은 새 GoogleAccountDeletionReauthenticationRequiredException → reauthentication_required → 기존 다시 로그인 alert로 연결한다. Android는 기존 직접 disconnect를 유지한다. SDK 복원으로 앱 JWT auth_time을 새로 만들거나 서버 최근 로그인 조건을 우회하지 않는다.
- 에러/UX: PlatformException·GoogleSignInException은 GoogleLoginUnavailableException의 사용자용 메시지로 변환한다. 탈퇴의 예상 밖 오류도 고정 한국어 문구로 표시한다. 서버 ApiException 메시지/request_id 처리·202/401/진행 중 세션 정리·계정 Provider 수명·확인/취소/재로그인 후 재확인은 유지한다. 실패를 외부 연결 해제 성공으로 처리하지 않는다. 서버 설계의 내부 삭제/외부 해제 분리와 FE ADR-0021의 선행 해제 조건 차이는 기존 PRIVACY_FE_CONTRACT_PROPOSAL의 미합의 영역이며 이번에 사전 해제 우회 정책을 새로 만들지 않았다.
- 파일 역할/의존성/사용 예: 기존 google_login_service.dart의 SDK 경계에 restoreAccountId()를 추가하고 disconnect(expected_google_id: user.google_id!)로 호출한다. 기존 repository는 서버 프로필 ID를 주입하며 AuthNotifier는 타입을 UI 결과로 매핑한다. 신규 영구 파일/패키지·공용 위젯/테마/라우트/analytics·서버 API/DB/env 변경은 없다. 기존 서비스/저장소/provider/설정 테스트에 만료 모의 세션·다른 계정·400·오류 비노출·재로그인 이동 회귀를 추가했다.
- 검증/한계/롤백: 최종 WORKLOG를 따른다. 실계정 Google revoke·실기기 탈퇴/앱 재실행 인수·배포는 수행하지 않았다. 수정 전 파일은 /private/tmp/shiftmate_google_deletion_20261113/before에 보관했으며 이번 인증/테스트/문서 diff만 복구한다. Flutter 저장소에 origin/main만 있어 기존 main 기반으로 로컬 develop을 만들고 미커밋 작업을 보존했다. 커밋/푸시는 하지 않는다.

## 친구 추가는 정확 일치 계정 한 명을 확인한다 (2026-11-13)

- 높이/제스처 최신 정책: ADR-0079(ADR-0078 후속). 기본/최대 두 높이를 유지하며 위48px 이상은 최대, 최대에서 아래48px 이상은 먼저 기본으로 접고 기본에서 아래120px 이상은 닫는다. 드래그 전후 애니메이션을 유지해260ms로 보간하며 중간 높이를 저장하지 않는다.
- 후속 정리: 사용자 요청으로 기본 가입 정보 입력 안내와 버튼 아래 수락 안내를 제거했다. 안내 자리의 여백도 제거하며 입력 오류/검색 실패/요청 상태는 유지한다.
- 현행 정책: ADR-0077이 ADR-0076의 화면 배치를 대체한다. 이메일/전화번호는 중복 불가능한 식별자이며 정확히 일치하는 계정 한 명을 확인한다. 입력 폼 하나·중앙 프로필 하나·주요 버튼 하나로 구성하고 내용만큼 시트가 높아진다.
- 상태별 주요 버튼은 친구 찾기 → 친구 요청 보내기 → 완료다. 입력을 수정하면 프로필/이전 오류를 지우고 친구 찾기로 복귀한다. 기존 친구·보낸 요청은 상태와 완료, 받은 요청은 기존 알림 탭으로 연결한다. 상세 크기·수명/검증·파일 역할/렌더 명령·롤백은 아래 ‘친구 추가 검색 흐름’ 절을 따른다. API/DB/인증·정규화/응답 최신성·공유 권한과 provider 수명 계약은 유지하며 신규 파일/패키지는 없다.

## 친구·그룹 빈/짧은 목록 당겨 새로고침 (2026-11-12)

- 현재 정책/Behavior change: ADR-0075. 친구 목록과 실제 그룹 목록은 로딩/오류/빈/정상 상태 모두 동일한 CustomScrollView와 CupertinoSliverRefreshControl을 유지한다. BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics())로 내용이 없어도 여백에서 아래로 당길 수 있다. 기존 목록 조회를 재호출하며 요청 중에는 당김의 추가 조회를 실행하지 않는다.
- 역할/의존성/사용 예: 기존 `lib/core/widgets/scrollable_centered_body.dart`의 공용 프레임을 `SliverCenteredBody(children: [...])`로 전환했다. Flutter widgets의 SliverFillRemaining(hasScrollBody:false)·16px Padding·중앙 Column에 의존하며 CustomScrollView.slivers 안에서 사용한다. 예전 ScrollableCenteredBody의 다른 Dart 호출부가 없음을 검색 확인하고 중첩 SingleChildScrollView 구현을 제거했다. 신규 파일/의존성은 없다.
- 흐름/상태: FriendListPage는 root scroll과 상태별 _buildContentSliver를 분리했다. GroupRoomListView도 초기/오류/빈/목록을 sliver로 분기한다. 그룹 ScrollEndNotification은 groups가 있고 pixels>=0이며 extentAfter<120일 때만 기존 loadMore에 전달한다. 그룹 API 비활성의 정적 미리보기·탭 route/접근권한·PageView/keep-alive/dispose·도메인 provider·API/DB/env/analytics/logging 계약은 유지한다.
- 테스트/검증: 기존 friend_list_page_test.dart와 group_room_list_view_test.dart에 실제 당김·조회 횟수·지연 응답 중 컨트롤 유지/중복 방지·새 목록 표시·오류 복구를 추가했다. 활성 그룹에서는 빈 화면 여백을 당겨 친구/그룹 각각만 조회하고 선택 탭/가로 전환을 보존하는 실제 PageView 통합 경로도 확인한다. 기존 작은 높이/글자3.2배·일반/가로·다크/동작 줄이기/스크롤 위치·탐색 회귀와 최종 분석/포맷 결과는 WORKLOG를 따른다.
- 한계/롤백: 서버는 모의 service/repository로 검증하며 실기기/VoiceOver·운영 API·빌드/업로드·커밋/푸시는 수행하지 않는다. 이번 root/physics·상태 sliver·회귀/문서만 되돌리고 기존 미커밋 변경을 보존한다.

## 개인정보처리방침은 정책 내용만 표시 (2026-11-12)

- 사용자 요청/Behavior change: privacy.html의5개 ‘표가 화면보다 넓으면…’ 안내 문단과 .table-hint CSS·aria-describedby 참조를 제거했다. 공개 변경 이력에서도 ‘모바일 표 표시 개선’을 빼고 개인정보 처리 관련 변경만 기재하며 정본 MD도 동기화했다.
- 보존/검증: 정책 본문·연령/동의·75%치수·표 caption/행·열 scope·영역명/키보드 포커스·내부 가로 스크롤을 유지한다. HTML중첩·14절/5표·MD표 셀 일치·연령/동의 보존·안내 잔존0/누락ARIA참조0·diff검사를 확인했다. 단순 문구 삭제로 신규 테스트·렌더·파일·의존성을 추가하지 않았다. support는 변경하지 않았다.
- 배포/롤백: 운영 교체는 수행하지 않았고 최신privacy hash는 DEPLOY_GUIDE상단에 반영했다. 이번 안내/참조·변경 이력 정리와 문서만 되돌리면 롤백된다.

## 개인정보·고객지원 페이지75% 크기 (2026-11-12)

- 사용자 요청/Behavior change: 기존 `_docs/app_store_web/privacy.html`·`support.html`의 CSS 글자·여백·본문 최대 폭·표 최소 폭·반경 등을75%로 축소했다. 본문16→12px, h1 데스크톱30→22.5px/모바일26→19.5px, h2 21→15.75px, 본문 최대 폭860→645px다. 개인정보 표는 기본480px·2열420px·4열660px로 유지한다. 이전 절의16px/표640·560·880 설명은 이번 크기로 대체한다.
- 보존: 본문/링크는 CSS 이후 원문까지 완전히 동일하다. 연령·동의/보관기간·정책 버전과 지원 내용도 변경하지 않는다. viewport 초기 배율1·600px breakpoint·브라우저 확대·native table·표 내부 가로 스크롤을 유지한다. 내비게이션/이메일 버튼 최소 터치 높이44px·1px 구분선·포커스 강조는 축소하지 않는다. support도 같은44px 내비게이션 높이를 사용한다. 외부 CSS/JS·새 의존성/API/DB·앱 변경은 없다.
- 검증 역할/사용 예: 임시 `/private/tmp/shiftmate_web_scale_2026-11-12.mjs`는 기존Node 내장 CDP 측정 경계를 사용해 두 실제 HTML을320/375/844/1440px·375px200% 본문/다크 선호·동작 줄이기12조건에서 렌더한다. 루트에서 `node /private/tmp/shiftmate_web_scale_2026-11-12.mjs` 실행 시 `/private/tmp/shiftmate_web_scale_2026-11-12`에 PNG4개·measurements.json을 저장한다. 별도 임시 Chrome CDP9337이 필요하고 저장소 신규 파일은 없다.
- 결과/배포/롤백:12조건에서 본문12px(확대24px)·최대645px·표 열 정렬·페이지 가로 넘침 없음·내비게이션/문의44px 이상과 본문/링크 보존을 확인했다. 이전 내용 구조 검증도 통과했다. 실제 Safari/VoiceOver·운영 교체·커밋/푸시는 하지 않았다. 두 파일 최신 hash는 DEPLOY_GUIDE 상단을 따른다. 이번 CSS/문서만 되돌리며 앞선 표·본문 정정은 유지한다.

## 개인정보 웹페이지 모바일 표·본문 정정 (2026-11-12)

- 정책/흐름: ADR-0074. 앱의 개인정보 링크는 기존 `https://www.shiftmate.co.kr/privacy`를 유지한다. 기존 정적 `_docs/app_store_web/privacy.html`만 교체하는 변경이며 앱 바이너리/API/DB/상태 수명·동의 기능을 바꾸지 않는다. 모바일에서 헤더/본문을 각각 세로 나열하던 block CSS를 제거하고 native table/thead/tbody/tr/th/td를 보존한다.
- UI:5개 표는 caption·열/행 제목 scope·가로 스크롤 영역/키보드 접근·설명 연결을 제공한다. 기본640px·2열560px·4열880px 최소 폭으로 표 안에서만 스크롤되며 페이지 자체는 viewport 폭을 유지한다. 기존 색상/16px 본문과600px 본문 패딩 분기는 유지한다.
- 본문: 정본 PRIVACY_POLICY.md와 HTML을 v1.1/최종수정2026-11-12로 동기화했다. 나만 보기 공유 제외·그룹 비친구 근무 열람·레벨0·통합 SDK의 분석/진단·공휴일 API를 보완하고 실제 없는 그룹 설명 대신 시간대를 적는다. 사용자 지시로 연령/항목별 동의 원문은 유지한다. 최초 시행일·기존 보관기간·S3 위치/담당자도 유지한다. 근거·남은 계약별 국외 처리 확인은 PRIVACY_REVIEW 상단을 따른다.
- 검증 도구 역할/의존성/사용 예: 저장소 밖 `/private/tmp/shiftmate_privacy_render_2026-11-12.mjs`는 Node 내장fetch/WebSocket/fs와 전용 임시 headless Chrome의CDP9337을 이용해 실제 HTML을11조건에서 렌더·측정한다. 루트에서 `node /private/tmp/shiftmate_privacy_render_2026-11-12.mjs`를 실행하면 `/private/tmp/shiftmate_privacy_qa_2026-11-12`에 PNG/measurements.json을 저장한다. `/private/tmp/shiftmate_privacy_content_audit_2026-11-12.py`는 Python표준HTMLParser로 태그·표/MD 셀 일치·연령/동의 원문 보존을 확인한다. 신규 저장소 파일/패키지는 없다.
- 결과/배포/롤백: 수정 전375px5개 표 열 불일치, 수정 후11조건×5표 정렬·본문 가로 넘침 없음·ArrowRight40px 이동을 확인했다. 실제 Safari/VoiceOver·운영 교체는 수행하지 않았다. 확인된 배포 연결이 없어 교체본/hash/롤백을 DEPLOY_GUIDE 상단에 준비했다. 이번 정적 페이지/본문/문서만 되돌리며 기존 미커밋 변경을 보존한다.

## 설정 고객 지원 링크 (2026-11-12)

- 목적/Behavior change: 미지원 고객 센터를 숨긴 ADR-0073의 후속으로, 실제 운영 고객 지원 페이지에 연결하는 ‘고객 지원’ 행을 추가했다. 설정의 지원 섹션은 고객 지원 → 개인정보처리방침 → 버전 정보 순서다.
- 역할/의존성/사용 예: 기존 lib/core/utils/privacy_policy.dart가 customer_support_url(https://www.shiftmate.co.kr/support)·openCustomerSupport와 공용 외부 페이지 열기/실패 처리를 제공한다. 기존 url_launcher의 externalApplication 모드를 사용한다. SettingsPage는 `openCustomerSupport(context, launcher: widget.launch_customer_support)`로 호출하고, 선택적 ExternalPageLauncher를 주입할 수 있다. 기존 PrivacyPolicyLauncher/launchPrivacyPolicy/openPrivacyPolicy 계약과 로그인·설정 정책 URL/문구는 유지한다.
- UX/영향: 브라우저 열기 실패/Exception은 고객 지원 페이지명·URL·재시도 안내를 다이얼로그로 표시하고 화면 해제 뒤에는 다이얼로그를 띄우지 않는다. 기존 행 높이/아이콘/구분선·root route·인증/provider·API/DB/env·나머지 미지원 메뉴 숨김은 유지한다. 신규 파일·의존성은 없다.
- 검증/롤백: 설정·로그인 기존 회귀 및 분석/포맷·지원 URL 확인 결과는 WORKLOG를 따른다. 이번 지원 행과 공용 열기 확장·문서 추가분만 되돌리며 기존 미지원 메뉴 제거는 보존한다.

## 미지원 설정 메뉴 숨김 (2026-11-12)

- 목적/정책: ADR-0073. 앱 심사 재제출 전 미지원 기능은 설정에 표시하지 않는다. 이전의 ‘준비 중’ 표시 정책을 대체한다.
- 변경/Behavior change: 기존 settings_page.dart에서 기본 알림 설정·다크 모드·언어 및 지역·글꼴 크기·비밀번호 변경·로그인 생체 인증·공지사항·고객 센터 8개 행과 비게 되는 앱 설정/계정 및 보안 섹션·간격을 제거했다. 행 helper의 is_available/준비 중 분기도 제거한다.
- 표시/흐름: 프로필 카드 → 근무 관리(근무 패턴 설정) → 지원(개인정보처리방침·버전 정보) → 로그아웃 → 회원 탈퇴 순서다. 기존 root 설정 route, 프로필 편집·근무 패턴 이동·정책 열기·인증/삭제 처리, ListView 스크롤·테마·접근성 크기를 유지한다. OS 알림 권한과 실제 푸시 수신 기능은 이 메뉴 제거와 별개다.
- 영향/검증/롤백: 신규 파일·의존성·API/DB/env/provider 수명·analytics/logging 변경은 없다. 기존 설정/프로필 화면 테스트와 정적 분석·포맷 결과는 WORKLOG를 따른다. 이번 메뉴 표시와 문서 변경분만 되돌리며 기존 미커밋 변경은 보존한다.

## 그룹 캘린더 UI 공용화 (2026-11-12)

- 선택 네모 후속 보완: 앞선 통일에서 남은 _CellLayoutMetrics.dots의50px/아래3px를 badge와 같은58px/아래4px로 통합했다. 58은 요청한 한 변 크기이며 실제 Rect는 7열의 칸 너비와 rowHeight(상세52/56px) 제약을 받는다. 메인 접힌 보기 compact의48px/아래8px와 점/배지 내용은 유지한다. 기존 group_calendar_page_test.dart가 폭320/375/390/430/667/768와 행52/56의12조합에서 badge/dots의 실제 선택 Rect(셀 기준 크기·위치)를 비교한다. 신규 파일/API/DB/상태 변경은 없고 결과는 WORKLOG를 따른다.
- 현행 정책: ADR-0072. 아래 ‘범위 검토’와 과거 그룹 전용 버튼/달력 여백/구성원 카드 설명을 대체한다. 메인·친구·실제/미리보기 그룹은 CalendarPageBody와 CalendarMonthHeader.onToday를 함께 사용한다. 그룹의 grid_wrapper 좌우8px/요일30px 예외를 제거해 기본32px 요일·전체 폭 날짜 셀을 사용한다.
- 흐름/역할: 기존 calendar_viewport.dart에 CalendarPageBody(calendar, schedule, key_prefix)를 추가하고 기존 메인 LayoutBuilder를 추출했다. 예: `CalendarPageBody(key_prefix: 'group-calendar', calendar: _buildCalendar(state), schedule: _buildSelectedDayDetail(state))`. 일정 최소 공간144px를 글자 크기에 맞춰 예약하고 달력 뒤4px 간격·하단16px를 사용한다. 높이가 극도로 부족하거나 글자 배율1.25를 넘으면 전체 페이지 스크롤과 일정280px의 확대 높이를 사용한다. 다른 경우 달력만 제한 높이 안에서 스크롤하며 목록은 남은 공간을 채운다. 네 페이지의 SafeArea(bottom: false)와 함께 사용한다.
- 일정 행: 기존 calendar_schedule_card.dart에 CalendarScheduleItem(color, child, include_margin)을 추가했다. 메인/친구의 근무/개인 일정 장식을 그대로 추출하고 실제/미리보기 그룹 구성원이 사용한다. 배경8% tint·4px 왼쪽 선·12px 반경·안쪽12x10px·바깥 좌우12px/상하4px를 공유하며 그룹 목록은 위아래4px 여백이다. 구성원 아바타/이름·코드·개인 일정 가로 목록·DENIED 표시를 보존한다. 단일 소유자 모델로 변환하지 않는다.
- 헤더/Behavior change: 친구/그룹의 별도 오늘 버튼을 메인과 같은 공용44x44 이상 액션으로 대체하며 today_key로 기존 키를 유지한다. 그룹의 월 로딩 표시를 제공한다. 큰 글자/좁은 헤더는 연월과 탐색 액션을 각각 한 행에 배치하고 요일 높이를 공용 body_small의 확대 크기 이상으로 확보한다. 실제 그룹 관리 액션도44x44·‘그룹 정보’ 이름을 제공한다.
- 상태/영향: 기존 GroupCalendarRangeNotifier의 멤버/ACL/timezone·3개월 조회와 페이지 날짜 state·멤버별 필터·근무 점·수정/삭제·route/접근권한·analytics/logging·autoDispose 계약은 유지한다. API/DB/env/패키지 변경과 신규 저장소 파일은 없다.
- 검증/역할: 기존 test/helpers/calendar_header_assertions.dart에 verifyResponsiveCalendar를 추가했다. 실제/미리보기 그룹 테스트가320x568·375x667·390x844·667x375·768x1024·글자3.2배·다크/동작 줄이기에서 달력 폭/요일 높이·연월 한 줄·44px 오늘·마지막 구성원 접근·다음 월/오늘 이동을 검증한다. GROUP_CALENDAR_RENDER_OUTPUT 환경변수를 지정하면 실제 폰트로 PNG를 임시 경로에 저장한다. 메인/친구 및 그룹·탭 탐색/레이아웃 정책 회귀 결과는 WORKLOG를 따른다.
- 롤백: 이번 공용 위젯 추출/호출부·관련 테스트·ADR-0072/이번 절/일지 추가분만 되돌린다. 기존 미커밋 변경은 보존한다. 실기기 인수/배포는 수행하지 않는다.

## 그룹 캘린더 UI 통일 범위 검토 (2026-11-12)

- 상태: 구현 전 정적 검토이며 새 UI 정책을 확정하지 않았다. ADR-0016/0017의 표시 공용화·그룹 전용 domain state를 유지한다.
- 코드 근거: 메인/친구/실제 그룹은 CalendarViewport·CalendarMonthView를 사용하고 선택일 날짜는 CalendarScheduleHeader를 공유한다. 실제 GroupCalendarPage와 GroupCalendarPreviewPage는 오늘 버튼54x36·별도 타이포/반경, grid_wrapper 좌우8px·요일30px를 지정한다. 메인은 공용 onToday 액션, 친구는44x32 별도 버튼을 사용한다. 메인 LayoutBuilder의 일정 최소 공간/큰 글자 스크롤 대응도 친구/그룹의 단순 Column 배치와 다르다.
- 변경 후보/영향: 공용 액션·달력 치수·선택일 영역 배치를 정리하면 FE 안에서 외형을 맞출 수 있다. 구성원별 본문은 별도 카드이며 멤버 식별·다중 근무·공개 안 함 의미가 필요하므로 단일 소유자 CalendarScheduleCard 데이터로 축약하지 않는다. 실제/미리보기 그룹을 함께 검토한다. 앱/API/DB 동작은 이번에 수정하지 않았다.
- 검증/롤백: 관련 소스와 기존 ADR을 대조했으며 테스트 실행/실기기 시각 검증은 수행하지 않았다. 구현 시 작은 화면·확대 글자·다중 멤버·DENIED와 기존 월 이동/날짜 선택의 회귀를 확인해야 한다. 이번 절과 WORKLOG 조사 항목만 제거하면 롤백된다. 신규 파일/의존성은 없다.

## 근무·개인 일정의 삭제 문구와 화살표 통일 (2026-11-12)

- 목적/Behavior change: ADR-0071. 메인 근무 일정도 개인 일정과 같이 왼쪽 스와이프의 노출 폭이88px 이상이면 휴지통 옆에 `삭제` 문구를 표시한다. 개인 일정 오른쪽의 연필/`수정` 표시는 근무와 동일한14px `chevron_left`·outline_variant_color 화살표로 대체한다. 아래 과거 연필/수정 표시 설명은 이번 정책이 대체한다.
- 흐름/영향: 기존 CalendarPage의 `_buildWorkShiftItem`에 `show_delete_label: true`를 전달하고 `_buildEventItem`의 trailing만 교체한다. 행 전체 탭 편집·접근성의 ‘일정 수정’/삭제 액션·삭제 중 표시·짧은 스와이프 복귀·3초 유예/되돌리기·API/DB·provider 수명·라우트/권한은 유지한다. 신규 파일/의존성/env 변경은 없다.
- 검증/롤백: 기존 calendar_page_test.dart의46개 회귀로 탭 수정·근무/개인 혼합 삭제·되돌리기·부분 스와이프 배경을 확인했다. 실행은 `flutter test --no-pub test/features/calendar/presentation/pages/calendar_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`이며 정적 분석/포맷 결과는 WORKLOG를 따른다. 이번 표시 속성/아이콘과 문서 추가분만 되돌린다.

## 그룹 생성자 탈퇴 후 상세 정보의 nullable 계약 지원 (2026-11-12)

- 목적/Behavior change: ADR-0070. 생성자가 회원 탈퇴해 `GET /api/v1/groups/{group_id}`의 `created_by_user_id`가 null이어도 그룹 정보를 정상 표시한다. 기존 `GroupDetail.created_by_user_id`를 `String?`, `fromJson`의 캐스트를 `as String?`로 변경했다. 생성자 문자열은 그대로 보존하고 null을 빈 문자열이나 현재 OWNER ID로 대체하지 않는다.
- 흐름/영향: 기존 `GroupManagementPage → GroupDetailNotifier.load → GroupRepositoryImpl.getGroupDetail → GroupDetail.fromJson` 경로를 유지하며 데이터 계약 두 줄만 수정한다. 권한은 기존 `my_role`/멤버 `role`을 따르며 UI state/domain state 관리·autoDispose·라우트/접근권한·API 요청·서버/DB·의존성/env·로깅은 변경하지 않는다.
- 파일/검증: 신규 파일 없이 기존 `group_repository_impl_test.dart`에 생성자 문자열/null 응답 파싱과 승계된 OWNER 보존을 검증한다. 기존 `group_management_page_test.dart`의 모의 repository는 실제 JSON 파서를 호출하며 null 생성자에서도 그룹명/멤버/활성 초대 버튼을 표시하고 기본 오류/재시도를 표시하지 않는지 검증한다. 수정 전 두 null 회귀가 실패해 증상을 재현했다. 실행: `flutter test --no-pub test/features/group --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --dart-define=GROUP_API_ENABLED=true --dart-define=GROUP_P1_ENABLED=true`. 결과/기본 플래그 검증은 WORKLOG를 따른다.
- 롤백/배포: 이번 모델 두 줄·추가 회귀·문서 추가분만 되돌린다. 수정 앱을 빌드/배포해야 설치 사용자에게 반영되며 기존 앱의 파싱 오류를 서버 문서 변경으로 해결할 수는 없다. 이번 작업은 실기기/운영 API 확인·앱 배포를 포함하지 않는다.

## 그룹 생성자 회원 탈퇴 후 상세 조회 오류 조사 (2026-11-12)

- 상태: 수정 전 원인 조사 기록이다. 앱 수정 결과와 현행 nullable 계약은 위 절 및 ADR-0070을 따른다.

- 조사 결과: 인접 서버의 `accountDeletionService.purgeAccountData`는 남은 멤버를 `OWNER`로 승계하고 탈퇴자를 물리 삭제한다. `add_account_deletion_support.sql`의 `groups.created_by_user_id`는 nullable/`ON DELETE SET NULL`이며, 서버 `groupService.getGroupDetail`과 `types/group.ts`는 이 null을 그대로 응답한다. 현재 소유권은 `group_members.role`이고 생성자 감사 필드는 소유권 이전 대상이 아니다.
- FE 계약 불일치: `lib/features/group/domain/entities/group_models.dart:209`의 `GroupDetail.fromJson`은 생성자 값을 `as String`으로 읽는다. 생성자 탈퇴 후 null 응답은 TypeError를 발생시키고 `GroupDetailNotifier.load`가 저장한다. `GroupManagementPage`는 그룹 데이터가 없고 로딩 중이 아니며 ApiException이 아닌 오류이면 ‘그룹 정보를 불러오지 못했습니다.’를 표시한다. 연결 API는 `GET /api/v1/groups/{group_id}`이며 HTTP 성공 응답의 파싱만 실패해도 나타난다.
- 캘린더와 목록이 유지되는 이유: `GET /groups/{group_id}/calendar/range`의 헤더는 group_id/name/timezone만 사용하고 그룹 목록 모델도 생성자 필드를 파싱하지 않는다. 캘린더 진입에서 상세와 캘린더 요청은 별도로 실행된다. 상세 파싱 오류가 있어도 캘린더 데이터로 제목/구성원/일정을 표시할 수 있다.
- 검증/한계: 실제 GroupDetail/GroupSummary/GroupCalendarHeader를 호출하는 외부 임시 진단 스크립트 `/private/tmp/group_owner_deletion_repro.dart`로 생성자 문자열 성공 → null일 때 목록/캘린더 성공·상세 TypeError를 재현했다. 실행 예: `/opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart /private/tmp/group_owner_deletion_repro.dart`. 순수 Dart 모델에만 의존하며 서버/DB/인증 정보를 사용하지 않는다. 임시 스크립트는 저장소 산출물이 아니다. 사용자가 겪은 실제 API 응답·배포 코드·운영 DB 값은 이번에 수집하지 않았다.
- 영향/후속: 이번 작업은 분석/문서만 추가하고 앱·서버·API·DB 동작을 변경하지 않는다. 수정 지점은 FE 생성자 타입과 파서의 nullable 수용 및 생성자 탈퇴 후 상세/화면 회귀다. 소유권 판단을 생성자 ID로 대체하거나 새 소유자를 과거 생성자로 덮어쓰지 않는다. 새 설계 결정이 없어 ADR은 추가하지 않으며 이번 조사 문서만 제거하면 롤백된다.

## 커스텀 색상 고정 미리보기와 독립 조절 패널 (2026-11-12)

- 헤더 후속 정책: ADR-0058의 배경 고정 예외를 이 화면에도 적용한다. 고정 미리보기 아래 패널만 스크롤하므로 navigationBar에 automaticBackgroundVisibility=false·backgroundColor=AppTheme.background_color·border=null을 지정해 메인/친구 목록과 같이 흰색 재질로 전환하지 않는다. 기존6조건 회귀는 실제 스크롤/최하단/맨 위 복귀의 렌더된 헤더 BoxDecoration 색상/경계 불변도 검증한다. 기존 헤더 렌더러의 커스텀 기대값도 갱신했다. 미리보기/패널 배치·조절/저장·다른 상세 화면 헤더는 유지한다.

- 목적/현재 정책: ADR-0069가 ADR-0065를 대체한다. 사용자가 적용색을 보면서 조절해야 한다고 정정해 ‘적용될 색상’을 상단 고정으로 복구했다. 키보드가 열려도 숨기지 않는다. 아래 조절 패널은 미리보기와16px 떨어져 있으며 외곽 테두리/둥근 경계가 고정되고 내용만 스크롤한다. 이동하는 카드의 테두리가 미리보기 아래에서 잘리던 기존 구조와 구분한다.
- 구현/Behavior change: Column → 고정 미리보기 → Expanded(공용 카드 장식/ClipRRect → SingleChildScrollView → 기준색·휠·RGB·농도·최근 색상)이다. 별도 스크롤 패널은 최대폭480·좌우16px·하단 안전영역+24px를 사용한다. 본문 가용 높이420px 미만은 미리보기 패딩12/샘플32px·라벨/HEX Wrap으로 공간을 확보하며 일반 화면은 기존 패딩16/샘플56px·세로 정보 배치를 유지한다. 글자 배율을 제한하지 않는다. 입력/미리보기는 마운트 상태를 유지하며 기준색/최종색 계산·휠 제스처·기록·route/저장 계약과 기존 헤더 재질은 유지한다. 신규 provider/controller/패키지/API/DB/env 변경은 없다.
- 파일/검증: 기존 shift_custom_color_picker_page.dart·shift_custom_color_picker_page_test.dart·shift_color_picker_page_test.dart를 갱신한다.320x568·375x667·667x375·375px 글자3.2배·768x1024·키보드240px에서 실제 드래그 후 미리보기/패널 Rect 고정·16px 간격·최근 색상 접근/선택 즉시 최종 HEX 갱신을 검증한다. 농도 트랙 실제 탭/드래그 중 샘플 색상 갱신과 위치/스크롤 유지도 확인한다. 스크롤 조작은 패널 내부 여백에서 시작한다. 실행 예: `flutter test --no-pub test/features/calendar/presentation/widgets/shift_custom_color_picker_page_test.dart test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`. 최종 결과/시각 검증/롤백은 WORKLOG를 따른다. 신규 저장소 파일은 없다.

## 선택일 헤더의 좁은 폭·확대 글자 대응 (2026-11-12)

- 목적/현재 정책: ADR-0068. 실제 그룹의 선택일 날짜가 좁은 Row에서 두 줄이 되지만 높이는28px에 고정돼 잘리는 문제를 수정했다. 날짜/공휴일과 요약 표시를 각각 자연 크기로 배치하고 함께 들어가지 않으면 요약 묶음을 다음 줄로 옮긴다. 요약끼리도 공간이 부족하면 줄을 나누며, 날짜/공휴일 자체가 한 줄보다 길면 전체 내용을 줄바꿈한다. 텍스트 축소·말줄임으로 숨기지 않는다.
- 구현/Behavior change: 기존 calendar_schedule_card.dart의 CalendarScheduleHeader를 실제/미리보기 그룹까지 공유한다. 중첩 Wrap의 실측 배치로 화면 폭·번들 폰트·TextScaler·굵은 글자를 반영한다. 기존 고정28px를 최소28px로 바꿔 한 줄이면44.5px 헤더를 유지하고 필요한 만큼 높아진다. 메인/친구의 배율1.25 초과 분기와 공휴일 말줄임도 이 규칙으로 대체한다. 공용 타이포·16px 수평/8px 수직 여백·0.5px 경계는 유지한다. 본문 목록은 헤더 뒤 남은 공간을 사용하며 그룹의 구성원 목록 스크롤은 유지한다.
- 역할/사용 예: 새 앱 파일 없이 CalendarScheduleHeader의 선택적 summary_chips, header_key, summary_key를 추가했다. 그룹은 `CalendarScheduleHeader(selected_date: date, summary_chips: [CalendarScheduleSummaryChip(label: '근무 2명', is_primary: true), CalendarScheduleSummaryChip(label: '일정 4개')])`로 사용한다. 기존 total_count/trailing 호출도 유지한다. API/DB·domain/UI state·라우트/권한·analytics·env·패키지 의존성은 바꾸지 않는다.
- 신규 검증 파일: test/features/calendar/presentation/widgets/calendar_schedule_header_test.dart는 Flutter test/rendering/services·intl·기존 공용 헤더/그룹 미리보기에 의존하며 실제 Cafe24/Cupertino 폰트를 로드한다. 폭320/375/390/430/667/768·배율1/1.1/1.25/2/3.2·굵은 글자에서 긴 날짜·세 자리 요약·공휴일의 글리프 경계와 겹침/줄 전환을 확인한다. 기존 그룹 테스트에는320/375/390px 실제 페이지 재현을 추가했다. 선택 영역의 줄 끝 공백은 글리프 경계 검사에서 제외한다.
- 실행/산출물: `SCHEDULE_HEADER_RENDER_OUTPUT=/private/tmp/shift_schedule_header_2026-11-12 flutter test --no-pub test/features/calendar/presentation/widgets/calendar_schedule_header_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 선택일 헤더4개와 실제 미리보기320x568·375x667·667x375 PNG3개를 생성한다. 결과와 한계는 WORKLOG를 따른다. 이 검증은 헤더의 최대 글자 배율을 포함하며 모든 상세 페이지 전체의 최대 Dynamic Type/실기기 인수를 의미하지 않는다.
- 롤백: 이번 공용/그룹 헤더·관련 회귀/문서 추가분만 되돌린다. 기존 미커밋 시간 구분자·빈 상태 정렬·탐색/개인 일정 작업은 보존한다.

## 일정 없음 안내의 세로 중앙 정렬 (2026-11-12)

- 목적/Behavior change: 메인·친구 공용 CalendarScheduleCard의 ‘등록된 일정이 없습니다’ 아이콘/문구 묶음을 날짜 헤더와 하단 추가 버튼을 제외한 일정 본문의 상하 중앙에 표시한다. 빈 상태의 기존 SingleChildScrollView를 Center로 감싸며 높이가 부족하면 기존 스크롤을 유지한다.
- 파일/영향: 기존 calendar_schedule_card.dart의 빈 상태 분기만 변경한다. 일정이 있는 목록·카드 크기·헤더/footer·데이터/라우팅은 유지하며 신규 파일·상태·의존성·설계 정책은 없다. 관련 메인/친구 기존 회귀 및 분석·포맷 결과는 WORKLOG를 따른다. 롤백은 이번 Center와 문서 추가분만 되돌린다.

## 하단 탭 재선택과 알림 목적지 경로 (2026-11-12)

- 목적/정책: ADR-0067. 다른 하단 탭을 선택하면 해당 탭의 기존 탐색 이력·선택 날짜·친구/그룹 선택을 보존한다. 현재 탭을 다시 누르면 해당 Navigator를 `popUntil(route.isFirst)`로 홈까지 되돌린다. 친구 탭이 이미 목록이면 친구↔그룹 목록을 전환한다. 상세에서 홈으로 돌아오는 한 번의 탭은 목록 전환까지 함께 하지 않는다. 캘린더 홈 재선택은 기존 선택 날짜를 유지한다.
- 흐름/Behavior change: 하단 버튼·접근성 탭은 MainTabPage._onTabPressed, 일반 탭 선택은 _selectTab으로 구분한다. `AppTabNavigation.openFriends()`는 친구 탭을 선택하고 기존 상세 이력을 정리한 후 지정한 목록을 표시한다. 친구 수락은 친구 목록→FriendCalendarPage, 그룹 수락/그룹 바로가기는 그룹 목록→GroupCalendarPage, `/friends`의 친구 목록 보기는 친구 목록으로 이동한다. 알림 탭 위에 상세를 추가하지 않으며 뒤로가기는 목적지 목록으로 돌아간다. MainTabPage 밖에서 NotificationPage를 단독 표시하는 기존 호출은 로컬 Navigator fallback을 유지한다.
- 상태/역할·사용 예: 새 파일 없이 기존 app_navigation.dart에 FriendTabSection과 openFriends(section, detail_builder)를 추가한다. MainTabPage의 GlobalKey<FriendListPageState>가 기존 목록의 showSection/toggleSection을 호출하며 PageController·keep-alive·dispose 정책은 유지한다. 첫 방문 탭은 프레임 종료 후 경로를 적용하고 revision으로 연속 요청/그 사이 하단 탭 입력의 오래된 요청을 무시한다. 예: `AppTabNavigation.maybeOf(context)?.openFriends()` 또는 `openFriends(section: FriendTabSection.groups, detail_builder: (_) => GroupCalendarPage(group_id: id))`. provider/analytics·인증/접근권한·API/DB/env/의존성은 바꾸지 않는다.
- 검증/한계: 기존 main_tab_page_test.dart에 실제 친구 캘린더/정보·알림·그룹 화면의 탭 선택, 날짜/state 보존, 홈 복귀/목록 전환, 목적지 뒤로가기, 첫 방문/기존 상세 정리, 실패·친구 누락·거절을 검증한다. 테스트용 service/repository/notifier가 서버 응답을 모의하며 수락 API 자체의 검증은 기존 provider 테스트가 담당한다. 세로375x667·768x1024와 가로844x390의 목록 전환/동작 줄이기·다크 모드를 포함한다. 별도 탐색 검증 중844x390의 실제 FriendCalendarPage에서 하단8.5px overflow가 관찰됐다. 해당 페이지 배치는 이번에 수정하지 않았으며 정확한 overflow 지점/원인 확인과 가로 상세 레이아웃 해결은 남아 있다. 가로 검증은 목록 전환 범위다. 실기기 인수는 수행하지 않았다.
- 롤백: 이번 네 탐색/화면 파일과 기존 회귀·정본 문서 추가분만 되돌린다. 기존 미커밋 애니메이션/목록 스와이프·화면 배치 작업은 보존한다. 최종 테스트 결과는 WORKLOG를 따른다.

## 일정 시간 구분자 통일 (2026-11-12)

- 목적/표시 정책: ADR-0066. 근무·개인 일정의 시간 구간은 `HH:mm - HH:mm`처럼 공백을 포함한 하이픈(` - `)으로 표시한다. 근무 타입 카드의 기존 표기를 따르며, 야간 편집 요약도 `22:30 - 다음 날 07:00`으로 표시한다.
- 그룹 보완: 실제 GroupCalendarPage의 `_shiftTime`과 GroupCalendarPreviewPage의 네 근무 템플릿도 ` - `로 통일한다. 미리보기 야간의 `익일` 안내는 유지한다. 앞선 변경에서 남아 있던 공백 없는 `–` 표기를 보완하며 기존 ADR-0066 정책을 확장 적용한다. 신규 파일/API/DB/상태/라우트 변경은 없다. 기존 그룹 화면 두 테스트의 시간 기대값을 갱신하며, 이번 문자열·기대값·문서 추가분만 되돌리면 롤백된다.
- 범위/Behavior change: 공용 일정 카드의 `formatWorkShiftTime`, `ShiftTypeInfo.timeDisplay`, 근무 타입 편집 요약의 구분자만 통일한다. 개인 일정·근무 타입 카드의 기존 하이픈, `근무없음`/`시간 없음`/`종일`, 시간 값과 저장 계약은 유지한다. 메인·친구는 공용 일정 카드에 반영되며 API/DB·라우트·상태/의존성 변경은 없다. 수정한 ShiftTypeInfo의 기존 분석 진단은 프로젝트 snake_case 예외 선언과 같은 ARGB 정수 변환의 현행 API(`toARGB32`)로 해소했다.
- 검증/롤백: 기존 메인·친구 캘린더 및 근무 타입 편집 테스트 기대값을 갱신했다. 신규 파일은 없으며 결과는 WORKLOG를 따른다. 이번 구분자·관련 분석 정리·테스트 기대값·문서 추가분만 되돌린다.

## 커스텀 색상 미리보기와 본문의 연속 스크롤 (2026-11-12)

- 상태: 사용자 후속 정정으로 ADR-0069가 대체한 이전 구현 기록이다. 현재는 미리보기를 고정하고 독립 패널 안에서 조절한다.

- 목적/최신 정책: ADR-0065. 고정 미리보기 아래에서 조절 카드가 잘리는 경계를 없애기 위해 ‘적용될 색상’ → 16px 간격 → 기준색/휠/RGB/농도 → 최근 색상을 하나의 SingleChildScrollView 안에 배치한다. 스크롤 시 미리보기도 같은 거리로 이동하며 고정 완료/뒤로가기 헤더는 ADR-0064를 유지한다.
- 범위/Behavior change: 기존 Column의 고정 미리보기 + Expanded(ListView)를 스크롤 가능한 하나의 Column으로 변경했다. 소수의 입력 영역은 마운트 상태를 유지한다. 본문 최대폭480·좌우16px·하단 안전영역+24px, 키보드 표시 시 미리보기 접기와 드래그로 키보드 닫기, 색상/농도 계산·휠 제스처·최근 기록·route 결과 계약은 유지한다. 신규 상태/controller/provider/패키지/API/DB/env 변경은 없다.
- 검증/파일: 기존 shift_custom_color_picker_page_test.dart에320x568·375x667·667x375·375x667 글자3.2배의 실제 드래그 전후 미리보기/조절 카드 동일 이동량·간격 보존·최근 색상 접근·맨 위 복귀 회귀를 추가했다. 실행: `flutter test --no-pub test/features/calendar/presentation/widgets/shift_custom_color_picker_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`. 최종 결과·시각 검증·롤백은 WORKLOG를 따른다. 신규 저장소 파일은 없다.

## 작은 화면의 날짜·시간과 상태 화면 배치 (2026-11-12)

- 최신 정책/Behavior change: ADR-0063. 개인 일정의 날짜·시간3:2 분할과 너비300px/배율1.25 경계를 실제 번들 폰트·TextScaler·굵은 글자 기준 폭 측정으로 대체한다. 시작/종료 두 행은 긴 값의 폭을 함께 예약한다. 부족하면 라벨을 위로 옮기고, 날짜와 시간도 컨트롤 단위로 세로 배치한다. 글자를 축소하거나 날짜/시간을 말줄임하지 않는다. 매우 큰 글자의 긴 날짜/요약은 내용 전체를 줄바꿈한다.
- 피커: 시간/연월 요약은 빠른 선택 버튼을 다음 줄로 옮겨 선택값 공간을 확보한다. 날짜 연월 탐색도 공간이 부족하면 연월과 이전/오늘/다음을 분리한다. 연월 시트는 화면 높이·상단 안전영역·최대폭560을 반영하고 본문만 스크롤한다. 연도/월 휠은 배율·확대율을 포함한 실제 텍스트 폭에 맞춰 비율을 나누며 둘이 들어가지 않으면 세로 배치한다. 휠 행 높이도 글자 배율을 반영한다. 큰 글자(scale(16)>20)의 시간/연월 하단 버튼은 같은 폭의 취소/적용·이동으로 간결하게 표시하고 접근성 이름은 기존 전체 문구를 유지한다. 날짜 확인/취소도 같은 폭을 사용한다. 연월의 이번 달 이동은 동작 줄이기를 따른다.
- 상태/검색: 친구·그룹 빈 목록/오류는 가운데 정렬을 유지하면서 본문 높이가 부족하면 스크롤한다. 친구 추가 시트는 낮은 본문(<250px) 또는 큰 글자(scale(16)>24)에서 검색 입력과 결과 영역을 함께 스크롤한다. 최대 글자 크기의 헤더는 제목/취소를 분리한다. 기존 검색/검증/높이 조절/저장·provider/API/권한·DB/env는 유지한다.
- 신규 파일 역할/의존성/사용 예: `lib/core/widgets/scrollable_centered_body.dart`는 Flutter widgets만 사용하는 공용 빈 목록/오류 프레임이며 현재는 ADR-0075에 따라 `SliverCenteredBody(children: [...])`를 친구·그룹의 공통 새로고침 스크롤 안에서 사용한다. `lib/features/calendar/presentation/widgets/picker_selection_summary.dart`는 Cupertino/AppTheme/TextPainter에 의존하며 `PickerSelectionSummary(icon: ..., value: ..., action_label: ..., onAction: ...)`로 시간/연월 선택값과 빠른 선택을 배치한다. 신규 provider/controller/패키지는 없다.
- 검증 파일/산출물: `test/features/calendar/presentation/widgets/compact_layout_test.dart`는 실제 팝업·WidgetTester·intl·번들 Cafe24/Cupertino 폰트에 의존한다. 작은 화면/가로/태블릿·글자1~3.2배의 텍스트 박스·정렬·연도/종일 보존·저장 위치·실제 휠 접근을 검증한다. `COMPACT_LAYOUT_RENDER_OUTPUT=artifacts/compact_layout_2026-11-12 flutter test --no-pub test/features/calendar/presentation/widgets/compact_layout_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 해당 폴더에 PNG를 생성한다. `_docs/SMALL_SCREEN_LAYOUT_REVIEW_2026-11-12.md`는 코드/재현/수정/검증 범위를 구분한 검토 기록이며 런타임 의존성은 없다. 최종 결과·한계·롤백은 WORKLOG를 따른다.

## 상세·편집·색상 선택 헤더의 흰색 재질 통일 (2026-11-12)

- 후속 예외: 커스텀 색상 선택은 독립 패널 도입 후 사용자 요청으로 ADR-0058의 배경 고정 정책을 따른다. 아래 흰색 자동 전환은 다른 상세·편집·색상 선택 화면에 유지한다.

- 목적/최신 정책: ADR-0064. 아래 조사에서 찾은 친구 정보·근무 타입 추가/편집·색상 선택·커스텀 색상 선택의 배경 고정/선 구분을 사용자 요청의 1번 방식으로 변경했다. 각 CupertinoNavigationBar의 backgroundColor override를 제거해 기존 CupertinoTheme.barBackgroundColor를 따르고 border=null로 기본 선까지 제거한다. 라이트 테마는 최상단에서 기존 scaffold 배경(#F8F9FB), 세로 스크롤 시 공통 반투명 흰색(#E6FFFFFF)으로 전환한다. 별도 스크롤 감지/state/provider/공용 위젯은 추가하지 않았다.
- 모달/영향: 친구 추가 모달은 제목 아래 1px 고정선을 제거하고 기존 드래그 헤더에 공통 CupertinoTheme.barBackgroundColor와 상단 반경을 적용한다. 본문은 AppTheme.background_color로 구분하며 고정 헤더이므로 처음부터 흰 재질이다. 선 제거로 본문 가용 높이는 1px 늘어난다. 제목·저장/완료·뒤로가기·모달 크기/드래그/키보드/검색·페이지별 본문 및 하단 버튼 동작을 유지한다. 기존 메인/친구/그룹 캘린더와 친구·그룹 목록의 ADR-0058 배경 고정 예외 및 카드 내부 날짜 헤더 선은 이 요청 범위에서 변경하지 않는다. 현재 메인은 자동 흰색 전환이 아닌 배경 고정 상태이므로 사용자의 명시적인 ‘1번’ 정의에 맞춰 상세 화면에 공통 테마 전환을 적용했다.
- 파일/의존성/사용 예: 기존 friend_detail_page.dart·shift_type_form_modal.dart·shift_color_picker_page.dart·shift_custom_color_picker_page.dart·add_friend_modal.dart의 표시만 바꾼다. 신규 artifacts/header_background_2026-11-12/render_test.dart는 실제 여섯 화면/모달 상태·Flutter test/Riverpod/SharedPreferences 모의 저장소·번들 Cafe24/Cupertino 폰트로 375x667 및 667x375에서 스크롤 전후 PNG22개와 measurements.json을 생성한다. `flutter test --no-pub artifacts/header_background_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 재생성하며 실제 헤더 색상/경계·맨 위 복귀·레이아웃 예외를 검증한다. 콘텐츠가 화면에 들어가 스크롤 공간이 없으면 기존 배경을 유지하는 정상 동작도 확인한다. 친구/근무 정보는 예시이며 API 호출은 없다.
- 검증/롤백: 관련 기존 친구 정보·친구 추가·근무 타입/색상/커스텀 색상·저장 상태 회귀와 변경 파일 분석·렌더 결과는 WORKLOG를 따른다. API/DB/라우트/접근권한/analytics·domain state·의존성/환경변수는 바꾸지 않았다. 이번 헤더 변경·검토 산출물/문서만 되돌리며 기존 미커밋 배치 작업은 보존한다.

## 배경색 유지·하단 구분선 헤더 조사 (2026-11-12)

- 상태: 수정 전 조사 기록이다. 위 ADR-0064 적용 절이 현재 동작을 설명한다.

- 목적/결과: 사용자 요청의 ‘헤더 배경색은 그대로이고 선으로 구분하는 경우’를 현재 코드에서 조사했다. 화면 상단은 FriendDetailPage(친구 정보, 1px), ShiftTypeFormModal(근무 타입 추가/편집, 0.5px), ShiftColorPickerPage(색상 선택, 1px), ShiftCustomColorPickerPage(커스텀 색상 선택, 1px)의 네 구현/다섯 화면이다. 모두 scaffold와 navigationBar에 동일한 AppTheme.background_color(#F8F9FB)를 지정하고 하단 Border를 명시한다. 선은 검정이 아니라 AppTheme.outline_variant_color(#C1C7D2)다.
- 표시 조건/근거: 네 구현은 automaticBackgroundVisibility의 기본 true를 사용한다. 로컬 Flutter SDK의 cupertino/nav_bar.dart는 scaffold 배경에서 명시 배경으로 색상을 보간하고 투명 경계에서 명시 Border로 보간한다. 두 배경색이 같아 색상은 그대로이며 세로 스크롤에 따라 선만 나타날 수 있다. ‘처음부터 항상 선이 보인다’는 뜻은 아니다. 공통 테마의 흰 재질로 전환하는 다른 기본 navigationBar와 구분한다.
- 진입: 친구 목록 → 친구 캘린더의 설정 → 친구 정보. 설정 → 근무 패턴 설정 → 타입 추가/편집 → 표시 색상 → 색상 선택 → 선택한 색상 조절 → 커스텀 색상 선택. 기존 Navigator/CupertinoPageRoute 경로를 코드로 확인했으며 변경하지 않았다.
- 추가 사용처: 친구 목록에서 여는 AddFriendModal은 흰 surface 배경을 공유하고 제목 바로 아래 1px 고정선을 둔다. 화면 내부 헤더까지 포함하면 메인/친구의 CalendarScheduleHeader(메인 근무 설정 카드에도 사용)와 실제/미리보기 그룹의 날짜 상세 카드도 같은 배경 위 0.5px 하단선을 사용한다. ShiftInputSheet의 ‘근무 추가’ 헤더도 0.5px 선이 있으나 현재 lib에 생성 호출/다른 파일의 import가 없어 활성 화면 목록에서는 제외한다.
- 검증/영향/롤백: lib 전체의 CupertinoNavigationBar 선언과 수동 Border/구분선 및 관련 진입 호출을 읽고 공용 토큰/로컬 SDK와 대조한 정적 조사다. 앱 코드·동작·API/DB/상태/라우트/의존성은 변경하지 않았고 런타임 테스트/실기기 확인은 수행하지 않았다. 신규 파일/설계 결정은 없으며 이번 컨텍스트/WORKLOG 조사 기록만 제거하면 롤백된다.

## 하단 캘린더·친구·알림 선택 이동 (2026-11-12)

- 목적/Behavior change: ADR-0062. MainTabPage 하단 바의 선택 배경을 탭별 페이드에서 하나의 이동하는 배경으로 변경했다.280ms easeOutCubic으로 탭 중심 사이를 이동하고 아이콘/라벨 색상도 같은 시간/곡선으로 보간한다. 연속 탭은 현재 위치/색상부터 새 대상으로 이어지며 동작 줄이기는0ms다.
- 흐름/구현: 기존 `_selectTab`과 Navigator/IndexedStack·알림 갱신은 유지한다. 바 안의 Stack에 버튼 Row를 그대로 두고 Positioned.fill → IgnorePointer → AnimatedAlign → FractionallySizedBox(폭1/3)의 배경을 배치한다. AlignmentDirectional로 글 방향을 반영하고 버튼별 TweenAnimationBuilder<Color?>가 기존 읽기 대비색 사이를 보간한다. 기존 글라스/고대비·폭/높이·여백·배지·접근성 선택/터치 동작은 유지한다. 애니메이션 state는 Flutter implicit animation이 관리해 신규 controller/provider/의존성이 없다.
- 검증/파일: 기존 main_tab_page.dart·main_tab_page_test.dart와 정본 문서를 갱신했다. 신규 파일은 없다. 회귀는375x667·844x390·768x1024(다크/글자2배)의 중간 위치/색상·연속 선택·끝 위치·바/버튼 Rect 보존과 동작 줄이기를 확인한다. 기존 탐색/푸시/가입·친구/그룹 스와이프도 확인한다. `flutter test --no-pub test/core/navigation/main_tab_page_test.dart test/features/friend/presentation/pages/friend_list_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 실행한다.
- 영향/롤백: 하단 선택 표시만 변경하며 각 탭 탐색/선택 날짜·상단 친구/그룹 세그먼트·domain state/API/DB/env는 유지한다. 이번 이동 배경·색상 보간·추가 검증·문서만 되돌린다. 실기기/VoiceOver 인수는 별도이며 최종 결과는 WORKLOG를 따른다.

## 친구·그룹 탭 좌우 스와이프 (2026-11-12)

- 목적/Behavior change: ADR-0061. FriendListPage 본문에서 왼쪽으로 쓸면 그룹, 오른쪽으로 쓸면 친구로 전환한다. 상단 CupertinoSlidingSegmentedControl 탭도 유지하며 PageView의 현재 페이지와 선택 표시·제목·추가/초대 액션을 동기화한다.
- 흐름/상태: MainTabPage 친구 영역 → FriendListPage → PageView(친구/그룹). PageController와 선택 상태는 페이지 내부 UI state이며 dispose에서 컨트롤러를 해제한다. 파일 내부 `_KeepAliveSection`이 AutomaticKeepAliveClientMixin으로 두 목록의 state/스크롤 위치를 보존한다. 그룹은 처음 선택될 때 생성하며 실제 GroupRoomListView/미리보기 분기와 기존 provider/API·권한·라우트는 유지한다. 세그먼트 탭은250ms easeOutCubic 이동, 동작 줄이기에서는 jumpToPage로 즉시 전환한다. 본문 세로 스크롤과 기존 헤더 배경 고정을 유지한다.
- 검증/파일: 기존 friend_list_page_test.dart를 확장해390x800·375x667·844x390에서 실제 양방향 드래그·탭·선택 표시/헤더 액션 동기화·세로 스크롤/복귀 위치·그룹 최초 요청1회, 다크 테마/글자2배/동작 줄이기를 확인한다. 기존 group_calendar_preview_page_test.dart의 전환 후 검증은 이동 애니메이션 종료까지 기다린다. 신규 파일/의존성은 없다. 실행: `flutter test --no-pub test/features/friend/presentation/pages/friend_list_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`; 실제 API 분기는 `--dart-define=GROUP_API_ENABLED=true`를 추가하며 서버는 모의한다.
- 영향/롤백: UI 전환만 변경하며 DB/env·domain state·다른 미커밋 작업은 보존한다. 이번 PageView/keep-alive·추가 회귀·문서만 되돌린다. 최종 검증 결과는 WORKLOG를 따른다.

## 메인 캘린더 남은 일정 공간과 작은 화면 경계 (2026-11-12)

- 최신 정책/Behavior change: ADR-0060. 사용자 정정에 따라 아래40% 정책은 폐기했다. 일정/근무 설정 카드는 달력을 배치한 뒤 실제 본문에서 남은 높이를 Expanded로 채운다. 비율/고정280px로 정상 세로 화면의 카드 높이를 정하지 않는다.
- 원인/흐름: 기존 본문580px 미만 전체 스크롤 분기는320x568 기기에서 본문371px보다 달력204+간격24+카드280=508px를 크게 만들어 전체를 스크롤하게 했다. 현재 LayoutBuilder는 본문 높이에서 글자 배율 기준 최소 일정144px와 기존 간격4/16px를 제외한 값을 달력의 maxHeight로 전달한다. ConstrainedBox/SingleChildScrollView는 달력이 짧으면 실제 콘텐츠 높이만 쓰고, 길면 달력만 스크롤한다. 바로 아래 일정 카드는 남는 높이를 전부 채우며 카드 하단은 탭 위16px다.144px는 최소 보호 공간이며 고정 카드 높이나 화면 비율이 아니다.
- 예외/영향: 달력 상한이100px(기본 연월 헤더60+요일32+하단8) 미만인 매우 낮은 본문 또는 scale(16)>20의 큰 글자는 기존 전체 스크롤/scale(280) 접근성 경로를 유지한다. 일반 작은 세로 화면에는 적용하지 않는다. 기본 달력 행 높이·750px 미만2주·형식/확장·근무 설정 전환·목록 내부 스크롤·삭제 오버레이/헤더 배경은 유지한다. 친구/그룹·라우트/권한/analytics·provider/API/DB/env 변경은 없다.
- 검증/산출물 역할·의존성·사용 예: 기존 calendar_page_test.dart는6개 크기의 남은 공간·4/5/6주 실제 탐색·형식/근무 설정과 낮은 가로/큰 글자 예외를 검증한다. 기존 `artifacts/calendar_schedule_ratio_2026-11-12/render_test.dart`를 현재 남은 공간 검증용으로 갱신했으며 같은 Flutter/Riverpod/MainTabPage/Audit fixtures/EditRenderService/번들폰트에 의존한다. `flutter test --no-pub artifacts/calendar_schedule_ratio_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`는 새 `artifacts/calendar_remaining_space_2026-11-12/`에8조건 기본·6조건 근무 설정·6주 월 전후의 PNG16개/measurements.json을 생성한다. 이전40% PNG는 당시 기록으로 보존한다. 상단47/하단34px 안전영역·정확한 MediaQuery 크기로 작은 화면의 실제 목록 스크롤/달력 고정·탭 경계와 월6주의 최소 카드144px/달력 스크롤을 확인한다.
- 결과/한계/롤백: 최종 WORKLOG를 따른다. 실기기/VoiceOver 인수는 별도다. 이번 메인 레이아웃·검증/렌더·문서만 되돌리고 기존 미커밋 일정 편집/삭제·서버 변경은 보존한다.

## 메인 캘린더 하단 일정 영역 비율 (2026-11-12, 폐기된 이전 기록)

- 상태: 사용자 정정으로 ADR-0060이 대체한다. 아래40% 구현/검증은 과거 작업 기록이며 현재 정책이 아니다.

- 목적/Behavior change: ADR-0059. CalendarPage의 일정/근무 설정 카드 높이는 헤더·안전영역·하단 탭을 제외한 실제 본문 LayoutBuilder 높이의40%다. 이전 달력 고정 높이 이후 남은 공간을 모두 채우던 방식과 본문580px 전환 기준을 대체한다.40%는 사용자 요구인 화면별 비율 통일을 구현하기 위해 선택한 초기 UI 값이며 지정받은 수치는 아니다.
- 흐름/영향: 본문 Column → Expanded(달력 전용 SingleChildScrollView) → 기존4px 간격 → SizedBox(본문 높이×0.4, 일정/근무 설정 공용 슬롯) → 기존16px 하단 여백. 달력은 기존 행 높이·750px 미만2주·월/2주/주·확장/compact·월 탐색을 유지한다. 달력이 상단 슬롯보다 크면 달력만 세로 스크롤하고 일정 카드는 고정한다. 일정 목록의 내부 스크롤·삭제 토스트 오버레이·헤더 배경 고정도 유지한다. 작은 화면에서는 목록 일부만 동시에 보일 수 있고,2주/compact 달력이 짧으면 상단 슬롯 안의 여백이 늘어난다.
- 접근성 예외:40% 높이가 textScaler.scale(144) 미만이거나 scale(16)>20이면 기존 전체 스크롤/scale(280) 카드로 전환해 헤더·목록·추가/완료 버튼 접근을 보장한다. 가로/큰 글자에서는 비율 고정보다 조작 가능성을 우선한다. 친구/그룹 공용 위젯·라우트/권한/analytics·domain state/provider 수명·API/DTO/DB/env는 변경하지 않는다.
- 검증/파일 역할: 기존 calendar_page_test.dart는 실제 번들 폰트를 로드하고6개 화면 크기·실제 월 탐색으로4/5/6주·형식/근무 설정 전환의 카드 Rect 동일과 가로/큰 글자 fallback을 확인한다. 헤더 회귀는 일정 카드 안의 목록만 정확히 찾아 스크롤한다. 신규 `artifacts/calendar_schedule_ratio_2026-11-12/render_test.dart`는 Flutter test/Riverpod/실제 MainTabPage·기존 Audit fixtures/EditRenderService·번들폰트에 의존하는 모의 API 렌더러다. `flutter test --no-pub artifacts/calendar_schedule_ratio_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 PNG10개/measurements.json을 생성한다. 표면과 MediaQuery 크기를 일치시키고 상단47px/하단34px 안전영역을 주입한다.6개 세로 화면의40%·탭 위 배치/추가 버튼과 가로/큰 글자 예외,6주 월의 실제 탐색/달력 스크롤 전후 카드 Rect를 확인한다. 과거 렌더 산출물은 보존한다.
- 결과/한계/롤백: 최종 검증 결과는 WORKLOG를 따른다. 실제 기기 조작/VoiceOver 인수는 별도다. 이번 메인 레이아웃·추가 검증/렌더·문서만 되돌리고 기존 미커밋 일정 입력/수정/삭제·서버 작업은 보존한다.

## 캘린더 헤더 배경 고정 (2026-11-12)

- 후속 범위 확대: 사용자가 친구·그룹 탭 목록도 같은 배경 고정을 요청했다. 두 목록이 공유하는 `FriendListPage.navigationBar`에 동일한 automaticBackgroundVisibility=false·backgroundColor=AppTheme.background_color·border=null을 적용한다. `친구`/`그룹 방` 제목 전환·추가/초대 액션·IndexedStack 스크롤 위치 보존·새로고침/페이지네이션·GROUP_API_ENABLED의 실제/미리보기 분기는 유지한다. 아래 네 캘린더 외에 이 목록 헤더도 ADR-0044의 자동 전환 예외다.
- 후속 신규 검증 파일 역할/의존성/사용 예: `test/features/friend/presentation/pages/friend_list_page_test.dart`는 실제 FriendListPage·WidgetTester/Riverpod·AppTheme와20명 친구/20개 그룹을 반환하는 모의 FriendService/GroupRepository에 의존한다. 친구 목록 실제 스크롤·그룹 전환·실제 그룹 스크롤/맨 위 복귀·친구로 복귀 후 위치/헤더 보존을 확인한다. 기본 빌드는 미리보기 카드/목록 제스처와 전환을 검증하며 카드1개라 실제 양수 스크롤은 요구하지 않는다. `flutter test --no-pub test/features/friend/presentation/pages/friend_list_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 기본 경로를, 여기에 `--dart-define=GROUP_API_ENABLED=true`를 더해 실제 API 목록 경로를 검증한다. 서버 요청은 모의하며 신규 API/provider/라우트는 없다. 최종 결과/롤백은 WORKLOG의 후속 항목을 따른다.
- 최신 정책/Behavior change: ADR-0058. CalendarPage·FriendCalendarPage·GroupCalendarPage·GroupCalendarPreviewPage는 헤더를 `AppTheme.background_color`로 고정한다. `CupertinoNavigationBar.automaticBackgroundVisibility=false`와 `border=null`을 함께 지정해 일정/구성원 목록의 세로 스크롤로 흰 재질·하단 경계선이 나타나지 않는다. 아래 ADR-0044의 공통 자동 전환 설명에 대한 캘린더 화면 예외다. 작은 화면의 메인 전체 스크롤에서도 같은 배경을 유지한다.
- 확인된 원인: 로컬 Flutter SDK의 nav_bar.dart는 depth0 ScrollUpdateNotification의 extentBefore를 헤더 아래 스크롤 여부로 사용한다. 실제 목록과 헤더의 겹침은 확인하지 않으므로 고정 달력 아래 목록도 배경 보간을 유발했다. 디버거에서 친구 목록161.17px 이동·달력 Rect 동일·헤더 BoxDecoration의 색상/경계 변경을 확인했고 수정 전 회귀 테스트도 같은 차이로 실패했다.
- 영향/흐름: 네 페이지의 기존 navigationBar 표시 설정만 변경한다. 공통 테마·다른 페이지의 자동 배경 전환·제목/뒤로가기/설정 버튼·기존 달력/목록/탭 구조·provider/라우트/API/DB는 유지한다. 반투명 공통색을 항상 표시하는 대신 기존 정지 상태의 불투명 배경을 사용한다.
- 신규 파일 역할/의존성/사용 예: `test/helpers/calendar_header_assertions.dart`는 Flutter WidgetTester/Cupertino/AppTheme에 의존하는 공용 회귀 도우미다. `verifyCalendarHeaderOnScroll(tester, calendar: ..., list: ...)`로 실제 세로 스크롤과 맨 위 복귀 전후의 헤더 색상·경계/달력 Rect를 확인한다. 네 기존 페이지 테스트가 각 모의 서비스/repository와 실제 화면으로 호출한다. 실행 예: `flutter test --no-pub test/features/friend/presentation/pages/friend_calendar_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`.
- 테스트/한계/롤백: 최종 결과는 WORKLOG 완료 항목을 따른다. 실제 기기 인수는 별도다. 이번 네 헤더 설정·추가 회귀/도우미·문서만 되돌리며 기존 미커밋 일정 편집/삭제/피커 작업은 보존한다.

## 되돌리기 토스트 아래로 쓸어 닫기 (2026-11-12)

- 최신 정책/목적: ADR-0057. 메인 삭제 토스트를 아래로 끌어 화면에서 숨길 수 있다. 닫기는 표시만 바꾸며 기본3초/접근성 탐색10초 뒤 DELETE 예약과 묶음 정책을 유지한다. 되돌리기 버튼만 명시적으로 미전송 삭제를 취소하며 기존 앱 비활성화/dispose/계정 전환 취소·서버 실패 복귀는 그대로다.
- 흐름/영향: CalendarDeleteToast는 down 방향 Dismissible과 필수 onDismiss를 제공한다. 높이50% 또는 Flutter 기본 아래 fling 판정으로 닫고, 위/가로·짧은 끌기는 유지/복귀한다. 수축 없이 이동/복귀180ms·동작 줄이기0ms다. 제스처 안의 Semantics 경계로 접근성 dismiss와 메시지 liveRegion·독립 Undo 버튼을 유지한다. CalendarPage는 알림 revision별 숨김 상태를 삭제 pending map/타이머와 분리하고 추가 삭제마다 새 알림을 띄운다. 이전 알림의 늦은 닫기 콜백은 현재 알림을 숨기지 않는다. 기존 Stack 오버레이 위치·본문/카드/탭 배치는 유지하며 서버/API/DB·라우팅/provider는 바꾸지 않는다.
- 검증/산출물 역할·의존성·사용 예: 기존 페이지 회귀에 실제 아래 끌기/버튼과의 판정·위/가로/짧은 복귀·삭제 예약/오류 복귀·추가 삭제 알림·늦은 콜백·실제 semantics dismiss/동작 줄이기 검증7개를 추가했다. 기존 입력 렌더러의 `TOAST_DISMISS_RENDER_OUTPUT` 옵션으로 실제 MainTabPage/모의 service/번들폰트에 의존하는7조건의 표시/드래그/닫힘 PNG21개와 measurements.json을 생성한다. 예: `TOAST_DISMISS_RENDER_OUTPUT=artifacts/toast_dismiss_2026-11-12 flutter test --no-pub artifacts/calendar_input_flow_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`. 이전 산출물은 보존하며 실제 서버 요청은 페이지 모의 테스트로 검증한다.
- 한계/롤백: 실기기·VoiceOver 인수는 별도다. 최종 테스트/정적 분석 결과는 WORKLOG를 따른다. 이번 토스트 제스처/표시 상태·회귀/렌더 옵션·문서 추가분만 되돌리고 기존 미커밋 입력/공개 레벨/서버 작업은 보존한다.

## 날짜 확인·오늘 위치·피커 시트 끌어 닫기 (2026-11-12)

- 최신 정책: ADR-0056. 아래 과거 날짜 탭 즉시 반환 설명을 대체한다. 시작/종료 행 구분·제목 완료 안내·시간 휠/종일·공개 레벨1~5는 유지한다.
- 날짜/입력 흐름: DatePickerSheet의 날짜 탭은 시트 내부 _selected_date와 선택 표시/날짜 요약만 바꾼다. 오늘도 선택일과 표시 월을 갱신할 뿐 닫지 않는다. 오늘은 월 내비게이션 오른쪽으로 옮기고 하단에는 취소/확인을 고정했다. 확인을 눌러야 date를 반환하고 팝업 전환 완료 후 해당 시간 휠을 연다. 취소/OS 복귀/바깥 탭/끌기 닫기는 null을 반환해 자동 진행을 중단한다. 확인한 날짜는 시간 취소 후에도 유지하고, 확인하지 않은 날짜/시간 변경은 폼에 반영하지 않는다. 부모 개인 일정 폼의 제목/입력은 유지한다.
- 신규 파일 역할/의존성/사용 예: `lib/features/calendar/presentation/widgets/picker_sheet_frame.dart`는 Cupertino/AppTheme와 ScrollController에 의존하는 공용 UI 프레임이다. DatePickerSheet/TimePickerSheet가 key_prefix·height·body·footer·onDismiss를 주입한다. 예: 날짜 시트는 `onDismiss: _cancel`과 확인/취소 footer를 전달한다. 최대폭560/화면 높이·SafeArea/상단 반경28을 유지하고 손잡이44px·스크롤 본문·고정 footer를 구성한다. 날짜는6행과 본문 기준 높이, 시간은기존520px 기준을 사용한다. 새 provider/라우트/API 계약은 없다.
- 끌기 규칙: 본문 AlwaysScrollable+Clamping physics의 depth0·수직·dragDetails·최상단 음수 overscroll만 시트 이동으로 누적한다. 손잡이는 터치 시작부터 실제 이동량을 센다. 최대180px 이동·120px 이상 취소 닫기·짧은 복귀180ms/동작 줄이기0ms다. 본문 중간은 내용만 스크롤하며 휠의 중첩 알림·달력 가로 스크롤·프로그램 이동은 무시한다. 닫기/확인 중복 pop을 방지하고 프레임 dispose 시 controller를 정리한다. 기존 개인 일정 폼의120px 정책과 맞추되 그 폼을 리팩터링하지 않았다. 공용 시간 피커의 근무 타입도 끌기 취소를 공유한다. 연월 빠른 이동 시트 자체는 이번 변경 대상이 아니다.
- 신규 검증 파일 역할/의존성/사용 예: `test/features/calendar/presentation/widgets/picker_sheet_drag_test.dart`는 실제 날짜/시간 팝업·Flutter WidgetTester/intl/기존 AppTheme에 의존해 손잡이/본문 충분한 끌기·짧고 빠른 복귀/값 보존·119/121px·큰글자 본문 중간·휠/달력 가로 분리를16개로 확인한다. 루트에서 `flutter test --no-pub test/features/calendar/presentation/widgets/picker_sheet_drag_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 실행한다. 기존 날짜/폼/메인 테스트는 확인 확정·오늘 위치·끌어 취소 후 폼 저장값을 검증한다.
- 렌더 역할/의존성/사용 예: 기존 `artifacts/calendar_input_flow_2026-11-12/render_test.dart`에 PICKER_CONFIRM_RENDER_OUTPUT을 추가했다. 예: `PICKER_CONFIRM_RENDER_OUTPUT=artifacts/picker_confirm_drag_2026-11-12 flutter test --no-pub artifacts/calendar_input_flow_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`. 기존 MainTabPage/모의 service/번들폰트 의존성으로 PNG24개·measurements.json을 생성하며 과거 PNG는 보존한다. 토스트/날짜/시간/공개 범위와 일반 미확정 날짜·70px 드래그를 렌더하고 확인 높이/하단·오늘이 달력 위에 있는지·입력 연결/복귀·예외를 검사한다.
- 영향/한계/롤백: 전체 Flutter362 pass/기존 skip1·관련97 pass·렌더1 pass, 변경 Dart9개 분석 진단0건/포맷 변경0건이다. 확인48px/큰글자72px·화면 내 하단·오늘 상단 위치와 예외/조작 경고0건을 확인했다. 날짜/시간/폼 연결·관련 회귀/렌더·문서만 변경했다. 기존 미커밋 서버/DB·공개 레벨1~5·토스트/일정 수정 작업은 보존한다. 최종 검증은 WORKLOG를 따른다. 실제 OS/기기/VoiceOver·서버 인수는 별도이며 전체 다크 테마나 기존 메인 글자3배 문제를 수정하지 않았다. 이번 확인/배치/공용 프레임과 관련 추가분만 되돌린다.

## 개인 일정 공개 레벨1~5 (2026-11-12)

- 기획/최신 정책: ADR-0055. 친구 레벨0은 근무표만 열람하며 개인 일정은1~5·기본1이다. 아래 과거0~5·모든 친구 기본 설명보다 이 정책을 우선한다. 근무표 visibility_level=0·친구 friend_level0~5와 can_view/private는 유지한다. 기존 친구 설정0의 근무표만 공유 설명은 이미 일치해 변경하지 않았다.
- UI/흐름: PersonalEventFormModal의 생성 기본값·슬라이더 min/숫자 버튼·클램프·접근성 감소 경계를1로 바꿨다.1~5의 기존 레벨 문장을 사용하며0 옵션/모든 친구 설명을 제거했다. private 전환은 레벨을 보존한다. 기존0 일정은 읽기를 유지하고 편집 시1 이상으로 보정/저장 안내를 제공한다. 원본 모델/캐시는 저장 전까지 유지하며0→1 보정은 편집 변경에 포함된다. CalendarService 생성/수정 진입에서0/-1/6 등을400 INVALID_VISIBILITY_LEVEL로 차단해 HTTP 요청을 보내지 않는다.
- 서버/DB: 인접 서버의 route/service·Event ORM min1/max5/default1·OpenAPI와 신규 DDL/정본 도면·로컬 AGENTS DDL을 맞췄다. 새 `restrict_event_visibility_levels.sql`은 기존 events0만1로 보정하고 default1/ck_events_visibility BETWEEN1AND5를 적용한다. transaction·lock_timeout·예상 밖 범위 preflight/재실행을 지원하고 private/소유자/ID·시각·근무표/친구 설정·공개 view는 보존한다. 역할·의존성·적용 예/배포 순서·구형 요청 호환·롤백은 [서버 공개 레벨 가이드](../../shift_calendar_server/_docs/EVENT_VISIBILITY_GUIDE.md)를 따른다. 서버 코드 배포와 SQL 적용 전에는 원격 기존0 노출이 해소된 것으로 간주하지 않는다.
- 파일/검증: 기존 폼/서비스·폼/서비스 회귀와 캘린더 입력 렌더러를 갱신했다. 기존 렌더러는 EVENT_VISIBILITY_RENDER_OUTPUT을 지정하면 공개 범위만7조건으로 출력하고 min/max/default를 측정한다. 예: `EVENT_VISIBILITY_RENDER_OUTPUT=artifacts/personal_event_visibility_2026-11-12 flutter test --no-pub artifacts/calendar_input_flow_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`. 새 PNG7개/measurements.json의 역할은 실제 메인 폼에서1~5/default1과0 미노출을 시각/수치로 확인하는 것이며 기존 Flutter/Riverpod·모의 서비스/번들폰트에 의존한다. 과거 PNG는 보존했다. 루트 schema/visibility_flow.drawio는 레벨 의미만 갱신하고 기존 전체 구조 차이는 유지한다.
- 결과/한계/롤백: 전체 Flutter343 pass/기존 skip1·폼/서비스61 pass·시각 렌더1 pass, 서버 관련 HTTP12/격리 PostgreSQL9 pass. 서버 전체의 기존17개 실패는 변경 전후 동일하고 신규 실패0개다. 상세 분석/포맷·한계는 WORKLOG를 따른다. 서버 배포/운영 SQL 적용·원격/실기기 인수/커밋·푸시는 하지 않았다. 이번 레벨 정책 관련 변경만 되돌리되 보정된 데이터와 private/ACL을 다시 공개하는 롤백은 하지 않는다.

## 삭제 오버레이·개인 일정 캘린더와 입력 단계 (2026-11-12)

- 최신 정책: ADR-0053/0054를 따른다. 아래 기존5초·하단 슬롯 토스트와 날짜 휠 설명은 당시 기록이며 이번3초·오버레이·캘린더 선택이 대체한다.
- 토스트/상태: CalendarPage는 기존 본문을 Stack의 원래 크기로 배치하고 Positioned(left/right/bottom16)의 토스트를 겹친다. 본문/일정 카드·추가 버튼의 좌표/크기와 스크롤 모드가 바뀌지 않는다. 토스트 밖 터치를 막는 배리어는 없다. 기본3초/접근성 탐색10초, 묶음 되돌리기·서버 DELETE 지연·실패 복귀·계정/revision·미전송 예약 취소 수명은 기존과 같다. 사용자가 앱 종료 제약을 수용해 영속 큐는 추가하지 않는다. 토스트는 잠시 본문 일부를 덮을 수 있으며 탭 위16px 간격과 SafeArea를 지킨다.
- 날짜/시간: 기존 DatePickerSheet 내부를 TableCalendar 월간 달력으로 교체했다. 날짜 셀을 누르면 즉시 반환하며 기존 날짜 적용 버튼은 제거했다. 요일/선택일·오늘·월 스와이프/화살표·헤더의 기존 YearMonthPickerSheet 빠른 이동과 범위 제한을 제공한다. 일요일/토요일 의미 색상을 유지하고 날짜 셀은 전체 날짜/선택/활성 상태와 탭 semantics를 제공한다. 큰 글자의 두 자리 날짜는 셀 안에서 축소해 줄바꿈/잘림을 막는다. 시간은 기존24시간 휠을 유지하며 스크롤 본문/고정 취소·적용으로 작은/가로/큰 글자에서도 조작할 수 있다. 두 피커 모두 화면 높이/안전영역과 최대폭560을 사용하고 팝업이 완전히 닫힌 뒤 값을 반환한다.
- 입력 안내: 신규 제목의 키보드 완료 → 시작일 캘린더 → 시작 시간 휠 → 종료 시간 휠 → 공개 범위로 스크롤한다. 당일 종료를 기본으로 불필요한 종료 날짜 단계를 줄이고 여러 날 일정은 종료일에서 직접 선택한다. 종일이면 제목 완료 → 시작일 → 종료일 → 공개 범위로 시간을 건너뛴다. 직접 날짜 변경은 해당 시간만 자동으로 열며 수정 모드에 전체 생성 안내를 강제하지 않는다. 빈 제목은 오류/제목 포커스를 유지한다. 각 피커의 취소/OS 복귀는 안내를 중단하고 기존 입력을 보존한다. 신규 안내에서 시작 시각이 종료 이상이면 종료 기본값을 시작+1시간(자정 넘어가면 다음 날)으로 제안한다. 수동 입력의 시간 검증·기존 수정 시각 정밀도·종일 종료 의미는 유지한다. 피커 중복 진입/닫기와 disposed 후 후속 진입을 막는다.
- 영향/파일 역할: CalendarPage·DatePickerSheet·TimePickerSheet·PersonalEventFormModal과 기존 페이지/날짜/폼 회귀를 갱신했다. 공용 시간 피커를 사용하는 근무 타입은 새 높이/스크롤과 전환 완료 대기를 공유하되 선택 계약은 유지한다. 서버/API DTO/DB/env·provider 수명·라우팅·analytics와 기존 미커밋 수정 기능은 보존한다. 날짜 피커는 이미 사용 중인 table_calendar와 YearMonthPickerSheet, 시간 피커는 기존 CupertinoDatePicker에 의존한다.
- 신규 파일 역할/의존성/사용 예: `artifacts/calendar_input_flow_2026-11-12/render_test.dart`는 실제 MainTabPage·기존 Audit fixtures/모의 EditRenderService·번들폰트·Flutter test/Riverpod로 토스트와 캘린더/휠/공개 범위 PNG22개·measurements.json을 생성한다. 루트에서 `flutter test --no-pub artifacts/calendar_input_flow_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 재생성한다. 320/375/390px·큰글자2배·가로/태블릿·다크/동작줄이기에서 토스트 전후 달력·카드 Rect 동일·탭 간격·버튼 높이·예외와 실제 입력 연결을 검사한다. 과거 삭제 토스트/폼 렌더 파일과 PNG는 당시 기록으로 보존한다.
- 검증/한계/롤백: 최종 전체331 pass/기존 skip1·관련 입력/페이지76개/렌더1개 통과, 변경 Dart8개 분석 진단0건·포맷 변경0건이다. 실제 메인7조건/PNG22개에서 예외0건·토스트 전후 달력/카드 Rect 동일과 입력 연결을 확인했다. 상세는 WORKLOG를 따른다. 실기기 키보드/VoiceOver/실서버 인수를 대체하지 않는다. 기존 메인3배 넘침과 앱 전체 다크 테마는 범위 밖이다. 이번 토스트 시간/배치·공용 피커·입력 연결 및 관련 회귀/렌더·문서 추가분만 되돌린다.

## 메인 일정 삭제 토스트와 되돌리기 (2026-11-12)

- 목적/Behavior change: ADR-0052에 따라 본인 개인 일정과 근무를 왼쪽 스와이프하면 즉시 메인 목록/일정 수·근무 배지에서 숨기고 `일정을 삭제했어요. / 되돌리기` 토스트를 하단 탭 위에 표시한다. 기본5초, 접근성 탐색10초이며 연속 삭제는 묶어서 표시하고 마지막 삭제부터 시간을 다시 센다. 되돌리기는 미확정 묶음 전체를 복원한다. 아래 이전 삭제 중 행 표시·즉시 DELETE 설명보다 이 정책을 우선한다.
- 흐름/상태: CalendarPage UI pending maps → Timer → 기존 CalendarService.deleteEvent / WorkShiftService.deleteWorkShift → 성공 후 CalendarRangeNotifier.removeEvent/removeWorkShift → 그룹 캐시 무효화. 유예·요청 중 대상은 ID로 필터링하되 원본 domain 캐시는 보존한다. 여러 날짜 일정/재조회도 같은 ID를 숨긴다. 취소는 UI 필터만 제거해 원본 ID·private·시각·레벨·장소/메모·근무 schedule 참조를 보존하며 생성/복원 API를 호출하지 않는다. notifier는 진행 중 GET별 근무 변경도 보정해 늦은 응답이 성공한 삭제를 복구하지 않게 한다.
- 수명/오류: 시간이 지나 서버 요청을 시작하면 되돌리기 토스트가 닫힌다. 실패한 항목은 다시 표시하고 오류 문자열은 중복 없이 한 다이얼로그에 모은다. EVENT_NOT_FOUND는 기존처럼 제거/안내, INVALID_EVENT_ID는 재조회다. 앱 inactive/hidden/paused/detached와 페이지 dispose는 미전송 예약을 취소하고, 계정 변경은 타이머/대기·진행 UI 상태를 비우고 revision을 증가시킨다. 이미 보낸 요청은 취소하지 못하지만 이전 계정/revision의 완료 결과는 반영하지 않는다. 메인 탭은 IndexedStack으로 유지되므로 탭 변경 중에도 카운트다운은 계속된다. 영속 삭제 큐/새 provider·라우트·analytics·서버/DB/env 변경은 없다. 근무 삭제 대기/요청 중 입력 진입만 잠가 동일 근무 재저장 경합을 막는다.
- UI/신규 파일 역할·의존성·사용 예: `lib/features/calendar/presentation/widgets/calendar_delete_toast.dart`는 Cupertino/AppTheme만 사용하는 표시 전용 위젯이다. CalendarPage가 count/onUndo를 주입하고 타이머를 소유한다. 어두운 불투명 토큰 표면/흰 글자·최소48px 버튼·liveRegion을 사용하며 좁은 화면/큰 글자에서는 문구와 버튼을 세로로 배치한다. 메인 레이아웃의 하단 슬롯/SafeArea에 배치해 목록·추가하기·탭을 가리지 않는다. 친구/그룹 읽기 전용 화면에는 추가하지 않는다.
- 검증/신규 산출물 역할·의존성·사용 예: 기존 calendar_page_test/calendar_range_notifier_test가 유예 경계·취소/원본 보존·재조회/다일·연속/혼합 삭제·오류/404·계정·dispose/앱 수명·접근성/레이아웃·늦은 GET을 검증한다. `artifacts/calendar_delete_undo_2026-11-12/render_test.dart`는 실제 MainTabPage·번들 Cafe24/Cupertino 폰트·Flutter test/Riverpod·기존 design_update fixtures와 personal_event_edit의 EditRenderService를 재사용해 토스트 PNG/measurements.json을 생성한다. 모의 API만 사용하며 루트에서 `flutter test --no-pub artifacts/calendar_delete_undo_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 재생성한다. 크기/배율·토스트 하단/탭 상단·버튼 높이·예외를 기록한다. 최종 전체321 pass/기존 skip1·관련40 pass·변경6개 분석 진단0건이다. 토스트 단독은 글자3배·라이트/다크/안전영역을 포함한32조건, 실제 메인 PNG7개는 글자2배까지 확인했다. 메인3배는 삭제 전부터65px 수평 넘침이 있어 기존 화면은 범위 밖으로 보존했다. 다크는 토스트 검증 범위이며 전체 앱 테마/실기기·VoiceOver/실서버 인수를 대체하지 않는다. 상세 수치와 한계는 WORKLOG를 따른다.
- 롤백: 이번 페이지 삭제 예약/필터·토스트 위젯·근무 조회 보정·관련 회귀/렌더·문서 추가분만 되돌린다. 기존 미커밋 개인 일정 수정·API/폼과 사용자 데이터를 보존한다.

## 개인 일정 탭 수정 구현 (2026-11-12)

- 동작: 메인의 본인 개인 일정 행 전체를 누르면 기존 값을 채운 `개인 일정 수정` 시트를 연다. 오른쪽은 연필/수정 표시이며 왼쪽 스와이프 삭제·둥근 빨간 배경을 유지한다. 충분한 폭에서 삭제 문구, 요청 중 spinner/삭제 중·탭 차단, 스크린리더 삭제 액션을 제공한다. 근무·친구/그룹에는 편집 진입을 추가하지 않는다.
- 흐름: CalendarPage → PersonalEventFormModal(initial_event/onUpdate) → UpdateEventRequest → CalendarService.updateEvent → PUT /events/{event_id} → CalendarRangeNotifier.replaceEvent → 목록/일정 수. 수정 응답 ID/private를 확인하고 그룹 캘린더 캐시를 무효화한다. 선택일이 새 기간에 포함되면 날짜를 유지하고 기간 밖이면 새 시작일로 이동한다. 비교 전 선택일을 날짜로 정규화한다.
- 입력/오류: PersonalEventFormValue를 생성/수정 DTO의 공통 값으로 두고 기존 생성 onSave/CreateEventRequest 반환 계약은 보존했다. 수정 DTO는 장소/메모 null 삭제를 명시한다. 종일 배타적 종료를 표시용 종료일로 역변환하고 미변경 시각의 초/밀리초를 보존한다. 변경 없으면 저장 비활성, 저장 실패는 입력/재시도와 목록 다시 확인을 제공한다. 404는 로컬 제거·안내 후 닫는다. 저장 중 이탈/중복 차단과 기존 확인 없는120px 닫기를 유지한다.
- 상태: replaceEvent는 구 ID를 전체 날짜에서 제거하고 새 기간에 한 번의 state로 반영한다. 진행 중 GET별 mutation 보정으로 늦은 구응답이 수정/삭제를 되돌리지 못하게 한다. refreshMonth는 필요 시 서버 목록으로 해당 범위 일정을 교체한다. 요청 완료 시 mounted/계정을 확인하며 기존 autoDispose를 유지한다.
- UI 영향: 공용 CalendarEventItem의 시간/장소를 Wrap으로 바꿔 320px·큰 글자에서 넘침을 방지한다. 이 줄바꿈 보완은 공용 행을 쓰는 읽기 전용 화면에도 적용되지만 권한/동작은 유지한다. 무변경 저장은 보조색 라벨, 저장 중은 primary 바탕/spinner로 구분한다. ADR-0051과 [수정 API 계약](EVENT_API_GUIDE.md)을 따른다.
- 신규 파일 역할/의존성/사용 예: `artifacts/personal_event_edit_2026-11-12/render_test.dart`는 Flutter test/Riverpod·기존 Audit 인증/친구/알림/그룹 fixtures·실제 MainTabPage/CalendarPage·번들폰트·모의 service를 사용해 목록/수정/저장오류/스와이프/삭제 중과320/375/390px·큰 글자2배·키보드inset·가로·태블릿·동작줄이기 PNG19개와 measurements.json을 생성한다. 루트에서 `flutter test --no-pub artifacts/personal_event_edit_2026-11-12/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 재생성한다. 원격 요청은 하지 않으며 측정값은 저장 높이/하단·뷰 크기·예외를 기록한다.
- 검증/한계/롤백: 최종 결과는 WORKLOG를 따른다. 인접 서버에 PUT·엄격한 검증·소유자/활성 조건부 UPDATE RETURNING·OpenAPI·실제 격리 PostgreSQL/HTTP 테스트를 추가했다. DB migration/env 변경은 없다. Stage/운영 배포·원격 인수/실기기·VoiceOver·다크 테마 검증은 수행하지 않았다. 수정 연결/DTO/service/cache·행 UX 보완과 관련 테스트/문서만 되돌리고 기존 폼 작업·생성/삭제/private 데이터·필터를 보존한다.

## 메인 캘린더 개인 일정 탭 수정 계획 (2026-11-12)

- 상태/목적: [PERSONAL_EVENT_EDIT_PLAN.md](PERSONAL_EVENT_EDIT_PLAN.md)는 구현 전 검토 기록이며 후속 구현은 상단 구현 절/ADR-0051을 따른다. 작성 당시에는 앱/서버 코드를 변경하지 않았다.
- 확인 사실: CalendarPage의 개인 일정 행에는 삭제 Dismissible만 있고 탭이 없다. 폼은 생성 초기값/CreateEventRequest만 지원하고 Flutter 및 인접 로컬 서버에는 개인 일정 수정 API가 없다. EventApiModel에는 편집 필드가 있지만 owner/updated_at이 없으며 addEvent만으로 기간 이동 시 구 날짜 항목을 제거할 수 없다.
- 제안/영향: 서버 PUT /events/{event_id}·JWT 소유권/soft-delete 검증·장소/메모 null 삭제·private 보존을 선행하고, 공용 폼 수정 모드·notifier 원자적 교체/늦은 GET 응답 보정·메인 탭 연결을 순서대로 구현한다. 기존 생성/삭제/근무·친구/그룹 읽기 전용·확인 없는 닫기 정책을 유지한다. 상세 API/선택일/시간·캐시/오류/인수·롤백은 계획 문서를 따른다.
- 수정/삭제 UX 보완 제안: 개인 일정은 행 탭으로 수정하고 기존 왼쪽 스와이프 삭제를 유지한다. 개인 일정의 왼쪽 chevron은 연필+수정으로 교체하고 근무 행은 유지한다. 빨간 삭제 배경은 충분한 폭에서 삭제 텍스트를 보완하며 별도 누르기 버튼으로 바꾸지 않는다. 삭제 중 행 잠금/피드백·스크린리더 삭제 액션·짧은 스와이프 복귀/탭 충돌 인수를 계획 3.1절에 기록했다. 당시 제안은 삭제 확인창·Undo를 추가하지 않았으며, 후속 삭제 되돌리기는 ADR-0052와 상단 토스트 절을 따른다. 구현/시각 검증 전 제안 기록이다.
- 파일 역할/의존성/사용 예: 신규 PERSONAL_EVENT_EDIT_PLAN.md는 현행 Flutter page/form/service/notifier·인접 서버 route/controller/service/OpenAPI·양쪽 drawio와 private 가이드에 근거한 공동 구현 계획이다. 구현 범위 분리·서버 계약 검토·테스트 인수에 사용하며 확정 전 제안과 확인 사실을 구분한다. 설계 확정 ADR은 구현 착수 시 추가한다.
- 검증/롤백: 코드와 계약·문서 링크 및 diff 정합성을 확인한다. 계획 문서 작업이므로 앱 테스트/원격 수정 API 인수는 수행하지 않는다. 이번 계획 파일과 컨텍스트/작업 기록 추가분만 제거하면 된다. 기존 미커밋 변경은 보존한다.

## 누적 작업별 커밋·푸시 검증 (2026-11-11)

- 기존 변경을 디자인 검토·공통 내비게이션/설정/그룹 UI·색상·근무 타입·프로필·개인 일정의 6개 커밋으로 나눠 origin/main에 푸시했다. 커밋별 컨텍스트·ADR·작업 기록과 시안/검증 산출물을 포함했고 앱 코드 추가 변경은 없다. 기존 ADR의 대체 안내와 아래 상세 UI/라우팅 설명의 정합성은 후속 문서 커밋으로 보존한다.
- 전체 Flutter 285 pass·기존 skip 1, 변경 Dart 51개 분석 진단 0건·포맷 변경 0건. 인덱스를 별도 디렉터리로 내보내 후속 기능 없이 내비게이션 14개·색상/기존 폼 40개·근무 타입 24개·프로필 30개가 통과했고, 그룹 플래그 활성 회귀 2개도 통과했다. 코드 원본/최종 인덱스 일치·측정 JSON 10개 파싱·diff 검사를 확인했다.
- 커밋 식별자·원격 일치 결과·검증 한계는 WORKLOG의 같은 날짜 완료 항목을 참조한다. 새 설계/정책은 추가하지 않았으며 실기기·원격 서버 인수는 기존 후속 과제로 유지한다. 롤백은 각 작업 커밋을 의존성 역순으로 git revert한다.

## 개인 일정 슬라이드업 모달과 인라인 공개 레벨 (2026-11-11)

- 최신 입력 디테일(ADR-0050): 날짜/시간 헤더 오른쪽 연도와 종료 아래 기간/다음날/종일 합계 설명을 제거했다. 날짜 선택기·서로 다른 연도의 날짜 버튼·접근성 연도와 시간 검증/종일 저장 의미는 유지한다. 장소·메모는 기본 펼침이며 접기/입력 보존을 지원한다. 공개 레벨은 double 시각 위치와0~5 int 선택/저장을 분리해 드래그 중 연속 이동하고 놓기/숫자 선택 시180ms easeOutCubic으로 정수 위치에 정렬한다. 동작 줄이기는 정렬 애니메이션을 생략하며 접근성 증감은1단위다. 레벨1~5 설명은 `내가 지정한 레벨이 N 이상인 친구에게 보여요.`로 간소화했다. 아래 이전 표시 설명 중 충돌하는 부분은 이 정책으로 대체한다.
- 파일 역할/재현: 기존 폼·폼/저장 회귀를 갱신했다. 기존 `artifacts/personal_event_sheet_2026-11-11/render_test.dart`는 기본 펼침 입력을 직접 검사하고 `PERSONAL_EVENT_RENDER_OUTPUT` 환경변수로 PNG/측정 출력 디렉터리를 바꿀 수 있다. 예: `PERSONAL_EVENT_RENDER_OUTPUT=/private/tmp/personal_event_details_2026-11-11 flutter test --no-pub artifacts/personal_event_sheet_2026-11-11/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`. 기존 렌더 의존성은 동일하며 과거 PNG는 보존한다. 최종 검증/한계·롤백은 WORKLOG 최신 디테일 항목을 따른다.
- 목적/정책: 모달/공개 조절은 ADR-0047, 본문 끌기/확인 없는 닫기는 ADR-0048, 최소 끌기 거리는 ADR-0049를 따른다. CalendarPage의 기존 showCupertinoModalPopup(root, barrierDismissible=false)과 생성 콜백을 그대로 사용하고 기존 캘린더/탭을 dim 배경으로 남긴다. 본문/저장·모의/실서버 계약은 ADR-0046과 같다.
- 모달: 화면88%·최대폭560·상단반경28, 흰 표면·손잡이·중앙17px 제목·닫기48px이다. 키보드가 열리면 화면높이-상단안전영역-12-키보드 높이를 사용하고 시트 전체를 키보드 위에 둔다. 본문최대480/좌우24(360 미만20)·본문스크롤·하단 저장52 이상/안전영역을 유지한다. 손잡이 또는 본문 최상단 아래 끌기로 최대180px 이동하며 시트 이동량120 논리px 이상일 때만 닫는다. 속도가 빨라도120px 미만이면 복귀하며 입력을 보존한다(ADR-0049). 본문은 AlwaysScrollable+Clamping physics와 depth0/사용자 dragDetails/음수 OverscrollNotification/minScrollExtent를 확인해 목록 중간·중첩 스크롤·프로그램 이동을 구분한다. 위로 되밀면 이동량을 줄이며 동작 줄이기에서는 복귀 애니메이션을 생략한다. **Behavior change**: 내용 변경 여부/내용 버리기/계속 작성 확인 로직을 제거해 닫기 버튼·OS 복귀도 바로 닫고 미저장 입력은 사라진다. 저장 중 입력·닫기·중복 요청 차단과 저장 필수 검증은 유지한다. 이미 닫힌 route의 중복 pop을 방지한다. 바깥 탭은 기존처럼 닫지 않는다. 레벨 가로 드래그는 시트를 닫지 않는다.
- 공개 범위: 선택 시트를 없애고 친구에게 공개/나만 보기 세그먼트와 친구 공개 전용0~5 CupertinoSlider를 배치했다. 최신 연속 이동/정수 정렬은 ADR-0050을 따른다. 숫자0~5도 최소44px 버튼으로 선택할 수 있고 선택 숫자/트랙에 primary를 사용한다. 나만 보기에서는 슬라이더를 접되 _visibility_level을 보존해 다시 공개하면 복원한다. 설명은0에서 열람 허용된 친구,1~5에서 내가 지정한 최소 레벨을 표시한다. 기존 is_private boolean/레벨0~5·응답 확인·DTO/서버 정책·날짜 보정·dispose/provider 수명/analytics는 유지한다.
- 파일 역할/의존성/사용 예: 기존 personal_event_form_modal.dart는 시트 크기/키보드·손잡이/본문 overscroll·인라인 공개 컨트롤을 담당하며 CalendarPage 진입부는 유지한다. 기존 personal_event_form_modal_test.dart는 실제 popup·숫자/슬라이더·private 전환·손잡이/본문 상단 끌기·중간 목록/짧은 끌기 복귀·확인 없는 닫기/OS 복귀·바깥 탭/저장 차단을 검증한다. `artifacts/personal_event_sheet_2026-11-11/render_test.dart`는 기존 design_update 렌더러의 공개 모의 auth/calendar/friend/notification/group fixtures·실제 MainTabPage/CalendarPage·번들폰트를 사용해 실제 일정 추가하기 버튼을 누른다. 모의 createEvent는 저장 오류를 반환하며 원격 요청은 수행하지 않는다. Flutter test/Riverpod·모의 SharedPreferences에 의존하고 루트에서 `flutter test --no-pub artifacts/personal_event_sheet_2026-11-11/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로17개 PNG/measurements.json을 재생성한다. JSON은 시트상단/높이/하단·화면/글자배율/키보드·저장/입력 좌표·예외를 기록한다. 직전 시안/렌더는 당시 기록으로 보존한다.
- 검증/한계/영향/롤백: 최종 수치는 WORKLOG를 따른다. [슬라이드업 모달](../artifacts/personal_event_sheet_2026-11-11/normal.png), [인라인 레벨3](../artifacts/personal_event_sheet_2026-11-11/visibility.png), [나만 보기](../artifacts/personal_event_sheet_2026-11-11/private.png). 실제 캘린더 위젯/모의 키보드inset·API 기준으로 실제 OS/VoiceOver/원격 인증 사용자별 인수를 대체하지 않는다. 기존 라이트 테마 범위다. 이번 폼·회귀/렌더·문서만 되돌리며 서버/DB·기존 미커밋 작업은 보존한다.

## 개인 일정 행 중심 구도와 나만 보기 활성화 (2026-11-11)

- 목적/상태: ADR-0046의 직전 구도 기록이다. 후속 슬라이드업 모달/인라인 레벨은 상단 절과 ADR-0047을 따른다. 인접 서버의 Event.is_private·엄격 boolean 검증·createEvent/응답·친구/타인 그룹 view 필터·add_event_privacy.sql·EVENT_PRIVACY_GUIDE를 직접 확인했다. 원격 배포 완료는 사용자/서버 문서 기록이며 이 작업에서 별도로 원격 인증 저장/권한별 실응답을 확인한 것은 아니다.
- UI: 기존 카드 테두리/중첩 입력을 제거하고 흰 단일 바탕의 제목 → 날짜/시간 → 공개 범위 → 접는 장소/메모 → 하단 저장으로 구성했다. 제목26px 무배경·상단17px 본문 계열·본문16/보조14·좌우24(360 미만20)·최대480이다. 날짜/시간은 시작/종료 라벨·날짜·작은 시간 배경의 행이며 영역은0.5px 구분선, 영역간20px을 사용한다. 일반375/390px에서 장소/메모 진입까지 첫 화면에 보인다. 가용너비300 미만 또는16pt 확대크기20 초과 시 날짜/시간을 세로로 쌓는다. 연도는 영역 헤더에 보이며 시작/종료 연도가 다르면 날짜 버튼에 각각 연도를 표시한다. 실제 Cafe24/Cupertino·기존 색상/테마를 재사용하고 글로벌 테마는 변경하지 않았다.
- 상태/Behavior change: 나만 보기를 선택 시트의 실제 옵션으로 활성화하고 자물쇠·친구/그룹 미공개 설명을 표시한다. UI의 _is_private와 _visibility_level을 분리해 private를 선택해도 레벨을 보존하고 친구 공개로 되돌릴 수 있다. 생성 요청은 is_private boolean을 명시 전송한다(기존 공개 기본 false). API EventApiModel.isPrivate 및 그룹 domain GroupCalendarEvent.is_private/파서는 생략 응답을 false로 처리한다. private 생성 응답이 true가 아니면 CalendarService가 EVENT_PRIVACY_NOT_CONFIRMED를 반환하고 성공으로 닫지 않는다. 생성 후 결과 불일치이므로 저장 취소/보안 보장으로 해석하지 않으며 사용자는 목록에서 실제 공개 범위를 확인해야 한다. 서버 필터와 선배포 전제는 유지한다. 종일/기간·날짜 보정·입력 보존/이탈/로딩/재시도·dispose·provider/라우트·analytics 정책은 ADR-0045와 같다.
- 파일 역할/의존성/사용 예: 기존 personal_event_form_modal.dart의 구도/공개 선택, event_api_model.dart의 요청/응답 boolean, calendar_service.dart의 private 응답 확인, group_models.dart와 group_repository_impl.dart의 서버 필드 보존을 변경했다. 기존 폼·이벤트 모델·calendar service·그룹 repository 테스트에 true/false/생략·구형 호환·레벨 보존·선택 취소/공개 전환·생성 응답 불일치를 추가했다. 신규 `artifacts/personal_event_layout_2026-11-11/render_test.dart`는 직전 렌더러를 기반으로 실제 위젯/번들 Cafe24·Cupertino 폰트·Flutter test로17개 PNG/measurements.json을 생성한다. 루트에서 `flutter test --no-pub artifacts/personal_event_layout_2026-11-11/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 재생성한다. 화면크기·글자배율·키보드inset·저장좌표/높이·입력좌표·예외를 기록하고 첫 화면의 추가정보 접근과 재페인트 후 저장 라벨 픽셀도 검사한다. 나만 보기 캡처는 예시 선택 상태이며 실제 서버 저장 캡처가 아니다. 이전 시안/렌더는 당시 기록으로 보존한다.
- 검증/영향/롤백: 최종 수치는 WORKLOG를 따른다. [새 기본 구도](../artifacts/personal_event_layout_2026-11-11/normal.png), [나만 보기](../artifacts/personal_event_layout_2026-11-11/private.png), [375px](../artifacts/personal_event_layout_2026-11-11/phone375.png). 기존 라이트 테마·모의 repository/위젯·키보드inset 범위이며 실기기/원격 권한별 인수를 대체하지 않는다. 서버/DB·기존 미커밋 작업은 보존한다. 이번 구도/boolean 연동·응답 확인·검증/문서만 되돌리고 서버의 private 컬럼·필터는 유지한다. 서버 요청서는 별도 외부 전달 없이 문서로 제공한다는 사용자의 후속 지시를 유지한다.

## 개인 일정 추가 재설계 구현과 나만 보기 서버 요청 (2026-11-11)

- 목적/상태: 첫 번째 재설계 적용 당시 기록이며, 후속 구도/나만 보기 활성화는 상단 절과 ADR-0046을 따른다. CalendarPage → 인증 후 기존 root showCupertinoModalPopup → 기존 CalendarService.createEvent/POST events → calendarRangeProvider 갱신 흐름과 별도 analytics 미도입을 유지했다.
- UI: 제목22px → 날짜/시간 카드(종일·시작/종료·기간) → 문장형 공개 범위 카드 → 접는 장소·메모 카드 → 하단 단일 일정 저장이다. 0~5 선택 시트와 can_view 전제를 포함한 설명을 사용하고 숫자 트랙·큰 선행 메모·장소 다이얼로그·반복 미지원 행을 제거했다. 뒤로가기는 기존 화살표/공통 내비게이션 재질을 사용한다. 좌우20(360 미만16), 본문최대480, 카드패딩/반경16·입력반경12·최소높이52, 섹션24·필드16, 상단20·영역18·본문16·보조14와 기존 AppTheme 색상/Cafe24를 사용한다. 날짜/시간은 카드 가용너비300 미만 또는16pt 확대크기20 초과 시 세로로 배치한다. 큰글자는 줄바꿈/세로확장하며 입력/오류를 스크롤한다.
- Behavior change: 선택정보는 기본 접힘·직접 입력이며 접어도 보존한다. 종일을 껐다 켜도 시간값을 보존한다. 기간/다음날 종료 안내, 제목/시간 인접 검증과 첫 오류 포커스/스크롤, 실패 시 입력 보존/하단 다시 저장, 실질 변경 후 이탈 확인을 제공한다. 본문 pointer 기반 아래로 끌어 닫기는 제거했으며 뒤로가기/OS maybePop이 확인 흐름을 따른다. 저장 중 입력·뒤로가기·중복 저장을 차단하고 성공/미변경 복귀는 확인하지 않는다. 키보드는 scaffold resize와 분리된 하단 저장으로 반영하며 안전영역을 유지한다. 날짜 양끝 선후 자동보정·초기 선택일09~10시/레벨0·UTC 전송·빈 선택정보 생략은 보존한다. 종일 배타적 종료는 날짜 생성자로 다음 날00:00을 계산한다.
- 상태/서버: controllers·focus nodes·scroll·입력 오류/상세 펼침·이탈/저장 상태는 화면이 소유하고 dispose한다. 기존 domain state/provider 수명과 생성 DTO/API는 유지한다. 현재 서버 Event 모델/생성/본인조회·친구/그룹 SQL·정본 뷰를 직접 확인했다. is_private가 없으므로 나만 보기는 선택 불가이며 서버 준비 중이라고 표시한다. 레벨5/범위 밖 숫자나 알 수 없는 필드로 private를 저장하지 않는다. 서버 요청서는 별도 boolean·친구/타인 그룹 차단·본인 보존·엄격한 검증·view 컬럼 순서 보존 migration·선배포/인수·private가 공개되지 않는 롤백을 제안한다. 서버 구현·배포·외부 메시지 발송은 하지 않았다.
- 파일 역할/의존성/사용 예: 기존 personal_event_form_modal.dart는 화면/입력/콜백, form_save_state_test.dart는 실패 후 제목/메모 보존 회귀를 갱신했다. 신규 `test/features/calendar/presentation/widgets/personal_event_form_modal_test.dart`는 Flutter test·intl과 공용 날짜/시간 시트로 생성 DTO·선택정보 보존·레벨0~5/나만보기 차단·필수/시간 오류·종일/야간/날짜보정·이탈/비동기 재시도를 검증한다. 신규 `artifacts/personal_event_redesign_2026-11-11/render_test.dart`는 실제 위젯·Flutter test·번들 Cafe24/Cupertino 폰트로 16개 PNG/measurements.json을 만든다. 루트에서 `flutter test --no-pub artifacts/personal_event_redesign_2026-11-11/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 재생성한다. JSON은 화면크기·글자배율·키보드 inset·저장좌표/높이·입력하단·예외를 기록한다. 신규 `_docs/PERSONAL_EVENT_PRIVACY_SERVER_HANDOFF.md`는 인접 Express/Sequelize 코드와 최종 DDL을 근거로 한 담당자 전달용 서버 구현 요청서이며 Stage/운영 인수 체크리스트를 사용한다. 종전 HTML 시안은 당시 기록으로 보존한다.
- 검증/한계/영향/롤백: 최종 수치는 WORKLOG의 완료 항목을 따른다. 320/375/390px·큰글자2배·키보드inset·가로·태블릿·공개시트의 실제 Flutter 렌더와 주요 PNG를 확인했다. [기본 화면](../artifacts/personal_event_redesign_2026-11-11/normal.png), [선택 정보](../artifacts/personal_event_redesign_2026-11-11/details.png), [저장 오류](../artifacts/personal_event_redesign_2026-11-11/save_error.png). 키보드는 모의 inset이며 실제 OS·VoiceOver·실서버 검증을 대체하지 않는다. 앱 현행 라이트 테마 범위다. 이번 폼·테스트/렌더·문서만 되돌리면 직전 UI로 복구되며 DB 작업은 없다. 기존 미커밋 작업은 보존한다.

## 개인 일정 추가 화면 재설계 제안 (2026-11-11)

- 상태/목적: 당시 사용자에게 일반 캘린더의 입력 데이터와 ShiftMate에 맞는 요소·배치·크기·색상을 제안한 기록이다. 후속 승인으로 구현했으며 최신 동작은 상단 구현 절과 ADR-0045를 따른다. 당시 폼 전체·CreateEventRequest/EventApiModel·CalendarPage 진입/저장 콜백·AppTheme·EVENT_API_GUIDE·ADR-0002/0038 및 기존 캡처를 확인했다.
- 확인한 계약: 제목·종일·시작/종료·공개 레벨은 필수 요청 값이며 장소·메모는 선택이다. 초기 선택일·09:00–10:00·종일 해제·레벨0은 기존 기본값이다. 사용자 1명=캘린더 1개이므로 캘린더 선택은 제안하지 않는다. 반복/알림/참석자/색상은 개인 일정의 현재 요청 필드에 없다. 공개 조건은 친구 관계·can_view=true·친구 레벨>=일정 레벨이며, 레벨5도 나만 보기가 아니다. 실제 인원 데이터 없이 공개 대상 수나 명단을 표시하지 않는다. 두 drawio는 확인했으나 calendars/calendar_shares 기반 구형 구조이므로 현행 단일 캘린더 DDL·모델·ADR을 기준으로 한다.
- 제안: 전체 화면의 뒤로가기/제목 → 제목 → 날짜와 시간 → 공개 범위 → 접을 수 있는 장소·메모 → 하단 고정 단일 일정 저장. 큰 메모가 날짜보다 먼저 차지하는 공간을 줄이고, 장소는 선택 영역 안에서 바로 입력한다. 반복 미지원 행은 제거를 제안한다. 공개 범위는 숫자만 있는 트랙 대신 설명형 선택 행/선택 시트로 0~5를 고르며 조건을 문장으로 함께 보여준다. 나만 보기·반복·시작 전 알림은 별도 요구/서버 계약이 필요한 후속 후보이고, 현재 지원하는 기능으로 제시하지 않는다.
- 규격/색상: Flutter 논리 픽셀 기준 좌우20(작은 화면16), 카드 반경/패딩16, 필드 반경12·높이52 이상, 섹션24·필드16·라벨/값8, 제목입력22·상단20·섹션18~20·본문16·보조14, 아이콘20~24·실효 터치 iOS44/Android48 이상. 넓은 화면 본문 최대480, 작은 화면/큰 글자는 날짜·시간을 세로 확장한다. 기존 primary #0061A4·배경 #F8F9FB·표면 #FFFFFF·입력 #F2F4F6·본문 #191C1E·보조 #414750·경계 #C1C7D2·오류 #B3261E를 사용한다. 시안은 앱의 현행 라이트 테마 범위이며 실제 Flutter 적용 시 Cafe24/Cupertino를 유지한다.
- Behavior change 제안: 입력 후 이탈 확인, 필드 인접 오류·첫 오류 포커스, 저장 실패 입력 보존·하단 재시도, 시간 합계/다음 날 표시, 키보드 위 저장과 안전영역/스크롤 확보를 권장한다. 종일은 사용자가 고른 종료일까지 표시하고 저장 시 다음 날00:00의 배타적 종료 계약을 유지한다. 자동 시간 조정·중복/근무 충돌 안내는 정책 확정 전 도입하지 않는다. 시안은 종일 전환·기간 요약·레벨 설명·선택정보 펼침·검증/첫 필드 포커스·폐기/계속 작성·모의 저장만 동작하며, 저장 버튼은 실제 서버에 전송하지 않는다.
- 신규 파일 역할/의존성/사용 예: `artifacts/personal_event_proposal_2026-11-11/personal-event-editor.html`은 대화에서 조작하는 독립 HTML 조각이다. 날짜/시간·공개 레벨·종일·제목을 바꿔 보고 장소·메모를 펼친다. 외부 통신/앱 의존성 없이 시스템 폰트·브라우저 기본 날짜/시간/선택 입력을 사용하며 호스트 Lucide와 선택적 Tweak(카드 반경/섹션 간격)을 지원한다. 선택적 호스트 상태에는 종일/레벨만 저장하며 제목·장소·메모를 저장하지 않는다. 2026-11-11/09:00–10:00·placeholder 장소는 시연 예시다. 실제 Flutter 날짜/시간은 기존 공용 시트를 재사용할 제안이다.
- 검증/한계/롤백: Node VM에서 조각 형식/ID 유일성/리터럴 마크업·JS 문법·필수제목/공백/포커스·모의 저장·역전/동일시간·1/3일 종일·다음 날9시간·종일 재전환·레벨0~5 설명·폐기/계속작성/초기화를 확인했다. 독립 preview wrapper 생성도 통과했다. headless Chrome은 이 환경에서 종료코드134로 실행되지 않았고 실제 브라우저/Flutter·실기기·키보드·큰글자·VoiceOver 시각 검증은 하지 못했다. UI UX 검색의 제품 결과(캘린더/일정 앱)와 라벨/제출 피드백만 참고했으며 초기 시스템 검색의 랜딩/새 팔레트/폰트는 채택하지 않았다. Flutter 세부 검색은 두 번 모두 일치가 없어 해당 부분은 스킬 기본 원칙·기존 코드와 토큰을 근거로 제안했다. Google 공식 일정 생성/Events API 문서로 일반 입력 범위를 확인했다. 이번 시안과 컨텍스트/작업로그 항목만 제거하면 롤백된다. 기존 미커밋 작업·앱·API·DB·ADR은 변경하지 않는다.

## 글라스 내비게이션 (2026-11-11)

- 목적/범위: 사용자 요청으로 하단 탭을 둥근 플로팅 글라스 스타일로 바꾸고 공통 상단 바 재질을 맞췄다(ADR-0044). Flutter의 제한된 BackdropFilter·반투명 그라데이션으로 표현하며 Apple 시스템 Liquid Glass의 굴절/광학 효과를 구현한 것은 아니다.
- 하단: 좌우 16px·최대 너비 480px·반경 28px·내부 4px·일반 높이 64px이다. 홈 인디케이터 안전영역과 바 사이에 추가 8px(안전영역이 없으면 합계 최소 16px)을 확보한다. 흰색/어두운 표면의 94→82% 농도와 18px 블러·얕은 그림자를 사용한다. 기존 Column에서 본문과 바 공간을 분리하며 일정 카드와 바 경계의 16px 간격을 유지한다. 아래에 겹치는 일정이 없어 글라스의 뒤 배경 변화는 제한적이다.
- 선택/접근성: 선택 탭에는 읽기 가능한 전경색의 10% 배경을 표시한다. 아이콘·텍스트·탭별 읽음 수 의미를 유지하고 180ms 색상 전환은 동작 줄이기에서 생략한다. 고대비는 불투명 표면/블러 끄기를 사용한다. 알림 `99+`는 고정 아이콘 슬롯 안에 두고 숫자 글자 확대만 최대 1.2배로 제한해 둥근 경계의 잘림을 막는다. 탭 라벨은 시스템 확대를 따르며 접근성 라벨은 실제 전체 미읽음 수를 읽는다. 숫자 바탕은 기존 error_text_color를 사용한다.
- 상단: AppTheme.lightTheme/darkTheme의 `navigation_bar_color`를 공유한다. CupertinoNavigationBar의 기존 스크롤 배경 전환·블러를 사용하며, 정지 상태에는 scaffold 배경을 표시할 수 있다. 제목·뒤로가기 위치/동작·탐색 경로는 유지하고 별도 캡슐 장식을 추가하지 않는다. 설정·근무 패턴의 개별 불투명 배경/굵은 경계 override를 제거해 같은 테마를 따른다. API/DB·인증/탭 이력·provider 수명·analytics 정책은 유지한다.
- 파일 역할/의존성/사용 예: 기존 `main_tab_page.dart`는 글라스 바와 선택 표시, `app_theme.dart`는 공통 내비게이션 색상/치수, 설정/근무 패턴 페이지는 공통 헤더 재질을 사용한다. 신규 `artifacts/glass_navigation_2026-11-11/render_test.dart`는 기존 design_update 렌더러의 공개 모의 repository/notifier·번들 폰트·실제 페이지로 PNG와 `measurements.json`을 만든다. 루트에서 `flutter test --no-pub artifacts/glass_navigation_2026-11-11/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 재생성한다. 각 PNG는 같은 이름의 화면/조건 캡처이며 JSON은 크기·글자배율·접근성 조건·바/배지 좌표·카드 간격·예외를 기록한다. 계정/알림 수는 예시다. [캘린더](../artifacts/glass_navigation_2026-11-11/calendar.png), [설정 헤더](../artifacts/glass_navigation_2026-11-11/settings.png), [큰 글자](../artifacts/glass_navigation_2026-11-11/text2.png).
- 검증/한계/롤백: 최종 수치는 WORKLOG 완료 항목을 따른다. 앱은 기존 라이트 테마이며 dark_navigation 캡처는 하단 재질/전경만 확인한다(앱 전체 다크 모드 도입 아님). 모의 위젯 렌더로 실제 기기의 프레임 성능·VoiceOver·OS 투명도 줄이기 연동을 검증하지 않았다. 이번 테마/바/두 헤더·렌더/문서 변경만 되돌리면 직전 디자인으로 복구한다.

## 프로필 수정 재설계 구현 (2026-11-11)

- 목적/상태: 아래 시안의 사용자 승인으로 `ProfileSetupPage.edit`에 실제 적용했다. 최신 정책은 ADR-0043이다. 인증 사용자 설정의 프로필 카드 → 기존 CupertinoPageRoute → 수정 → 성공 시 설정 복귀 흐름과 별도 analytics 미도입을 유지한다.
- UI: 72px 사진/20px 이름 요약·44px 사진 변경 → 기본 정보(이름·휴대폰) → 선택 근무 정보(직종·소속/부서) → 읽기 전용 이메일 → 고정 저장이다. 후속 사용자 피드백으로 기본·근무·계정 정보를 각각 16px 반경/패딩 카드로 묶었다. 제목은 20px 제목 폰트·32px 바탕의 18px 영역 아이콘, 라벨은 14px/굵기600, 값은 16px로 위계를 나눈다. 카드 제목과 내용은 20px, 카드 사이는 24px이다. 기본/근무 카드는 흰색, 입력은 background, 읽기 전용 계정 카드는 surface_container_low를 사용한다. 필수 항목은 시각적으로 `이름 *`·`휴대폰 번호 *`의 오류 색상 기호로 표시하며, 스크린리더는 이름/휴대폰 번호와 필수 의미를 읽는다. 반복 안내·필드 장식 아이콘·섹션 필수/이메일 인증됨 배지는 편집에서 제거했다. 입력/버튼 최소 52·반경 12, 좌우 20(360 미만 16)·필드 간격 16·보조 14·전체 최대 너비 480이다. 확대 시 세로 확장/스크롤하며 하단은 safe area와 키보드 inset을 반영한다. 실제 Flutter는 Cafe24/Cupertino를 사용한다.
- Behavior change: 이름/선택값의 trim 결과·전화 숫자·사진 선택을 비교해 실질 변경이 없으면 저장을 비활성화한다. 이름·휴대폰은 포커스 이탈 후 검증하고, 저장 오류는 첫 필드로 포커스/스크롤한다. 변경 후 뒤로가기와 OS maybePop은 계속 수정/버리기를 확인하고, iOS edge swipe는 PopScope가 변경 중 시작을 막는다. 저장 성공·미변경 복귀는 확인하지 않는다. 서버 실패는 입력/사진을 보존하고 하단에 오류·다시 저장을 표시한다. 사진 선택/저장 중 입력·뒤로가기·중복 액션을 막는다.
- 상태/API: 편집 UI state(controllers·focus nodes·scroll·이미지 bytes·오류·변경/이탈 상태)는 화면이 소유하고 dispose한다. 최신 사용자 domain state와 이미지 cache 갱신은 기존 authProvider 흐름이다. 일반 수정 endpoint·변경 필드만 전송·미변경 레거시 전화 예외·빈 선택값 삭제·타임존 유지·이미지 1024px/품질85/5MB 및 가입 완료 흐름은 유지한다. 가입 화면은 기존 표시·저장 동작을 사용한다. 사진/자유 직종의 원격 서버 반영은 기존 PROFILE_EDIT_SERVER_HANDOFF의 미확인 인수 조건을 유지한다.
- 파일 역할/의존성/사용 예: 기존 profile_setup_page.dart에 편집 표시와 `_ProfileEditField`를 추가했다. 기존 AppTheme에 `error_text_color=#B3261E`를 추가해 새 편집 오류 문구에만 사용한다(현재 배경 대비 계산 6.20:1). 기존 프로필/설정 테스트는 새 버튼 활성화 프레임·폐기 확인·재시도에 맞춰 갱신했다. 신규 `artifacts/profile_edit_redesign_2026-11-11/render_test.dart`는 Flutter test·Riverpod 모의 repository·번들 Cafe24/Cupertino 폰트로 일반/수정/저장 실패/320px/375px/큰 글자2배/모의 키보드/가로/태블릿의 14개 PNG와 measurements.json을 생성한다. 루트에서 `flutter test --no-pub artifacts/profile_edit_redesign_2026-11-11/render_test.dart`로 재생성한다. [기본 화면](../artifacts/profile_edit_redesign_2026-11-11/normal.png), [계정 정보](../artifacts/profile_edit_redesign_2026-11-11/normal_bottom.png), [변경 후](../artifacts/profile_edit_redesign_2026-11-11/edited.png). 이름·전화·이메일·기관은 예시다.
- 검증/영향/롤백: 최종 테스트/분석 수치는 WORKLOG의 완료 항목을 따른다. 위젯/모의 repository·키보드 inset 검증으로 실제 OS 사진/키보드·실서버·VoiceOver 인수를 대체하지 않는다. 앱 기존 라이트 테마 범위다. 이번 화면·테스트·렌더·문서 변경만 되돌리면 직전 디자인으로 복구되며 DB 마이그레이션은 없다. 기존 미커밋 작업은 보존한다.

## 프로필 수정 화면 재설계 제안 (2026-11-11)

- 상태/목적: 당시 사용자에게 요소·배치·크기·색상 제안을 제공한 기록이며 후속 승인으로 구현했다. 최신 동작은 상단 구현 절과 ADR-0043을 따른다. 기존 ProfileSetupPage 전체·AppTheme·최신 편집 캡처와 관련 컨텍스트/ADR/WORKLOG를 확인했다.
- 제안: 상단 뒤로가기/제목 → 72px 사진·이름 요약/44px 사진 변경 → 기본 정보(이름·휴대폰) → 선택 근무 정보(직종·소속/부서) → 읽기 전용 이메일 → 하단 단일 저장. 반복 편집 안내·필드별 장식 아이콘·섹션 필수 배지는 줄이고 필드 라벨에 필수를 표시한다. 근무 정보 삭제 안내는 보존한다. 인증 여부를 증명하는 데이터 없이 이메일에 인증됨 배지를 표시하지 않는다.
- 규격: Flutter 적용 제안의 논리 픽셀 기준 좌우 20(작은 화면 16), 섹션 24, 필드 16, 입력/버튼 최소 높이 52, 입력 반경 12, 계정 카드 16, 본문 16/보조 14/제목 18/이름 요약 20. 넓은 화면은 기존 공통 480 최대 너비를 따르고 글자 확대 시 세로 확장/스크롤한다. AppTheme의 primary #0061A4·배경 #F8F9FB·표면 #FFFFFF·본문 #191C1E·보조 #414750·경계 #C1C7D2를 유지한다.
- Behavior change 제안: 변경 없을 때 저장 비활성화, 포커스 이탈 후 필드 인접 검증과 첫 오류 포커스, 변경 후 이탈 확인, 서버 실패의 입력 보존과 재시도 안내를 권장한다. 시안은 변경 감지·이름 요약·모의 저장·필수 오류/첫 오류 포커스·예시 복원을 구현하며 실제 route 이탈 확인/비동기 업로드·서버 실패는 구현하지 않는다. 실제 앱 적용 시 기존 미변경 레거시 전화 검증 예외·부분 수정·빈 선택값 삭제·타임존 유지 계약을 보존해야 한다.
- 신규 파일 역할/의존성/사용 예: `artifacts/profile_edit_proposal_2026-11-11/profile-editor.html`은 대화에서 탐색하는 독립 HTML 조각이다. 외부 통신/앱 의존성 없이 예시 이름·전화·직종·소속을 바꾸고 변경 전 상태로 복원한다. 사진은 브라우저에서 로컬 미리보기만 하며 서버 전송하지 않는다. 호스트 Lucide/선택적 Tweak(반경·섹션 간격·사진 크기)을 사용한다. 시안은 라이트 테마·시스템 폰트이며 실제 Flutter에서는 기존 Cafe24/Cupertino를 유지한다. 이름·전화·이메일·기관은 예시다. 화면 전체를 펼친 시안으로 하단 고정/키보드 동작은 실제 Flutter 검증 대상이다.
- 검증/영향/롤백: Node VM으로 마크업 ID 유일성·리터럴 조각·JS 문법과 변경 감지/미변경 비활성/이름 미리보기/모의 저장/필수 오류/첫 오류 포커스/취소 복원/선택 정보 비우기를 확인했다. diff 검사 통과. 실제 브라우저 렌더·사진 파일 선택·Flutter/실기기·큰 글자·VoiceOver는 미검증이다. 앱·서버·DB·기존 ADR 변경 없음. 시안과 이번 컨텍스트/로그 항목만 제거하면 롤백된다. UI UX Pro Max의 초기 전체 시스템 검색은 웹 랜딩/금색 방향이라 채택하지 않았고, 후속 라벨/인접 검증 결과와 기존 토큰을 사용했다.

## 근무 타입 편집 재설계 구현 (2026-11-11)

- 목적/상태: 사용자가 아래 시안의 적용을 요청해 공용 추가/편집 화면에 반영했다. 정책은 ADR-0041과 기본값/뒤로가기 후속 ADR-0042다. 기존 root route·인증 조건·저장 콜백·Riverpod 갱신 흐름을 유지하고 별도 analytics는 추가하지 않는다.
- UI: 52px 원형 코드와 이름/시간 요약, 이름 → 캘린더 표시 코드 → 표시 색상 → 시간 지정 스위치, 상단 뒤로가기 화살표와 하단 단일 저장이다. 본문 16/보조 14·입력 반경 12·최소 터치 44·최대 본문 너비 480을 사용한다. 시간 필드는 가용 너비 340 미만 또는 16pt 확대 크기 20 초과 시 세로로 배치한다. 폼은 SingleChildScrollView로 전체 입력을 유지하며 하단 버튼은 스크롤과 분리하고 안전영역/키보드를 반영한다.
- 시간: 기존 시간 중 하나라도 있으면 지정 상태, 신규는 시간 지정 켬으로 시작하고, 기존 시간 없는 타입은 해제로 복원한다. 스위치를 꺼도 폼 메모리에 시간을 보존해 저장 전 다시 켜면 복원한다. 해제 저장은 기존 수정 DTO가 start_time/end_time을 명시적 null로 전송하고 생성 DTO는 생략한다. 지정 상태는 두 시간이 모두 있어야 저장한다. 다음 날/총 시간은 로컬 서버 shiftTemplateService.calculateTimeInfo와 대조한 분 단위 간격으로, 휴게시간을 차감하지 않으며 시작=종료는 기존 서버처럼 0시간이다.
- 입력/오류: 이름 키보드 다음은 코드, 코드 완료는 닫기다. 시간은 버튼으로 선택하며 시작 적용 후 종료 시트를 연다. 중복 코드는 기존 포커스 이탈/저장 시점 검증·안정적인 TextField/오버레이를 유지한다. 필수 이름/코드와 시간 쌍 오류는 각 필드 옆에 표시하고 첫 오류로 포커스/스크롤한다. 서버 오류는 하단 저장 옆에서 입력을 보존한다. 저장 중 입력·뒤로가기·중복 요청을 차단한다. 모든 controller/focus/scroll/notifier는 화면에서 dispose한다.
- 파일 역할/의존성/사용 예: 기존 shift_type_form_modal.dart와 폼/저장 테스트를 수정했다. 신규 `artifacts/shift_type_redesign_2026-11-11/render_test.dart`는 실제 위젯·번들 Cafe24/Cupertino 폰트·Flutter test로 일반/무시간/추가/320px/큰 글자 2배/키보드 inset/가로/태블릿의 12개 PNG와 measurements.json을 생성한다. 루트에서 `flutter test --no-pub artifacts/shift_type_redesign_2026-11-11/render_test.dart`로 재생성한다. [편집 화면](../artifacts/shift_type_redesign_2026-11-11/normal.png), [시간 요약](../artifacts/shift_type_redesign_2026-11-11/normal_bottom.png), [오프](../artifacts/shift_type_redesign_2026-11-11/no_time.png). 이전 시안/캡처는 당시 기록으로 보존한다.
- 검증/영향/롤백: 최종 검증 수치는 WORKLOG를 따른다. 앱의 기존 라이트 테마·모의 위젯/콜백 검증 범위이며 실기기/실서버/VoiceOver 검증을 대체하지 않는다. 폼·회귀/렌더·문서만 변경하며 이번 변경만 되돌리면 직전 UI로 복구된다. API/DB/색상 저장·기준색/농도 계약은 유지한다.

## 근무 타입 편집 화면 재설계 제안 (2026-11-11)

- 상태/목적: 당시 디자인 제안이며 후속 사용자 요청으로 구현했다. 최신 동작은 상단 구현 절과 ADR-0041/0042를 따른다. 현재 폼과 ADR-0009/0015/0038/0040을 기준으로 정보 위계와 시간 없는 타입의 발견 가능성을 검토했다.
- 제안: 96px 단독 원형을 코드·이름·시간의 작은 요약으로 바꾸고, 이름 → 캘린더 표시 코드 → 색상 → 근무 시간 순으로 편집한다. 시간 지정 스위치, 다음 날 종료/총 시간 안내, 하단 단일 저장 버튼과 필드 인접 오류를 권장한다. 앱의 파랑·중립 배경·16px 본문을 유지한다.
- Behavior change 제안: 시간 지정 해제 시 두 시간을 전송하지 않는 선택을 명시한다. 이는 기존 개별 X 삭제/중간 상태 허용 정책(ADR-0009)과 달라 채택 시 ADR 갱신과 기존 시간 복원·null 전송 확인이 필요하다. 시간 합계는 휴게시간을 차감하지 않는 단순 간격이며 동일 시작/종료의 24시간 의미는 확정하지 않는다. 코드 중복·색상 기준색/농도·비동기 저장 계약은 유지해야 한다.
- 파일 역할/의존성/사용 예: `artifacts/shift_type_proposal_2026-11-11/shift-type-editor.html`은 대화에서 보는 독립 HTML 시안이다. 외부 통신·앱 의존성 없이 이름/코드/색상/시간을 바꾸어 결과를 살펴본다. 선택적인 호스트 Tweak은 모서리만 조절한다. 시스템 폰트와 브라우저 시간/색상 입력은 시연용이며 실제 구현에서는 기존 Cafe24·Cupertino·색상 페이지를 사용한다. 야간/N/22:00–07:00은 예시 데이터다.
- 검증/영향/롤백: HTML ID/리터럴 마크업·JS 문법 확인과 Node VM의 시간 유무/다음 날 9시간/코드 미리보기/필수 입력/예시 복원 동작 확인. 실제 브라우저·Flutter 렌더·실기기 검증은 수행하지 않았다. 앱·API·DB·기존 ADR은 변경하지 않았으며 시안과 이번 문서 항목만 제거하면 된다.

## 커스텀 색상 선택 재디자인 (2026-11-11)

- 프리셋 여백 보정: 카드 내부 GridView의 패딩은 0으로 명시해 safe-area가 중첩되지 않도록 한다. 카드의 16px 패딩만 적용하며, 렌더러가 첫/마지막 행의 위아래 간격(테두리 포함 각각 17px)을 측정한다. 수정 전 아래쪽에 추가되던 34px을 제거했다.
- 농도 통합 완료(ADR-0040): 사용자 승인에 따라 프리셋 화면은 선택/완료와 `선택한 색상 조절` 진입만 제공한다. 농도 슬라이더는 커스텀의 RGB 아래에 있다. HEX/RGB/휠은 기준 색상을 편집하고 농도는 별도 유지한다. `적용될 색상`은 흰색 혼합 후 최종 RGB를 표시한다. 최신 ADR-0069는 키보드 여부와 관계없이 미리보기를 고정하고 낮은 본문에서는 작게 표시한다. 프리셋 새 선택은 100%, 커스텀 완료/재진입은 기준색/농도를 보존하고 취소는 원래 선택을 유지한다.
- 최근 색상: `shift_custom_recent_selections_v2`에 기준 HEX/정수 농도의 JSON 문자열 목록을 저장한다. 유효 값만 복원하며 최종 RGB 기준 중복 제거·최신순·최대 6개다. v2에 유효 기록이 없으면 v1 RGB를 기준색/100%로 복원한다. 완료 시 v1에도 최종 HEX를 기록해 이전 버전과 호환한다. API/DB의 base_color/color_intensity 및 불투명 흰색 혼합 계약은 변경하지 않는다.
- 신규 `lib/features/calendar/presentation/widgets/shift_color_selection.dart`: 두 선택 화면이 공유하는 결과값 `ShiftColorSelection`과 `calculateShiftColor`를 기존 프리셋 파일에서 이동했다. 의존성은 dart:ui이며 예: `calculateShiftColor(const Color(0xFF4355B8), 50)` → `0xFFA1AADC`. 기존 프리셋 파일도 이 파일을 export해 호출부 호환성을 유지한다. 커스텀 route 반환형도 Color에서 ShiftColorSelection으로 바꿨다.
- 최신 검증 산출물 `artifacts/custom_color_intensity_2026-11-11/render_test.dart`: Flutter test/SharedPreferences 모의 저장소/번들 폰트에 의존하며 프리셋과 농도 50% 커스텀의 10개 PNG/measurements.json을 생성한다. 루트에서 `flutter test --no-pub artifacts/custom_color_intensity_2026-11-11/render_test.dart`로 재생성한다. [프리셋](../artifacts/custom_color_intensity_2026-11-11/preset.png), [RGB와 농도](../artifacts/custom_color_intensity_2026-11-11/intensity_bottom.png). 이전 디자인 폴더는 해당 작업 시점 기록이다.

- 후속 제스처 수정(ADR-0039): `ShiftCustomColorPickerPage` 내부 `_ColorWheelPanGestureRecognizer`가 휠 원 내부 누름을 즉시 수락한다. 첫 손가락으로 원 밖까지 이동해도 드래그가 유지되며, 원 밖 모서리/주변 여백에서 시작하면 기존 ListView가 스크롤한다. 종료/취소 시 기본 PanGestureRecognizer의 추적 정리를 사용하므로 전역 스크롤 잠금 state는 없다. 색상 값 계산은 기존 함수를 사용한다. 기존 페이지 테스트에 실제 포인터 드래그/취소/다중 터치 회귀 4개를 추가했다.
- 사용자 재디자인 요청으로 `ShiftCustomColorPickerPage`만 후속 정리했다. 56px 모서리 둥근 미리보기와 HEX 입력을 상단 카드로 묶고, 색상 휠 아래 RGB를 `채널 문자 / 가로폭을 채운 슬라이더 / 숫자` 한 행씩 배치한다. RGB의 접근성 이름은 빨강/초록/파랑이며 값 계산·6자리 코드 검증·완료/취소 계약은 그대로다.
- 최근 색상은 44px 버튼을 줄바꿈하며 선택 체크·접근성 선택 상태·눌림 반응을 제공한다. 작은 화면은 세로 스크롤, 큰 글자는 미리보기/코드 입력을 세로로 분리하며 가로·태블릿의 본문 최대 너비는 480이다. 동작 줄이기 설정에서 휠 마커 애니메이션을 생략한다. UI state·SharedPreferences 저장 키/최대 6개/중복 제거 정책은 유지한다.
- 검증 산출물: `artifacts/custom_color_redesign_2026-11-11/render_test.dart`는 Flutter test·SharedPreferences 모의 저장소·번들 폰트를 사용하는 전용 렌더러다. 저장소 루트에서 `flutter test --no-pub artifacts/custom_color_redesign_2026-11-11/render_test.dart`로 재생성한다. 같은 폴더의 PNG 8개와 `measurements.json`은 일반/작은 화면/큰 글자/키보드 inset/가로/태블릿 캡처와 예외 기록이다. [최신 화면](../artifacts/custom_color_redesign_2026-11-11/normal.png). 이전 전체 화면 비교 이미지는 재디자인 전 기록으로 보존한다.
- 영향/롤백: 커스텀 화면·기존 회귀 테스트·전용 렌더러·문서만 변경했다. 이번 후속 변경만 되돌리면 직전 공통 UI로 복구된다. API/DB/라우팅/저장 형식 변경 없음. 실제 OS 키보드·VoiceOver는 미확인이고 앱의 기존 라이트 테마 범위에서 검증했다.

## 공통 폼·고정 하단 탭 구현 (2026-11-10 착수, 11-11 완료)

- 목적/상태: 사용자가 수정 방향을 승인해 앱에 반영했다. 정책은 ADR-0038, 화면별 범위는 [수정 방향서](UI_DESIGN_DIRECTION_2026-11-10.md), 결과 이미지는 [화면 비교](../artifacts/design_update_2026-11-10/comparison.png)를 참조한다.
- 진입/상태: AuthWrapper가 로그인·가입 프로필·MainTabPage를 분기한다. 소셜 로그인/가입 페이지의 직접 pushReplacement는 제거했다. 인증 사용자 id가 바뀌면 탭 컨테이너를 새로 생성하고 로그아웃 시 root 탐색 이력을 정리한다. 각 탭 Navigator와 지연 IndexedStack은 선택 날짜·친구/그룹·목록·상세 이력을 유지한다. 탭/observer는 dispose하며 domain provider는 기존 계정별 무효화 정책을 유지한다.
- 내비게이션: 하단은 캘린더·친구·알림, 오늘은 달력 헤더, 친구/그룹은 상단 세그먼트다. 설정·생성/편집/초대는 root로 열며 푸시는 폼을 덮지 않고 root가 현재 화면으로 복귀한 뒤 알림 탭을 연다. 알림 재진입은 목록/읽음 상태를 갱신한다. 별도 analytics 시스템은 추가하지 않는다.
- 폼: 설정·근무 타입·색상의 전체 0.8 배율 제거, 본문 16/보조 14·카드 16·입력 12·터치 최소 44 목표. 미지원 설정은 ADR-0073에 따라 표시하지 않는다. 개인 일정 날짜/시간은 별도 줄, 커스텀 색상은 세로 스크롤·한글 라벨·6자리 코드 검증을 사용한다. 근무 타입/개인 일정 저장은 콜백 완료까지 중복 입력/이탈을 막고 실패 시 입력을 보존한다. 알림 수락/거절은 최소 높이 44, 처리 중 표시와 중복 액션 방지를 제공한다.
- 반응형: 가용 높이 580 미만 또는 16pt 기준 확대 크기 20 초과인 메인은 본문 스크롤을 허용한다. 달력의 750px 기준 월/2주 정책은 유지한다. 고정 달력 셀 날짜는 한 줄 FittedBox, 큰 글자의 일정 헤더는 줄바꿈한다. 프로필/근무 타입/색상 등 저장 내용과 API 형식은 유지한다.
- 시간대: 그룹 수정은 도시/현재 UTC 시차 검색 선택을 사용한다. 기존 timezone 패키지의 위치 목록을 사용하고 목록에 없는 기존 값도 보존한다. 서버는 Intl.DateTimeFormat 검증을 수행하며 미지원 후보는 기존 API 오류로 안내한다. UTC 시차는 현재 날짜의 서머타임을 반영한다.
- 신규 파일 역할/의존성/사용 예:
  - `lib/core/navigation/main_tab_page.dart`: 인증 후 세 탭·badge·탭 이력과 pending 처리. Cupertino/Riverpod/기존 화면 provider에 의존. AuthWrapper가 `MainTabPage(key: ValueKey(user.id))`로 생성한다.
  - `lib/core/navigation/app_navigation.dart`: root route 변경 observer와 탭 선택 InheritedWidget. 앱 root Navigator에 `rootNavigationObserver`를 등록하고 `AppTabNavigation.maybeOf(context)?.openFriends()`로 친구 목록 경로에 이동한다(ADR-0067).
  - `lib/features/group/presentation/widgets/group_timezone_picker.dart`: 기존 timezone DB 기반 검색 페이지와 도시/시차 라벨. `GroupTimezonePicker(selected_timezone: current)`가 선택한 기존 식별자를 반환한다.
  - `test/core/navigation/main_tab_page_test.dart`: 모의 인증/달력/친구/알림으로 탭 상태·오늘·상세 복귀·푸시 보류·로그인/가입/로그아웃을 검증한다.
  - `test/features/calendar/presentation/widgets/form_save_state_test.dart`: Completer 기반 저장 중복 방지/실패 후 입력 보존 검증.
  - `test/features/group/presentation/widgets/group_timezone_picker_test.dart`: 도시 표시·미등록 현재 값 보존·검색과 식별자 반환 검증.
  - `artifacts/design_update_2026-11-10/render_update_test.dart`: 실제 위젯/번들 폰트/모의 provider의 28개 캡처 생성. `flutter test --no-pub artifacts/design_update_2026-11-10/render_update_test.dart`로 실행한다. `measurements.json`은 각 파일명·화면 크기·글자 배율·키보드 높이·예외·스크롤 측정 결과이며 같은 이름의 PNG가 대응한다. 실제 네트워크/계정은 사용하지 않는다.
  - `artifacts/design_update_2026-11-10/compose_comparison.swift`: macOS AppKit으로 주요 캡처 9개를 원본 그대로 합성한다. 저장소 루트에서 `swift artifacts/design_update_2026-11-10/compose_comparison.swift`로 `comparison.png`를 재생성한다.
- 검증/영향/롤백: 결과 수치는 WORKLOG 완료 항목을 따른다. 위젯 렌더/모의 회귀이며 실기기·실제 푸시·실서버 시간대 저장·VoiceOver 확인을 대체하지 않는다. 변경된 UI/내비게이션/테스트와 이번 문서·산출물만 되돌리면 복구되며 스키마/데이터 롤백은 필요 없다. 이전 검토·스킬 설치 작업은 보존한다.

## 화면·하단 내비게이션 수정 방향 (2026-11-10)

- 목적/상태: 사용자가 앞선 검토 결과에 공감하고 하단 바까지 포함한 수정 방향을 요청했다. [수정 방향서](UI_DESIGN_DIRECTION_2026-11-10.md)의 방향을 사용자 후속 요청으로 구현했다. 최신 동작은 상단 구현 절과 ADR-0038을 따른다.
- 제안: 캘린더·친구·알림 고정 탭, 오늘 액션의 달력 헤더 이동, 친구/그룹 상단 세그먼트, 화면 전체 0.8 배율 대신 역할별 크기, 설정·폼·색상·그룹 수정·알림의 통일. 인증/푸시 진입과 탭 상태 보존도 적용 범위에 포함한다.
- 파일 역할/의존성/사용 예: 방향서는 기존 검토 보고서·AppTheme·현재 진입 코드에 근거한 화면별 변경안과 후속 검증 조건이다. 구현 시 해당 화면 절과 완료 조건을 체크리스트로 사용한다.
- 검증/영향/롤백: 코드 진입점·기존 정책 대조 및 문서 검사. 방향 수립 당시에는 문서만 변경했으며 후속 구현·검증 결과는 상단 구현 절을 따른다. 롤백은 방향서와 이번 컨텍스트/로그 항목만 제거한다.

## 전체 화면 디자인 검토 (2026-11-10)

- 사용자 요청으로 앱 내부 일관성과 일반적인 모바일 UI 관례를 동일 비중으로 검토했다. 19개 페이지 정의와 관련 폼/공용 UI 코드를 확인하고, 실제 Flutter 위젯의 15개 렌더링 사례를 비교했다.
- 결과: [디자인 검토 보고서](UI_DESIGN_AUDIT_2026-11-10.md)에 작은 화면의 커스텀 색상 하단 접근 불가, 미구현 설정의 활성 토글 표현, 화면별 타이포 밀도, 하단 메뉴 역할, 터치 크기, 그룹 정보 수정 폼, 안내문 대비·언어 차이를 근거와 우선순위로 정리했다. 기존 0.8 배율·스크롤 차단이 문서에 기록된 의도라는 점과 그룹 플래그별 진입 조건도 구분했다. 이는 수정 전 검토 기록이며 후속 사용자 승인·구현은 ADR-0038과 상단 구현 절을 따른다.
- 파일 역할/의존성/사용 예: `_docs/UI_DESIGN_AUDIT_2026-11-10.md`는 검토 범위·발견·근거·후속 제안이다. `artifacts/design_audit_2026-11-10/render_audit_test.dart`는 기존 Flutter test/모의 의존성과 번들 폰트·아이콘으로 화면을 캡처한다. 루트에서 `flutter test --no-pub --reporter expanded artifacts/design_audit_2026-11-10/render_audit_test.dart`로 실행한다. 같은 폴더의 15개 화면 PNG·`measurements.json`은 시각/치수 근거, `comparison.png`는 주요 6개 화면 비교용이며 개별 파일 목록은 보고서를 참조한다.
- 검증/영향/롤백: 렌더러 1 test 완료·수집된 Flutter 예외 0, 분석 진단 0건 및 PNG 시각 확인. 320×568 커스텀 색상 초과 높이 147.4·드래그 전후 위치 0, 알림 버튼 높이 34·하단 버튼 높이 36을 측정했다. 앱 코드·DB·정책 변경은 없으며 새 ADR은 추가하지 않는다. 롤백은 이번 보고서·산출물 폴더·컨텍스트/로그 항목만 제거한다.

## UI UX Pro Max 개발 스킬 (2026-11-10)

- 목적/설치: 사용자 요청으로 `nextlevelbuilder/ui-ux-pro-max-skill`의 커밋 `6ae86f61f520d6ca229d2f40e070410638c908c5`에서 `.claude/skills/ui-ux-pro-max`를 공식 `skill-installer` 도우미로 사용자 공용 경로 `/Users/parkhyunseo/.agents/skills/ui-ux-pro-max`에 설치했다. 다른 프로젝트에서도 사용하는 로컬 개발 도구이며 앱 빌드 의존성은 없다.
- 파일 역할/의존성: `SKILL.md`는 적용 조건·검색 흐름, `scripts/search.py`는 CLI 진입점, 나머지 Python 모듈은 검색·디자인 제안 생성, `data/`는 CSV/JSON 검색 자료, `references/`는 UX 점검 기준이다. Python 3 표준 라이브러리로 실행하며 설치 당시 Python 3.13.0을 확인했다. 원본 검색 코드·데이터는 유지하고 manifest의 Claude 전용 실행 경로 11곳만 실제 설치 경로와 `python3` 명령으로 맞췄다.
- 사용 예: 다음 메시지에서 `$ui-ux-pro-max ShiftMate의 Flutter 캘린더 화면 UX를 검토해줘. 기존 Cupertino 구조와 AppTheme 토큰을 유지하고 개선안을 먼저 제시해줘.`처럼 호출한다. 새 스킬이 보이지 않을 때는 Codex를 재시작한다.
- 직접 실행 예: `python3 /Users/parkhyunseo/.agents/skills/ui-ux-pro-max/scripts/search.py "safe area accessibility" --stack flutter -n 2`. 새 시안 제안은 같은 스크립트에 `"calendar scheduling productivity" --design-system -p ShiftMate --json`을 전달한다. `--design-system` 모드는 `--stack`을 무시하므로 Flutter 검색은 별도 명령으로 수행한다.
- 적용 기준: 기존 Shift Harmony/Cupertino·`AppTheme` 규칙을 기준으로 검토한다. 생성 결과는 참고용이며 앱 코드 자동 변경이 아니다. 설치 검증의 디자인 제안에는 웹 랜딩페이지 패턴이 포함됐고 Flutter CSV의 결과는 3.44.x 대상이므로, 실제 프로젝트 버전과 화면에 맞는지 코드를 확인한 뒤 적용한다. 이번 검증에서는 `--persist`를 사용하지 않아 별도 디자인 문서를 생성하지 않았다.
- 검증/영향/롤백: Flutter 접근성 검색 2건과 디자인 제안의 `Calendar & Scheduling App` 분류·JSON 생성 성공을 확인했다. 변경 범위는 로컬 스킬과 이 문서·WORKLOG이며 앱 코드·UI·DB 변경은 없다. 롤백은 설치 디렉터리와 이번 문서 항목만 제거한다. 앱 설계·정책 변경이 없어 ADR은 추가하지 않는다.
- 근거: [원본 저장소](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill), [OpenAI 공식 스킬 문서](https://learn.chatgpt.com/docs/build-skills).

## 프로필 편집 작업 검토·커밋·푸시 (2026-11-10)

- 프로필 편집·사진 변경·관련 테스트·서버 요청서의 기존 변경 16개 파일을 검토해 `44595b6`으로 보존하고, 이전 로컬 커밋 `9516c5a`와 함께 origin/main에 일반 push했다. push 후 로컬 HEAD와 origin/main 일치를 확인했다. 추가 앱 코드 수정은 없다.
- 전체 Flutter 테스트 227 pass·기존 skip 1, 변경 Dart 12개 분석 진단 0건·포맷 변경 0건 및 diff 검사를 통과했다. 목적·영향·롤백·검증 세부 결과는 WORKLOG의 같은 날짜 완료 항목을 참조한다. 서버 반영·실기기 사진 교체 및 별도 iPhone 진단 TODO는 후속 작업으로 유지한다.

## 설정 프로필 수정 (2026-11-10)

- 진입: 인증된 사용자가 설정의 프로필 카드 → `ProfileSetupPage.edit(user: user)`를 `CupertinoPageRoute`로 push한다. 저장 성공은 현재 route를 pop해 기존 설정으로 복귀한다. 별도 analytics 시스템은 추가하지 않는다.
- 가입 화면과 이름·전화·직종·소속 입력/검증·사진 선택·미리보기·저장 로직을 공유한다. 후속 ADR-0043은 편집 표시를 분리해 현재 값으로 초기화하고 이메일을 읽기 전용 계정 영역으로 배치한다. 최신 규격/편집 UX는 상단 재설계 구현 절을 따른다.
- 흐름: `ProfileSetupPage.edit` → `AuthNotifier.updateProfile` → `AuthRepositoryImpl` → `AuthRemoteDataSource` → `POST /api/v1/auth/profile`. 가입 완료 endpoint를 호출하지 않는다.
- 편집 UI state(입력 controller·사진 bytes·로딩)는 화면이 소유하고 dispose한다. 최신 사용자 domain state는 기존 `authProvider`가 관리한다. 저장 성공 시 서버 완료 boolean을 보존하고 사진 업로드 성공 시 `profileImageBytesProvider`를 무효화한다.
- Behavior change: 설정 프로필 카드의 준비 중 안내를 실제 편집으로 대체한다. 변경 필드만 보내며 변경이 없으면 저장을 비활성화해 API를 호출하지 않는다. 선택 직종/소속을 비우면 빈 문자열을 보내 서버에서 null로 지운다. 레거시 직종 코드는 한글로 표시하지만 미수정 값은 다시 보내지 않는다. 편집은 저장된 타임존을 바꾸지 않으며 기존 전화는 미수정 시 재검증/전송하지 않는다.
- 사진은 기존 1024px·품질 85·최종 5MB 제한을 공유한다. 사진이 없으면 JSON, 있으면 multipart `profile_image` 파일을 전송한다. 편집은 저장/사진 선택 중 입력·뒤로가기·중복 작업을 막는다. 저장 실패는 입력·미리보기를 유지하고 하단 서버 오류/다시 저장을 표시하며 사진 선택 실패·제한 초과는 기존 다이얼로그를 사용한다.
- 기존 Dio 토큰 갱신 후 재시도에서 finalized multipart를 clone해 사진/필드를 다시 보낼 수 있게 한다. 다른 설정 메뉴는 변경하지 않는다.
- **서버 선행 조건**: 로컬 서버 코드는 일반 수정에 multipart parser가 없고 직종 enum 제한이 남아 있다. 사진 수정·자유 직종은 서버 반영 및 Stage/운영 인수 전 사용 가능으로 간주하지 않는다. 확인한 것은 로컬 소스이며 원격 배포 상태는 미확인이다. 상세 요청은 [PROFILE_EDIT_SERVER_HANDOFF.md](PROFILE_EDIT_SERVER_HANDOFF.md).
- 파일 역할/의존성/사용 예:
  - `lib/features/auth/presentation/pages/profile_setup_page.dart`: 가입/편집을 명시적인 생성자로 구분한 공용 입력 화면. Riverpod·기존 User·image_picker에 의존. 가입은 `ProfileSetupPage(user: user)`, 편집은 `ProfileSetupPage.edit(user: user)`.
  - `lib/features/auth/presentation/pages/settings_page.dart`: 기존 사용자 프로필 카드에서 편집 route push. 성공 후 authProvider 갱신으로 카드도 다시 표시한다.
  - auth datasource/repository/provider: 선택 `ProfileImageUpload`를 일반 수정까지 전달하고 공용 multipart 변환을 가입/편집에서 재사용한다. 예: `updateProfile(profile_image: image, workplace: '')`.
  - `lib/core/network/api_client.dart`: 기존 인증·갱신 경로에서 multipart 재전송을 지원한다.
  - 기존 auth 페이지/provider/datasource 테스트: 초기값·부분 저장·삭제·취소·실패 재시도·사진 bytes/캐시·401 재전송과 가입 회귀를 모의 검증한다. login 테스트 fake는 선택 이미지 인자 계약만 맞춘다.
  - `_docs/PROFILE_EDIT_SERVER_HANDOFF.md`: 서버 수정 위치·계약·DB/env·OpenAPI·정리/실패/롤백·인수 체크리스트. 서버 코드를 읽은 근거와 구현 요청을 구분한다. 사용 예: 서버 작업 이슈 첨부.
- 롤백: 이번 편집 생성자/설정 연결/일반 수정 이미지 전달·재전송 변경을 되돌린다. 서버 배포 후 자유 직종 데이터가 있으면 enum 제약을 강제 복구하지 않는다.
- 검증: 전체 Flutter 테스트 227 pass·기존 skip 1, 변경 Dart 12개 분석 진단 0건·포맷 변경 0건. 실제 서버/S3·실기기 사진 변경은 서버 인수 후 확인한다.

## 미커밋 변경 정리·재검증 (2026-11-09)

- Debug 전용 호환 번호 테스트 옵션·실행 구성, 로그인/설정의 개인정보처리방침 공용 링크, 빌드 1.0.0+4 및 출시 진행 문서의 기존 변경 14개 파일을 검토해 로컬 커밋으로 보존한다. 상세 파일 역할·의존성·사용 예·Behavior change는 아래 관련 절과 ADR-0036을 따른다. 추가 앱 코드 변경은 없다.
- 전체 Flutter 테스트 214 pass·1 skip, Debug 번호 0 적용/-1 기본값 복구 각각 2 pass, 변경 Dart 7개 분석 진단 0건·포맷 변경 0건 및 실행 JSON·diff 검사를 통과했다. 이번 작업에서 스토어·서버 상태를 재검증하거나 변경하지 않았다. 롤백은 해당 정리 커밋의 일반 git revert이며 검증 세부 결과는 WORKLOG를 참조한다.

## 앱 개인정보 선언 게시 (2026-11-08)

- Chrome에서 15개 데이터 유형의 목적·연결·추적 응답을 실제 저장하고, Apple 최종 게시 동의에 사용자 확인을 받은 뒤 23:09(Asia/Seoul) 게시했다. ‘몇 초 전에 게시함’ 문구와 새로고침 후 게시 기록·15개 응답 유지를 직접 확인했다. 아래 과거 유형 화면까지 진행/미게시 상태는 이 기록으로 대체한다. 최종 App Review는 미제출이다.
- 이름·이메일·전화·대략적인 위치·연락처(친구/그룹 관계)·사진/비디오·고객 지원·기타 사용자 콘텐츠·사용자 ID·기기 ID·제품 상호 작용·기타 사용 데이터·실적 데이터·기타 진단 데이터·기타 데이터 유형을 선언했다. 모두 사용자 연결 있음·추적 없음. 고객 지원은 문의 보관에 대한 사용자 확인을 반영했다.
- 실제 빌드의 GoogleSignIn/Firebase/Kakao 수집 선언과 서버 저장/운영 로그를 대조했다. 사용자 ID·기기 ID·기타 진단·기타 데이터는 앱 기능과 분석, 기타 사용 데이터는 분석, 나머지는 앱 기능 목적이다. 목적별 근거는 APP_STORE_RELEASE_CHECKLIST 상단 표를 참조한다. 개인정보 선언만 변경했으며 실제 수집 동작·API·동의 계약은 변경하지 않았다. 수정/롤백은 포털 답변 편집·재게시로 수행한다.

## 개인정보처리방침 링크·빌드 4 (2026-11-08)

- 사용자 제공 패치를 검토하고 앱/테스트/버전 변경 부분을 실제 적용했다. 공용 URL 열기/오류 안내로 정리하여 로그인 화면 `개인정보처리방침 보기`와 설정 → 지원 → `개인정보처리방침`에서 동일한 `https://www.shiftmate.co.kr/privacy`를 외부 브라우저로 연다. 일반 약관 안내 문구·OAuth/가입 동의 계약·수집 항목·API 호환 번호는 변경하지 않는다.
- 신규 `lib/core/utils/privacy_policy.dart`: Cupertino·기존 url_launcher에 의존하는 공개 정책 URL·`PrivacyPolicyLauncher` 경계·`openPrivacyPolicy(context, launcher: ...)`를 제공한다. 로그인/설정 생성자의 `launch_privacy_policy` 콜백으로 외부 브라우저 열기를 대체하여 검증한다. 실패/플랫폼 예외는 URL이 포함된 재시도 안내로 처리하고 화면 해제 후에는 다이얼로그를 표시하지 않는다. 앱 전역 상태나 새 Provider/Route를 추가하지 않는다.
- Behavior change: 로그인 전후 정책 페이지에 실제 접근 가능한 진입점 추가. `pubspec.yaml`은 1.0.0+4이며 Release 호환 번호는 1이다. 빌드 3의 IPA·Archive는 `build/ios/releases/1.0.0-3/`의 `ipa/`·`Runner.xcarchive`로 보존했다. 신규/기존 로그인·설정·프로필·인증 상태·업데이트 테스트 44개, 변경 Dart 분석 진단 0건을 확인했다. 빌드 4 생성·배포 서명/운영 설정·무결성 검증, Transporter 전송과 Connect 처리/기존 동일 수출 규정 답변을 완료했고 제출용 빌드를 4로 교체·저장했다. 새로고침 후 빌드 4 유지도 직접 확인했다. WORKLOG/출시 체크리스트에 산출물 해시·검증·시간을 기록했다. 개인정보 설문 게시·실기기 링크 확인·최종 심사 제출은 남아 있다.
- 사용자 보고: 빌드 3 전송/처리 완료, 연령 등급 글로벌 16+/대한민국 15+ 저장 및 콘텐츠 권리 1번 저장 완료. 앱 개인정보는 수집함 선택/유형 화면까지 진행했고 세부 답변·게시는 미완료다. 아래 과거 출시 상태보다 이 보고를 우선하며 직접 포털 조작/검증으로 확대하지 않는다.
- 롤백: 이번 링크·공용 helper·검증·빌드 번호 변경만 되돌리거나 보존한 빌드 3을 선택한다. 기존 Debug 버전 테스트 변경과 서버 정책은 유지한다.

## 잔여 작업 전체 보존 (2026-11-08)

- 후속 사용자 요청으로 업데이트 기능 커밋에서 제외했던 프로필 이미지 인증·계정 전환 캐시 무효화, 로컬 API 디버그, iPhone 전용 설정, 출시/개인정보 문서 및 스크린샷도 이번 커밋 범위에 포함한다. 빌드 2에 포함된 기존 프로필 이미지 수정 등의 소스를 함께 보존한다.
- 영향: 보호된 프로필 이미지 요청과 개발 실행 옵션, iPhone 지원 범위 및 출시 전달 자료. 각 기능의 동작·검증·파일 역할은 아래 관련 절과 ADR-0030~0034, 출시 체크리스트를 참조한다. 환경 파일·서명 비밀값·Archive/IPA는 Git에 추가하지 않는다.
- 롤백: 이번 잔여 변경 커밋을 일반 `git revert`로 되돌린다. 서버 배포·앱 업로드·심사 제출 상태는 그대로다.
- 보존 결과: 잔여 변경 35개 파일을 `a123a07`로 origin/main에 push했으며 원격 HEAD 일치를 확인했다. 상세 범위·검증 결과는 WORKLOG의 같은 날짜 완료 항목에 기록했다.

## 서버 API 호환 버전·필수 업데이트

- 로컬 실기기 QA: `DEBUG_API_COMPATIBILITY_VERSION=0`은 Debug에서만 적용하며 Profile/Release 번호는 1을 유지한다. `ShiftMate (debug local update test v0)` 구성으로 로컬 최소값 1보다 한 단계 낮은 앱을 실행한다. 서버값 0은 비활성이다. 설정·복구·파일 역할은 APP_VERSION_POLICY의 로컬 실기기 구버전 테스트 절을 참조한다. 2026-11-08 사용자 서버 배포 완료 보고 및 Stage/운영 정책 GET 200·최소값 0을 확인했으며, 후속 사용자 정정에 따라 이번 실기기 테스트 대상은 로컬 서버다. 아래 미배포 설명은 이전 작업 시점 이력이다.
- 실기기 결과: 로컬 공개 정책 최소값 1·HTTP 200을 직접 확인하고 사용자가 iPhone의 ‘업데이트가 필요해요’ 화면을 확인했다. 차단 검증 완료이며 Store 이동·복귀와 기본 번호 1 복구는 후속이다. 테스트 코드·문서는 WORKLOG에 기록했다.

- [APP_VERSION_SERVER_HANDOFF.md](APP_VERSION_SERVER_HANDOFF.md)는 서버 담당자 전달용 코드 반영·초기 env·실제 HTTP 수용 기준·배포 순서·롤백·결과 회신 가이드다. 서버 기능 커밋 90ece07 및 앱 정책 계약에 의존한다. 사용 예: 서버 담당자에게 가이드와 전달 패치를 넘기고 배포 결과를 회신받는다. 메시지 전송·운영 배포는 수행하지 않았다.

- 재빌드 완료: Archive·IPA 1.0.0(2), 앱 내부 호환 번호 1. 현재 작업 트리 전체 테스트 206 pass·1 skip 및 변경 파일 분석 진단 0건, 서버 선택 테스트 23건·TypeScript 통과. IPA의 새 게이트/API 경로·스토어 플러그인·운영 API·배포 서명/권한·무결성을 검증했다. 빌드 2에는 작업 당시 미커밋 프로필 이미지 수정 등도 포함되며 업데이트 기능 선별 커밋과 소스 범위가 달랐다. 후속 요청에 따라 이 잔여 소스도 별도 커밋 범위에 포함한다. 이전 빌드 1은 `build/ios/releases/1.0.0-1/`로 보존했다. 서버 커밋 `90ece07`은 origin 기능 브랜치로 push했고 전달 패치를 준비했다. 서버 배포·앱 업로드·심사 제출은 미수행이다.

- 사용자 확정(2026-11-08): App Store 버전/빌드 번호와 별도인 앱 내부 `AppConstants.api_compatibility_version=1`을 서버 최소값과 비교하고, 최소값 미만이면 업데이트 전까지 이용을 차단한다. Apple ID `6831957246`은 스토어 이동용이다. 현재 사용자 표시 버전은 1.0.0, 새 빌드 번호는 2다.
- `CupertinoApp.builder → AppUpdateGate → AppUpdateController → AppUpdateRepository(Dio/SharedPreferences) → GET /app/version-policy` 흐름이다. 시작/복귀에 5초 내 확인하고 이미 확인된 차단은 장애에도 유지한다. 캐시 없는 최초 실패는 허용한다. 앱 전역 domain state는 ProviderScope 수명, 스토어 버튼 상태는 UI state다.
- 신규 feature/테스트의 파일 역할·의존성·사용 예, FE/BE 계약·선택 env·운영 적용 순서·rollback은 [APP_VERSION_POLICY.md](APP_VERSION_POLICY.md), 결정은 ADR-0035를 참조한다. 서버 구현은 develop 기반 `codex/app-compatibility-policy` 작업이며 실제 배포는 미수행이다. 서버 최소값을 올리기 전에 해당 내부 호환 번호를 지원하는 앱을 스토어에 먼저 공개해야 한다.

## App Store 출시 준비 문서

- 2026-11-08 스크린샷 폰트 검증: Figma 실제 홍보 텍스트는 Noto Sans KR Black/Medium/Regular 32개. 공식 SIL OFL 1.1·FAQ 및 앱 화면의 Cafe24 Ssurround/Air 로컬 라이선스 네 페이지 확인 결과, 제작 PNG의 상업 홍보 사용이 허용된다. 이미지 안의 폰트 출처 표기·별도 구매는 필요하지 않다. 폰트 파일 자체 재배포 시 라이선스 동봉은 별도 조건이며, 앱 바이너리 동봉 상태·전체 콘텐츠 권리 검증은 이번 범위 밖이다. 근거·조건·검증은 출시 체크리스트의 폰트 라이선스 확인 절을 참조한다.

- 2026-11-08 빌드 완료: 후속 첨부 화면에서 심사 로그인 정보 및 보조 계정 메모 입력 확인(비밀번호 미기록). Xcode 27.1(27A9275)·iOS SDK 27.1·Flutter 3.38.5/Dart 3.10.4로 `build/ios/archive/Runner.xcarchive` 및 `build/ios/ipa/ShiftMate.ipa` 1.0.0(1) 생성. Release 운영 API·Production OAuth/Firebase·iPhone 전용·배포 서명/권한·IPA 무결성 검증 완료, 기존 테스트 196 pass·1 skip. 전체 정적 분석은 기존 info 33건(error/warning 0). 기본 LaunchImage 안내 1건 유지. 산출물 역할·의존성·명령·SHA-256·롤백은 출시 체크리스트의 제출용 빌드 결과를 참조한다. Connect 업로드·Apple 서버 검증·실기기 실행·심사 제출은 미수행이며, 과거 Xcode 16.2 및 빌드 미생성 상태는 당시 이력이다.

- 2026-11-08 심사 계정 후속 보고: `shiftmate.review1@gmail.com`, `shiftmate.review2@gmail.com` 두 Google 계정 생성 및 ShiftMate 회원가입 완료(사용자 보고). 친구·그룹 연결, 예시 근무표, 제출 빌드 접속 서버에서의 로그인 및 Connect 계정 정보 저장은 미확인이다. 비밀번호는 저장소에 기록하지 않는다. 아래의 Google 심사 계정 준비 대기 설명 중 생성·가입 단계만 이번 보고로 대체한다.

- 2026-11-08 최신 사용자 보고: Connect에 저작권 `2026 박현서`, 심사 연락처, 설명·홍보 문구·키워드·지원/개인정보 URL·심사 메모를 저장했고 무료·대한민국 한정 및 iPhone 스크린샷 4장 등록을 확인했다. Codex 직접 포털 검증은 아니다. Google 심사 계정·제출용 빌드·개인정보 설문·연령 등급·콘텐츠 권리 확인이 남아 있다. 현재 승인 후 자동 출시이며 최종 제출 전 재확인한다. 심사는 미제출이다. 아래 과거 기록의 포털 미입력 상태는 이번 명시 항목에 한해 대체하며, 공개 개인정보 페이지 최종 검증 완료로 확대하지 않는다. 심사용 연락처 입력은 공개 지원 이메일 변경을 뜻하지 않는다.

- 2026-11-08: 실제 앱 첨부 화면으로 [Figma 출시 스크린샷](https://www.figma.com/design/bkMSAJCfP2X28FuyNJu1Ej?node-id=2-2) 4종을 제작했다. `artifacts/app_store_screenshots/`의 두 규격 폴더(1290×2796, 1179×2556)는 제출용 RGB PNG 각 4장, `preview.png`는 구성 확인용, `ShiftMate_AppStore_Screenshots.zip`은 전달용 묶음이다. 원본 `../design/KakaoTalk_Photo_2026-11-08-19-29-18 001.png`~`004.png`와 Figma 편집본에 의존하며 앱 런타임 의존성은 없다. 사용 예: ZIP 해제 후 해당 규격의 01~04 이미지를 Connect에 등록한다. 문구·원본 매핑·검증·롤백은 아래 출시 체크리스트의 2026-11-08 제작 결과를 참조한다. 실제 Connect 등록·심사 제출은 미수행.

- [`APP_STORE_RELEASE_CHECKLIST.md`](APP_STORE_RELEASE_CHECKLIST.md): 첨부 체크리스트 전체와 심사 준비 진행 상태·근거·다음 작업을 관리한다.
- 의존성: 이 문서의 앱 식별자, iOS Xcode 설정, Apple Developer / App Store Connect 실제 상태.
- 사용 예: 계정·서명·심사 자료 검증을 완료할 때 체크 상태와 날짜별 증거를 갱신한다. 등록·결제는 사용자 확인 완료이며 포털 활성화·배포 서명은 별도 검증한다.

- 출시 문서 상단의 「2번 준비」는 구현 근거에 맞춘 한국어 등록 문구, 아이콘 검사 결과, iPhone 촬영 계획 및 후속 iPad 지원 과제와 공개 URL 미결 항목을 포함한다. 포털 등록 완료와 로컬 초안을 구분한다.

## App Store 공개 페이지 전달 파일

- [`app_store_web/FE_PRIVACY_CONTRACT_REPLY.md`](app_store_web/FE_PRIVACY_CONTRACT_REPLY.md): BE-05 화면·상태·DTO·오류·SDK 경계 FE 회신안. 기존 인증 코드와 BE 제안에 의존한다. 합의 후 계약 테스트/구현 기준으로 사용하며 현재 후보 필드를 전송하지 않는다.


- [`app_store_web/PRIVACY_ACTION_PLAN.md`](app_store_web/PRIVACY_ACTION_PLAN.md): 문서 수정 완료·FE/BE 프로그램 요청·운영 확인을 ID/담당/완료 기준으로 나눈 작업표. API·운영 결과 회신 후 상태를 갱신한다.
- [`app_store_web/BACKEND_PRIVACY_REQUEST.md`](app_store_web/BACKEND_PRIVACY_REQUEST.md): 서버 담당자 전달용 이미지 삭제·탈퇴 감시·기기/작업 정리·가입 계약 요청서. 코드 근거와 수용 기준·운영 회신 양식을 포함하며 직접 전송하지 않았다.


- `_docs/app_store_web/support.html`: 확정된 지원 이메일·문의 방법·탈퇴 요청 경로를 제공하는 독립 HTML. 외부 자산·빌드·API 의존성 없음. 사용 예: 서버 `/support` 응답.
- `_docs/app_store_web/PRIVACY_POLICY.md`: 운영자가 채택한 보관 정책·실제 코드 근거 기반 개인정보처리방침 편집 정본. 2026-10-18 시행 v1.0 공개 문안으로 정리했다.
- `_docs/app_store_web/privacy.html`: 위 MD와 동일 본문의 단일 HTML. 검토 배너·개발 메모를 제거했다. 실제 계약/국외 이전 고지 대조와 공개 재게시·제출은 별도다. 두 파일을 함께 갱신하고 최종 HTML을 서버 `/privacy` 응답으로 사용한다.
- [`app_store_web/PRIVACY_REVIEW.md`](app_store_web/PRIVACY_REVIEW.md): 코드 근거·실제 URL 응답·운영 확정 목록. 서버 담당자의 공개 전 검토에 사용하며 웹에 게시하지 않는다.
- [`app_store_web/DEPLOY_GUIDE.md`](app_store_web/DEPLOY_GUIDE.md): 서버 담당자용 Nginx·파일 배치·검증·롤백 및 정책 확정 체크리스트. 서버 환경에 맞춰 적용하며 실제 배포는 담당자가 수행한다.

### 개인정보 운영 정책 채택 (ADR-0032)

- 최신 사용자 확정: 최초 시행일 2026-10-18, 일반 로그/DB 백업 30일·문의 완료 후 1년 삭제 적용 완료, 이미지 별도 백업 없음. 개인정보 MD/HTML은 공개 문체 v1.0으로 갱신. 계정별 외부 처리/국외 이전 고지의 완결성은 실제 계약 대조 필요. 서버 재게시·심사 제출 미수행.


- BE-05 최신 상태: 구현·검증 완료(2026-10-18 사용자 명시 확인). 이전 미구현/합의 대기 설명은 당시 이력이다. Codex 직접 코드/테스트 검증은 아니며 제안 DTO를 실제 계약으로 확정하지 않는다. 다른 운영 검증 대기 항목에는 이 완료 상태를 확대 적용하지 않는다.


- 최신 사용자 전달: BE-01~04 main 코드 배포 완료. 기존 배포 미확인 기록을 대체한다. 실삭제·cleanup·호스트 timer/SMTP·로그/백업/메일 보관 설정은 별도 검증 대기.
- AWS 개인 계정·개인용 Gmail 확인 완료. S3 서울·복제/CDN 없음에 더해 버전 관리 off 확인. 프로필 사진 별도 백업은 미확인. 시행일은 조건부 제안으로 미확정.


- 최신 사용자 정정: ‘모두 완료’ 답변 철회. BE-01~04는 구현 및 DB migration/S3 조회 권한 준비 보고가 있으나 운영 배포·파기·감시·보관 설정은 미검증/미완료.
- 국내 홈서버 수동 Stage·운영 DB 백업 존재 보고. 최대 보관 기간·30일 순환 삭제·정기 백업·복원 시험 미확인. 이미지 별도 백업 유무도 미확인. 시행/개정일과 AWS/Gmail 계정 유형은 미확정. 상세 증거 상태는 PRIVACY_REVIEW의 최신 운영 상태 표를 우선 적용한다.


- 2026-10-18 사용자 정정: 프로필 이미지는 AWS S3 저장. API·DB 홈서버 운영과 분리한다. 이미지 서울 리전 ap-northeast-2·복제/CDN 없음 사용자 확인. 별도 백업 위치·계약 법인·실제 파기는 미확인. 기존 이미지까지 국내 홈서버 설명을 대체한다.


- BE-01~04 결과 전달서 수신 및 인접 서버 c1af0f7 핵심 소스 확인: 관리 이미지 파기·탈퇴 감시·기기 cleanup·retention 강제 구현. 실제 홈서버 적용은 대기다.
- BE 보고의 추가 승인 정책: 무연결 비활성 기기 30일 경과 후 정기 정리, 완료 탈퇴/종료 푸시 30일, 미완료 7일 초과 경보·30일 이내 운영자 최종 조치. 실제 일일 cleanup 주기와 예외는 운영 절차를 따른다.
- BE-05는 합의 전 제안. 신규 API·DB·가입 필드·연령 차단·SDK 호출 순서 변경은 아직 수행하지 않았다.


- 개인정보처리자·보호 담당자: 박현서. 연락처 `sspp8585@gmail.com`.
- 사용자 채택: 탈퇴 처리 목표 7일 이내, 일반 서버/Nginx 로그 최대 30일, 백업 최대 30일 순환 삭제, 문의 처리 완료 후 1년. 법정 의무 기록은 별도 적용. 운영 설정 구현 완료를 뜻하지 않는다.
- 만 14세 미만 가입·이용 미허용 정책. 가입 제한의 실제 구현·운영은 후속 확인 필요.
- 분석·충돌 수집 SDK는 도구 미정·현재 미도입. 도입 전에 정책·App Privacy를 갱신한다. 기존 FCM·Gmail의 외부 처리는 별도다.
- 공개 지원 URL: `https://www.shiftmate.co.kr/support`(2026-10-18 GET 200 확인). `/privacy`는 최초 확인에서 404였으나 후속 GET 200으로 검토본 공개 확인. 최종 정책 확정·재게시가 필요하다.

## 프로젝트 개요

**ShiftMate**는 교대 근무 일정 관리 및 공유를 위한 Flutter 모바일 애플리케이션입니다.

### 주요 기능

- 교대 근무 일정 관리 (데이/이브닝/나이트 등)
- 캘린더 기반 일정 조회 및 편집
- 친구 간 일정 공유
- 카카오·네이버·Google·Apple OAuth 로그인
- FCM 친구·그룹 푸시 알림과 인앱 알림 목록 연결

### 기술 스택

- **프레임워크**: Flutter (Cupertino 디자인)
- **상태관리**: Flutter Riverpod 2.6.1
- **네트워크**: Dio 5.7.0
- **인증**: 카카오 Flutter SDK, 네이버 iOS/Android 네이티브 SDK,
  `google_sign_in` 7.2.0, `sign_in_with_apple` 7.0.1
- **로컬 저장소**: Flutter Secure Storage, Shared Preferences
- **푸시**: Firebase Core/Messaging, Flutter Local Notifications
- **코드 생성**: Freezed, JSON Serializable

### 최초 App Store 출시 범위

- 2026-10-18 사용자 확정: 대한민국 한정, 무료, 앱 내 결제 없음(ADR-0031).
- 공개 고객 문의 이메일: `sspp8585@gmail.com`.
- 서비스는 앱으로 제공하며 지원·개인정보처리방침은 기존 `shiftmate.co.kr` 도메인에 정적 HTML로 제공할 방향이다. 실제 www 호스트의 `/support`·`/privacy`는 GET 200 확인했으며 정책의 공개 최종 내용은 별도 검증 대상이다. 2026-11-08 사용자 보고로 App Store Connect 무료·대한민국 한정 설정 및 지원/개인정보 URL 저장 완료를 확인했다.

### iOS 지원 기기

- 최초 출시는 iPhone 전용이다(2026-10-18 사용자 결정, ADR-0030).
- `ios/Runner.xcodeproj/project.pbxproj`의 Debug/Profile/Release `TARGETED_DEVICE_FAMILY = 1`을 사용한다.
- iPad 네이티브 지원·UI 검증·전용 스크린샷은 후속 업데이트 과제다. iPhone 앱의 iPad 호환 실행 차단을 뜻하지 않는다.

### 앱 브랜드 및 플랫폼 식별자

- 사용자 노출 브랜드명과 Android/iOS 표시 이름은 `ShiftMate`를 사용한다.
- Dart 패키지명은 `shift_mate`를 사용한다.
- Android `namespace`와 `applicationId`, Kotlin 패키지는 `com.hspark.shiftmate`를 사용한다.
- iOS Runner Bundle ID와 네이버 전용 URL Scheme은 `com.hspark.shiftmate`를 사용한다.
  Google iOS client와 Android OAuth client도 같은 Bundle ID/package name을 등록한다.
- `calendar`는 캘린더 기능·도메인을 나타내는 명칭에만 사용하고 앱 브랜드 식별자로 사용하지 않는다.

### UI 디자인 시스템

- 디자인 기준은 Shift Harmony 문서(`../design/DESIGN.md`,
  `../design/design prompt/DESIGN.md`,
  `../design/design prompt/flutter_fe_development_prompt_shift_harmony.md`)를 따른다.
- 앱 구조는 기존 Flutter Cupertino 기반을 유지하고, Material 3 전환은 하지 않는다.
- 공용 색/타이포/반경/보더 토큰은 `lib/core/theme/app_theme.dart`에 둔다.
- Cafe24 폰트는 사용자 요청으로 재활성화했다. 본문·버튼·탭·피커는
  `AppTheme.default_font_family` (`Cafe24SsurroundAir`), 공용 제목은
  `AppTheme.heading_font_family` (`Cafe24Ssurround`)를 사용한다.
- `assets/fonts/Cafe24SsurroundAir-v1.1.ttf`와 `Cafe24Ssurround-v2.0.ttf`는
  pubspec에 별도 family로 등록된 본문/제목 자산이다. 사용 예는 `body_large`/`heading_small`이다.
  `License-Ssurround.pdf`와 `License-SsurroundAir.pdf`는 라이선스 원본 보관용이며 runtime 의존성은 없다.
- ADR-0028 구성을 재적용하며 ADR-0029의 해제 상태는 종료했다.
  기존 fontWeight는 유지하므로 굵은 본문도 Air를 사용하고 필요하면 굵기를 합성한다.
- 핵심 토큰:
  - 배경: `#F8F9FB`
  - Primary: `#0061A4`
  - Surface: `#FFFFFF`
  - Surface container: `#F2F4F6`, `#ECEEF0`, `#E0E3E5`
  - Text: `#191C1E`, 보조 텍스트 `#414750`
  - Outline: `#C1C7D2`
- 카드/섹션은 흰색 surface + 16px radius + 얇은 outline을 기본으로 한다.
  무거운 shadow는 쓰지 않고, 선택/상태 강조는 색상 tint와 border로 표현한다.
- 입력/작은 컨트롤은 12px radius, badge/chip은 pill 성격의 16px radius를 사용한다.
- 근무 타입 색상, 공휴일 빨간색, 성공/오류/소셜 로그인 브랜드 색처럼 의미가 있는 색은
  공용 surface 규칙과 별도로 유지한다.
- 파일 역할/의존성/사용 예:
  - `lib/core/theme/app_theme.dart`: Shift Harmony 공용 토큰과 `CupertinoThemeData`,
    `cardDecoration()` helper를 제공한다. 페이지/위젯은 배경, 카드, outline, 텍스트 색을
    직접 하드코딩하지 않고 이 토큰을 우선 사용한다. `surface_container_highest_color`
    (`#E0E3E5`)는 비활성/최대치 도달 버튼 배경처럼 더 높은 surface 상태에 사용한다.
    `readableForegroundColor()`는 실제 배경과 선호 전경색의 WCAG 대비율을 계산해 4.5:1을
    만족하면 선호색을 유지하고, 부족하면 `on_surface_color`와 `surface_color` 중 대비가 높은
    색을 반환한다. 옅은 사용자 정의 근무 색상 위의 코드처럼 동적 배경의 텍스트에 사용한다.
  - `lib/core/utils/korean_holidays.dart`: 한국천문연구원 특일 정보 API의 요청 월 앞뒤 1개월
    공휴일을 조회하는 앱 공용 데이터 원천이다. 날짜·이름과 조회 완료 월을 메모리에 병합하고
    `SharedPreferences`의 `korean_holidays_cache_v1` JSON에 저장한다. `main.dart`는 앱 시작 시
    `initialize()`를 호출해 이전 실행의 캐시를 먼저 복원하며, 메인·친구 캘린더는 월 이동 시
    `getHolidaysForYear(year, month: month)`를 호출하고 동기 `isFixedHoliday()`로 렌더링한다.
    같은 연도/월의 동시 요청은 하나의 Future를 공유하고, 1월·12월 조회 결과는 실제 날짜 연도에
    나누어 저장한다. 사용 예는 날짜 셀의 `holidayPredicate`와 선택일 카드의 `getHolidayName()`이다.
  - `test/core/utils/korean_holidays_test.dart`: 가짜 API 조회 결과가 로컬 저장소에 기록되고 메모리
    초기화 후 다시 복원되는지, 연도 경계 날짜가 실제 연도 캐시에 보존되는지 검증한다.
  - `lib/features/calendar/presentation/pages/calendar_page.dart`: 메인 캘린더 화면.
    `TableCalendar`와 `/calendar/range` 응답을 결합해 저장된 근무표/개인 일정을 표시한다.
    월 헤더를 누르면 공용 `YearMonthPickerSheet`를 열고, 사용자가 선택한 연도/월로 이동한 뒤
    해당 기간의 캘린더와 공휴일 데이터를 로드한다.
    일반 달력은 별도 surface 카드 없이 페이지 배경에 바로 표시한다. 기본 상태에서 날짜 아래에
    근무 코드 배지를 노출한다. 화면 높이 750px 미만에서는 캘린더 형식을 2주 보기로 고정하고
    52px 행 높이를 사용하며, 750px 이상에서는 기존 월/2주/주 형식과 56px 행 높이를 유지한다.
    위로 드래그하면 기존 48px compact 점 표시로 접을 수 있으나 750px 미만의 2주 형식은 유지된다.
    날짜 셀은 행 높이를 다시 수동 계산하지 않고 `TableCalendar`가 전달한 실제 가용 높이를 채우며,
    2px 외부 여백을 제외한 영역에 날짜와 근무 배지를 배치해 작은 화면에서도 넘치지 않게 한다.
    선택일은 8% primary tint 배경과 2px primary dark outline 사각형, 굵은 날짜 텍스트로 표시하며
    별도 원은 그리지 않는다. 선택 여부가 날짜 의미 색상을 덮어쓰지 않으므로 토요일은 primary blue,
    일요일과 공휴일은 accent red를 선택 후에도 유지한다.
    선택 배경은 날짜 콘텐츠와 분리해 셀 전체 너비를 채우지 않는다. compact 점 보기에서는
    날짜와 점을 감싸는 48x48px, 근무 코드 보기에서는 58x58px 설정값을 사용하되 실제 크기는
    날짜 셀의 가용 너비·높이로 제한된다. 선택 배경의 하단 오프셋은 compact 8px, 근무 코드 보기
    4px이며, 날짜 콘텐츠는 선택 여부와 관계없이 2px 사방 padding을 사용해 숫자 위치를 고정한다.
    `CalendarStyle.tablePadding` 하단 8px이 마지막 행 선택 배경의 offset을 내부 `PageView` 경계에
    포함하고, 일정 카드 앞 외부 간격은 4px을 사용해 기존 달력 본문-to-카드 간격 12px을 유지한다.
    오늘은 선택 여부와 관계없이 날짜 의미 색상을 유지한 굵은 날짜 텍스트와 숫자 아래 12x2px
    primary 밑줄로 구분한다. 일요일과 공휴일은 accent red, 토요일은 primary blue를 사용한다.
    우측 상단 `+` 버튼으로 근무 추가 모드에 들어가면 선택일 헤더 아래에 근무 타입 원형
    버튼을 표시한다. 날짜 헤더 오른쪽에는 공용 헤더 콘텐츠와 같은 28px 높이의 compact `완료`
    버튼을 배치하고,
    별도 하단 완료 버튼과 근무 타입 수 배지는 표시하지 않는다. 원형 버튼은 한 행 최대 5개,
    최대 2행으로 배치해 타입 1~10개를 내부 스크롤 없이 노출한다. 버튼 안에는 코드와 이름을
    표시하며, 선택 시 해당 타입 색상의 tint와 굵은 outline을 사용한다.
    버튼을 누르면 `_schedules`에 선택 근무를 임시 저장한 뒤 다음 날로 자동 이동한다.
    날짜 헤더/완료 버튼, 버튼 그리드, 안내 문구는 하나의
    `surface_container_low_color` 카드 영역 안에 둔다. 선택일 일정 카드와 근무 설정 카드는
    같은 `Expanded` 하단 슬롯을 사용해 `+` 버튼 전후 외부 크기를 유지한다. 근무 추가 모드 진입은
    현재 `CalendarFormat`과 확장/compact 상태를 변경하지 않으며, 행 높이도 기존 확장 52/56px 또는
    compact 48px을 유지한다. 확장 상태에서는 날짜 셀 아래 근무 코드 배지를 사용하고, compact
    상태에서는 기존 작은 marker를 사용한다. 입력 중에는 수직 드래그 확장/축소를 잠근다.
    화면 높이가 750px 미만이면 전역 반응형 규칙에 따라 2주 보기를 계속 유지한다.
    다음 날 자동 이동은 `_selected_day`와 `_focused_day`를 함께 갱신해 월/2주 보기의 표시 페이지가
    선택일을 따라가게 하며, 캘린더·공휴일 데이터 추가 조회는 월 경계를 넘을 때만 실행한다.
    근무 설정 카드의 헤더 아래 본문은 12px padding을 사용한다.
  - `lib/features/calendar/application/calendar_range_state.dart`,
    `calendar_range_notifier.dart`: 메인·친구 캘린더가 공유하는 조회 상태다. 페이지가 주입한
    loader로 전월 1일~다음월 말일을 조회하고, 월별 loaded/loading 집합과 in-flight Future로
    동일 월 요청을 합친다. `WorkShiftApiModel`과 `EventApiModel`을 정규화된 날짜 맵에 병합하며
    생성·근무 저장·삭제 결과를 같은 캐시에 반영한다. 오류는 `last_error`와 증가하는
    `error_revision`으로 UI에 전달한다. 메인은 `calendarRangeProvider`, 친구는 친구 ID를 키로 한
    `friendCalendarRangeProvider`를 사용하고 두 Provider 모두 `autoDispose`다.
  - `lib/features/calendar/presentation/providers/calendar_range_provider.dart`,
    `lib/features/friend/presentation/providers/friend_calendar_range_provider.dart`: 같은
    `CalendarRangeNotifier`에 각각 `CalendarService.getCalendarRange()`와
    `FriendService.getFriendCalendarRange(friend_user_id)` loader를 주입하는 조립 지점이다.
    페이지는 focused month를 `ensureMonthLoaded()`에 전달하고 state의 `workShiftFor()`와
    `eventsFor()`만 읽는다. 인증 계정 전환 시 `AuthNotifier`가 두 provider 캐시를 무효화한다.
  - `lib/features/calendar/presentation/models/calendar_day_presentation.dart`: API/더미 도메인
    데이터를 날짜 셀이 이해하는 `CalendarDayPresentation`으로 바꾸는 공용 표시 계약이다.
    단일 근무는 `CalendarBadgeIndicator`, compact 또는 다중 구성원 근무는
    `CalendarDotsIndicator`로 표현하고, 셀은 `compact`·`badge`·`dots` 레이아웃만 해석한다.
  - `lib/features/calendar/presentation/models/calendar_layout_policy.dart`,
    `controllers/calendar_viewport_controller.dart`: 750px 미만 2주 보기, compact 48px,
    상세 52/56px 규칙과 2000.01~2050.12 월 이동 경계를 한 곳에서 관리한다.
    focused/selected 날짜를 실제로 변경하고 월 변경 후 API를 요청하는 시점은 각 페이지가 소유한다.
  - `lib/features/calendar/presentation/widgets/calendar_viewport.dart`,
    `calendar_month_view.dart`: 메인·친구·그룹 캘린더가 함께 사용하는 연월 헤더, 수평 스크롤
    알림 경계와 `TableCalendar` 날짜 셀이다. 한국어 요일, 날짜 의미 색상, badge/dots,
    오늘 밑줄, 선택 primary tint·2px outline을 한 곳에서 렌더링한다. 각 페이지는
    `CalendarDayPresentation` builder와 날짜·페이지 선택 콜백만 주입하며, 메인의 근무 편집
    draft와 일정 추가, 친구 설정, 그룹 구성원 상세는 이 공용 위젯에 넣지 않는다.
    근무 코드 배지는 저장된 근무 색상을 배경으로 유지하고 코드 글자는 해당 배경과 대비되는
    공용 전경색을 사용한다.
  - `test/features/calendar/application/calendar_range_notifier_test.dart`,
    `test/features/calendar/presentation/controllers/calendar_viewport_controller_test.dart`,
    `test/features/calendar/presentation/models/calendar_layout_policy_test.dart`: 동일 월 요청 병합,
    3개월 범위·데이터 병합·실패 재시도·mutation 반영, 월 경계와 화면 높이별 형식/행 높이를
    각각 검증한다. 공용 캘린더 계약을 변경할 때 세 페이지 위젯 테스트와 함께 실행한다.
  - `lib/features/calendar/presentation/widgets/calendar_schedule_card.dart`: 메인·친구 캘린더가
    함께 사용하는 선택일 일정 카드. `CalendarScheduleHeader`는 일정 카드와 메인 근무 설정 카드가
    같은 16px 수평·8px 수직 padding, 최소28px 콘텐츠, 날짜/공휴일 타이포와 0.5px 하단
    구분선을 사용한다. ADR-0068에 따라 그룹도 같은 헤더를 사용하며 한 줄이면44.5px,
    좁은 폭/확대 글자에서는 필요한 만큼 높아진다. 선택일은
    `M월 d일 EEEE` 한국어 형식으로 표시하고 일정 수는 `N개의 일정` 문장 대신
    `CalendarScheduleSummaryChip`의 `일정 N개` pill로 배치하며, 일정이 없을 때도 `일정 0개`를
    명시한다. 이 공용 pill은 그룹의 `근무 N명`·`일정 N개`에도 사용한다. 일정 카드는 이 헤더와
    근무·개인 일정 행, 빈 상태를 제공한다. 메인은 근무 삭제 wrapper와 개인 일정 추가 footer를
    주입하고, 친구 캘린더는 기본 읽기 전용 근무 행을 사용한다.
  - `lib/features/calendar/presentation/widgets/shift_type_button.dart`: 근무 타입 선택 버튼 위젯.
    기존 `ShiftTypeButtonGroup`은 근무 추가 페이지/시트에서 Provider 기반 원형 버튼을 표시하고,
    `ShiftTypeSelectionGrid`는 메인 캘린더가 전달한 정렬된 `ShiftTypeInfo` 목록을 실제 너비와
    높이에 맞춰 최대 5열로 배치한다. 메인 그리드는 코드/이름, 선택 상태, 접근성 label을
    제공하며 선택 콜백으로 코드만 반환한다. 근무 색상을 코드 선호색으로 사용하되 버튼 배경과
    4.5:1 대비가 부족한 옅은 색은 공용 어두운 전경색으로 대체한다.
  - `lib/features/calendar/presentation/widgets/year_month_picker_sheet.dart`: 메인 캘린더와 근무 추가
    화면이 함께 사용하는 연도/월 선택 하단 시트. 현재 선택값 요약, `이번 달` 빠른 이동,
    연도·월 휠, 취소/이동 액션을 Shift Harmony surface/primary 토큰으로 표시한다.
    호출 화면은 자신의 `TableCalendar.firstDay`/`lastDay`와 같은 연도 범위를 전달하고,
    반환된 월의 1일을 focused day로 사용한다.
  - `lib/features/calendar/presentation/widgets/date_picker_sheet.dart`: 개인 일정의 시작일/종료일처럼
    일 단위 날짜를 선택하는 공용 하단 시트. 연도/월 선택 시트와 같은 핸들, 선택값 요약 카드,
    빠른 `오늘` 액션, surface 기반 피커 카드, 취소/적용 버튼을 제공한다. 호출 화면이 최소/최대
    날짜를 전달하며, 결과는 시간이 제거된 로컬 `DateTime`으로 반환한다.
  - `lib/features/calendar/presentation/widgets/time_picker_sheet.dart`: 개인 일정과 근무 타입의
    시작시간/종료시간처럼 시·분 단위 시간을 선택하는 공용 하단 시트. 선택 시간을 오전/오후
    형식으로 요약하고,
    `지금` 빠른 선택, 24시간 시·분 휠, 취소/적용 버튼을 날짜 선택 시트와 같은 구조로 제공한다.
    결과는 0~23시와 0~59분으로 정규화된 `Duration`으로 반환한다.
  - `test/features/calendar/presentation/widgets/year_month_picker_sheet_test.dart`:
    연도/월 선택 시트의 초기 선택값 표시, 선택 결과 반환, 취소 시 null 반환을 검증한다.
  - `test/features/calendar/presentation/widgets/date_picker_sheet_test.dart`: 날짜 선택 시트의 초기 날짜
    요약 표시, 선택 결과 반환, 취소 시 null 반환을 검증한다.
  - `test/features/calendar/presentation/widgets/time_picker_sheet_test.dart`: 시간 선택 시트의 초기 시간
    요약 표시, 선택 결과 반환, 취소 시 null 반환을 검증한다.
  - `test/features/calendar/presentation/pages/calendar_page_test.dart`: 캘린더/알림 서비스를 가짜 구현으로
    대체하고 390x740 크기에서는 2주 보기가 고정되는지, 390x750 경계 크기에서는 기존 월 보기가
    유지되는지 검증한다. 2주 보기의 두 번째 토요일에서 근무를 입력하면 선택일·focused day·표시
    페이지가 다음 일요일로 함께 이동하는 회귀도 확인한다. 390x740 compact 보기와 390x800 2주
    보기에서는 근무 설정 진입 전후 달력 형식·행 높이와 하단 카드 크기가 같은지도 검증한다.
    일정 카드와 근무 설정 카드의 헤더 좌표·크기·구분선 및 공휴일명이 같은지도 검증한다.
    근무 타입 수정 표시 업데이트를 발행하면 캘린더 range API를 다시 호출하지 않고 이미 로드된
    선택일 근무의 이름·색상·시간이 PUT 응답값으로 교체되는지도 검증한다.
    또한 선택된 토요일/일요일의 의미 색상과
    8% primary tint 배경·2px primary dark outline, 날짜·근무 배지 셀의 레이아웃 예외,
    확장/compact 보기의
    마지막 행 선택 사각형이 달력 경계 안에 포함되는지 검증한다.
  - `lib/core/navigation/main_tab_page.dart`: 인증 후 공통 하단 탭(캘린더·친구·알림).
    탭별 Navigator와 지연 생성 IndexedStack으로 날짜·목록·상세 탐색 이력을 보존한다.
    오늘 이동은 달력 헤더의 명시적 버튼이며 탭 재선택은 날짜를 초기화하지 않는다.
    `bottom_action_bar.dart`는 참조 없는 기존 ShiftAddPage용 레거시 위젯으로 남고 현재 메인/친구에서는 사용하지 않는다.
  - `test/features/calendar/presentation/widgets/shift_type_button_test.dart`:
    `ShiftTypeSelectionGrid`가 320x128 영역에서 타입 1~10개를 스크롤/오버플로우 없이 표시하는지,
    10개를 5개씩 2행으로 배치하는지, 선택 코드를 콜백으로 전달하는지, 옅은 근무 색상에서
    코드 글자가 공용 어두운 전경색으로 보정되는지 검증한다.
  - `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`: 근무 패턴 설정 화면.
    `../design/stitch_shift_schedule_planner (4)/code.html` 시안의 중앙 `근무 패턴 설정`
    헤더, 근무 타입 수 배지, 카드형 근무 타입 목록, 하단 `근무 타입 추가` 버튼을
    Cupertino 기반 위젯으로 구현한다. 상단 `근무 패턴 설정` 헤더와 뒤로가기는
    `CupertinoPageScaffold.navigationBar`에 두어 설정 화면의 `CupertinoNavigationBar`와
    route 전환 시 같은 헤더 transition을 타게 한다. 근무 타입은 최대 10개까지 추가 가능하며,
    10개에 도달하면 추가 버튼을 `AppTheme.surface_container_highest_color` 배경으로
    비활성 표시하고 추가 모달 진입을 막는다. 이때 버튼 위에는 최대 10개 제한과 기존 타입
    삭제 후 추가 가능하다는 안내 문구를 표시한다. 추가 버튼은 스크롤 목록 안에 넣지 않고
    하단 안전영역을 반영한 고정 영역에 둬, 근무 타입이 10개여도 버튼과 마지막 카드가
    홈 인디케이터에 잘려 보이지 않게 한다. 시안 기준으로 이 화면 상단에는 템플릿 이름
    변경 액션을 노출하지 않는다.
  - `lib/features/calendar/presentation/widgets/shift_type_card.dart`: 근무 타입 목록 카드.
    원형 색상 배지 안에 코드, 오른쪽 본문에 이름과 시간 또는 `시간 없음`을 표시하고,
    삭제 버튼은 `CupertinoIcons.trash`와 outline 색상으로 표현한다. 카드는
    `ShiftTemplateSettingsPage`에서 편집/삭제 액션을 주입받아 사용한다. 원형 배지의 코드는
    저장된 근무 색상 명도에 따라 어두운색 또는 흰색을 선택해 낮은 농도에서도 읽을 수 있게 한다.
  - `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`: 근무 타입 추가/편집 화면.
    상단 뒤로가기, 52px 코드/이름/시간 요약 → 이름 → 표시 코드 → 표시 색상 → 시간 지정과 하단 저장이다.
    구체적인 반응형/시간 스위치/오류/포커스 정책은 상단 근무 타입 편집 재설계 구현 절과 ADR-0041을 따른다.
    기존 `CupertinoPageRoute`, 공용 `TimePickerSheet`, `HH:mm:ss` 요청과 코드 최대 3자/대문자 변환을 유지한다.
    중복은 입력 중 표시하지 않고 코드 포커스 이탈/저장 시 현재 템플릿 existingTypes와 대소문자 무관 비교하며
    편집 중인 자기 자신을 제외한다. 중복 notifier/포인터 비활성 오류 오버레이로 플랫폼 입력 연결을 유지한다.
    색상 행은 ShiftColorPickerPage의 완료 결과만 반영하며 최종색·기준색·정수 농도를 함께 보존한다.
    생성은 base_color/color_intensity를 함께 전송하고 색상 무변경 편집은 둘 다 생략한다.
    onCreate/onUpdate 콜백 성공 후에만 닫고 실패는 입력을 보존한다. 콜백 없는 테스트 호스트에는 DTO를 반환한다.
    UI state와 controller/focus/scroll/notifier는 화면이 소유·dispose한다.
  - `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`: 근무 타입 색상 선택 화면.
    좌측 뒤로가기/중앙 제목/우측 `완료`와 선택 미리보기→12개 프리셋→`선택한 색상 조절`을 제공한다.
    공통 16/14 타이포와 반경 16, 64px 미리보기, 52px 프리셋을 사용한다. 좁은 화면·큰 글자에서는
    미리보기를 세로로 배치하며 색상명 슬롯은 최소 24px에서 내용에 맞게 확장한다.
    뒤로가기는 값을 반환하지 않으며 완료만 최종 색상·기준 색상·정수 농도의 `ShiftColorSelection`을 반환한다.
    색상 농도는 서버 계약의 고정 흰색 `#FFFFFFFF`와 선택한 기준 색상을 정수 0~100 퍼센트로
    혼합하고 alpha를 항상 1로 고정한다. 각 RGB 채널을 서버와 같은 식으로 반올림해 테마 변경과
    무관하게 최종 색상을 일치시킨다. 0%는 불투명 흰색, 100%는 불투명 원본 색이며 중간값은
    배경이 비치지 않는 옅은 색이다. 계산/선택값은 `shift_color_selection.dart`에 공유한다.
  - `lib/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart`: 커스텀 근무 색상
    선택 전체 화면. 상단 최종 색상 미리보기와 스크롤 가능한 기준 HEX→휠→RGB→농도→최근 색상을 제공한다.
    입력 컨트롤은 기준색, 고정 미리보기는 최종색이며 농도 0%에서도 기준색을 잃지 않는다.
    휠 원 내부는 즉시 제스처를 소유하고, 농도 트랙은 탭/가로 드래그·접근성 조절을 지원한다.
    작은 화면·큰 글자는 독립된 둥근 패널 안에서 스크롤하며 키보드가 열려도 미리보기를 유지한다. 낮은 본문은 미리보기를 작게 표시한다. 저장 중 입력/뒤로가기/중복 완료를 막는다.
    완료 시 유효한 6자리 HEX를 검사하고 `ShiftColorSelection`으로 기준색/농도/최종색을 반환한다.
    뒤로가기는 결과/최근 기록을 저장하지 않는다. 최근 색상의 v2 메타데이터와 v1 호환 규칙은 상단 농도 통합 절을 따른다.
  - `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`: 작은 미리보기/하단 저장,
    이름→코드 포커스, 3자 대문자·조합 입력·중복 시 플랫폼 입력 연결, 대비색과 공용 색상/시간 페이지 왕복,
    기준색/농도 복원과 요청 생략, 시간 지정 해제의 명시적 null·재활성 복원·시간 쌍 오류,
    다음 날/분 단위 간격/동일 시간 0시간, 필수 입력 인접 오류와 포커스·취소 폐기를 검증한다.
  - `test/features/calendar/presentation/providers/shift_template_settings_provider_test.dart`:
    근무 타입 수정 요청이 진행되는 동안 설정 상태를 공용 로딩으로 전환하지 않는지, 서버 PUT 응답
    모델을 설정 목록에 그대로 반영하는지, 같은 응답을 기존 `shiftTypesProvider` GET 캐시 위에
    합성해 근무 입력용 표시 목록을 갱신하는지 검증한다. 가짜 템플릿/근무 타입 서비스를 주입해
    실제 네트워크 없이 Provider 상태 전이를 재현한다.
  - `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`: 색상 선택 화면의
    뒤로가기/완료 헤더와 공통 폼 크기, surface 카드 안의 선택 원→구분선→색상명/HEX
    좌우 좌표·정보 세로 순서와 편집 아이콘 미노출, 프리셋→선택한 색상 조절 순서와 프리셋
    개수 문구 미노출, 모든 프리셋의
    색상명 슬롯 높이·스크롤 오프셋·각 섹션 Y 좌표 불변,
    고정 흰색 혼합의 0·50·100% 계산, 저장된 기준 색상·농도 초기 복원,
    커스텀 왕복/취소/재진입의 기준색·농도 보존, 적용 시 최종 색상·기준 색상·농도 반환과
    뒤로가기 폐기, 전체 화면 커스텀 색상 적용을 검증한다.
  - `test/features/calendar/presentation/widgets/shift_custom_color_picker_page_test.dart`: 커스텀 색상
    화면의 공통 치수와 세로 스크롤, 같은 카드 안의 휠 위·RGB 아래 배치,
    축소 없는 슬라이더, HEX·RGB·색상 휠·최근 색상 간 동기화, 완료 색상
    반환과 뒤로가기 폐기, 기준색과 최종색의 분리/0·50·100% 농도/트랙 탭·드래그, 로컬 최근 색상의 메타데이터·v1 복구·빈 상태·최신순·중복 제거·6개 상한을 검증한다.
  - `lib/features/auth/presentation/pages/login_page.dart`: 비인증 사용자의 로그인 화면.
    `AuthNotifier`의 카카오·네이버·Google·Apple 로그인 콜백과 공용 로딩 표시를 제공한다.
    Apple 버튼은 서버와 Apple Developer 설정이 준비된 빌드에서만
    `APPLE_LOGIN_ENABLED=true`로 노출하며, 기본값은 false다.
    Google 버튼은 별도 기능 플래그 없이 항상 노출한다. 네 provider는
    `assets/icons/kakao.png`, `naver.png`, `google.png`, `apple.png`의 원형 아이콘을 64px로
    표시하고, 각 아이콘과 접근성 터치 영역을 동일한 64x64로 구성한다. 버튼 중심 간 거리는
    84px(64px 터치 영역 + 20px 간격)이다. `Wrap`이 390px에서 카카오→네이버→Google→Apple
    순서의 한 행을 만들고, 좁은 화면에서는 같은 순서로 자동 줄바꿈한다. 소셜 버튼 영역은
    가용 가로 너비를 채우고 `WrapAlignment.center`로 그룹을 화면 좌우 중앙에 배치하며,
    수평 위치 보정을 위한 px 기반 이동은 사용하지 않는다. 공용 로그인 요청 중에는
    아이콘을 유지한 채 모든 버튼을 비활성화·반투명 처리하고 아래 로딩 표시를 노출한다. 헤더부터
    약관까지를 하나의 중앙 콘텐츠 그룹으로 배치하고 헤더 설명과 소셜 버튼 사이 간격은 64px로
    고정한다. flex `Spacer`로 화면 상·하를 분리하지 않으며, 콘텐츠가 화면 높이를 넘으면
    `SingleChildScrollView`로 전체 로그인 요소에 접근한다. Google·Apple 사용자 취소는 실패
    alert로 처리하지 않는다.
  - `assets/icons/kakao.png`, `assets/icons/naver.png`, `assets/icons/google.png`,
    `assets/icons/apple.png`: 로그인 화면의 원형 아이콘 이미지. 네 파일은 모두 176x176 PNG이며
    이미지 자체 의미는 중복 읽지 않도록 제외하고 버튼 단위의 `카카오 로그인`, `네이버 로그인`,
    `Google 로그인`, `Apple 로그인` 접근성 레이블을 제공한다.
  - `test/features/auth/presentation/pages/login_page_test.dart`: Google 상시 노출, Apple 기능 플래그,
    네 아이콘의 64x64 터치/시각 크기, 20px 간격, 390px 한 줄과 좁은 화면 줄바꿈, 순서,
    176x176 원본 규격, 접근성 레이블, 공용 로딩 비활성화, 헤더-버튼 64px 세로 간격과 작은 높이의
    스크롤/overflow 방지를 검증한다.
  - `lib/features/auth/data/services/naver_login_service.dart`: `naver_login_flutter`이 연결한
    iOS/Android 네이버 네이티브 SDK를 호출하고 Access Token만 Repository에 반환한다.
    iOS는 네이버 앱 설치 시 앱 인증을 우선하며 미설치 때만 SDK 인앱 브라우저로 fallback한다.
    Android 로그인 결과에 토큰이 직접 포함되지 않는 경우 SDK의 현재 Access Token을 추가로
    조회한다. `NaverLoginSdk` 경계를 통해 플랫폼 채널 없이 서비스 결과를 단위 테스트할 수 있다.
  - `test/features/auth/data/services/naver_login_service_test.dart`: 로그인 결과 토큰 반환,
    Android 토큰 추가 조회, 사용자 취소·네이티브 취소 오류 변환과 SDK 로그아웃 위임을 검증한다.
  - `lib/features/auth/data/services/google_login_service.dart`: `GoogleSignIn.instance` 초기화를 한 번만
    수행하고 사용자 탭에서 `authenticate()`를 호출해 서버 audience용 ID Token만 반환한다.
    `GoogleSignInSdk` 경계로 client ID, 토큰 누락, 사용자 취소, 설정 오류와 로그아웃을 플랫폼 채널
    없이 테스트할 수 있다. Android는 `serverClientId`, iOS는 `clientId`와 `serverClientId`를 전달한다.
  - `test/features/auth/data/services/google_login_service_test.dart`: SDK 초기화 1회, 플랫폼별 client ID,
    ID Token 반환·누락, 취소·설정 오류의 사용자용 예외 변환과 로그아웃을 검증한다.
  - `lib/features/auth/data/models/apple_auth_models.dart`: 서버 challenge와 Apple SDK 결과를
    플랫폼 독립적인 요청 모델로 정규화한다. 서버에는 authorization code, 선택적인 identity token,
    state/nonce와 최초 로그인 이름만 전송하며 클라이언트 이메일은 보내지 않는다.
  - `lib/features/auth/data/services/apple_login_service.dart`: iOS 네이티브 인증과 Android 웹 인증을
    `AppleSignInSdk` 경계로 호출한다. 서버가 발급한 nonce/state를 SDK에 전달하고 반환 state를
    로컬에서도 대조한다. Android Service ID와 HTTPS callback은 challenge 응답을 사용하며,
    Chrome Custom Tab이 앱으로 돌아오지 않으면 2분 뒤 재시도 가능한 오류로 종료한다.
  - `test/features/auth/data/services/apple_login_service_test.dart`: iOS/Android 옵션, nonce/state,
    state 불일치, 사용자 취소와 지원 불가 처리를 실제 플랫폼 채널 없이 검증한다.
  - `lib/features/auth/presentation/pages/settings_page.dart`: 설정 화면. `../design/stitch_shift_schedule_planner (3)/code.html`
    시안의 중앙 `설정` 헤더, 프로필 카드, 근무 관리/지원 카드 섹션,
    별도 로그아웃·회원 탈퇴 버튼을 Cupertino 위젯으로 구현한다. 미지원 메뉴와 빈 섹션은 표시하지 않는다(ADR-0073). 설정 화면 내부에는
    하단 내비게이션을 두지 않고, 메인 캘린더에서 push된 페이지로 뒤로가기를 제공한다.
    상단 `설정` 헤더와 뒤로가기는 `CupertinoPageScaffold.navigationBar`에 두어 메인
    캘린더의 `CupertinoNavigationBar`와 route 전환 시 같은 헤더 transition을 타게 한다.
    프로필/설정 섹션/로그아웃 버튼만 본문 `ListView`에서 스크롤한다.
    전체 축소 대신 본문 16/설명 14와 최소 높이 56의 행을 사용한다. 큰 글자는 행 안에서 줄바꿈한다. 섹션 카드는
    행 배경/구분선을 `ClipRRect`로 먼저 클리핑하고, `foregroundDecoration`이 primary
    tint 1px outline을 마지막에 그려 같은 크기의 내부 surface가 border를 덮지 않게 한다.
    실제 표시 항목은 프로필 편집, `ShiftTemplateSettingsPage`로 이동하는 근무 패턴 설정,
    고객 지원, 개인정보처리방침, 버전 정보, 로그아웃, 회원 탈퇴이다. 회원 탈퇴는 로그아웃 아래의 별도 destructive 액션으로 노출하고,
    일정·근무표·친구·그룹 정보 삭제와 복구 불가를 최종 확인한 뒤만 요청한다.
    요청 중에는 로그아웃과 탈퇴 버튼을 모두 비활성화해 중복 요청을 막는다.
    프로필 편집은 상단 2026-11-10 절의 실제 편집 route를 사용한다. 기본 알림 설정, 다크 모드, 언어 및 지역, 글꼴 크기, 비밀번호 변경,
    로그인 생체 인증, 공지사항과 미지원 고객 센터는 UI에서 제거했다. 후속으로 실제 `/support` 페이지를 여는 고객 지원 행을 추가했다. 버전 정보는
    `AppConstants.app_version`을 표시한다.

### 아키텍처 개요

```
Page (UI)
  ↓
Provider/Notifier (State Management)
  ↓
Repository (Domain Interface)
  ↓
Service/DataSource (Data Layer)
  ↓
Dio (HTTP Client)
  ↓
API Server
```

캘린더 조회/표시의 구체 흐름은 다음과 같다.

```
CalendarPage / FriendCalendarPage
  → CalendarRangeNotifier(loader)
  → CalendarService / FriendService
  → Dio → API
  → CalendarRangeState
  → CalendarDayPresentation
  → CalendarViewport → CalendarMonthView
```

- 캘린더 UI state인 focused/selected 날짜, 선호 형식, 메인 근무 입력 draft는 페이지가 소유한다.
- 서버에서 조회한 근무·일정 domain state, 월별 로딩/완료/오류 상태는
  `CalendarRangeNotifier`가 소유한다.
- 실제 그룹 캘린더는 여러 소유자의 `owner_user_id`와 `calendar_access`를 보존하는
  `GroupCalendarRangeNotifier`를 사용한다. 그룹 timezone 변환과 월별 캐시는 그룹 전용 상태가
  담당하고, `CalendarDayPresentation`·공용 viewport·날짜 셀만 메인/친구 화면과 공유한다.
- `GROUP_API_ENABLED=false`인 기본 빌드는 서버 Stage 인수 전 rollback 경로로 결정적 더미
  `GroupCalendarPreviewPage`를 유지한다.

**에러 처리 흐름**:

```
DioException → handleApiError() → ApiException → UI (CupertinoAlertDialog)
```

### 푸시 알림·기기 동기화 흐름

```text
AuthWrapper 인증 상태
  → PushCoordinator
     ├─ 로그인/앱 시작: 권한 → APNs(iOS) → FCM token → PUT /devices/current
     ├─ onTokenRefresh: 강제 기기 동기화
     ├─ foreground 복귀: 5분 debounce 동기화
     ├─ onMessage: notification_id 중복 제거 → local banner → 미읽음 갱신
     └─ getInitialMessage/onMessageOpenedApp/local tap
          → pending destination
          → 인증·프로필 완료
          → NotificationPage
```

- 푸시 lifecycle은 인증 성공과 분리된 best-effort 동작이며 실패해도 로그인을 실패시키지 않습니다.
- 설치 UUID는 `InstallationIdService`가 secure storage에 만들고 logout 후에도 유지합니다.
- logout 요청에는 installation ID를 선택 필드로 보내 서버의 사용자-기기 귀속을 해제하며 local pending route와 중복 ID 상태는 지웁니다.
- foreground는 Firebase 자동 표시를 끄고 `shiftmate_high` local notification을 사용합니다. background/종료 상태 표시는 OS가 처리합니다.
- schema v1과 `destination=NOTIFICATIONS`만 수용하고 모든 알림 탭 이벤트는 세부 화면 대신 MainTabPage의 알림 탭(`NotificationPage`)으로 이동합니다.
- Debug는 Stage Firebase/API, Profile/Release는 Production Firebase/API를 사용합니다. 설정 값은 `--dart-define`으로 주입하며 없으면 push만 비활성화합니다.
- 파일 역할·환경 변수·실기기 인수는 `_docs/PUSH_NOTIFICATION_GUIDE.md`, 결정 근거는 ADR-0018을 정본으로 사용합니다.

### API 기본 URL 정책

- `ApiConstants.base_url`은 `kDebugMode`를 기준으로 빌드 모드별 주소를 선택한다.
- 디버그 빌드(개발/Stage): `https://stage-api.shiftmate.co.kr/api/v1`
- 릴리스 빌드(운영/Center): `https://api.shiftmate.co.kr/api/v1`
- `ApiClient.createDio()`가 선택된 값을 Dio `BaseOptions.baseUrl`에 적용하고,
  각 서비스는 `ApiConstants`의 상대 엔드포인트를 결합해 요청한다.
- 그룹 Stage 인수 시 테스트한 origin·서버 이미지·migration 적용 시각을 작업 로그에 기록한다.
- 기기 등록은 인증 `PUT /devices/current`를 사용하며 raw FCM token은 응답/로그에 노출하지 않는다.

### 카카오 인증 및 프로필 저장 흐름

```
LoginPage
  → Kakao Flutter SDK (카카오톡/카카오 계정 로그인)
  → Kakao Access Token
  → POST /api/v1/auth/kakao/token
  → 신규 사용자: ProfileSetupPage
  → POST /api/v1/auth/profile/complete
  → CalendarPage
```

- 현재 앱은 카카오 Flutter 네이티브 SDK가 인증과 Access Token 발급을 담당한다.
  Stage API 주소를 카카오 웹 Redirect URI로 사용하지 않는다.
- 네이티브 앱 콜백은 Android `AndroidManifest.xml`과 iOS `Info.plist`에서
  `kakao${KAKAO_NATIVE_APP_KEY}://oauth` 스킴으로 연결한다.
- 카카오 SDK는 `main.dart`에서 Native App Key로 초기화한다. 카카오 개발자 콘솔의 네이티브
  플랫폼 설정은 Android 패키지명 `com.hspark.shiftmate`와 빌드 서명 키 해시,
  iOS Bundle ID `com.hspark.shiftmate`를 사용한다. 카카오 로그인을 활성화하고
  닉네임·프로필 이미지·이메일 동의항목을 설정한다.
- Native App Key는 Debug(Stage)와 Profile/Release(Production)를 분리하되, 각 환경 안에서는
  Dart SDK 초기화 값과 네이티브 callback URL Scheme에 같은 키를 주입한다.
  `.env`에는 Stage용 `KAKAO_NATIVE_APP_KEY_STAGE`와 Production용
  `KAKAO_NATIVE_APP_KEY`를 두고 `--dart-define-from-file=.env`로 전달한다.
  `AppConstants`는 `kDebugMode`가 true일 때 Stage 키, 그 외 Profile/Release에서는 Production
  키를 선택한다. 네이티브 callback은 Android의 gitignored `android/secrets.properties`에
  같은 두 이름을 두고 Gradle build type별 Manifest placeholder로 선택하며, iOS의 gitignored
  `ios/Flutter/Secrets.xcconfig`에 같은 두 이름을 두고 Debug xcconfig만 Stage 키를 공용
  `KAKAO_NATIVE_APP_KEY` build setting으로 매핑한다. Profile/Release xcconfig는 Production
  `KAKAO_NATIVE_APP_KEY`를 그대로 사용한다. Dart define은 Gradle/Xcode build setting을
  자동으로 채우지 않으며 네이티브 secret 파일도 `String.fromEnvironment`를 채우지 않는다.
- `main.dart`는 현재 빌드가 선택한 Dart define 키가 비어 있으면 `StateError`로 시작을
  중단하고 누락된 환경변수 이름을 표시한다. 카카오 버튼이 항상 노출되는 현재 앱에서 빈 키로
  SDK를 초기화하지 않는다.
- `test/core/constants/app_constants_test.dart`는 Debug 테스트 빌드에 Stage sentinel을 Dart
  define으로 주입해 `AppConstants`가 Stage 키와 환경변수 이름을 선택하는지 검증한다.
- `AuthRepositoryImpl.loginWithKakao()`는 SDK 토큰을
  `AuthRemoteDataSource.loginWithKakaoToken()`에 전달하며, 서버 토큰 교환 요청 본문은
  `{"access_token": "<Kakao Access Token>"}`이다.
- 카카오 token endpoint의 Dio 실패는 공용 `handleApiError()`로 변환해 서버의 구조화된
  `error.code`, `error.message`, `request_id`를 `ApiException`에 보존한다. 토큰 발급 앱 불일치처럼
  인증이 거부된 이유를 일반 문자열 예외로 소실하지 않는다.
- 서버는 Redirect URI 없이 `POST /api/v1/auth/kakao/token`만 운영 계약으로 제공해야 하며,
  전달받은 토큰의 `/v1/user/access_token_info.app_id`를 서버의 기대 Kakao App ID와 비교한 뒤
  사용자 정보를 조회해야 한다. 상세 구현·환경변수·레거시 제거·테스트 계약은
  `_docs/KAKAO_LOGIN_SERVER_REQUEST.md`를 따른다.
- Express 서버의 일반 프로필 수정 계약은 `POST /api/v1/auth/profile`이고 가입 완료 계약은
  `POST /api/v1/auth/profile/complete`로 분리한다. 가입 화면의 필수 입력은 이름·휴대폰이며
  직종·재직 중인 회사/기관 및 부서·프로필 이미지는 선택이다. 직종은 특정 업종 enum을 고르는
  방식이 아니라 최대 20자의 자유 문자열을 직접 입력한다. 서버는 기존
  `NURSE/DOCTOR/EMT/OTHER` check와 enum validation을 제거한 뒤 Flutter보다 먼저 배포해야 한다.
  타임존 행은 노출하지 않고 `flutter_timezone`으로 조회한 기기 IANA timezone을 시스템 필드로
  전송한다. 조회 실패 시 서버 사용자 값 또는 앱 기본값을 쓴다.
- 가입 화면의 아바타를 누르면 `image_picker`로 사진 한 장을 선택한다. 앱은 최대 1024x1024,
  품질 85로 요청하고 5MB 초과 결과는 전송하지 않는다. 이미지를 선택하지 않으면 기존 JSON,
  선택하면 텍스트 필드와 `profile_image` 파일을 포함한 multipart 요청을 같은 완료 endpoint로 보낸다.
  서버 object storage 계약과 선배포 조건은 `_docs/PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md`를 따른다.
- 서버 응답의 `requires_profile_setup`만 가입 화면 분기의 정본으로 사용한다. OAuth의
  `is_new_user`는 계정 생성 여부를 위한 서버 호환 필드이며 Flutter 화면 상태에 보관하거나
  분기 조건으로 사용하지 않는다. 따라서 앱 종료·재실행 뒤에도 서버의 영속 완료 상태로
  입력 화면을 재개한다.
- `../design/signup input personal data/code.html`은 프로필 설정의 UI/UX 검토용 HTML 시안이다.
  기본 정보는 `필수` 배지와 필수 표시를 사용하고, 근무 정보는 `선택` 배지 및
  `지금 입력하지 않아도 괜찮아요` 안내를 항상 노출한다. 선택 근무 정보가 비어 있어도
  하단의 단일 `저장하고 시작하기` 동작을 막지 않는다. 화면 배경 탭과 목록 드래그는 현재 입력
  포커스를 해제한다. 휴대폰은 숫자만 받아 입력 중 한국 형식(`010-1234-5678`, 10자리 번호는
  `01X-XXX-XXXX`)으로 하이픈을 표시하지만 API에는 숫자만 보낸다. 기본·근무 정보 카드는 내부
  행을 16px로 클립한 뒤 테두리를 foreground에 그려 하단 모서리와 outline이 잘리지 않게 한다.
  Flutter 화면과 클라이언트 계약은 구현됐고,
  서버의 DB/API/응답 변경과 선배포 조건은 `_docs/PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md`를
  정본으로 따른다.
- 파일 역할/의존성/사용 예:
  - `lib/features/auth/data/datasources/auth_remote_datasource.dart`: 카카오 SDK 로그인,
    서버 토큰 교환, 프로필 조회·수정과 로그아웃 HTTP 요청을 담당한다.
    신규 사용자 프로필 완료 시 `completeProfile()`이 전용 POST 요청을 보낸다.
  - `lib/features/auth/presentation/pages/profile_setup_page.dart`: 필수 기본 정보와 선택 근무 정보를
    분리하고, 배경 탭 키보드 해제, 직종 자유 입력, 휴대폰 실시간 하이픈 표시, 카드 반경 보존,
    프로필 이미지 선택·미리보기와 기기 timezone 자동 조회 후 가입 완료 API를 호출한다.
  - `lib/features/auth/domain/entities/profile_image_upload.dart`: 선택 이미지의 byte, 파일명, MIME type을
    data 계층까지 전달한다. datasource가 multipart의 `profile_image` part로 변환한다.
  - `test/features/auth/data/datasources/auth_remote_datasource_test.dart`:
    실제 네트워크 대신 Dio 인터셉터로 요청을 가로챈다. 카카오·네이버 SDK Access Token과 Google
    ID Token이 각 `/auth/kakao/token`, `/auth/naver/token`, `/auth/google/token` 요청의 정확한 필드로 전달되는지,
    Google 응답의 `google_id`와 millisecond `expires_at`, 프로필 수정·가입 완료의 POST
    메서드·경로·선택값 생략·응답 파싱을 검증한다. 카카오 App ID 불일치 응답과 프로필 구조화
    오류의 코드·메시지·request ID 보존도 검증한다.
  - `test/features/auth/presentation/pages/profile_setup_page_test.dart`: 390x844 화면에서 필수·선택
    위계, 단일 CTA, 입력 밖 포커스 해제, 휴대폰 formatter·검증·숫자 전송, 직종 자유 입력,
    업종 중립 문구, 카드 클립·foreground outline과 선택값 생략/전달을 검증한다.
  - `build.yaml`: Freezed/json_serializable 입력을 실제 annotation 파일로 제한해 Dart SDK와
    analyzer 언어 버전 차이로 사용하지 않는 builder가 전체 소스를 분석하는 실패를 피한다.
    entity나 `@freezed` 모델을 새 위치에 추가하면 include 목록도 함께 갱신한다.
  - `_docs/PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md`: 가입 완료 DB migration, Express 흐름,
    API·오류·개인정보·OpenAPI·테스트·서버 선배포 순서를 정의하는 서버 전달 정본이다.
  - `test/features/auth/data/repositories/auth_repository_impl_test.dart`:
    카카오 SDK Access Token이 server token datasource로 전달되고 서버 성공 후 ShiftMate JWT가
    저장되는지 검증한다. Apple challenge/code, Google ID Token, 회원 탈퇴 세션 정리 회귀도 함께
    고정한다.
  - `_docs/KAKAO_LOGIN_SERVER_REQUEST.md`: 현재 Flutter SDK 토큰 로그인과 키 주입 완료 범위,
    Express의 Kakao App ID 검증, SDK 전용 endpoint, Admin Key 탈퇴 worker, 배포·테스트·롤백
    인수 조건을 서버 담당자에게 전달하는 정본이다.

### 네이버 네이티브 인증 흐름

```
LoginPage
  → Naver iOS/Android Native SDK
  → 네이버 앱 우선 인증(미설치 시 SDK 브라우저 fallback)
  → Naver Access Token
  → POST /api/v1/auth/naver/token
  → 신규 사용자: ProfileSetupPage
  → POST /api/v1/auth/profile
  → CalendarPage
```

- 앱 내부 `InAppWebView`에서 네이버 ID/비밀번호를 직접 입력받거나 OAuth fragment를 파싱하지
  않는다. `naver_login_flutter` 3.0.4가 공식 iOS/Android SDK를 연결하며, iOS 로그인 동작은
  `appPreferredWithInAppBrowserFallback`이다.
- `AuthRepositoryImpl.loginWithNaver()`는 SDK Access Token을
  `AuthRemoteDataSource.loginWithNaverToken()`에 전달한다. 서버 요청 본문은
  `{"access_token": "<Naver Access Token>"}`이며 앱 JWT 저장 방식은 카카오와 같다.
- iOS Bundle ID는 `com.hspark.shiftmate`, 네이버 전용 URL Scheme과 `NidUrlScheme`은
  모두 `com.hspark.shiftmate`로 일치시킨다. 네이버 개발자 센터의 iOS `URL Scheme`에도
  `com.hspark.shiftmate`만 등록하며 `://naver/callback` 경로를 붙이지 않는다.
- Android 네이버 개발자 센터에는 패키지명 `com.hspark.shiftmate`를 등록한다.
  기존 WebView callback intent-filter는 사용하지 않으며, 공식 SDK가 인증 결과를 처리한다.
- 네이티브 SDK 키는 소스에 직접 넣지 않는다.
  - Android 로컬: gitignored `android/secrets.properties`에
    `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET`을 설정한다.
  - iOS 로컬: gitignored `ios/Flutter/Secrets.xcconfig`에
    `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET`을 설정한다.
  - CI/CD: 같은 이름의 Gradle project property/Xcode build setting을 주입한다.
- 로그아웃은 서버 refresh token 폐기 시도 후 카카오·네이버·Google SDK 로컬 세션을 각각 정리하고,
  소셜 SDK 오류 여부와 관계없이 앱 JWT를 삭제한다.

### 회원 탈퇴 흐름

```text
SettingsPage 최종 확인
  → Google 현재 계정 disconnect / Naver 현재 SDK token disconnect
  → DELETE /api/v1/auth/account { confirmation: true }
  → 202: 로컬 JWT·소셜 로컬 세션·계정 Provider 캐시 정리
  → 로그인 화면으로 navigation stack 초기화
```

- 탈퇴는 서버의 비동기 삭제 작업을 시작하는 `202 Accepted`를 성공 기준으로 삼고
  삭제 완료 상태를 폴링하지 않는다.
- 요청은 boolean `confirmation: true`만 전송한다. 탈퇴 API의 `401`은 refresh token으로
  자동 재시도하지 않고 로컬 인증을 정리한다. `ACCOUNT_DELETION_IN_PROGRESS`도 이미
  접수된 상태로 보고 동일하게 로그인 화면으로 이동한다.
- `REAUTHENTICATION_REQUIRED`는 현재 JWT와 설정 화면을 유지하고 전용 안내를 표시한다.
  `다시 로그인` 선택 시 로컬 세션을 종료하고 로그인 화면으로 이동하며, 전체
  로그인 후 사용자가 탈퇴를 다시 확인해야 한다. access token refresh는 재인증이 아니다.
- Google은 현재 사용자의 `google_id`가 있을 때 연결을 해제한다. iOS의 선행 복원·갱신/동일 계정 확인 및 400 재로그인 분기는 ADR-0080과 위 2026-11-13 항목을 따른다.
  Naver는 SDK의 현재 access token이 있을 때만 `logOutAndDeleteToken()`으로 앱 연결을
  해제한다. Apple·Kakao provider revoke는 서버 비동기 삭제 작업이 담당한다.
- `ApiException.request_id`는 서버 오류 추적 ID를 보존한다. 미접수 오류는 request ID를
  로그에 남기고 로컬 로그인 상태를 유지하며, 서버 메시지를 alert로 표시한다.
- 파일 역할/의존성/사용 예:
  - `AuthRemoteDataSource.deleteAccount()`: refresh 자동 재시도를 비활성화한 DELETE 요청과
    `202` 성공 계약을 구현한다.
  - `AuthRepositoryImpl.deleteAccount()`: Google/Naver 사전 연결 해제, 서버 접수,
    로컬 credential 정리 순서를 소유한다.
  - `AuthNotifier.deleteAccount()`: API 오류 코드를 UI 결과로 변환하고 성공·이미 처리 중·
    미인증 시 계정 단위 Provider 캐시를 무효화한다.
  - `test/features/auth/presentation/pages/settings_page_test.dart`: 버튼 동시 노출, 복구 불가 확인,
    성공 후 로그인 이동과 재인증 안내를 검증한다.

### Google ID Token 인증 흐름

```text
LoginPage
  → GoogleLoginService → google_sign_in authenticate()
  → Google ID Token
  → POST /api/v1/auth/google/token { id_token }
  → 서버 verifyIdToken() 및 사용자 정책 적용
  → ShiftMate Access/Refresh Token
  → 신규 사용자: ProfileSetupPage
  → 기존 사용자: CalendarPage
```

- `google_sign_in` 7.2.0을 고정하며 Google API scope나 authorization code를 요청하지 않는다.
- `AuthRepositoryImpl.loginWithGoogle()`은 SDK ID Token을 서버에 전달하고 서버 성공 후에만 기존
  `TokenService`에 ShiftMate JWT를 저장한다. 서버 교환 실패 시 Google 로컬 세션을 정리한다.
- `AuthRemoteDataSource.loginWithGoogleIdToken()`은 public endpoint인 `/auth/google/token`에
  `{"id_token":"..."}`만 전송한다. 응답 `expires_at` 정수는 Unix epoch milliseconds로 파싱한다.
- Google 취소는 `GoogleLoginCanceledException`으로 분리해 `AuthNotifier`와 로그인 화면이 오류
  dialog를 표시하지 않는다. 다른 SDK/설정 오류와 서버 오류는 사용자용 메시지로 표시한다.
- `User.google_id`는 서버 전환 전후 응답을 함께 처리할 수 있는 nullable 필드다.
- 빌드 설정:
  - Android/iOS 공통 Dart define: `GOOGLE_SERVER_CLIENT_ID` (Web application OAuth client ID)
  - iOS Dart define: `GOOGLE_IOS_CLIENT_ID`
  - iOS xcconfig build setting: `GOOGLE_REVERSED_CLIENT_ID`; `Info.plist` URL scheme이 이를 참조한다.
  - Android는 `google-services.json` 없이 `serverClientId`를 전달한다. Google Cloud에 package
    `com.hspark.shiftmate`와 Debug/Stage/Release별 SHA-1·SHA-256을 등록한다.
- 파일 역할/의존성/사용 예:
  - `lib/core/constants/app_constants.dart`: 두 Google Dart define을 compile-time 상수로 제공한다.
  - `lib/features/auth/data/repositories/auth_repository_impl.dart`: Google SDK → 서버 → JWT 저장 순서와
    서버 실패/앱 로그아웃의 Google 세션 정리를 소유한다.
  - `_docs/GOOGLE_SIGN_IN_SERVER_GUIDE.md`: 실제 Express route/controller/service/model/migration과
    OpenAPI 구조에 맞춘 검증, 이메일 충돌, 오류, 환경변수, Stage/Center 배포·롤백 요구문서다.
  - Google 서버 구현의 핵심 정책은 검증된 `sub`만 로그인 키로 사용하고 같은 이메일의 기존 계정에
    자동 연결하지 않는 것이다.

### Apple 인증 흐름

```text
LoginPage
  → POST /api/v1/auth/apple/challenge { platform }
  → AppleLoginService
     ├─ iOS: AuthenticationServices 네이티브 인증
     └─ Android: Service ID + HTTPS callback 웹 인증
  → POST /api/v1/auth/apple
     { platform, authorization_code, identity_token?, state, nonce, name? }
  → 서버 Apple code/token/claim 검증
  → ShiftMate Access/Refresh Token
  → 신규 사용자: ProfileSetupPage
  → 기존 사용자: CalendarPage
```

- Flutter 3.38.5/Dart 3.10.4와 호환되는 `sign_in_with_apple` 7.0.1을 고정한다.
- `AuthRepositoryImpl.loginWithApple()`은 challenge → SDK → 서버 검증 순서를 소유하고 서버 성공
  이후에만 기존 `TokenService`로 앱 JWT를 저장한다.
- `AuthRemoteDataSource`는 public endpoint인 `/auth/apple/challenge`, `/auth/apple`만 호출한다.
  Android의 `/auth/apple/callback`은 Apple 서버와 plugin callback activity 사이의 경로이므로
  Flutter가 직접 호출하지 않는다.
- challenge 응답이 플랫폼별 `client_id`와 `redirect_uri`를 제공한다. 앱에 Apple Service ID나
  callback을 하드코딩하지 않는다.
- `AuthResponse`는 `data.requires_profile_setup`을 파싱해 인증 상태와 화면 분기에 전달한다.
  서버 메시지나 `is_new_user`는 가입 완료 여부를 추론하는 fallback으로 사용하지 않는다.
- iOS `Runner.entitlements`와 Xcode target에 Sign in with Apple capability를 선언한다.
  실제 실행에는 Apple Developer App ID capability와 갱신된 provisioning profile이 필요하다.
- Android manifest는 plugin의 `signinwithapple://callback` activity를 등록하며 기존 MainActivity의
  `singleTop`을 유지한다.
- 서버 구현 전 또는 Stage 검증 전에는 `APPLE_LOGIN_ENABLED=false`로 버튼을 숨긴다.
- 파일 역할/의존성/사용 예:
  - `lib/core/constants/app_constants.dart`: Apple 로그인 빌드 기능 플래그를 제공한다. 서버 활성화,
    Apple Developer 설정, 실기기 검증이 모두 끝난 환경에서만 `--dart-define`으로 true를 전달한다.
  - `lib/features/auth/data/datasources/auth_remote_datasource.dart`: challenge와 로그인 완료 HTTP 계약을
    구현하고 서버 오류를 `ApiException`으로 변환한다.
  - `lib/features/auth/data/repositories/auth_repository_impl.dart`: Apple SDK 결과를 서버가 검증하기
    전에는 앱 세션을 만들지 않으며 성공 응답의 앱 JWT만 secure storage에 저장한다.
  - `_docs/APPLE_SIGN_IN_SERVER_GUIDE.md`: 현재 Express route/controller/service/model/migration 규칙에
    맞춘 Apple code 교환, JWKS 검증, 이메일 충돌, token 암호화/revoke, OpenAPI, 테스트,
    Stage/Center 배포·롤백 가이드다. 서버 구현 티켓과 완료 감사 체크리스트로 사용한다.
  - `test/features/auth/data/repositories/auth_repository_impl_test.dart`,
    `test/features/auth/presentation/providers/auth_provider_test.dart`: challenge → SDK → 서버 → 앱 JWT
    순서와 사용자 취소 시 오류 미노출을 검증한다.

현재 `schema.drawio`와 `visibility_flow.drawio`는 Apple 인증 테이블과 `users.google_id`를 포함하지
않으며, `schema.drawio`는 최종 단일 캘린더 DDL보다 오래된 구조다. 서버에서 Google migration을
구현할 때 Apple 정본화 상태도 확인하고 서버 정본 DDL·AGENTS 문서·drawio를 함께 갱신해야 한다.

### 메인 캘린더 조회/표시 흐름

```
CalendarPage
  → calendarRangeProvider
  → CalendarRangeNotifier.ensureMonthLoaded()
  → CalendarService.getCalendarRange()
  → GET /api/v1/calendar/range
  → CalendarRangeResponse(work_shifts, events)
  → CalendarRangeState 날짜별 맵
  → CalendarDayPresentation
  → CalendarViewport + 선택 날짜 일정 카드
```

- 메인 캘린더의 저장된 근무표 표시는 서버가 반환한 `WorkShiftApiModel`을 기준으로 한다.
- 근무 타입 수정 흐름은 `ShiftTypeFormModal → PUT /shift-types/:id
  → UpdateShiftTypeResponse.data → ShiftTemplateSettingsState +
  shiftTypeDisplayUpdatesProvider → CalendarPage` 순서다. 수정 요청 중 설정 화면의 공용
  `is_loading`이나 별도 로딩 다이얼로그를 사용하지 않고, 서버 응답 모델로 목록의 해당 항목만 교체한다.
- 메인 달력은 근무 코드 배지를 기본 노출하고, compact 보기에서는 기존 색상 점을 표시한다.
  화면 높이 750px 미만에서는 2주 보기로 고정하며, 750px 이상에서는 기존 월/2주/주 형식 전환을
  유지한다. 좌우 기간 이동 동작은 두 경우 모두 유지한다.
- `work_shifts` 응답의 `shift_type_code`, `shift_type_name`, `shift_type_color`,
  `start_time`, `end_time`은 저장된 근무표 표시용 스냅샷이다.
- `shiftTypesProvider`는 현재 계정의 근무 타입 설정 조회 및 근무 입력 원형 버튼 표시용이다.
  `effectiveShiftTypesProvider`는 GET 결과 위에 같은 세션의 수정 PUT 응답만 합성해 추가 GET 없이
  근무 입력 버튼을 최신화한다.
- 저장된 근무표를 처음 화면에 그릴 때는 `shiftTypesProvider`의 코드별 캐시로 색상/이름/시간을
  재해석하지 않는다. 다만 화면이 유지된 상태에서 근무 타입 수정 응답이 도착하면
  `CalendarPage`가 수정 전 코드와 일치하는 `CalendarRangeState`와 편집용 `_schedules` 항목의
  코드·이름·색상·시간만 응답값으로 교체한다.
- 이 stale 표시는 `SharedPreferences`나 보안 저장소의 영속 로컬 데이터가 원인이 아니다.
  설정 route 아래에 계속 살아 있는 `CalendarPage`의 range provider 메모리 캐시가 수정 응답을
  전달받지 못하면 발생하므로, PUT 응답을 notifier의 `upsertWorkShifts()`로 직접 반영한다.
- 메인 캘린더 근무 추가 모드는 서버 저장 전 `_schedules`에 임시 선택값을 쌓는다.
  진입 시 기존 `CalendarFormat`/확장 상태를 저장하고 월 확장 보기를 활성화하며, 입력 중에는
  확장/축소 드래그를 잠근다. 완료/취소 시 기존 달력 형식과 확장 상태를 복구한다.
  선택일의 원형 버튼에서 근무 타입을 누르면 다음 날로 자동 이동하고, 근무 설정 카드 내부 `완료` 버튼을
  눌렀을 때 변경된 항목만 `WorkShiftService.batchUpsertWorkShifts()`로 저장한다.
- 로그인/로그아웃으로 계정이 바뀌면 근무 타입, 수정 응답 표시 업데이트, 근무 템플릿 설정,
  메인·친구 캘린더 range, 친구, 알림 Provider 캐시를 무효화한다.

### 개인 일정 생성/표시/삭제 흐름

```
CalendarPage
  → PersonalEventFormModal
  → CalendarService.createEvent()
  → POST /api/v1/events
  → EventApiModel
  → 선택 날짜 일정 목록에 즉시 반영
```

```
CalendarPage 개인 일정 왼쪽 스와이프
  → CalendarService.deleteEvent(event_id)
  → DELETE /api/v1/events/{event_id}
  → CalendarRangeNotifier.removeEvent(event_id)
  → 모든 날짜 캐시에서 즉시 제거
```

- 메인 캘린더 선택일 카드는 하단 탭 위 16px(`AppTheme.spacing_md`) 여백을 제외한 달력 아래 남은
  `Expanded` 하단 슬롯을 채운다(2026-11-11 사용자 피드백 반영). 근무 설정 카드도 같은 슬롯/간격을
  사용한다. 작은 화면·큰 글자의 기존 스크롤 배치는 목록 끝에서 같은 16px 여백을 유지한다. 일정이 가용 높이를
  넘을 때만 목록을 내부 스크롤한다. `일정 추가하기...`는 카드 하단의 구분선 없는 primary 인셋
  액션으로 표시하며 개인 일정 추가 모달을 띄운다.
- 선택일 카드의 공휴일명은 날짜 아래에 별도 줄을 만들지 않고 날짜 오른쪽 하단에 한 줄 accent red
  라벨로 표시한다. 공휴일명이 길면 말줄임해 오른쪽 일정 수를 유지하며, 공휴일 유무와 관계없이
  날짜·일정 수 헤더 높이는 동일하게 유지한다.
- 선택일의 근무 일정은 왼쪽 스와이프로 삭제한다. `Dismissible.onUpdate.progress`와 항목 너비로
  현재 노출 폭을 계산하고, 그 폭 자체를 가진 12px radius 삭제 배경을 오른쪽 정렬해 부분 스와이프
  중에도 노출 영역의 양쪽 모서리가 둥글게 보이게 한다. 삭제 API는 기존처럼 `confirmDismiss`에서
  호출하며 실패 시 항목을 원래 위치로 복원한다.
- 본인 개인 일정도 근무 일정과 같은 왼쪽 스와이프, chevron, 삭제 배경을 사용한다. 삭제 요청은
  body 없이 `DELETE /api/v1/events/{event_id}`로 보내고 요청 중 같은 ID의 중복 실행을 막는다.
  `200`이면 응답의 `data.event_id`를 기준으로 다일 일정을 포함한 모든 날짜 캐시에서 제거한다.
  `404 EVENT_NOT_FOUND`도 서버 활성 상태가 이미 삭제된 것이므로 요청 ID를 로컬에서 제거하고
  `이미 삭제된 일정입니다.`를 안내한다. `500`·네트워크 오류는 항목을 유지해 재시도할 수 있게 하며,
  `400 INVALID_EVENT_ID`는 오류 안내 후 현재 월 범위를 다시 조회한다. 친구·그룹 캘린더는 읽기
  전용이므로 타인 일정 삭제 액션을 제공하지 않는다.
- 입력 필수값은 `title`, `all_day`, `start_at`, `end_at`, `visibility_level`이다.
- 선택값은 `place`, `memo`이며, 빈 문자열은 요청에서 제외한다.
- `owner_user_id`, `created_by_user_id`는 서버가 인증 사용자 기준으로 채운다.
- 프론트는 로컬 `DateTime`을 UTC ISO 문자열로 변환해 요청하고, 응답의 `start_at`/`end_at`은 로컬 시간으로 파싱해 표시한다.
- 종일 일정은 `end_at`을 배타적 종료 시각으로 사용한다. 하루짜리 종일 일정은 선택일 00:00부터 다음 날 00:00까지로 저장한다.
- `event_api_model.dart`의 `addEventToCalendarDateMap()`이 메인·친구 응답을 같은 날짜별 맵으로
  변환한다. 자정인 배타적 종료일은 제외하고, 같은 일정 ID는 중복 제거한 뒤 시작 시각순으로 정렬한다.
- 공개 판단은 서버 책임이다. 내 일정을 친구가 볼 때 서버는 `friend_level_settings.owner_user_id = 내 user_id`,
  `friend_level_settings.friend_user_id = 조회자 user_id`, `can_view=true`,
  `friend_level >= events.visibility_level` 조건을 적용한다.
- API 서버 요청 문서는 기능별 가이드에 둔다.
  - 개인 일정 생성: `_docs/EVENT_API_GUIDE.md`
  - 개인 일정 삭제: `../shift_calendar_server/_docs/EVENT_DELETION_FRONTEND_API_GUIDE.md`
  - 근무 타입 기준 색상·농도 영속화 계획:
    `_docs/SHIFT_TYPE_COLOR_METADATA_API_GUIDE.md`
- 파일 역할/의존성/사용 예:
  - `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`:
    개인 일정 입력 모달. `CalendarPage`에서 `showCupertinoModalPopup`으로 호출하고
    저장 시 `CreateEventRequest`를 반환한다. 최신 UI/입력 정책은 ADR-0047/0048과 상단 구현 절을 따른다.
    전체 화면에서 제목·일시·공개 범위·선택 장소/메모를 편집하고 키보드 위 하단 저장을 사용한다.
    인라인 공개 방식과0~5 정수 슬라이더/숫자 탭을 사용한다. 나만 보기는 is_private boolean으로 전송한다.
    시작일/종료일은 공용 `DatePickerSheet`, 시작시간/종료시간은 공용 `TimePickerSheet`를 재사용한다.
    날짜가 반대편을 넘으면 기존 선후 보정을 유지한다. 시간은 `Duration` 상태와 검증을 유지한다.
    저장 중 이탈/입력은 막고 실패 시 입력을 보존한다. 그 외 손잡이/본문 최상단 아래 끌기·닫기/OS 복귀는 폐기 확인 없이 닫는다.
  - `_docs/EVENT_API_GUIDE.md`: 개인 일정 생성 API, 입력 필수/선택값,
    공개 레벨 규칙, 서버 DDL 확인 요청을 정리한 서버 구현 문서다.
  - `test/features/calendar/data/services/calendar_service_test.dart`:
    개인 일정 삭제가 body 없는 정확한 DELETE path를 사용하고 성공 응답 ID와
    `EVENT_NOT_FOUND` 구조화 오류를 보존하는지 검증한다.
  - `test/features/calendar/application/calendar_range_notifier_test.dart`:
    생성·근무 저장·삭제 mutation과 다일 개인 일정 삭제 시 모든 날짜 캐시 제거를 검증한다.
  - `test/features/calendar/presentation/pages/calendar_page_test.dart`:
    개인 일정 스와이프 삭제의 `200` 즉시 제거, `404` 제거·안내, `500` 항목 유지·재시도를
    메인 캘린더 위젯에서 검증한다.
  - `_docs/SHIFT_TYPE_COLOR_METADATA_API_GUIDE.md`: 근무 타입 색상 설정의 기준 색상과
    농도를 재진입 시 복원하기 위한 API 계약, Express 변경 지점, PostgreSQL
    expand/backfill/enforce migration, 배포·검증·롤백 순서를 정리한 구현 전 계획 문서다.
    현재 서버 저장소의 모델·route·controller·service와 migration 운영 규칙에 의존하며,
    서버·Flutter 구현 및 실제 DB 적용 전 계약 검토에 사용한다.
  - `test/features/calendar/data/models/event_api_model_test.dart`: 일정 날짜별 매핑의 자정
    배타적 종료 처리와 일정 ID 중복 제거·시작 시각 정렬을 검증한다.

### 친구 추가 검색 흐름

최신 UI 배치는 ADR-0077, 높이/제스처 정책은 ADR-0079(2026-11-13)이다. 사용자가 명확히 한 요구는 이메일/전화번호 유일성·정확 일치·계정 단일 반환이며, ADR-0076의 큰 도입/검색 결과 제목·카드·검색/요청 버튼 병렬 표시·비율 기반 높이·접이식 공유 안내를 아래 구성으로 대체한다.

```
FriendListPage → AddFriendModal
  입력 → [친구 찾기] → SearchUserNotifier → FriendService
  → GET /api/v1/users/search?query=... → 정확히 일치하는 data.user 한 명
  → 중앙 프로필 확인 → [친구 요청 보내기] → FriendRequestsNotifier
  → POST /api/v1/friend-requests → 기존 보낸 요청 목록 갱신
  → 같은 프로필/수락 대기 상태 → [완료] → 시트 닫기
입력 수정/지우기 → 이전 프로필/오류 제거 → [친구 찾기]
받은 요청 → [받은 요청 확인] → Navigator.pop(true)
  → 호출부가 기존 AppTabNavigation.selectTab(2)
  → 탭 컨테이너가 없으면 독립 NotificationPage push
```

- 크기/색상: 흰 surface 배경 #FFFFFF에 연한 회색 입력 #F2F4F6·기존 primary #0061A4/Cafe24 폰트를 사용한다. 상단 반경24px·최대 폭560px·좌우24px·본문 위24px/아래24px+안전영역이다. 입력 라벨14px·입력16px/최소52px/반경12px, 제목20px·닫기44x44/핸들36x5를 사용한다. 헤더와 본문은 같은 흰색이며 도입 문구/검색 결과 제목/결과 카드 외곽/공유 안내를 추가하지 않는다.
- 높이/스크롤: 기본은 mainAxisSize.min Column+Flexible(fit:loose)/SingleChildScrollView의 실제 내용 높이다. 최대 상태는 개인 일정 추가와 같은 `keyboard>0 ? max_height : min(screen_height*0.88,max_height)`이며 `max_height=screen_height-viewPadding.top-keyboard_height-12`를0~화면 높이로 제한한다. 기본 높이도 이 상한 안에서 스크롤하고 최대는 tight Flexible로 남은 본문 공간을 채운다. 작은 화면/키보드/큰 글자에서도 동일한 본문 스크롤을 사용한다.
- 단계/제스처: bool _is_expanded만 높이 선택으로 저장하고 임의 drag height는 저장하지 않는다. 헤더 드래그 중 크기를 바꾸지 않고 아래 translation만 최대180px까지 따라간다. 놓을 때 위48px 이상은 최대, 최대에서 아래48px 이상은 거리와 관계없이 기본으로 접는다. 기본 상태에서 시작한 아래120px 이상 제스처만 닫는다. 더 짧으면 기존 단계를 유지하고 속도만으로 닫지 않는다. 입력/검색/요청 완료·키보드 전환은 선택한 높이 단계를 유지한다.
- 높이/위치 전환: 일반 상태의 AnimatedSize는 드래그 전후 같은 요소를 유지하고260ms/easeOutCubic으로 보간한다. 드래그 중 이 위젯을 제거하면 종료 때 새 RenderAnimatedSize가 최종 크기에서 첫 레이아웃을 수행해 확대가 순간 전환되는 것을 실제 프레임 테스트로 재현했다. 배경/라운드 클리핑은 AnimatedSize 바깥의 add-friend-visible-surface에 두고 topCenter 정렬로 헤더가 움직이는 상단에 계속 붙도록 한다. translation은 드래그 중 즉시 반영하고 종료 때260ms로 복귀한다.
- 키보드/동작 줄이기/취소: AnimatedSize의 ValueKey는 viewInsets.bottom이며 IME 값이 바뀌는 프레임은 새 애니메이션 요소의 첫 배치로 즉시 반영한다. 같은 inset 안의 사용자 단계 전환은 정상 보간한다. 동작 줄이기는 AnimatedSize 자체를 우회한다. Duration.zero RenderAnimatedSize 재진입 회귀를 피하는 정책을 유지하며, 기존 GlobalKey를 KeyedSubtree에 두어 애니메이션 경계 변경에도 controller/포커스/스크롤 subtree를 보존한다. Listener.onPointerCancel과 onVerticalDragCancel은 거리/translation/플래그를 초기화하고 비활성 onEnd를 무시한다.
- 프로필/버튼: 사진64px·이름20px·이메일14px를 카드 없이 중앙 세로 배치하고 긴 값은 줄바꿈한다. 프로필 위24px·사진 뒤12px·이름 뒤4px를 둔다. 주요 버튼은 항상 정확히 하나이며 최소52px/글자16px/반경12px·primary 색이다. 계정 확인 전에는 친구 찾기(통신 실패는 같은 버튼의 다시 시도), 계정 확인 후에는 친구 요청, 이미 친구/보낸 요청/방향 불명 대기는 완료, 명시적인 받은 요청은 받은 요청 확인으로 바뀐다. 가입 정보 입력/수락 대기 절차의 일반 설명은 표시하지 않으며 오류·이미 친구·요청 대기 같은 실제 상태만 표시한다.
- 검색/오류: 입력 수정/지우기는 검색 상태와 입력/요청 오류를 즉시 초기화한다. 기존 이메일/국내 전화번호/+82 검증과 하이픈 정규화를 유지하며 부분 검색·자동 완성/추천/목록은 제공하지 않는다. 유효하지 않은 값은 API 호출 없이 필드 아래 오류로 안내한다. USER_NOT_FOUND와 통신 실패도 필드 아래에서 구분한다. 검색 중 주요 버튼 안에 진행 표시와 비활성화를 적용하고 입력 수정 후 새 검색은 가능하다. 검색 generation으로 역순/초기화 이전/해제 뒤의 응답을 버리는 앞선 보호를 유지한다. 키보드 검색도 같은 계정 확인을 실행하되 이미 확인한 계정에서 다시 누르더라도 요청을 자동 전송하지 않는다.
- 요청/수명: 요청 중 입력/지우기/중복 전송을 막고 닫기는 제공한다. 응답 뒤 mounted를 먼저 확인한다. 실패 시 프로필/입력을 보존하고 오류와 같은 요청 버튼으로 재시도한다. 성공 시 프로필/수락 대기 상태와 완료 버튼을 표시하고 완료로 닫는다. 같은 시트에서 보낸 사용자 ID Set과 기존 비-autoDispose domain provider 정책을 유지한다. controller/FocusNode는 dispose한다. 실제 친구 수락/공유 ACL/레벨/기본 설정은 바꾸지 않는다.
- 파일 역할/의존성/사용 예(모두 기존 파일): add_friend_modal.dart는 Cupertino/Riverpod/AppTheme/ProfileImage 및 기존 검색·요청 provider에 의존하는 폼이다. `showCupertinoModalPopup<bool>(builder: (_) => const AddFriendModal())`로 열고 기존 friend_list_page.dart가 true 결과를 받은 요청 확인으로 연결한다. 기존 add_friend_modal_test.dart가 API 모의 service·입력·단일 행동 전환·오류/요청·높이 단계/취소·키보드·실제 폰트 렌더를 검증한다. 테스트는 기존 PersonalEventFormModal과 intl 한국어 날짜 초기화에 의존해5개 화면/키보드/상단 안전영역 조건에서 실제 최대 높이 일치를 비교한다. _buildTestApp은 CupertinoApp.builder에서 Navigator와 popup 전체에 같은 MediaQuery/캡처 경계를 적용하고 테스트 scaffold의 resizeToAvoidBottomInset=false로 모달이 실제 popup처럼 키보드 inset을 직접 받게 한다. 드래그 도중 pump한 뒤 종료 직후/80ms/완료의 실제 표면 높이·헤더 상단·하단을 검증한다. 이번 수정은 모달/해당 테스트만 바꾸며 기존 route/접근권한·탭 호출부·analytics/logging·API/DTO/Entity·DB/env·패키지는 변경하지 않는다.
- 렌더 사용 예: `ADD_FRIEND_RENDER_OUTPUT=/private/tmp/shiftmate_friend_motion_2026-11-13/render flutter test --no-pub test/features/friend/presentation/widgets/add_friend_modal_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`. 기존 테스트의 선택적 캡처가 dart:io/dart:ui·RepaintBoundary/FontLoader로 확대 전/종료 직후/중간/완료 프레임과 초기/확인/완료/최대 단계·작은 화면/가로/태블릿/큰 글자/키보드/어두운 OS 선호 PNG를 지정 경로에 생성한다. 새 저장소 파일/스크립트·의존성은 없다.
- 검증/롤백: 최종 결과와 실행 조건은 WORKLOG를 따른다. 모의 API/위젯 렌더 범위이며 실기기/VoiceOver·운영 API 인수는 별도다. 이번 모달/관련 테스트·ADR-0079/문서 변경만 되돌리고 기존 미커밋 변경과 앞선 검색 최신성·알림 이동을 보존한다.

### 친구 캘린더 조회 흐름

```
FriendListPage
  → FriendCalendarPage
  → FriendService.getFriendCalendarRange()
  → GET /api/v1/friends/:friend_user_id/calendar/range
  → API Server
  → v_visible_work_shifts_for_friend / v_visible_events_for_friend
```

- 친구 목록 항목 선택 시 기존 `FriendDetailPage`가 아니라 `FriendCalendarPage`로 진입한다.
- `FriendCalendarPage` 오른쪽 설정 버튼은 기존 `FriendDetailPage`로 이동한다.
- `FriendCalendarPage` 상단은 내비게이션 바의 친구 이름만 유지하고 동일한 이름/이메일 프로필 행을
  반복하지 않는다. 월 이동 헤더는 달력 바로 위에 배치하며 좌우 버튼·수평 스와이프와 함께
  연/월 제목을 눌러 공용 `YearMonthPickerSheet`로 직접 이동할 수 있다. 헤더 오른쪽의 `오늘`
  버튼은 포커스 월과 선택일을 현재 날짜로 함께 이동하고 해당 월 데이터를 조회한다. 달력의
  가로 PageView가 생성하는 시작/갱신 스크롤 알림은 달력 경계에서 소비해 상위
  `CupertinoNavigationBar`가 빌드 중 상태를 변경하지 않게 하며, `onPageChanged` 상태 반영은
  다음 프레임에서 처리한다.
- 친구 달력은 메인 달력과 같은 화면 높이 규칙을 사용해 750px 미만에서는 2주 보기와 52px 행으로
  고정하고, 750px 이상에서는 월 보기와 56px 행을 사용한다. 근무 코드 배지, 8% primary tint 배경과
  2px primary dark outline 선택 사각형, 오늘 밑줄을 사용하며 일요일은 accent red, 토요일은
  primary blue로 표시한다. `KoreanHolidays` 공용 캐시의 공휴일도 accent red로 표시하고 선택일
  카드 날짜 오른쪽에 공휴일명을 표시하며, 선택 후에도 해당 날짜 의미 색상을 유지한다. 달력 내부에는
  `CalendarStyle.tablePadding`으로 8px 하단 여유를 두어 `PageView`가 마지막 행의 4px offset 선택
  사각형까지 포함하도록 한다. 일정 카드 앞에는 별도 8px 간격을 두어 달력 표 본문부터 카드까지
  총 16px을 확보한다.
- 선택일 일정 카드는 메인 캘린더와 같은 날짜 헤더, 일정 수, 근무/개인 일정 항목, 빈 상태 표현을
  사용한다. 친구 일정은 읽기 전용이므로 일정 추가와 스와이프 삭제 액션은 제공하지 않는다.
  카드 아래에는 시스템 하단 안전영역과 최소 16px 여백을 적용해 화면 바닥 및 홈 인디케이터와
  맞닿지 않게 한다.
- `FriendDetailPage`는 완료 결과를 `FriendDetailResult.saved`와
  `FriendDetailResult.deleted`로 구분해 `FriendCalendarPage`에 반환한다. 삭제 성공이면
  `FriendCalendarPage`가 자기 자신을 닫아 친구 리스트로 복귀한다.
- `FriendDetailPage`의 친구 레벨/캘린더 공유 토글은 화면 안에서 먼저 변경하고, 상단 `저장`을
  눌렀을 때 기존 `PUT /api/v1/friends/:friend_user_id/settings` API로 `friend_level`과
  `can_view`를 함께 저장한다. 저장에 성공하면 이전 친구 캘린더 화면으로 자동 복귀하며,
  `FriendCalendarPage`는 `GET /api/v1/friends`로 친구 목록을 새로고침한 뒤 같은 `user_id`의
  최신 `FriendModel`을 현재 화면에 반영한다. 따라서 설정 화면 재진입 시 최신 레벨과 공유값을
  사용한다. 실패하면 상세 화면을 유지하고 오류 다이얼로그를 표시한다. 저장 전 뒤로가기는
  변경값을 폐기하며 새로고침하지 않는다.
- 친구 설정 화면은 컴팩트 레이아웃을 기본으로 하며, 프로필 사진 위 편집 아이콘은 표시하지 않는다.
  친구 레벨은 개인 일정 추가 모달의 공개 레벨 선택과 같은 0~5 탭/드래그 트랙으로 조정한다.
- 친구 캘린더 응답은 기존 `CalendarRangeResponse` 형식(`work_shifts`, `events`)을 재사용한다.
- 공개 판단은 서버 책임이다. 서버는 `friend_level_settings.owner_user_id = friend_user_id`,
  `friend_level_settings.friend_user_id = viewer_user_id`, `can_view=true`,
  `friend_level >= events.visibility_level` 조건을 적용한 결과만 반환한다.
- 친구 근무표 색상/이름/시간은 현재 사용자 템플릿 Provider가 아니라
  `WorkShiftApiModel` 응답 필드를 직접 사용한다.
- 파일 역할/의존성/사용 예:
  - `lib/features/friend/presentation/pages/friend_calendar_page.dart`: 친구 이름과 설정 진입,
    화면 높이별 2주/월 읽기 전용 달력 및 선택일 일정 카드를 표시한다.
    `friendCalendarRangeProvider(friend_user_id)`가 `FriendService`의 서버 공개 필터링 결과를
    공용 range state로 관리하고 화면은 `WorkShiftApiModel`/`EventApiModel`을
    `CalendarDayPresentation`으로 변환한다. 공용 `CalendarViewport`, `CalendarMonthView`,
    `CalendarScheduleCard`, `YearMonthPickerSheet`를 사용한다. 메인과 동일한 이벤트 날짜 매핑을
    사용하므로 종일 일정의 배타적 종료일을 중복 표시하지 않는다. 진입·월 이동·오늘 복귀 때
    `KoreanHolidays`의 월별 공용 캐시를 요청해 메인과 같은 공휴일 색상과 이름을 표시한다.
    설정 저장 결과를 받으면 `friendListProvider`의 친구 목록을 서버에서 다시 조회하고 현재
    `user_id`의 로컬 친구 모델을 교체한다.
  - `lib/features/friend/presentation/pages/friend_detail_page.dart`: 친구별 `friend_level`과
    `can_view`를 편집하고 `friendListProvider`를 통해 저장한다. 저장 성공 시 이전 화면으로
    `FriendDetailResult.saved`를 반환하고, 삭제 성공 시 `deleted`를 반환한다. 실패 시 현재
    입력값을 유지한 채 오류를 표시한다.
  - `test/features/friend/presentation/pages/friend_detail_page_test.dart`: 가짜 `FriendService`로
    캘린더 공유 설정 저장 요청값, 성공 후 이전 화면 복귀와 `saved` 결과 반환을 검증한다.
  - `test/features/friend/presentation/pages/friend_calendar_page_test.dart`: 가짜 `FriendService`로
    명시적 `MediaQuery` 높이 740px에서 2주 보기 고정, 750px에서 월 보기 유지 여부를 검증한다.
    390x800 월 보기에서는 중복 프로필 제거, 선택된 토요일/일요일·공휴일의 의미 색상과 공휴일명,
    8% primary tint 배경·2px
    primary dark outline 사각형 선택 표시, 근무 시간 포맷,
    마지막 행 선택 사각형이 달력 경계 안에 포함되는지, 달력과 선택일 일정 카드 사이 및 카드 하단의
    최소 16px 여백, 3개월 뒤에서 오늘로 복귀할 때 빌드 중 setState 예외가 없는지와 연/월 이동
    시트 노출을 검증한다. 설정 저장 후 친구 목록 GET을 다시 호출하고 서버 응답의 최신 `can_view`로
    설정 화면에 재진입하는지도 검증한다.

### 친구·그룹 상단 세그먼트, 실제 그룹 API와 미리보기 fallback

```
MainTabPage 친구 탭 → FriendListPage 상단 세그먼트
  → 친구 | 그룹 목록
  → GROUP_API_ENABLED=true: GroupRoomListView → GroupCalendarPage
  → GROUP_API_ENABLED=false: `우리 병동` 카드 → GroupCalendarPreviewPage
```

- 친구 탭은 상단 `CupertinoSlidingSegmentedControl` 또는 본문 좌우 스와이프로 친구/그룹을 전환한다. 하단은 공통 세 탭을 유지한다.
- 두 목록은 PageView와 파일 내부 keep-alive 래퍼로 상태·스크롤 위치를 보존하고 그룹 목록은 처음 선택할 때 생성한다(ADR-0061).
  그룹 선택 시 제목은 `그룹 방`, 친구 추가 액션은 숨기고 미리보기 또는 실제 목록을 표시한다.
- 그룹 생성은 root 전체 화면에서 저장 후 group_id를 반환한다. 친구 탭은 목록 갱신 후 내부 Navigator로 새 그룹을 연다.
  그룹 수정·초대도 root 폼에서 처리하고 완료 시 기존 탐색 화면으로 복귀한다.
- 실제 그룹 API는 기본 비활성 rollout gate 뒤에 구현되어 있다. `GROUP_API_ENABLED=true`면
  그룹 목록·생성·상세·캘린더·초대·그룹 알림을 사용하고, false면 기존 Flutter 전용 미리보기를
  표시한다. `GROUP_P1_ENABLED=true`는 Stage P1 확인 후에만 수정·멤버 관리·탈퇴·소유권·삭제
  액션을 추가 노출한다. 두 플래그 기본값은 빌드 모드와 관계없이 false다.
- 실제 그룹 화면은 서버가 기존 `friend_level_settings`로 필터링한 row만 표시한다.
  `SELF`/`VISIBLE`은 받은 row를 보여주고 `DENIED` 멤버는 목록에 남기되 `캘린더 공개 안 함`으로
  표시한다. 숨겨진 근무·일정이나 개수는 추정하지 않으며 `DENIED`를 `근무 없음`으로 표시하지 않는다.
- 그룹 event의 UTC `start_at`/`end_at`은 `timezone` package로 응답 `group.timezone`에 변환한다.
  `work_date`는 timezone 변환 없이 날짜 그대로 사용하고, 현지 자정의 배타적 종료일은 전날까지만
  날짜 맵에 포함한다.
- 구성원은 박현서·김민수·이지연·이동욱 4명으로 고정한다. 날짜를 기준으로 결정적으로 생성한
  데이터가 4명→3명→2명→1명→0명 근무를 5일 주기로 반복하고, 하루 전체 개인 일정은 2개와
  3개를 번갈아 구성원에게 분배한다. 근무자는 `D`·`E`·`N`·`F` 코드와 근무 시간을,
  비근무자는 `OFF`와 `근무 없음`을 표시한다.
- 그룹 보기 main 영역은 `../design/group_view ver2/DESIGN.md`, `code.html`, `screen.png`의
  정보 계층을 참고하되 기존 ShiftMate의 Shift Harmony 컴포넌트 규칙을 우선한다. 내비게이션은
  그룹명 `우리 병동`과 primary tint의 `4명` 요약만 표시해 중복된 별도 멤버 섹션을 제거한다.
  월 헤더는 메인·친구 캘린더의 공용 `CalendarMonthHeader`를 재사용하고 연/월 선택,
  이전·다음 이동과 `오늘` 액션을 같은 위치·타이포·surface 규칙으로 제공한다.
- 월/2주 캘린더는 둥근 외곽 카드와 셀 구분선, 별도 흰색 surface 없이
  `AppTheme.background_color` 페이지 배경에 직접 표시해 메인·친구 캘린더와 같은 바탕을 사용한다.
  날짜별 `N명 근무` 문구 대신 실제 근무자의 근무색 5px 점을 최대 4개 표시해 7열에서도
  구성원의 근무 분포를 빠르게 비교한다. 선택일은 앱 공통 8% primary tint와 2px primary dark
  outline 사각형, 오늘은 공통 primary 밑줄을 사용한다. 선택된 토요일은 primary blue,
  선택된 일요일은 accent red를 유지한다. HTML 시안에서 설명을 위해 생략한 주차는 실제 Flutter
  달력에서는 생략하지 않는다.
- 날짜 선택 시 캘린더와 8px 간격을 두고, 좌우 16px 여백·16px 반경·얇은 outline을 사용한
  독립된 흰색 surface 영역에 날짜, 공용 `CalendarScheduleSummaryChip`을 사용한
  `근무 N명`·`일정 N개` 요약 pill 및
  4명의 근무/개인 일정 목록을 함께 표시한다. 헤더와 스크롤 목록 사이는 0.5px 선으로 구분하고,
  카드 하단은 시스템 안전영역과 최소 16px 떨어뜨린다. 각 사람 카드는 흰색 surface,
  16px radius와 outline, 4px 근무색 왼쪽 바를 사용한다. 원형 아바타는 멤버 고유색으로
  사람을 구분하고 근무색 점·solid 근무 코드 배지는 당일 근무 타입을 구분한다. 본문은
  이름 → `데이 · 07:00–15:00` 또는 `휴무 · 근무 없음` → 개인 일정 chip 순서로 배치하고,
  개인 일정이 여러 개면 해당 행만 가로 스크롤한다. 연/월 제목은 공용
  `YearMonthPickerSheet`를 열며, 화면 높이 750px 미만에서는 2주 보기와 52px 행,
  그 이상에서는 월 보기와 56px 행을 사용한다.
- 파일 역할/의존성/사용 예:
  - `lib/features/friend/presentation/pages/friend_list_page.dart`: `friendListProvider` 기반 기존
    친구 목록과 그룹 방 목록을 페이지 내부 상태·PageController/상단 세그먼트로 전환한다.
    좌우 스와이프를 지원하며 목록은 keep-alive로 보존한다. 그룹 API 플래그가 켜지면 실제 목록·받은 초대·생성
    진입을 제공하고, 꺼지면 `우리 병동` 카드를 눌러 `GroupCalendarPreviewPage`를 연다.
  - `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`: 고정 구성원,
    결정적 날짜별 더미 데이터 생성기, 0~4명의 근무색 점 캘린더와 선택일 구성원 상세를 한
    파일에서 제공한다. 더미 날짜 데이터를 `CalendarDotsIndicator`로 변환해 공용
    `CalendarViewport`·`CalendarMonthView`와 `YearMonthPickerSheet`에 의존하며
    달력은 페이지 배경에 직접 배치하고 선택일 헤더·구성원 목록만 공용 카드 토큰으로 영역화한다.
    `GROUP_API_ENABLED=false`일 때 `FriendListPage`의 그룹 방 목록 카드가 이 화면을 연다.
    실제 그룹 화면과 상태는 `features/group`에 분리하며 이 결정적 생성기는 rollout fallback과
    공용 캘린더 표시 회귀 검증용으로 유지한다.
  - `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`: 5일 근무
    인원 순환, 하루 2~3개 일정, 근무색 점의 개수·색상, 내비게이션 멤버 수, full-width
    background calendar와 무경계, 하단 선택일 surface 영역의 반경·outline·헤더 구분선·안전 여백,
    선택일 tint/outline과 주말 의미 색상, 구성원 카드의 근무색 바·16px radius·이름/근무 시간/
    개인 일정 순서, 월/2주 반응형 렌더링, 0명 날짜의 휴무 상세, 상단 세그먼트의 친구/그룹 양방향
    전환, 그룹 방 목록 카드 진입 경로와 390px 화면 오버플로 부재를 검증한다.
  - `_docs/GROUP_API_SERVER_REQUEST.md`: 더미 그룹 방을 실제 서버 데이터로 전환하기 위한 구현
    요청서다. 최종 단일 캘린더 DDL을 기준으로 `groups`·`group_members`·`group_invitations`
    migration, 그룹 생성/목록/상세/관리·초대 API, 기존 친구 ACL을 재사용하는 그룹 캘린더
    aggregate 응답, 역할별 권한·오류·트랜잭션·성능·테스트·Swagger 완료 조건을 정의한다.
    이 문서는 제안 계약이며 서버 적용 전 공개 권한, 멤버 수, timezone 정책을 확정해야 한다.
  - `_docs/group_api_guide/GROUP_FRONTEND_API_GUIDE.md`: 서버 구현 결과에서 추출한 Flutter 소비
    계약이다. endpoint별 request/response, 역할 매트릭스, `calendar_access`, 오류, 알림 상태,
    Stage 인수 조건의 기준으로 사용한다.
  - `_docs/GROUP_FRONTEND_IMPLEMENTATION_PLAN.md`: P0/P1 구현 범위, rollout 플래그, 화면/API 매핑,
    테스트와 Stage 출시 체크리스트를 관리한다.
  - `lib/features/group/domain/entities/group_models.dart`: 그룹·멤버·초대·캘린더 aggregate entity와
    `OWNER/ADMIN/MEMBER`, `SELF/VISIBLE/DENIED`, 초대 상태의 안전한 unknown 파싱을 제공한다.
  - `lib/features/group/domain/repositories/group_repository.dart`,
    `lib/features/group/data/datasources/group_remote_datasource.dart`,
    `lib/features/group/data/repositories/group_repository_impl.dart`: 화면과 Dio를 분리하는 그룹
    Repository 계약, P0/P1 HTTP 호출, wrapper 파싱을 담당한다. 근무색과 `owner_user_id`, UTC
    timestamp를 손실 없이 domain entity로 변환한다.
  - `lib/features/group/application/group_providers.dart`: 그룹 목록·상세, 받은/보낸 초대와 행 단위
    요청 상태를 관리한다. 목록은 page 1 교체/다음 page ID 병합, 수락은 그룹 목록 갱신,
    관리 mutation은 상세 재조회를 사용한다.
  - `lib/features/group/application/group_calendar_range_state.dart`,
    `group_calendar_range_notifier.dart`, `group_calendar_provider.dart`: 그룹 전용 멀티 소유자
    캘린더 상태와 3개월 범위 로더다. 월별 loaded/loading/in-flight, 그룹 timezone 이벤트 날짜 맵,
    날짜별 근무·일정과 멤버 순서를 보존한다.
  - `lib/features/group/presentation/widgets/group_room_list_view.dart`: `GroupSummary`만 사용해 그룹명,
    멤버 수, 내 역할과 최대 4명 아바타를 표시하고 목록 새로고침·페이지네이션을 제공한다.
  - `lib/features/group/presentation/pages/group_create_page.dart`, `group_invite_page.dart`,
    `received_group_invitations_page.dart`: 그룹 생성, 기존 친구 bulk 초대, 받은 초대 수락/거절을
    담당한다. 활성 멤버 20명과 메시지 200자 제한, 초대 행별 처리 상태를 UI에서 선검증한다.
  - `lib/features/group/presentation/pages/group_calendar_page.dart`: 공용 캘린더 표시 계약 위에 실제
    그룹 aggregate를 렌더링한다. 날짜별 근무색 점은 시작·종료 시간이 모두 있는 근무만 최대 4개로
    표시하며 `시간 없음` 근무는 인원 집계와 선택일 상세에는 남기되 점은 그리지 않는다. 공개된 row
    집계, 멤버별 근무·일정과 DENIED 잠금 상태를 표시한다. 공개 멤버에게 근무 객체가 없으면
    `근무 없음` 문구나 근무 행을 만들지 않고 이름과 개인 일정만 표시한다. `GROUP_NOT_FOUND`면 일반
    문구로 목록에 복귀한다.
  - `lib/features/group/presentation/pages/group_management_page.dart`, `group_edit_page.dart`: 역할별
    관리 UI다. P0 초대 진입은 OWNER/ADMIN에게 제공하고, P1 플래그가 켜질 때 수정·초대 취소·
    멤버 제거/역할·소유권·탈퇴·삭제를 서버 권한표와 같은 조건으로 노출한다. 보낸 초대 목록은
    OWNER/ADMIN 화면이 Provider를 구독한 뒤에만 조회하며, MEMBER는 관리자 전용 endpoint를 호출하지
    않는다. outgoing invitation의 비동기 결과는 notifier가 dispose된 뒤 상태에 반영하지 않는다.
  - `lib/features/friend/data/models/notification_model.dart`,
    `presentation/providers/notification_provider.dart`, `presentation/pages/notification_page.dart`:
    그룹 알림 payload/status를 보존하고 PENDING+accept/reject와 받은 초대 API 결과가 모두 유효할
    때만 액션을 노출한다. 그룹 초대는 친구 요청 API와 분리해 응답하고 수락 시 그룹 목록을 갱신한다.
  - `lib/core/network/api_client.dart`: 여러 요청이 동시에 401을 받아도 단일 refresh Future를
    공유한다. 공개 refresh endpoint의 401은 재귀 갱신하지 않고, 원 요청은 새 토큰으로 한 번만
    재시도하며 두 번째 401이면 토큰을 정리한다.
  - `test/features/group/**`,
    `test/features/friend/data/models/group_notification_model_test.dart`,
    `test/features/friend/presentation/providers/group_notification_provider_test.dart`: 그룹 응답 파싱,
    unknown enum, 3개월/중복 월 요청, timezone·배타 종료일, DENIED UI, 그룹 알림 조건과 친구/그룹
    API 분리를 검증한다.

### 친구 요청 알림 응답 흐름

```
NotificationPage
  → NotificationNotifier.handleNotificationAction()
  → 원본 FRIEND_REQUEST 알림을 처리 완료 알림으로 즉시 교체
  → FriendService.respondToRequest()
  → PUT /api/v1/friend-requests/:request_id/respond
  → 응답 data.notification으로 알림 카드 최종 교체
```

- 친구 요청 알림의 수락/거절 버튼을 누르면 프론트는 서버 응답을 기다리기 전에
  기존 알림 카드를 `FRIEND_REQUEST_ACCEPTED` 또는 `FRIEND_REQUEST_REJECTED`
  상태로 낙관적 교체한다.
- 낙관적 알림은 `actions=[]`, `is_read=true`, `read_at/responded_at=현재 시각`,
  `payload.request_status=ACCEPTED|REJECTED`를 사용해 버튼이 즉시 사라지도록 한다.
- 서버 성공 응답에 `data.notification`이 있으면 그 객체로 같은 알림 카드를 다시 교체한다.
  서버가 이전 계약처럼 `notification`을 반환하지 않으면 `responded_at` 기준으로 만든
  낙관적 완료 알림을 유지한다.
- 수락 액션이 성공하면 `NotificationPage`는 친구 목록을 다시 조회한 뒤
  `payload.related_user_id`와 일치하는 친구를 찾아 친구 탭의 친구 목록→`FriendCalendarPage` 경로로 이동한다(ADR-0067).
  거절 액션은 알림 상태만 갱신하고 화면 이동하지 않는다.
- 응답 처리 중 또는 처리 직후 알림 목록 재조회가 실행되어 서버 목록에 완료 알림이 빠져 있어도,
  프론트는 같은 `notification_id` 또는 `payload.request_id`의 로컬 처리 완료 알림을 병합해
  현재 화면에서 카드가 사라지지 않게 한다.
- 서버 실패 시에는 교체 전 원본 알림 목록으로 롤백하고 기존 에러 다이얼로그 흐름을 사용한다.
- 알림 타입 파서는 서버 신규 타입 `FRIEND_REQUEST_ACCEPTED`/`FRIEND_REQUEST_REJECTED`와
  기존 타입 `FRIEND_ACCEPTED`/`FRIEND_REJECTED`를 모두 수용한다.
- 알림 목록은 `SafeArea(bottom: false)`와 목록 끝 footer 여백을 함께 사용해 마지막 카드가
  홈 인디케이터/화면 끝에서 잘린 것처럼 보이지 않게 한다. 추가 페이지가 남아 있거나 로딩 중이면
  footer 문구 대신 하단 여백만 표시하고, 마지막 페이지에서만 완료 문구를 표시한다.

### 푸시 수신 파일과 상태 규칙

- `lib/core/push/firebase_environment_options.dart`: Debug Stage/Profile·Release Production 옵션 선택
- `lib/core/push/installation_id_service.dart`: secure storage 설치 UUID 생성·검증·재사용
- `lib/core/push/device_remote_datasource.dart`: 인증 기기 API와 safe response parsing
- `lib/core/push/push_coordinator.dart`: 권한, APNs/FCM token, lifecycle, local banner, persistent dedupe
- `lib/core/push/push_providers.dart`: Riverpod coordinator와 pending navigation 상태
- 푸시의 보류 여부는 `pendingPushNotificationNavigationProvider`, 현재 탭/탐색 이력은 MainTabPage가 소유하고, 서버 알림 domain state와 미읽음 개수는 기존 `notificationProvider`가 소유합니다.
- 기기 동기화의 로딩/실패 UI는 표시하지 않으며 오류는 민감값 없이 runtime type만 debug log에 남깁니다.
- Android 최소 버전은 API 24입니다. `flutter_local_notifications 22.2.0`이 API 24를 선언하므로 계획의 API 23을 강제 override하지 않습니다.

### iOS 로컬 빌드 규칙

- iOS Runner, RunnerTests와 Podfile의 최소 deployment target은 15.0입니다.
- Push Notifications entitlement와 Background Modes의 `remote-notification`/`fetch`가 필요하며 APNs method swizzling은 기본 활성 상태를 유지합니다.
- VS Code의 `.vscode/launch.json`은 `lib/main.dart`와 프로젝트 루트를 명시하고,
  `.env`의 compile-time define은 앱 인자 `args`가 아니라 Flutter 도구 인자
  `toolArgs`의 `--dart-define-from-file=.env`로 전달한다.
- Xcode 전역 DerivedData 위치가 커스텀 경로여도 Flutter가 사전 조회한
  `TARGET_BUILD_DIR`과 실제 `flutter run` 산출 경로가 달라지지 않도록, VS Code 실행은
  `XCODE_XCCONFIG_FILE=.vscode/xcode_build_location.xcconfig`를 전달한다. 이 파일은
  `SYMROOT`만 프로젝트의 `build/ios`로 한정하며 Xcode 전역 설정은 변경하지 않는다.
- CLI Release 설치 시 `build/ios/iphoneos/Runner.app`이 이전 Debug 산출물로 남을 수 있다.
  2026-10-14 실행에서는 Release 빌드 성공 후 해당 경로의 Debug 엔진이 실행되었다.
  실제 AOT 산출물인 `build/ios/Release-iphoneos/Runner.app`을 확인하고
  `xcrun devicectl device install app --device <UDID> build/ios/Release-iphoneos/Runner.app`으로
  직접 설치한 뒤 `device process launch --device <UDID> com.hspark.shiftmate`로 실행했다.
- CocoaPods 의존성이 있는 iOS 앱은 Xcode에서 `ios/Runner.xcworkspace`를 연다.
  `Runner.xcodeproj`만 열면 Pods target이 빌드 그래프에 포함되지 않아
  `Framework 'Pods_Runner' not found`가 발생할 수 있다.
- Flutter CLI와 Xcode를 번갈아 사용한 뒤 같은 링크 오류가 발생하면 프로젝트 루트에서
  `flutter clean`, `flutter pub get`을 순서대로 실행하고 `ios/`에서
  `pod install --deployment`을 실행해 `Generated.xcconfig`와 Pods workspace를 다시 맞춘다.
- Debug/Profile/Release Runner 구성은 각각 동일한 이름의 Flutter xcconfig를 사용하며,
  각 파일은 해당 `Pods-Runner.<configuration>.xcconfig`, `Generated.xcconfig`,
  로컬 `Secrets.xcconfig`를 포함한다.
- Google 로그인 iOS 빌드는 `GOOGLE_IOS_CLIENT_ID`, `GOOGLE_SERVER_CLIENT_ID`를 Dart define으로,
  `GOOGLE_REVERSED_CLIENT_ID`를 xcconfig build setting으로 주입한다. `Info.plist`의 Google URL scheme은
  마지막 값을 참조하므로 로컬 `Secrets.xcconfig`와 CI secret 설정에 reversed client ID가 필요하다.
- 파일 역할/의존성/사용 예:
  - `.vscode/launch.json`: VS Code/Cursor의 Flutter Debug·Release 실행 진입점.
    Dart/Flutter 확장의 `toolArgs`로 `.env` define을 전달하고, iOS 실행 시
    `XCODE_XCCONFIG_FILE`로 프로젝트 전용 산출 경로 설정을 연결한다.
  - `.vscode/xcode_build_location.xcconfig`: VS Code에서 시작한 Xcode 빌드의
    `SYMROOT`를 `build/ios`로 고정하는 실행 전용 설정. `launch.json`의 `env`가
    이 파일을 가리키며, 전역 DerivedData가 커스텀 경로인 환경에서
    `flutter run`이 `Runner.app`을 찾지 못하는 문제를 방지한다.
  - `ios/Flutter/Profile.xcconfig`: Profile 빌드의 CocoaPods 검색 경로와 Flutter 생성 설정,
    로컬 secret 설정을 연결한다. `Runner.xcodeproj`의 Runner/Profile base configuration에서
    참조하며 `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner
    -configuration Profile ...` 실행 시 사용한다.

# 사용하는 DB Schema

아래는 **PostgreSQL 기준으로 "바로 실행 가능한 DDL"**이야.
그리고 DDL 안에 COMMENT ON ...으로 테이블/컬럼 역할 설명까지 같이 넣었어(=DB에서 바로 의미 확인 가능).

전제

- UUID 사용 (RDS Postgres에서 흔히 사용)
- 시간은 timestamptz로 UTC 저장을 권장
- Soft delete는 deleted_at 기준

/\* =========================================================
FINAL SCHEMA (PostgreSQL) — Single-calendar-per-user
요구사항 반영 요약

- 사용자 1명 = 캘린더 1개 (calendars 테이블 제거)
- 공유 = "내 캘린더를 친구에게 열람 허용" (calendar_shares 제거)
- 친구별 설정 = friend_level_settings에서 일괄 관리
  - can_view (내 캘린더 열람 허용/차단)
  - friend_level (레벨 비교로 일정 노출)
- 노출 규칙:
  - (can_view = true) AND (friend_level >= visibility_level)
  - work_shifts.visibility_level = 0 고정
- UUID 사용: pgcrypto + gen_random_uuid()
- 시간: timestamptz (UTC 저장 권장)
- Soft delete: deleted_at

※ 참고: "UTC 저장"은 컬럼 타입(timestamptz) + DB/세션 timezone 설정으로 보장 권장
========================================================= \*/

-- =========================================================
-- 0) PUBLIC SCHEMA 삭제 및 재생성
-- ⚠️ 경고: 기존 모든 데이터가 삭제됩니다!
-- =========================================================
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO public;

-- =========================================================
-- 1) Extensions
-- =========================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =========================================================
-- 2) USERS
-- =========================================================
CREATE TABLE users (
user_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
email text NOT NULL,
name text NOT NULL,
profile_image_url text,
timezone text, -- 예: 'Asia/Seoul'
kakao_id text, -- 카카오 OAuth 사용자 ID
apple_id text, -- 애플 OAuth 사용자 sub
password text, -- 패스워드 인증용 bcrypt 해시 (OAuth 사용자는 null)
created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT uq_users_email UNIQUE (email)
);

-- 카카오/애플 OAuth ID 인덱스
CREATE UNIQUE INDEX idx_users_kakao_id ON users(kakao_id) WHERE kakao_id IS NOT NULL;
CREATE UNIQUE INDEX idx_users_apple_id ON users(apple_id) WHERE apple_id IS NOT NULL;

COMMENT ON TABLE users IS '앱 사용자. 사용자 1명당 캘린더 1개(=모든 일정/근무 owner_user_id=user_id)';
COMMENT ON COLUMN users.user_id IS '사용자 PK(UUID)';
COMMENT ON COLUMN users.email IS '로그인/식별용 이메일(유니크)';
COMMENT ON COLUMN users.timezone IS '사용자 선호 타임존(렌더링용)';
COMMENT ON COLUMN users.kakao_id IS '카카오 OAuth 사용자 ID';
COMMENT ON COLUMN users.apple_id IS '애플 OAuth 사용자 sub';
COMMENT ON COLUMN users.password IS '패스워드 인증용 bcrypt 해시 (OAuth 사용자는 null)';

-- =========================================================
-- 3) FRIEND REQUESTS (요청/수락 플로우)
-- =========================================================
CREATE TABLE friend_requests (
request_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
requester_user_id uuid NOT NULL,
addressee_user_id uuid NOT NULL,
status text NOT NULL DEFAULT 'PENDING', -- PENDING | ACCEPTED | REJECTED | CANCELED
message text,
created_at timestamptz NOT NULL DEFAULT now(),
responded_at timestamptz,

CONSTRAINT fk_friend_requests_requester FOREIGN KEY (requester_user_id) REFERENCES users(user_id),
CONSTRAINT fk_friend_requests_addressee FOREIGN KEY (addressee_user_id) REFERENCES users(user_id),
CONSTRAINT ck_friend_requests_status CHECK (status IN ('PENDING', 'ACCEPTED', 'REJECTED', 'CANCELED')),
CONSTRAINT ck_friend_requests_not_self CHECK (requester_user_id <> addressee_user_id)
);

-- 같은 두 사람 사이에 "대기중(PENDING)" 요청 1개만 허용(방향 포함)
CREATE UNIQUE INDEX uq_friend_requests_pending_pair
ON friend_requests (requester_user_id, addressee_user_id)
WHERE status = 'PENDING';

-- 받은 요청함
CREATE INDEX idx_friend_requests_addressee_status
ON friend_requests (addressee_user_id, status, created_at DESC);

-- 보낸 요청함
CREATE INDEX idx_friend_requests_requester_status
ON friend_requests (requester_user_id, status, created_at DESC);

COMMENT ON TABLE friend_requests IS '친구 요청/수락. ACCEPTED 시 friendships + friend_level_settings(양방향) 자동 생성';

-- =========================================================
-- 4) FRIENDSHIPS (수락된 친구 관계, 대칭 1건)
-- - user_id_a < user_id_b 규칙으로 중복 저장 방지
-- =========================================================
CREATE TABLE friendships (
user_id_a uuid NOT NULL,
user_id_b uuid NOT NULL,
created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT pk_friendships PRIMARY KEY (user_id_a, user_id_b),
CONSTRAINT fk_friendships_a FOREIGN KEY (user_id_a) REFERENCES users(user_id),
CONSTRAINT fk_friendships_b FOREIGN KEY (user_id_b) REFERENCES users(user_id),
CONSTRAINT ck_friendships_order CHECK (user_id_a < user_id_b)
);

-- 친구 목록 조회는 양방향 모두 필요
CREATE INDEX idx_friendships_user_a ON friendships(user_id_a);
CREATE INDEX idx_friendships_user_b ON friendships(user_id_b);

COMMENT ON TABLE friendships IS '수락된 친구 관계(대칭). user_id_a < user_id_b로 1건만 저장';

-- =========================================================
-- 5) FRIEND LEVEL SETTINGS (owner -> friend 방향성)
-- - can_view: 내 캘린더 열람 허용 여부(ACL)
-- - friend_level: 레벨 기반 노출 판단값
-- =========================================================
CREATE TABLE friend_level_settings (
owner_user_id uuid NOT NULL,
friend_user_id uuid NOT NULL,

can_view boolean NOT NULL DEFAULT true, -- 내 캘린더를 이 친구에게 보여줄지
friend_level smallint NOT NULL DEFAULT 0, -- 0 이상

created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT pk_friend_level_settings PRIMARY KEY (owner_user_id, friend_user_id),
CONSTRAINT fk_fls_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
CONSTRAINT fk_fls_friend FOREIGN KEY (friend_user_id) REFERENCES users(user_id),
CONSTRAINT ck_fls_level CHECK (friend_level >= 0),
CONSTRAINT ck_fls_not_self CHECK (owner_user_id <> friend_user_id)
);

-- "내가 설정한 친구 목록" / "내 캘린더 열람 허용된 친구"
CREATE INDEX idx_fls_owner ON friend_level_settings(owner_user_id);

-- 정렬/필터(레벨 기반 노출 판단용) 최적화
CREATE INDEX idx_fls_owner_can_view_level
ON friend_level_settings(owner_user_id, can_view, friend_level DESC);

COMMENT ON TABLE friend_level_settings IS '친구별 열람 설정(ACL + 레벨). 노출 조건: can_view=true AND friend_level>=visibility_level';

-- =========================================================
-- 6) SHIFT TEMPLATES / VERSIONS / TYPES / SCHEDULES
-- - 사용자별(=owner_user_id)로 템플릿 관리
-- =========================================================
CREATE TABLE shift_templates (
template_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
owner_user_id uuid NOT NULL,

name text NOT NULL,
created_at timestamptz NOT NULL DEFAULT now(),
deleted_at timestamptz,

CONSTRAINT fk_shift_templates_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
CONSTRAINT uq_shift_templates_name UNIQUE (owner_user_id, name)
);

CREATE INDEX idx_shift_templates_owner
ON shift_templates(owner_user_id)
WHERE deleted_at IS NULL;

COMMENT ON TABLE shift_templates IS '근무 템플릿(사용자 단위). 예: 기본 3교대';

CREATE TABLE shift_template_versions (
template_version_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
template_id uuid NOT NULL,

version_no int NOT NULL,
effective_from date NOT NULL DEFAULT CURRENT_DATE, -- 사용자 timezone 기준 해석은 앱에서
created_by_user_id uuid NOT NULL,
created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT fk_shift_versions_template FOREIGN KEY (template_id) REFERENCES shift_templates(template_id),
CONSTRAINT fk_shift_versions_creator FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
CONSTRAINT uq_shift_versions_no UNIQUE (template_id, version_no),
CONSTRAINT uq_shift_versions_effective UNIQUE (template_id, effective_from),
CONSTRAINT ck_shift_versions_no CHECK (version_no > 0)
);

CREATE INDEX idx_shift_versions_template_effective
ON shift_template_versions(template_id, effective_from DESC);

COMMENT ON TABLE shift_template_versions IS '템플릿 시간표 버전 스냅샷. 설정 변경은 UPDATE가 아니라 버전 INSERT';

CREATE TABLE shift_types (
shift_type_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
template_id uuid NOT NULL,

code text NOT NULL, -- 예: 'D', 'E', 'N', 'OFF', 'VAC' 등 사용자 정의
name text NOT NULL, -- 예: '데이'
color int, -- 예: 0xFFF5A623 (앱과 동일하게 사용)
sort_order smallint,

created_at timestamptz NOT NULL DEFAULT now(),
deleted_at timestamptz,

CONSTRAINT fk_shift_types_template FOREIGN KEY (template_id) REFERENCES shift_templates(template_id)
);

CREATE INDEX idx_shift_types_template
ON shift_types(template_id)
WHERE deleted_at IS NULL;

COMMENT ON TABLE shift_types IS '근무 타입(사용자 정의). code/name/color 지원. (template_id, code) 중복 허용';

CREATE TABLE shift_type_schedules (
schedule_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
shift_type_id uuid NOT NULL,
template_version_id uuid NOT NULL,

start_time time,
end_time time,
crosses_midnight boolean NOT NULL DEFAULT false,
duration_minutes int NOT NULL DEFAULT 0,

created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT fk_shift_schedules_type FOREIGN KEY (shift_type_id) REFERENCES shift_types(shift_type_id),
CONSTRAINT fk_shift_schedules_version FOREIGN KEY (template_version_id) REFERENCES shift_template_versions(template_version_id),
CONSTRAINT uq_shift_schedules UNIQUE (template_version_id, shift_type_id),

-- 시간 있는 타입은 start/end 필수, OFF류는 null 허용
CONSTRAINT ck_shift_schedule_time_required CHECK (
(start_time IS NULL AND end_time IS NULL)
OR
(start_time IS NOT NULL AND end_time IS NOT NULL)
),
CONSTRAINT ck_shift_schedule_duration CHECK (duration_minutes >= 0)
);

CREATE INDEX idx_shift_schedules_version
ON shift_type_schedules(template_version_id);

CREATE INDEX idx_shift_schedules_type
ON shift_type_schedules(shift_type_id);

COMMENT ON TABLE shift_type_schedules IS '버전별 근무 시간표 스냅샷(시작/종료/자정넘김/시간(분))';

### 근무 타입 색상 파싱 규칙

- 이 문서에 포함된 초기 DDL 예시는 `shift_types.color int`이지만, 현재 Express 서버의
  `migrations/final_schema.sql`과 Sequelize 모델은 `color text`를 사용한다.
  실행 코드와 migration 계획은 서버의 `#AARRGGBB` text 계약을 기준으로 하며,
  구현 완료 시 이 DDL 예시와 `schema.drawio`를 실제 적용 스키마로 동기화해야 한다.
- 실제 API 응답은 정수 또는 문자열(`#AARRGGBB`, `#RRGGBB`, `0xAARRGGBB`, 10진수 문자열)로 들어올 수 있다.
- 클라이언트는 `lib/core/utils/color_parser.dart`의 `parseApiColorValue()`로 응답 색상을 정규화한다.
- `ShiftTypeApiModel`은 `base_color`를 파싱하고 없으면 최종 `color`로 fallback하며,
  `color_intensity`가 없거나 계약 범위를 벗어나면 100으로 복원한다.
- 신규 생성/색상 변경 요청은 `base_color`와 정수 `color_intensity`를 항상 함께 보내며
  최종 `color`는 서버 계산에 맡겨 생략한다. 두 메타데이터 중 하나만 있거나 농도가
  `0..100` 밖이면 직렬화 전에 차단한다. 구버전 호출부가 `color`만 전달하는 직렬화 계약은 유지한다.
- 사용 예: `ShiftTypeApiModel.color`, `WorkShiftApiModel.shiftTypeColor` 파싱 시 `parseApiColorValue()`를,
  근무 타입 생성/수정 요청의 기준 색상 직렬화 시 `formatApiColorValue()`를 공통 사용한다.
- 최종 `color`만으로는 농도 적용 전 기준 색상과 농도를 유일하게 복원할 수 없으므로
  Flutter 설정 화면은 서버의 nullable `base_color`와 `0..100` 정수 `color_intensity`를
  별도 상태로 사용한다. 세부 API·migration·호환성 정책은
  `_docs/SHIFT_TYPE_COLOR_METADATA_API_GUIDE.md`를 따른다.

-- =========================================================
-- 7) EVENTS (개인 일정)
-- - owner_user_id가 곧 "내 캘린더"의 소유자
-- =========================================================
CREATE TABLE events (
event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

owner_user_id uuid NOT NULL, -- 캘린더 소유자(사용자 1명=캘린더 1개)
created_by_user_id uuid NOT NULL, -- 생성자(사실상 owner=created_by가 일반적)

title text NOT NULL,
memo text,
place text,

all_day boolean NOT NULL DEFAULT false,
start_at timestamptz NOT NULL,
end_at timestamptz NOT NULL,

visibility_level smallint NOT NULL DEFAULT 0, -- 0 이상
created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz NOT NULL DEFAULT now(),

deleted_at timestamptz,
deleted_by_user_id uuid,

CONSTRAINT fk_events_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
CONSTRAINT fk_events_created_by FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
CONSTRAINT fk_events_deleted_by FOREIGN KEY (deleted_by_user_id) REFERENCES users(user_id),
CONSTRAINT ck_events_time CHECK (start_at < end_at),
CONSTRAINT ck_events_visibility CHECK (visibility_level >= 0)
);

-- 월/주/일 뷰 핵심 인덱스: owner + 기간 + not deleted
CREATE INDEX idx_events_owner_start_not_deleted
ON events(owner_user_id, start_at)
WHERE deleted_at IS NULL;

-- visibility_level 조건까지 자주 타면(친구 조회)
CREATE INDEX idx_events_owner_visibility_not_deleted
ON events(owner_user_id, visibility_level, start_at)
WHERE deleted_at IS NULL;

COMMENT ON TABLE events IS '개인 일정. 노출 조건: (친구 설정 can_view=true) AND (friend_level >= visibility_level)';

-- =========================================================
-- 8) WORK SHIFTS (근무표: visibility_level=0 고정)
-- =========================================================
CREATE TABLE work_shifts (
work_shift_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

owner_user_id uuid NOT NULL, -- 사용자 1명=캘린더 1개
work_date date NOT NULL, -- 사용자 timezone 기준 해석은 앱에서

schedule_id uuid NOT NULL, -- 버전 포함 스냅샷
note text,

visibility_level smallint NOT NULL DEFAULT 0, -- 항상 0
created_by_user_id uuid NOT NULL,
created_at timestamptz NOT NULL DEFAULT now(),
updated_at timestamptz NOT NULL DEFAULT now(),

deleted_at timestamptz,
deleted_by_user_id uuid,

CONSTRAINT fk_work_shifts_owner FOREIGN KEY (owner_user_id) REFERENCES users(user_id),
CONSTRAINT fk_work_shifts_schedule FOREIGN KEY (schedule_id) REFERENCES shift_type_schedules(schedule_id),
CONSTRAINT fk_work_shifts_created_by FOREIGN KEY (created_by_user_id) REFERENCES users(user_id),
CONSTRAINT fk_work_shifts_deleted_by FOREIGN KEY (deleted_by_user_id) REFERENCES users(user_id),

CONSTRAINT uq_work_shifts_one_per_day UNIQUE (owner_user_id, work_date),
CONSTRAINT ck_work_shifts_visibility_fixed CHECK (visibility_level = 0)
);

CREATE INDEX idx_work_shifts_owner_date_not_deleted
ON work_shifts(owner_user_id, work_date)
WHERE deleted_at IS NULL;

COMMENT ON TABLE work_shifts IS '근무표(날짜 기반). visibility_level=0 고정 → can_view=true인 친구는 모두 열람 가능';

-- =========================================================
-- 9) REFRESH TOKENS (JWT Refresh Token 관리)
-- - 로그아웃 및 토큰 무효화를 위한 테이블
-- =========================================================
CREATE TABLE refresh_tokens (
token_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
user_id uuid NOT NULL,
token_hash text NOT NULL, -- refresh_token의 SHA-256 해시
device_info text, -- 디바이스 정보 (선택)
expires_at timestamptz NOT NULL, -- 토큰 만료 시점
revoked_at timestamptz, -- 무효화 시점 (null이면 유효)
created_at timestamptz NOT NULL DEFAULT now(),

CONSTRAINT fk_refresh_tokens_user
FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- 사용자별 유효한 토큰 조회 최적화
CREATE INDEX idx_refresh_tokens_user
ON refresh_tokens(user_id) WHERE revoked_at IS NULL;

-- 토큰 해시로 조회 (갱신/검증 시)
CREATE UNIQUE INDEX idx_refresh_tokens_hash
ON refresh_tokens(token_hash) WHERE revoked_at IS NULL;

-- 만료된 토큰 정리용 (배치 작업)
CREATE INDEX idx_refresh_tokens_expires
ON refresh_tokens(expires_at) WHERE revoked_at IS NULL;

COMMENT ON TABLE refresh_tokens IS 'JWT Refresh Token 저장. 로그아웃 시 revoked_at 설정으로 무효화';
COMMENT ON COLUMN refresh_tokens.token_hash IS 'refresh_token의 SHA-256 해시값';
COMMENT ON COLUMN refresh_tokens.device_info IS '토큰 발급 디바이스 정보 (User-Agent 등)';
COMMENT ON COLUMN refresh_tokens.revoked_at IS '토큰 무효화 시점. null이면 유효한 토큰';

-- =========================================================
-- 10) TRIGGER: friend_requests ACCEPTED → friendships + friend_level_settings(양방향)
-- =========================================================
CREATE OR REPLACE FUNCTION fn_on_friend_request_status_change()
RETURNS TRIGGER AS $$
DECLARE
v_user_a uuid;
v_user_b uuid;
BEGIN
-- 응답 시각 자동 기록(처음 1회)
IF NEW.status IS DISTINCT FROM OLD.status
AND OLD.status = 'PENDING'
AND NEW.status IN ('ACCEPTED', 'REJECTED', 'CANCELED')
AND NEW.responded_at IS NULL THEN
NEW.responded_at := now();
END IF;

-- 수락 처리 시 자동 생성
IF NEW.status = 'ACCEPTED' AND OLD.status = 'PENDING' THEN
v_user_a := LEAST(NEW.requester_user_id, NEW.addressee_user_id);
v_user_b := GREATEST(NEW.requester_user_id, NEW.addressee_user_id);

    INSERT INTO friendships (user_id_a, user_id_b)
    VALUES (v_user_a, v_user_b)
    ON CONFLICT DO NOTHING;

    -- 양방향 기본 설정: can_view=true, friend_level=0
    INSERT INTO friend_level_settings (owner_user_id, friend_user_id, can_view, friend_level)
    VALUES
      (NEW.requester_user_id, NEW.addressee_user_id, true, 0),
      (NEW.addressee_user_id, NEW.requester_user_id, true, 0)
    ON CONFLICT (owner_user_id, friend_user_id) DO NOTHING;

END IF;

RETURN NEW;
END;

$$
LANGUAGE plpgsql;

CREATE TRIGGER trg_friend_request_status_change
BEFORE UPDATE ON friend_requests
FOR EACH ROW
EXECUTE FUNCTION fn_on_friend_request_status_change();

-- =========================================================
-- 11) VIEWS: 친구 열람용 (can_view + 레벨 비교 + friendships 존재)
-- =========================================================

-- 11-1) 친구가 볼 수 있는 events
CREATE OR REPLACE VIEW v_visible_events_for_friend AS
SELECT
  e.*,
  fls.friend_user_id AS viewer_user_id
FROM events e
JOIN friend_level_settings fls
  ON fls.owner_user_id = e.owner_user_id
 AND fls.can_view = true
WHERE e.deleted_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM friendships f
    WHERE f.user_id_a = LEAST(e.owner_user_id, fls.friend_user_id)
      AND f.user_id_b = GREATEST(e.owner_user_id, fls.friend_user_id)
  )
  AND fls.friend_level >= e.visibility_level;

-- 11-2) 친구가 볼 수 있는 work_shifts (visibility_level=0 고정)
CREATE OR REPLACE VIEW v_visible_work_shifts_for_friend AS
SELECT
  ws.*,
  fls.friend_user_id AS viewer_user_id
FROM work_shifts ws
JOIN friend_level_settings fls
  ON fls.owner_user_id = ws.owner_user_id
 AND fls.can_view = true
WHERE ws.deleted_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM friendships f
    WHERE f.user_id_a = LEAST(ws.owner_user_id, fls.friend_user_id)
      AND f.user_id_b = GREATEST(ws.owner_user_id, fls.friend_user_id)
  )
  AND fls.friend_level >= ws.visibility_level; -- 항상 0

/* =========================================================
   (OPTIONAL) 운영 권장: DB timezone을 UTC로
   ALTER DATABASE your_db_name SET timezone TO 'UTC';
   ========================================================= */
$$

## 로컬 API 디버그 실행 (2026-11-08)

- VS Code/Cursor에서 `ShiftMate (debug local)`을 선택하면 `USE_LOCAL_API=true`가 전달되어
  `http://172.30.1.93:3000/api/v1`로 연결한다. 현재 주소는 `ApiConstants.base_url_local`과 일치한다(2026-11-16 갱신). 기존 `ShiftMate (debug)`는 Stage를 유지한다.
- CLI: `flutter run --debug --dart-define-from-file=.env --dart-define=USE_LOCAL_API=true`.
- `lib/core/constants/api_constants.dart`는 Debug에서만 로컬 옵션을 적용한다.
  Profile/Release는 운영 API, Kakao/Firebase는 기존 빌드 모드별 설정을 유지한다.
  로컬 서버의 OAuth 설정은 Stage 앱 키와 일치해야 한다.
- Android Debug manifest에서 HTTP를 허용한다. iOS는 기존 ATS HTTP 허용 설정을 사용한다.
- 기기에서 해당 LAN 주소로 접근할 수 있어야 한다. 실제 기기 연결·로그인 검증은 별도다.
- 롤백: 로컬 실행 구성, API 옵션, Android Debug HTTP 허용 변경을 되돌린다.

### 프로필 이미지 표시 (2026-11-08)

- `lib/core/widgets/profile_image.dart`: 설정·가입·친구 목록/상세·검색에서 공유하는 이미지 위젯과 autoDispose byte Provider. Dio/Riverpod에 의존한다. 사용 예: `ProfileImage(image_url: url, fallback: Icon(CupertinoIcons.person_fill))`.
- 현재 API와 origin이 같고 `/api/v1/profile-images/:user_id`인 URL(서버 상대 경로 포함)만 기존 Dio로 조회한다. Bearer 첨부와 토큰 갱신을 재사용하고 인증 요청의 redirect는 따르지 않는다. 외부 OAuth 이미지는 토큰 없이 Image.network로 표시한다.
- Behavior change: 보호 이미지 GET에도 인증을 적용한다. 로딩·실패·빈 URL은 호출부 기본 아이콘을 유지한다. 구독 해제 시 요청을 취소하며 계정 전환/로그아웃에서 이미지 Provider를 무효화한다.
- `test/core/widgets/profile_image_test.dart`: secure storage 모의 토큰과 Dio adapter로 상대 URL·Bearer·redirect 차단·이미지 표시 및 빈 URL을 검증한다. 실제 서버 연결을 수행하지 않는다.
