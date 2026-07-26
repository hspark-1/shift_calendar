# 작업 로그

## 2026-07-26

- [DONE] (CHORE) 앱 브랜드·패키지 식별자를 ShiftMate로 통일
  - 목적: 로컬 개발 단계에 남아 있는 초기 프로젝트 명칭과 Android 애플리케이션 식별자를 출시 전 `ShiftMate` 기준으로 일관되게 정리한다.
  - 변경: 사용자 노출 이름을 `ShiftMate`, Dart 패키지를 `shift_mate`로 변경하고 `ShiftCalendarApp`을 `ShiftMateApp`으로 정리했다. 화면의 앱 이름은 `AppConstants.app_name` 단일 상수를 사용한다. Android 표시 이름·namespace·applicationId·Kotlin 패키지와 소스 경로를 `ShiftMate`/`com.hspark.shiftmate` 기준으로 이동했다. iOS `CFBundleDisplayName`과 `CFBundleName`을 `ShiftMate`로 변경하고 기존 `com.hspark.shiftmate` Bundle ID·OAuth 스킴은 유지했다. 전체 테스트의 Dart package import, VS Code 실행 구성, README와 현재 프로젝트 컨텍스트를 갱신하고 식별자 정책을 ADR-0014로 기록했다. 기본 Flutter counter 템플릿에 머물러 있던 루트 위젯 테스트는 실제 Riverpod 루트와 앱 제목·초기 브랜드명을 검증하도록 교체했다.
  - 영향범위: 앱 표시 이름, Flutter 내부 패키지 참조, Android 설치 식별자 및 네이버·카카오 Android 플랫폼 등록값, Kotlin MainActivity 경로, iOS 메타데이터, 개발 실행 구성, 테스트·문서. Behavior change: Android 기존 로컬 설치와 새 앱은 서로 다른 애플리케이션으로 취급되어 로컬 데이터가 자동 이전되지 않는다. 서버 API와 DB 계약, 캘린더 기능 용어는 변경하지 않는다.
  - 파일: `pubspec.yaml`, `lib/main.dart`, `lib/core/constants/app_constants.dart`, `lib/features/auth/presentation/pages/login_page.dart`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/hspark/shiftmate/MainActivity.kt`, `ios/Runner/Info.plist`, `.vscode/launch.json`, `README.md`, `test/**/*.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 롤백: 이 작업에서 변경한 앱 명칭·패키지·플랫폼 식별자와 문서를 직전 값으로 함께 복원한다.
  - 테스트: `flutter pub get` 성공 후 전체 95개 테스트가 통과했다. 최초 전체 테스트에서 발견한 기존 counter 템플릿 테스트 1건은 현재 앱 구조에 맞게 수정한 뒤 전용·전체 테스트를 모두 재통과했다. 변경 핵심 파일 대상 `flutter analyze --no-fatal-infos`는 warning/error 없이 통과했고, 프로젝트 전체 분석은 이번 변경 밖의 기존 warning/info 96건으로 종료 코드 1이며 package import 오류는 없다. Android debug APK와 iOS debug simulator 앱 빌드가 성공했다. 병합 Android manifest는 package `com.hspark.shiftmate`·label `ShiftMate`, 빌드된 iOS Info.plist는 Bundle ID `com.hspark.shiftmate`·DisplayName/BundleName `ShiftMate`, Dart package config는 `shift_mate`임을 확인했다. 소스·플랫폼 구성 legacy 명칭 검색 0건, `plutil`·`xmllint`·JSON 구문 검사와 `git diff --check`가 통과했다.
  - 다음: 네이버·카카오 개발자 콘솔의 Android 패키지명을 `com.hspark.shiftmate`로 등록하고 카카오에는 현재 빌드 서명 키 해시를 함께 등록한다. 기존 applicationId의 로컬 Android 앱이 설치되어 있으면 필요에 따라 수동 제거한 뒤 실제 기기에서 카카오·네이버 로그인을 회귀 확인한다.

- [DONE] (FE) 네이버 로그인 네이티브 SDK 전환
  - 목적: 앱 내부 WebView에서 네이버 계정을 직접 입력받는 implicit OAuth 흐름을 제거하고, 네이버 앱이 설치된 경우 네이버 앱으로 우선 연결해 소셜 로그인을 이어간다.
  - 변경: `flutter_inappwebview`·`url_launcher`와 306줄 WebView/implicit OAuth/callback fragment 파싱을 제거하고 Flutter 3.38.5 호환 `naver_login_flutter` 3.0.4를 연결했다. iOS는 네이버 앱 우선·SDK 인앱 브라우저 fallback으로 인증하며 Android도 공식 SDK 요청을 사용한다. SDK Access Token은 기존 `POST /api/v1/auth/naver/token`에 전달하고, Android 결과에 토큰이 직접 없으면 현재 SDK 토큰을 추가 조회한다. 로그인 API에서 `BuildContext` 의존성을 제거하고 로그아웃 시 네이버 SDK 세션도 정리한다. iOS `NidClientID`·`NidClientSecret`·`NidAppName`·`NidUrlScheme=com.hspark.shiftmate`, URL Scheme/앱 조회 스킴과 Android SDK meta-data/Gradle 비밀키 주입을 구성하고 기존 Android WebView callback intent-filter를 제거했다. 설계 결정은 ADR-0013에 기록했다.
  - 영향범위: 네이버 로그인 진입·콜백·토큰 조회·로그아웃, iOS/Android 네이티브 인증 설정, 인증 의존성·테스트·문서. Behavior change: 네이버 앱 설치 시 앱으로 이동하며 미설치 때만 SDK 브라우저를 사용한다. 카카오 로그인과 서버 JWT 저장/API/DB 계약은 변경하지 않는다.
  - 파일: `pubspec.yaml`, `pubspec.lock`, `ios/Podfile.lock`, `lib/core/constants/app_constants.dart`, `lib/features/auth/data/services/naver_login_service.dart`, `lib/features/auth/data/repositories/auth_repository_impl.dart`, `lib/features/auth/presentation/providers/auth_provider.dart`, `lib/features/auth/presentation/pages/login_page.dart`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`, `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Profile.xcconfig`, `ios/Flutter/Release.xcconfig`, `test/features/auth/data/datasources/auth_remote_datasource_test.dart`, `test/features/auth/data/services/naver_login_service_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 롤백: 네이티브 플러그인과 플랫폼 설정을 제거하고 기존 `NaverLoginService`의 WebView OAuth 흐름 및 관련 의존성을 복원한다.
  - 테스트: 인증 테스트 9건 통과(네이버 서비스 5건, 네이버 토큰 교환 POST 1건, 프로필 POST 1건, 로그인 화면 2건). 변경 Dart 코드·테스트 5개 파일 대상 `flutter analyze --no-fatal-infos` 0건. `plutil`·`xmllint`와 `git diff --check` 통과. Android debug APK와 iOS debug simulator 앱 네이티브 빌드 성공. 전체 `flutter analyze --no-fatal-infos`는 이번 변경 밖의 기존 warning/info를 포함해 종료 코드 1이다.
  - 다음: gitignored 로컬/CI 비밀키 파일에 `NAVER_CLIENT_ID`, `NAVER_CLIENT_SECRET`을 주입한 뒤 실제 iOS/Android 기기에서 네이버 앱 설치·미설치·사용자 취소 경로와 Stage 서버 토큰 교환을 확인한다.

- [DONE] (FIX) 프로필 저장 API 메서드를 서버 계약과 일치
  - 목적: 신규 카카오 로그인 후 프로필 저장 시 Flutter가 지원되지 않는 `PATCH /api/v1/auth/profile`을 호출해 HTML 404 오류가 표시되는 문제를 해결한다.
  - 변경: `AuthRemoteDataSource.updateProfile()`의 요청 메서드를 Express `authRoutes.ts`가 지원하는 POST로 변경했다. Dio 요청을 가로채 POST 메서드, `/auth/profile` 경로, null 필드가 제외된 본문과 응답 사용자 파싱을 검증하는 데이터소스 테스트를 추가했다. 프로젝트 컨텍스트에 카카오 Flutter SDK→Access Token→서버 토큰 교환과 신규 사용자 프로필 저장 흐름, Android/iOS 네이티브 앱 설정을 기록했다. 대상 분석에서 확인된 기존 미사용 `flutter/foundation.dart` import를 제거하고 프로젝트 `snake_case` 규칙의 lint 예외를 파일에 명시했다.
  - 영향범위: 신규 사용자 프로필 설정 및 향후 같은 데이터소스를 사용하는 프로필 수정 요청과 인증 계약 문서. Behavior change: 프로필 저장이 `PATCH`가 아니라 서버가 지원하는 `POST /api/v1/auth/profile`을 사용한다. 카카오 Flutter SDK 로그인, `kakao${KAKAO_NATIVE_APP_KEY}://oauth` 네이티브 콜백, `POST /api/v1/auth/kakao/token` 토큰 교환과 DB 구조는 변경하지 않는다.
  - 파일: `lib/features/auth/data/datasources/auth_remote_datasource.dart`, `test/features/auth/data/datasources/auth_remote_datasource_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 신규 데이터소스 테스트 1건과 기존 로그인 화면 테스트 2건 등 인증 테스트 3건 통과. 대상 `flutter analyze --no-fatal-infos` 0건, `dart format`과 `git diff --check` 통과.
  - 롤백: `updateProfile()` 요청 메서드를 PATCH로 복원하고 신규 데이터소스 테스트와 인증 계약 문서 기록을 제거한다.
  - 다음: Stage 실제 계정에서 신규 카카오 로그인 후 이름·타임존 저장이 완료되고 캘린더로 전환되는지 확인한다.

- [DONE] (FE) 친구 탭 footer로 친구 리스트·그룹 방 리스트 전환
  - 목적: 친구 리스트 탭에서 메인 화면과 같은 하단 footer를 사용해 친구 리스트와 그룹 방 리스트를 한 화면 안에서 전환해 볼 수 있게 한다.
  - 변경: 공용 `BottomActionBar`가 화면별 `BottomActionBarItem` 목록과 선택 상태를 받을 수 있게 확장했다. `FriendListPage` 하단에는 `친구 리스트`·`그룹 방` footer를 고정하고, 친구 선택 시 기존 API 목록과 친구 추가 버튼을 유지하며 그룹 선택 시 `우리 병동` 더미 방 카드·4명 겹침 아바타를 표시한다. 기존 상단 그룹 미리보기 아이콘은 제거하고 그룹 방 카드를 통해 `GroupCalendarPreviewPage`로 진입하게 했다. 선택 footer는 8% primary tint와 primary dark outline으로 구분한다. 친구 전체 테스트에서 확인된 기존 흰색 선택 배경 기대값 1건은 ADR-0012와 현재 8% primary tint 구현에 맞게 수정했다.
  - 영향범위: 친구 탭의 하단 내비게이션, 친구/그룹 방 목록 표시와 그룹 미리보기 진입 경로, 공용 footer의 화면별 항목 주입 기능, 관련 친구 위젯 테스트·문서. Behavior change: 그룹 미리보기는 내비게이션 바 아이콘이 아니라 footer의 `그룹 방` 목록 카드에서 진입한다. 친구·그룹 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/bottom_action_bar.dart`, `lib/features/friend/presentation/pages/friend_list_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/WORKLOG.md`
  - 테스트: 그룹 미리보기 전용 테스트 7건 통과. 친구 기능 전체 테스트 19건 통과. footer의 친구→그룹 방→친구 양방향 전환, 친구 추가 버튼 조건부 노출, 그룹 방 카드·아바타 표시와 그룹 캘린더 진입을 검증했다. 최초 전체 실행에서는 과거 테스트가 선택일의 흰색 배경을 기대해 1건 실패했으며, 확정 문서와 현재 구현의 8% primary tint 기대값으로 바로잡은 뒤 전체 통과했다. 변경 코드·테스트 대상 `flutter analyze --no-fatal-infos` 0건, `dart format`, `git diff --check` 통과. 전체 프로젝트 analyze는 이번 변경 파일 밖의 기존 진단 109건(미사용 import/요소, 생성 코드 중복 ignore, 프로젝트 snake_case와 Flutter lowerCamelCase lint 충돌 등)으로 종료 코드 1이며 변경 대상 파일에는 진단이 없다.
  - 롤백: `BottomActionBarItem` 주입 기능과 친구 페이지 footer·그룹 방 목록을 제거하고 기존 친구 목록 단일 화면 및 상단 그룹 아이콘 진입을 복원한 뒤 테스트 기대값과 관련 문서 기록을 되돌린다.
  - 다음: 실제 iOS/Android 기기에서 footer의 홈 인디케이터 여백, 긴 그룹명 카드 레이아웃과 선택 상태를 확인하고, 실제 그룹 API 계약이 확정되면 더미 `우리 병동` 카드 목록을 서버 데이터로 교체한다.

- [DONE] (FIX) 친구 검색 결과 카드 높이를 내부 콘텐츠 기준으로 변경
  - 목적: 검색한 사용자가 이미 친구일 때 상태 문구 아래에 남는 고정 최소 높이 여백을 제거하고, 프로필·간격·상태/액션 영역의 실제 높이에 맞춰 카드가 동적으로 결정되게 한다.
  - 변경: 검색 결과 카드의 `BoxConstraints(minHeight: ...)`를 제거해 프로필 행, 28px 간격, 친구 관계 상태 또는 요청 버튼, 20px 카드 패딩의 실제 합산 높이로 카드가 결정되게 했다. 카드 식별 키와 이미 친구인 검색 상태를 주입하는 위젯 테스트를 추가해 세로 최소 제약이 0이고 렌더 높이가 기존 고정값보다 작으며 상태 문구 아래 여백이 제한되는지 검증했다. 프로젝트 컨텍스트와 친구 기능 설계 문서에도 콘텐츠 기반 높이 및 결과 영역 스크롤 책임을 기록했다.
  - 영향범위: 친구 추가 모달의 단일 사용자 검색 결과 카드 높이와 관련 테스트·문서. Behavior change: 검색 결과 카드는 고정 최소 높이를 유지하지 않고 내부 콘텐츠 높이로 축소된다. 검색 API, 친구 상태 판정, 친구 요청 동작은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `test/features/friend/presentation/widgets/add_friend_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/WORKLOG.md`
  - 테스트: 친구 추가 모달 위젯 테스트 6건 통과. 신규 테스트의 최초 실행에서는 `width: double.infinity`가 생성한 가로 제약까지 `null`로 잘못 기대해 1건 실패했으나, 세로 `minHeight=0`·무한 `maxHeight`를 직접 검증하도록 바로잡은 뒤 통과했다. 대상 코드·테스트 `dart format`과 `flutter analyze` 0건 통과.
  - 롤백: 검색 결과 카드에 기존 고정 `BoxConstraints(minHeight: ...)`를 복원하고 카드 식별 키, 신규 테스트와 관련 문서 기록을 되돌린다.
  - 다음: 실제 iOS/Android 기기에서 이미 친구, 요청 대기, 요청 가능 세 상태의 카드 하단 여백과 큰 텍스트 설정의 스크롤을 확인한다.

## 2026-07-24

- [DONE] (CHORE) 테스트용 그룹 캘린더와 VS Code 실행 설정 커밋·푸시
  - 목적: 검증이 끝난 그룹 캘린더 미리보기와 `launch.json` 실행 복구 변경을 공유 가능한 파일 단위로 정리하고 원격 `main`에 반영한다.
  - 변경: 더미 그룹 화면·친구 목록 진입·위젯 테스트를 `fd64b41`로, Flutter 도구 인자와 iOS 산출 경로가 수정된 VS Code 실행 설정을 `962bc9c`로 분리했다. `.vscode/` 전체 ignore 정책은 유지하면서 프로젝트 공용 `launch.json`과 Xcode 산출 경로 xcconfig만 명시적으로 추적했다. 그룹·실행 규칙과 작업 결과는 후속 문서 커밋으로 정리해 함께 푸시한다.
  - 영향범위: 그룹 미리보기 화면·테스트, VS Code Flutter 실행 설정, 관련 프로젝트 문서와 Git 이력. 기존 `api_constants.dart`의 개인 LAN 주소 메모는 범위 밖 사용자 로컬 변경이므로 커밋하지 않고 작업 트리에 보존한다.
  - 파일: `.vscode/launch.json`, `.vscode/xcode_build_location.xcconfig`, `lib/features/friend/presentation/pages/friend_list_page.dart`, `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 관련 Dart 파일 3개 `dart format` 변경 0건, 대상 `flutter analyze --no-fatal-infos` 0건, 그룹 미리보기 위젯 테스트 7건, `launch.json` JSON 검증, 각 커밋의 `git diff --cached --check`를 통과했다. 직전 실행 복구 작업에서 iPhone 15 Pro Max iOS 17.4 시뮬레이터의 Xcode build·앱 실행·Dart VM Service·Flutter DevTools 연결도 확인했다.
  - 롤백: 원격 반영 후 필요 시 생성한 커밋을 `git revert`하고 푸시한다.
  - 다음: 실제 그룹 API 계약이 확정되면 더미 데이터 생성기를 application/data 계층 조회로 교체하고, 실제 iPhone의 VM Service 연결 지연은 기기 권한·연결 상태와 함께 별도로 점검한다.

- [DONE] (FIX) VS Code launch.json Flutter 앱 실행 복구
  - 목적: `.vscode/launch.json`으로 Flutter 앱을 시작할 때 실행되지 않는 원인을 재현하고, 프로젝트의 실제 엔트리포인트·환경변수·기기 구성에 맞게 수정한다.
  - 변경: Dart/Flutter 확장 3.138.0의 launch schema와 현재 구성을 대조해 `.env`의 `--dart-define-from-file`이 Flutter 도구 옵션이 아닌 `main()` 앱 인자 `args`에 들어가 있음을 확인하고 두 Debug/Release 구성 모두 `toolArgs`로 교체했다. `program=lib/main.dart`, `cwd=${workspaceFolder}`를 명시했다. 추가 재현에서 Xcode 전역 DerivedData 커스텀 경로 때문에 Flutter의 사전 `TARGET_BUILD_DIR` 조회값과 실제 `BUILD_DIR`이 달라져 빌드된 `Runner.app`을 찾지 못하는 원인을 확인했다. 전역 Xcode 설정은 변경하지 않고 launch 환경변수 `XCODE_XCCONFIG_FILE`과 신규 `.vscode/xcode_build_location.xcconfig`의 `SYMROOT=$(PROJECT_DIR)/../build/ios`로 이 프로젝트 실행만 일치시켰다.
  - 영향범위: VS Code Flutter Debug/Release 실행의 엔트리포인트, compile-time define 전달, iOS 산출물 경로와 로컬 실행 문서. Behavior change: launch 구성으로 iOS 시뮬레이터를 실행하면 앱과 Dart VM Service/DevTools가 정상 연결된다. 앱 런타임 기능, API/DB 계약과 Xcode 전역 환경은 변경하지 않는다.
  - 파일: `.vscode/launch.json`, `.vscode/xcode_build_location.xcconfig`(신규), `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: launch와 동일한 `XCODE_XCCONFIG_FILE`, `--dart-define-from-file=.env`, `lib/main.dart` 인자로 iPhone 15 Pro Max iOS 17.4 시뮬레이터 Debug 실행에 성공했다. Xcode build, 앱 동기화, Dart VM Service와 Flutter DevTools 연결을 확인한 뒤 정상 종료했다. 수정 전에는 같은 시뮬레이터에서 Xcode build 성공 후 `build/ios/iphonesimulator/Runner.app`을 찾지 못해 실패했고, 프로젝트 xcconfig 적용 후 해소됐다. `jq` JSON 검증, `flutter analyze --no-fatal-infos lib/main.dart` 0건, `git diff --check`를 통과했다. 실제 iPhone에서는 Xcode build·설치까지 성공했으나 VM Service 탐색이 60초를 넘겨 기기 연결 상태 이슈를 별도로 확인했다.
  - 롤백: `toolArgs`를 기존 `args`로 되돌리고 `program`·`cwd`·`env`, `.vscode/xcode_build_location.xcconfig`와 관련 문서 기록을 제거한다.
  - 다음: VS Code에서 이 프로젝트 폴더 자체를 workspace로 열고 상태 표시줄에서 실행할 iOS 기기 또는 시뮬레이터를 선택한 뒤 `ShiftMate (debug)`를 실행한다. 실제 iPhone의 VM Service 연결이 계속 지연되면 기기 잠금·신뢰·로컬 네트워크 및 Xcode 자동화 권한을 점검한다.

## 2026-07-23

- [DONE] (FE) 첨부 시안 기반 그룹 보기 main 디자인 재구성
  - 목적: `design/group_view`의 `DESIGN.md`, `code.html`, `screen.png`를 기준으로 더미 그룹 보기 본문을 Shift Harmony 시안과 같은 정보 계층과 카드 구조로 정리한다.
  - 변경: 기존 안내 카드와 히트맵을 제거하고 `그룹 멤버` 수·44px 겹침 아바타·추가 원, 28px 연월 제목, 이전/오늘/다음 액션, 흰색 surface/outline 셀 그리드로 본문 상단을 재구성했다. 모든 실제 월 주차와 날짜별 근무 인원은 유지하며 선택일에는 8% primary tint와 2px outline, 오늘에는 solid primary 원을 적용했다. 선택일 상세의 외곽 큰 카드를 제거하고 날짜/집계 독립 헤더 아래에 흰색 사람별 행을 배치했다. 각 행은 4px 근무색 바, tint 아바타, solid 코드 배지와 가로 스크롤 일정 영역을 사용하며 근무 시간이 첫 칩이고 개인 일정이 뒤따른다. 상단 앱 내비게이션과 친구 화면 진입 흐름은 유지했다.
  - 영향범위: 더미 그룹 캘린더 main 영역의 레이아웃·색상·간격·선택 상태와 관련 위젯 테스트·프로젝트 문서. Behavior change: 근무 인원은 붉은 히트맵이 아닌 outline 캘린더 셀의 보조 텍스트로 표시되고, 사람별 상세는 세로 정보 카드가 아닌 시안형 한 줄 카드와 가로 일정 스크롤을 사용한다. 더미 데이터의 4→0명 근무/하루 2~3개 일정, API/DB, 기존 내 캘린더·친구 캘린더는 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 그룹 미리보기 테스트 7건에서 4→0명 데이터, Shift Harmony 오렌지·핑크·인디고·outline 멤버색, 겹침 아바타·추가 원·오늘 버튼, surface/outline 캘린더 카드, 선택일 8% primary tint·2px outline, 첫 근무색 바, 근무 시간 선두 순서, 0명 휴무, 390x800 월/390x740 2주 렌더링과 친구 화면 진입을 검증해 통과했다. 대상 화면·테스트 `flutter analyze` 0건, `dart format`과 `git diff --check` 통과.
  - 롤백: 시안 기반 본문 레이아웃과 관련 테스트·문서 기록을 제거하고 직전 히트맵/상세 카드 구조로 복원한다.
  - 다음: 실제 iOS/Android 기기에서 긴 이름·긴 개인 일정의 가로 스크롤 발견 가능성과 월별 5주/6주 높이에서 보이는 사람별 카드 수를 확인한다.

- [DONE] (FE) 그룹 사람별 일정 목록에 근무 시간 우선 표시
  - 목적: 그룹 선택일의 사람별 개인 일정 목록에서 해당 구성원의 설정된 근무 시간을 개인 일정과 같은 형식으로 가장 먼저 확인할 수 있게 한다.
  - 변경: 사람별 헤더의 근무 시간 문자열을 일정 칩 목록으로 이동하고, 시계 아이콘과 근무 타입 색상을 사용한 첫 번째 칩으로 고정했다. 근무자는 `07:00–15:00 근무`, 휴무자는 달 아이콘과 `근무 없음`을 표시하며 개인 일정 `09:30 병원 예약` 등은 그 뒤에 이어진다. 개인 일정이 없는 경우에도 근무 시간 칩은 유지하고 기존 빈 일정 안내를 함께 표시한다.
  - 영향범위: 더미 그룹 캘린더 선택일의 사람별 상세 카드와 위젯 테스트·프로젝트 문서. Behavior change: 근무 시간이 이름 아래 보조 문구가 아니라 개인 일정과 같은 칩 목록의 선두 항목으로 표시된다. 더미 생성 규칙, API/DB, 기존 내 캘린더·친구 캘린더는 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 그룹 미리보기 테스트 7건에서 `Wrap.children.first`가 근무 시간 칩인지, 근무일의 `07:00–15:00 근무`가 `09:30 병원 예약`보다 먼저 구성되는지, 0명 근무일에 `근무 없음`이 표시되는지와 기존 월/2주·오버플로·진입 회귀를 검증해 통과했다. 대상 코드·테스트 `flutter analyze` 0건, `dart format` 통과.
  - 롤백: 근무 시간 선두 칩과 관련 테스트·문서 기록을 제거하고 기존 사람별 헤더 시간 표시 구조로 복원한다.
  - 다음: 실제 그룹 API를 연결할 때 `shift_type_schedules.start_time`·`end_time` 응답을 동일한 선두 근무 시간 칩에 매핑한다.

- [DONE] (FE) 더미 데이터 기반 그룹 캘린더 미리보기 화면
  - 목적: 실제 그룹 API·DB 구현 전에 4명 그룹의 날짜별 근무 인원 분포와 개인 일정 상세를 실제 기기/위젯 테스트에서 검토할 수 있는 화면을 제공한다.
  - 변경: 박현서·김민수·이지연·이동욱 4명의 고정 더미 데이터와 날짜 기반 결정적 생성기를 추가했다. 날짜마다 4→3→2→1→0명 근무를 반복하고 하루 전체 2개/3개 개인 일정을 구성원에게 분배한다. 월/2주 캘린더에는 5단계 근무 인원 히트맵과 접근성 요약을, 선택일 카드에는 사람별 `D`·`E`·`N`·`F`·`OFF` 근무/시간과 일정 칩을 표시한다. 친구 화면 상단 그룹 아이콘으로 미리보기에 진입하며 750px 미만 화면은 2주 보기로 고정한다.
  - 영향범위: Flutter 친구 화면 내 미리보기 진입과 신규 그룹 캘린더 프레젠테이션 코드·위젯 테스트. Behavior change: 친구 화면 내비게이션 바에 그룹 미리보기 버튼이 추가된다. API/DB/기존 내 캘린더·단일 친구 캘린더 동작은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`, `lib/features/friend/presentation/pages/friend_list_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 신규 테스트 6건에서 0~4명 근무 순환, 하루 2~3개 일정, 5단계 히트맵 색상, 0명 날짜 선택 상세, 390x740 2주 보기와 오버플로 부재, 친구 화면 진입을 검증해 통과했다. 대상 코드·테스트 `flutter analyze` 0건, `dart format`과 `git diff --check` 통과. 전체 `flutter analyze`는 이번 변경 밖의 기존 이슈 109건 때문에 실패하며, 기존 친구 캘린더 테스트 묶음은 과거 흰색 선택 배경 기대값 1건이 현재 8% primary tint 구현과 달라 실패하는 상태임을 확인했다.
  - 롤백: 신규 화면·테스트·친구 목록 진입 액션을 제거하고 프로젝트 컨텍스트/작업 로그 기록을 복원한다.
  - 다음: 실제 그룹 엔티티·공개 범위·API 계약이 확정되면 결정적 더미 생성기를 application/data 계층 조회 결과로 교체하고 그룹 생성·멤버 관리 흐름을 연결한다.

## 2026-07-21

- [DONE] (FE) 카카오·네이버 로그인 이미지 버튼 적용
  - 목적: `assets/icons`에 준비된 600x90 카카오·네이버 완성형 이미지를 로그인 화면에서 실제 버튼으로 사용하고, 네이버 공식 BI 핵심 규격을 회귀 테스트로 고정한다.
  - 변경: 존재하지 않는 `kakao_login_center.png`·`naver_login_center.png` 참조를 실제 `kakao_login_img.png`·`naver_login_img.png`로 교체했다. 카카오의 366x90 중앙형 이미지에 맞춘 219.6x54 전용 슬롯과 별도 배경 컨테이너를 제거하고, 두 600x90 완성형 이미지를 동일한 342x54 터치 영역에서 `BoxFit.contain`으로 표시한다. 기존 로그인 콜백, 공용 로딩 차단, 버튼 내부 로딩 표시, 접근성 레이블은 유지했다. 테스트는 에셋을 실제 디코딩해 600x90 크기와 카카오 `#FEE500`·네이버 `#03A94D` 배경 픽셀도 검증한다.
  - 영향범위: 로그인 화면의 소셜 로그인 버튼 이미지와 내부 배치, 에셋 참조, 위젯 테스트, 프로젝트 문서. Behavior change: 두 버튼 모두 실제 wide 완성형 이미지의 왼쪽 심볼·레이블 배치를 사용한다. OAuth/API/DB 계약은 변경하지 않는다.
  - 파일: `assets/icons/kakao_login_img.png`, `assets/icons/naver_login_img.png`, `lib/features/auth/presentation/pages/login_page.dart`, `test/features/auth/presentation/pages/login_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 로그인 위젯 테스트 2건에서 실제 에셋 로드, 두 이미지 경로와 `BoxFit.contain`, 342x54 터치 영역, 접근성 레이블, 600x90 규격, 브랜드 배경색을 검증해 통과했다. 대상 코드·테스트 `flutter analyze` 0건, `dart format`과 `git diff --check` 통과.
  - 롤백: 두 버튼의 에셋 참조를 이전 구현으로 되돌리고 신규 이미지 규격·색상 테스트와 프로젝트 컨텍스트 기록을 복원한다.
  - 다음: 실제 iOS/Android 기기에서 다양한 화면 너비의 이미지 선명도, 좌우 여백, 로그인 탭과 로딩 전환을 최종 확인한다.

## 2026-07-20

- [DONE] (FIX) 카카오 로그인 묶음 중앙 정렬 적용
  - 목적: 카카오 공식 디자인 가이드에 따라 심볼·레이블 영역을 유지하면서 네이버 center 버튼과 같은 묶음 중앙 정렬을 적용한다.
  - 변경: 카카오 공식 가이드의 가로 확장 규칙을 확인해 기존 `large_wide` 전체 이미지를 `large_narrow` 공식 원본으로 교체했다. 366x90 심볼·레이블 영역을 219.6x54로 비율 유지하고, `#FEE500`·12px radius의 342x54 전체 너비 컨테이너 정중앙에 배치했다. 컨테이너 좌우만 동일하게 확장하므로 네이버 center 버튼처럼 로고·레이블 묶음이 중앙에 오며, 공식 심볼·문구의 형태·자간·비율은 변경하지 않는다.
  - 영향범위: 로그인 화면의 카카오 버튼 내부 심볼·레이블 가로 배치와 에셋 경로. Behavior change: 카카오 심볼이 기존 좌측 고정 위치에서 레이블과 함께 버튼 중앙 묶음으로 이동한다. 외곽 크기, 로그인 콜백, 로딩/접근성, OAuth/API/DB 계약은 변경하지 않는다.
  - 파일: `assets/icons/kakao_login_center.png`, `lib/features/auth/presentation/pages/login_page.dart`, `test/features/auth/presentation/pages/login_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 공식 `large_narrow` 원본과 복사본의 SHA-256 일치 및 366x90 규격을 확인했다. 최초 테스트에서 비동기 이미지 고유 너비가 0으로 측정되는 문제를 확인해 공식 비율 기반 219.6x54 슬롯을 명시했다. 수정 후 위젯 테스트 1건에서 카카오 컨테이너 색·반경·342x54 크기, 콘텐츠 219.6x54 크기와 정확한 중앙 배치, 양쪽 에셋·접근성 회귀를 검증해 통과했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format`과 `git diff --check` 통과.
  - 롤백: 카카오 버튼을 기존 large wide 공식 이미지 표시로 복원한다.
  - 다음: 실제 iOS/Android 기기에서 카카오·네이버 묶음 중심과 공식 콘텐츠 크기를 최종 확인한다.

- [DONE] (FIX) 소셜 로그인 레이블 정렬 통일
  - 목적: 서로 다른 공식 버튼 정렬 변형을 사용해 카카오·네이버 로그인 레이블의 가로 위치가 어긋난 문제를 해결한다.
  - 변경: 네이버 Light 한국어 green `wide` H56 에셋을 같은 규격의 `center` H56 에셋으로 교체했다. 에셋 이름을 `naver_login_center.png`로 명확히 하고 로그인 화면과 테스트 참조를 갱신했다. 네이버 로고와 레이블을 하나의 묶음으로 가운데 정렬해 같은 묶음 중심형인 카카오 버튼과 레이블 위치를 맞췄다.
  - 영향범위: 로그인 화면의 네이버 버튼 내부 로고·레이블 가로 배치와 에셋 경로. Behavior change: 네이버 레이블이 기존 버튼 절대 중앙에서 로고와 함께 묶음 중앙 정렬되어 카카오 레이블과 같은 방향으로 이동한다. 버튼 외곽 크기, 로그인 콜백, 로딩/접근성, OAuth/API/DB 계약은 변경하지 않는다.
  - 파일: `assets/icons/naver_login_center.png`, `lib/features/auth/presentation/pages/login_page.dart`, `test/features/auth/presentation/pages/login_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 공식 center 원본과 복사본의 SHA-256 일치 및 기존과 동일한 1472x224 규격을 확인했다. 로그인 화면 위젯 테스트 1건에서 신규 에셋 경로, `BoxFit.contain`, 342x54 버튼 영역과 접근성 레이블 회귀를 검증해 통과했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format`과 `git diff --check` 통과.
  - 롤백: 네이버 버튼을 기존 Light green wide H56 에셋으로 복원한다.
  - 다음: 실제 iOS/Android 기기에서 카카오·네이버 레이블의 광학적 정렬을 최종 확인한다.

- [DONE] (FE) 카카오·네이버 공식 로그인 이미지 적용
  - 목적: 제공된 카카오·네이버 로그인 디자인 리소스에서 현재 앱에 맞는 이미지를 선택해 로그인 버튼을 공식 이미지 기반으로 교체한다.
  - 변경: 카카오 한국어 `large_wide`(600x90)와 네이버 Light 한국어 green wide H56(1472x224) 원본을 앱 에셋으로 복사했다. 로그인 화면의 임시 원형 K/N 아이콘과 직접 그린 브랜드 버튼을 제거하고, 54px 전체 너비 터치 영역 안에서 두 공식 이미지를 `BoxFit.contain`으로 왜곡 없이 표시한다. 기존 카카오·네이버 로그인 콜백과 버튼 내부 로딩 표시는 유지하고 각 버튼에 접근성 레이블을 추가했다.
  - 영향범위: 비인증 사용자가 보는 로그인 화면의 카카오·네이버 버튼 UI와 신규 이미지 에셋. Behavior change: 직접 구성한 버튼 대신 공식 한국어 브랜드 이미지가 표시된다. OAuth 처리, 인증 상태 전환, API/DB 계약은 변경하지 않는다.
  - 파일: `assets/icons/kakao_login.png`, `assets/icons/naver_login.png`, `lib/features/auth/presentation/pages/login_page.dart`, `test/features/auth/presentation/pages/login_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 원본과 복사본의 SHA-256 일치 및 600x90·1472x224 규격을 확인했다. 로그인 화면 위젯 테스트 1건에서 두 에셋 경로, `BoxFit.contain`, 342x54 버튼 영역과 접근성 레이블을 검증해 통과했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format`과 `git diff --check` 통과.
  - 롤백: 두 신규 에셋과 로그인 화면 이미지·접근성 적용, 전용 테스트·문서 기록을 제거하고 기존 직접 구성한 카카오·네이버 버튼을 복원한다.
  - 다음: 실제 iOS/Android 기기에서 다양한 화면 너비의 이미지 선명도와 로그인 탭·로딩 전환을 확인한다.

- [DONE] (CHORE) 완료된 근무 타입·캘린더 변경 작업별 커밋 및 푸시
  - 목적: 현재 작업 트리의 완료된 색상 선택 UX, 입력 포커스, 색상 메타데이터, 글자 대비와 선택일 배경 변경을 검증 가능한 작업 단위로 정리해 원격 `main`에 반영한다.
  - 변경: 색상 선택 화면 UX를 `1993c94`, 폼 입력 포커스 흐름을 `b9f6fda`, 기준 색상·농도 영속화를 `453d2e9`, 낮은 농도 글자 대비를 `874ea35`, 캘린더 선택일 배경 tint와 회귀 테스트를 `3e72781`로 분리했다. 프로젝트 컨텍스트·ADR-0010~0012·색상 메타데이터 API 가이드·작업 로그는 후속 문서 커밋으로 정리해 `origin/main`에 푸시한다.
  - 영향범위: 완료된 Flutter 변경의 Git 이력과 원격 `main`. 개인 LAN 주소를 사용하는 개발 API 기본값은 공유 환경 영향 때문에 커밋 대상에서 제외하고 작업 트리에 보존한다.
  - 파일: 현재 완료된 변경 파일과 `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 관련 코드·테스트 15개 파일 `dart format` 변경 0건, `flutter analyze --no-fatal-infos` 0건, 색상 파싱·색상 선택·커스텀 색상·근무 타입 버튼/폼·메인 캘린더 위젯 테스트 55건 통과. 각 작업 커밋과 최종 문서의 `git diff --check`를 확인했다.
  - 롤백: 원격 반영 후 필요 시 작업별 커밋을 역순으로 `git revert`하고 푸시한다.
  - 다음: 실제 서버 migration 적용 환경에서 기준 색상·농도 API 왕복과 실제 기기의 포커스·색상 대비·선택일 tint를 확인한다.

- [DONE] (STYLE) 캘린더 선택일 배경 primary tint 적용
  - 목적: 페이지 배경과 흰색 선택 배경의 차이가 작아 outline에만 의존하던 선택 상태를 더 분명하게 표시한다.
  - 변경: 공용 `CalendarMonthView`의 선택 사각형 배경을 흰색 surface에서 `primary_color` 8% tint로 변경했다. 기존 2px primary dark outline, 날짜 의미 색상, 선택 박스 크기·오프셋·애니메이션은 유지하고 메인 캘린더 회귀 테스트 기대값을 현재 계약에 맞췄다. 설계 변경은 ADR-0012에 기록했다.
  - 영향범위: 메인·친구 캘린더의 선택일 배경. Behavior change: 선택일이 흰색이 아닌 옅은 primary 배경으로 표시된다. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/calendar_month_view.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 메인 캘린더 위젯 테스트 10건 통과. 선택된 토요일의 8% primary tint, 2px primary dark outline과 날짜 의미 색상 유지를 검증했다.
  - 롤백: 선택 사각형 배경을 `AppTheme.surface_color`로 되돌리고 테스트·컨텍스트·ADR-0012 기록을 제거한다.
  - 다음: 실제 기기에서 메인·친구 캘린더의 선택 tint와 날짜 의미 색상 대비를 확인한다.

- [DONE] (FE) 근무 타입 기준 색상·농도 화면/API 연동
  - 목적: 서버의 신규 `base_color`, `color_intensity` 계약을 Flutter 근무 타입 설정 화면에 적용해 저장 후 재진입 시 기준 색상과 농도를 정확히 복원한다.
  - 변경: `ShiftTypeApiModel`에 기준 색상과 정수 농도를 추가하고 레거시 응답은 `base_color=color`, 농도 100으로 fallback한다. 생성·수정 요청은 두 필드의 동시 존재, 0~100 범위와 불투명 `FF` 알파를 직렬화 전에 검증하며 신규 요청에서는 최종 `color`를 생략한다. 색상 선택 화면은 고정 흰색과 RGB 채널을 서버 식으로 반올림하고 `ShiftColorSelection`으로 최종 색상·기준 색상·농도를 반환한다. 폼은 저장된 메타데이터로 50% 등 기존 상태를 복원하며 생성에는 메타데이터를 항상 포함하고, 편집에서 색상을 적용하지 않았으면 관련 필드를 모두 생략한다.
  - 영향범위: 근무 타입 API 모델·생성/수정 요청, 색상 선택 결과와 편집 화면 초기 상태, 관련 모델·위젯 테스트. Behavior change: 색상 농도는 테마 surface가 아닌 고정 흰색 기준의 1% 단위 정수로 계산되고 저장 후 재진입 시 복원된다. 기존 캘린더 `shift_type_color` 표시는 유지한다.
  - 파일: `lib/features/calendar/data/models/shift_type_api_model.dart`, `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/core/utils/color_parser_test.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/SHIFT_TYPE_COLOR_METADATA_API_GUIDE.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 색상 파싱/직렬화, 선택·커스텀 선택, 폼, 설정 Provider, 근무 버튼 관련 테스트 47건 통과. 고정 흰색 0·50·100% 계산, 레거시/null fallback, 메타데이터 쌍·범위·알파 검증, 50% 재진입 복원, 생성 요청, 색상 변경/무변경 수정 요청을 검증했다. 관련 구현·테스트·Provider·설정 페이지 11개 파일 `flutter analyze --no-fatal-infos` 0건, `dart format`과 `git diff --check` 통과. 실제 Express model/route/controller/service와 두 migration 파일에 신규 계약이 구현된 것도 대조했으나, 서버 2026-07-20 WORKLOG상 연결 DB에는 아직 컬럼이 없어 실제 API 왕복은 수행하지 않았다.
  - 롤백: 신규 메타데이터 필드와 선택 결과 객체·복원 흐름을 제거하고 최종 `color` 단독 요청/반환 방식으로 되돌린다.
  - 다음: 실제 신규 서버와 DB migration 적용 환경에서 50% 저장 → GET 재조회 → 편집 재진입 왕복을 확인한다.

## 2026-07-19

- [DONE] (PLAN) 근무 타입 색상 메타데이터 API·DB 마이그레이션 계획 수립
  - 목적: 색상 농도 적용 후 설정 화면에 다시 진입했을 때 기준 색상과 농도를 복원할 수 있도록 현재 Flutter·Express·PostgreSQL 계약을 근거로 서버 API 변경 및 DB 마이그레이션 계획을 확정한다.
  - 변경: Flutter의 색상 선택 반환·요청 모델과 Express 서버의 model/route/controller/service, 실제 `shift_types.color text`, 수동 migration 정책을 확인했다. 기존 최종 `color`는 하위 호환용으로 유지하고 nullable `base_color text`, 기본값 100의 `color_intensity smallint`를 추가하는 API 계약을 정했다. 신규 요청은 기준 색상·정수 농도로 최종 색상을 서버 계산하며 구버전 `color` 단독 요청과 레거시 행은 100%로 해석한다. 운영 계획은 데이터 감사·백업 → nullable 컬럼 확장 → 서버 dual-read/dual-write → backfill·범위/형식 제약 → Flutter 배포 순으로 분리하고 검증·롤백 SQL까지 문서화했다.
  - 영향범위: 문서만 변경. 서버·Flutter 실행 코드와 실제 DB는 변경하지 않는다. Behavior plan: 구현 후 설정 재진입 시 기준 색상과 농도를 복원하며 기존 캘린더 API는 최종 `shift_type_color`만 유지한다.
  - 파일: `_docs/SHIFT_TYPE_COLOR_METADATA_API_GUIDE.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: Flutter 필수 문서·AGENTS.md·`schema.drawio`·`visibility_flow.drawio`, 실제 Express 서버의 필수 문서·Sequelize 모델·route·controller·service·migration·package script를 대조했다. 신규 가이드의 코드 fence 28개가 짝수임을 확인했고 `git diff --check`를 통과했다. 문서 계획 작업이므로 Flutter/서버 실행 테스트와 실제 SQL 실행은 하지 않았다.
  - 롤백: 위 계획 문서와 문서 연결·ADR·작업 로그 항목을 제거한다.
  - 다음: 서버 저장소에서 Phase 0 데이터 감사 결과를 확인한 뒤 두 단계 migration과 dual-read/dual-write API를 구현하고, 계약 검증 후 Flutter 값 객체·요청·재진입 복원을 구현한다.

- [DONE] (FIX) 낮은 근무 색상 농도의 글자 대비 보정
  - 목적: 근무 타입 색상 농도를 낮췄을 때 근무 코드 글자까지 옅어져 읽기 어려운 원인을 제거한다.
  - 변경: 농도 값이 alpha가 아니라 `surface_color`와의 불투명 혼합으로 저장되는 반면, 표시 위젯은 흰색 또는 옅어진 근무 색상 자체를 글자색으로 사용해 대비가 사라지는 원인을 확인했다. `AppTheme.readableForegroundColor()`를 추가해 실제 배경과 선호 전경색이 4.5:1 대비를 만족하면 유지하고, 부족하면 공용 어두운색/밝은색 중 대비가 높은 색을 선택한다. 이를 근무 타입 폼 미리보기, 설정 목록 배지, 기존/메인 근무 선택 버튼, 라벨 배지, 캘린더 코드 배지에 적용했다.
  - 영향범위: 근무 타입 미리보기·설정 목록·근무 선택 버튼·캘린더 배지의 전경색. Behavior change: 밝거나 낮은 농도의 근무 색상에서는 코드 글자가 어두운색으로 표시될 수 있다. 저장 색상 및 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/core/theme/app_theme.dart`, `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `lib/features/calendar/presentation/widgets/shift_type_card.dart`, `lib/features/calendar/presentation/widgets/shift_type_button.dart`, `lib/features/calendar/presentation/widgets/shift_badge.dart`, `lib/features/calendar/presentation/widgets/calendar_month_view.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `test/features/calendar/presentation/widgets/shift_type_button_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 색상 선택 7건, 근무 타입 폼 11건, 근무 선택 버튼 3건 등 관련 위젯 테스트 21건 통과. 옅은 `#F5F7FA` 배경의 폼 미리보기와 선택 버튼 코드가 `on_surface_color`를 사용하는지 검증했다. 대상 10개 코드·테스트 파일 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과. 이후 선택 배경 primary 8% tint의 캘린더 기대값도 별도 작업에서 현재 계약에 맞춰 수정했다.
  - 롤백: `readableForegroundColor()`와 각 근무 코드 전경색 호출을 제거하고 폼·목록·캘린더는 흰색, 선택 버튼은 근무 색상을 직접 사용하는 방식으로 복원한다.
  - 다음: 실제 기기에서 밝은 프리셋과 0%·25%·50% 농도의 코드 대비를 확인한다.

- [DONE] (FE) 근무 타입 입력 포커스 흐름 개선
  - 목적: 근무 타입 설정에서 코드 → 이름 → 시작 시간 → 종료 시간 순서로 입력을 이어가고, 텍스트 선택 시 커서를 끝으로 이동하며 화면 터치로 키보드를 닫을 수 있게 한다.
  - 변경: 코드·이름에 전용 `FocusNode`를 연결하고 처음 포커스를 얻은 프레임 뒤 기존 텍스트 끝으로 커서를 이동하도록 했다. 키보드 완료 액션은 코드에서 이름, 이름에서 시작 시간 시트로 연결했으며 시작 시간의 `선택한 시간 적용` 후 종료 시간 시트를 자동으로 연다. 종료 시간 적용 또는 시트 취소 뒤에는 텍스트 포커스를 남기지 않는다. 본문 전체에 키보드 해제 터치 영역을 추가하고 시간·색상 선택 및 저장 진입 전에도 포커스를 명시적으로 해제했다.
  - 영향범위: 근무 타입 추가·편집 화면의 텍스트 포커스, 시간 선택 전환, 키보드 닫기 UX. Behavior change: 시작 시간을 적용하면 폼으로 즉시 돌아오지 않고 종료 시간 선택이 이어진다. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 근무 타입 폼 위젯 테스트 10건과 공용 시간 선택 시트 테스트 2건 등 총 12건 통과. 코드·이름의 최초 포커스 커서 끝 이동, 키보드 완료 액션, 시작 시간 적용 후 종료 시간 자동 진입, 종료 시간 적용 후 포커스 해제, 본문 터치 키보드 닫기와 기존 저장·삭제·색상 선택 회귀를 검증했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과. 프로젝트 전체 분석은 이번 변경 파일 밖의 기존 미사용 import·생성 코드 ignore 경고와 네이밍/deprecation info를 포함한 114건 때문에 종료 코드 1이며, 관련 없는 코드는 수정하지 않았다.
  - 롤백: 전용 `FocusNode`, 순차 제출 콜백, 시작 시간 적용 후 종료 시간 호출과 본문 포커스 해제 영역을 제거하고 시간 선택을 각 행에서 독립적으로 여는 방식으로 복원한다.
  - 다음: 실제 iOS/Android 기기에서 키보드 완료 액션 라벨, 커서 위치, 시작→종료 시간 시트 전환 애니메이션을 확인한다.

- [DONE] (FE) 선택 색상 좌우 배치 카드 재디자인
  - 목적: 선택 색상 원과 오른쪽 정보의 좌우 배치를 유지하면서 상단 미리보기를 앱 카드 디자인에 맞게 다시 구성한다.
  - 변경: 상단 미리보기를 공용 `AppTheme.cardDecoration` 기반 surface 카드로 감싸고, 왼쪽에 76.8px 선택 색상 원을 배치했다. 중앙에는 세로 구분선을 추가했으며 오른쪽 정보 열은 `선택한 색상` 안내, 색상명, HEX pill 순서로 재구성해 정보 계층과 가독성을 높였다. 기존 연필 편집 배지는 노출하지 않는다.
  - 영향범위: 근무 타입 색상 선택 화면 상단 미리보기 카드의 표면·간격·정보 계층. 색상 선택·농도 조절·적용 반환과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 색상 선택 위젯 테스트 7건과 근무 타입 편집 연동 테스트 8건 등 총 15건 통과. 390x844 화면에서 surface 카드 토큰, 선택 원→구분선→정보 열의 좌우 좌표, 색상명→HEX의 세로 순서, 연필 아이콘 미노출과 기존 색상·농도 동기화를 검증했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: surface 카드와 세로 구분선을 제거하고 선택 색상 원과 오른쪽 정보만 있는 직전 `Row` 구조로 복원한다.
  - 다음: 실제 iPhone에서 카드 좌우 균형, 긴 커스텀 색상명의 ellipsis와 HEX pill 가독성을 확인한다.

- [DONE] (FE) 선택 색상 미리보기 가로 정보 배치
  - 목적: 선택 색상 미리보기의 편집 배지를 제거하고 색상 원 왼쪽·HEX/색상명 오른쪽의 가로 구조로 변경한다.
  - 변경: 편집 배지가 제거된 뒤 남아 있던 빈 `Stack`과 기존 세로 `Column`을 하나의 중앙 정렬 `Row`로 교체했다. 76.8px 선택 색상 원을 왼쪽에 두고, 오른쪽 `Column`에 `선택한 색상` 안내, HEX pill, 19.2px 고정 색상명 슬롯을 왼쪽 정렬로 배치했다.
  - 영향범위: 근무 타입 색상 선택 화면 상단 미리보기 레이아웃. 색상 선택·농도 조절·적용 반환과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 색상 선택 7건과 근무 타입 편집 연동 8건 등 위젯 테스트 15건 통과. 390x844 화면에서 선택 색상 원의 오른쪽 좌표가 HEX와 색상명의 왼쪽 좌표보다 작은지, 연필 아이콘 미노출, 기존 크기·색상 동기화·농도 제스처·섹션 위치·적용/뒤로가기/커스텀 연동을 검증했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 가로 `Row`와 안내 문구를 제거하고 선택 원·HEX·색상명을 세로 `Column` 중앙 정렬 구조로 복원한다.
  - 다음: 실제 iPhone에서 선택 원과 오른쪽 정보 열의 세로 중심, 긴 커스텀 색상명 ellipsis를 확인한다.

- [DONE] (FE) 색상 농도 슬라이더 드래그·트랙 터치 이동 지원
  - 목적: 색상 농도를 슬라이더 핸들 드래그뿐 아니라 트랙의 원하는 위치를 터치하거나 트랙에서 바로 드래그해 조절할 수 있게 한다.
  - 변경: 기본 `CupertinoSlider`가 핸들 주변 포인터만 hit test하는 구현임을 Flutter SDK 코드에서 확인했다. 슬라이더 전체 44px 영역을 불투명 `GestureDetector`로 감싸고 Cupertino 트랙의 좌우 inset을 반영해 로컬 X 좌표를 0~1 농도로 변환했다. 내부 슬라이더는 `IgnorePointer`로 중복 제스처 경쟁을 막고 활성 시각을 유지하며, 핸들 드래그·트랙 탭·핸들이 없는 임의 위치에서 시작한 가로 드래그를 모두 같은 `_setColorIntensity()` 경로로 갱신한다.
  - 영향범위: 근무 타입 색상 선택 화면의 농도 슬라이더 제스처. 색상 혼합·적용 반환과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 색상 선택 7건과 근무 타입 편집 연동 8건 등 위젯 테스트 15건 통과. 실제 포인터로 트랙 중앙 탭 후 50%, 핸들을 드래그한 후 25%, 트랙 25% 위치에서 시작해 75% 위치까지 드래그 후 75%가 되는지 검증했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: `_cupertino_slider_track_inset`, 위치 기반 농도 갱신 메서드와 트랙 `GestureDetector`를 제거하고 기본 `CupertinoSlider.onChanged`만 사용하는 구조로 복원한다.
  - 다음: 실제 iPhone에서 핸들 드래그, 트랙 탭, 트랙 시작 드래그와 세로 화면 스크롤 간 제스처 충돌이 없는지 확인한다.

- [DONE] (FE) 불투명 색상 농도 조절 및 색상 선택 화면 재구성
  - 목적: 채도 조절을 배경이 비치지 않는 색상 농도 조절로 교체하고, 화면 정보 순서와 조절 카드 디자인을 개선한다.
  - 변경: HSV 채도 계산을 제거하고 `AppTheme.surface_color`와 기본 색상을 `Color.lerp()`로 혼합한 뒤 alpha를 1로 고정하는 `_color_intensity` 상태로 교체했다. 본문은 프리셋→색상 농도→커스텀 색상 순서로 재배치하고 `12개 선택 가능` 문구를 제거했다. 농도 카드는 기존 영문 라벨·축소 슬라이더 대신 한글 제목/설명, 퍼센트 pill, 옅은색·원본색 endpoint와 44px 높이 슬라이더를 사용하는 컴팩트 카드로 재구성했다.
  - 영향범위: 근무 타입 색상 선택 화면의 색상 보정 방식, 섹션 순서, 농도 조절 카드와 프리셋 안내 문구. Behavior change: 농도 0%는 불투명 surface 색, 100%는 불투명 원본 색이며 중간값도 배경이 비치지 않는 옅은 색이다. 색상 적용 반환 및 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 색상 선택 6건과 근무 타입 편집 연동 8건 등 위젯 테스트 14건 통과. 390x844 화면에서 프리셋→농도→커스텀 Y 순서, 개수 문구 미노출, 농도 50%의 불투명 `#A1AADC`, 모든 프리셋 선택 후 섹션 위치 불변과 기존 적용/뒤로가기/커스텀 연동을 검증했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: `_color_intensity` surface 혼합과 새 농도 카드·순서를 제거하고 직전 HSV 채도 상태, SATURATION 카드, 프리셋→커스텀→채도 순서와 관련 테스트·컨텍스트로 복원한다.
  - 다음: 실제 iPhone에서 농도 카드의 설명/퍼센트/endpoint 정렬과 0%·50%·100% 색상 가독성을 확인한다.

- [DONE] (FE) 근무 색상 밝기 조절을 채도 조절로 변경
  - 목적: 근무 타입 색상 선택 화면의 밝기 조절을 채도 조절로 교체한다.
  - 변경: `_brightness`와 HSV `value` 배율 계산을 `_saturation`과 HSV `saturation` 배율 계산으로 교체했다. 조절 카드의 `BRIGHTNESS` 문구와 관련 키를 `SATURATION` 기준으로 변경하고, 프리셋·커스텀 색상 선택 시 채도를 100%로 초기화한다. 인디고 색상에서 50% 조절 시 밝기를 유지한 `#7E87B8`이 되는 회귀 테스트를 추가했다.
  - 영향범위: 프리셋·커스텀 근무 색상의 보정 방식과 조절 카드 UI. Behavior change: 0~100% 슬라이더가 밝기가 아니라 원본 대비 채도를 조절하며, 0%는 같은 밝기의 무채색이고 100%는 원본 색상이다. 색상 선택·적용 반환 및 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 색상 선택 6건과 근무 타입 편집 연동 8건 등 위젯 테스트 14건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 채도 상태·HSV saturation 계산·SATURATION 카드와 관련 테스트를 기존 밝기 상태·HSV value 계산·BRIGHTNESS 카드로 복원하고 프로젝트 컨텍스트를 되돌린다.
  - 다음: 실제 기기에서 0%·50%·100% 채도 변화와 적용 후 근무 타입 미리보기 색상을 확인한다.

- [DONE] (FE) 커스텀 색상 선택 화면 세로 스크롤 차단
  - 목적: `_ShiftCustomColorPickerPageState`의 본문이 사용자 드래그로 세로 스크롤되지 않게 한다.
  - 변경: 본문 `ListView`에 `NeverScrollableScrollPhysics`를 적용해 기존 레이아웃과 콘텐츠 구성을 유지하면서 사용자 세로 드래그에 의한 이동만 차단했다. 위젯 테스트에 스크롤 물리 설정과 드래그 전후 미리보기 좌표 불변 검증을 추가했다.
  - 영향범위: 커스텀 근무 색상 선택 화면의 세로 스크롤 입력. 색상 선택·최근 색상·적용 동작과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_custom_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 커스텀 색상 선택 7건과 상위 색상 선택 연동 6건 등 위젯 테스트 13건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 본문 `ListView`의 `NeverScrollableScrollPhysics`와 드래그 좌표 회귀 검증을 제거하고 프로젝트 컨텍스트의 세로 스크롤 차단 설명을 되돌린다.
  - 다음: 실제 기기에서 세로 드래그 중 색상 휠·RGB 슬라이더 조작이 안정적으로 유지되는지 확인한다.

- [DONE] (CHORE) 완료된 변경사항 작업별 커밋 및 푸시
  - 목적: 현재 작업 트리의 완료된 iOS 빌드 설정, API URL, 캘린더/근무 타입, 친구 설정 변경을 검증 가능한 작업 단위로 정리해 원격 `main`에 반영한다.
  - 변경: iOS Profile 설정을 `40f9761 fix(ios): add profile build configuration`, Stage/Center API URL을 `9c5758a chore(api): update stage and production endpoints`, 근무 타입 편집·색상·시간 선택·수정 응답 동기화와 하단 카드 정렬을 `441c2ed feat(calendar): refine shift type editing workflow`, 친구 설정 저장 후 복귀·목록 새로고침을 `484fdc0 fix(friend): refresh settings after save`로 분리했다. 프로젝트 컨텍스트·ADR·작업 로그는 후속 문서 커밋으로 정리해 다섯 커밋을 `origin/main`에 푸시한다.
  - 영향범위: 완료된 변경의 Git 이력과 원격 `main`. 문서·ADR·테스트와 충돌하는 `calendar_month_view.dart`의 선택 배경 tint 변경은 커밋하지 않고 기존 작업 트리에 그대로 보존했다.
  - 파일: 현재 완료된 변경 파일과 `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: iOS 프로젝트 파일 `plutil -lint` 통과 및 Profile CocoaPods/Generated/Secrets include 연결 확인. API 상수 분석은 error/warning 0건이며 프로젝트 snake_case 규칙에 따른 기존 naming info 25건만 확인했다. 캘린더·근무 타입 대상 15개 파일 분석 0건과 관련 테스트 37건, 친구 대상 4개 파일 분석 0건과 관련 테스트 6건 등 총 43건 통과. 대상 `dart format`, 각 커밋의 `git diff --cached --check` 통과.
  - 롤백: 원격 반영 후 필요 시 작업별 커밋을 역순으로 `git revert`하고 푸시한다.
  - 다음: 후속 문서 커밋 생성 후 `origin/main` 푸시와 원격 동기화 상태 확인

- [DONE] (FE) 근무 시간 개별 삭제
  - 목적: 근무 타입 폼의 시작·종료 시간 X 버튼이 사용자가 누른 시간만 삭제하도록 변경한다.
  - 변경: `_clearTime()`이 시작/종료 대상을 받아 해당 `TimeOfDay`만 null로 변경하도록 수정하고 각 행의 X 버튼에서 자신의 대상을 전달했다. 시작 시간 삭제 후 종료 시간이 유지되고, 종료 시간 삭제 후 시작 시간이 유지되는 개별 동작을 테스트로 고정했다. 한쪽만 남은 중간 편집 상태는 허용하지만 완료 시 기존 시간 쌍 검증으로 저장을 막는 정책을 ADR-0009에 기록했다.
  - 영향범위: 근무 타입 추가·편집 화면의 시간 삭제 UX와 관련 정책 문서. Behavior change: 한 X 버튼이 두 시간을 동시에 지우지 않고 해당 행의 시간만 지운다. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 근무 타입 폼 위젯 테스트 8건 통과. 시작 시간만 삭제 후 종료 시간 유지, 한쪽만 남은 상태의 완료 차단, 종료 시간 개별 삭제와 빈 시간 정렬을 검증했다. 대상 코드/테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 삭제 액션을 시작·종료 동시 초기화 방식으로 복원한다.
  - 다음: 실제 기기에서 각 X 버튼의 터치 대상과 개별 삭제 후 재선택 흐름을 확인한다.

- [DONE] (FE) 근무 타입 시간 선택 모달 공용화
  - 목적: 근무 타입 추가·편집의 시작/종료 시간 선택 화면을 개인 일정 추가에서 사용하는 공용 시간 선택 하단 시트와 통일한다.
  - 변경: 근무 타입 폼 내부의 자체 300px `CupertinoDatePicker` 팝업을 제거하고 개인 일정과 같은 `showTimePickerSheet()`를 호출하도록 변경했다. 폼의 기존 `TimeOfDay`를 공용 시트의 `Duration` 초기값으로 전달하고 적용 결과를 다시 `TimeOfDay`로 변환해 표시 및 `HH:mm:ss` 저장 계약을 유지했다. 관련 회귀 테스트에서 문서 계약과 다르게 한쪽 시간만 비우던 기존 오류를 재현해, 어느 삭제 액션이든 시작·종료 시간을 함께 비우도록 바로잡았다.
  - 영향범위: 근무 타입 추가·편집 화면의 시작/종료 시간 선택 UX와 시간 삭제 일관성, 관련 위젯 테스트. Behavior change: 시간 선택 화면이 개인 일정과 동일한 선택 요약·`지금`·취소/적용 UI로 통일된다. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 근무 타입 폼 8건과 공용 시간 선택 시트 2건 등 관련 위젯 테스트 10건 통과. 공용 `TimePickerSheet` 진입, 기존 06:30 초기값, 적용 후 폼 표시, 시간 동시 삭제와 기존 저장 계약을 검증했다. 대상 3개 파일 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 공용 시트 호출을 제거하고 근무 타입 폼 내부 시간 피커 팝업을 복원한다.
  - 다음: 실제 iOS/Android 기기에서 근무 타입의 시작·종료 시간 시트 높이, `지금` 선택과 하단 안전영역을 확인한다.

- [DONE] (FE) 친구 설정 저장 후 이전 화면 데이터 새로고침
  - 목적: 친구 설정 저장 후 친구 캘린더로 복귀할 때 서버의 최신 친구 목록을 다시 조회하고, 같은 화면에서 설정을 재진입해도 갱신값을 사용한다.
  - 변경: 친구 상세 route 결과를 `FriendDetailResult.saved`와 `deleted`로 구분했다. 저장 성공으로 친구 캘린더에 복귀하면 `friendListProvider.loadFriends()`가 `GET /api/v1/friends`를 다시 호출하고, 응답 목록에서 같은 `user_id`의 `FriendModel`을 찾아 현재 화면의 로컬 친구 모델을 교체한다. 이후 설정 화면은 이 최신 모델로 진입한다. 삭제 성공은 기존처럼 친구 캘린더까지 닫아 친구 목록으로 복귀하고, 저장하지 않은 일반 뒤로가기는 새로고침하지 않는다.
  - 영향범위: 친구 상세 저장/삭제 결과 반환, 친구 캘린더의 복귀 후 친구 목록 API 조회와 설정 재진입 데이터. 친구 캘린더 일정 조회 API와 DB 구조는 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/friend_detail_page.dart`, `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/friend/presentation/pages/friend_detail_page_test.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 저장 성공 시 `saved` 반환 테스트 1건과 복귀 후 친구 목록 GET 호출·최신 `can_view` 재진입 테스트 1건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format`, `git diff --check` 통과.
  - 롤백: `FriendDetailResult`와 `_refreshFriend()`를 제거하고 상세 route 결과를 기존 삭제 여부 `bool`로 복원한 뒤, 저장 성공은 결과 없이 pop하도록 되돌리고 관련 테스트·문서 기록을 제거한다.
  - 다음: 실제 계정에서 공유 설정을 저장한 후 네트워크 탭으로 친구 목록 GET 재호출을 확인하고, 설정 화면 재진입 시 저장값이 유지되는지 확인한다.

- [DONE] (FE) 친구 설정 저장 성공 후 이전 화면 이동
  - 목적: 친구 상세 화면에서 변경한 레벨/캘린더 공유 설정의 저장이 성공하면 사용자를 이전 화면으로 자동 이동시킨다.
  - 변경: `FriendDetailPage._saveSettings()`가 `friendListProvider`의 설정 변경 성공 응답을 받으면 현재 상세 route를 즉시 pop하도록 변경했다. 실패 시에는 상세 화면을 유지하고 로딩 상태를 해제한 뒤 기존 오류 다이얼로그를 표시한다. 가짜 `FriendService`로 캘린더 공유 토글의 요청값과 성공 후 이전 화면 복귀를 검증하는 위젯 테스트를 추가했다.
  - 영향범위: 친구 상세 화면의 설정 저장 완료 내비게이션. Behavior change: 저장 성공 후 상세 화면에 머무르지 않고 이전 친구 캘린더 화면으로 자동 복귀한다. 저장 API, Provider 로컬 상태 갱신, 실패 UX와 DB 구조는 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/friend_detail_page.dart`, `test/features/friend/presentation/pages/friend_detail_page_test.dart`(신규), `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 신규 위젯 테스트 1건 통과, 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format`, `git diff --check` 통과. 친구 기능 전체 테스트에서는 9건 통과 후 작업 시작 전부터 현재 작업 트리에 존재한 선택 배경 primary 8% tint와 기존 surface 기대값 불일치 1건이 실패했으며, 이번 저장 내비게이션 범위 밖이라 수정하지 않았다.
  - 롤백: 저장 성공 분기의 `Navigator.pop()`을 제거하고 성공 시 `_saved_level`·`_saved_can_view`만 갱신하는 기존 화면 유지 흐름으로 복원한 뒤 신규 테스트와 관련 문서 기록을 제거한다.
  - 다음: 실제 기기에서 레벨 또는 공유 토글을 변경해 저장한 뒤 친구 캘린더로 복귀하는지, 네트워크 실패 시 상세 화면과 변경값이 유지되는지 확인한다.

- [DONE] (FIX) 근무 타입 수정 응답 기반 화면 동기화
  - 목적: 근무 타입 수정 저장 중 설정 화면의 전체 새로고침성 로딩을 제거하고, 수정 API 응답값으로 설정 목록과 메인 캘린더 표시를 즉시 최신화한다.
  - 변경: 수정 저장 시 `ShiftTemplateSettingsNotifier`가 공용 `is_loading`을 켜지 않고 `ShiftTypeApiModel?` 응답을 반환하도록 변경했으며, 설정 페이지의 로딩 다이얼로그와 성공 후 `shiftTypesProvider` 무효화를 제거했다. 성공 응답은 설정 목록의 해당 항목을 직접 교체하고 `shiftTypeDisplayUpdatesProvider`에 수정 전 코드와 함께 발행한다. `effectiveShiftTypesProvider`는 기존 GET 캐시 위에 이 응답을 합성해 근무 입력 버튼을 최신화한다. 메인 `CalendarPage`는 표시 업데이트를 구독해 수정 전 코드가 같은 `_workShifts`와 `_schedules`의 코드·이름·색상·시간만 응답값으로 교체한다. 로그인/로그아웃 시 표시 업데이트도 무효화한다. 원인은 영속 로컬 저장소가 아니라 설정 route 아래에서 유지되는 `CalendarPage`의 `_workShifts`/`_loadedMonths` 메모리 스냅샷과 수정 응답 전달 부재로 확인했다. 설계 결정은 ADR-0008에 기록했다.
  - 영향범위: 근무 타입 수정 요청 중 UI 상태, 설정 목록과 근무 입력 목록, 메인 캘린더의 이미 로드된 근무표 표시 데이터, 계정 전환 시 Provider 무효화. 생성/삭제와 DB/API 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`, `lib/features/calendar/presentation/providers/shift_template_settings_provider.dart`, `lib/features/calendar/presentation/providers/shift_types_provider.dart`, `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/calendar/data/models/work_shift_api_model.dart`, `lib/features/auth/presentation/providers/auth_provider.dart`, `test/features/calendar/presentation/providers/shift_template_settings_provider_test.dart`(신규), `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: VM·Chrome에서 Provider 테스트 각 2건과 메인 캘린더 동기화 테스트 각 1건 통과. 수정 요청 중 `is_loading=false`, PUT 응답 객체의 설정 목록 반영, GET 캐시 위 응답 합성, 캘린더 range 추가 호출 없이 기존 선택일 이름·시간 교체를 검증했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 통과. 전체 캘린더 테스트의 기존 월 보기 색상 기대값 1건과 근무 타입 폼의 기존 시간 동시 삭제 기대값 1건은 현재 작업 트리 코드와 불일치해 실패하며 이번 동기화 변경 범위에서는 수정하지 않았다.
  - 롤백: `shiftTypeDisplayUpdatesProvider`/`effectiveShiftTypesProvider`, 캘린더 표시 패치와 `copyWithShiftType()`을 제거하고, 수정 메서드를 `Future<bool>` 및 공용 `is_loading`/로딩 다이얼로그/`shiftTypesProvider` 무효화 흐름으로 복원한다. ADR-0008과 관련 컨텍스트·테스트를 제거한다.
  - 다음: 실제 계정으로 코드·이름·색상·시간을 수정해 설정 목록과 메인 캘린더가 추가 GET 없이 즉시 같아지는지 확인한다. 앱 재실행 후 `/calendar/range` 자체가 이전 메타데이터를 반환하면 서버 조회 join/스냅샷 정책을 점검한다.

- [DONE] (FE) 근무 타입 중복 코드 표시를 영역 테두리로 변경
  - 목적: 중복 코드 입력 시 코드 글자색을 바꾸는 대신 코드 입력 영역의 빨간 테두리로 오류 위치를 더 명확하게 표현한다.
  - 변경: 중복 상태에서 `CupertinoTextField`의 코드 글자색을 accent red로 바꾸던 분기를 제거해 기본 본문 색상을 유지했다. 대신 코드 입력 행에 1.6px accent red foreground 테두리를 표시하고 카드 상단 모서리 반경을 동일하게 적용했다. 고유 코드로 변경하면 테두리는 즉시 제거되며 기존 인라인 안내와 `완료` 비활성화는 유지한다.
  - 영향범위: 근무 타입 코드 중복 상태의 시각 표현. 중복 판정, 완료 비활성화, API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: VM 및 Chrome 브라우저에서 전용 위젯 테스트 각 7건 통과(중복 시 1.6px accent red 코드 행 테두리, 기본 코드 글자색 유지, 고유 코드 변경 시 테두리 제거 포함). 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format`, `git diff --check` 통과.
  - 롤백: 코드 입력 영역의 오류 테두리를 제거하고 중복 코드 입력값의 accent red 글자색 표시를 복원한다.
  - 다음: 실제 브라우저와 iOS/Android 기기에서 코드 행의 빨간 테두리가 카드 outline 및 구분선과 자연스럽게 겹치는지 확인한다.

- [DONE] (FE) 근무 타입 코드 중복 즉시 표시
  - 목적: 근무 타입 추가/편집 화면에서 코드를 입력하는 동안 현재 템플릿의 기존 코드와 즉시 비교해 사용 불가능 여부를 저장 전에 알린다.
  - 변경: 코드 입력 리스너가 기존 대문자 정규화와 함께 화면을 즉시 갱신하도록 하고, `existingTypes`를 대소문자·앞뒤 공백 정규화 후 비교하는 공용 중복 판정을 추가했다. 편집 중인 타입은 `shiftTypeId`로 제외한다. 중복 코드는 인라인 안내와 후속 작업에서 반영한 코드 입력 영역 테두리를 accent red로 표시하고 `완료`를 비활성화하며, 고유 코드로 바꾸면 즉시 안내·테두리를 제거하고 완료 액션을 복구한다. 저장 시점의 기존 중복 검증과 서버 오류 처리는 유지했다.
  - 영향범위: 근무 타입 코드 입력 검증 UI와 완료 액션. 현재 화면 진입 시 로드된 코드 목록을 사용하는 로컬 사전 검증이며 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: VM 및 Chrome 브라우저에서 전용 위젯 테스트 각 7건 통과(다른 타입의 소문자 코드 입력 시 즉시 중복 표시·완료 비활성화, 고유 코드 변경 시 즉시 복구 포함). 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format`, `git diff --check` 통과. 전체 프로젝트 `flutter analyze --no-fatal-infos`는 이번 대상 밖 기존 경고·정보 126건으로 종료 코드 1이며 이번 변경 파일의 진단은 없다.
  - 롤백: 입력 리스너의 즉시 중복 상태 표시와 관련 테스트·문서를 제거하고 기존 완료 시점 검증만 유지한다.
  - 다음: 실제 브라우저와 iOS/Android 기기에서 키보드 입력 중 안내 문구 표시 및 레이아웃 이동을 확인한다.

- [DONE] (FIX) 일부 프리셋 선택 시 색상 화면 세로 이동
  - 목적: 호박색·에메랄드·골드·차콜 선택 시 프리셋 영역부터 하단 콘텐츠가 조금씩 아래로 이동하는 원인을 확인하고 레이아웃을 고정한다.
  - 변경: 색상명만 고정 높이 없이 intrinsic line box를 사용하고 있었고, 테마에 지정된 `Plus Jakarta Sans` 폰트 파일이 프로젝트에 번들되지 않아 iOS 한글 fallback의 font run 구성에 따라 공백 없는 호박색·에메랄드·골드·차콜과 공백이 있는 이름의 높이가 달라질 수 있는 구조를 원인으로 확인했다. 색상명을 디자인 기준 24px, 0.8 본문 배율에서 19.2px인 고정 슬롯 안에 한 줄로 배치해 이름에 관계없이 프리셋 이하의 위치를 고정했다. 현재 코드의 우측 `적용` 문구에 맞춰 관련 테스트·컨텍스트의 이전 `완료` 표현도 최신화했다.
  - 영향범위: 근무 타입 색상 선택 화면의 선택 색상 미리보기와 하단 섹션 세로 위치. 색상 값·밝기·적용 반환 및 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `test/features/calendar/presentation/widgets/shift_custom_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 12개 모든 프리셋 선택 후 19.2px 색상명 슬롯 높이, 스크롤 오프셋, 프리셋·커스텀·밝기 섹션 Y 좌표 불변성과 기존 색상 선택 동작을 포함한 관련 위젯 테스트 19건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 색상명 슬롯 고정 높이와 좌표 회귀 테스트를 제거해 기존 콘텐츠 기반 높이로 복원한다.
  - 다음: 실제 iPhone에서 12개 프리셋을 순회하며 스크롤 위치가 고정되는지 확인한다.

- [DONE] (FE) 근무 타입 폼 우측 콘텐츠 정렬
  - 목적: 코드·이름 입력값과 아이콘이 없는 시간 선택 텍스트의 오른쪽 끝을 시간 삭제용 `CupertinoIcons.xmark_circle_fill`의 오른쪽 끝과 같은 세로선에 맞춘다.
  - 변경: 삭제 버튼의 36px 슬롯·18px 아이콘·12px 외부 여백으로 계산되는 21px 시각 inset을 공용 상수로 정의하고, 코드·이름 입력 오른쪽 padding과 빈 시간 텍스트 뒤 여백에 동일하게 적용했다. 현재 `xmark_circle_fill` 아이콘은 유지하고 관련 문서·테스트의 이전 아이콘명을 최신화했다.
  - 영향범위: 근무 타입 추가·편집 화면 카드의 우측 정렬. 입력·시간 삭제·저장 동작과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 코드·이름 `EditableText`, 두 시간 선택 텍스트, 삭제 아이콘의 우측 좌표가 0.01px 허용 오차 안에서 일치하는지 포함한 전용 위젯 테스트 6건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 공용 우측 inset을 제거하고 입력 padding 16px, 시간 선택 뒤 여백 12px로 복원한다.
  - 다음: 실제 iOS 기기에서 문자 glyph와 원형 삭제 아이콘의 시각적 오른쪽 정렬을 확인한다.

- [DONE] (FE) 근무 시간 삭제 아이콘 강조
  - 목적: 근무 타입 편집 화면의 시작·종료 시간 삭제 X 아이콘을 더 굵게 표시해 식별성을 높인다.
  - 변경: 기존 `CupertinoIcons.xmark`를 같은 18px 크기와 accent red 색상의 `CupertinoIcons.clear_thick`으로 교체하고 아이콘 회귀 테스트를 추가했다.
  - 영향범위: 근무 타입 추가·편집 화면의 시간 삭제 아이콘 외형. 시간 동시 삭제 동작과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 굵은 아이콘 렌더링과 기존 시간 동시 삭제 동작을 포함한 전용 위젯 테스트 6건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 시간 삭제 아이콘을 `CupertinoIcons.xmark`로 되돌린다.
  - 다음: 실제 iOS 기기에서 18px 아이콘의 선명도와 터치 영역을 확인한다.

- [DONE] (FE) 근무 타입 편집 계열 화면 헤더 통일
  - 목적: 근무 타입 편집, 색상 선택, 커스텀 색상 선택 화면의 상단 내비게이션을 동일한 좌측 화살표·중앙 제목·우측 완료 조합으로 통일한다.
  - 변경: 커스텀 색상 선택 화면의 헤더 치수와 스타일을 기준으로 근무 타입 편집의 `취소`/primary pill `저장`을 좌측 화살표/우측 `완료`로 변경했다. 색상 선택의 좌측 화살표/X 헤더와 하단 `선택 완료` 영역은 좌측 화살표/우측 `완료` 헤더로 통합하고, 제거한 하단 영역만큼 본문 하단 안전 여백을 반영했다. 세 화면의 제목 색상, 화살표와 완료 타이포·색상·터치 영역을 동일하게 맞췄으며 기존 입력 검증과 결과 반환 계약은 유지했다.
  - 영향범위: 세 화면의 상단 헤더와 색상 선택 화면의 완료 액션 위치. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, 관련 위젯 테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 세 화면의 헤더 구성, 뒤로가기 폐기, 완료 결과 반환, 기존 입력·색상 동기화를 포함한 관련 위젯 테스트 18건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 두 화면의 헤더와 색상 선택 완료 액션을 기존 취소/저장 및 뒤로가기/X/하단 버튼 구성으로 복원한다.
  - 다음: 실제 iOS 기기에서 세 화면의 제목과 좌우 액션 정렬을 확인한다.

- [DONE] (FE) 최근 커스텀 색상 로컬 저장
  - 목적: 커스텀 색상 화면의 고정 샘플 목록을 실제 기기에서 사용자가 완료한 최근 색상 기록으로 전환한다.
  - 변경: `SharedPreferences`의 `shift_custom_recent_colors_v1` 문자열 목록에 완료 색상을 6자리 RGB HEX로 저장한다. 최신 색상을 앞에 두고 기존 중복을 제거해 최대 6개만 유지하며, 화면 진입 시 유효한 값만 복원하고 잘못된 값·중복·초과 항목은 정규화한다. 기록이 없으면 빈 상태를 표시하고 뒤로가기로 폐기한 색상은 저장하지 않는다.
  - 영향범위: 커스텀 색상 선택 화면의 최근 사용 색상 목록과 로컬 저장소. 색상 선택·반환 및 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart`, 관련 위젯 테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 로컬 빈 상태·복원·최신순 저장·중복 제거·6개 상한·잘못된 값 제외와 기존 색상 동기화·반환을 포함한 관련 위젯 테스트 17건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 최근 색상 저장 키와 로드/저장 로직을 제거하고 기존 고정 6색 목록을 복원한다.
  - 다음: 실제 기기에서 앱 재실행 후 최근 색상 순서와 유지 여부를 확인한다.

- [DONE] (FE) 커스텀 색상 휠·RGB 좌우 배치
  - 목적: 첨부 표시의 의도를 휠 확대가 아니라 색상 휠 왼쪽·RGB 슬라이더 오른쪽의 가로 배치로 정확히 반영한다.
  - 변경: 색상 휠 카드와 별도 RGB 카드를 하나의 카드로 합쳤다. 반응형 가로 레이아웃에서 390px 화면 기준 약 172px·최대 176px 휠을 왼쪽에, Red/Green/Blue 라벨·값·슬라이더를 오른쪽 열에 배치했다. 우측 열 가독성을 위해 RGB 본문 타이포와 행 간격을 컴팩트하게 조정하고 슬라이더 가로 1.0/세로 0.8 배율을 유지했다. HEX 입력과 외부 여백은 유지했다.
  - 영향범위: 커스텀 색상 선택 화면의 휠·RGB 카드 레이아웃. 색상 계산·입력·반환 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_custom_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 휠 오른쪽 좌표가 RGB 왼쪽 좌표보다 작은지와 두 컨트롤이 같은 카드에 포함되는지 검증했다. 기존 색상 동기화·반환을 포함한 커스텀 색상·상위 색상 선택·근무 타입 폼 위젯 테스트 15건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 통합 가로 카드를 제거하고 휠 카드와 하단 RGB 카드를 세로로 복원한다.
  - 다음: 실제 iPhone에서 우측 슬라이더 라벨·값·트랙 가독성을 확인한다.

- [DONE] (FE) 커스텀 색상 휠·RGB 컨트롤 폭 조정
  - 목적: 커스텀 색상 화면의 색상 휠 주변 좌우 빈 공간과 RGB 슬라이더 트랙이 짧게 보이는 문제를 첨부 표시 기준으로 개선한다.
  - 변경: 카드·HEX·화면 외부 여백은 유지하면서 색상 휠을 224→280px로 확대했다. RGB 슬라이더의 transform은 기존 가로·세로 0.8에서 가로 1.0/세로 0.8로 분리해 트랙이 카드 가용 폭을 사용하면서 기존 세로 밀도는 유지하게 했다.
  - 영향범위: 커스텀 색상 선택 화면의 색상 휠과 RGB 슬라이더 시각 크기. 색상 계산·입력·반환 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_custom_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 휠 280px와 슬라이더 가로 1.0/세로 0.8 배율 회귀 검증을 포함해 커스텀 색상·상위 색상 선택·근무 타입 폼 위젯 테스트 15건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 휠 최대 크기를 224px로, RGB 슬라이더 transform을 가로·세로 0.8로 되돌린다.
  - 다음: 실제 iPhone에서 휠 카드 여백과 RGB 트랙 길이를 확인한다.

- [DONE] (FE) 커스텀 색상 선택 화면 전면 적용
  - 목적: 근무 타입 색상 선택의 단순 색조·채도 하단 시트를 폐기하고 제공된 커스텀 색상 선택 시안을 실제 동작하는 전체 화면으로 적용한다.
  - 변경: 선택 색상 미리보기·HEX 표시/6자리 입력, 실제 HSV 좌표를 계산하는 드래그 가능 색상 휠, RGB 0~255 슬라이더, 6개 최근 색상 단축 선택, 뒤로가기/완료 내비게이션을 갖춘 전체 화면을 추가했다. 모든 입력은 미리보기·HEX·RGB·휠 마커에 즉시 동기화된다. 기존 색조·채도 하단 시트를 제거하고 색상 선택 페이지가 새 화면을 push하도록 연결했으며 앱 설정 화면과 같은 0.8 본문 밀도와 44px 최소 터치 영역을 유지했다.
  - 영향범위: 근무 타입 편집 → 색상 선택 → 커스텀 색상 선택 흐름의 UI와 색상 입력 방식. 최종 색상 반환 및 근무 타입 API 계약은 유지한다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart`(신규), `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, 관련 위젯 테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 커스텀 색상 화면 5건, 상위 색상 선택 5건, 근무 타입 폼 5건 등 위젯 테스트 15건 통과. 색상 휠·HEX·RGB·최근 색상 동기화, 완료/뒤로가기 반환과 상위 화면 연동을 검증했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 신규 커스텀 색상 페이지와 연결·테스트·문서를 제거하고 기존 색조·채도 하단 시트를 복원한다.
  - 다음: 실제 iOS 기기에서 색상 휠 드래그, 키보드, 작은 화면 스크롤과 색 대비를 확인한다.

- [DONE] (FE) 근무 타입 편집·색상 선택 화면 밀도 재조정
  - 목적: 근무 타입 편집 화면의 요소가 크게 보이는 문제를 해결하고 색상 선택 화면도 앱의 다른 설정 화면과 같은 시각적 밀도로 맞춘다.
  - 변경: 앱 설정 화면의 기존 `_settings_scale = 0.8`을 기준으로 두 화면의 본문 배율을 0.8로 통일하고 상단 내비게이션 바는 공통 크기로 유지했다. 근무 타입 편집은 미리보기 96→76.8px, 입력·시간 행 56→44.8px, 본문 기본 글자 16→12.8px로 줄이고 카드 반경·아이콘·간격·안내 문구도 함께 축소했다. 색상 선택은 기존 0.75에서 0.8로 보정해 미리보기 76.8px, 프리셋 원 41.6px, 완료 버튼 44.8px, 커스텀 미리보기 54.4px로 맞췄으며 주요 터치 영역은 최소 44px을 유지했다.
  - 영향범위: 근무 타입 추가·편집 화면과 색상 선택 화면의 시각적 크기·간격. 입력, 검증, 색상·시간 선택 및 API 요청 반환 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, 관련 위젯 테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 앱 설정 화면 배율·행 높이 대조 완료. 상단 헤더 유지와 두 화면의 80% 본문 치수 회귀 검증을 포함한 위젯 테스트 10건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 본문 배율과 축소 치수·테스트·문서를 제거해 직전 화면 크기로 복원한다.
  - 다음: 실제 iOS 기기에서 타이포 가독성, 카드 밀도, 터치 영역을 확인한다.

- [DONE] (FE) 색상 선택 화면 본문 75% 축소
  - 목적: 상단 헤더를 제외한 색상 선택 화면 본문 요소가 지나치게 크게 보이는 문제를 해결한다.
  - 변경: 본문 전용 0.75 배율을 적용해 미리보기를 96→72px, 프리셋 원을 52→39px, 하단 완료 버튼을 56→42px, 커스텀 미리보기를 68→51px로 축소했다. 본문 텍스트·간격·카드·슬라이더와 커스텀 색상 시트에도 같은 비율을 적용하고 상단 헤더 치수는 유지했다. 프리셋 행과 커스텀 버튼은 최소 44px 터치 영역을 유지했다.
  - 영향범위: 근무 타입 색상 선택 화면과 커스텀 색상 시트의 시각적 밀도. 색상 선택·반환 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 상단 헤더와 본문 치수 회귀 검증을 포함한 색상 선택 페이지 5건과 근무 타입 폼 5건 등 위젯 테스트 10건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 본문 배율 상수와 축소 치수·테스트·문서를 제거해 기존 크기로 복원한다.
  - 다음: 실제 iOS 기기에서 축소 후 터치 영역과 가독성을 확인한다.

- [DONE] (FE) 근무 타입 색상 선택 화면 전면 교체
  - 목적: 근무 타입 편집의 기존 `CupertinoActionSheet` 색상 목록을 폐기하고 제공된 Shift Harmony 색상 선택 시안을 전체 화면으로 적용한다.
  - 변경: 선택 색상 96px 미리보기·HEX·색상명, 4x3 프리셋 12개, 커스텀 색조/채도 시트, 원본 색상을 보존하는 밝기 0~100% 조절, 하단 고정 `선택 완료` 버튼을 제공하는 전체 화면 페이지를 추가했다. 근무 타입 폼의 색상 변경은 이 페이지를 push하며 `선택 완료` 결과만 반영하고 뒤로가기/X는 변경을 폐기한다. 기존 `CupertinoActionSheet` 색상 목록은 제거했다.
  - 영향범위: 근무 타입 추가·편집 화면의 색상 선택 UX와 최종 색상 값. Behavior change: 색상 선택이 액션 시트에서 독립 페이지로 바뀌고 프리셋·커스텀·밝기 조절을 지원한다. 근무 타입 API DTO와 DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`, `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 색상 선택 페이지 5건과 근무 타입 폼 5건 등 위젯 테스트 10건 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 새 색상 선택 페이지와 연결·테스트·문서를 제거하고 기존 `CupertinoActionSheet` 구현을 복원한다.
  - 다음: 실제 iOS 기기에서 프리셋/커스텀/밝기 조절과 작은 화면 스크롤을 확인한다.

- [DONE] (FE) 근무 코드 최대 길이 3자로 확장
  - 목적: 근무 타입 코드에 최대 3자까지 입력할 수 있도록 허용한다.
  - 변경: 근무 타입 폼의 코드 입력 `maxLength`와 안내를 2자에서 3자로 변경하고, `offx` 입력이 `OFF`로 제한·대문자화되어 원형 미리보기에 반영되는 테스트로 갱신했다.
  - 영향범위: 근무 타입 추가·편집 화면의 코드 입력 및 원형 미리보기. Behavior change: 기존 최대 2자 대신 최대 3자까지 입력할 수 있다. API DTO와 DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 전용 위젯 테스트 4건 통과, 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 코드 입력 제한·안내·테스트·문서를 최대 2자로 되돌린다.
  - 다음: 실제 기기에서 3자 코드의 원형 미리보기 가독성을 확인한다.

- [DONE] (FE) 근무 타입 추가·편집 화면 디자인 개편
  - 목적: 근무 타입 설정 화면을 제공된 Shift Harmony 시안에 맞추고, 친구 설정 화면의 컴팩트한 상단 내비게이션·중앙 미리보기·카드형 설정 그룹 레이아웃과 통일한다.
  - 변경: 친구 설정 화면과 같은 outline 카드·컴팩트 내비게이션을 사용하고, 시안 기준 96px 원형 코드 미리보기, 색상 변경 pill, 코드/이름 입력 카드, 시작/종료 시간 카드, 취소/primary pill 저장 액션으로 재구성했다. 코드는 최대 2자와 대문자로 제한하고 입력 즉시 미리보기에 반영한다. 기존 색상/시간 선택, 시간 동시 삭제·검증, 추가/수정 요청 반환 동작은 유지했다.
  - 영향범위: 근무 패턴 설정에서 진입하는 근무 타입 추가·편집 페이지 UI. Behavior change: 코드 입력이 시안 기준 최대 2자로 제한되고 원형 미리보기가 실시간 갱신된다. API 요청 DTO, Provider, DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 전용 위젯 테스트 4건(컴팩트 카드/96px 미리보기, 2자 대문자 동기화, 시간 동시 삭제, 수정 요청 계약) 통과. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: 근무 타입 폼의 새 레이아웃과 관련 테스트·문서 기록을 제거하고 기존 `CupertinoListSection` 기반 화면으로 복원한다.
  - 다음: 실제 iOS 기기에서 키보드, 색상/시간 선택 시트, 작은 화면 스크롤을 확인한다.

- [DONE] (CHORE) Stage/Center API 기본 URL 변경
  - 목적: Flutter 디버그 빌드는 Stage API, 릴리스 빌드는 Center 운영 API에 연결한다.
  - 변경: `ApiConstants.base_url_dev`를 `https://stage-api.shiftmate.co.kr/api/v1`, `base_url_prod`를 `https://api.shiftmate.co.kr/api/v1`로 변경했다. 기존 `kDebugMode` 분기와 `ApiClient.createDio()`의 `BaseOptions.baseUrl` 연결은 유지하고, 프로젝트 컨텍스트의 빌드 모드별 API URL 정책도 같은 값으로 갱신했다.
  - 영향범위: 디버그·릴리스 모드의 모든 Dio API 요청 대상. Behavior change: 디버그 빌드는 개발/Stage API, 릴리스 빌드는 운영/Center API로 요청한다. API 엔드포인트, 인증, DTO, DB 구조는 변경하지 않는다.
  - 파일: `lib/core/constants/api_constants.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format` 0개 변경, `flutter analyze --no-fatal-infos lib/core/constants/api_constants.dart` exit 0 및 error/warning 0건, 새 URL 문자열과 `ApiClient.createDio()` 연결 직접 대조, `git diff --check` 통과. 프로젝트 snake_case 규칙과 Flutter 기본 lint가 충돌하는 기존 naming info 25건은 확인했으며 이번 URL 변경 범위에서는 유지했다.
  - 롤백: `base_url_dev`를 `http://172.30.1.49:3000/api/v1`, `base_url_prod`를 `https://www.shiftmate.co.kr/api/v1`로 되돌리고 프로젝트 컨텍스트의 URL 정책을 함께 복원한다.
  - 다음: 실제 Debug/Release 빌드에서 각 도메인의 TLS 및 API 응답을 확인한다.

- [DONE] (FIX) 선택일 일정·근무 설정 헤더 통일
  - 목적: 일정 리스트와 근무 설정 카드의 선택 날짜 헤더가 같은 위치·간격·타이포·공휴일 표시를 사용하도록 맞춘다.
  - 변경: 일정 카드의 기존 전용 헤더를 trailing 위젯을 받을 수 있는 공용 `CalendarScheduleHeader`로 전환했다. 일정 카드와 근무 설정 카드가 모두 16px 수평·12px 수직 padding, 36px 콘텐츠 슬롯, 같은 날짜/공휴일 타이포와 0.5px 하단 구분선을 사용한다. 근무 설정의 완료 버튼은 같은 헤더 trailing에 두고, 근무 설정에도 `KoreanHolidays`의 선택일 공휴일명을 전달한다. 근무 타입 그리드와 안내 문구의 12px padding은 헤더 아래 본문으로 한정했다.
  - 영향범위: 메인 캘린더 하단 일정 카드와 근무 설정 카드의 헤더 UI. Behavior change: `+` 버튼 전후 선택 날짜의 좌표와 헤더 크기가 유지되고, 근무 설정 헤더에도 공휴일명과 구분선이 표시된다. 근무 선택·저장 API 및 DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/calendar_schedule_card.dart`, `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 신규 헤더 위치·공휴일 테스트 단독 실행 통과, 변경 코드/테스트 대상 `flutter analyze` 0건, `dart format` 및 `git diff --check` 통과. 캘린더 페이지 전체 테스트에서는 신규 테스트와 기존 크기·자동 이동 등 8건이 통과했고, 작업 시작 전부터 존재한 사용자 변경인 선택 배경 primary 8% tint와 기존 surface 기대값 불일치 1건은 범위 밖 변경을 보존해 그대로 남겼다.
  - 롤백: 공용 헤더 적용과 관련 테스트·문서 변경을 제거하고 기존 개별 헤더 구현으로 되돌린다.
  - 다음: 실제 기기에서 일정 카드와 근무 설정 카드의 날짜·공휴일·구분선·완료 버튼 정렬을 확인한다.

- [DONE] (FIX) iOS `Pods_Runner` 프레임워크 링크 오류 해결
  - 목적: iPhone 앱 빌드에서 `Framework 'Pods_Runner' not found`와 `Linker command failed with exit code 1`이 발생하는 원인을 재현하고 정상 빌드 상태로 복구한다.
  - 변경: Xcode workspace 빌드 로그와 생성된 framework 경로를 대조해 `Pods_Runner.framework` 자체는 정상 생성되지만, 이전 Flutter 빌드가 남긴 `Generated.xcconfig`의 고정 `CONFIGURATION_BUILD_DIR` 때문에 Runner와 Pods 산출물 경로가 달라지는 것을 확인했다. `flutter clean` → `flutter pub get` → `pod install --deployment`으로 생성 설정과 workspace를 재동기화했다. 별도로 CocoaPods가 경고한 Profile base configuration 누락은 `ios/Flutter/Profile.xcconfig`를 추가하고 Runner/Profile이 이를 사용하도록 연결해 해소했다. Xcode는 `Runner.xcworkspace`를 열고, 동일 오류 재발 시 생성 설정을 재동기화하는 규칙을 프로젝트 컨텍스트에 기록했다.
  - 영향범위: iOS Runner의 CocoaPods 의존성 링크, Debug/Profile 로컬 iPhone 빌드와 빌드 운영 문서. Flutter 화면/API/DB 동작은 변경하지 않는다.
  - 파일: `ios/Flutter/Profile.xcconfig`, `ios/Runner.xcodeproj/project.pbxproj`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: CocoaPods 1.16.2에서 `pod install --deployment` 성공 및 base configuration 경고 제거, `Podfile.lock`/`Pods/Manifest.lock` 일치 확인. Xcode 16.2의 `Runner.xcworkspace`에서 Debug 및 Profile iPhone generic 대상 무서명 빌드가 모두 성공해 `Pods_Runner` 링크 오류 제거를 확인했다. `flutter analyze --no-fatal-warnings --no-fatal-infos`는 error 0건으로 통과했으며 이번 범위 밖 기존 warning/info 126건을 확인했다. `git diff --check` 통과.
  - 롤백: Runner/Profile base configuration을 `Flutter/Release.xcconfig`로 되돌리고 `ios/Flutter/Profile.xcconfig` 및 iOS 빌드 문서 기록을 제거한다. 로컬 생성 설정은 다시 `flutter clean`, `flutter pub get`, `pod install --deployment` 순서로 복원한다.
  - 다음: Xcode에서 `ios/Runner.xcworkspace`를 열어 실제 연결 iPhone에 서명·설치하고 앱 실행을 확인한다.

- [DONE] (FIX) 일정 카드와 근무 설정 카드 크기 일치
  - 목적: 메인 캘린더에서 `+` 버튼 전후 달력의 표시 형식과 높이를 유지해 선택일 일정 카드와 근무 설정 카드가 같은 외부 크기를 사용하도록 한다.
  - 변경: 근무 설정 전용 60px 행 높이와 월/확장 보기 강제 전환·복원 상태를 제거했다. 근무 설정은 진입 전 월/2주/주 형식과 확장 52/56px 또는 compact 48px 행 높이를 유지하며, compact 상태에서는 기존 marker로 근무를 표시한다. 하단 슬롯을 loose `Flexible`에서 tight `Expanded`로 바꿔 일정 카드와 근무 설정 카드가 동일한 외부 크기를 사용하도록 했다. 두 카드에 회귀 테스트용 key를 추가하고 390x740 compact 및 390x800 2주 보기에서 형식·행 높이·카드 크기를 비교하는 테스트를 추가했다.
  - 영향범위: 메인 캘린더의 근무 설정 진입/종료 시 달력 형식·행 높이와 하단 카드 크기. Behavior change: 일정이 적거나 없어도 선택일 일정 카드가 남은 하단 영역을 채우며, 근무 설정 진입 시 월/60px 확장 보기로 강제 전환하지 않는다. 근무 선택·저장 API와 데이터 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 변경 전 신규 테스트는 740px에서 행 높이 52→60, 800px에서 56→60 차이로 실패해 원인을 재현했다. 변경 후 신규 크기 회귀 테스트 2건과 근무 타입 그리드 테스트 2건이 통과했고, 대상 코드/테스트 `flutter analyze` 0건을 확인했다. 캘린더 페이지 전체 테스트는 이번 변경 관련 테스트를 포함해 7건 통과했으며, 작업 시작 전부터 존재한 사용자 변경인 선택 배경색 primary 8% tint와 기존 surface 기대값 불일치 1건은 범위 밖 변경을 보존하기 위해 수정하지 않았다.
  - 롤백: 하단 슬롯을 `Flexible`로 되돌리고 근무 설정 진입 시 월/확장 보기, 60px 행 높이와 종료 시 복원 상태를 다시 적용한 뒤 관련 테스트·문서와 ADR-0007을 제거한다.
  - 다음: 실제 750px 전후 기기에서 일정 없음/다수 상태와 compact/월/2주/주 상태의 `+` 전후 카드 크기 및 marker 가독성을 확인한다.

- [DONE] (CHORE) 릴리스 API 기본 URL 변경
  - 목적: Flutter 릴리스 빌드의 모든 API 요청 대상을 운영 도메인 `https://www.shiftmate.co.kr`로 변경한다.
  - 변경: `ApiConstants.base_url_prod`를 `https://www.shiftmate.co.kr`로 변경했다. 기존 `kDebugMode` 분기와 Dio `BaseOptions.baseUrl` 연결은 유지하고, 빌드 모드별 API URL 정책을 프로젝트 컨텍스트에 기록했다.
  - 영향범위: 릴리스 모드의 모든 Dio API 요청 대상. Behavior change: 릴리스 요청은 기존 `https://shiftmate.co.kr/api/v1` 대신 `https://www.shiftmate.co.kr`에 상대 엔드포인트를 결합한다. 디버그 모드의 개발 API 주소는 변경하지 않는다.
  - 파일: `lib/core/constants/api_constants.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format --set-exit-if-changed` 통과. 변경 파일 대상 `flutter analyze --no-fatal-infos`는 error/warning 0건으로 통과했고 프로젝트 snake_case 규칙과 Flutter 기본 lint가 충돌하는 기존 naming info 25건만 확인했다. 운영 상수값과 `ApiClient.createDio()` 연결을 직접 대조했으며 `git diff --check`도 통과했다.
  - 롤백: `base_url_prod`를 기존 `https://shiftmate.co.kr/api/v1`로 되돌리고 관련 문서 기록을 제거한다.
  - 다음: 실제 릴리스 빌드에서 운영 도메인의 API 라우팅과 TLS 연결을 확인한다.

## 2026-07-16

- [DONE] (CHORE) 친구 추가 모달 개선 작업 커밋 및 푸시
  - 목적: 완료된 키보드/애니메이션/오버플로, 헤더 비율, 검증 말풍선 개선을 코드·테스트·문서와 함께 Git 이력으로 정리해 원격 `main`에 반영한다.
  - 변경: 친구 추가 모달 코드, 전용 위젯 테스트, 프로젝트 컨텍스트/기능 설계/작업 로그를 `1119b9f fix(friend): polish add friend modal interactions`로 커밋했다. 이 완료 기록을 후속 문서 커밋으로 생성하고 두 커밋을 `origin/main`에 푸시한다.
  - 영향범위: Git 이력과 원격 `main` 브랜치. 런타임 동작은 완료된 친구 추가 모달 변경과 동일하다.
  - 파일: 친구 추가 모달 관련 코드·테스트·문서와 `_docs/WORKLOG.md`
  - 테스트: 친구 추가 모달 위젯 테스트 5건 통과, 대상 `flutter analyze` 0건, `dart format`, `git diff --check`, `git diff --cached --check` 통과
  - 롤백: 원격 반영 후 필요 시 생성 커밋을 `git revert`하고 푸시한다.
  - 다음: 실제 iOS 기기에서 키보드 외부 터치, 검색 직후 시트 전환, 헤더 비율, 검증 말풍선 오버레이를 최종 확인한다.

- [DONE] (FIX) 친구 추가 검증 말풍선 오버레이 전환
  - 목적: 빨간 검증 말풍선 표시 시 검색 결과 안내 문구가 아래로 밀리지 않도록 말풍선을 검색 행 위에 오버레이로 그린다.
  - 변경: 검증 말풍선을 검색 영역 `Column`의 일반 자식에서 제거했다. 검색 행에 `CompositedTransformTarget`을 두고 모달 최상위 `Stack`의 후순위 `CompositedTransformFollower`로 말풍선을 연결해 결과 영역 위에 그리며, `IgnorePointer`로 검색 결과 상호작용을 방해하지 않게 했다. 기존 합산 구조였던 헤더 높이는 `_headerHeight = 66` 단일 상수와 고정 `SizedBox`로 정리해 설정 위치를 명확히 했다. 현재 취소 14px/제목 16px 스타일과 44px 터치 영역은 유지했다.
  - 영향범위: 친구 추가 모달의 로컬 입력 검증 말풍선 배치와 헤더 높이 상수화. Behavior change: 말풍선 표시 전후 검색 안내/결과 위치가 고정된다. 검색 API, 키보드, 시트 드래그 동작은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `test/features/friend/presentation/widgets/add_friend_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/WORKLOG.md`
  - 테스트: 검증 메시지 표시 전후 결과 안내 Y좌표가 동일하고 말풍선이 `CompositedTransformFollower`에 속하는 신규 테스트 1건과 기존 헤더/키보드/오버플로 테스트 4건 등 총 5건 통과. 대상 코드/테스트 `dart format` 통과, 대상 `flutter analyze` 0건, `git diff --check` 통과.
  - 롤백: 말풍선을 검색 영역 `Column`의 일반 자식으로 되돌리고 헤더 단일 높이 상수와 관련 테스트·문서를 제거한다.
  - 다음: 실제 iOS 기기에서 빈 값/잘못된 형식 말풍선이 검색 결과 안내 위에 표시되고 안내 위치가 유지되는지 확인한다.

- [DONE] (FE) 친구 추가 모달 헤더 비율 축소
  - 목적: 친구 추가 모달의 헤더 제목과 상하 여백을 검색 안내·입력 요소의 크기와 균형이 맞도록 축소한다.
  - 변경: 기존 헤더의 16px 사방 여백과 20px `heading_small` 제목을 핸들 포함 66px 고정 높이, 16px `body_large` 타이포로 조정했다. 취소는 w600, 제목은 w700을 사용하고 44px 최소 터치 영역을 유지했다. `Stack`과 중앙 정렬을 사용해 취소 버튼 너비와 관계없이 제목이 시트 정중앙에 놓이도록 했다.
  - 영향범위: 친구 추가 모달 상단 드래그 핸들 아래의 취소 액션, 제목 타이포, 헤더 높이. Behavior change: 헤더의 시각적 높이와 제목 크기가 축소된다. 검색/키보드/드래그/API 동작은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `test/features/friend/presentation/widgets/add_friend_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/WORKLOG.md`
  - 테스트: 1.1176배 텍스트에서 헤더 66px 높이와 16px 제목을 검증하는 신규 위젯 테스트 1건 및 기존 키보드/오버플로 회귀 테스트 3건 등 총 4건 통과. 대상 코드/테스트 `dart format` 통과, 대상 `flutter analyze` 0건, `git diff --check` 통과.
  - 롤백: 헤더의 기존 16px 사방 여백과 `heading_small` 제목 스타일로 되돌리고 관련 테스트·문서를 제거한다.
  - 다음: 실제 iOS 기기에서 축소된 헤더와 검색 설명/입력 영역의 비율, 취소 터치 영역과 제목 정중앙 배치를 확인한다.

- [DONE] (FIX) 친구 추가 모달 키보드 해제·검색 전환 버벅임·세로 오버플로 수정
  - 목적: 친구 추가 모달에서 키보드 외부 터치 시 포커스를 해제하고, 검색 후 전환 애니메이션의 버벅임 원인과 3.4px 세로 오버플로를 확인해 안정적으로 수정한다.
  - 변경: 검색창과 검색 버튼을 `TapRegion`으로 묶어 외부 터치 시 검색 `FocusNode`를 해제했다. 시트 높이를 `min(사용자 선택 높이, 화면-키보드-상단 여백)`으로 제한하고 키보드가 표시되는 프레임에는 별도 220ms 보간을 제거했다. 기존 구현은 키보드 `viewInsets`가 닫힘 애니메이션 중 감소할수록 시트를 남은 공간 전체(테스트에서 676.48px)로 확장한 뒤 기본 높이(573.92px)로 다시 축소하고, `AnimatedPadding`과 `AnimatedContainer`가 이미 애니메이션 중인 inset을 재보간해 검색 직후 버벅임을 만들었다. 검색 전·오류·결과 없음 안내는 가용 높이보다 커질 때 스크롤되도록 변경해 확대 텍스트에서 발생한 RenderFlex 오버플로를 제거했다. DebugMCP는 Flutter 테스트 대신 잘못된 npm 디버그 구성으로 종료되어 중단점을 잡지 못했고 즉시 세션과 중단점을 정리한 뒤 위젯 렌더 테스트의 실제 높이/예외로 원인을 검증했다.
  - 영향범위: 친구 추가 모달의 포커스/키보드 처리, 검색 상태 전환 시트 높이, 좁은 결과 영역의 안내 표시. 친구 검색 API/DB 계약과 친구 요청 상태는 변경하지 않는다. Behavior change: 검색창 밖 터치로 키보드가 닫히며 키보드 닫힘 중 시트가 기본 높이 이상으로 튀지 않는다.
  - 파일: `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `test/features/friend/presentation/widgets/add_friend_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/WORKLOG.md`
  - 테스트: 큰 키보드·1.1176배 텍스트 오버플로 방지, 외부 터치 포커스 해제, 키보드 닫힘 중 기본 높이 상한 등 신규 위젯 테스트 3건 통과. 대상 코드/테스트 `dart format` 통과, 대상 `flutter analyze` 0건, `git diff --check` 통과.
  - 롤백: `TapRegion`, 시트 높이 상한/키보드 직접 반영, 스크롤 가능한 안내 레이아웃과 신규 테스트·문서 기록을 함께 제거하고 기존 이중 애니메이션 계산으로 되돌린다.
  - 다음: 실제 iOS 기기에서 키보드 외부 터치, 검색 버튼/엔터 검색 직후 시트 이동, 큰 텍스트 접근성 설정의 안내 스크롤을 확인한다.

- [DONE] (CHORE) 캘린더 공용화·공휴일 캐시 변경사항 커밋 및 푸시
  - 목적: 완료된 메인·친구 캘린더 공용 위젯 리팩토링과 공휴일 로컬 캐시 변경을 검증된 문서·테스트와 함께 Git 이력으로 정리해 원격 저장소에 반영한다.
  - 변경: 기존 미푸시 공휴일명 위치 수정 커밋 `b3dd26a fix: location holiday name`을 보존했다. 캘린더 공용 위젯 추출, 이벤트 날짜 매핑 공통화, 공휴일 영속 캐시와 친구 캘린더 표시, 테스트·문서를 `2391888 refactor(calendar): share views and persist holidays`로 생성하고 두 기능 커밋을 `origin/main`에 푸시했다. 이 완료 기록은 후속 문서 커밋으로 원격에 반영한다.
  - 영향범위: Git 이력과 원격 `main` 브랜치. 런타임 동작은 완료된 캘린더 변경과 동일하다.
  - 파일: 캘린더 공용화·공휴일 캐시 관련 코드와 테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 이벤트 날짜 매핑 2건, 공휴일 저장·복원 1건, 메인 캘린더 6건, 친구 캘린더 4건으로 총 13건 통과. 변경 대상 11개 Dart 파일 `flutter analyze` 0건, `dart format --set-exit-if-changed`, `git diff --check`, `git diff --cached --check` 통과.
  - 롤백: 원격 반영 후 필요 시 생성 커밋을 `git revert`하고 푸시한다.
  - 다음: 실제 기기에서 공용 월 렌더링과 앱 재실행 후 공휴일 캐시 복원을 확인한다.

- [DONE] (FE) 공휴일 API 로컬 캐시와 전체 캘린더 공유
  - 목적: 앱에서 조회한 공휴일 API 데이터를 로컬에 보존하고 메인·친구 일정 조회 캘린더가 동일한 공휴일 데이터와 표시 규칙을 사용하도록 한다.
  - 변경: `KoreanHolidays`가 요청 월 앞뒤 1개월의 API 결과를 실제 날짜 연도별 메모리에 병합하고 날짜·이름·조회 완료 월을 `SharedPreferences`의 버전 1 JSON으로 저장하도록 변경했다. 동일 월 동시 요청은 하나의 Future를 공유한다. `main.dart`에서 앱 시작 시 이전 캐시를 복원하고, 메인 페이지의 중복 `_holidays` 캐시를 제거해 공용 소스만 참조한다. 친구 캘린더도 진입·월 이동·오늘 복귀 시 공용 캐시를 조회하며 공휴일을 accent red로 표시하고 선택일 카드에 공휴일명을 노출한다. ADR-0006과 프로젝트 컨텍스트에 캐시 수명주기·파일 역할·표시 규칙을 기록했다.
  - 영향범위: 공휴일 API 캐시 수명주기, 앱 초기화, 메인·친구 캘린더의 공휴일 표시, 관련 테스트와 아키텍처 문서. Behavior change: 친구 일정 조회 달력에도 공휴일 색상과 이름이 표시되며, 조회 완료 월은 앱 재시작 후에도 API를 다시 호출하지 않는다. 일정/근무 API 및 DB 공개 범위 계약은 변경하지 않는다.
  - 파일: `lib/core/utils/korean_holidays.dart`, `lib/main.dart`, `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/core/utils/korean_holidays_test.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 로컬 저장·재시작 복원 단위 테스트 1건, 친구 캘린더 공휴일 표시 포함 위젯 테스트 4건, 메인 캘린더 회귀 테스트 6건으로 총 11건 통과. 변경 대상 코드/테스트 7개 파일 `flutter analyze` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: `main.dart`의 캐시 초기화와 `KoreanHolidays`의 SharedPreferences 직렬화·복원 코드를 제거하고, 친구 화면의 월별 공휴일 조회/표시 연결을 제거한 뒤 메인 페이지의 기존 페이지 전용 공휴일 캐시를 복원한다. 기존 로컬 키 `korean_holidays_cache_v1`은 남아도 이전 코드에서 읽지 않는다.
  - 다음: 실제 기기에서 최초 API 조회 후 앱을 완전히 종료·재실행하고 네트워크 없이 메인·친구 달력의 공휴일 색상과 이름이 유지되는지 확인한다. 임시공휴일 갱신 요구가 생기면 ADR-0006의 후속 과제로 TTL 또는 수동 새로고침 정책을 추가한다.

- [DONE] (REFACTOR) 메인·친구 캘린더 공용 표시 코드 추출
  - 목적: 메인 캘린더와 친구 일정 조회 캘린더의 중복 구현을 실제 동작 기준으로 비교하고, 동일한 날짜 셀·선택일 일정 표시 규칙을 공용 위젯으로 추출한다.
  - 변경: 두 페이지에 중복된 월 헤더, `TableCalendar` 설정, 날짜 의미 색상·오늘 밑줄·근무 코드 배지·선택 사각형 렌더링을 `CalendarMonthView`로 추출했다. 선택일 카드의 날짜/공휴일/일정 수 헤더, 근무/개인 일정 행, 빈 상태는 `CalendarScheduleCard`로 추출했다. 메인은 compact marker, 근무 편집/삭제, 개인 일정 추가 footer를 주입하고 친구 화면은 읽기 전용 기본 행을 사용한다. 문서/테스트와 달랐던 선택 배경을 두 화면 모두 흰색 surface로 복구하고 공휴일명 행을 하단 정렬했다. 이벤트 날짜별 매핑은 `addEventToCalendarDateMap()`으로 공통화해 친구 화면도 자정인 exclusive 종료일을 제외하고 일정 ID 중복 제거·시작 시각 정렬을 적용한다.
  - 영향범위: 메인·친구 캘린더의 월 헤더, 날짜 셀, 선택일 일정 카드와 이벤트 날짜별 매핑. 메인 근무 입력/저장/삭제, 개인 일정 추가, 공휴일 조회와 친구 조회/공개 필터링 API는 기존 페이지 책임으로 유지한다. 선택 surface 복구와 친구 종일 일정 종료일 중복 제거는 문서화된 기존 계약에 맞춘 동작 수정이다.
  - 파일: `lib/features/calendar/data/models/event_api_model.dart`, `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/calendar/presentation/widgets/calendar_month_view.dart`, `lib/features/calendar/presentation/widgets/calendar_schedule_card.dart`, `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/calendar/data/models/event_api_model_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 변경 대상 8개 코드/테스트 파일 `flutter analyze` 0건, 이벤트 매핑 2건·메인 캘린더 6건·친구 캘린더 3건 총 11건 통과, `dart format` 및 `git diff --check` 통과. 전체 `flutter analyze`는 이번 범위 밖 기존 warning/info 134건을 확인했고, 전체 `flutter test`는 관련 테스트를 포함해 27건 통과 후 기존 `test/widget_test.dart`의 `ProviderScope` 누락 및 현재 앱과 무관한 카운터 기대값으로 1건 실패했다.
  - 롤백: 두 페이지의 `CalendarMonthView`/`CalendarScheduleCard` 사용을 기존 로컬 렌더링으로 되돌리고 `event_api_model.dart` 공용 매핑 함수와 전용 테스트를 제거한다. 선택 배경을 되돌릴 경우 문서/기존 테스트와 다시 불일치한다.
  - 다음: 실제 기기에서 메인 compact/근무 입력 모드와 친구 읽기 전용 화면의 월 이동, 긴 장소 말줄임, 종일 일정 종료일 표시를 확인한다.

- [DONE] (FE) 메인 캘린더 공휴일명 하단 정렬
  - 목적: 날짜 오른쪽으로 이동한 공휴일명의 상하 위치를 날짜 영역 하단에 맞춘다.
  - 변경: 날짜와 공휴일명을 담는 내부 `Row`에 `CrossAxisAlignment.end`를 적용해 공휴일 라벨을 날짜 영역 하단에 정렬했다. 내부 행에 테스트 key를 추가하고 회귀 테스트가 하단 정렬값을 검증하도록 보강했으며 프로젝트 문서의 표시 위치를 `날짜 오른쪽 하단`으로 갱신했다.
  - 영향범위: 메인 캘린더 선택일 헤더의 날짜·공휴일명 내부 행 수직 정렬. 헤더 전체 높이, 오른쪽 일정 수, 공휴일 로딩/판단과 일정 데이터는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 코드/테스트 `dart format` 통과, 대상 2개 파일 `flutter analyze` 0건 통과, 헤더 행 회귀 테스트 1건 통과, `git diff --check` 통과.
  - 롤백: 공휴일명 영역의 하단 정렬 설정을 제거한다.
  - 다음: 실제 기기에서 날짜보다 작은 공휴일 라벨이 의도한 하단 위치에 표시되는지 확인

- [DONE] (FE) 메인 캘린더 공휴일명 위치 조정
  - 목적: 선택일 날짜·일정 수 헤더의 높이가 공휴일 유무에 따라 달라지지 않도록 공휴일명을 다른 위치로 이동한다.
  - 변경: 선택일 카드 헤더에서 날짜 아래에 조건부로 추가하던 공휴일명 두 번째 줄을 제거하고, 날짜 오른쪽의 한 줄 accent red 라벨로 이동했다. 날짜·공휴일명 영역을 `Expanded`로 두고 공휴일명에는 한 줄 말줄임을 적용해 오른쪽 `N개의 일정`을 유지한다. 날짜와 일정 수가 동일한 헤더 행과 세로 위치에 배치되는 위젯 테스트를 추가하고 현재 표시 규칙을 프로젝트 문서에 반영했다.
  - 영향범위: 메인 캘린더 선택일 일정 카드의 공휴일명 위치와 헤더 높이. 공휴일 로딩/판단, 날짜 셀 색상, 근무·개인 일정 목록과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 코드/테스트 `dart format` 통과, 대상 2개 파일 `flutter analyze` 0건 통과, 신규 헤더 행 회귀 테스트 1건 통과, `git diff --check` 통과. 변경 전 전체 `calendar_page_test.dart` 실행에서는 이번 작업과 무관하게 선택 사각형 배경의 기존 테스트 기대값(surface)과 구현값(primary 8% tint)이 달라 1건 실패하는 상태를 확인했다.
  - 롤백: 변경된 공휴일명 배치를 기존 날짜 헤더 아래 위치로 되돌린다.
  - 다음: 실제 기기에서 긴 공휴일명과 일정 수가 함께 표시될 때 말줄임과 헤더 높이를 확인

- [DONE] (CHORE) 캘린더 날짜 상호작용 변경사항 커밋 및 푸시
  - 목적: 완료된 2주 보기 자동 이동 수정과 선택일·주말·공휴일 색상 구분 개선을 검증된 문서·테스트와 함께 Git 이력으로 정리해 원격 `main`에 반영한다.
  - 변경: 캘린더 코드, 회귀 테스트, PROJECT_CONTEXT/DECISIONS/WORKLOG 변경을 `14be245 fix(calendar): improve date selection interactions` 기능 커밋으로 정리했다. 이 작업 로그의 완료 상태는 후속 문서 커밋으로 기록하고 두 커밋을 `origin/main`에 푸시한다.
  - 영향범위: Git 이력과 원격 `main` 브랜치. 런타임 동작은 현재 검증된 작업 트리와 동일하다.
  - 파일: 현재 캘린더 관련 변경 전체와 `_docs/WORKLOG.md`
  - 테스트: 메인 캘린더 5건·친구 캘린더 3건 전체 통과, 변경 대상 `flutter analyze` 0건, 기능 커밋 전 `git diff --cached --check` 통과
  - 롤백: 원격 반영 후 필요 시 생성 커밋을 `git revert`하고 푸시한다.
  - 다음: 후속 작업 로그 커밋 생성 후 원격 `main` 푸시

- [DONE] (FE) 캘린더 선택일과 주말·공휴일 색상 구분 개선
  - 목적: 선택일의 primary 글자색이 토요일 색상과 같고 공휴일의 빨간색을 덮어쓰는 문제를 해결해 날짜 의미와 선택 상태를 동시에 식별할 수 있게 한다.
  - 변경: 메인·친구 캘린더가 선택일/오늘의 날짜 글자색을 무조건 primary로 덮어쓰던 로직을 제거했다. 토요일은 primary blue, 일요일과 메인 캘린더 공휴일은 accent red를 선택 후에도 유지하며, 선택 상태는 흰색 surface 배경과 2px primary dark outline, 굵은 글씨로 분리했다. 기존 선택 박스 크기·오프셋·180ms 애니메이션과 오늘 밑줄은 유지했다. 선택된 토요일/일요일의 의미 색상과 선택 배경·테두리를 메인·친구 캘린더 위젯 테스트로 고정하고, ADR-0005와 프로젝트 컨텍스트에 시각 상태 분리 정책을 기록했다. 이전 문서에 남아 있던 양쪽 주말 빨간색 규칙도 현재 구현에 맞게 토요일 primary blue/일요일 red로 정정했다.
  - 영향범위: 메인 캘린더와 친구 캘린더의 날짜 셀 선택 스타일, 관련 위젯 테스트와 UI 정책 문서. 날짜 선택 동작, 근무/개인 일정 데이터, API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 코드/테스트 `dart format` 통과, 대상 4개 파일 `flutter analyze` 0건 통과, `calendar_page_test.dart` 5건과 `friend_calendar_page_test.dart` 3건 전체 통과, `git diff --check` 통과
  - 롤백: 날짜 셀의 선택 시 의미 색상 유지와 surface/2px outline을 기존 primary 글자색 및 8% tint/24% outline으로 되돌리고 관련 테스트·문서를 제거한다.
  - 다음: 실제 기기에서 선택된 평일·토요일·공휴일의 2px outline 무게와 날짜 의미 색상 가독성 확인

## 2026-07-15

- [DONE] (FIX) 2주 보기 근무 입력 다음 날짜 자동 이동 동기화
  - 목적: 2주 보기의 두 번째 주 토요일에서 근무를 선택하면 다음 일요일 선택 상태와 달력 표시 페이지가 함께 이동하도록 수정한다.
  - 변경: `_moveToNextDay()`가 다음 날의 월 변경 여부와 관계없이 `_selected_day`와 `_focused_day`를 함께 갱신하도록 변경했다. `table_calendar`가 변경된 focused day로 2주 페이지를 계산해 페이지 경계에서 다음 화면으로 애니메이션 이동한다. 캘린더·공휴일 데이터 로딩은 `setState` 밖에서 기존과 동일하게 월이 바뀔 때만 실행한다. 2주 페이지의 마지막 토요일을 동적으로 계산해 다음 일요일의 focused day, 선택 predicate, 렌더 셀을 검증하는 영구 위젯 테스트를 추가했다.
  - 영향범위: 메인 캘린더 근무 추가 모드의 날짜 자동 이동과 관련 위젯 테스트. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 신규 회귀 테스트 1건 단독 통과, `calendar_page_test.dart` 전체 5건 통과, 대상 코드/테스트 `flutter analyze` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: `_moveToNextDay()`의 focused day 동기화와 회귀 테스트·문서 변경을 되돌린다.
  - 다음: 실제 작은 화면 기기에서 두 번째 토요일 입력 후 다음 페이지 애니메이션과 연속 근무 입력 감각 확인

- [DONE] (INVESTIGATION) 2주 보기 근무 입력 자동 이동 불일치 진단
  - 목적: 작은 화면의 2주 보기에서 두 번째 주 토요일 근무를 선택한 뒤 선택일은 다음 날로 바뀌지만 달력 표시 구간이 따라가지 않는 원인을 확인하고 수정 방향을 정한다.
  - 변경: `_moveToNextDay()`는 다음 날이 `_focused_day`와 다른 월일 때만 `_focused_day`를 변경하고 있었다. 반면 `table_calendar` 3.2.0의 2주 보기는 `focusedDay`를 기준으로 14일 단위 페이지 인덱스를 계산하고, `focusedDay` 입력이 바뀌어야 내부 `PageController`를 해당 페이지로 이동한다. 따라서 같은 달 안에서 2주 페이지 경계만 넘으면 `_selected_day`만 다음 날로 바뀌고 달력 페이지는 그대로 남는 것이 직접 원인이다. 수정 시 `_selected_day`와 `_focused_day`를 항상 다음 날로 함께 갱신하고, API/공휴일 로딩만 기존처럼 월 변경 시 실행하는 방향이 가장 작고 형식 독립적이다. `pageJumpingEnabled`는 날짜 탭에만 적용되므로 이 자동 이동 문제의 해결책이 아니다.
  - 영향범위: 조사 및 문서화만 수행하며 런타임 코드는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/WORKLOG.md`
  - 테스트: 임시 위젯 테스트에서 390x740 2주 보기의 두 번째 토요일에 근무를 입력하면 선택일 헤더는 다음 일요일로 바뀌지만 `TableCalendar.focusedDay`는 기존 값이고 다음 일요일 셀이 렌더 트리에 없는 현상을 재현했다. 임시 테스트는 조사 후 제거했다. 기존 `calendar_page_test.dart` 4건 통과, 대상 코드/테스트 `flutter analyze` 0건.
  - 롤백: 이 조사 기록을 제거한다.
  - 다음: `_moveToNextDay()`에서 두 날짜 상태를 함께 갱신하고 같은 달의 2주 경계, 월 경계, 페이지 내부 이동을 검증하는 영구 회귀 테스트를 추가

- [DONE] (CHORE) 완료된 캘린더 변경사항 커밋 및 푸시
  - 목적: 현재 작업 트리에서 완료된 캘린더 피커, 메인/친구 캘린더 UI 및 반응형 2주 보기 변경을 목적별 커밋으로 정리해 원격 저장소에 반영한다.
  - 변경: 기존 staging 경계를 보존해 `36f6c31 feat(calendar): polish calendar and picker UI`, `cfc9a55 feat(calendar): refine responsive calendar layouts` 커밋을 생성하고 `origin/main`에 푸시했다.
  - 영향범위: Git 이력과 원격 `main` 브랜치. 런타임 동작은 현재 검증된 작업 트리와 동일하다.
  - 파일: 현재 staged/unstaged 캘린더 관련 변경 전체와 `_docs/WORKLOG.md`
  - 테스트: 캘린더/피커 및 관련 유틸 테스트 23건 통과, 변경 대상 `flutter analyze` 0건, `git diff --check` 통과. 전체 `flutter test`에서는 현재 Riverpod 구조와 맞지 않는 기존 `test/widget_test.dart` 카운터 템플릿 1건이 `ProviderScope` 누락으로 실패했으며 이번 범위에서는 수정하지 않았다.
  - 롤백: 원격 반영 후 필요 시 생성된 커밋을 `git revert`하고 푸시한다.
  - 다음: 기존 `test/widget_test.dart`를 현재 앱 구조에 맞는 스모크 테스트로 교체

- [DONE] (FE) 750px 미만 친구 캘린더 2주 보기 고정
  - 목적: 메인 캘린더와 동일하게 작은 화면의 친구 캘린더도 2주 범위만 표시해 읽기 전용 일정 영역을 확보한다.
  - 변경: `FriendCalendarPage`에 `MediaQuery` 화면 높이 판별 getter와 실제 표시용 `CalendarFormat` getter를 추가했다. 750px 미만에서는 `CalendarFormat.twoWeeks`, 750px 이상에서는 기존 `CalendarFormat.month`를 `TableCalendar`에 전달하며 행 높이도 같은 판별 결과를 재사용한다. 명시적 `MediaQuery`를 사용하는 740px/750px 경계 테스트를 추가하고 기존 월 보기 레이아웃 회귀 검증은 800px에서 유지했다.
  - 영향범위: 친구 캘린더의 화면 높이별 `CalendarFormat` 선택. 친구 캘린더 API와 공개 범위 규칙은 변경하지 않는다. 750px 미만에서는 월 전체 대신 2주 범위를 표시하는 동작 변경이 있다.
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 친구 캘린더 위젯 테스트 3건 통과. 740px에서 초기 및 다음 기간 이동 후 모두 2주 보기인지, 750px에서 월 보기인지, 800px에서 기존 읽기 전용 일정 카드와 월 레이아웃 회귀가 유지되는지 검증했다. 대상 코드/테스트 `flutter analyze` 0건, `dart format` 통과.
  - 롤백: 친구 캘린더의 화면 높이별 형식 선택 로직과 관련 테스트·문서 기록을 제거한다.
  - 다음: 실제 높이 750px 전후 기기에서 친구 일정 카드의 가용 높이와 2주 기간 이동을 확인

- [DONE] (FE) 750px 미만 화면 메인 캘린더 2주 보기 고정
  - 목적: 세로 공간이 부족한 화면에서 메인 캘린더가 항상 2주 범위만 표시하도록 해 일정 영역을 안정적으로 확보한다.
  - 변경: `MediaQuery` 화면 높이가 750px 미만인지 판별하는 공용 getter와 실제 표시용 `CalendarFormat` getter를 추가했다. 작은 화면에서는 내부 `_calendar_format` 값과 관계없이 `CalendarFormat.twoWeeks`를 `TableCalendar`에 전달하고 형식 변경 콜백도 비활성화해 일반/compact/근무 추가 상태 모두 2주 보기를 유지한다. 750px 이상에서는 기존 `_calendar_format` 상태를 그대로 사용한다. 기존 행 높이 분기도 같은 화면 높이 getter를 재사용한다.
  - 영향범위: 메인 캘린더의 화면 높이별 `CalendarFormat` 선택. 캘린더 API와 데이터 구조는 변경하지 않는다. 750px 미만에서는 월 전체 대신 2주 범위를 표시하는 동작 변경이 있다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: `CalendarPage` 위젯 테스트 4건 통과. 명시적 `MediaQuery` 높이 740px에서 초기 및 compact 전환 후 모두 2주 보기인지, 750px에서 기존 월 보기인지 검증했다. 대상 코드/테스트 `flutter analyze` 0건, `dart format` 통과.
  - 롤백: 화면 높이에 따른 형식 선택 로직과 관련 테스트·문서 기록을 제거한다.
  - 다음: 실제 높이 750px 전후 기기에서 2주 달력과 선택일 일정 영역의 공간 배분을 확인

- [DONE] (FIX) 근무 일정 스와이프 삭제 배경 radius 적용
  - 목적: 근무 일정을 왼쪽으로 부분 스와이프할 때 삭제 배경의 노출된 왼쪽 경계도 12px radius로 보이게 한다.
  - 변경: `_RoundedDeleteDismissible`이 `Dismissible.onUpdate.progress`를 자체 상태로 관리하고 `LayoutBuilder`의 항목 너비와 곱해 실제 노출 폭을 계산하도록 했다. 삭제 배경은 계산된 폭으로 오른쪽 정렬하고 `AppTheme.input_border_radius`를 적용해 부분 스와이프 시에도 현재 보이는 영역의 양쪽 모서리가 둥글게 렌더링된다. 진행률 상태를 근무 일정 항목 내부에 격리해 드래그마다 `CalendarPage` 전체가 다시 빌드되지 않게 했으며, 기존 `confirmDismiss` 삭제 API 및 실패 복원 흐름은 유지했다.
  - 영향범위: 메인 캘린더 선택일 근무 일정의 스와이프 삭제 배경. 삭제 API 계약, 로컬 삭제 상태, 개인 일정 표시는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 390x740 화면에 근무 일정을 렌더링하고 72px 부분 스와이프한 상태에서 삭제 배경 너비가 72px이며 `AppTheme.input_border_radius`가 적용되는지 검증했다. 대상 위젯 테스트 2건 통과, 대상 코드/테스트 `flutter analyze` 0건, `dart format` 통과.
  - 롤백: `_RoundedDeleteDismissible`을 제거하고 근무 일정 항목을 고정 너비 배경의 기존 `Dismissible`로 복구한 뒤 관련 위젯 테스트와 문서 설명을 제거한다.
  - 다음: 실제 기기에서 짧은 드래그와 삭제 임계값 이상 드래그 모두 배경 radius와 아이콘 위치가 자연스러운지 확인

- [DONE] (INVESTIGATION) 근무 일정 스와이프 삭제 배경 radius 확인
  - 목적: 근무 일정을 왼쪽으로 스와이프하기 시작할 때 삭제 배경의 오른쪽만 둥글고 왼쪽 노출 경계는 각져 보이는 원인을 확인하고 수정 방향을 정한다.
  - 변경: 현재 삭제 배경은 항목 전체 너비의 12px radius `Container`이며, Flutter 3.38.5의 `Dismissible`은 이동 중인 앞 카드가 비운 영역만 `_DismissibleClipper`의 직사각형 `ClipRect`로 노출한다. end-to-start 스와이프 초반에는 전체 배경의 오른쪽 모서리만 보이고 왼쪽 radius는 아직 클립 영역 밖에 있어, 노출 영역의 왼쪽 경계가 각지게 보이는 것이 직접 원인이다. 외곽 `ClipRRect` 추가만으로는 내부 이동 경계가 둥글어지지 않는다. 최소 수정안은 전용 근무 일정 항목 위젯에서 `Dismissible.onUpdate.progress`와 항목 너비로 현재 노출 폭을 계산하고, 그 폭을 가진 12px radius 삭제 배경을 오른쪽 정렬하는 것이다. 삭제 API와 `confirmDismiss` 흐름은 유지한다.
  - 영향범위: 조사 및 문서화만 수행. 런타임 코드, 삭제 API, 로컬 상태는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, Flutter SDK `packages/flutter/lib/src/widgets/dismissible.dart`, `_docs/WORKLOG.md`
  - 테스트: 현재 위젯 트리와 Flutter SDK의 `Dismissible.build()`, `_DismissibleClipper.getClip()`, `Dismissible.onUpdate` 계약을 직접 대조했다. 런타임 코드는 변경하지 않아 Flutter 테스트는 실행하지 않았고 `git diff --check`만 확인한다.
  - 롤백: 이 조사 기록을 제거한다.
  - 다음: 위 `근무 일정 스와이프 삭제 배경 radius 적용` 작업에서 구현과 회귀 테스트를 완료했다.

- [DONE] (FIX) 메인 달력 마지막 행 선택 사각형 클리핑 수정
  - 목적: 메인 페이지에서도 offset이 적용된 선택 사각형이 마지막 행에서 잘리지 않도록 한다.
  - 변경: 390x740 화면의 마지막 날짜를 선택했을 때 확장 보기 선택 사각형 하단이 `TableCalendar` 경계보다 4px 내려가는 현상을 재현했다. `CalendarStyle.tablePadding` 하단에 8px을 적용해 확장 보기의 4px offset과 compact 보기의 8px offset을 내부 `PageView` 높이에 포함했다. 일정 카드 앞 외부 간격은 12px에서 4px로 줄여 달력 표 본문부터 카드까지 기존 총 12px을 유지했다. `TableCalendar`에는 명시적 key를 추가해 핫 리로드 시 내부 페이지 높이가 이전 상태로 남지 않게 했다.
  - 영향범위: `CalendarPage`의 달력 선택 표시와 달력 아래 일정 영역 배치.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 수정 전 대상 위젯 테스트에서 확장 보기 선택 박스 하단이 달력 경계 396px보다 아래인 400px로 실패하는 것을 확인했다. 수정 후 캘린더 presentation 테스트 9건과 친구 캘린더 회귀 테스트 1건, 총 10건 통과. 테스트는 확장 보기와 compact 보기에서 현재 월 마지막 날짜의 선택 사각형 하단이 달력 경계 안인지 확인한다. 대상 코드/테스트 `flutter analyze` 0건, `dart format` 및 `git diff --check` 통과.
  - 롤백: `CalendarStyle.tablePadding`, `TableCalendar` key를 제거하고 일정 카드 앞 간격을 12px로 되돌린 뒤 마지막 행 좌표 검증을 제거한다.
  - 다음: 실제 기기에서 5주/6주 월의 마지막 행 및 compact 전환 후 선택 outline을 확인

- [DONE] (FIX) 친구 달력 마지막 행 선택 사각형 클리핑 재확인 및 수정
  - 목적: 실제 화면에서 마지막 행 선택 사각형 하단이 계속 잘리는 현상을 재현하고 내부 렌더링 경계에 맞는 수정으로 해결한다.
  - 변경: 현재 코드에 이전 조사에서 권장한 내부 padding과 컴포넌트 간격이 실제 적용되지 않아 390x740 위젯 테스트에서 달력 표 본문과 일정 카드 사이가 0px인 상태를 재현했다. `CalendarStyle.tablePadding` 하단에 8px을 적용해 패키지 내부 `PageView` 높이에 선택 사각형 overflow 영역을 포함하고, 일정 카드 앞에 별도 8px `SizedBox`를 추가했다. `TableCalendar`에는 명시적 key를 부여해 기존 상태로 핫 리로드할 때도 페이지 높이가 다시 초기화되게 했다. 테스트는 현재 월 마지막 날짜를 선택해 58px 선택 사각형 하단이 `TableCalendar` 경계 안에 있는지 직접 좌표로 검증한다.
  - 영향범위: `FriendCalendarPage`의 달력 선택 표시와 달력·일정 카드 사이 간격.
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 수정 전 `flutter test test/features/friend/presentation/pages/friend_calendar_page_test.dart`에서 달력 표 본문과 일정 카드 사이가 기대 16px, 실제 0px로 실패하는 것을 확인했다. 수정 후 같은 위젯 테스트 1건 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `dart format` 통과. 마지막 행 선택 사각형 하단 경계, 표 본문부터 일정 카드까지 16px, 카드 하단 16px, 오늘 복귀 회귀를 함께 검증한다.
  - 롤백: `CalendarStyle.tablePadding`, 일정 카드 앞 `SizedBox`, `TableCalendar` key와 마지막 행 좌표 검증을 제거한다.
  - 다음: 실제 기기에서 핫 리로드 후에도 마지막 행 선택 사각형 outline이 온전히 표시되는지 확인

- [DONE] (INVESTIGATION) 친구 달력 마지막 행 선택 사각형 잘림 원인 및 수정안 검토
  - 목적: 컴포넌트 사이 외부 여백을 추가한 뒤에도 마지막 행 선택 사각형 하단 outline이 잘리는 원인을 확인하고 안전한 수정 방향을 정한다.
  - 변경: 선택 사각형은 58x58px에 y=4px offset으로 셀 경계를 넘겨 그리며 셀 Stack은 `Clip.none`이다. 그러나 `table_calendar` 3.2.0의 상위 `PageView.builder`는 기본 `Clip.hardEdge`이므로 마지막 행에서 넘친 outline을 자른다. 현재 `TableCalendar` 바깥의 8px padding은 이 내부 클리핑 경계를 확장하지 않는다. 최소 변경안은 바깥 padding을 `CalendarStyle.tablePadding: EdgeInsets.only(bottom: AppTheme.spacing_sm)`으로 옮기는 것이다. 패키지의 페이지 높이 계산이 `tablePadding.vertical`을 포함하므로 4px offset을 내부 영역에 수용할 수 있다.
  - 영향범위: 조사 및 문서화만 수행. 런타임 코드는 변경하지 않는다.
  - 파일: `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 앱 코드와 `table_calendar` 3.2.0의 `table_calendar.dart`, `calendar_core.dart`, `calendar_page.dart`, `table_calendar_base.dart`를 직접 대조해 셀/페이지 클리핑과 높이 계산을 확인했다. 런타임 코드는 변경하지 않아 Flutter 테스트는 실행하지 않았다.
  - 롤백: 해당 조사 기록과 `PROJECT_CONTEXT.md`의 현재 제약 설명을 제거한다.
  - 다음: 외부 하단 padding을 `CalendarStyle.tablePadding`으로 옮기고 마지막 행 날짜 선택 시 선택 사각형 하단이 달력 경계 안에 있는지 위젯 테스트로 고정한다.

- [DONE] (FE) 친구 캘린더와 일정 카드 사이 여백 보강
  - 목적: 하단 행의 선택 사각형이 4px offset으로 일정 카드 방향에 그려질 때 잘려 보이지 않도록 컴포넌트 사이 공간을 확보한다.
  - 변경: `_buildCalendarSection()`의 `TableCalendar` 아래에 `AppTheme.spacing_sm` 8px padding을 추가해 offset 선택 사각형이 그려질 내부 여유를 확보했다. 달력 섹션과 일정 카드 사이의 기존 12px 고정 간격은 같은 8px 토큰으로 정리해, TableCalendar 실제 하단부터 일정 카드 상단까지의 전체 간격을 16px으로 구성했다. 선택 사각형의 4px offset은 유지했다.
  - 영향범위: `FriendCalendarPage`의 달력과 선택일 일정 카드 사이 세로 간격. 선택일 offset과 데이터 동작은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/friend/presentation/pages/friend_calendar_page_test.dart` 1건 통과. 390x740 화면에서 `TableCalendar` 하단과 일정 카드 상단의 실제 좌표 차이가 16px 이상이며 기존 하단 안전영역과 오늘 이동 회귀 테스트가 함께 통과하는지 확인했다.
  - 롤백: `_buildCalendarSection()`의 달력 하단 padding을 제거하고 일정 카드 앞 간격을 12px로 되돌린 뒤 관련 좌표 테스트와 문서를 복구한다.
  - 다음: 실제 기기에서 5주/6주 월의 마지막 행 선택 사각형 하단 outline이 온전히 보이는지 확인

- [DONE] (FIX) 친구 캘린더 오늘 이동 시 빌드 중 setState 예외 수정
  - 목적: 다른 월에서 `오늘` 버튼을 누를 때 `setState() or markNeedsBuild() called during build` 예외가 발생하지 않게 한다.
  - 변경: 3개월 뒤로 이동한 뒤 `오늘` 버튼을 누르는 위젯 테스트로 동일 예외를 재현했다. `TableCalendar`의 가로 PageView가 여러 달을 이동하며 보낸 `ScrollStartNotification`/`ScrollUpdateNotification`이 상위 `CupertinoNavigationBar`의 `_handleScrollNotification()`에 전달되고, 일정 영역 `Flexible`이 빌드 중인 시점에 내비게이션 바가 자체 `setState()`를 호출한 것이 직접 원인이었다. `_buildCalendar()`를 `NotificationListener<ScrollNotification>`로 감싸 가로 시작/갱신 알림을 달력 경계에서 소비했다. `onPageChanged`의 페이지 상태 갱신도 다음 프레임으로 지연해 같은 프레임의 중복 변경을 방지했다.
  - 영향범위: `FriendCalendarPage`의 오늘/월 페이지 이동 상태 갱신. 데이터 및 UI 디자인은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 수정 전 `flutter test test/features/friend/presentation/pages/friend_calendar_page_test.dart`에서 동일한 `CupertinoNavigationBar` 빌드 중 setState 예외를 재현했다. 수정 후 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, 같은 위젯 테스트 1건 통과, `git diff --check` 통과. 테스트는 3개월 뒤로 이동하는 동안과 `오늘` 복귀 후 각각 `tester.takeException()`이 null인지 확인한다.
  - 롤백: `_buildCalendar()`의 가로 스크롤 알림 필터를 제거하고 `onPageChanged`를 즉시 `setState()`로 되돌린 뒤 강화한 회귀 테스트와 문서를 복구한다. 동일 예외가 다시 발생한다.
  - 다음: 실제 기기에서 여러 달 떨어진 상태와 빠른 연속 탭 모두 `오늘` 복귀가 정상인지 확인

- [DONE] (FE) 친구 캘린더 오늘 이동 버튼 추가
  - 목적: 다른 월이나 날짜를 보고 있을 때 친구의 오늘 일정으로 즉시 돌아올 수 있게 한다.
  - 변경: 월 헤더 오른쪽에 primary tint와 pill 반경을 사용하는 32px 높이의 compact `오늘` 버튼을 추가했다. 버튼을 누르면 로컬 현재 날짜를 일 단위로 정규화해 `_selectedDay`와 `_focusedDay`를 동시에 갱신하고, 해당 월의 친구 캘린더 데이터를 조회한다. 데이터 로딩 중에는 버튼 왼쪽에 기존 activity indicator를 유지한다.
  - 영향범위: `FriendCalendarPage`의 월 헤더와 날짜 이동 동작. 친구 일정 조회 API 계약은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/friend/presentation/pages/friend_calendar_page_test.dart` 1건 통과. 다음 달로 이동한 뒤 `오늘` 버튼을 눌러 `TableCalendar.focusedDay`, 선택일 predicate와 선택일 일정 카드 날짜가 현재 날짜로 복귀하는지 검증했고 `git diff --check`도 통과했다.
  - 롤백: `_goToToday()`과 월 헤더의 `friend-calendar-today-button`, 관련 테스트 assertion 및 문서 기록을 제거한다.
  - 다음: 실제 기기에서 로딩 인디케이터와 오늘 버튼이 동시에 보일 때 월 헤더가 잘리지 않는지 확인

- [DONE] (FE) 친구 캘린더 일정 카드 하단 여백 확보
  - 목적: 선택일 일정 카드가 페이지 바닥과 홈 인디케이터 영역에 붙어 보이지 않도록 하단 호흡을 확보한다.
  - 변경: `FriendCalendarPage`의 본문 `SafeArea`에 하단 시스템 안전영역을 활성화하고 `AppTheme.spacing_md` 기준 최소 16px bottom padding을 적용했다. 일정 카드에는 테스트용 식별 키를 추가했다.
  - 영향범위: `FriendCalendarPage`의 선택일 일정 카드 아래 여백. 달력 및 일정 데이터 동작은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/friend/presentation/pages/friend_calendar_page_test.dart` 1건 통과. 390x740 화면에서 일정 카드 하단과 화면 바닥 사이가 16px 이상인지 검증했고 `git diff --check`도 통과했다.
  - 롤백: 본문 `SafeArea.minimum`과 일정 카드 식별 키, 관련 테스트 assertion 및 문서 기록을 제거한다.
  - 다음: 실제 홈 인디케이터가 있는 기기에서 시스템 안전영역이 적용된 카드 하단 간격을 확인

- [DONE] (FE) 친구 캘린더 화면 디자인 통일
  - 목적: 친구 캘린더의 중복 프로필 정보와 분리된 월 이동 영역을 정리하고, 달력 및 선택일 일정 목록을 메인 캘린더와 같은 시각 규칙으로 통일한다.
  - 변경: 내비게이션 바 아래에서 친구 이름/이메일을 반복하던 프로필 행을 제거했다. 월 이동 헤더와 `TableCalendar`를 하나의 섹션으로 묶고 메인 캘린더와 같은 좌우 이동 배치 및 공용 `YearMonthPickerSheet` 진입을 추가했다. 날짜 셀은 52/56px 반응형 행, primary tint/outline 선택 사각형, 오늘 밑줄, 11px 근무 코드 배지를 사용하며 일요일은 accent red, 토요일은 primary blue로 구분한다. 선택일 카드는 메인 화면과 같은 근무 시간 포맷, 장소 구분점, 아이콘이 포함된 빈 상태를 사용하되 친구 일정의 읽기 전용 동작은 유지했다.
  - 영향범위: `FriendCalendarPage`의 화면 구성과 표시 스타일. 친구 캘린더 조회/설정/삭제 API 및 공개 범위 판정은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `test/features/friend/presentation/pages/friend_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/friend/presentation/pages/friend_calendar_page_test.dart` 1건 통과. 390x740 화면에서 중복 이메일 미노출, 토요일 primary 색상, 사각형 선택 표시, 근무/개인 일정 카드, 연/월 이동 시트와 레이아웃 예외 없음까지 확인했다. `git diff --check` 통과.
  - 롤백: `FriendCalendarPage`에서 공용 연/월 시트와 메인 달력형 셀 빌더를 제거하고 기존 분리형 중앙 월 헤더, 62px 원형 선택/오늘 셀, 양쪽 빨간 주말 표현, 중복 프로필 행과 텍스트 전용 빈 상태를 복구한 뒤 관련 테스트·문서를 제거한다.
  - 다음: 실제 기기에서 긴 친구 이름의 내비게이션 말줄임, 5주/6주 월의 선택 사각형과 일정 카드 가용 높이를 확인

- [DONE] (FIX) 메인 달력 날짜 선택 시 숫자 위치 고정
  - 목적: 날짜를 선택할 때 숫자가 아래로 2px 이동하는 시각적 흔들림을 제거한다.
  - 변경: 선택 전에는 `EdgeInsets.all(2)`, 선택 후에는 `EdgeInsets.fromLTRB(2, 4, 2, 0)`이 적용돼 전체 여백 합계는 같아도 콘텐츠 중심이 2px 내려가던 조건부 `content_padding`을 제거했다. 날짜 콘텐츠는 선택 여부와 관계없이 2px 사방 padding을 사용한다. 현재 선택 배경 설정값(근무 코드 보기 58px/오프셋 4px, compact 보기 48px/오프셋 8px)은 유지했다.
  - 영향범위: 메인 달력 날짜와 근무 코드 콘텐츠의 선택 전후 세로 위치. 선택 배경 크기·오프셋, 오늘 밑줄, 근무 점, 선택 색상/굵기와 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 다음 날짜의 숫자 중심 Y 좌표를 선택 전후 비교해 0.1px 오차 이내로 동일한지 검증했다. 현재 선택 배경의 compact 48x48px 및 셀 중심 대비 8px 하단 배치와 작은 화면 레이아웃 예외 없음도 함께 확인했다. 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation` 9건 통과, `git diff --check`와 staged diff check 통과.
  - 롤백: `content_padding`을 선택 상태에 따라 위 4px/아래 0px 또는 2px 사방으로 분기하도록 되돌리고 관련 테스트·문서를 복구한다.
  - 다음: 실제 기기에서 일반 날짜를 연속 선택할 때 숫자 기준선이 흔들리지 않는지 확인

- [DONE] (FE) 메인 달력 선택일 박스를 콘텐츠 중심 크기로 축소
  - 목적: 선택 상태 사각형을 날짜 셀 전체 너비가 아니라 날짜 숫자와 근무 표시를 감싸는 제시 영역으로 조정한다.
  - 변경: `_buildCalendarDayCell()`의 선택 tint/outline과 날짜 콘텐츠를 동일한 전체 크기 `AnimatedContainer`에서 분리해 `Stack` 레이어로 구성했다. 제시 이미지의 검은 영역에 맞춰 compact 점 보기의 선택 배경은 44x44px 정사각형과 중심 대비 4px 하단 오프셋을 사용한다. 날짜+근무 코드 보기에서는 46px 고정 콘텐츠와 최대 44px 코드가 잘리지 않도록 48x48px 정사각형과 2px 하단 오프셋을 사용한다. 날짜·오늘 밑줄·근무 표시에는 기존 padding을 유지하고 선택 배경만 축소/이동한다.
  - 영향범위: 메인 달력 선택일 tint/outline의 크기와 위치. 날짜/오늘 밑줄, 근무 점·코드, 일반 셀, 선택 동작과 API/DB는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 390x740 `CalendarPage` 위젯 테스트에서 확장 보기 선택 배경이 48x48px인지, 위로 드래그한 compact 보기에서 44x44px 및 셀 중심 대비 4px 하단 배치인지, 두 모드에서 레이아웃 예외가 없는지 검증했다. 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation` 9건 통과, `git diff --check`와 staged diff check 통과.
  - 롤백: 선택 배경/콘텐츠 `Stack`을 제거하고 전체 셀을 채우는 단일 `AnimatedContainer`와 조건부 margin 구조로 복구한 뒤 관련 테스트·문서를 되돌린다.
  - 다음: 실제 기기 compact 보기에서 선택 사각형이 제시 영역과 일치하는지, 다음 행과 충분히 분리되는지 확인

## 2026-07-14

- [DONE] (FE) 메인 달력 선택일 박스 세로 위치 하향 조정
  - 목적: 선택 상태를 나타내는 사각형이 날짜 셀 위쪽에 치우쳐 보이는 문제를 개선한다.
  - 변경: `CalendarStyle.markersAlignment`는 행 전체를 채우는 커스텀 선택 셀의 위치를 바꾸지 못하는 것을 `table_calendar` 3.2.0의 `_buildCell()`/`CellContent` 구현으로 확인했다. 일반 셀은 기존 2px 사방 margin을 유지하고, 선택 셀만 `EdgeInsets.fromLTRB(2, 4, 2, 0)`을 적용해 박스 높이와 내부 46px 콘텐츠 영역은 유지하면서 시각적 중심을 2px 아래로 옮겼다.
  - 영향범위: 메인 달력 선택일 박스와 그 안의 날짜/근무 배지 세로 위치. 일반 날짜, 오늘 밑줄, compact 근무 점, 행 높이와 선택 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 390x740 `CalendarPage` 위젯 테스트에 선택 셀의 비대칭 margin 검증을 추가했다. 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation` 9건 통과, `git diff --check`와 staged diff check 통과.
  - 롤백: 선택 셀의 조건부 `cell_margin`을 제거하고 `margin: const EdgeInsets.all(2)`로 복구한 뒤 관련 테스트·문서 기록을 제거한다.
  - 다음: 실제 기기에서 선택 박스가 날짜 행 아래 경계와 붙어 보이지 않는지, 오늘 밑줄·근무 배지와 균형이 맞는지 확인

- [DONE] (FIX) 작은 화면 달력 근무 배지 셀 2px 오버플로 수정
  - 목적: 750px 미만 화면의 52px 달력 행에서 날짜/근무 배지 Column이 2px 넘치는 RenderFlex 오류를 제거한다.
  - 변경: 52px 행에서 셀 높이를 `_calendarRowHeight - 4`로 다시 제한한 뒤 2px 사방 margin까지 적용해 실제 자식 제약이 44px로 줄어들었고, 날짜 28px + 간격 2px + 근무 배지 16px의 46px 합계가 2px 넘치는 원인을 확인했다. `AnimatedContainer` 높이를 `double.infinity`로 바꿔 `TableCalendar`가 전달한 실제 셀 높이를 채우게 했으며, margin을 제외한 48px 안에 기존 46px 콘텐츠가 배치되도록 했다.
  - 영향범위: 메인 달력 날짜 셀의 내부 높이 제약. 날짜/오늘/선택 상태, 근무 배지 디자인, 행 높이와 사용자 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `test/features/calendar/presentation/pages/calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 390x740 화면과 빈 캘린더/알림 가짜 서비스를 사용한 `CalendarPage` 위젯 테스트에서 레이아웃 예외가 없음을 확인했다. 대상 코드/테스트 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation` 9건 통과, `git diff --check` 통과.
  - 롤백: 날짜 셀 `AnimatedContainer.height`를 `_calendarRowHeight - 4`로 되돌리고 회귀 테스트와 문서 항목을 제거한다. 단, 750px 미만 화면의 동일한 2px 오버플로가 다시 발생한다.
  - 다음: 실제 750px 미만 iPhone에서 5주/6주 월의 날짜, 오늘 밑줄, 근무 배지와 선택 박스 정렬을 확인

- [DONE] (FE) 메인 달력 선택일 박스 중앙 정렬
  - 목적: 선택일 박스가 날짜 셀의 하단 정렬을 따라 치우치지 않도록 셀 중앙에 배치한다.
  - 변경: `TableCalendar`의 `CalendarStyle.markersAlignment`를 기본 `bottomCenter`에서 `Alignment.center`로 변경해 선택일의 tint/outline 박스와 날짜 셀 콘텐츠가 셀 중앙에 정렬되도록 했다. compact 보기의 근무 점과 확장 보기의 근무 코드 배지는 각각 기존 `Positioned`/셀 내부 위치를 유지한다.
  - 영향범위: 메인 달력 날짜 셀 콘텐츠와 선택일 박스의 세로 위치. 근무 점/배지, 오늘 밑줄, 선택 상태와 달력 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, 대상 파일 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation/widgets` 8건 통과, `git diff --check` 통과.
  - 롤백: `CalendarStyle.markersAlignment`의 `Alignment.center` 설정을 제거해 기본 `bottomCenter` 정렬로 되돌린다.
  - 다음: 실제 기기에서 compact 점 보기와 확장 근무 배지 보기 모두 선택 박스가 날짜 셀 중앙에 놓이는지 확인

- [DONE] (FE) 메인 달력 오늘 원형 표시를 밑줄로 교체
  - 목적: 오늘 날짜의 outline 원을 제거하고 근무 배지·선택 셀과 구분되는 별도 표시 방식으로 오늘 상태를 전달한다.
  - 변경: 오늘 날짜를 감싸던 28px primary tint/outline 원을 제거했다. 오늘은 굵은 primary 날짜 텍스트 아래에 12x2px primary 밑줄을 표시하며, 오늘과 선택일이 겹쳐도 선택 셀의 tint/outline과 오늘 밑줄이 함께 나타난다. 근무 코드는 별도 하단 배지 영역을 계속 사용한다.
  - 영향범위: 메인 달력의 오늘 날짜 표시. 선택 셀, 근무 배지, 주말 색상과 달력 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, 대상 파일 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation/widgets` 8건 통과, `git diff --check` 통과.
  - 롤백: `is_today` 날짜의 밑줄을 제거하고 28px primary tint/outline 원으로 다시 감싼다.
  - 다음: 실제 기기에서 오늘 밑줄과 근무 코드 배지가 충분히 분리되어 보이는지 확인

- [DONE] (FE) 메인 달력 선택일 원형 표시 제거
  - 목적: 선택일 셀에 중복 적용된 채움 원을 제거하고 셀 tint/outline만으로 선택 상태를 표현한다.
  - 변경: `_buildCalendarDayCell()`에서 선택일에 적용하던 28px primary 채움 원과 흰색 날짜 텍스트를 제거했다. 선택일 날짜는 굵은 primary 텍스트로 표시하고 기존 셀 전체의 primary tint와 outline은 유지한다. 오늘이면서 선택되지 않은 날짜의 28px primary outline 원은 유지했다.
  - 영향범위: 메인 달력 선택일의 날짜 숫자 표시. 선택 셀 tint/outline, 오늘 표시, 근무 배지, 주말 색상과 달력 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, 대상 파일 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation/widgets` 8건 통과, `git diff --check` 통과.
  - 롤백: `is_selected`일 때 날짜 숫자를 28px primary 채움 원과 흰색 텍스트로 다시 감싼다.
  - 다음: 실제 기기에서 선택 셀 tint/outline만으로 선택 상태가 충분히 구분되는지 확인

- [DONE] (FE) 메인 달력 카드 외형 원복
  - 목적: 메인 달력에 적용한 흰색 surface, 16px 반경, outline 카드 외형만 제거해 이전의 배경 일체형 표현으로 되돌린다.
  - 변경: `_buildCalendar()`에서 `TableCalendar`를 감싸던 16px 화면 여백, 8px 내부 여백, 흰색 surface, 16px 반경과 outline의 `Container`를 제거하고 기존처럼 `Listener`를 직접 반환하도록 원복했다. 근무 코드 기본 노출, 반응형 행 높이, 선택일/오늘 표시, 일요일/토요일 색상과 compact 전환은 유지했다.
  - 영향범위: 메인 달력의 외부 배경, 여백, 테두리. 날짜 셀 디자인, 근무 배지, 월 이동·날짜 선택·근무 입력·저장 동작은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, 대상 파일 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation/widgets` 8건 통과, `git diff --check` 통과.
  - 롤백: `_buildCalendar()`의 `Listener`를 16px margin, 8px padding, `AppTheme.cardDecoration()`을 가진 `Container`로 다시 감싼다.
  - 다음: 실제 기기에서 페이지 배경과 달력 사이의 밀도, 선택 셀 및 근무 배지 가독성을 확인

- [DONE] (FE) 메인 달력 Shift Harmony 디자인 적용
  - 목적: 메인 달력에 Shift Harmony 시안의 카드 표면, 근무 코드 중심 정보 구조, 선택 상태와 주말 색상 체계를 적용해 월 근무표 탐색성을 높인다.
  - 변경: `TableCalendar`를 16px 화면 여백, 8px 내부 여백, 흰색 surface, 16px 반경과 outline의 Shift Harmony 카드로 감쌌다. 일반 달력의 기본 상태를 근무 코드 표시 모드로 바꾸고 근무 배지 텍스트를 11px로 높였으며, 화면 높이 750px 미만에서는 52px, 그 외에는 56px 행을 사용해 시안의 정보 밀도를 작은 화면에 맞췄다. 모든 날짜 상태를 공용 셀 빌더로 통합해 선택일은 primary tint/outline 셀과 28px 채움 원, 오늘이지만 미선택인 날짜는 primary outline 원으로 구분하고 180ms 선택 전환을 적용했다. 일요일/공휴일은 accent red, 토요일은 primary blue, 평일 요일은 보조 텍스트 색상으로 표시한다. 위로 드래그하는 기존 compact 점 보기와 월/2주/주 형식, 좌우 이동, 근무 입력 모드 복원은 유지했다.
  - 영향범위: 메인 캘린더 달력의 컨테이너, 기본 행 높이, 날짜/요일 색상, 근무 배지, 선택일/오늘 표시. 선택일 일정 카드, 근무/개인 일정 데이터, 월 이동·날짜 선택·근무 입력·저장 API/DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, 대상 파일 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation/widgets` 8건 통과, `git diff --check` 통과. 프로젝트 전체 `flutter analyze`는 이번 변경과 무관한 기존 warning/info 134건을 확인했다.
  - 롤백: 달력 외부 `AppTheme.cardDecoration()` 컨테이너를 제거하고 `_is_expanded_view` 기본값과 행 높이를 이전 값으로 복구한 뒤 `_buildCalendarDayCell()`을 이전 확장 셀/상태별 빌더로 되돌린다.
  - 다음: 실제 iPhone에서 5주/6주 월과 750px 전후 화면 높이의 카드 크기, 선택 애니메이션, 근무 배지 가독성을 확인

- [DONE] (FE) 메인 캘린더 일정 추가 행 디자인 반영
  - 목적: 제공된 Shift Harmony 시안 중 선택일 일정 컴포넌트의 `일정 추가하기...` 행만 현재 메인 캘린더에 반영한다.
  - 변경: 선택일 카드가 남은 높이를 강제로 채우던 `Expanded` 목록을 loose `Flexible`로 바꿔 일정 수에 맞춰 카드가 줄어들고 추가 액션이 마지막 일정 바로 아래에 오도록 했다. 일정이 많으면 기존처럼 목록만 내부 스크롤된다. 추가 행은 상단 구분선이 있는 전체 너비 푸터 대신 디자인 시안의 `p-sm`, `mt-xs`, 8px 반경을 반영한 44px 인셋 `CupertinoButton`으로 교체하고 primary 색상의 24px 원형 더하기 아이콘과 눌림 피드백을 적용했다. 기존 `_showPersonalEventModal()` 진입 동작은 유지했다.
  - 영향범위: 메인 캘린더 선택일 카드의 높이, 일정 목록과 개인 일정 추가 진입 행의 배치/스타일. 캘린더 본문, 근무/개인 일정 항목, 개인 일정 입력 모달, 저장 API/DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, 대상 파일 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation/widgets` 8건 통과, `git diff --check` 통과. 프로젝트 전체 `flutter analyze`는 이번 변경 파일이 아닌 기존 코드의 warning/info 134건을 확인했다.
  - 롤백: 선택일 카드 목록을 `Expanded`와 `MainAxisSize.max`로 복구하고 `_buildAddPersonalEventButton()`을 제거한 뒤 기존 상단 구분선 `GestureDetector` 푸터를 되살린다.
  - 다음: 실제 iPhone에서 일정 0개/1개/여러 개일 때 카드 높이와 추가 행 위치, 눌림 영역을 확인

- [DONE] (FE) 개인 일정 시간 선택 모달 디자인 통일
  - 목적: 개인 일정 추가 화면의 시작시간/종료시간 선택에도 날짜 선택 시트와 동일한 정보 구조와 디자인을 적용한다.
  - 변경: 기존 300px 기본 시간 팝업을 공용 `TimePickerSheet`로 교체했다. 새 시트는 날짜 선택 시트와 같은 28px 상단 반경, 드래그 핸들, 제목/설명, 선택 시간 요약 카드, `지금` 빠른 선택, 시·분 피커 카드, 취소/적용 버튼과 하단 안전영역을 사용한다. 피커는 기존처럼 24시간 형식을 유지하고, 상단 요약은 `오전 09:00`처럼 읽기 쉬운 형식으로 표시한다. 개인 일정의 시작시간/종료시간 상태는 기존 `Duration` 타입을 그대로 사용한다.
  - 영향범위: 개인 일정 추가 화면의 시작시간/종료시간 선택 모달 UI와 선택값 반환. 종일 토글, 시작/종료 날짜, 종료 시각 검증, 일정 저장 요청, UTC 변환, API/DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/time_picker_sheet.dart`, `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `test/features/calendar/presentation/widgets/time_picker_sheet_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 3개 Dart 파일 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, 시간/날짜/연도월 선택 시트 테스트 6건 통과, `git diff --check` 통과.
  - 롤백: `PersonalEventFormModal._selectTime()`을 이전 내부 `showCupertinoModalPopup` + `CupertinoDatePicker` 구현으로 되돌리고 `time_picker_sheet.dart`, 전용 테스트, PROJECT_CONTEXT 역할 설명을 제거한다.
  - 다음: 실제 iPhone에서 시작/종료시간 시트의 휠 가독성, `지금` 선택, 오전/오후 요약과 홈 인디케이터 여백을 확인

- [DONE] (FE) 개인 일정 날짜 선택 모달 디자인 통일
  - 목적: 개인 일정 추가 화면의 시작일/종료일 선택 모달에도 개선된 캘린더 선택 시트의 시각 언어와 명확한 액션 구조를 적용한다.
  - 변경: 기존 300px 기본 `CupertinoDatePicker` 팝업을 공용 `DatePickerSheet`로 교체했다. 새 시트는 연도/월 선택 시트와 같은 28px 상단 반경, 드래그 핸들, 제목/설명, 선택 날짜 요약 카드, `오늘` 빠른 선택, 연·월·일 피커 카드, 취소/적용 버튼과 하단 안전영역을 사용한다. 개인 일정의 시작일/종료일 모두 2000-01-01~2050-12-31 범위로 연결했고, 선택 후 시작일과 종료일의 순서가 역전되면 반대편 날짜를 맞추는 기존 로직은 유지했다.
  - 영향범위: 개인 일정 추가 화면의 시작일/종료일 선택 모달 UI, 날짜 선택 결과 반환. 시간 선택 모달, 일정 저장 요청, UTC 변환, 종일 일정의 배타적 종료 규칙, API/DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/date_picker_sheet.dart`, `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `test/features/calendar/presentation/widgets/date_picker_sheet_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 3개 Dart 파일 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, 날짜/연도월 선택 시트 테스트 4건 통과, `git diff --check` 통과.
  - 롤백: `PersonalEventFormModal._selectDate()`를 이전 내부 `showCupertinoModalPopup` + `CupertinoDatePicker` 구현으로 되돌리고 `date_picker_sheet.dart`, 전용 테스트, PROJECT_CONTEXT 역할 설명을 제거한다.
  - 다음: 실제 iPhone에서 시작일/종료일 시트의 높이, 연·월·일 휠 가독성, `오늘` 선택과 홈 인디케이터 여백을 확인

- [DONE] (FE) 연도/월 선택 모달 디자인 개선
  - 목적: 메인 캘린더와 근무 추가 화면의 연도/월 선택 모달을 현재 디자인 시스템에 맞게 정돈하고, 선택값과 이동 액션을 더 명확하게 제공한다.
  - 변경: 화면별로 중복되어 있던 300px 높이 연도/월 피커를 공용 `YearMonthPickerSheet`로 교체했다. 시트에 드래그 핸들, 제목/설명, 현재 선택값 요약 카드, `이번 달` 빠른 이동, 구분된 연도·월 휠 카드, 하단 취소/이동 버튼을 추가하고 Shift Harmony 색상·반경 토큰을 적용했다. 메인 캘린더는 2000~2050, 근무 추가 화면은 실제 `TableCalendar` 범위와 같은 2020~2030만 선택하도록 연결했다. 선택/취소 반환 동작을 위젯 테스트로 추가했다.
  - 영향범위: 메인 캘린더와 근무 추가 화면의 연도/월 선택 모달 UI, 선택 가능한 연도 범위, 선택 후 focused day 이동 및 메인 캘린더 데이터 재조회. API/DB 구조는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/calendar/presentation/pages/shift_add_page.dart`, `lib/features/calendar/presentation/widgets/year_month_picker_sheet.dart`, `test/features/calendar/presentation/widgets/year_month_picker_sheet_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 4개 Dart 파일 `dart format` 통과, 대상 코드/테스트 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation/widgets/year_month_picker_sheet_test.dart` 2건 통과, `git diff --check` 통과. 전체 `flutter test`에서는 신규 테스트를 포함한 12건이 통과했으나, 이번 변경과 무관한 기존 기본 `test/widget_test.dart`가 `MyApp`을 `ProviderScope` 없이 직접 실행하는 `Counter increments smoke test`라 기존 상태 그대로 1건 실패했다.
  - 롤백: 두 페이지의 `showYearMonthPickerSheet()` 호출을 이전 화면별 `showCupertinoModalPopup` + `CupertinoPicker` 구현으로 되돌리고 공용 시트/테스트 파일 및 PROJECT_CONTEXT 역할 설명을 제거한다.
  - 다음: 실제 iPhone에서 시트 높이, 휠 스크롤 감도, 홈 인디케이터 여백과 `이번 달` 애니메이션을 확인

- [DONE] (CHORE) 현재 변경사항 목적별 커밋 및 푸시
  - 목적: 개발 API 주소 변경과 메인 캘린더 근무 입력 UI 변경을 목적별 git 이력으로 분리해 원격 `origin/main`에 반영한다.
  - 변경: 개발 API 주소 변경을 `04ad4cc`(`chore(api): update development server host`), 캘린더 근무 입력 UI/테스트/문서를 `481c0f1`(`feat(calendar): refine shift entry controls`)로 분리해 `origin/main`에 푸시했다.
  - 영향범위: git 이력, 원격 `main`, 작업 문서. 런타임 동작은 각 변경 항목의 영향범위와 동일하다.
  - 파일: `lib/core/constants/api_constants.dart`, 캘린더 관련 코드/테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 4개 Dart 파일 `dart format` 변경 없음, 캘린더/위젯/테스트 대상 `flutter analyze` 0건, API 상수 대상 error/warning 0건과 기존 naming info 25건 확인, `flutter test test/features/calendar/presentation/widgets/shift_type_button_test.dart` 2건 통과, `git diff --check` 통과. `git push origin main` 성공.
  - 롤백: 기능 변경은 `git revert 481c0f1`, 개발 API 주소 변경은 `git revert 04ad4cc` 순서로 되돌린다.
  - 다음: 원격 `origin/main` 반영 완료

- [DONE] (CHORE) 개발 API 서버 호스트 변경 문서화
  - 목적: 로컬 개발 환경이 사용하는 API 서버 주소를 현재 접속 대상에 맞춘다.
  - 변경: `ApiConstants.base_url_dev`의 호스트가 `172.30.1.13`에서 `172.30.1.49`로 변경된 현재 작업 트리를 문서화한다.
  - 영향범위: 개발 모드의 모든 API 요청 대상. 운영 API 주소는 변경하지 않는다.
  - 파일: `lib/core/constants/api_constants.dart`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/core/constants/api_constants.dart` 변경 없음. 대상 `flutter analyze`에서 error/warning 0건이며 프로젝트 snake_case 정책과 기본 린트가 충돌하는 기존 naming info 25건을 확인했다. `git diff --check` 통과.
  - 롤백: `base_url_dev` 호스트를 `172.30.1.13`으로 되돌린다.
  - 다음: 캘린더 UI 변경과 분리해 커밋 및 푸시

- [DONE] (FE) 근무 입력 완료 버튼을 날짜 헤더로 이동
  - 목적: 근무 타입 개수 `N개`가 표시되던 날짜 헤더 오른쪽에 완료 액션을 배치하고, 하단 버튼이 차지하던 공간을 근무 타입 영역에 돌려준다.
  - 변경: `shift_types_data`와 `_buildShiftTypeCountBadge()`를 제거하고 날짜 헤더 오른쪽에 `_buildShiftAddCompleteButton()`을 배치했다. 완료 버튼은 36px 높이, 14px 텍스트의 compact primary 버튼으로 변경했다. 카드 하단의 48px 전체 너비 완료 버튼과 앞 여백을 제거해 원형 근무 타입 영역이 남은 높이를 더 사용할 수 있게 했다. 버튼은 기존 `_completeShiftAddMode()`를 그대로 호출한다.
  - 영향범위: 메인 캘린더 근무 입력 카드의 헤더와 완료 버튼 위치. 저장 로직/API는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart` 0건 통과, `flutter test test/features/calendar/presentation/widgets/shift_type_button_test.dart` 2건 통과, `git diff --check` 통과.
  - 롤백: 헤더 완료 버튼을 제거하고 타입 수 배지 및 하단 전체 너비 완료 버튼을 복구한다.
  - 다음: 실제 기기에서 날짜와 완료 버튼이 한 행에 잘리지 않고 표시되며 저장 동작이 동일한지 확인

- [DONE] (FE) 근무 입력 모드 진입 시 달력 확장 보기 활성화
  - 목적: 근무 입력 모드의 달력 행 높이 60px에 맞춰 날짜 아래 근무 코드가 보이는 확장 모드를 자동 활성화한다.
  - 변경: 근무 입력 진입 시 `_calendar_format_before_shift_add`와 `_expanded_view_before_shift_add`에 기존 상태를 저장한 뒤 `CalendarFormat.month`, `_is_expanded_view=true`를 적용했다. 따라서 60px 날짜 셀에 근무 코드가 함께 표시된다. 변경 없음 종료, 저장 성공, 취소 경로는 공통 `_restoreCalendarViewAfterShiftAdd()`로 진입 전 형식/확장 상태를 복구한다. 입력 중에는 `_onPointerMove()`가 확장/축소를 바꾸지 않도록 잠갔다. 2주 보기 강제 전환은 추가하지 않았다.
  - 영향범위: 메인 캘린더 근무 입력 모드의 달력 셀 표시, 진입/종료 시 달력 상태, 수직 드래그 동작. 근무 선택/저장 API는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart` 0건 통과, `flutter test test/features/calendar/presentation/widgets/shift_type_button_test.dart` 2건 통과, `git diff --check` 통과.
  - 롤백: `_calendar_format_before_shift_add`와 진입 시 월 확장 설정을 제거하고, 복원 함수를 확장 상태만 복구하도록 되돌린 뒤 입력 중 포인터 이동 차단을 제거한다.
  - 다음: 실제 기기에서 근무 설정 진입 시 근무 코드가 표시되고 완료/취소 시 기존 달력 형식으로 돌아오는지 확인

- [DONE] (FE) 근무 입력 모드의 2주 보기 강제 전환 제거
  - 목적: 메인 캘린더에서 근무 설정을 시작해도 사용자가 보던 달력 형식을 유지하고, 달력이 자동으로 2주 보기로 바뀌지 않게 한다.
  - 변경: `_calendar_format_before_shift_add`와 근무 입력 진입 시 `CalendarFormat.twoWeeks`를 대입하던 로직을 제거했다. 종료 시 달력 형식을 복원하던 처리도 제거해 월/2주/주 중 진입 전 형식을 그대로 유지한다. 확장 보기는 입력 중 셀/카드 공간 충돌을 막기 위해 기존처럼 임시 해제 후 종료 시 복구한다. 다음 날 자동 이동은 2주 보기 전용 매일 포커스 이동을 제거하고 월 경계를 넘을 때만 `_focused_day`를 갱신한다.
  - 영향범위: 메인 캘린더 근무 입력 모드 진입/종료 시 달력 표시 형식과 다음 날 이동 시 달력 포커스. 근무 선택, 선택일 이동, 저장 API, 원형 버튼 그리드는 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart` 0건 통과, `flutter test test/features/calendar/presentation/widgets/shift_type_button_test.dart` 2건 통과, `git diff --check` 통과.
  - 롤백: `_calendar_format_before_shift_add` 필드와 진입 시 `CalendarFormat.twoWeeks` 설정, 종료 시 기존 형식 복원, 입력 중 매일 `_focused_day` 이동 로직을 다시 추가한다.
  - 다음: 실제 기기에서 월 보기 상태로 근무 설정에 진입/완료/취소해 월 보기가 유지되는지 확인

- [DONE] (FE) 메인 캘린더 근무 입력 원형 버튼 레이아웃 복원
  - 목적: 일별 근무 입력 화면의 세로 스크롤 리스트를 원형 선택 버튼으로 바꾸고, 등록된 근무 타입 1~10개를 스크롤 없이 한 화면에서 확인하고 선택할 수 있게 한다.
  - 변경: `CalendarPage`의 스크롤 리스트를 `ShiftTypeSelectionGrid`로 교체했다. 그리드는 가용 너비/높이로 버튼 지름을 계산하고 한 행 최대 5개, 최대 2행으로 중앙 정렬해 1~10개를 모두 노출한다. 각 원형 버튼에는 근무 코드와 이름을 표시하고, 선택 시 타입 색상의 tint/굵은 outline을 적용한다. 날짜 헤더에는 현재 타입 수를 `N개`로 표시하며 기존 로딩/빈 상태/오류 재시도, 선택 후 다음 날 자동 이동, 완료 저장 흐름은 유지했다.
  - 영향범위: 메인 캘린더 근무 추가 모드의 근무 타입 선택 UI와 `shift_type_button.dart`의 재사용 위젯. 근무 저장 API, 기존 `ShiftTypeButtonGroup` 사용 화면, 근무 패턴 설정 화면은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/calendar/presentation/widgets/shift_type_button.dart`, `test/features/calendar/presentation/widgets/shift_type_button_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 대상 3개 파일 `dart format` 통과, 대상 3개 파일 `flutter analyze` 0건 통과, `flutter test test/features/calendar/presentation/widgets/shift_type_button_test.dart` 2건 통과. 테스트에서 320x128 영역의 타입 1~10개 무스크롤 표시, 10개 5열 2행 배치, 선택 콜백을 검증했다. 프로젝트 전체 `flutter analyze`는 error 0건이며 이번 범위 밖의 기존 warning/info 140건을 확인했다. `git diff --check` 통과.
  - 롤백: `CalendarPage`의 `ShiftTypeSelectionGrid`와 타입 수 배지를 제거하고 이전 `ListView.builder`/리스트 항목 위젯을 복구한 뒤, `shift_type_button.dart`의 신규 그리드와 전용 테스트를 제거한다.
  - 다음: 실제 iPhone 최소 지원 화면에서 10개 버튼의 코드/이름 가독성과 다음 날 자동 이동 시 선택 상태를 확인

## 2026-07-10

- [DONE] (FE) 메인 캘린더 근무 입력 모드 가용 영역 확대
  - 목적: 근무 입력 모드에서 월 달력과 근무 타입 카드가 세로 공간을 과도하게 차지해 실제 선택 가능한 리스트 영역이 좁아지는 문제를 줄인다.
  - 변경: 근무 추가 모드 진입 시 현재 달력 형식/확장 보기 상태를 저장한 뒤 `CalendarFormat.twoWeeks`로 전환하고 확장 보기를 해제한다. 저장/취소/변경 없음 종료 시 이전 상태를 복구한다. 다음 날 자동 이동 시 `_focused_day`를 같이 이동해 2주 보기에서 선택일이 보이도록 했다. 근무 설정 카드 padding, 리스트 행 높이, 텍스트 크기, 체크 아이콘, 완료 버튼 높이를 줄여 compact 밀도로 조정했고 기존 `print`는 `debugPrint`로 바꿨다. `CalendarPage`에 프로젝트 snake_case 정책용 `ignore_for_file: non_constant_identifier_names`를 명시해 대상 analyzer가 통과하도록 했다.
  - 영향범위: 메인 캘린더 근무 추가 모드의 달력 높이, 근무 타입 리스트 카드 밀도, 완료 버튼 높이
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart` 통과, `git diff --check` 통과
  - 롤백: `_calendar_format_before_shift_add`/`_expanded_view_before_shift_add` 저장·복구 로직과 근무 입력 모드의 `CalendarFormat.twoWeeks` 전환을 제거하고, `_calendarRowHeight`와 `_buildShiftAddOverlay()`/`_buildShiftTypeListItem()`/`_buildShiftAddCompleteButton()` 치수를 이전 값으로 되돌린다. PROJECT_CONTEXT의 compact 입력 모드 설명도 제거한다.
  - 다음: 실제 iPhone에서 근무 입력 모드 진입 시 2주 달력으로 충분한 리스트 높이가 확보되는지, 다음 날 자동 이동 중 선택일이 계속 보이는지 확인

- [DONE] (FE) 메인 캘린더 근무 설정 영역 카드화 및 완료 버튼 내부 배치
  - 목적: `stitch_shift_harmony_design_system` 시안처럼 근무 타입 리스트 전체를 하나의 영역으로 감싸고, `완료` 버튼을 하단 footer가 아니라 해당 영역 내부에 배치한다.
  - 변경: `CalendarPage`의 근무 추가 모드 영역을 `surface_container_low_color` 카드로 감싸고, 날짜 헤더/근무 타입 리스트/안내 문구/`완료` 버튼을 모두 카드 내부에 배치했다. 리스트는 카드 안에서만 스크롤하고, `완료` 버튼은 56px 높이의 primary 버튼으로 카드 하단에 고정했다. 이전에 추가했던 하단 footer 분리와 `BottomActionBar.showTopBorder` 옵션은 제거되어 최종 diff에서 `bottom_action_bar.dart` 변경은 사라졌다. `PROJECT_CONTEXT.md`의 메인 캘린더 근무 추가 모드 설명도 현재 구조로 갱신했다.
  - 영향범위: 메인 캘린더 근무 추가 모드의 리스트 컨테이너, 완료 버튼 위치, 하단 내비게이션과의 간격
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart lib/features/calendar/presentation/widgets/bottom_action_bar.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart lib/features/calendar/presentation/widgets/bottom_action_bar.dart`는 기존 `CalendarPage`의 snake_case/avoid_print info 10건으로 exit 1이며 신규 error/warning은 없음.
  - 롤백: `CalendarPage`의 `_buildShiftAddOverlay()`에서 외부 카드 decoration/padding과 내부 `완료` 버튼을 제거하고, 이전 리스트-only 본문 또는 기존 `ShiftTypeButtonGroup` 구조로 되돌린다. `PROJECT_CONTEXT.md`의 카드 내부 완료 버튼 설명도 함께 되돌린다.
  - 다음: 실제 iOS 시뮬레이터/기기에서 근무 추가 모드 카드의 높이, 리스트 스크롤, 카드 내부 `완료` 버튼과 하단 내비게이션 간 간격이 시안과 맞는지 확인

- [DONE] (FE) 메인 캘린더 근무 설정 리스트 디자인 반영
  - 목적: 메인 캘린더 우측 상단 `+` 버튼으로 근무 설정 영역을 열었을 때, 제공된 `mainpage calendar shift set` 시안처럼 선택일 기준 근무 타입 리스트를 표시하고 선택 UX를 정리한다.
  - 변경: `CalendarPage`의 근무 추가 모드 UI를 원형 버튼 그룹에서 세로 리스트로 교체했다. 리스트 항목은 좌측 색상 바, 선택 시 shift tint 배경, primary outline, 체크 아이콘을 표시한다. 항목 선택 시 기존처럼 `_schedules`에 임시 저장한 뒤 다음 날로 이동한다. `완료` 버튼은 리스트 내부에서 하단 `BottomActionBar` 위 고정 footer로 분리했고, `BottomActionBar`에는 외부 footer와 border가 겹치지 않도록 `showTopBorder` 옵션을 추가했다. `PROJECT_CONTEXT.md`에 메인 캘린더 근무 추가 모드와 수정 파일 역할을 문서화했다.
  - 영향범위: 메인 캘린더의 근무 추가 모드 UI, 선택일 근무 타입 선택/다음 날 이동 흐름, 하단 완료 버튼 표시
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/calendar/presentation/widgets/bottom_action_bar.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart lib/features/calendar/presentation/widgets/bottom_action_bar.dart` 통과, `flutter analyze lib/features/calendar/presentation/widgets/bottom_action_bar.dart` 통과, `git diff --check` 통과. `flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart lib/features/calendar/presentation/widgets/bottom_action_bar.dart`는 기존 `CalendarPage`의 snake_case/avoid_print info 10건으로 exit 1이며, 이번 변경으로 추가된 `show_top_border`/`unnecessary_underscores` lint는 수정 완료.
  - 롤백: `CalendarPage`의 `_buildShiftAddOverlay()`를 기존 카드형 날짜 헤더 + `ShiftTypeButtonGroup` + 내부 완료 버튼 구조로 되돌리고, 하단 `_buildShiftAddFooter()`/`_buildMainBottomActionBar()` 분리를 제거한다. `BottomActionBar.showTopBorder` 옵션과 PROJECT_CONTEXT의 근무 추가 리스트 설명도 제거한다.
  - 다음: 실제 iOS 시뮬레이터/기기에서 우측 상단 `+` 버튼을 눌러 근무 추가 모드 진입 후 리스트 카드 높이, 긴 근무 타입명 말줄임, 선택 체크 아이콘, 다음 날 자동 이동, 하단 `완료` 버튼 위치가 시안처럼 보이는지 확인

## 2026-07-09

- [DONE] (CHORE) 작업 내용 분리 커밋 및 푸시
  - 목적: 누적된 프론트/UI/문서 변경사항을 작업 목적별 커밋으로 분리하고 원격 저장소에 반영한다.
  - 변경: 공통 UI 토큰, 개인 일정 입력 화면, 설정 화면, 근무 타입 설정 화면, 근무 타입 색상 직렬화, 친구 설정 화면, 알림 목록 하단 여백, 문서 갱신을 각각 별도 커밋으로 분리했다. 생성 커밋은 `87de17c`, `e509e33`, `0ab4bde`, `f1ce19a`, `8469aa0`, `a0e9067`, `e2b35c5`, `ca7e27c`이다.
  - 영향범위: git 이력/원격 반영, `_docs` 문서 최신화. 코드 동작은 각 기능 커밋 범위와 동일하다.
  - 파일: `_docs/DECISIONS.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `git diff --check` 통과, `dart format --output=none --set-exit-if-changed ...` 통과, `flutter test test/core/utils/color_parser_test.dart` 통과. `flutter analyze`는 기존 snake_case/lowerCamelCase 정책 충돌, 기존 unused/deprecated 항목 등 156건으로 exit 1.
  - 롤백: 원격 반영 후 문제가 있으면 대상 커밋을 `git revert`로 역순 되돌림한다. 푸시 전이면 필요한 커밋만 새 브랜치로 분리하거나 후속 수정 커밋을 추가한다.
  - 다음: 원격 `origin/main` push 완료

- [DONE] (FE) 설정 진입 근무 패턴 설정 헤더 연결 애니메이션 보강
  - 목적: 설정 화면에서 근무 패턴 설정 화면으로 진입할 때 상단 헤더가 route 전환과 함께 자연스럽게 연결되도록 한다.
  - 변경: `ShiftTemplateSettingsPage`의 본문 내부 커스텀 `_buildTopBar()`를 제거하고 `CupertinoPageScaffold.navigationBar`에 `CupertinoNavigationBar`를 배치했다. 설정 화면과 같은 route navigation bar transition을 사용하도록 했고, PROJECT_CONTEXT에 근무 패턴 설정 화면 헤더 규칙을 문서화했다.
  - 영향범위: 설정 화면의 `근무 패턴 설정` 항목에서 근무 패턴 설정 화면으로 진입/복귀할 때 상단 헤더 전환. 근무 타입 조회/추가/수정/삭제, 하단 추가 버튼, 10개 제한 안내, API, DB 구조는 변경 없음.
  - 파일: `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/shift_template_settings_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/shift_template_settings_page.dart` 통과, `git diff --check` 통과
  - 롤백: `ShiftTemplateSettingsPage`의 `navigationBar`를 제거하고 기존 `_buildTopBar()` + 본문 `Column` 상단 배치 구조를 복구한다. PROJECT_CONTEXT의 navigation bar transition 설명도 이전 커스텀 헤더 설명으로 되돌린다.
  - 다음: 실제 iOS 시뮬레이터/기기에서 설정 화면의 `근무 패턴 설정` 행을 눌렀을 때 `설정` 헤더에서 `근무 패턴 설정` 헤더로 자연스럽게 전환되고, 뒤로가기 시 반대로 이어지는지 확인

- [DONE] (FE) 메인 캘린더 설정 진입 헤더 연결 애니메이션 보강
  - 목적: 메인 캘린더의 설정 버튼으로 설정 화면에 진입할 때, 알림/친구/친구 설정 흐름처럼 상단 헤더가 자연스럽게 연결되는 느낌을 준다.
  - 변경: `SettingsPage`의 본문 내부 커스텀 상단 헤더를 제거하고 `CupertinoPageScaffold.navigationBar`에 `CupertinoNavigationBar`를 배치했다. 설정 화면 본문은 단일 `ListView`로 유지하고, 프로필/설정 섹션이 navigation bar 아래에서 시작하도록 상단 padding을 조정했다. PROJECT_CONTEXT에 설정 화면 헤더가 route 간 navigation bar transition을 사용한다는 규칙을 문서화했다.
  - 영향범위: 메인 캘린더 설정 버튼으로 설정 화면 진입/복귀 시 상단 헤더 전환, 설정 화면 본문 시작 여백. 설정 항목 동작, 근무 패턴 설정 이동, 로그아웃 처리, 인증 상태, API, DB 구조는 변경 없음.
  - 파일: `lib/features/auth/presentation/pages/settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/auth/presentation/pages/settings_page.dart` 통과, `flutter analyze lib/features/auth/presentation/pages/settings_page.dart` 통과, `git diff --check` 통과
  - 롤백: `SettingsPage`의 `navigationBar`를 제거하고 기존 `_buildTopBar()` + `Column` + `Expanded(ListView)` 구조와 `_goBackToSchedule()`를 복구한다. PROJECT_CONTEXT의 navigation bar transition 설명도 이전 커스텀 고정 헤더 설명으로 되돌린다.
  - 다음: 실제 iOS 시뮬레이터/기기에서 메인 캘린더 우측 설정 버튼을 눌렀을 때 `캘린더` 헤더에서 `설정` 헤더로 자연스럽게 전환되고, 뒤로가기 시 반대로 이어지는지 확인

- [DONE] (FE) 근무 타입 최대 개수 안내 메시지 추가
  - 목적: 근무 타입이 10개라 추가할 수 없는 상태에서 사용자가 이유를 알 수 있도록 안내 메시지를 표시한다.
  - 변경: `ShiftTemplateSettingsPage`에 `_maxShiftTypes` 상수를 추가하고, 근무 타입이 10개 이상이면 하단 고정 버튼 위에 `근무 타입은 최대 10개까지 설정할 수 있습니다. 기존 타입을 삭제하면 다시 추가할 수 있어요.` 안내 문구를 표시하도록 했다. 기존 10개 제한 다이얼로그와 버튼 비활성 조건도 같은 상수를 사용하도록 정리했다. PROJECT_CONTEXT에 최대 개수 안내 문구 표시 규칙을 문서화했다.
  - 영향범위: 근무 패턴 설정 화면의 10개 도달 상태 안내 문구, 추가 버튼 비활성 조건 상수화. 근무 타입 API, 저장/수정/삭제 흐름, 카드 목록, DB 구조는 변경 없음.
  - 파일: `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/shift_template_settings_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/shift_template_settings_page.dart` 통과
  - 롤백: 하단 고정 버튼 위의 10개 제한 안내 `Text`와 `_maxShiftTypes` 상수 사용 변경을 제거하고, 기존 하드코딩된 10개 조건으로 되돌린다. PROJECT_CONTEXT의 안내 문구 설명도 제거한다.
  - 다음: 실제 기기에서 근무 타입 10개 상태를 열어 안내 문구가 버튼 위에 자연스럽게 표시되고 텍스트가 잘리지 않는지 확인

- [DONE] (FE) 근무 패턴 설정 목록 하단 잘림 수정
  - 목적: 근무 타입이 10개일 때 근무 패턴 설정 화면 하단 카드/추가 버튼 영역이 홈 인디케이터 쪽에서 잘려 보이는 문제를 해결한다.
  - 변경: `ShiftTemplateSettingsPage`의 추가 버튼을 `ListView` 마지막 child에서 스크롤 목록 밖 하단 고정 영역으로 분리했다. 화면 전체는 `SafeArea(bottom: false)`를 사용하고, 하단 버튼 영역은 `MediaQuery` 하단 안전영역을 padding에 반영한다. 근무 타입 목록은 카드만 스크롤하며 버튼 위에서 끝나도록 하단 padding을 조정했다. PROJECT_CONTEXT에 근무 패턴 설정 화면의 하단 고정 버튼 규칙을 문서화했다.
  - 영향범위: 근무 패턴 설정 화면의 목록 스크롤 영역, 하단 `근무 타입 추가` 버튼 위치와 10개 도달 시 비활성 버튼 표시. 근무 타입 추가/수정/삭제 API, 카드 디자인, DB 구조, 친구 공개 규칙은 변경 없음.
  - 파일: `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/shift_template_settings_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/shift_template_settings_page.dart` 통과
  - 롤백: `ShiftTemplateSettingsPage`의 하단 고정 버튼 영역을 제거하고, `_buildAddButton(state)`를 다시 `ListView` 마지막 child로 넣는다. PROJECT_CONTEXT의 하단 고정 버튼 설명도 제거한다.
  - 다음: 실제 iPhone 기기/시뮬레이터에서 근무 타입 10개 상태를 열어 마지막 카드와 비활성 추가 버튼이 홈 인디케이터에 가려지지 않는지 확인

- [DONE] (FE) 근무 타입 설정 팝업 하단 잘림 완화
  - 목적: 근무 타입 추가/편집 화면과 시간 선택 팝업의 하단 영역이 홈 인디케이터/화면 끝에 붙어 잘려 보이는 문제를 해결한다.
  - 변경: `ShiftTypeFormModal` 본문을 `SafeArea(bottom: false)` + `ListView` 내부 bottom padding 구조로 바꿔 마지막 안내 문구가 하단에 붙지 않게 했다. 시간 선택 팝업은 `MediaQuery` 하단 안전영역만큼 컨테이너 높이와 spacer를 추가해 피커 휠이 홈 인디케이터 뒤로 내려가지 않게 했다. 같은 파일에서 analyzer가 지적한 deprecated `Color.value` 사용은 `toARGB32()`로 교체했다. PROJECT_CONTEXT에 근무 타입 추가/편집 화면의 하단 안전영역 처리 규칙을 문서화했다.
  - 영향범위: 근무 타입 추가/편집 화면의 스크롤 하단 여백, 시작/종료 시간 선택 팝업의 하단 안전영역, 근무 타입 색상 정수 추출 방식. 근무 타입 API, validation, 저장/수정/삭제 흐름, DB 구조는 변경 없음.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/widgets/shift_type_form_modal.dart` 통과, `flutter analyze lib/features/calendar/presentation/widgets/shift_type_form_modal.dart` 통과
  - 롤백: `ShiftTypeFormModal`의 `SafeArea(bottom: false)`, `ListView` bottom padding, 시간 선택 팝업의 하단 spacer/높이 보정을 제거하고, 색상 정수 추출을 이전 방식으로 되돌린다. PROJECT_CONTEXT의 하단 안전영역 설명도 제거한다.
  - 다음: 실제 iPhone 기기/시뮬레이터에서 근무 타입 추가/편집 화면과 시작/종료 시간 선택 팝업을 열어 안내 문구와 피커 휠이 홈 인디케이터에 겹치지 않는지 확인

- [DONE] (FE) 근무 타입 색상 요청 직렬화 형식 수정
  - 목적: 근무 타입 추가/수정 API 요청의 `color`를 서버 validation 규칙인 `#AARRGGBB` 문자열로 전송해 400 `VALIDATION_ERROR`를 해결한다.
  - 변경: `formatApiColorValue()`를 추가해 Flutter `Color` 정수값을 8자리 대문자 hex 문자열로 변환하도록 했다. `CreateShiftTypeRequest.toJson()`과 `UpdateShiftTypeRequest.toJson()`은 `color`가 있을 때 숫자 대신 `#AARRGGBB` 문자열을 전송한다. 색상 파서 테스트에 요청 직렬화 검증을 추가했고, PROJECT_CONTEXT의 근무 타입 색상 규칙에 서버 요청 형식을 문서화했다.
  - 영향범위: 근무 타입 생성/수정 요청 body의 `color` 필드 직렬화. 응답 색상 파싱, 근무 타입 UI, DB schema, 서버 validation 규칙은 변경 없음.
  - 파일: `lib/core/utils/color_parser.dart`, `lib/features/calendar/data/models/shift_type_api_model.dart`, `test/core/utils/color_parser_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/core/utils/color_parser.dart lib/features/calendar/data/models/shift_type_api_model.dart test/core/utils/color_parser_test.dart` 통과, `flutter analyze lib/core/utils/color_parser.dart lib/features/calendar/data/models/shift_type_api_model.dart test/core/utils/color_parser_test.dart` 통과, `flutter test test/core/utils/color_parser_test.dart` 통과
  - 롤백: `CreateShiftTypeRequest`/`UpdateShiftTypeRequest`의 `color` 직렬화를 기존 숫자 전송으로 되돌리고, `formatApiColorValue()`와 관련 테스트/PROJECT_CONTEXT 설명을 제거한다.
  - 다음: 실제 API 연동에서 근무 타입 추가/수정 요청 body의 `color`가 `#FF0061A4` 형식으로 전송되고 서버 400이 사라지는지 확인

- [DONE] (FE) 근무 타입 설정 화면 10개 제한 디자인 반영
  - 목적: 근무 타입 설정 화면을 제공된 `stitch_shift_schedule_planner (4)` 시안에 맞추고, 근무 타입 10개 도달 시 추가 버튼을 비활성 색상으로 표시한다.
  - 변경: `ShiftTemplateSettingsPage`를 고정 상단 `근무 패턴 설정` 헤더, 근무 타입 수 배지, 카드형 근무 타입 목록, 하단 전체 폭 추가 버튼 구조로 변경했다. `ShiftTypeCard`는 원형 색상 배지 안에 코드를 표시하고, 이름/시간 행과 outline 색상 삭제 아이콘을 시안 기준으로 정리했다. 근무 타입이 10개 이상이면 추가 버튼을 `surface-container-highest`(`#E0E3E5`) 배경으로 비활성화하고 추가 모달 진입을 막는다. `AppTheme`에는 `surface_container_highest_color` 토큰과 기존 snake_case 토큰 정책용 lint 예외를 추가했다.
  - 영향범위: 근무 패턴 설정 화면의 표시 구조, 근무 타입 카드 디자인, 10개 도달 시 추가 버튼 상태. 시안 기준으로 상단 템플릿 이름 변경 액션은 노출하지 않는다. 근무 타입 조회/추가/수정/삭제 API, 근무표 DB 구조, 친구 공개 규칙은 변경 없음.
  - 파일: `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`, `lib/features/calendar/presentation/widgets/shift_type_card.dart`, `lib/core/theme/app_theme.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/core/theme/app_theme.dart lib/features/calendar/presentation/pages/shift_template_settings_page.dart lib/features/calendar/presentation/widgets/shift_type_card.dart` 통과, `flutter analyze lib/core/theme/app_theme.dart lib/features/calendar/presentation/pages/shift_template_settings_page.dart lib/features/calendar/presentation/widgets/shift_type_card.dart` 통과, `git diff --check` 통과
  - 롤백: `ShiftTemplateSettingsPage`를 기존 `CupertinoSliverNavigationBar` + `CupertinoButton.filled` 구조로 되돌리고, `ShiftTypeCard`를 코드/이름 Row와 기존 카드 decoration으로 되돌린다. `AppTheme.surface_container_highest_color`와 PROJECT_CONTEXT의 근무 타입 설정 화면 설명을 제거한다.
  - 다음: 실제 기기에서 9개/10개 상태를 각각 열어 카운트 배지, 카드 간격, 추가 버튼 비활성 배경색(`#E0E3E5`)과 터치 차단을 확인

- [DONE] (FE) 설정 섹션 테두리 렌더링 구조 수정
  - 목적: 설정 섹션 카드가 같은 크기의 바깥/안쪽 박스 2개처럼 렌더링되어 radius 값에 따라 border가 일부만 보이는 문제를 해결한다.
  - 변경: `_buildSettingsCard()`에서 border를 먼저 그리는 outer `DecoratedBox`를 제거했다. 행 배경/구분선은 `ClipRRect`로 한 번만 클리핑하고, 카드 외곽선은 `Container.foregroundDecoration`에서 primary tint 1px border로 마지막에 그리도록 변경했다.
  - 영향범위: 설정 화면의 근무 관리/앱 설정/계정 및 보안/지원 섹션 카드 외곽선 렌더링. 프로필 카드, 행 구분선, 설정 항목 탭 동작, 헤더 고정, 로그아웃 처리, 인증 상태, DB/공개 범위 규칙은 변경 없음.
  - 파일: `lib/features/auth/presentation/pages/settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/auth/presentation/pages/settings_page.dart` 통과, `flutter analyze lib/features/auth/presentation/pages/settings_page.dart` 통과, `git diff --check` 통과
  - 롤백: `_buildSettingsCard()`를 outer `DecoratedBox` + inner `ClipRRect` 구조로 되돌리고, PROJECT_CONTEXT의 `foregroundDecoration` 설명을 이전 outline 설명으로 되돌린다.
  - 다음: 실제 기기에서 섹션 카드 radius를 키워도 외곽선이 내부 surface에 덮이지 않고 전체 둘레에 일정하게 보이는지 확인

- [DONE] (FE) 설정 섹션 테두리 색상 적용
  - 목적: 설정 화면의 근무 관리/앱 설정/계정 및 보안/지원 섹션 카드 외곽선에 더 명확한 색상을 적용한다.
  - 변경: `SettingsPage`에 설정 섹션 카드 전용 `_settings_section_border_color`를 추가하고, `_buildSettingsCard()`의 outer `DecoratedBox` border 색상을 기존 outline variant에서 primary tint 색상으로 변경했다. 내부 행 구분선은 기존 outline variant를 유지했다.
  - 영향범위: 설정 화면의 근무 관리/앱 설정/계정 및 보안/지원 섹션 카드 외곽선 색상. 프로필 카드, 행 구분선, 설정 항목 탭 동작, 헤더 고정, 로그아웃 처리, 인증 상태, DB/공개 범위 규칙은 변경 없음.
  - 파일: `lib/features/auth/presentation/pages/settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/auth/presentation/pages/settings_page.dart` 통과, `flutter analyze lib/features/auth/presentation/pages/settings_page.dart` 통과, `git diff --check` 통과
  - 롤백: `_settings_section_border_color`를 제거하고 `_buildSettingsCard()` border 색상을 `AppTheme.outline_variant_color`로 되돌린다. PROJECT_CONTEXT의 primary tint outline 설명도 이전 outline 설명으로 되돌린다.
  - 다음: 실제 기기에서 설정 섹션 카드 외곽선 색상이 과하게 튀지 않고 radius 모서리에서 끊겨 보이지 않는지 확인

- [DONE] (FE) 설정 화면 헤더 고정
  - 목적: 설정 화면을 스크롤해도 상단 `설정` 헤더와 뒤로가기 버튼이 화면 상단에 고정되도록 한다.
  - 변경: `SettingsPage`의 최상위 내용을 단일 `ListView`에서 `Column`으로 바꾸고, `_buildTopBar()`를 스크롤 영역 밖에 배치했다. 프로필 카드, 설정 섹션, 로그아웃 버튼은 `Expanded` 내부 `ListView`로 분리해 본문만 스크롤되도록 했다.
  - 영향범위: 설정 화면 스크롤 구조와 헤더 고정 동작. 설정 항목 탭, 근무 패턴 설정 이동, 로그아웃 처리, 미구현 기능 alert, 인증 상태, DB/공개 범위 규칙은 변경 없음.
  - 파일: `lib/features/auth/presentation/pages/settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/auth/presentation/pages/settings_page.dart` 통과, `flutter analyze lib/features/auth/presentation/pages/settings_page.dart` 통과, `git diff --check` 통과
  - 롤백: `SettingsPage`의 `Column` + fixed `_buildTopBar()` + `Expanded(ListView)` 구조를 제거하고, `_buildTopBar()`를 다시 본문 `ListView`의 첫 child로 넣는 이전 구조로 되돌린다. PROJECT_CONTEXT의 헤더 고정 설명을 제거한다.
  - 다음: 실제 기기에서 설정 화면을 끝까지 스크롤해도 상단 `설정` 헤더와 뒤로가기 버튼이 고정되어 있는지 확인

- [DONE] (FE) 설정 화면 80% 밀도 조정 및 섹션 테두리 클리핑 수정
  - 목적: 설정 화면의 글자/박스/아이콘/토글 크기가 다른 화면보다 커 보이는 문제를 줄이고, 섹션 카드의 radius 모서리에서 1px outline이 미묘하게 잘려 보이는 문제를 정리한다.
  - 변경: `SettingsPage`에 설정 화면 전용 `_settings_scale = 0.8`과 `_scaledTextStyle()`을 추가해 페이지 좌우/하단 패딩, 상단 헤더, 프로필 카드, 아바타/편집 버튼, 섹션 간격, 섹션 제목, 행 높이/패딩, 아이콘, chevron, 정적 토글, 로그아웃 버튼 크기와 글씨를 기존 대비 80% 수준으로 줄였다. 섹션 카드의 outline과 clipping을 같은 `Container`에서 처리하던 구조를 `DecoratedBox` outer border + `ClipRRect` inner content 구조로 바꿔 rounded corner의 1px 테두리가 잘려 보이는 현상을 줄였다.
  - 영향범위: 설정 화면의 시각 밀도, 섹션 카드 모서리 렌더링, 설정 화면 내부 터치 영역. 근무 패턴 설정 이동, 로그아웃 처리, 미구현 기능 alert, 인증 상태, DB/공개 범위 규칙은 변경 없음.
  - 파일: `lib/features/auth/presentation/pages/settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/auth/presentation/pages/settings_page.dart` 통과, `flutter analyze lib/features/auth/presentation/pages/settings_page.dart` 통과, `git diff --check` 통과
  - 롤백: `_settings_scale`/`_scaledTextStyle()` 적용과 `_buildSettingsCard()`의 `DecoratedBox` + inner `ClipRRect` 구조를 제거하고 이전 고정 치수 및 `Container(clipBehavior: Clip.antiAlias, decoration: AppTheme.cardDecoration(...))` 섹션 카드 구조로 되돌린다. PROJECT_CONTEXT의 0.8 스케일/outline 클리핑 설명도 제거한다.
  - 다음: 실제 기기에서 설정 화면과 캘린더/친구 화면을 나란히 비교해 텍스트 크기, 행 높이, 섹션 모서리 outline이 자연스럽게 보이는지 확인

- [DONE] (FE) 설정 화면 디자인 시안 재반영
  - 목적: 제공된 설정 화면 시안(`design/stitch_shift_schedule_planner (3)`)에 맞춰 현재 설정 페이지의 간격, 카드 크기, 아이콘, 토글, 로그아웃 버튼 스타일을 재정렬한다.
  - 변경: `SettingsPage`의 상단을 좌측 영문 타이틀/하단 설정 내비게이션 구조에서 중앙 `설정` 헤더와 좌측 뒤로가기 구조로 변경했다. 하단 설정 내비게이션을 제거하고, 프로필 카드의 아바타/텍스트 크기와 섹션 간격, 설정 행 높이/패딩, chevron, 토글, 로그아웃 버튼을 제공 시안 기준으로 축소·정렬했다. 미구현 토글은 상태 변경 없이 정적 토글 UI와 `준비 중인 기능` alert를 유지한다. 버전 정보는 하드코딩 대신 `AppConstants.app_version`을 표시하도록 변경했다.
  - 영향범위: 설정 화면 UI 레이아웃, 설정 화면 내 뒤로가기/스크롤 구조, 토글 표시 방식, 버전 정보 표시. 인증 상태/로그아웃 처리, 근무 패턴 설정 이동, 미구현 기능 차단 정책, DB/공개 범위 규칙은 변경 없음.
  - 파일: `lib/features/auth/presentation/pages/settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/auth/presentation/pages/settings_page.dart` 통과, `flutter analyze lib/features/auth/presentation/pages/settings_page.dart` 통과, `git diff --check` 통과
  - 롤백: `SettingsPage`의 중앙 `설정` 헤더/정적 토글/축소된 카드·행 치수/하단 내비게이션 제거 변경을 되돌리고 이전 좌측 `Settings` 헤더와 `_buildBottomNavigationBar()` 구조로 복구한다. PROJECT_CONTEXT의 설정 화면 설명도 이전 하단 내비게이션 설명으로 되돌린다.
  - 다음: 실제 기기에서 제공된 캡처와 비교해 상단 헤더, 프로필 카드 높이, 각 섹션 행 높이, 긴 이메일 말줄임, 로그아웃 버튼 위치를 확인

- [DONE] (FE) 설정 화면 디자인 및 미구현 기능 차단
  - 목적: 제공된 설정 화면 시안에 맞춰 설정 페이지를 재구성하고, 아직 개발되지 않은 설정 항목은 alert로 접근을 막는다.
  - 변경: `SettingsPage`를 시안 기반의 커스텀 설정 화면으로 재구성했다. 상단 `Settings` 헤더, 프로필 카드, 근무 관리/앱 설정/계정 및 보안/지원 카드 섹션, 하단 설정 내비게이션, 별도 로그아웃 버튼을 추가했다. 실제 구현된 근무 패턴 설정은 기존 `ShiftTemplateSettingsPage`로 이동하고, 로그아웃은 기존 인증 Provider 흐름을 유지한다. 프로필 편집, 기본 알림 설정, 다크 모드, 언어 및 지역, 글꼴 크기, 비밀번호 변경, 로그인 생체 인증, 공지사항, 고객 센터, 하단 Shifts/History 탭은 `준비 중인 기능` alert를 표시하고 상태를 변경하지 않도록 막았다.
  - 영향범위: 설정 화면 UI, 설정 항목 탭 동작, 미구현 기능 접근 차단, 로그아웃 버튼 위치. 인증 상태/로그아웃 처리, 근무 템플릿 설정 화면, DB/공개 범위 규칙은 변경 없음.
  - 파일: `lib/features/auth/presentation/pages/settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/auth/presentation/pages/settings_page.dart` 통과, `flutter analyze lib/features/auth/presentation/pages/settings_page.dart` 통과, `git diff --check` 통과
  - 롤백: `SettingsPage`의 커스텀 카드/하단 내비게이션/미구현 alert 변경을 제거하고 이전 `CupertinoListSection.insetGrouped` 프로필/계정 섹션 구조로 되돌린다. PROJECT_CONTEXT의 설정 화면 시안 및 alert 차단 설명을 이전 내용으로 되돌린다.
  - 다음: 실제 기기에서 설정 화면 스크롤, 긴 이름/이메일 말줄임, 각 미구현 항목 alert, 근무 패턴 설정 이동, 로그아웃 확인 다이얼로그를 확인

- [DONE] (FE) 친구 설정 화면 밀도 조정
  - 목적: 친구 설정 화면의 요소 크기와 여백을 줄이고, 친구 레벨 설정을 개인 일정 추가 화면과 같은 드래그형 레벨 조정 컴포넌트로 맞춘다.
  - 변경: `FriendDetailPage`의 프로필 이미지, 이름/이메일 글자 크기, 카드 내부 패딩, 카드 간격, 삭제 버튼, 공유 토글 표시 크기를 전반적으로 줄였다. 프로필 사진 옆 연필 아이콘은 제거했다. 친구 레벨 설정은 기존 개별 버튼 Row를 제거하고, 개인 일정 추가 모달의 공개 레벨 선택과 같은 0~5 탭/좌우 드래그 트랙으로 변경했다.
  - 영향범위: 친구 설정 화면의 시각 밀도, 친구 레벨 선택 조작 방식, 프로필 표시. 친구 설정 저장 API, 저장 시점, 친구 삭제 흐름은 변경 없음.
  - 파일: `lib/features/friend/presentation/pages/friend_detail_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/presentation/pages/friend_detail_page.dart` 통과, `flutter analyze lib/features/friend/presentation/pages/friend_detail_page.dart` 통과, `git diff --check` 통과
  - 롤백: `FriendDetailPage`의 축소된 치수와 `_buildFriendLevelSelector()`/`_updateFriendLevelFromPosition()`을 제거하고 이전 개별 레벨 버튼 Row와 큰 프로필/카드 치수로 되돌린다. PROJECT_CONTEXT와 FRIEND_FEATURE_DESIGN의 컴팩트 레이아웃/드래그 트랙 설명을 제거한다.
  - 다음: 실제 기기에서 친구 설정 화면을 열어 75% 수준의 밀도, 긴 이름/이메일 말줄임, 레벨 탭/드래그 조작, 공유 토글 터치 영역을 확인

- [DONE] (FE) 친구 설정 화면 디자인 변경 반영
  - 목적: 제공된 친구 정보 디자인 시안에 맞춰 친구 상세/설정 화면의 레이아웃과 시각 스타일을 정리한다.
  - 변경: `FriendDetailPage`를 시안 기준의 상단 프로필 중심 레이아웃으로 재구성했다. 내비게이션 바에는 뒤로가기와 `Save` 액션을 배치했고, 프로필 이미지는 원형 이미지/편집 표시 FAB 형태로 변경했다. 친구 레벨 설정은 단일 선택 0~5 세그먼트 카드로 바꾸고, `friend_level_settings.friend_level >= events.visibility_level` 규칙에 맞춰 현재 레벨 설명을 표시한다. 내 캘린더 공유 토글은 별도 카드로 정리했다. 레벨/공유 설정은 화면에서 먼저 변경하고 `Save`를 눌렀을 때 기존 친구 설정 API로 `friend_level`, `can_view`를 함께 저장하도록 변경했다. 친구 삭제 버튼은 시안의 연한 오류 배경과 사람 삭제 아이콘을 적용했다.
  - 영향범위: 친구 캘린더 우측 설정 버튼으로 진입하는 `FriendDetailPage` UI, 친구 레벨/캘린더 공유 설정 저장 시점, 친구 삭제 버튼 시각 표현. 친구 캘린더 조회 API, 친구 삭제 성공 후 `Navigator.pop(true)` 흐름, DB 공개 조건은 변경 없음.
  - 파일: `lib/features/friend/presentation/pages/friend_detail_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/presentation/pages/friend_detail_page.dart` 통과, `flutter analyze lib/features/friend/presentation/pages/friend_detail_page.dart` 통과, `git diff --check` 통과
  - 롤백: `FriendDetailPage`의 커스텀 내비게이션 바/프로필 섹션/카드형 레벨·공유 설정/저장 버튼 흐름을 제거하고 기존 즉시 저장형 `CupertinoListSection.insetGrouped` 기반 구조로 되돌린다. PROJECT_CONTEXT와 FRIEND_FEATURE_DESIGN의 `Save` 저장 시점 설명을 제거한다.
  - 다음: 실제 iOS/Android 기기에서 친구 정보 화면을 열어 시안과의 간격, 긴 이름/이메일 말줄임, Save 비활성/활성 상태, 설정 저장 후 친구 목록의 레벨/공유 상태 반영을 확인

## 2026-07-08

- [DONE] (FE) 설정 페이지 섹션 배경 사각형 제거
  - 목적: 설정 페이지의 프로필/계정 섹션 뒤에 보이는 큰 네모 배경을 제거하고 앱 배경과 카드 스타일을 통일한다.
  - 변경: `CupertinoListSection.insetGrouped`의 기본 section 배경색(`CupertinoColors.systemGroupedBackground`)이 앱 배경과 달라 프로필/계정 영역 뒤에 큰 사각형 띠처럼 보이던 원인을 확인했다. 설정 화면의 두 list section에 `backgroundColor: AppTheme.background_color`를 명시하고 실제 행 묶음에는 `AppTheme.cardDecoration()`을 적용했다. 프로젝트 snake_case 변수명과 Flutter 기본 lint 충돌은 `_is_logging_out` 한 줄에만 lint 예외를 명시했다.
  - 영향범위: 설정 페이지 프로필/계정 섹션의 배경 및 카드 보더 표시. 로그아웃, 근무 설정 이동, 인증 상태 흐름은 변경 없음.
  - 파일: `lib/features/auth/presentation/pages/settings_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/auth/presentation/pages/settings_page.dart` 통과, `flutter analyze lib/features/auth/presentation/pages/settings_page.dart` 통과
  - 롤백: 설정 페이지의 `CupertinoListSection.insetGrouped`에서 `backgroundColor`, `decoration` 지정을 제거하고 `_is_logging_out` lint 예외와 PROJECT_CONTEXT의 설정 화면 section 배경 규칙을 제거한다.
  - 다음: 실제 iPhone 기기/시뮬레이터에서 설정 화면의 프로필/계정 섹션 뒤에 전체 폭 사각형 배경이 남지 않는지 확인

- [DONE] (FE) 알림 목록 하단 잘림 완화
  - 목적: 알림 목록 하단 카드가 홈 인디케이터/화면 끝에서 잘린 것처럼 보이는 느낌을 줄인다.
  - 변경: `NotificationPage`의 최상위 `SafeArea`에서 하단 안전영역 적용을 제외하고, 목록 끝에 홈 인디케이터 높이를 반영한 footer sliver를 추가했다. 추가 페이지가 남아 있거나 로딩 중이면 하단 여백만 표시하고, 마지막 페이지에서는 `모든 알림을 확인했습니다` 문구를 표시한다.
  - 영향범위: 알림 목록 화면의 하단 스크롤 여백과 마지막 페이지 footer 표시. 알림 API, 알림 액션 처리, 친구 요청 수락/거절 흐름은 변경 없음.
  - 파일: `lib/features/friend/presentation/pages/notification_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/presentation/pages/notification_page.dart` 통과, `flutter analyze lib/features/friend/presentation/pages/notification_page.dart` 통과
  - 롤백: `NotificationPage`의 `SafeArea(bottom: false)`를 기존 `SafeArea`로 되돌리고 `_buildListFooter()`와 footer `SliverToBoxAdapter`를 제거한다. PROJECT_CONTEXT의 알림 목록 footer 규칙도 제거한다.
  - 다음: 실제 iPhone 기기/시뮬레이터에서 알림 목록 최하단까지 스크롤해 마지막 카드가 홈 인디케이터와 겹치지 않고 자연스럽게 끝나는지 확인

- [DONE] (FE) 전체 화면 디자인 통일
  - 목적: 제공된 디자인 문서 기준으로 캘린더/친구/알림/개인 일정 화면의 시각 언어를 통일한다.
  - 변경: Shift Harmony 디자인 토큰을 `AppTheme`에 중앙화했다. Primary를 `#0061A4`, 배경을 `#F8F9FB`, surface/outline/text/radius 토큰으로 정리하고 `cardDecoration()` helper를 추가했다. 캘린더 메인/근무 추가/근무 입력/근무 타입 설정, 개인 일정 모달, 친구 목록/친구 캘린더/친구 상세/친구 추가 모달, 알림 목록, 로그인/스플래시/설정/프로필 화면의 배경, 카드, outline, 보조 텍스트, primary 버튼 색을 공용 토큰으로 맞췄다. 무거운 카드 shadow는 대부분 outline 기반 카드로 교체했고, 근무 타입 색상/공휴일/오류/성공/소셜 로그인 브랜드 색은 의미 색상으로 유지했다. 디자인 적용 정책 ADR-0003과 PROJECT_CONTEXT UI 디자인 시스템 섹션을 추가했다.
  - 영향범위: 앱 전반의 Flutter presentation UI 스타일, 공용 테마 토큰, 카드/모달/선택일/친구/알림/근무 타입 컴포넌트의 시각 표현. API 요청/응답, 라우팅, DB/권한 규칙은 변경 없음.
  - 파일: `lib/core/theme/app_theme.dart`, `lib/main.dart`, `lib/features/auth/presentation/pages/login_page.dart`, `lib/features/auth/presentation/pages/profile_setup_page.dart`, `lib/features/auth/presentation/pages/settings_page.dart`, `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/calendar/presentation/pages/shift_add_page.dart`, `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`, `lib/features/calendar/presentation/widgets/bottom_action_bar.dart`, `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `lib/features/calendar/presentation/widgets/shift_badge.dart`, `lib/features/calendar/presentation/widgets/shift_input_sheet.dart`, `lib/features/calendar/presentation/widgets/shift_type_button.dart`, `lib/features/calendar/presentation/widgets/shift_type_card.dart`, `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `lib/features/friend/presentation/pages/friend_detail_page.dart`, `lib/features/friend/presentation/pages/friend_list_page.dart`, `lib/features/friend/presentation/pages/notification_page.dart`, `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `lib/features/friend/presentation/widgets/friend_list_item.dart`, `lib/features/friend/presentation/widgets/notification_item.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format ...` 통과, `flutter test test/core/utils/color_parser_test.dart` 통과, `git diff --check` 통과. `flutter analyze ...`는 타입/컴파일 오류 없이 완료됐지만 기존 프로젝트 snake_case 네이밍 규칙과 Flutter analyzer lowerCamelCase 규칙 충돌, 기존 미사용 `_showTimezonePicker`, deprecated API info 등 74건으로 exit 1.
  - 롤백: `AppTheme`의 Shift Harmony 토큰/`cardDecoration()` 추가와 각 화면의 `AppTheme` 토큰 참조를 이전 `CupertinoColors.*`/파일별 `Color(...)`/shadow 기반 스타일로 되돌린다. `_docs/PROJECT_CONTEXT.md`의 UI 디자인 시스템 섹션과 `_docs/DECISIONS.md`의 ADR-0003을 제거한다.
  - 다음: 실제 iOS/Android 기기에서 캘린더, 개인 일정 모달, 친구 상세/추가 모달, 알림 카드, 근무 타입 설정 화면을 열어 카드 반경/보더/텍스트 크기와 긴 한글 텍스트 overflow를 확인

- [DONE] (FE) 개인 일정 등록 화면 미리보기 overflow 수정
  - 목적: 개인 일정 등록 화면의 하단 미리보기 일러스트에서 발생하는 `RenderFlex overflowed` 오류를 제거한다.
  - 변경: 하단 미리보기 카드의 휴대폰 내부 미니 스케줄 UI에서 고정 높이 합이 내부 제약보다 커지던 문제를 수정했다. 미니 상태 점, 라인, 일정 블록, 간격 높이를 줄여 94px 내부 높이 안에 들어가도록 조정했다.
  - 영향범위: 개인 일정 등록 화면 하단 미리보기 일러스트 렌더링
  - 파일: `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `flutter analyze lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `git diff --check` 통과
  - 롤백: `_buildPreviewIllustration()`의 미니 스케줄 상태 점/라인/일정 블록/간격 높이를 이전 값으로 되돌린다.
  - 다음: 앱에서 개인 일정 등록 화면을 다시 열어 노란/검은 overflow 표시와 콘솔 `RenderFlex overflowed` 로그가 사라졌는지 확인

- [DONE] (FE) 개인 일정 등록 화면 디자인 수정
  - 목적: 제공된 디자인 시안을 참고해 개인 일정 등록 화면의 정보 구조와 시각 스타일을 정리한다.
  - 변경: `PersonalEventFormModal`을 시안 기반의 전체 화면 카드형 레이아웃으로 재구성했다. 기본 정보는 제목 밑줄 입력, 장소 선택 행, 메모 박스로 정리했고 장소 행은 입력/삭제 다이얼로그를 띄우도록 했다. 일시 섹션은 종일 토글, 시작/종료 날짜+시간 행, 반복 `안 함` 안내 행으로 바꿨다. 공개 설정은 0~5 세그먼트 트랙에서 탭/드래그로 선택하게 했고, 공개 레벨 설명은 현재 DB 규칙(`friend_level >= visibility_level`)에 맞춰 표시한다. 하단에는 외부 네트워크 이미지 없이 코드 기반 스케줄 미리보기 카드를 추가했다.
  - 영향범위: 메인 캘린더의 개인 일정 등록 모달 UI, 장소 입력 방식, 일시 선택 표시, 공개 레벨 선택/설명 표시, 개인 일정 화면 문서
  - 파일: `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/EVENT_API_GUIDE.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `flutter analyze lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `git diff --check` 통과
  - 롤백: `PersonalEventFormModal`의 카드형 섹션/장소 다이얼로그/반복 안내/세그먼트 공개 레벨/미리보기 카드 변경을 제거하고 기존 `CupertinoListSection.insetGrouped` 기반 제목·장소·메모·일시·드래그 공개 레벨 구성으로 되돌린다. PROJECT_CONTEXT와 EVENT_API_GUIDE의 화면 구조 설명을 이전 내용으로 되돌린다.
  - 다음: iOS 시뮬레이터에서 제목/장소/메모 입력, 날짜/시간 선택, 종일 토글, 공개 레벨 탭/드래그, 저장 요청 값(`place`, `visibility_level`)을 확인

- [DONE] (FE) 친구 요청 수락 후 친구 캘린더 이동
  - 목적: 알림에서 친구 요청을 수락하면 수락된 친구의 스케줄/캘린더 화면을 바로 보여준다.
  - 변경: `NotificationPage`에서 친구 요청 수락 액션 성공 후 친구 목록을 다시 조회하고, 알림 `payload.related_user_id`와 일치하는 `FriendModel`을 찾아 `FriendCalendarPage`로 이동하도록 했다. 거절 액션은 기존처럼 목록 새로고침만 수행하고 화면 이동하지 않는다. 수락 후 친구 정보를 찾지 못하면 오류 다이얼로그를 표시한다.
  - 영향범위: 알림 페이지 친구 요청 수락 후 화면 전환, 친구 목록 Provider 재조회, 친구 캘린더 진입 흐름
  - 파일: `lib/features/friend/presentation/pages/notification_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/presentation/pages/notification_page.dart` 통과, `flutter analyze lib/features/friend/presentation/pages/notification_page.dart lib/features/friend/presentation/pages/friend_calendar_page.dart lib/features/friend/presentation/providers/friend_provider.dart` 통과, `git diff --check` 통과
  - 롤백: `NotificationPage`의 `FriendCalendarPage`/`FriendModel` import, `_navigateToAcceptedFriendCalendar()`, `_findFriendById()`를 제거하고, 수락 성공 시 친구 목록만 다시 불러오도록 되돌린다. PROJECT_CONTEXT의 수락 후 친구 캘린더 이동 설명을 제거한다.
  - 다음: 실제 기기에서 친구 요청 알림 수락 후 수락한 친구의 캘린더 화면으로 이동하고, 거절 시에는 이동하지 않는지 확인

- [DONE] (FE) 친구 삭제 후 친구 리스트 복귀 보장
  - 목적: 친구 리스트 > 친구 캘린더 > 설정 > 삭제 흐름에서 삭제 성공 후 친구 캘린더가 남지 않고 친구 리스트 화면으로 복귀하게 한다.
  - 변경: `FriendDetailPage`가 삭제 성공 시 직접 두 번 pop하지 않고 `Navigator.of(context).pop(true)`로 삭제 결과를 반환하도록 변경했다. `FriendCalendarPage._navigateToSettings()`는 `FriendDetailPage` push 결과를 `await`하고, 결과가 `true`이면 자기 자신을 한 번 pop해 친구 리스트로 복귀한다. 연속 pop이 route 전환 중 두 번째 pop을 처리하지 못해 친구 캘린더가 남는 문제를 결과 전달 방식으로 제거했다.
  - 영향범위: 친구 리스트 > 친구 캘린더 > 친구 정보 > 삭제 성공 후 화면 복귀 동작
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `lib/features/friend/presentation/pages/friend_detail_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/presentation/pages/friend_detail_page.dart lib/features/friend/presentation/pages/friend_calendar_page.dart` 통과, `flutter analyze lib/features/friend/presentation/pages/friend_detail_page.dart lib/features/friend/presentation/pages/friend_calendar_page.dart` 통과, `git diff --check` 통과
  - 롤백: `FriendCalendarPage._navigateToSettings()`를 단순 push로 되돌리고, `FriendDetailPage` 삭제 성공 시 기존 단일 pop 또는 이전 `_popAfterDeleteSuccess()` 방식으로 되돌린다. PROJECT_CONTEXT의 삭제 결과 반환 설명을 제거한다.
  - 다음: 실제 기기에서 친구 리스트 > 친구 > 설정 > 삭제 확인 후 친구 리스트 화면이 남고 삭제된 친구 행이 사라지는지 확인

- [DONE] (FE) 친구 삭제 성공 후 두 단계 뒤로가기 적용
  - 목적: 친구 상세 화면에서 친구 삭제 확인 시 삭제 성공 후 뒤로가기를 두 번 실행해 이전 중간 화면까지 함께 닫는다.
  - 변경: `FriendDetailPage._deleteFriend()`에서 삭제 API 성공 후 `_popAfterDeleteSuccess()`를 호출하도록 변경했다. `_popAfterDeleteSuccess()`는 현재 `Navigator`를 보관한 뒤 `canPop()`이 허용하는 범위에서 최대 두 번 `pop()`을 실행해 친구 상세 화면과 직전 친구 캘린더 화면을 함께 닫는다. 삭제 API 응답 대기 중 화면이 사라진 경우 `setState()`가 실행되지 않도록 `mounted` 확인을 추가했다.
  - 영향범위: 친구 상세 화면의 친구 삭제 성공 후 화면 복귀 동작
  - 파일: `lib/features/friend/presentation/pages/friend_detail_page.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/presentation/pages/friend_detail_page.dart` 통과, `flutter analyze lib/features/friend/presentation/pages/friend_detail_page.dart` 통과, `git diff --check` 통과
  - 롤백: `_popAfterDeleteSuccess()`를 제거하고 삭제 성공 시 기존처럼 `Navigator.of(context).pop()` 한 번만 호출하도록 되돌린다. PROJECT_CONTEXT의 친구 삭제 두 단계 뒤로가기 설명을 제거한다.
  - 다음: 실제 기기에서 친구 캘린더 → 친구 정보 → 친구 삭제 확인 후 친구 목록 화면까지 돌아가는지 확인

- [DONE] (FE) 친구 요청 수락 시 알림 카드 사라짐 원인 확인
  - 목적: 친구 요청 수락 버튼을 누르면 처리 완료 카드로 교체되지 않고 알림이 화면에서 사라지는 문제를 확인한다.
  - 변경: 알림 Provider에 로컬 처리 완료 알림 캐시를 추가했다. 수락/거절 버튼을 누르면 낙관적 완료 알림을 캐시에 저장하고, `loadNotifications()`/`loadMore()`가 서버 목록을 다시 가져올 때 같은 `notification_id` 또는 `payload.request_id` 기준으로 로컬 완료 알림을 병합한다. 서버 목록에 처리 완료 알림이 빠져 있거나 응답 처리 중 재조회가 끼어들어도 현재 화면의 완료 알림 카드가 사라지지 않도록 했다. 서버 응답의 알림 ID가 원본과 달라도 `request_id` 기준으로 중복 캐시를 제거한다.
  - 영향범위: 알림 페이지 친구 요청 수락/거절 후 카드 유지, 알림 목록 새로고침/페이지네이션 병합, 친구 요청 알림 응답 문서
  - 파일: `lib/features/friend/presentation/providers/notification_provider.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/presentation/providers/notification_provider.dart` 통과, `flutter analyze lib/features/friend/presentation/providers/notification_provider.dart lib/features/friend/data/models/notification_model.dart lib/features/friend/data/models/friend_request_model.dart` 통과, `git diff --check` 통과
  - 롤백: `NotificationNotifier`의 `_locallyRespondedNotifications`, `_mergeLocalRespondedNotifications`, `_cacheLocalRespondedNotification`, `_removeLocalRespondedNotification`, `_isSameNotification` 병합/캐시 로직을 제거하고 `loadNotifications()`/`loadMore()`가 서버 응답 목록만 사용하도록 되돌린다. PROJECT_CONTEXT의 로컬 병합 설명을 제거한다.
  - 다음: 실제 기기에서 친구 요청 수락/거절 직후 카드가 처리 완료 상태로 유지되는지, 당겨서 새로고침 후에도 현재 화면에서 사라지지 않는지 확인

- [DONE] (FE) 친구 요청 알림 응답 낙관적 UI 반영
  - 목적: 친구 요청 알림에서 수락/거절 버튼을 누른 즉시 서버가 갱신할 알림 상태를 화면에 먼저 반영한다.
  - 변경: `NotificationNotifier.handleNotificationAction()`이 친구 요청 수락/거절 버튼 탭 시 원본 `FRIEND_REQUEST` 알림을 즉시 처리 완료 알림으로 교체하도록 했다. 낙관적 알림은 `FRIEND_REQUEST_ACCEPTED`/`FRIEND_REQUEST_REJECTED`, `actions=[]`, `is_read=true`, `payload.request_status`, `responded_at` 값을 사용한다. 서버 성공 응답의 `data.notification`이 있으면 해당 객체로 다시 교체하고, 없으면 응답 `responded_at` 기준의 완료 알림을 유지한다. 실패 시 원본 알림 목록으로 롤백한다. 알림 모델은 신규 타입과 기존 `FRIEND_ACCEPTED`/`FRIEND_REJECTED` 타입을 모두 파싱하고, 친구 요청 응답 모델은 `data.notification`을 파싱한다.
  - 영향범위: 알림 페이지 친구 요청 수락/거절 카드 표시, 알림 액션 버튼 제거 시점, 친구 요청 응답 API 파싱, 친구 요청 알림 API 문서
  - 파일: `lib/features/friend/presentation/providers/notification_provider.dart`, `lib/features/friend/data/models/notification_model.dart`, `lib/features/friend/data/models/friend_request_model.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_API_GUIDE.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/data/models/notification_model.dart lib/features/friend/data/models/friend_request_model.dart lib/features/friend/presentation/providers/notification_provider.dart` 통과, `flutter analyze lib/features/friend/data/models/notification_model.dart lib/features/friend/data/models/friend_request_model.dart lib/features/friend/presentation/providers/notification_provider.dart` 통과, `git diff --check` 통과
  - 롤백: `NotificationNotifier`의 `_respondToFriendRequest`, `_buildRespondedNotification`, `_replaceNotification` 흐름을 제거하고 기존 성공 후 `_removeNotification` 방식으로 되돌린다. `RespondRequestData.notification`과 `NotificationPayload.requestStatus/respondedAt`, 신규 알림 타입 파싱, 관련 문서 변경을 제거한다.
  - 다음: 실제 API에서 수락/거절 시 버튼이 즉시 사라지고 처리 완료 문구로 바뀐 뒤, 새로고침 후에도 서버 `data.notification`과 동일한 카드가 유지되는지 확인

- [DONE] (FE) 개인 일정 공개 레벨 드래그 선택 UI 적용
  - 목적: 개인 일정 추가 모달의 공개 레벨 선택을 개별 버튼 클릭 방식이 아니라 좌우 드래그 방식으로 변경한다.
  - 변경: 공개 레벨 0~5 개별 `GestureDetector` 버튼 Row를 제거하고, 하나의 드래그 트랙과 선택 핸들 UI로 교체했다. 사용자가 트랙을 좌우로 드래그하면 터치 위치를 0~5 레벨로 매핑해 `_visibilityLevel`을 갱신한다. 선택된 레벨은 파란 핸들과 채워진 트랙으로 표시한다.
  - 영향범위: 개인 일정 추가 모달의 공개 레벨 선택 UI/상호작용
  - 파일: `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `flutter analyze lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `git diff --check` 통과
  - 롤백: `_buildVisibilityLevelDragSelector()`와 `_updateVisibilityLevelFromDrag()`를 제거하고, 기존 0~5 버튼 Row와 각 버튼 `onTap` 상태 변경 로직으로 되돌린다. PROJECT_CONTEXT의 드래그 트랙 설명을 제거한다.
  - 다음: iOS 시뮬레이터에서 공개 레벨 트랙을 좌우로 드래그할 때 0~5 값이 자연스럽게 바뀌고 저장 요청의 `visibility_level`에 반영되는지 확인

## 2026-07-07

- [DONE] (FE) 개인 일정 모달 공개 설정 내부 Text 영역 제거
  - 목적: 개인 일정 추가 모달의 공개 설정 섹션에서 중복 표시되는 내부 Text 영역을 제거한다.
  - 변경: 공개 설정 섹션 내부의 `Text('공개 설정')`과 바로 아래 세로 간격을 제거해 섹션 헤더만 남기고 레벨 버튼이 바로 표시되도록 했다.
  - 영향범위: 개인 일정 추가 모달의 공개 설정 섹션 레이아웃
  - 파일: `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `flutter analyze lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `git diff --check` 통과
  - 롤백: 제거한 `Text('공개 설정')`과 `SizedBox(height: 12)`를 다시 추가한다.
  - 다음: 앱에서 공개 설정 섹션에 중복 라벨 없이 레벨 버튼만 보이는지 확인

- [DONE] (FE) 개인 일정 모달 공개 설정 라벨 문구 변경
  - 목적: 개인 일정 추가 모달의 공개 레벨 선택 영역 표시 문구를 요청한 용어로 맞춘다.
  - 변경: 공개 레벨 선택 영역의 내부 라벨 `공개 레벨`을 `공개 설정`으로 변경했다.
  - 영향범위: 개인 일정 추가 모달의 공개 설정 섹션 표시 문구
  - 파일: `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `flutter analyze lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `git diff --check` 통과
  - 롤백: 해당 `Text` 문구를 `공개 레벨`로 되돌린다.
  - 다음: 앱에서 개인 일정 추가 모달의 공개 설정 섹션 문구 확인

- [DONE] (FE) 개인 일정 모달 전체 높이 고정 및 스와이프 닫기 개선
  - 목적: 개인 일정 추가 모달이 처음부터 화면 상단까지 차도록 만들고, 키보드 표시 시 모달 자체가 줄거나 내려갔다 올라오는 애니메이션 없이 입력할 수 있게 한다.
  - 변경: `PersonalEventFormModal`의 `AnimatedPadding`과 `screenHeight - keyboardHeight` 기반 높이 계산, 0.92 배율, 상단 둥근 모서리 클리핑을 제거했다. 모달은 `CupertinoPageScaffold` 전체 화면으로 고정 표시하고, `MediaQuery.viewInsets`는 내부 Scaffold에 전달하지 않는다. 키보드 높이는 `ListView`의 하단 padding에만 반영해 모달 자체 위치/높이 애니메이션이 발생하지 않도록 했다. `ScrollController`와 `Listener`를 사용해 리스트가 맨 위에 있을 때 아래로 당기면 모달을 닫도록 했다.
  - 영향범위: 개인 일정 추가 모달 초기 표시 높이, 상단 여백, 키보드 표시 시 움직임, 아래 스와이프 닫기 동작
  - 파일: `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/widgets/personal_event_form_modal.dart lib/features/calendar/presentation/pages/calendar_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/widgets/personal_event_form_modal.dart lib/features/calendar/presentation/pages/calendar_page.dart`에서 컴파일/타입 오류 없음(기존 `CalendarPage` snake_case/print info 10건은 남음), `git diff --check` 통과
  - 롤백: `PersonalEventFormModal`을 이전 `AnimatedPadding` + 0.92 높이 + `ClipRRect` 구조로 되돌리고, `_scrollController`/포인터 드래그 닫기 로직을 제거한다. PROJECT_CONTEXT의 전체 화면 고정/스와이프 닫기 설명도 제거한다.
  - 다음: iOS 시뮬레이터에서 모달 첫 표시가 상단까지 차는지, 제목/장소/메모 입력 시 모달 위치가 흔들리지 않는지, 리스트 최상단에서 아래 스와이프 시 닫히는지 확인

- [DONE] (FE) 개인 일정 모달 키보드 표시 시 레이아웃 깨짐 수정
  - 목적: 개인 일정 추가 모달에서 텍스트 입력 시 키보드가 올라오면 배경 캘린더와 모달 본문이 함께 줄어들어 화면이 깨지는 문제를 수정한다.
  - 변경: `CalendarPage`와 `PersonalEventFormModal`의 `CupertinoPageScaffold.resizeToAvoidBottomInset`을 `false`로 설정했다. 배경 캘린더는 키보드 표시 시 리사이즈되지 않게 하고, 개인 일정 모달은 기존 `AnimatedPadding`/`viewInsets.bottom` 계산만으로 키보드 위 위치와 높이를 제어하도록 정리했다.
  - 영향범위: 개인 일정 모달 텍스트 입력 시 키보드 표시 레이아웃, 배경 캘린더 선택일 카드 overflow 방지
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`에서 컴파일/타입 오류 없음(기존 `CalendarPage` snake_case/print info 10건은 남음), `git diff --check` 통과
  - 롤백: 두 `CupertinoPageScaffold`의 `resizeToAvoidBottomInset: false` 설정을 제거한다.
  - 다음: iOS 시뮬레이터에서 개인 일정 모달의 제목/장소/메모 입력 시 모달 본문이 잘리지 않고 배경 캘린더 overflow 로그가 사라지는지 확인

- [DONE] (FE/DOCS) 개인 일정 추가 모달 및 API 요청 문서 작성
  - 목적: 메인 화면의 `일정 추가하기` 동작에서 개인 일정을 입력할 수 있는 모달을 띄우고, 서버가 구현해야 할 개인 일정 생성 API 계약과 DB 반영 필요 여부를 문서화한다.
  - 변경: 선택일 카드의 `일정 추가하기...` placeholder를 개인 일정 입력 모달로 교체했다. 모달은 제목, 장소, 메모, 종일 여부, 시작/종료 일시, 공개 레벨(0~5)을 입력받고 `POST /api/v1/events` 생성 요청으로 저장한다. 생성 성공 시 응답 `EventApiModel`을 현재 캘린더 날짜별 일정 맵에 즉시 반영한다. `start_at`/`end_at`은 UTC ISO 문자열로 요청하고 응답은 로컬 시간으로 표시한다. 종일 일정 중복 표시를 막기 위해 `end_at`은 배타적 종료 시각으로 해석한다. 개인 일정 API 문서와 ADR, 프로젝트 컨텍스트를 추가했다.
  - 영향범위: 메인 캘린더 선택일 카드의 개인 일정 추가 UX, 개인 일정 생성 API 호출, 이벤트 시간 파싱/날짜별 표시, 개인 일정 서버 구현 문서, 공개 레벨 정책 문서
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`, `lib/features/calendar/data/models/event_api_model.dart`, `lib/features/calendar/data/services/calendar_service.dart`, `_docs/EVENT_API_GUIDE.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/data/models/event_api_model.dart lib/features/calendar/data/services/calendar_service.dart lib/features/calendar/presentation/pages/calendar_page.dart lib/features/calendar/presentation/widgets/personal_event_form_modal.dart` 통과, `flutter analyze lib/features/calendar/data/models/event_api_model.dart lib/features/calendar/data/services/calendar_service.dart lib/features/calendar/presentation/pages/calendar_page.dart lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`에서 컴파일/타입 오류 없음(기존 `CalendarPage` snake_case/print info 10건은 남음), `flutter test test/core/utils/color_parser_test.dart` 통과, `git diff --check` 통과
  - 롤백: `CalendarPage`의 `_showPersonalEventModal`, `_addEventToDateMap` 연결과 `PersonalEventFormModal` import를 제거하고 `일정 추가하기...` 버튼을 기존 placeholder 다이얼로그로 되돌린다. `CalendarService.createEvent`, `CreateEventRequest`, `personal_event_form_modal.dart`, `_docs/EVENT_API_GUIDE.md`, ADR-0002와 PROJECT_CONTEXT 개인 일정 생성 섹션을 제거한다.
  - 다음: 서버에 `POST /api/v1/events`를 구현하고, 실제 계정에서 공개 레벨 0~5와 친구 캘린더 조회 조건(`can_view`, `friend_level >= visibility_level`)을 조합별로 확인

## 2026-07-06

- [DONE] (FE/DOCS) 메인 캘린더 근무표 표시 데이터 소스 분리
  - 목적: 계정 전환 후 이전 계정의 `shiftTypesProvider` 캐시가 메인 달력의 저장된 근무 색상/이름/시간 표시에 섞이지 않도록 한다.
  - 변경: `CalendarPage`가 `/calendar/range`의 `WorkShiftApiModel` 전체를 날짜별 표시 데이터로 보관하고, 저장된 근무표의 달력 배지/확장 셀/선택일 카드는 서버 응답의 `shift_type_color`, `shift_type_name`, `start_time`, `end_time`을 직접 사용하도록 변경했다. 근무 추가 모드의 임시 선택/버튼 표시는 기존처럼 `shiftTypesProvider`를 사용한다. 배치 저장 응답과 삭제 결과도 표시용 근무표 맵에 반영한다. 로그인/로그아웃 시 근무 타입/템플릿/친구/알림 Provider 캐시를 무효화한다. 설계 결정 ADR과 프로젝트 컨텍스트를 갱신했다.
  - 영향범위: 메인 캘린더 저장 근무표 표시 색상/이름/시간, 근무 추가 후 즉시 표시 상태, 근무 삭제 후 로컬 표시 상태, 계정 전환 시 계정 단위 Provider 캐시 초기화, 캘린더 표시 데이터 소스 문서
  - 파일: `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/auth/presentation/providers/auth_provider.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/calendar/presentation/pages/calendar_page.dart lib/features/auth/presentation/providers/auth_provider.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/calendar_page.dart lib/features/auth/presentation/providers/auth_provider.dart`에서 컴파일/타입 오류 없음(기존 네이밍/print/미사용 함수 info/warning 18건은 남음), `flutter test test/core/utils/color_parser_test.dart` 통과, `git diff --check` 통과
  - 롤백: `CalendarPage`의 `_workShifts` 저장/표시 경로를 제거하고 기존 `shiftTypesMapProvider` 기반 표시로 되돌린다. `AuthNotifier`의 Provider 무효화 로직과 ADR/PROJECT_CONTEXT의 데이터 소스 분리 설명을 제거한다.
  - 다음: 실제 계정 A/B를 번갈아 로그인해 `/calendar/range` 응답의 `shift_type_color`와 메인 달력/선택일 카드 색상이 일치하는지 기기에서 확인

- [DONE] (FE) Flutter 로컬 실행 방법 및 실행 전 오류 점검
  - 목적: VS Code/CLI Flutter 실행 설정, 환경변수 전달, 연결 기기, 정적분석 결과를 확인해 로컬 실행 가능 상태를 점검한다.
  - 변경: `flutter doctor -v`, `flutter devices`, `.vscode/launch.json`, `.env`, iOS/Android 카카오 secret 연결을 확인했다. 개발 API 호스트를 `172.30.1.13:3000`으로 갱신했다. `flutter analyze`에서 발견된 실제 컴파일 오류인 `BottomActionBar`의 존재하지 않는 `onMemoTap` 인자 사용을 현재 위젯 API인 `onFriendTap`으로 수정했다. iOS 시뮬레이터에서 `flutter run -d 665D5DEE-E4EE-42E0-97AE-FE47C1791135 --dart-define-from-file=.env` 실행 성공을 확인했다. `devtools_options.yaml`은 Dart/Flutter DevTools 확장 활성화 상태를 저장하는 프로젝트 설정 파일이며 런타임 의존성은 없다.
  - 영향범위: 개발 환경 API base URL, 근무 추가 페이지 하단 액션 바 첫 번째 버튼 콜백 연결, Flutter DevTools 설정, Flutter 로컬 실행 점검 기록
  - 파일: `lib/core/constants/api_constants.dart`, `lib/features/calendar/presentation/pages/shift_add_page.dart`, `devtools_options.yaml`, `_docs/WORKLOG.md`
  - 테스트: `flutter pub get` 통과, `dart format lib/features/calendar/presentation/pages/shift_add_page.dart` 통과, `flutter analyze lib/features/calendar/presentation/pages/shift_add_page.dart`에서 컴파일 오류 없음(기존 snake_case 정보 6건만 남음), iOS 시뮬레이터 앱 실행 및 `/auth/profile` 요청 발생 확인
  - 롤백: 개발 API 호스트를 이전 IP로 되돌리고, `shift_add_page.dart`의 `onFriendTap` 인자를 제거하거나 기존 호출부로 되돌린다. `devtools_options.yaml`이 불필요하면 삭제하고 실행 점검 기록은 이 항목에서 제거한다.
  - 다음: Android 실행 전 `flutter doctor --android-licenses`로 미수락 라이선스를 처리하고, 프로젝트 네이밍 컨벤션과 Dart analyzer 규칙 충돌을 별도 정책으로 정리한다.

## 2026-07-05

- [DONE] (FE/DOCS) 친구 캘린더 조회 페이지 및 API 요청 문서 작성
  - 목적: 친구 리스트 항목 선택 시 설정 화면이 아니라 친구 캘린더 조회 화면으로 진입하고, 해당 화면에서 친구 근무표와 공개 레벨에 맞는 개인 일정을 조회할 수 있게 한다.
  - 변경: `FriendCalendarPage`를 추가해 친구 프로필, 월 캘린더, 날짜별 근무 코드, 선택 날짜의 근무/일정 목록을 표시한다. 친구 목록 Row 탭 이동 대상을 친구 캘린더로 변경하고, 친구 캘린더 우측 설정 버튼에서 기존 `FriendDetailPage`로 이동하도록 연결했다. `FriendService.getFriendCalendarRange()`와 API 요청 문서를 추가했다.
  - 영향범위: 친구 목록 탭 동작, 친구 캘린더 읽기 전용 조회 화면, 친구 캘린더 기간 조회 API 서버 계약 문서, 프로젝트 컨텍스트 문서
  - 파일: `lib/features/friend/presentation/pages/friend_calendar_page.dart`, `lib/features/friend/presentation/pages/friend_list_page.dart`, `lib/features/friend/data/services/friend_service.dart`, `_docs/FRIEND_API_GUIDE.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: `dart format lib/features/friend/presentation/pages/friend_calendar_page.dart lib/features/friend/data/services/friend_service.dart lib/core/constants/api_constants.dart` 통과, `flutter analyze lib/features/friend/data/services/friend_service.dart lib/features/friend/presentation/pages/friend_list_page.dart lib/features/friend/presentation/pages/friend_calendar_page.dart` 통과
  - 롤백: `FriendListPage`의 이동 대상을 `FriendDetailPage`로 되돌리고, `FriendCalendarPage` 파일과 `FriendService.getFriendCalendarRange()`를 제거한다. 문서의 친구 캘린더/API 조회 섹션을 삭제한다.
  - 다음: 서버에 `GET /api/v1/friends/:friend_user_id/calendar/range`를 구현한 뒤 실제 친구 계정으로 `can_view`, `friend_level`, `visibility_level` 조합별 응답을 확인

- [DONE] (DOCS) 로컬 전용 디버깅 문서 및 env 예시 ignore 명시
  - 목적: 개인 OAuth 디버깅 메모와 로컬 환경 예시 파일이 커밋 후보로 올라오지 않도록 한다.
  - 변경: `.gitignore`에 `NAVER_LOGIN_CHECKLIST.md`, `NAVER_OAUTH_URL_EXPLANATION.md`, `.env.example`을 명시적으로 추가했다.
  - 영향범위: Git 추적 대상 필터링, 로컬 전용 문서/환경 파일 관리
  - 파일: `.gitignore`, `_docs/WORKLOG.md`
  - 테스트: `git status --short --ignored`에서 `.env.example`, `NAVER_LOGIN_CHECKLIST.md`, `NAVER_OAUTH_URL_EXPLANATION.md`가 `!!` ignored로 표시됨을 확인
  - 롤백: `.gitignore`에서 해당 3개 항목을 제거하고, 필요하면 파일을 다시 `git add` 대상으로 올린다.
  - 다음: 커밋 분리 시 `.gitignore`와 이 작업 로그를 문서/관리 커밋에 포함

- [DONE] (FE) 친구 추가 모달 최대 확장 상단 여백 조정
  - 목적: 크기 조절 가능한 친구 추가 모달이 iOS sheet처럼 상태표시줄/상단 영역을 침범하지 않고 상단 여백을 남기도록 한다.
  - 변경: Flutter `CupertinoSheetRoute`/`showCupertinoSheet`의 기본 `topGap=0.08` 동작을 커스텀 모달에 맞춰 반영했다. 최대 높이를 화면 높이의 92%로 제한하고, 키보드 표시 시에도 화면 높이의 8% 상단 여백을 남긴다. 최대 확장 상태에서도 상단 둥근 모서리를 유지한다.
  - 영향범위: 친구 추가 모달 최대 확장 위치, 키보드 표시 시 모달 상단 위치, 친구 기능 설계 문서
  - 파일: `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `_docs/FRIEND_FEATURE_DESIGN.md`
  - 테스트: `dart format lib/features/friend/presentation/widgets/add_friend_modal.dart` 통과, `flutter analyze lib/features/friend/presentation/widgets/add_friend_modal.dart` 통과
  - 롤백: `_sheetTopGapFactor`와 `_maxSheetHeightFactor=0.92` 계산을 제거하고 기존 최대 높이 `1.0`으로 되돌린다. 키보드 표시 시 `topGap` 차감도 제거한다.
  - 다음: 실제 iOS 기기에서 최대 확장 시 상단이 상태표시줄 아래에 머무르는지 확인

- [DONE] (FE) 친구 검색 전화번호 정규화 및 키보드 대응 모달 위치 수정
  - 목적: 전화번호 검색 요청을 서버 기대 형식으로 정규화하고, 키보드 표시 시 친구 추가 모달이 키보드 위로 올라오도록 한다.
  - 변경: 전화번호 입력을 검색 실행 시 `000-0000-0000` 또는 `000-000-0000` 형식으로 정규화해 입력창과 API 요청값에 반영했다. 키보드 표시 시 `MediaQuery.viewInsets.bottom`을 모달 하단 패딩과 높이에 반영해 모달이 키보드 위 가용 영역으로 이동하도록 수정했다. DebugMCP는 사용 가능하나 이번 원인은 `viewInsets` 미반영으로 코드에서 확인 가능해 실제 디버그 세션은 열지 않았다.
  - 영향범위: 친구 추가 모달 전화번호 검색 요청값, 키보드 표시 시 모달 위치/높이, 친구 검색 문서
  - 파일: `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `_docs/FRIEND_API_GUIDE.md`, `_docs/FRIEND_FEATURE_DESIGN.md`
  - 테스트: `dart format lib/features/friend/presentation/widgets/add_friend_modal.dart` 통과, `flutter analyze lib/features/friend/presentation/widgets/add_friend_modal.dart` 통과
  - 롤백: `AddFriendModal`의 `AnimatedPadding`/키보드 높이 계산과 전화번호 정규화 헬퍼를 제거하고 검색 요청을 기존 원문 query 전달로 되돌린다. 문서의 정규화/키보드 대응 설명을 제거한다.
  - 다음: 실제 기기에서 `01012345678`, `010-1234-5678`, `+821012345678` 검색 요청값과 키보드 표시 시 모달 위치를 확인

- [DONE] (FE) 친구 추가 모달 검색 입력 UX 및 드래그 동작 개선
  - 목적: 친구 검색 전 이메일/전화번호 형식을 프론트에서 안내하고, 엔터 외 검색 버튼과 드래그로 모달 확대/닫기 동작을 제공한다.
  - 변경: 검색창 오른쪽 검색 아이콘 버튼 추가, 이메일/전화번호 로컬 형식 검증 및 검색창 하단 말풍선 안내 추가, 상단 핸들 드래그로 모달 최소/기본/전체 화면 스냅 및 아래 드래그 닫기 추가
  - 영향범위: 친구 추가 모달 검색 실행 UX, 검색 요청 전 입력 검증, 모달 표시/닫기 상호작용, 친구 검색 문서
  - 파일: `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `_docs/FRIEND_API_GUIDE.md`, `_docs/FRIEND_FEATURE_DESIGN.md`
  - 테스트: `dart format lib/features/friend/presentation/widgets/add_friend_modal.dart` 통과, `flutter analyze lib/features/friend/presentation/widgets/add_friend_modal.dart` 통과
  - 롤백: `AddFriendModal`의 검색 버튼/검증 말풍선/드래그 높이 상태와 관련 헬퍼를 제거하고 기존 고정 높이 모달로 되돌린다. 문서의 검색 버튼/검증/드래그 설명을 제거한다.
  - 다음: 기기에서 잘못된 입력, 엔터 검색, 버튼 검색, 위/아래 드래그 닫기 제스처를 확인

- [DONE] (FE) 친구 검색 단일 결과 UI 반영
  - 목적: 이메일/전화번호 유니크 검색 결과가 최대 1명이라는 API 계약에 맞게 친구 추가 모달 디자인을 단일 결과 카드 중심으로 변경한다.
  - 변경: 친구 추가 모달 높이와 검색 결과 영역을 조정하고, 검색 성공 시 단일 사용자 카드 1개만 표시하도록 UI를 정리했다. 입력값 변경 시 이전 검색 결과를 즉시 초기화하고 검색 Provider의 디버그 출력을 제거했다. 친구 검색 API/기능 설계 문서에 단일 결과 계약을 명시했다.
  - 영향범위: 친구 목록 화면의 `AddFriendModal`, 친구 검색 Provider 로그 출력, 친구 검색 API/UX 문서
  - 파일: `lib/features/friend/presentation/widgets/add_friend_modal.dart`, `lib/features/friend/presentation/providers/friend_provider.dart`, `_docs/FRIEND_API_GUIDE.md`, `_docs/FRIEND_FEATURE_DESIGN.md`
  - 테스트: `dart format lib/features/friend/presentation/widgets/add_friend_modal.dart lib/features/friend/presentation/providers/friend_provider.dart` 통과, `flutter analyze lib/features/friend/presentation/widgets/add_friend_modal.dart lib/features/friend/presentation/providers/friend_provider.dart` 통과
  - 롤백: `AddFriendModal`의 카드 레이아웃/높이/입력 변경 초기화 로직을 이전 구현으로 되돌리고, 문서의 단일 결과 설명을 제거한다.
  - 다음: 실제 API 검색 성공/미검색/이미 친구/대기 요청 케이스별 모달 표시를 기기에서 확인

- [DONE] (FE) 근무 타입 색상 파싱 오류 수정
  - 목적: 근무 타입 확인/설정 화면에서 서버가 반환하는 `#AARRGGBB` 색상 문자열을 실제 색상으로 표시한다.
  - 변경: API 색상 응답 공통 파서 추가, 근무 타입/근무표 모델의 10진수 전용 문자열 파싱을 공통 파서로 교체
  - 영향범위: 근무 타입 설정 카드 색상, 캘린더 근무표 색상 응답 파싱
  - 파일: `lib/core/utils/color_parser.dart`, `lib/features/calendar/data/models/shift_type_api_model.dart`, `lib/features/calendar/data/models/work_shift_api_model.dart`, `test/core/utils/color_parser_test.dart`, `_docs/PROJECT_CONTEXT.md`
  - 테스트: `flutter test test/core/utils/color_parser_test.dart` 통과, 변경 파일 대상 `flutter analyze ...` 통과
  - 롤백: 모델의 `parseApiColorValue(...)` 호출을 기존 로컬 `int.tryParse(...)` 파싱으로 되돌리고 `color_parser.dart`/테스트를 제거한다.
  - 다음: 앱 실행 시 사용자 `0b58bbf9-f0a3-4644-ae7b-bd81b1117015`의 `#FF007AFF`, `#FF34C759`, `#FFFF9500`, `#FFF5A623` 표시 확인

## 프로젝트 초기 설정

### 완료된 작업

1. **프로젝트 구조 설정**

   - Feature 기반 폴더 구조 생성
   - Core 인프라 레이어 구성 (network, services, theme)

2. **인증 시스템 구현**

   - 카카오 OAuth 로그인 통합
   - JWT 토큰 관리 (Flutter Secure Storage)
   - 토큰 자동 갱신 인터셉터 구현
   - 인증 상태 관리 (Riverpod StateNotifier)

3. **네트워크 레이어 구현**

   - Dio 클라이언트 설정
   - 인증 인터셉터 (토큰 주입, 자동 갱신)
   - 에러 처리 매핑 (DioException → ApiException)
   - 로깅 인터셉터

4. **캘린더 기능 구현**

   - Table Calendar 통합
   - 근무 타입 조회 및 표시
   - 근무표 생성/수정/삭제
   - 배치 업데이트 기능

5. **UI 컴포넌트**
   - Cupertino 디자인 시스템 적용
   - 테마 중앙 집중식 관리
   - 공용 위젯 (ShiftBadge 등)

### 현재 상태

- 기본 인증 플로우 완료
- 캘린더 기본 기능 완료
- 근무표 CRUD 완료

### 최근 완료된 작업

6. **한국 공휴일 기능 구현** (2025-01)

   - 공공데이터포털 API 통합 (한국천문연구원 특일 정보 API)
   - 공휴일 동적 로딩 및 캐싱
   - 공휴일 빨간색 표시 (일요일과 동일)
   - 토요일/일요일 빨간색 표시
   - 하단 일정 리스트에 공휴일 이름 표시
   - Lazy loading 최적화 (현재 월 기준 앞뒤 한 달씩 총 3개월만 조회)
   - 중복 API 호출 방지 로직
   - 월별 로드 상태 추적

7. **근무 템플릿 설정 기능 구현** (2025-01)

   - **서버 API 연결**

     - 템플릿 조회 API (`GET /api/v1/shift-templates/current`)
     - 템플릿 이름 변경 API (`PUT /api/v1/shift-templates/current`)
     - 근무 타입 추가 API (`POST /api/v1/shift-types`)
     - 근무 타입 수정 API (`PUT /api/v1/shift-types/:shift_type_id`)
     - 근무 타입 삭제 API (`DELETE /api/v1/shift-types/:shift_type_id`)

   - **데이터 모델**

     - `ShiftTemplateApiModel`: 템플릿 정보 모델
     - `ShiftTemplateVersionApiModel`: 템플릿 버전 정보 모델
     - `CreateShiftTypeRequest`: 근무 타입 추가 요청 모델
     - `UpdateShiftTypeRequest`: 근무 타입 수정 요청 모델
     - `DeleteShiftTypeResponse`: 근무 타입 삭제 응답 모델

   - **서비스 레이어**

     - `ShiftTemplateService`: 템플릿 관리 서비스
     - `ShiftTypeService`: 근무 타입 CRUD 서비스 확장

   - **상태 관리**

     - `ShiftTemplateSettingsProvider`: 템플릿 설정 상태 관리 (StateNotifier)
     - 템플릿 정보 및 근무 타입 목록 관리
     - 로딩 상태 및 에러 처리

   - **UI 구현**

     - `ShiftTemplateSettingsPage`: 근무 템플릿 설정 메인 페이지
       - 템플릿 정보 표시
       - 근무 타입 목록 표시
       - 템플릿 이름 변경 기능
       - 근무 타입 추가/편집/삭제 기능
     - `ShiftTypeCard`: 근무 타입 카드 위젯
       - 색상, 코드, 이름, 시간 표시
       - 삭제 버튼 포함
     - `ShiftTypeFormModal`: 근무 타입 추가/편집 모달
       - 코드, 이름, 색상, 시작시간, 종료시간 입력
       - iOS 스타일 폼 디자인 (CupertinoListSection)
       - 시간 선택 피커 (CupertinoDatePicker)
       - 시간 제거 기능
       - 유효성 검사 (코드 중복, 시간 일관성)

   - **주요 기능**

     - 템플릿 이름 변경
     - 근무 타입 추가 (코드, 이름, 색상, 시간)
     - 근무 타입 수정 (Partial Update 지원)
     - 근무 타입 삭제 (Soft Delete)
     - 시간 없는 타입 지원 (휴가, 오프 등)
     - 코드 중복 검증
     - 시간 일관성 검증 (시작/종료 시간 둘 다 있거나 둘 다 없어야 함)

   - **에러 처리**

     - API 에러 코드별 사용자 친화적 메시지 매핑
     - `TEMPLATE_NOT_FOUND`, `SHIFT_TYPE_NOT_FOUND`, `DUPLICATE_CODE`, `IN_USE` 등

   - **네비게이션**
     - 설정 페이지에서 "근무 설정" 메뉴 추가
     - `CupertinoPageRoute`를 통한 화면 전환

8. **캘린더 확장 보기 모드 구현** (2026-01)

   - **기능 개요**

     - 달력 영역에서 아래로 드래그하면 확장 모드 활성화
     - 확장 모드에서는 날짜 숫자 밑에 근무 코드가 색상과 함께 표시됨
     - 위로 드래그하면 확장 모드 비활성화 (기존 축소 기능과 연동)

   - **구현 내용**

     - **상태 관리**

       - `_is_expanded_view`: 확장 모드 여부 상태
       - `_pointer_start_y`: 포인터 시작 위치 (드래그 감지용)
       - `_calendarRowHeight` getter: 확장 모드 시 72px, 기본 48px

     - **드래그 감지 로직**

       - `Listener` 위젯으로 포인터 이벤트 감지 (GestureDetector보다 낮은 레벨)
       - `onPointerDown`: 시작 위치 기록
       - `onPointerMove`: 이동 거리 계산 및 모드 전환 (임계값 50px)
       - `onPointerUp`: 상태 초기화
       - `availableGestures: AvailableGestures.horizontalSwipe`: TableCalendar가 수평 스와이프만 처리하도록 설정

     - **확장 모드용 날짜 셀 빌더**

       - `_buildExpandedDayCell()`: 날짜 + 근무 코드 표시
       - 고정 높이(56px)로 모든 셀 높이 통일
       - 날짜 숫자 영역: 28px (오늘/선택 날짜는 원형 배경)
       - 근무 코드 영역: 16px (색상 배경 + 흰색 텍스트)

     - **CalendarBuilders 확장**
       - `holidayBuilder`: 공휴일에 확장 모드 적용
       - `defaultBuilder`: 일반 날짜에 확장 모드 적용
       - `todayBuilder`: 오늘 날짜에 확장 모드 적용
       - `selectedBuilder`: 선택된 날짜에 확장 모드 적용
       - `outsideBuilder`: 이전/다음 달 날짜에 확장 모드 적용 (투명도 0.4)
       - `markerBuilder`: 확장 모드에서는 마커 숨김 (날짜 셀에 이미 표시되므로)

   - **UI 개선**

     - 근무 설정 위젯(`_buildShiftAddOverlay`) 패딩 최적화로 오버플로우 해결
     - 이전/다음 달(outside days) 날짜에도 근무 정보 표시
     - AnimatedContainer로 확장/축소 애니메이션 적용
     - 긴 근무 코드 자동 축소 (FittedBox 적용)
       - 짧은 코드("Q", "N")는 원래 크기(10pt) 유지
       - 긴 코드("WWWWW", "OFF")는 영역에 맞게 자동 축소
       - 말줄임표 대신 자동 축소로 전체 텍스트 표시

   - **기술적 결정**
     - `GestureDetector` 대신 `Listener` 사용: TableCalendar의 내부 제스처와 충돌 방지
     - 포인터 이벤트 기반 드래그 감지: 다른 제스처 인식기와 독립적으로 동작

9. **근무표 스와이프 삭제 서버 API 연결** (2026-01)

   - **문제 정의**

     - 근무 일정을 왼쪽으로 스와이프하면 로컬에서만 삭제되고 서버로 전달되지 않음
     - `_schedules` 맵에 `shiftTypeCode`만 저장되어 있어 삭제 API 호출에 필요한 `work_shift_id`가 없음

   - **해결 방법**

     - `_work_shift_ids: Map<DateTime, String>` 맵 추가 (날짜 -> work_shift_id 매핑)
     - 데이터 로딩 시 (`_loadCalendarData`) `work_shift_id`도 함께 저장
     - `_confirmDeleteWorkShift` 메서드 추가: 삭제 전 서버 API 호출

   - **구현 내용**

     - **새로운 상태 변수**

       ```dart
       // 근무표 ID 데이터: Map<DateTime, String> (날짜 -> work_shift_id)
       // 서버 삭제 API 호출 시 필요
       final Map<DateTime, String> _work_shift_ids = {};
       ```

     - **데이터 로딩 수정**

       ```dart
       for (final workShift in response.data.workShifts) {
         final normalizedDate = _normalizeDate(workShift.workDate);
         _schedules[normalizedDate] = workShift.shiftTypeCode;
         _work_shift_ids[normalizedDate] = workShift.workShiftId; // 추가
       }
       ```

     - **삭제 확인 메서드 추가**

       ```dart
       Future<bool> _confirmDeleteWorkShift(DateTime? selectedDay) async {
         // work_shift_id가 없으면 로컬에만 있는 데이터
         // work_shift_id가 있으면 서버 API 호출 후 로컬 삭제
       }
       ```

     - **Dismissible 위젯 수정**
       - `onDismissed` 대신 `confirmDismiss` 사용
       - 서버 API 성공 시 `true` 반환 (삭제 진행)
       - 서버 API 실패 시 `false` 반환 (삭제 취소) + 에러 표시

   - **API 엔드포인트**

     - `DELETE /api/v1/work-shifts/:work_shift_id`
     - 기존 `WorkShiftService.deleteWorkShift()` 메서드 활용

   - **동작 흐름**

     1. 사용자가 근무 일정 왼쪽으로 스와이프
     2. `confirmDismiss` 콜백 호출
     3. `_work_shift_ids`에서 해당 날짜의 `work_shift_id` 조회
     4. 서버 API 호출 (`DELETE /api/v1/work-shifts/:work_shift_id`)
     5. 성공 시: 로컬 상태(`_schedules`, `_work_shift_ids`)에서 삭제, `true` 반환
     6. 실패 시: 에러 다이얼로그 표시, `false` 반환 (원래 상태 유지)

   - **관련 파일**
     - `lib/features/calendar/presentation/pages/calendar_page.dart`
     - `lib/features/calendar/data/services/work_shift_service.dart` (기존)

10. **근무 설정 버튼 레이아웃 개선 및 UX 향상** (2026-01)

- **문제 정의**

  - 근무 설정 버튼이 6개 이상일 때 화면 오버플로우 발생
  - 모든 버튼이 한 줄에 배치되어 가독성 저하
  - 근무 타입 추가 제한이 없어 무제한 추가 가능
  - 편집 모드에서 코드 필드가 readOnly로 되어 수정 불가
  - 스크롤 시 네비게이션 바 전환이 부자연스러움

- **해결 방법**

  - **버튼 레이아웃 개선**

    - 한 줄에 최대 5개까지만 표시
    - 6개 이상일 때 자동으로 2줄로 배치
    - 첫 번째 줄: 중앙 정렬 (`MainAxisAlignment.spaceEvenly`)
    - 두 번째 줄: 첫 번째 줄의 첫 번째 버튼 아래 정렬 (동일한 간격 유지)

  - **최대 개수 제한**

    - 근무 타입 최대 10개까지 설정 가능하도록 제한
    - 10개 도달 시 추가 버튼 비활성화 및 안내 메시지 표시

  - **코드 필드 수정 가능하도록 변경**

    - 편집 모드에서도 코드 필드 수정 가능 (`enabled: true`)

  - **스크롤 UX 개선**
    - `CupertinoSliverNavigationBar`에 `border: null`, `stretch: true` 추가
    - 스크롤 시 largeTitle 전환이 더 자연스럽게 개선

- **구현 내용**

  - **ShiftTypeButtonGroup 위젯 수정** (`shift_type_button.dart`)

    - `LayoutBuilder`를 사용하여 실제 화면 너비 측정
    - 첫 번째 줄의 간격 계산 (`spaceEvenly` 기준)
      ```dart
      // spaceEvenly: 양쪽 여백과 버튼 사이 간격이 모두 동일
      firstRowSpacing = (availableWidth - totalButtonWidth) / (rows[0].length + 1);
      firstRowStartOffset = firstRowSpacing;
      ```
    - 두 번째 줄 이상일 때 첫 번째 줄과 동일한 간격 적용
    - 마지막 행의 불필요한 padding 제거

  - **최대 개수 제한 추가** (`shift_template_settings_page.dart`)

    - `_addShiftType` 메서드에 최대 10개 제한 체크 추가
    - 10개 도달 시 에러 다이얼로그 표시
    - UI에 안내 메시지 표시

  - **코드 필드 수정 가능** (`shift_type_form_modal.dart`)

    - `enabled: !isEdit` → `enabled: true`로 변경
    - 편집 모드에서도 코드 수정 가능

  - **스크롤 UX 개선** (`shift_template_settings_page.dart`)

    - `CupertinoSliverNavigationBar`에 `border: null`, `stretch: true` 추가
    - 스크롤 시 네비게이션 바 전환이 더 부드럽게 개선

- **기술적 결정**

  - `LayoutBuilder` 사용: 실제 화면 너비를 측정하여 정확한 간격 계산
  - `spaceEvenly` 간격 계산: 양쪽 여백과 버튼 사이 간격을 동일하게 유지
  - 첫 번째 줄과 두 번째 줄 간격 동기화: 사용자 경험 일관성 유지

- **UI 개선 효과**

  - 6개 이상의 근무 타입도 오버플로우 없이 표시
  - 첫 번째 줄과 두 번째 줄이 시각적으로 정렬되어 가독성 향상
  - 최대 10개 제한으로 무분별한 추가 방지
  - 편집 모드에서 코드 수정 가능으로 유연성 향상
  - 스크롤 시 자연스러운 전환으로 UX 개선

- **관련 파일**
  - `lib/features/calendar/presentation/widgets/shift_type_button.dart`
  - `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`
  - `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`

11. **서버 오류 메시지 표시 개선** (2026-01)

- **문제 정의**

  - 서버 통신 시 오류 발생하면 전체 오류 메시지가 표시되어 사용성이 좋지 않음
  - 하드코딩된 에러 메시지 매핑으로 인해 서버에서 전달하는 메시지가 제대로 표시되지 않음
  - Provider에서 `error` 필드가 `String?` 타입이어서 `ApiException` 객체가 문자열로 변환되어 타입 체크 실패

- **해결 방법**

  - **서버 메시지 직접 표시**

    - `ApiException`의 `message` 필드를 그대로 alert에 표시
    - 하드코딩된 에러 코드별 메시지 매핑 제거
    - 서버에서 전달하는 사용자 친화적 메시지를 그대로 활용

  - **Provider 에러 필드 타입 변경**
    - `ShiftTemplateSettingsState`의 `error` 필드를 `String?`에서 `dynamic`으로 변경
    - catch 블록에서 `e.toString()` 대신 `e` 자체를 저장하여 `ApiException` 객체 보존
    - `error is ApiException` 타입 체크가 정상 동작하도록 수정

- **구현 내용**

  - **에러 메시지 추출 함수 단순화**

    ```dart
    String _getErrorMessage(dynamic error) {
      if (error is ApiException) {
        // 서버에서 전달받은 message를 그대로 반환
        return error.message;
      }
      // ApiException이 아닌 경우 기본 메시지 반환
      return '알 수 없는 오류가 발생했습니다.';
    }
    ```

  - **AuthProvider 수정** (`auth_provider.dart`)

    - `ApiException` import 추가
    - `loginWithKakao()`, `updateProfile()` 메서드의 catch 블록에서 `ApiException` 체크 추가
    - `ApiException`인 경우 `e.message`만 사용, 아닌 경우 `e.toString()` 사용

  - **CalendarPage 수정** (`calendar_page.dart`)

    - `_getErrorMessage()` 함수 단순화
    - 하드코딩된 switch-case 제거
    - 서버 `message` 직접 반환

  - **ShiftTemplateSettingsPage 수정** (`shift_template_settings_page.dart`)

    - `_getErrorMessage()` 함수 단순화
    - 하드코딩된 switch-case 제거
    - 서버 `message` 직접 반환

  - **ShiftTemplateSettingsProvider 수정** (`shift_template_settings_provider.dart`)
    - `error` 필드 타입을 `String?`에서 `dynamic`으로 변경
    - 모든 catch 블록에서 `e.toString()` 대신 `e` 자체를 저장
    - `ApiException` 객체가 그대로 보존되어 타입 체크 가능

- **기술적 결정**

  - **서버 메시지 직접 사용**: 서버에서 이미 사용자 친화적인 메시지를 제공하므로 클라이언트에서 재매핑 불필요
  - **동적 타입 사용**: Provider의 `error` 필드를 `dynamic`으로 하여 다양한 예외 타입 지원
  - **타입 보존**: 예외 객체를 문자열로 변환하지 않고 그대로 저장하여 타입 정보 유지

- **개선 효과**

  - 서버에서 전달하는 정확한 오류 메시지가 사용자에게 표시됨
  - 예: "해당 근무 타입이 사용 중이어서 삭제할 수 없습니다." (서버 메시지 그대로)
  - 하드코딩된 메시지 제거로 유지보수성 향상
  - `ApiException` 타입 체크가 정상 동작하여 안정성 향상

- **관련 파일**
  - `lib/features/auth/presentation/providers/auth_provider.dart`
  - `lib/features/calendar/presentation/pages/calendar_page.dart`
  - `lib/features/calendar/presentation/pages/shift_template_settings_page.dart`
  - `lib/features/calendar/presentation/providers/shift_template_settings_provider.dart`

### 현재 진행 중 작업

12. **친구 관리 기능 구현** (2026-01)

- **기획 및 설계 완료**

  - 기능 설계 문서: `_docs/FRIEND_FEATURE_DESIGN.md`
  - API 가이드라인: `_docs/FRIEND_API_GUIDE.md`

- **구현 범위**

  - 친구 목록 조회/관리
  - 친구 추가 (이메일/전화번호 검색)
  - 친구 요청 보내기/취소
  - 친구 요청 수락/거절
  - 친구 레벨/열람 설정
  - 알림 탭 (받은/보낸 요청)

- **진행 상태**

  - [TODO] (BE) 친구 목록 조회 API
  - [TODO] (BE) 사용자 검색 API
  - [TODO] (BE) 친구 요청 보내기 API
  - [TODO] (BE) 받은 요청 목록 조회 API
  - [TODO] (BE) 보낸 요청 목록 조회 API
  - [TODO] (BE) 친구 요청 응답 API (수락/거절)
  - [TODO] (BE) 친구 요청 취소 API
  - [TODO] (BE) 친구 설정 변경 API
  - [TODO] (BE) 친구 삭제 API
  - [TODO] (BE) 알림 관련 API (목록 조회, 미읽음 개수)
  - [DONE] (FE) 친구 목록 페이지
  - [DONE] (FE) 친구 추가 모달
  - [DONE] (FE) 알림 페이지 (받은/보낸 요청)
  - [DONE] (FE) 친구 상세 페이지 (레벨/열람 설정)

- **프론트엔드 구현 완료** (2026-01-05)

  - **폴더 구조**

    ```
    lib/features/friend/
    ├── data/
    │   ├── models/
    │   │   ├── friend_model.dart         # 친구 정보 모델
    │   │   ├── friend_request_model.dart # 친구 요청 모델
    │   │   └── notification_model.dart   # 알림 모델 (동적 액션 지원)
    │   └── services/
    │       ├── friend_service.dart       # 친구 API 서비스
    │       └── notification_service.dart # 알림 API 서비스
    └── presentation/
        ├── pages/
        │   ├── friend_list_page.dart     # 친구 목록 페이지
        │   ├── friend_detail_page.dart   # 친구 상세/설정 페이지
        │   └── notification_page.dart    # 알림 페이지
        ├── widgets/
        │   ├── friend_list_item.dart     # 친구 리스트 아이템
        │   ├── notification_item.dart    # 알림 아이템 (동적 액션 버튼)
        │   └── add_friend_modal.dart     # 친구 추가 모달
        └── providers/
            ├── friend_provider.dart      # 친구 상태 관리
            └── notification_provider.dart # 알림 상태 관리
    ```

  - **주요 기능**

    - 친구 목록: 프로필 이미지, 이름, 이메일, 친구 레벨 표시
    - 친구 추가: 이메일/전화번호 검색, 친구 요청 보내기
    - 알림 페이지: 받은/보낸 요청 탭, 수락/거절/취소 버튼
    - 친구 상세: 레벨 설정 (0~5), 열람 설정, 친구 삭제
    - 미읽음 알림 배지: 하단 액션 바의 알림 버튼에 표시

  - **동적 알림 액션 시스템**

    - 서버에서 `actions` JSON 데이터를 받아 동적으로 버튼 생성
    - 액션 타입: `accept`, `reject`, `navigate`, `dismiss`
    - 알림 타입에 따라 아이콘/색상 자동 결정
    - 확장 가능한 구조로 향후 다른 알림 타입 지원 용이

  - **UI 변경**

    - BottomActionBar: "메모" → "친구" 버튼으로 변경
    - 알림 버튼에 미읽음 개수 배지 추가

  - **API 연동 준비 완료**
    - API Constants에 친구/알림 엔드포인트 추가
    - 서비스 레이어에서 API 호출 로직 구현
    - 서버 API 구현 후 바로 연동 가능

### 향후 작업

- 일정(Event) 기능
- 프로필 설정 화면 개선
- 에러 처리 UX 개선 (토스트 메시지 등)
- 친구 캘린더 열람 기능
