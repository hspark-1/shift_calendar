# ShiftMate 네이버 iOS SDK 호환 패키지

목적: Flutter3.38.5에서 재로그인 -1005가 수정된 NidThirdPartyLogin5.2.1을 사용한다.
공식 Flutter 플러그인4.0.0은 Flutter>=3.44.0을 요구해 현재 툴체인에서 바로 사용할 수 없다.

출처: https://pub.dev/api/archives/naver_login_flutter-3.0.4.tar.gz 의 공식3.0.4.
원본 archive SHA-256: `d5e9cfed5b5c9eba858655a878428dd464213fb904c883ed10035222d1ee4626` (기존 hosted pubspec.lock과 대조 일치).
원본 BSD LICENSE를 유지한다. Dart/Android/Swift 호출 소스와 설정 CLI의 동작은 원본 그대로다.
커밋 정리 과정에서 Android Gradle·Swift 3파일의 줄 끝 공백14곳만 제거했으며 줄 끝 공백을 제외한 원본 소스는 동일하다.
수정은 package 버전3.0.4+shiftmate.1/publish_to:none, CocoaPods/SPM의 iOS15/네이버SDK5.2.1 pin이다.
원본의 예제·Gradle standalone wrapper·Android 단위 테스트는 앱 빌드 대상이 아니므로 포함하지 않는다.
바이너리 framework·credential·기기 진단 자료는 포함하지 않는다.

## 파일 역할·의존성·사용 예

- lib/**: 기존 Dart API·MethodChannel·DTO/토큰 유틸리티. Flutter/plugin_platform_interface 의존.
- ios/naver_login_flutter.podspec: CocoaPods 플러그인 소스/SDK 정확한 버전 선언.
- ios/naver_login_flutter/Package.swift 및 Sources/**: SPM 선언과 기존 네이티브 bridge/Scene callback.
- android/**: 기존 Gradle/R8 설정·manifest·Kotlin bridge. Android SDK 버전/행동은 원본과 동일하다.
- bin/**: 기존 선택 설정 CLI. 앱 로그인/빌드에서는 실행하지 않는다.
- pubspec.yaml/LICENSE: 로컬 패키지 메타데이터·원본 라이선스.

앱 pubspec.yaml의 path dependency로 사용한다. 기존 `FlutterNaverLogin.logIn()` 호출은 그대로다.
`flutter pub get` 후 `cd ios && pod update NidThirdPartyLogin naver_login_flutter`로 lock을 재생성한다.
앱 iOS 최소 버전15·기존 Flutter/네이버 환경 설정에 의존하며 native 변경이므로 앱 전체 재빌드가 필요하다.
`flutter test test/features/auth`와 실제 iOS build 및 탈퇴→재가입을 검증한다.

공식 수정 근거: https://github.com/naver/naveridlogin-sdk-ios-swift/releases/tag/5.2.0
이슈: https://github.com/naver/naveridlogin-sdk-ios-swift/issues/6
자동 SDK 재시도·인가 코드 재전송은 추가하지 않는다.

롤백: 앱 pubspec/lock과 iOS lock을 이전 hosted3.0.4/NidThirdPartyLogin5.1.0으로 복원하고
pub get/pod install/앱 재빌드를 수행한 뒤 이 폴더를 제거한다. 기존 -1005도 재발할 수 있다.
향후 Flutter>=3.44 업그레이드 시 공식 플러그인으로 전환하고 이 호환 패키지를 제거한다.

## 적용 검증 (2026-11-16)

실제 수정 전 iPhone 재가입에서 SDK error/토큰 없음/-1005/token endpoint를 관측했다.
수정 후 인증 회귀125개, 전체 analyze error/warning0(기존 미변경 naming info26개),
iOS Debug build 및 Runner.app의 SDK5.2.1/iOS15를 확인했다.
같은 iPhone에 전체 재실행한 뒤 사용자가 “해결됐음”을 확인했다.
이는 이번 로컬 실계정 확인이며 스토어 Release 배포/다른 기기·반복 횟수 검증과 구분한다.
