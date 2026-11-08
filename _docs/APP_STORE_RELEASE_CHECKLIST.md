# ShiftMate App Store 심사 준비 및 진행 기록

- 작업 기준일: 2026-11-08 (Asia/Seoul)
- 현재 단계: **등록 정보·심사 로그인 정보 입력 확인 / 제출용 Archive·IPA 생성 및 로컬 검증 완료 / 빌드 업로드·계정 실행 검증·개인정보 설문·연령 등급·콘텐츠 권리 확인 대기 / 심사 미제출**
- 원본: 사용자 첨부 「Apple App Store 출시 준비 체크리스트」. 아래 1~10번 범위를 유지한다.
- 역할: 출시 체크리스트, 확인 근거, 다음 작업을 지속 갱신하는 기준 문서.
- 의존성: `PROJECT_CONTEXT.md`, iOS Xcode 설정, Apple Developer / App Store Connect의 실제 상태.
- 사용 예: 작업 완료 시 해당 행을 ☑로 변경하고 상단 진행 기록에 날짜·증거·남은 항목을 추가한다.
- ☑는 확인 완료, ☐는 미완료 또는 미확인. **로컬 설정 확인만으로 포털 등록·배포 성공을 완료 처리하지 않는다.**
- 아래 정책 설명은 첨부 기반이며, 이번 작업에서 재확인한 범위는 App ID 등록 절차와 SDK 요구사항이다. 나머지는 해당 단계에서 공식 문서로 재검증한다.
- 비밀번호, 인증 코드, 인증서 개인키, APNs 키 원문, 심사 계정 비밀번호는 이 문서에 기록하지 않는다.

## Connect 저장 완료 보고 — 2026-11-08

아래는 사용자의 입력·저장 완료 보고를 근거로 한 상태다. Codex가 포털을 직접 재확인한 결과는 아니다. 2026-10-18의 앱 생성 차단·포털 미입력 기록은 당시 이력이며, 이번에 명시된 항목은 아래 최신 상태를 우선한다. 앱 이름·부제목·카테고리 등 별도 보고가 없는 필드까지 완료로 확대하지 않는다.

| 항목 | 최신 상태 |
|---|---|
| 저작권 | 저장 완료: `2026 박현서` (사용자 보고) |
| 심사 연락처 | 이름·국제 형식 전화번호·심사 이메일 저장 완료(사용자 보고). 전화번호 원문은 저장소에 복사하지 않으며 공개 지원 연락처 변경으로 해석하지 않는다. |
| 설명·홍보 문구·키워드 | 저장 완료(사용자 보고) |
| 지원 URL·개인정보처리방침 URL | 저장 완료(사용자 보고). 공개 페이지의 최종 내용 검증과 구분한다. |
| 심사 메모 | 저장 완료(사용자 보고). 본문은 미첨부이므로 내용 적정성 검증 완료로 기록하지 않는다. |
| 가격·국가 | 무료·대한민국 한정 설정 완료(사용자 보고) |
| iPhone 스크린샷 | 4장 등록 확인(사용자 보고). 등록 규격·파일명은 미보고. |
| Google 심사 계정 | 두 계정 생성·ShiftMate 가입 완료(사용자 보고). 후속 첨부 화면에서 review1 로그인 정보와 review2 보조 계정 메모 입력 확인. 비밀번호는 기록하지 않는다. 친구·그룹 연결, 예시 데이터, 제출 환경의 로그인 검증은 미확인. |
| 제출용 빌드 | 2026-11-08 호환 버전 게이트 포함 1.0.0(2) Archive·IPA 생성/로컬 검증 완료. iPhone 전용, iOS 15 이상, Xcode 27.1 / SDK 27.1. 이전 빌드 1은 별도 보존. Connect 업로드·Apple 서버 검증 미수행. |
| 개인정보 설문 | 미완료 |
| 연령 등급 | 미완료 |
| 콘텐츠 권리 확인 | 미완료. 저작권 필드 저장과 별개다. |
| 출시 방식 | 현재 승인 후 자동 출시(사용자 보고). 최종 제출 전 재확인하며 수동 출시로 변경했다는 뜻이 아니다. |
| App Review 제출 | 미수행 |

- 목적/변경: 저장된 등록 정보와 남은 심사 준비를 최신 사용자 보고에 맞춰 구분한다.
- 영향범위: 문서만 변경. 포털 선언·출시 방식 변경·심사 제출은 수행하지 않는다.
- 테스트: 사용자 보고와 항목별 대조, 연락처 원문 비복사, 기존 지원용 이메일 유지, 문서 정합성 검사.
- 롤백: 이번 최신 상태 기록 및 컨텍스트·작업 로그의 해당 변경만 되돌린다.

## 업데이트 기능 포함 빌드 2 — 2026-11-08

- 목적/변경: 사용자 확정에 따라 스토어 버전과 별도인 앱 내부 API 호환 번호로 필수 업데이트를 판정한다. 현재 내부 번호는 1, 스토어 버전은 1.0.0, 새 빌드는 2다. 상세 계약·새 파일 역할/의존성/사용 예·롤백은 [APP_VERSION_POLICY.md](APP_VERSION_POLICY.md) 및 ADR-0035를 따른다.
- 실행: `flutter build ipa --release --no-pub --dart-define-from-file=.env --build-name=1.0.0 --build-number=2 --export-method=app-store`.
- 산출물: `build/ios/archive/Runner.xcarchive`(Release 앱·dSYM), `build/ios/ipa/ShiftMate.ipa`(App Store용 배포 파일, 24,704,605 bytes), 같은 폴더의 `ExportOptions.plist`·요약·패키징 로그. 기존 빌드 1 산출물의 역할과 의존성은 같으며 이전 빌드 1은 `build/ios/releases/1.0.0-1/`에 보존했다.
- IPA SHA-256: `9ea369145c838bbb64052e52bd373a6ca970bb4ac5dd33f5ca3368aa9174332f`.
- 검증: 변경 파일 analyzer 진단 0건, Flutter 전체 206 pass·1 skip, 서버 strict TypeScript 및 실제 정책 HTTP 포함 선택 회귀 23건 통과. IPA ZIP CRC, Apple Distribution deep/strict 서명, App Store profile, production APNs/Apple entitlement, 1.0.0(2)·Bundle ID·iPhone 전용·iOS 15·SDK 27.1 검증. 실제 AOT에 AppUpdateGate·정책 API·운영 API·정확한 Store ID와 url_launcher_ios 플러그인 포함, Stage API 부재 확인. 기본 LaunchImage 안내 1건 유지. git diff --check 통과.
- 영향범위: 시작/복귀 정책 확인·최소 미만 전체 화면 차단·스토어 이동. 신규 의존성 url_launcher 6.3.2 및 iOS pod lock 반영. 최초 정책/캐시 모두 실패하면 허용하고 기존 차단 캐시는 유지한다. 기존 범위 밖 lint info 33건은 앞선 전체 분석 결과이며 이번 변경 파일 분석은 깨끗하다.
- 서버는 develop 기반 `codex/app-compatibility-policy` 로컬 커밋 `90ece07` 및 `artifacts/app_update_backend/0001-app-compatibility-policy.patch`로 준비. 실제 배포 전이며 API 기본 최소값은 0이다. 해당 호환 번호를 지원하는 앱의 스토어 공개 전 서버 최소값을 올리지 않는다.
- 롤백: 서버 최소값을 0으로 정상 응답시키고 API를 유지한다. 앱은 기존 게이트 연결/feature/의존성 변경을 되돌려 이전 빌드를 만들 수 있으며 원본 빌드 1은 보존했다. 기존 사용자 코드 변경은 유지한다.
- 다음: 서버 API 배포·실기기 Store 이동/복귀 검증, Xcode Validate App·Connect 업로드, 개인정보·연령 등급·콘텐츠 권리·출시 방식 확인. 이 작업에서는 서버 배포·앱 업로드·심사 요청을 하지 않았다.

## 이전 제출용 iOS 빌드 1 결과 — 2026-11-08

아래는 빌드 1 생성 당시 기록이다. 이후 산출물을 `build/ios/releases/1.0.0-1/`로 옮겨 보존했고 현재 기본 Archive/IPA 경로에는 위 빌드 2가 있다.

- 목적: 사용자 요청에 따라 현재 작업 트리로 App Store 제출용 빌드를 생성한다. 기존 미커밋 코드도 현재 상태 그대로 포함하며 이번 빌드를 위해 앱 소스·의존성·앱 버전 설정을 수정하지 않았다.
- 실행: `flutter build ipa --release --no-pub --dart-define-from-file=.env --build-name=1.0.0 --build-number=1 --export-method=app-store`.
- 도구: Xcode 27.1(27A9275), iOS SDK 27.1, Flutter 3.38.5, Dart 3.10.4. 과거 16.2/SDK 미충족 기록은 당시 이력이며 이번 직접 확인값이 우선한다.
- 환경: Release 운영 API `https://api.shiftmate.co.kr/api/v1`, Production Kakao/Firebase, Google iOS/server client 설정. 기존 `.env`의 그룹 P0/P1·Apple 로그인 활성화 설정을 그대로 사용한다. 네이티브 로컬 `Secrets.xcconfig`와 Kakao·Naver 값 및 Google reversed client ID 일치 확인. 실제 키 값은 문서·출력에 남기지 않는다.

| 산출물 | 파일 역할 / 의존성 / 사용 예 |
|---|---|
| `build/ios/archive/Runner.xcarchive` | Release 앱·dSYM·Archive 메타데이터. 현재 코드·pubspec/Podfile lock·로컬 define/xcconfig·Xcode 서명 환경에 의존. 예: Xcode로 열어 Validate App 및 배포 절차 진행. |
| `build/ios/ipa/ShiftMate.ipa` | Apple Distribution으로 서명한 App Store용 IPA, 24,618,369 bytes. 위 Archive와 App Store provisioning에 의존. 예: Transporter 또는 Xcode 배포 절차로 Connect 업로드. 기기에 직접 설치하는 개발용 IPA가 아니다. |
| `build/ios/ipa/ExportOptions.plist` | Xcode가 생성한 내보내기 설정. 예: 같은 Archive 재내보내기에 사용. |
| `build/ios/ipa/DistributionSummary.plist`, `Packaging.log` | Xcode 내보내기 요약·진단 로그. 예: 서명/패키징 문제 조사에 로컬에서 확인하며 비밀값 포함 가능성이 있어 외부 공유·커밋하지 않는다. |

- IPA SHA-256: `41a1f1d62f2633a3dee4bb1931f7983685259f87a9acea43c0a5bd25baf22747`.
- 사전 검증: 전체 테스트 `flutter test --no-pub --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=release-preflight-test-key --reporter expanded` → 196 pass·1 skip. `flutter analyze --no-pub` → error/warning 0, 기존 범위 밖 info 33건으로 종료 코드 1. 기존 lint를 무관 수정하지 않았다.
- 산출물 검증: IPA ZIP CRC, `codesign --verify --deep --strict`, `Apple Distribution: Hyunseo Park (65S23F4TQL)` 서명, App Store profile(등록 기기/enterprise 플래그 없음), `get-task-allow=false`, APNs production, Sign in with Apple entitlement 및 team/app 식별자 일치 통과. profile 만료 시각은 2027-11-08T11:05:21Z.
- 앱 메타데이터: `com.hspark.shiftmate`, `ShiftMate`, 1.0.0(1), iOS 15.0 이상, `UIDeviceFamily=[1]`, SDK iphoneos27.1 검증. 실제 IPA AOT 바이너리에 운영 API가 있고 Stage/로컬 API 문자열은 없음을 확인했다. OAuth callback 치환·네이버 native 값도 검사했다.
- 남은 안내: Flutter가 기본 LaunchImage placeholder 사용 경고 1건을 표시했다. 현재 LaunchScreen storyboard/기존 자산을 확인했으며 시작 화면 디자인은 이번 빌드 작업에서 바꾸지 않았다. 실제 기기/TestFlight에서 운영 로그인·푸시·친구/그룹 동작 검증은 미수행이다.
- 다음: Xcode Validate App / Connect 업로드 및 처리 완료 후 빌드 선택. 이 작업에서는 업로드·심사 요청·출시 설정 변경을 하지 않았다. 빌드 번호 1의 기존 포털 사용 여부는 직접 확인하지 않았으며 중복이면 재빌드 시 번호를 올린다.
- 영향범위/롤백: 생성된 `build/ios/archive/Runner.xcarchive`와 `build/ios/ipa/` 및 이번 문서 기록만 제거한다. 키체인/Apple 계정의 인증서·프로파일을 자동 삭제하거나 기존 소스 변경을 되돌리지 않는다. 빌드 산출물·환경 파일은 커밋하지 않는다.
- 기준: [Flutter iOS 배포 안내](https://docs.flutter.dev/deployment/ios), [Apple 제출 도구 요건](https://developer.apple.com/news/upcoming-requirements/).

## 스크린샷 폰트 라이선스 확인 — 2026-11-08

- 목적/범위: 제작한 출시 이미지의 글꼴 상업 이용 조건 확인. 이미지·코드 수정 없음. 앱 전체 저작물·콘텐츠 권리 검증 완료를 뜻하지 않는다.
- Figma `2:2`, `2:43` 텍스트 32개를 직접 조회했다. 사용 폰트는 `Noto Sans KR` Black(16), Medium(8), Regular(8)뿐이다. 원본 앱 이미지 안의 글꼴은 `pubspec.yaml`·테마에서 Cafe24 Ssurround/Air를 확인했다.
- [Noto Sans KR 공식 라이선스](https://raw.githubusercontent.com/google/fonts/main/ofl/notosanskr/OFL.txt): SIL OFL 1.1. [SIL 공식 FAQ 1.1·1.1.1·1.1.2](https://openfontlicense.org/ofl-faq/)는 상업용을 포함한 디자인·그래픽 제작, 결과물의 독립적 이용 및 결과물 내 출처 표기 불필요를 설명한다. 제작한 PNG는 폰트 파일을 재배포하는 산출물이 아니므로 이미지에 라이선스 전문을 삽입할 필요가 없다.
- Cafe24 원문: `assets/fonts/License-Ssurround.pdf`, `License-SsurroundAir.pdf` 각 2페이지를 렌더링하여 확인했다. 두 문서 모두 SIL OFL 1.1 적용, 개인·기업 무료 이용, 웹/모바일 이미지·광고·모바일 앱 임베딩 허용을 명시한다. 별도 상업 이용 구매가 필요한 조건은 확인되지 않았다. [공식 배포처](https://fonts.cafe24.com/).
- 조건: 폰트 자체 단독 유료 판매 금지. 폰트 파일을 번들/재배포할 때 저작권·라이선스 동봉 조건이 적용되며, 이는 PNG 홍보 이미지 배포와 구분한다. Cafe24 안내에는 사용 결과물의 자사 프로모션 활용 가능 및 거부 요청 가능 문구도 있다.
- 결과: 현재 제작 PNG의 App Store 홍보 사용은 확인한 폰트 라이선스상 허용된다. 앱 바이너리의 라이선스 동봉 상태·기타 콘텐츠 권리는 이번 확인 범위 밖이다.
- 검증: Figma 읽기 전용 폰트 집계, 공식 OFL/FAQ, 로컬 PDF 네 페이지 시각 판독 및 문서 diff 검사. Poppler 미설치·PDF 텍스트 레이어 부재로 Swift PDFKit 렌더링을 사용했다. 롤백: 이번 검증 문서 추가만 제거한다. 새 정책·설계 변경이 없어 ADR 추가 없음.

## 스크린샷 제작 결과 — 2026-11-08

- 목적: 사용자 제공 실제 앱 화면 네 장을 한국어 App Store 홍보 이미지로 구성한다.
- [Figma 편집본](https://www.figma.com/design/bkMSAJCfP2X28FuyNJu1Ej?node-id=2-2): 사용자 선택 `박현서` 팀, `App Store · 한국어` 페이지. 홍보 문구·배경·프레임은 편집 가능하며 앱 화면은 제공 원본 이미지다.
- 출력: `artifacts/app_store_screenshots/1290x2796/`, `1179x2556/` 각 4개 RGB PNG. `preview.png`는 전체 구성 미리보기이며 제출용 이미지가 아니다. `ShiftMate_AppStore_Screenshots.zip`에 8장과 미리보기를 담았다.
- 원본 의존성: 사용자가 지정한 `../design/KakaoTalk_Photo_2026-11-08-19-29-18 001.png`~`004.png`, 모두 1290×2796. 앱 코드·DB·빌드에는 산출물 의존성이 없다.
- 사용 예: ZIP을 풀어 선택한 기기 규격 폴더의 `01`~`04` PNG를 순서대로 App Store Connect에 등록한다. 실제 등록·심사 제출은 수행하지 않았다.

| 출력 파일명 (두 규격 공통) | 문구 | 원본 파일 끝 번호 | 역할 |
|---|---|---|---|
| `01_shift_entry.png` | 한 달 근무표, 톡톡 눌러 완성 | 002 | 근무 선택·다음 날짜 자동 이동 소개 |
| `02_friend_calendar.png` | 친구의 근무도 한눈에 확인 | 004 | 친구 캘린더·근무 시간 조회 소개 |
| `03_group_calendar.png` | 우리의 근무를 한 달력에 모아 | 003 | 그룹 날짜별 멤버 근무 조회 소개 |
| `04_shift_types.png` | 내 근무에 맞게 이름부터 시간까지 | 001 | 근무 유형·시간 설정 소개 |

- 디자인: 앱 primary dark `#00497D`와 파랑·민트·보라 배경, 큰 한국어 제목, 원본 비율 유지. 앱 원본 Cafe24 글꼴은 그대로 보존한다. Figma에 Cafe24가 없어 별도 홍보 문구에는 사용 가능 여부를 확인한 `Noto Sans KR` Black/Medium/Regular를 사용했다.
- 검증: Figma 원본 이미지 4개·홍보 텍스트 16개 확인, 전체 시각 검수와 RGB 변환 후 개별 이미지 확인. 8장 크기·PNG 8bit RGB(color type 2)·알파 및 tRNS 부재·CRC·압축 데이터 길이·ZIP 9개 항목 무결성 통과. Swift CoreGraphics/ImageIO로 내보낸 PNG의 알파 채널을 제거했다.
- [Apple 공식 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)을 2026-11-08 확인했다. 1290×2796(large), 1179×2556(medium) 세로 출력과 알파 채널 제거를 적용했다. 현재 공식 페이지의 필수 iPhone 크기 설명이 이전 2026-10-18 문서 설명보다 우선하며, 실제 Connect 등록 시 제공되는 슬롯을 대조한다.
- 영향범위: 출시 이미지·문서만 변경. 앱 동작 변경 없음. 롤백은 이번 산출물 폴더·문서 추가·새 Figma 파일을 제거하며 다른 기존 변경은 유지한다.

## 진행 기록 — 2026-10-18

| 항목 | 상태 | 확인 근거 / 남은 작업 |
|---|---|---|
| 개발자 계정 등록 | 완료(사용자 확인) | 사용자: 이미 등록 완료 |
| 연간 등록비 결제 | 완료(사용자 확인) | 사용자: 결제 완료 |
| 계정 종류 | 완료(화면 확인) | 2026-10-18 사용자 제공 멤버십 세부 사항: Apple Developer Program, 등록 유형 개인 |
| 멤버십 갱신일 | 화면 확인 완료 | 2027-08-05. 별도 Active 표시와 판매자명은 제공 화면에 없어 미확인 |
| App Store Connect 접근 | 완료(화면 확인) | 2026-10-18 사용자 제공 Apps 화면 및 앱 추가 시도 확인. 아직 앱 없음 |
| 개발자 계약 업데이트 | 수락 완료(화면 확인) | 2026-10-14 발행 Apple Developer Program License Agreement를 2026-10-18 수락. 수락 후에도 앱 추가 시 동일 팝업 지속(사용자 보고). 원인 미확정, Business 계약 상태 추가 확인 필요 |
| 앱 이름 / Bundle ID | 로컬 확인 완료 | `PROJECT_CONTEXT.md`, Xcode Runner: `ShiftMate` / `com.hspark.shiftmate` |
| Team ID | 포털 화면·로컬 일치 확인 완료 | 사용자 제공 멤버십 화면과 Runner Debug/Profile/Release 모두 `65S23F4TQL` |
| App ID 포털 등록 | 미확인 | 기존 식별자가 있는지 먼저 확인. 없을 때만 동일 Explicit Bundle ID 등록 |
| APNs | 로컬 설정 확인 | entitlement 존재. Debug=development, Profile/Release=production. 포털 capability·Firebase APNs 인증 및 TestFlight 수신은 미확인 |
| Sign in with Apple | 로컬 설정 확인 | `com.apple.developer.applesignin=[Default]`. 포털 capability·배포 로그인은 미확인 |
| 배포 인증서·프로파일 | 미확인 | 현재 도구의 `security find-identity -v -p codesigning`: `0 valid identities found`. 키체인 접근 범위의 영향 가능성이 있어 인증서 부재로 단정하지 않음. Xcode에서 확인 필요 |
| 빌드 도구 | 제출 전 조치 필요 | 현재 선택된 `xcodebuild -version`: Xcode 16.2 (16C5032a). 제출용 Xcode 26 이상 / iOS 26 SDK 이상 환경 필요 |
| 최소 지원 iOS / 앱 버전 | 로컬 확인 | 프로젝트 iOS 15.0, `pubspec.yaml`: `1.0.0+1`. 실제 Archive 값은 빌드 시 확인 |
| 유료 앱 계약·금융 정보 | 적용 여부 미확인 | 유료 판매 / IAP 사용 여부 확정 후 판단 |

### 추가 확인 — 멤버십 화면

- 2026-10-18 사용자 제공 화면에서 개인 계정, Apple Developer Program, Team ID `65S23F4TQL`, 갱신일 2027-08-05를 확인했다.
- 연회비 표시는 129,000원이며 결제 완료는 앞선 사용자 진술을 근거로 유지한다.
- 화면의 전화번호·상세 주소는 출시 준비 기록에 복사하지 않는다.
- 후속 화면으로 App Store Connect Apps 접근과 개발자 계약 수락 완료를 확인했다. 앱 추가 재시도는 필요하다.

### 추가 확인 — App Store Connect 계약 업데이트

- 2026-10-18 사용자 제공 화면: Apps 목록 접근 가능, 앱 없음, 앱 추가 시 개발자 계약 업데이트 안내 표시.
- 후속 계약 화면에서 2026-10-14 발행 Apple Developer Program License Agreement의 2026-10-18 수락을 확인했다. 앞선 동의 대기 판단을 정정한다.
- 재시도 결과: 사용자 보고상 동일 팝업이 계속 표시된다. 로그아웃·재로그인 수행 여부는 미확인.
- 현재 작업: App Store Connect → 비즈니스 → 계약에서 표시되는 계약명·상태·조치 문구 확인. 수락 지연이나 세션 문제로 단정하지 않는다.
- [Apple 계약 상태 확인 안내](https://developer.apple.com/help/app-store-connect/manage-agreements/view-agreements-status)에 따라 상태를 점검한다. 유료 앱 계약은 유료 판매·IAP용이며 이번 팝업 해결에 필요하다고 확인되지 않았다.
- 추가 조치가 없고 동일 계정·팀에서도 차단이 지속되면 [Apple Developer 지원](https://developer.apple.com/contact/)에 계약 수락 화면과 차단 팝업을 첨부해 확인을 요청한다. 문의는 아직 전송하지 않았다.

### 추가 확인 — DSA 및 비즈니스 계약 화면

- 2026-10-18 이전 화면에서 DSA 두 번째 선택지 선택을 확인했다. 후속 화면에서 녹색 완료 안내와 DSA 상태 ‘활성화됨’, 갱신일 2026-10-18을 확인하여 DSA 신고 완료로 갱신한다.
- EU 미배포 계획이라면 해당 선택에 부합한다. EU 배포 계획은 아직 사용자 확정이 없으며, 개인 계정만으로 비거래자로 판단하지 않는다.
- [Apple DSA 안내](https://developer.apple.com/help/app-store-connect/manage-compliance-information/manage-european-union-digital-services-act-trader-requirements/): EU 미배포 시에도 상태 신고 필요. EU에서 배포할 경우 사업·직업·상업화 목적 등을 기준으로 거래자 여부를 자체 평가해야 한다.
- 배경의 무료 앱 계약 상태는 ‘활성화됨(새로운 계약 사용 가능)’으로 표시된다. 개발자 계약 업데이트 배너도 남아 있어 DSA가 앱 추가 차단 원인이라고 확정할 수 없다.
- 대한민국 비즈니스 연락처 팝업 입력 단계 확인. 이메일 입력 및 BRN 보유 질문 ‘아니요’ 선택 중이며, 실제 BRN 보유 여부·이메일 인증·최종 저장은 미확인이다.
- [Apple 대한민국 규정 준수 안내](https://developer.apple.com/kr/help/app-store-connect/manage-compliance-information/manage-korea-compliance-information): 제공 연락처는 대한민국 App Store 제품 페이지 표시용이다. 수신·인증 가능하고 공개할 이메일인지 사용자가 확인해야 한다. 이메일 원문은 이 문서에 복사하지 않는다.
- BRN을 보유하지 않았다면 ‘아니요’로 진행한다. 개인 계정이라는 이유만으로 BRN 미보유로 단정하지 않는다.
- 후속 화면에서 대한민국 전자상거래법 활성화 확인 완료. 개발자 계약 업데이트 배너는 남아 있으며 지원 확인이 필요하다.

### 추가 확인 — 계약 팝업 지속 및 지원 문의 초안

- 2026-10-18 추가 화면에서도 앱 추가 시 동일한 ‘계약 업데이트’ 팝업이 표시된다. DSA 완료는 확인됐지만 앱 생성 차단은 해소되지 않았다.
- 최신 화면에서 대한민국 전자상거래법 상태 ‘활성화됨’, 갱신일 2026-10-18 확인. DSA도 활성화됨. 두 규정 준수 항목은 완료로 갱신한다.
- 사용자 보고 및 최신 화면상 무료 앱 계약 행에 추가 수락·검토 버튼이 없다. 계약 행 클릭 안내는 철회한다. 계약 업데이트 배너는 계속 표시되며 원인은 미확정이다. 다음 조치는 Apple Developer 지원에 계정의 계약 적용 상태 확인 요청이다.
- 문의 초안(미전송):

> 제목: 개발자 계약 수락 후에도 App Store Connect 앱 생성이 차단됩니다
>
> Team ID: 65S23F4TQL / 개인 Apple Developer Program 계정입니다.
> 2026-10-14 발행 Apple Developer Program License Agreement를 2026-10-18 수락했으며 Developer 계정 화면에도 수락일이 표시됩니다.
> 그런데 App Store Connect에서 앱 추가를 누르면 계약 업데이트 검토가 필요하다는 팝업이 계속 표시됩니다.
> 비즈니스 화면의 무료 앱 계약 상태는 ‘활성화됨(새로운 계약 사용 가능)’이고 추가 수락 버튼은 없습니다. DSA와 대한민국 전자상거래법 상태 모두 활성화됨이며 갱신일은 2026-10-18입니다.
> 이 계정에 추가 수락이 필요한 계약이 있는지, 수락 내역이 App Store Connect에 정상 적용됐는지 확인 부탁드립니다.
> 계약 수락 기록 화면·무료 앱 계약 상태 화면·차단 팝업을 첨부합니다.

- 문의 경로: [Apple Developer 지원](https://developer.apple.com/contact/). 문의 전송은 수행하지 않았다. 첨부는 관련 부분만 포함한다.

### 1번의 다음 실행 순서

1. Membership details 화면에서 개인 계정·Team ID 일치·갱신일 2027-08-05 확인 완료. App Store Connect Apps 접근도 후속 화면으로 확인했다. 별도 Active 표시와 판매자명은 미확인으로 유지한다.
2. Apps 접근·개발자 계약 수락·DSA·대한민국 전자상거래법 활성화 확인 완료이나 앱 추가 차단 지속. 무료 앱 계약 행에 추가 수락 UI 없음. 아래 초안과 증거로 Apple 지원에 문의한다.
3. Developer → Certificates, Identifiers & Profiles → Identifiers에서 `com.hspark.shiftmate`를 검색한다. 있으면 팀과 capability를 대조하고, 없으면 App IDs → App → Explicit → 동일 Bundle ID로 등록한다. Push Notifications와 Sign in with Apple을 확인한다.
4. `ios/Runner.xcworkspace`를 Xcode로 열고 Runner → Signing & Capabilities에서 유료 팀과 서명 상태를 확인한다. 배포 인증서와 프로파일은 Organizer 배포 과정의 관리 방식까지 확인한다. 개발용 실기기 서명 성공은 App Store 배포 서명 완료의 근거로 사용하지 않는다.
5. 제출용 Xcode 26 이상과 iOS 26 SDK 환경을 확보하고 Release Archive / 배포 검증으로 서명·프로파일·entitlement 일치를 확인한다.
6. 위 결과가 확인되면 1번의 남은 체크를 갱신한다. 현재는 포털 로그인 상태를 확보하지 못해 원격 확인·등록·계약 수락·빌드 업로드를 수행하지 않았다.

### 2번 준비 — 한국어 App Store 등록 정보 (2026-10-18)

계약 문제와 독립적으로 준비한 로컬 초안이다. **App Store Connect 입력·등록 완료는 아니다.** 앱 이름 사용 가능 여부, 권리자, 공개 URL은 아직 확정되지 않았다. 최초 출시는 대한민국 한정·무료·앱 내 결제 없음으로 사용자 확정했다. 지원 문의 접수도 확인되지 않았다.

| 필드 | 준비 값 | 상태 |
|---|---|---|
| 앱 이름 | ShiftMate - 교대근무 캘린더 | 초안, 20자 / 이름 사용 가능 여부 미확인 |
| 부제목 | 근무표와 개인 일정, 친구 공유까지 | 초안, 19자 |
| 기본 언어 | 한국어 | 제안, 사용자 확정 전 |
| 기본 카테고리 | 생산성 | 제안, 캘린더·근무표 관리 기능 기준 |
| 보조 카테고리 | 우선 미지정 | 선택 사항 |
| Bundle ID | `com.hspark.shiftmate` | 코드 확인, 포털 등록 미확인 |
| SKU | `shiftmate-ios-001` | 제안, 생성·등록 미완료 |
| 앱 버전 / 빌드 | `1.0.0` / `1` | pubspec 확인, 제출 Archive 별도 확인 |
| 가격·배포 국가 | 대한민국 한정·무료·앱 내 결제 없음 | 2026-10-18 사용자 확정. 포털 설정은 미완료 |
| 저작권 | `2026 [실제 권리자명]` | 권리자 확인 후 입력. 대괄호 문구 제출 금지 |
| 지원 URL | `https://www.shiftmate.co.kr/support` | 2026-10-18 HTTPS GET 200, HTML·이메일·탈퇴 안내 확인 |
| 개인정보처리방침 URL | `https://www.shiftmate.co.kr/privacy` | 후속 GET 200·검토본 공개 확인. 문구 정정 로컬 완료, 최종 검토·재게시 필요 |
| 연령 등급 | 미정 | 실제 기능에 따라 Apple 질문에 응답 후 산정 |

#### 설명 — 복사 가능한 초안

```text
ShiftMate는 교대근무자의 근무표와 개인 일정을 함께 관리하는 캘린더 앱입니다.

[한눈에 보는 근무표와 일정]
달력에서 근무 일정과 개인 일정을 함께 확인하세요. 날짜를 선택하면 그날의 일정을 살펴볼 수 있습니다.

[나에게 맞는 근무 유형]
데이, 이브닝, 나이트, 오프 등 나의 근무 방식에 맞춰 근무 유형을 설정하세요. 이름과 코드, 색상, 근무 시간을 지정하고 날짜별 근무표를 관리할 수 있습니다.

[개인 일정 관리]
일정의 제목, 메모, 장소와 시간을 기록하세요. 종일 일정과 공개 레벨도 설정할 수 있습니다.

[친구와 일정 공유]
친구를 추가하고 서로 열람이 허용된 캘린더를 확인하세요. 친구별 열람 허용 여부와 공개 레벨을 설정해 공유 범위를 관리할 수 있습니다.

ShiftMate와 함께 근무와 일상의 일정을 정리해 보세요.
```

- 구현 근거: `work_shift_service.dart`의 조회·UPSERT·수정·삭제·배치 저장, `shift_type_service.dart`의 근무 유형 CRUD, `calendar_service.dart`의 통합 조회·개인 일정 생성·삭제, `friend_service.dart`의 친구 설정·캘린더 조회. 경로는 모두 `lib/features/<feature>/data/services/` 아래다.
- 화면 호출 근거: `calendar_page.dart`의 `createEvent`·`batchUpsertWorkShifts`, `friend_detail_page.dart`의 `can_view`·레벨 변경과 설정 저장. 실제 서버·Release 동작 검증은 6번에서 수행한다.
- 자동 근무표 생성, 개인 일정 수정, 주간 브리핑, 외부 캘린더 동기화 등 이번에 확인하지 않은 기능은 문구에 넣지 않았다.

#### 홍보 문구

```text
나의 근무표와 개인 일정을 한곳에서 관리하세요. 근무 유형을 직접 설정하고, 친구별 공개 범위를 정해 일정을 공유할 수 있습니다.
```

#### 키워드

```text
근무표,교대근무,근무일정,일정관리,공유달력,스케줄,친구일정
```

- UTF-8 기준 84바이트. Apple의 100바이트 제한 이내로 검사했다.
- 필드 제한·지원 URL·저작권 필수 여부 근거: [Apple 버전 정보 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/). 설명 4,000자, 홍보 문구 170자 이내. 저작권 정보는 필수 항목으로 정정한다.

#### 플랫폼 지원 결정

- [완료] 최초 출시 iPhone 전용 결정 및 로컬 기기 지원 설정 변경(ADR-0030).
- [TODO] 제출 Archive의 `UIDeviceFamily = [1]` 확인.
- [추후] iPad UI·가로/멀티태스킹 검증과 전용 스크린샷 준비 후 기기 지원 확장.
- 이 설정은 iPad용 네이티브 기기군 제외를 뜻하며, iPhone 앱의 iPad 호환 실행까지 차단한다는 의미는 아니다.

#### 아이콘 점검

- 원본: `assets/icons/app_icon.png` — 1024×1024 RGBA.
- iOS 마케팅 아이콘: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` — 1024×1024 RGB, 투명도 채널 없음. `Contents.json`의 ios-marketing 항목에서 참조한다.
- 이미지 확인: 흰색 바탕, 붉은 캘린더와 파란 체크 표시. 기존 자산을 유지했다. 최종 디자인 선택 및 Archive 자산 검증은 남아 있다.

#### 스크린샷 촬영 계획

2026-10-18 사용자 결정: 최초 출시는 iPhone 전용으로 진행한다. Debug/Profile/Release의 `TARGETED_DEVICE_FAMILY = 1`로 변경했다. iPad 네이티브 지원과 전용 UI·스크린샷은 후속 업데이트에서 준비한다. Archive의 실제 UIDeviceFamily는 제출 빌드에서 별도 확인한다.

| 순서 | 화면 | 소개 문구 | 촬영 전 준비 |
|---|---|---|---|
| 1 | 메인 월 캘린더 | 근무와 일정을 한눈에 | 가상 근무표·개인 일정 입력 |
| 2 | 근무 추가 모드 | 날짜별 근무를 간편하게 | D/E/N/OFF 등 실제 저장 가능한 유형 |
| 3 | 근무 설정 | 나에게 맞는 근무 유형 | 코드·색상·시간 설정 예시 |
| 4 | 개인 일정 등록 | 일상의 일정도 함께 | 제목·장소·시간·공개 레벨 입력 |
| 5 | 친구 캘린더 또는 친구 설정 | 공유할 범위를 직접 설정 | 가상 계정 두 개·친구 수락·공유 설정 |

- iPhone 촬영 기준 후보: 1290×2796 또는 1320×2868 세로. 해당 해상도 기기·시뮬레이터의 실제 앱 화면으로 촬영한다.
- iPad 스크린샷: 최초 출시 준비 대상에서 제외. 후속 iPad 지원 업데이트 시 당시 Apple 규격에 맞춰 준비한다.
- [Apple 스크린샷 규격](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/) 확인: 원본 첨부의 ‘중형 Dynamic Island 필수’ 표현은 부정확해 아래 표를 정정했다.
- 실제 촬영·파일 생성은 미실행. 실사용자 개인정보 대신 가상 데이터를 사용한다. 촬영 기기에서 UI·서버 동작 확인 후 최종 선정한다.

#### 개인정보 HTML 공개 문안 v1.0 (2026-10-18)

- 최초 시행일 2026-10-18 사용자 확정. 로그/DB 백업/문의 삭제 절차 적용 완료 및 이미지 별도 백업 없음 사용자 확인.
- PRIVACY_POLICY.md·privacy.html 공개 문체 갱신, 검토 배너/개발 메모/자리표시자 제거 완료. HTML 구조·링크·14개 절·정책값 검사 통과.
- 실제 계약별 수신 법인·구체 처리국가·국외 이전 근거와 필요한 동의/고지 최종 대조는 운영자 확인 필요. 본문 문체 정리가 법적 완결성 확인을 뜻하지 않는다.
- 서버 재게시·브라우저 시각 QA·심사 제출 미수행. 위 항목을 확인한 뒤 최종 URL 콘텐츠 검증.

#### BE-05 구현·검증 완료 확인 (2026-10-18)

- [완료: 사용자 확인] 사용자가 BE-05를 직접 구현하고 검증했다고 명시했다. 현재 진행 상태는 구현·검증 완료로 갱신한다.
- Codex 직접 실행 검증은 아니며 revision·최종 DTO·테스트 로그는 미첨부다. 이전 미구현 표현은 확인 당시 이력으로 읽는다.
- 다른 운영 설정/실삭제 검증·시행일·외부 서비스 고지 미확정 상태는 그대로 유지한다.

#### 후속 main 배포 완료 통보 (2026-10-18)

- BE-01~04 코드 배포 완료(사용자 전달). 이전 배포 미확인 기록을 대체하며 Stage 실삭제·worker cleanup·timer/SMTP·로그/백업/문의 보관 검증은 대기.
- AWS 개인 계정·개인용 Gmail·S3 versioning off 확인. 서울·복제/CDN 없음 유지. 이미지 백업은 프로필 사진 별도 사본이며 Docker 이미지와 구분.
- 시행일 2026-10-18은 조건부 제안으로 확정하지 않음. BE-05는 계약 제안/미구현.
- 최종 방침 본문 확정 전 필요한 항목은 PRIVACY_REVIEW 최신 상태표로 관리한다.

#### 최종화 전 운영 상태 정정 (2026-10-18)

- 최신 사용자 답변으로 앞선 모두 완료 답변 철회. BE-01~04·로그/백업/문의 보관은 운영 검증 미완료. DB migration·S3 조회 권한 준비 보고와 실제 배포·실행 결과를 구분한다.
- 수동 DB 백업 존재, 최대 보관 기간/자동 만료 미확정. 이미지 별도 백업 미확인. 시행일·계정 유형도 미확정.
- PRIVACY_REVIEW·PRIVACY_ACTION_PLAN 최신 운영 표와 정책 MD/HTML 백업 설명 갱신. 최종 공개본 완료로 표시하지 않는다.

#### 이미지 저장소 정정 (2026-10-18)

- 후속 사용자 확인: 서울 ap-northeast-2, 복제 없음, CDN 없음. 정책 MD/HTML 반영 완료. 별도 백업·계약 법인·파기 운영 증거는 대기.


- 사용자 확인: 프로필 이미지는 AWS S3. 기존 이미지까지 국내 홈서버·외부 저장소 없음 설명을 대체한다.
- 정책 MD/HTML 및 요청서·작업표 갱신. 리전·계약 법인·복제/CDN/백업·권한·버전 삭제 증거는 대기.
- 공개 페이지 재게시·버킷·프로그램 변경 없음.

#### BE 작업 결과 인수 및 FE 회신안 (2026-10-18)

- [완료] BE-01~04 구현·로컬 검증 보고 수신. 현재 서버 c1af0f7 이미지 파기/기기 정리/worker/retention/감시 핵심 경로 직접 확인. 보고의 미커밋 표기는 작성 시점 이력이며 실제 홈서버 revision과 다르다.
- [대기] migration·동일 revision API/worker 배포·Stage E2E·메일 수신·실제 cleanup·OPS 증거. 보고된 테스트 통과는 운영 적용 증거가 아니며 전체 기존 실패 18개도 남아 있다.
- [완료] [`FE 가입 계약 회신안`](app_store_web/FE_PRIVACY_CONTRACT_REPLY.md) 작성: 공통 진입 분기, UI/domain state, 후보 DTO/오류·SDK 재시도 경계·QA·호환 배포.
- [대기] 운영 동의 항목/근거·정책 version·기존 사용자 범위와 BE DTO/OpenAPI 합의. 신규 가입 필드/동작·DB·SDK 호출 순서 변경 없음.
- [완료] 정책 MD·HTML에 장치/완료 작업 30일 정기 정리와 이미지 삭제 보완 사실 반영. 운영 적용 대기·시행일·국외 이전 고지 미확정으로 검토본 유지.

#### 개인정보 문서·프로그램·운영 분리 작업 (2026-10-18)

- [완료] 공개 정책 후속 GET 200·검토본 안내 확인. 이전 404는 최초 확인 이력.
- [완료] MD·HTML의 Google/Naver FE 해제, Apple/Kakao BE 해제 설명·보관 정책/운영 미검증·연령 정책 문구 정정. 공개 사이트 재반영은 미실행.
- [완료] [`작업표`](app_store_web/PRIVACY_ACTION_PLAN.md): DOC/FE/BE/OPS 담당·우선순위·검증·미완료 상태 분리.
- [완료] [`백엔드 요청서`](app_store_web/BACKEND_PRIVACY_REQUEST.md): BE-01 이미지 파기, BE-02 실패·7일 감시, BE-03/04 잔여 기기/작업 보관·정리, BE-05 가입 정책 계약. 전달용 준비 완료·미전송.
- [TODO] FE 정책/지원 링크·연령/동의 계약 연결·외부 해제 실패 검증. 기존 SDK 해제 구현은 있으므로 중복 신규 구현을 요청하지 않는다.
- [TODO] 서버 담당자 코드 구현·운영 보관값/삭제 증거 회신 → 정책 최종화·앱/신고 동기화 → 재게시 검증.
- 이번 단계에서 Flutter/백엔드 생산 코드·DB·홈서버는 변경하지 않았다.

#### 개인정보처리방침 본문 작성 및 공개 주소 확인 (2026-10-18)

- 지원 URL `https://www.shiftmate.co.kr/support`: 실제 HTTPS GET 200, `text/html; charset=utf-8`, 지원 이메일·탈퇴 안내·개인정보 링크 확인. 웹 도구 실패 후 별도 GET으로 확인했다.
- 개인정보 URL `https://www.shiftmate.co.kr/privacy`: 실제 GET 404. 아직 공개 완료 아님.
- [`app_store_web/PRIVACY_POLICY.md`](app_store_web/PRIVACY_POLICY.md): 방침 본문 정본. [`privacy.html`](app_store_web/privacy.html)도 동일 본문으로 갱신했다.
- [`app_store_web/PRIVACY_REVIEW.md`](app_store_web/PRIVACY_REVIEW.md): 채택한 보관 정책, 프론트·인접 백엔드 코드 근거, 잔여 기기·이미지 삭제·국외 이전·가입 제한 등 공개 전 확인 항목.
- 운영자·보호 담당자 박현서, 탈퇴 목표 7일·일반 로그/백업 30일·문의 완료 후 1년 정책 채택(ADR-0032). 실제 적용은 미검증.
- 분석·충돌 SDK 도구는 미정·현재 미도입. 만 14세 미만 미허용 정책은 실제 가입 제한과 대조 필요.
- 검증: HTML 14개 절·구조·링크·정책값 대조, git diff --check. Chrome 미리보기 도구가 timeout으로 실패해 브라우저 시각 검증은 미완료.
- 지원 웹 URL 준비 확인과 정책 검토본 작성은 완료. 정책 최종 확정·공개·앱 내 링크·App Privacy는 미완료로 유지한다.

#### HTML·서버 전달 자료 (2026-10-18)

- 사용자 요청에 따라 서버 변경·배포 없이 로컬 전달 파일을 작성했다.
- [`app_store_web/support.html`](app_store_web/support.html): 문의 이메일·오류 문의 방법·탈퇴 요청 안내.
- [`app_store_web/privacy.html`](app_store_web/privacy.html): 프론트 확인 항목 기반 공개 전 초안. 운영 미확정 항목을 최종 작성하기 전 게시·심사 제출하지 않는다.
- [`app_store_web/DEPLOY_GUIDE.md`](app_store_web/DEPLOY_GUIDE.md): 파일 역할·의존성·사용 예, Nginx 예시·배치·HTTPS/GET/헤더 검증·롤백·정책 확인 목록.
- 검증: HTML 구조·viewport·내부 링크·이메일·외부 자산 비의존성 확인. Nginx 실행·실제 배포·브라우저 시각 검증은 미수행.
- 남은 작업: 서버 담당자의 정책 확정 및 배포 결과 수령, 앱 내 URL 진입점 구현. 파일 준비 완료와 URL 공개 완료를 구분한다.

#### 기존 도메인 사용 방향 (2026-10-18)

- 사용자 요청: `shiftmate.co.kr` 도메인에서 개인정보처리방침 HTML을 제공한다. 개인정보 URL은 `/privacy`, 지원 URL은 `/support`로 준비할 것을 제안하며 실제 라우팅은 미설정이다.
- `stage-api.shiftmate.co.kr` API 주소와 루트 도메인의 DNS·HTTPS·가상 호스트 연결은 별도 확인 대상이다. 기존 서버에서 정적 HTML 제공은 가능하나 현재 서버 구성은 확인하지 않았다.
- 이번 저장소 검색에서 Nginx·Docker·서버 배포 설정을 찾지 못했다. 개인정보처리방침 내용 확정에는 실제 서버의 보관·삭제·위탁·국외 이전 정보 확인이 필요하다.
- 접근 확인 한계: 로컬 dig는 샌드박스 소켓 권한 오류, curl은 이름 해석 실패, 웹 도구도 루트 URL을 열지 못했다. 이 결과만으로 실제 DNS 미등록이나 서버 장애라고 단정하지 않는다.
- 완료 조건: 공개 HTTPS 정상 응답, 인증 불필요, 모바일 가독성, 실제 처리 내용이 반영된 정책 본문, 지원 연락처, 앱 내 정책 링크. HTML 생성·배포·DNS 변경은 아직 수행하지 않았다.
- 후속 사용자 확인: API는 개인 홈서버 운영. DNS 관리 화면에서 @·api·stage-api A 레코드가 모두 `14.32.242.75`, www CNAME은 `shiftmate.co.kr.`, TTL 600으로 표시된다. 실제 DNS 전파·현재 공인 IP 일치는 별도 미검증이다.
- 화면 기준 DNS 값 변경은 불필요하다. 루트 도메인의 HTTPS와 HTML 제공 경로를 기존 서버 구성에 추가할 방향이다.
- Nginx는 정적 파일 제공·도메인별 요청 전달에 사용할 수 있는 도구의 예시이며 필수 설치로 확정하지 않았다. 현재 HTTPS 진입점(Nginx/Caddy/NAS 역방향 프록시/직접 TLS 등) 확인 후 그 구성에 맞춰 적용한다.
- 다음 확인: 기존 443 HTTPS 처리 프로그램, 인증서에 shiftmate.co.kr 포함 여부, 백엔드 저장소 위치.

#### 공개 URL 및 남은 결정

- 저장소 파일명 검색과 `lib`의 약관·개인정보·support URL 검색에서 배포 가능한 정책·지원 웹페이지를 확인하지 못했다. 웹 전체에 해당 페이지가 없다고 단정하지 않는다.
- `lib/features/auth/presentation/pages/login_page.dart`의 `_buildTermsText()`는 일반 `Text`이며 이용약관·개인정보처리방침 링크 동작이 없다. 문서와 실제 URL을 준비한 뒤 앱 내 진입점을 연결해야 한다.
- 지원 페이지에는 공개 문의 채널과 문의 방법, 개인정보처리방침에는 실제 수집·처리·보관·삭제 및 외부 서비스 내용을 확인해 반영한다. 정책 내용·개인정보 신고는 3번에서 별도 검증한다.
- 2026-10-18 사용자 확정: 대한민국 한정·무료·앱 내 결제 없음. 공개 지원 이메일 `sspp8585@gmail.com`. 포털 입력은 아직 수행하지 않았다.
- 서비스는 앱으로 제공한다. 게시 위치는 웹 앱 개발이 아니라 지원 안내·개인정보처리방침을 열 수 있는 웹페이지의 공개 위치를 뜻한다. 기존 도메인 `shiftmate.co.kr`에서 정적 HTML 제공 방향으로 정했으며, 공개 게시는 수행하지 않았다.
- 공식 요건: [지원 URL](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/)은 실제 연락처가 있는 지원 웹페이지이며 필수다. [개인정보처리방침 URL](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/)도 필수다. 지원 이메일만으로 두 URL을 대체하지 않는다.
- 다음: 앱·서버의 실제 개인정보 처리 근거를 확인해 정책과 지원 안내 초안을 준비한 뒤 공개 위치를 정한다.

### 공식 근거 및 제출 도구 확인

- [App ID 등록 절차](https://developer.apple.com/help/account/identifiers/register-an-app-id/): Explicit Bundle ID는 Xcode 앱 식별자와 일치해야 하며 등록에는 Account Holder 또는 Admin 권한이 필요하다.
- [Apple 제출 요구사항](https://developer.apple.com/news/upcoming-requirements/): 2026-04-28부터 Xcode 26 이상과 iOS 26 SDK 이상, 2026-09-09부터 최소 지원 iOS 13 이상. 프로젝트의 iOS 15 설정은 최소 지원 버전 조건에 맞지만 현재 선택된 Xcode 16.2는 제출 도구 조건을 충족하지 않는다.

### 이번 변경의 범위 및 검증

- 목적: 첨부를 저장하고 1번의 완료 여부를 근거별로 추적한다.
- 변경·영향: 이 문서 및 프로젝트 컨텍스트·작업 로그만 변경. 앱 동작·서버·DB 변경 없음.
- 롤백: 이번 문서 및 연결 기록을 되돌린다.
- 검증: Xcode 프로젝트 설정, entitlement, pubspec, 로컬 도구 버전과 서명 조회 결과를 확인했다. 빌드·실기기·포털 검증은 이번에 수행하지 않았다.

---

# 원본 기반 전체 체크리스트
**기준: 2026년 10월 18일 / Apple 공식 가이드**

실제 프로젝트 브랜드는 **ShiftMate(근무표 + 공유 캘린더 앱)**입니다. 아래 미확인 항목은 이후 단계에서 검증합니다.

단순한 앱 업로드뿐 아니라 개발자 계정, 법적 문서, 앱 심사, 기술 설정, 테스트, 출시 후 운영까지 포함했습니다.

우선순위는 다음과 같이 구분합니다.

- 🔴 **필수:** 출시 또는 심사에 반드시 필요한 항목
- 🟡 **조건부:** 앱에서 해당 기능을 사용하는 경우 필수
- ⚪ **권장:** 필수는 아니지만 출시 전에 준비하면 좋은 항목

## 1. Apple 개발자 계정 준비

| 우선순위 | 체크 | 준비 항목 | 설명 |
|---|---|---|---|
| 🔴 | ☑ | Apple Developer Program 가입 | 2026-10-18 사용자 확인: 등록 완료. 멤버십 Active 여부는 포털 확인 필요 |
| 🔴 | ☑ | 연간 개발자 등록비 결제 | 2026-10-18 사용자 확인: 결제 완료 |
| 🔴 | ☑ | 개인 / 조직 계정 결정 | 2026-10-18 멤버십 화면: 개인. 실제 스토어 판매자명은 별도 확인 |
| 🔴 | ☑ | App Store Connect 접근 | 2026-10-18 Apps 화면 확인. 앱 생성은 개발자 계약 업데이트 처리 후 진행 |
| 🔴 | ☐ | Bundle ID 생성 | 예: `com.hspark.shiftmate` |
| 🔴 | ☐ | 앱 서명 설정 | Signing Certificate, Provisioning Profile |
| 🟡 | ☐ | APNs 설정 | 푸시 알림을 사용하는 경우 |
| 🟡 | ☐ | Sign in with Apple 설정 | Apple 로그인 도입 시 |
| 🟡 | ☐ | 유료 앱 계약 및 금융 정보 | 유료 앱·앱 내 결제 사용 시 |

**참고:** 조직 계정은 법인 정보와 D-U-N-S 번호 등의 확인 절차가 필요할 수 있습니다.

공식 문서: [Apple Developer 가입](https://developer.apple.com/help/account/membership/program-enrollment/)

---

## 2. App Store 등록 정보

사용자가 App Store에서 실제로 보게 되는 정보입니다. 상단 「2번 준비」에 한국어 문구 초안·자산 점검·촬영 계획을 정리했다. 아래 체크는 최종 확정·등록까지 완료한 경우에만 변경한다.

| 우선순위 | 체크 | 준비 항목 | 설명 |
|---|---|---|---|
| 🔴 | ☐ | 앱 이름 | 최대 30자 |
| 🔴 | ☐ | 앱 설명 | 주요 기능 및 서비스 소개 |
| 🔴 | ☐ | 앱 아이콘 | 1024×1024px 원본 준비 권장 |
| 🔴 | ☐ | 앱 스크린샷 | 실제 앱 화면을 촬영한 이미지 |
| 🔴 | ☐ | 앱 카테고리 | 생산성 / 라이프스타일 등 |
| 🔴 | ☐ | 앱 키워드 | App Store 검색용 |
| 🔴 | ☑ | 지원 URL | https://www.shiftmate.co.kr/support — 2026-10-18 GET 200·본문 확인. Connect 입력은 별도 |
| 🔴 | ☐ | 개인정보 처리방침 URL | 공개 웹페이지로 제공 |
| 🔴 | ☐ | 앱 연령 등급 | Apple 연령 등급 질문에 응답 |
| 🔴 | ☐ | 앱 버전 | 예: `1.0.0` |
| 🔴 | ☐ | 배포 국가 및 지역 | 대한민국 또는 글로벌 |
| 🔴 | ☐ | 저작권 정보 | 필수. 실제 권리자 및 연도 확인 후 입력 |
| ⚪ | ☐ | 앱 부제목 | 최대 30자 |
| ⚪ | ☐ | 홍보 문구 | 앱의 특징 강조 |
| ⚪ | ☐ | 앱 미리보기 영상 | 실제 앱 사용 영상 |
| ⚪ | ☐ | 다국어 설명 | 영어, 일본어 등 |

### 스크린샷 준비

첨부의 스크린샷 요구사항 요약입니다. 정확한 기기 크기·픽셀 규격은 2번 진행 시 공식 규격표로 재확인해야 합니다.

| 기기 | 요구사항 |
|---|---|
| iPhone | 큰 Dynamic Island 화면 규격을 우선 준비. 해당 스크린샷이 없으면 큰 Face ID 화면 규격 필요 |
| iPad | 최초 출시 미지원으로 이번 제출 대상에서 제외. 추후 지원 추가 시 준비 |
| 기타 기기 | 지원 플랫폼에 따라 추가 요구사항 확인 |

기기 크기별로 최대 10장의 스크린샷을 등록할 수 있습니다. [Apple Developer](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications?utm_source=chatgpt.com)

**ShiftMate 추천 스크린샷 구성**

1. 월별 근무표와 일정 통합 조회
2. 친구 및 가족과 캘린더 공유
3. 근무 일정 등록 및 관리
4. 친구 일정 확인
5. 친구별 열람 허용·공개 레벨 설정 (확인하지 않은 주간 브리핑 문구 제외)

앱 소개 이미지에는 실제 구현된 기능만 포함하는 것이 좋습니다.

---

## 3. 개인정보 및 법적 문서

**앱 개발과 별개로 반드시 시간을 확보해야 하는 영역입니다.**

| 우선순위 | 체크 | 준비 항목 | 설명 |
|---|---|---|---|
| 🔴 | ☐ | 개인정보 처리방침 | 수집 정보, 이용 목적, 보관 기간 등 |
| 🔴 | ☐ | 개인정보 처리방침 공개 URL | 로그인 없이 열리는 웹페이지 |
| 🔴 | ☐ | App Privacy 작성 | Apple에 데이터 수집 및 이용 현황 신고 |
| 🔴 | ☐ | 계정 삭제 기능 | 계정 생성이 가능한 앱인 경우 |
| 🔴 | ☐ | 데이터 삭제 정책 | 탈퇴 시 개인정보 및 관련 데이터 처리 |
| 🟡 | ☐ | 서비스 이용약관 | 서비스 정책 및 법적 요구사항에 따라 준비 |
| 🟡 | ☐ | 개인정보 제3자 제공 안내 | 해당하는 경우 |
| 🟡 | ☐ | 개인정보 처리 위탁 안내 | 클라우드 및 외부 서비스 이용 시 |
| 🟡 | ☐ | 국외 이전 관련 안내 | 해외 서버·서비스로 개인정보를 이전하는 경우 |
| 🟡 | ☐ | 마케팅 알림 동의 | 광고성 푸시 알림을 발송하는 경우 |
| ⚪ | ☐ | 고객 문의 채널 | 이메일 또는 문의 페이지 |
| ⚪ | ☐ | 데이터 다운로드 기능 | 사용자 데이터 내보내기 |

### 특히 주의할 부분

**① 회원 탈퇴 기능**

Apple은 계정 생성 기능을 제공하는 앱에 앱 내부에서 계정 삭제를 시작할 수 있는 기능을 요구합니다.

단순히 로그아웃하거나 앱에서 계정을 비활성화하는 것만으로는 부족합니다.

**② 개인정보 공개**

App Store Connect에서 다음과 같은 데이터 수집 여부를 작성해야 합니다.

- 이메일 및 사용자 식별자
- 이름·프로필 정보
- 일정 및 사용자가 입력한 정보
- 앱 사용 기록
- 기기 정보 및 진단 데이터
- 분석 SDK가 수집하는 정보

앱뿐 아니라 통합된 타사 SDK의 데이터 처리도 포함해야 합니다. [Apple Developer](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy?utm_source=chatgpt.com)

---

## 4. 로그인 및 회원 관리

ShiftMate처럼 회원 간 정보를 공유하는 앱에서 중요한 항목입니다.

| 우선순위 | 체크 | 준비 항목 | 설명 |
|---|---|---|---|
| 🔴 | ☐ | 회원가입 정상 동작 | 신규 사용자 가입 |
| 🔴 | ☐ | 로그인 정상 동작 | 기존 사용자 로그인 |
| 🔴 | ☐ | 로그아웃 정상 동작 | 인증 세션 해제 |
| 🔴 | ☐ | 회원 탈퇴 | 앱에서 계정 삭제 요청 가능 |
| 🔴 | ☐ | 인증 오류 처리 | 만료된 토큰, 네트워크 오류 등 |
| 🟡 | ☐ | Apple 로그인 정책 확인 | 사용하는 소셜 로그인 방식에 따라 적용 |
| 🟡 | ☐ | 로그인 취소 처리 | OAuth 인증 취소 |
| 🟡 | ☐ | 계정 재가입 처리 | 탈퇴 후 동일 계정 재가입 |
| 🟡 | ☐ | 세션 및 토큰 보안 | 토큰 저장, 갱신, 폐기 |
| ⚪ | ☐ | 계정 복구 | 계정 접근 복구 방법 제공 |

Google, Kakao 등 타사 소셜 로그인을 제공하는 경우 Apple의 로그인 정책을 확인해야 합니다. 모든 소셜 로그인 앱에 Apple 로그인이 무조건 필요한 것은 아니며 예외가 존재합니다.

---

## 5. iOS 기술 설정 및 빌드

2026년 10월 기준 Apple의 최소 제출 요구사항은 **Xcode 26 이상과 iOS 26 SDK 이상**입니다.

또한 2026년 9월 9일부터 업로드하는 iOS 앱의 최소 배포 대상은 iOS 13 이상이어야 합니다. [Apple Developer](https://developer.apple.com/news/upcoming-requirements/?utm_source=chatgpt.com)

| 우선순위 | 체크 | 준비 항목 | 설명 |
|---|---|---|---|
| 🔴 | ☐ | 최신 요구 SDK 적용 | Xcode 26 이상, iOS 26 SDK 이상 |
| 🔴 | ☐ | Bundle Identifier 확인 | App Store Connect 설정과 일치 |
| 🔴 | ☐ | 앱 버전 설정 | `CFBundleShortVersionString` |
| 🔴 | ☐ | 빌드 번호 설정 | `CFBundleVersion` |
| 🔴 | ☐ | Release 빌드 성공 | 배포용 빌드 |
| 🔴 | ☐ | 앱 서명 성공 | Distribution Signing |
| 🔴 | ☐ | HTTPS 통신 | API 통신 보안 |
| 🔴 | ☐ | 앱 시작 및 종료 테스트 | 실행 직후 Crash 확인 |
| 🟡 | ☐ | 권한 요청 설명 | 알림, 사진, 카메라 등 |
| 🟡 | ☐ | Push Notification 설정 | APNs, FCM 연동 |
| 🟡 | ☐ | Deep Link 설정 | 초대 링크 등 |
| 🟡 | ☐ | Privacy Manifest 검증 | 관련 SDK 및 API 사용에 따른 선언 |
| 🟡 | ☐ | 암호화 사용 정보 신고 | 수출 규정 관련 질문에 응답 |
| ⚪ | ☐ | Crash 수집 도구 | Firebase Crashlytics 등 |
| ⚪ | ☐ | 자동 배포 파이프라인 | Fastlane, GitHub Actions 등 |

Flutter로 개발하고 있다면 추가로 다음 항목을 확인하면 됩니다.

- iOS Deployment Target
- CocoaPods 및 iOS 플러그인 호환성
- `Info.plist` 권한 설명
- `Runner.entitlements`
- Release 환경 변수
- Release 빌드의 API Base URL
- iOS 푸시 알림 토큰 처리

---

## 6. 앱 기능 및 품질 테스트

| 우선순위 | 체크 | 준비 항목 | 설명 |
|---|---|---|---|
| 🔴 | ☐ | 앱 실행 테스트 | 실행 시 Crash 발생 여부 |
| 🔴 | ☐ | 주요 기능 테스트 | 일정 생성·수정·삭제·조회 |
| 🔴 | ☐ | 네트워크 오류 처리 | 인터넷 연결 끊김, 서버 오류 |
| 🔴 | ☐ | 로딩 상태 처리 | 무한 로딩 방지 |
| 🔴 | ☐ | 빈 데이터 처리 | 일정이 없을 때 정상 표시 |
| 🔴 | ☐ | 사용자별 데이터 접근 제어 | 다른 사용자의 비공개 데이터 접근 차단 |
| 🔴 | ☐ | 실제 iPhone 테스트 | 시뮬레이터 외 실기기 검증 |
| 🟡 | ☐ | 푸시 알림 테스트 | 백그라운드 및 앱 종료 상태 |
| 🟡 | ☐ | Deep Link 테스트 | 초대 링크, 공유 링크 |
| 🟡 | — | iPad UI 테스트 | 최초 출시 미지원. 후속 업데이트 TODO |
| ⚪ | ☐ | 다크 모드 테스트 | UI 표시 확인 |
| ⚪ | ☐ | 접근성 테스트 | 글자 크기, VoiceOver 등 |
| ⚪ | ☐ | 성능 테스트 | 월별 일정이 많은 경우 |
| ⚪ | ☐ | 배터리 사용량 확인 | 불필요한 백그라운드 작업 |

### ShiftMate에서 추가로 확인할 사항

공유 캘린더 특성상 다음 기능을 집중적으로 테스트하는 것이 좋습니다.

- 친구 초대 및 초대 수락
- 공유 캘린더 접근 권한
- 친구 관계 해제 시 접근 권한 변경
- 탈퇴한 사용자와 연결된 일정 처리
- 여러 기기에서 동일한 일정 동기화
- 일정 변경 시 관련 사용자에게 변경 내용 반영
- 여러 날짜에 걸친 일정 표시
- 푸시 알림 중복 발송 방지

또한 사용자 생성 콘텐츠가 포함된 소셜 기능을 제공한다면 Apple의 신고·차단·콘텐츠 관리 정책도 검토해야 합니다. [Apple Developer](https://developer.apple.com/kr/app-store/review/guidelines/?utm_source=chatgpt.com)

---

## 7. App Store 심사 준비

**이 부분은 실제 심사 거절을 방지하기 위해 특히 중요합니다.**

| 우선순위 | 체크 | 준비 항목 | 설명 |
|---|---|---|---|
| 🔴 | ☐ | 심사용 계정 | Apple 심사자가 사용할 테스트 계정 |
| 🔴 | ☐ | 테스트 데이터 | 주요 기능을 확인할 수 있는 데이터 |
| 🔴 | ☐ | 심사 연락처 | 이메일 및 전화번호 |
| 🔴 | ☐ | 앱 심사 정보 | 앱의 목적과 기능 설명 |
| 🔴 | ☐ | 백엔드 서버 접근 가능 | 심사 중 서버 정상 운영 |
| 🔴 | ☐ | 개인정보 처리방침 접근 가능 | URL 정상 연결 |
| 🔴 | ☐ | 테스트 계정 권한 확인 | 주요 기능을 이용할 수 있어야 함 |
| 🟡 | ☐ | 외부 서비스 사용 설명 | 로그인, AI, 결제 등 |
| 🟡 | ☐ | 특수 기능 테스트 방법 | 초대, 공유, 알림 등 |
| ⚪ | ☐ | 심사 메모 작성 | 기능별 접근 방법 및 주의사항 |

### 심사용 계정 예시

공유 캘린더라면 테스트 계정을 2개 이상 준비하는 편이 좋습니다.

| 계정 | 용도 |
|---|---|
| `reviewer1@example.com` | 일정 생성 및 수정 |
| `reviewer2@example.com` | 공유받은 일정 확인 |

두 계정 간 친구 관계 및 공유 캘린더를 미리 설정해두면 심사자가 기능을 쉽게 확인할 수 있습니다.

Apple은 로그인이 필요한 앱에 활성화된 데모 계정이나 적절한 데모 환경을 제공하고, 심사 중 백엔드가 정상 작동하도록 요구합니다. [Apple Developer](https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review?utm_source=chatgpt.com)

---

## 8. TestFlight 및 출시 절차

| 순서 | 체크 | 작업 |
|---|---|---|
| 1 | ☐ | Xcode에서 Release 빌드 생성 |
| 2 | ☐ | App Store Connect에 빌드 업로드 |
| 3 | ☐ | 빌드 처리 및 검증 완료 확인 |
| 4 | ☐ | TestFlight 내부 테스트 |
| 5 | ☐ | TestFlight 외부 테스트(권장) |
| 6 | ☐ | 주요 버그 수정 |
| 7 | ☐ | App Store 등록 정보 입력 |
| 8 | ☐ | App Privacy 및 연령 등급 설정 |
| 9 | ☐ | 심사 계정 및 심사 메모 등록 |
| 10 | ☐ | 출시 국가·가격 설정 |
| 11 | ☐ | App Review 제출 |
| 12 | ☐ | 심사 결과 확인 및 대응 |
| 13 | ☐ | 승인 후 앱 출시 |

TestFlight는 내부 테스터 최대 100명, 외부 테스터 최대 10,000명을 지원하며, 외부 테스트에는 베타 앱 심사가 필요할 수 있습니다. [Apple Developer](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/?utm_source=chatgpt.com)

Apple은 App Store Connect에서 빌드와 필수 등록 정보를 설정한 뒤 심사 제출을 진행하도록 안내합니다. [Apple Developer](https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app?utm_source=chatgpt.com)

---

## 9. 출시 후 운영 준비

App Store 심사 통과 자체에 필수인 항목은 아니지만 실제 서비스를 운영한다면 권장합니다.

| 우선순위 | 체크 | 준비 항목 |
|---|---|---|
| ⚪ | ☐ | Crash 및 예외 모니터링 |
| ⚪ | ☐ | 서버 Health Check |
| ⚪ | ☐ | API 오류 로그 관리 |
| ⚪ | ☐ | 사용자 문의 대응 |
| ⚪ | ☐ | 서비스 장애 대응 절차 |
| ⚪ | ☐ | DB 백업 및 복구 |
| ⚪ | ☐ | 앱 버전 업데이트 정책 |
| ⚪ | ☐ | 최소 지원 버전 정책 |
| ⚪ | ☐ | 앱 리뷰 및 평점 모니터링 |
| ⚪ | ☐ | 개인정보 삭제 요청 처리 |
| ⚪ | ☐ | CI/CD 자동 배포 |

---

## 10. ShiftMate 기준 우선 준비할 항목

현재 서비스를 최초 출시하는 단계라면 다음 순서로 진행하는 것을 추천합니다.

| 순위 | 준비 항목 | 우선 이유 |
|---|---|---|
| 1 | Apple Developer 계정 가입 | 배포 환경 구축의 시작 |
| 2 | Bundle ID 및 iOS 배포 설정 | 빌드 및 TestFlight에 필요 |
| 3 | 개인정보 처리방침 작성 | 앱 심사 필수 |
| 4 | 회원 탈퇴 기능 구현 | Apple 심사 요구사항 |
| 5 | 소셜 로그인 정책 검토 | 로그인 방식에 따라 추가 구현 필요 |
| 6 | 앱 아이콘 제작 | App Store 및 앱 설치 화면 |
| 7 | 앱 스크린샷 제작 | 스토어 등록 필수 |
| 8 | 앱 소개 및 지원 페이지 작성 | App Store 메타데이터 |
| 9 | 공유 캘린더 권한 테스트 | 핵심 서비스 기능 |
| 10 | 심사용 테스트 계정 준비 | 주요 기능 검증 |
| 11 | TestFlight 테스트 | 출시 전 안정성 확인 |
| 12 | App Review 제출 | 최종 심사 |

### 별도로 준비할 웹페이지

자체 도메인을 사용한다면 다음처럼 구성하면 관리하기 편합니다.

| URL 예시 | 용도 |
|---|---|
| `shiftcalendar.co.kr/privacy` | 개인정보 처리방침 |
| `shiftcalendar.co.kr/terms` | 서비스 이용약관 |
| `shiftcalendar.co.kr/support` | 고객 문의 및 지원 |
| `shiftcalendar.co.kr/account/delete` | 계정 삭제 관련 안내 |

각 URL은 예시이며 실제 연결 가능한 페이지를 준비해야 합니다. 이용약관 및 계정 삭제 안내 페이지의 별도 공개는 상황에 따라 판단할 수 있습니다.

---

## 최종 정리

최초 출시에서는 다음 **5가지 영역을 먼저 완료**하는 것이 효율적입니다.

1. **개발자 계정 및 iOS 빌드 설정**
2. **개인정보 처리방침 및 회원 탈퇴**
3. **앱 아이콘·스크린샷·스토어 등록 정보**
4. **앱 기능 검증 및 심사용 테스트 계정**
5. **TestFlight 테스트 및 App Review 제출**

특히 ShiftMate는 **로그인, 사용자 일정 데이터, 친구와의 정보 공유** 기능이 있으므로 개인정보 처리와 접근 권한 검증이 중요합니다.

Apple의 심사 정책뿐 아니라 대한민국 개인정보 보호 관련 법적 의무도 별도로 확인해야 합니다.

### 주요 공식 문서

- [Apple App Store 제출 안내](https://developer.apple.com/kr/app-store/submitting/)
- [Apple App Review Guidelines](https://developer.apple.com/kr/app-store/review/guidelines/)
- [App Store Connect](https://appstoreconnect.apple.com/)
- [App Privacy 설정 가이드](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy)
- [TestFlight 가이드](https://developer.apple.com/help/app-store-connect/test-a-beta-version/testflight-overview/)

**참고:** 2026년 10월 현재 적용되는 SDK 요구사항을 기준으로 작성했습니다. 출시 시점이 변경되면 Apple의 최소 SDK 및 심사 요구사항을 다시 확인하는 것이 좋습니다.
