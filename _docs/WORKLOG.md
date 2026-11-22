# 작업 로그

## 2026-11-22 위젯 개발 참고 자료 버전 관리

- [DONE] (개발 환경) 기존 widgets 스킬과 원본 lock을 보존하고 로컬 Gradle 캐시는 버전 관리에서 제외했다.
  - 목적/변경: WidgetKit 개발 참고 자료의 재현성을 확보하고 자동 생성 캐시의 유입을 방지한다.
  - 파일/영향: `.agents/skills/widgets/`, `skills-lock.json`, `.gitignore`; 파일 역할·의존성·사용 예는 PROJECT_CONTEXT의 같은 제목 절을 따른다. 앱 동작 변경은 없다.
  - 테스트: lock JSON과 파일 경로, `git check-ignore` 및 커밋 파일 목록을 확인한다.
  - 롤백: 이 작업의 참고 자료/lock과 ignore 추가분만 revert한다.

## 2026-11-22 인증번호 전송 버튼을 번호 입력 오른쪽에 배치

- [DONE] (FE/UI) 인증번호 받기 버튼을 휴대폰 입력 오른쪽으로 옮기고 인증하기와 같은 파란 액션으로 표시했다.
  - 목적/범위: 사용자 요청의 입력/액션 가로 배치를 가입과 변경 번호 편집에 공통 적용한다. 작은 폭/큰 글자는 읽을 수 있게 세로 배치한다.
  - 변경/Behavior change: Page 공용 입력의 trailing 슬롯과 PhoneVerificationSection의 phone_input_builder(action)로 발송 버튼을 라벨 아래의 입력 오른쪽8px 간격에 중앙 정렬했다. 버튼 최소56/파랑·대기 비활성/번호 확인 중 표시를 제공하고 Google 안내는 행 아래에 유지한다. 폭300미만/14px 글자18초과면 세로 배치, 액션 폭은 행45% 이내다. 기존 발송/확인·재발송·번호 편집/복귀·저장·API/DB/라우트·상태 수명을 유지한다. 신규 파일은 없다. 초기 영역이 줄어 이전의 전후 동일 높이 검증을 종료하고 가로 위치/높이·기존 인증 전환 검증으로 갱신했다.
  - 테스트: 기존 profile_setup_page_test.dart와 인증 렌더 **43 pass**,26조건 framework 오류0/미스 터치 경고0, 변경3파일 analyze 진단0·포맷/공백 검사 통과.390px 최초 전송 행과375/320px 인증 입력·큰 글자/발송 중 이미지를 직접 확인했다. 기존 검토 PNG8개/measurements.json을 갱신하고 PROJECT_CONTEXT·ADR-0104에 인터페이스 역할/사용 예·표시 정책을 기록했다. 로그는 /private/tmp/shiftmate-profile-ui-20261122/send-row-*.log다. 실제 기기/실문자 인수는 별도다.
  - 롤백: 이번 Page/인증 위젯·기존 회귀/검토 자료·문서 변경분만 복원한다.


## 2026-11-22 프로필 번호 변경 안내 문구 제거

- [DONE] (FE/UI) 사용자 요청으로 기존 번호 아래의 재인증 안내와 해당 여백을 제거했다.
  - 목적/변경: 공용 PhoneVerificationSection의 안내 표시만 제거한다. 번호 변경 인증·저장 조건은 유지한다.
  - 영향: 프로필 수정의 미변경 번호 표시와 검토 이미지/기존 문서. 신규 파일·API/DB 변경은 없다.
  - 테스트: 기존 profile_setup_page_test.dart/인증 렌더43 pass·26조건 오류0, phone_verification_section.dart analyze 진단0·포맷 변경0·공백 검사 통과. 기존 검토 PNG8개/측정 JSON을 재생성하고 편집 최초 화면을 직접 확인했다. 로그는 /private/tmp/shiftmate-profile-ui-20261122/remove-phone-hint-*.log다. PROJECT_CONTEXT·ADR-0104를 최신화했다.
  - 롤백: 이번 조건부 표시/문서·검토 이미지 갱신분만 복원한다.


## 2026-11-22 회원가입·프로필 수정 전면 UI 재설계

- [DONE] (FE/UI) ui-ux-pro-max 스킬로 두 화면을 소개 문구 없는 간결한 정보 입력 폼으로 재설계했다.
  - 목적/근거: 사용자 최초 요청과 후속 “환영·소개 없이 필요한 정보 입력/마일드” 방향, PROJECT_CONTEXT 공용 UI/인증과 ADR-0101~0103, Page/공용 인증 위젯/AppTheme/연결 route/기존 회귀/렌더러/DDL·drawio를 직접 확인했다. drawio는 현행과 다른 이전 모델이므로 DB를 변경하지 않았다.
  - 변경/Behavior change: 흰 화면·72px 사진·기본/선택 근무 정보·중립 입력/얇은 구분선·계정 상자·하단 고정 버튼으로 정리했다. 최종안에는 영문/환영/소개 문구·큰 제목·이름 요약·파란 사진 패널·번호 장식이 없다. 가입 제목/버튼은 회원가입/가입 완료, 편집은 프로필 수정/변경사항 저장이다. 입력 최소56·라벨14/값16·본문 너비480·좌우20/24, 선택 정보 빈 placeholder·필수 표시를 유지했다. 높이360미만/확대 글자는 인증 안내·저장 오류를 본문으로 옮기며 오류를 스크롤해 표시한다. 최초 프로필 GET 전 스피너, 실패 영역 스크롤로3.2배 일시적22px 넘침도 해결했다.
  - 범위/파일: 제품은 기존 profile_setup_page.dart만 변경했다. profile_setup_page_test.dart와 기존 phone_verification_2026-11-21/render_test.dart를 갱신했다. 새 검토 PNG8개/측정 JSON의 역할·의존성·재현/사용 예는 PROJECT_CONTEXT 최신 절에 기록했다. 인증 controller/SDK/Dio/저장·DB/route/권한·analytics/env/의존성은 유지하고 ADR-0103의 즉시 뒤로가기도 보존했다. 기존 미커밋 변경은 되돌리지 않았다.
  - 스킬/진단: design-system 검색의 Flat Design을 참고했으나 웹 랜딩 패턴은 모바일 폼에 적용하지 않았다. product 재검색은 정확한 모바일 온보딩 일치가 없어 근거로 사용하지 않았고 별도 ux 검색의 inline/visible label·Flutter/앱 접근성 체크를 적용했다. debug-live 중단점/테스트 실행을 시도했으나 기존 iPhone Release 세션만 조회되어 테스트 중단이 불가능했다. 기존 세션을 중단하지 않고 이번 중단점만 제거했으며 실제 렌더 오류/화면 크기와 초기 로딩 코드를 확인해 수정·재실행했다. 임시 소스 로그/시스템 설정 변경은 없다.
  - 테스트: `flutter test --no-pub test/features/auth artifacts/phone_verification_2026-11-21/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --dart-define=PHONE_AUTH_RENDER_DIR=/private/tmp/shiftmate-profile-ui-20261122/render --reporter expanded` **190 pass**. 저장 실패의320px/글자3.2배 오류 가시성·재시도 회귀를 추가했다. 변경3파일 analyze 진단0·포맷/공백 검사 통과. SDK 캐시 제한은 검증 명령의 승인된 권한 확장으로 해소했다.
  - 렌더/결과: 가입/편집13조건씩26측정·상/하단 등을 포함한 PNG32개.320/375/390·가로844/태블릿768·글자2/3.2배·동작 줄이기·OS 다크 설정/라이트 표면·240px 모의 키보드·인증 발송/실패/완료를 검증했다. 미스 터치 경고를 실패로 처리했고 결과0건, framework 오류0건, 버튼 최소56·스크롤 최소122다. 최종 상/하단·인증·키보드/큰 글자 PNG를 직접 열어 확인했다. 전체 자료와 로그/시작 소스는 `/private/tmp/shiftmate-profile-ui-20261122/`다.
  - 문서/롤백: PROJECT_CONTEXT 최신 UI/파일·재현 절, ADR-0104, 본 일지를 갱신했다. 이번 UI/회귀·렌더러/새 검토 자료·문서 변경분만 복원한다. 이전 작업이 있는 파일 전체를 git restore하지 않는다.
  - 한계/다음: 실제 OS 사진/키보드·VoiceOver·실문자·서버/원격 게시 인수는 미실행이다. 사용자 방향을 반영한 최종 화면을 기준으로 실기기 확인한다.

## 2026-11-22 프로필 수정 미저장 뒤로가기 확인 제거

- [DONE] (FE/UI) 변경사항 버리기 확인과 미저장 변경에 따른 뒤로가기 차단을 제거했다.
  - 목적/근거: 사용자가 이전 discard 제거 결정이 프로필에 반영되지 않았다고 지적했다. PROJECT_CONTEXT·ADR-0043/0102·WORKLOG와 Page의 _requestLeave/PopScope·설정/프로필 탐색 회귀를 직접 읽고 남아 있는 확인창과 dirty guard를 확인했다. 이번 사용자 지시를 최신 정책으로 적용한다.
  - 변경/Behavior change: _requestLeave는 busy가 아니면 Navigator.maybePop으로 바로 복귀한다. _allow_pop/_confirming_leave·폐기 dialog·변경 시 canPop 차단과 onPop 재확인 분기를 삭제했다. 변경 감지는 저장 버튼 활성화에만 사용하며 뒤로가기 자체는 API 저장을 요청하지 않는다. 기존 저장/사진 선택 중 busy 보호는 유지한다. 미저장 이름/번호 변경은 재진입 시 기존 GET 값으로 돌아간다.
  - 영향/파일: 제품은 기존 profile_setup_page.dart만 수정했다. 기존 profile_setup_page_test의 확인창 시나리오를 버튼/시스템/실제 iOS edge drag3조건으로 교체하고, 문자 전송 대기 중 뒤로가기/세션 정리·늦은 콜백 무시를 추가했다. settings_page_test의 실제 설정 복귀 회귀에서 이전 확인창 기대를 제거하고 기존 사용자 이름/저장 호출0을 확인한다. 새 파일/패키지·API/DB/native·인증 정책과 다른 화면은 변경하지 않았다. PROJECT_CONTEXT·ADR-0103/0043후속·본 로그를 갱신했다.
  - 테스트: `flutter test --no-pub test/features/auth/application test/features/auth/presentation test/features/auth/data/repositories/phone_verification_repository_test.dart test/features/auth/data/services/firebase_phone_auth_service_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter expanded` **119 pass**. 변경3 Dart파일 `flutter analyze --no-pub` **진단0**, 포맷·diff 공백 검사 통과. 최초 설정 회귀에 남은 이전 확인창 기대1건은 새 정책으로 갱신한 뒤 최종 전체 대상 회귀를 통과했다. SDK 캐시 접근 제한은 승인된 검증 명령 권한 확장으로 해소했다.
  - 검증/자료: 수정 후3경로 즉시 복귀·확인창 없음·저장/가입/문자 요청0·재진입 초깃값 복구, 발송 대기 이탈의 SDK 세션 종료와 늦은 codeSent 무시, 미변경 복귀/성공 저장·저장/사진 선택 중 보호를 확인했다. 구조/스타일을 바꾸지 않아 PNG 렌더는 반복하지 않았다. 시작 소스·로그는 `/private/tmp/shiftmate-profile-back-20261122/`에 있다. 실기기 OS 제스처/VoiceOver는 미실행이다.
  - 롤백: 이번 Page/탐색 회귀/문서 추가분만 복구한다. 시작 소스는 위 임시 폴더의 profile_setup_page.before.dart다. 앞선 인증/UI·개인정보 정책과 다른 미커밋 작업을 보존한다. 향후 사용자 새 지시 없이 discard 확인을 다시 추가하지 않는다.

## 2026-11-22 번호 중복 확인 후 인증 입력 선표시·라벨 개선

- [DONE] (FE/UI) 서버 challenge 성공 직후 코드 입력을 표시하고 SDK 준비/문자 콜백은 백그라운드에서 계속 진행하도록 변경했다.
  - 목적/근거: SDK 발송 콜백 대기 때문에 입력을 시작하지 못하는 지연을 줄이고 전화번호가 라벨처럼 보이는 구성을 개선한다. PROJECT_CONTEXT·ADR-0101·WORKLOG·Page/widget/controller/state·SDK/repository·fake/회귀를 직접 읽고 인접 서버 createChallenge의 신규/멱등 복구 경로 모두 assertPhoneAvailable로 중복을 거절함을 확인했다. 원격 배포 상태를 추정하지 않았다. UI/UX 스킬의 라벨/로딩/포커스·큰 글자 기준을 적용했다.
  - 변경/Behavior change: checking(서버 중복/목적/기한 확인)과 sending(SDK 준비/발송)을 분리했다. 유효한 challenge 직후 sending으로 갱신해 OTP를 보이고 포커스·입력을 허용하되 code_sent 전 확인/저장/재발송은 차단한다. 전송 중 상태를 명시하고 실제 codeSent 후 입력 코드를 보존·6자리 확인을 활성화한다. 기존90초 timeout의 시작을 SDK 준비 전으로 옮겼고 준비/발송 실패는 번호 입력/오류로 복구한다. 늦은 세션/콜백·번호 변경·재발송 대기/멱등 방어는 유지한다.
  - UI: ‘인증번호 *’ 라벨과 코드/확인 아래에 별도 옅은 ‘수신 번호’ 요약 상자·번호 변경을 배치했다. 입력 아래에 전송 중/재발송을 표시한다. 좁은 폭/큰 글자는 코드/확인 및 번호/변경을 세로로 배치하며 번호는 하이픈 구간 단위로 줄바꿈/전체값 접근성 이름을 유지한다. 기본 크기에서 전체 전화 입력을 누적하지 않고 단계 교체를 유지하며 이전의 높이 완전 동일 검증은 새 요약 상자의8px 변화에 맞춰16px 이내로 갱신했다.
  - 인증 확인 검토/영향: SDK signInWithCredential→getIdToken(true)→서버 verify→저장 증명/목적/기한 대조를 직접 읽었다. 실제 기기 지연을 계측하지 않았고 이 필수 경로의 생략/임의 낙관적 완료를 적용하지 않았다. 제품 수정은 기존 state/controller/widget뿐이며 Page·SDK 서비스·API/DB/native/env·route/analytics·동의/정책 파일과 다른 미커밋 작업은 보존했다.
  - 파일/문서: 기존 test/helpers에 SDK 시작 지연/실패 주입을 보강하고 controller 회귀6개·페이지 회귀3개를 추가했다. 기존 렌더러는 발송 대기·큰 글자2조건×가입/편집을 추가해24조건을 생성한다. 기존 검토PNG3개를 갱신하고 signup_sending.png를 추가했다. 역할/의존성·사용 예는 PHONE_VERIFICATION_FLUTTER_PLAN13절, 상태 정책은 PROJECT_CONTEXT·ADR-0102에 기록했다. 새 제품 파일/패키지는 없다.
  - 테스트: `flutter test --no-pub test/features/auth/application test/features/auth/data/repositories/phone_verification_repository_test.dart test/features/auth/data/services/firebase_phone_auth_service_test.dart test/features/auth/presentation test/features/auth/data/datasources/auth_remote_datasource_test.dart artifacts/phone_verification_2026-11-21/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --dart-define=PHONE_AUTH_RENDER_DIR=/private/tmp/shiftmate-phone-optimistic-20261122/render --reporter expanded` 최종 **136 pass**. 변경7 Dart파일 `flutter analyze --no-pub` **진단0**, 포맷·diff 공백 검사 통과. SDK 캐시 제한은 승인된 검증 명령 권한 확장으로 해소했다.
  - 실행/렌더: 중복 확인 대기/409거절·SDK 준비 지연/실패·codeSent 지연·준비/콜백90초 timeout·미리 입력6자리 유지·확인 차단/활성·실패 복귀·번호 변경/늦은 성공·실패·기존 재발송/자동 인증/멱등 복구를 확인했다. PNG24개 중375 인증·390 전송 중·320 큰 글자/전송 중을 직접 확인했다. 큰 글자에서 번호 변경 버튼이 번호 폭을 좁히던 구성을 세로로 보완하고 마지막 한 자리만 줄바꿈되던 표시를 하이픈 구간 단위로 수정했다. 초기 렌더의 한 줄 고정 가정은2배 글자에서 자연스러운 최대2줄 기준으로 보완한 최종 회귀를 통과했다.
  - 자료/한계: 시작 소스·모든 로그/PNG는 `/private/tmp/shiftmate-phone-optimistic-20261122/`에 보존했다. 실제 SMS·실기기 키보드/VoiceOver·APNs/reCAPTCHA·단계별 지연 수치·원격 배포는 미검증이다. 네트워크 완료 시간 단축을 주장하지 않는다.
  - 롤백: 이번 state/controller/widget·fake/회귀/렌더러·검토 PNG·문서 추가분만 복구한다. 시작 소스는 위 임시 폴더의 같은 이름3개다. 이전 UI·정책 HTML과 다른 미커밋 변경을 보존한다.

## 2026-11-22 개인정보 HTML 휴대폰 인증 고지 보완

- [DONE] (문서/웹) Firebase Phone Auth의 확인된 처리 내역을 privacy.html과 동일 정책 MD v1.2에 반영했다.
  - 목적: 앱 인증 흐름에 필요한 처리 내역이 공개 정책 파일에 누락된 상태를 해소한다. 작업 전 PROJECT_CONTEXT·ADR-0101·직전 WORKLOG와 공개 HTML/MD·인증 SDK/모델·이전 개인정보 검토를 직접 읽었다.
  - 변경/영향:2항에 번호/문자코드·인증 정보·SDK IP/사용자 에이전트·인증과 Google 전반 악용 방지 목적,3항에 외부 인증 보관,6항에 FCM과 별도 서비스,7항에 미국·전송 시점/방법·Firebase 공식 보관 기준·Google 공개 문의 이메일·거부 영향/권리 요청을 추가했다. 버전1.2/최종수정2026-11-22·개정 이력을 동기화했다. 최초 시행일·기존 연령/동의/다른 처리 내용·CSS는 유지했다. 공개 정책의 Behavior change이며 앱/API/DB/동의 기록·사용자 삭제 동작은 변경하지 않았다.
  - 근거/범위: Firebase 공식 Phone Auth의 번호 전송/저장·서비스 전반 악용 방지·사전 동의 요구, 개인정보 안내의 미국 처리·IP 수 주/그 외 사용자 삭제 요청 전 보관·요청 후180일 이내 제거를 재확인했다. Google 한국어 개인정보방침의 공개 문의 이메일을 사용했다. Firebase 일반 기준임을 명시하고 실제 삭제 기능/적법한 동의 확보/특정 계정 계약 완료로 쓰지 않았다. 출처/후속 확인은 PRIVACY_REVIEW v1.2에 기록했다.
  - 파일/문서: 기존 app_store_web/privacy.html·PRIVACY_POLICY.md·PRIVACY_REVIEW.md, PROJECT_CONTEXT·PHONE_VERIFICATION_FLUTTER_PLAN·ADR-0101 후속·본 로그를 갱신했다. 새 영구 파일은 없다. UI 작업 당시 정책 누락/수정 없음 기록과 이번 로컬 보완을 구분했다.
  - 검증: 표준 HTMLParser로 중첩·14절/5표·모든 MD/HTML 표 셀 일치·기존 표 행 및1/4/5/8~13절·CSS 보존·버전/날짜를 확인했다. 실제 Chrome CDP viewport320/375/1440에서5표의 헤더/본문 열x/열수 일치·페이지 가로 넘침 없음 확인,375/1440의 새 인증 행/거부 문구 렌더를 직접 열어 확인했다. diff 공백 검사 통과. 문안 변경이라 앱 테스트는 반복하지 않았다.
  - 검증 도구: 초기 제한 환경 Chrome 종료134는 승인된 로컬 렌더 권한 확장으로 해소했다. headless window-size의 캡처 잘림/스크롤 빈 화면은 검토 근거에서 제외하고 CDP device metrics·실제 innerWidth 대조·paint 대기 캡처로 교체했다. 검사 코드/시작 사본·DOM·최종 PNG·geometry.json은 `/private/tmp/shiftmate-privacy-phone-20261122/`에 보존했다. 임시 도구는 표준 Python/Node23·설치 Chrome만 사용하며 저장소 의존성을 추가하지 않았다.
  - 롤백: 이번 정책/문서의 추가분만 복원한다. 원본 HTML/MD는 위 임시 폴더의 privacy.before.html·PRIVACY_POLICY.before.md다. 기존 UI와 다른 미커밋 작업은 보존한다.
  - 한계/다음: **원격 서버에는 게시하지 않았다.** 공개 시점/필요 고지·동의와 실제 수신자 계약·이전 근거·Firebase 사용자 소유 대조/삭제 절차를 확인한 뒤 `/privacy` HTML을 교체하고 실제 앱 링크를 점검한다. 문안 수정으로 법적 요건 충족을 확정하지 않는다. 실기기 Safari/VoiceOver는 미실행이다.

## 2026-11-22 회원가입 휴대폰 인증 UI 개선·안내 검토

- [DONE] (FE/UI) 전화번호와 인증번호 입력을 단계별로 교체하고 Google 안내 이동의 조건/미확정 사항을 기록했다.
  - 목적/근거: 발송 후 입력/버튼이 아래로 누적되는 길이를 줄인다. PROJECT_CONTEXT의 Firebase Phone Auth·프로필 공용 UI, ADR-0088~0090, WORKLOG와 실제 Page/인증 state/controller·SDK·fake/기존 회귀·로컬 공개 정책을 읽었다. schema.drawio/visibility_flow.drawio는 이전 calendars/calendar_shares 모델임을 확인했으며 이번 UI 작업에서 DB 변경 근거로 사용하지 않았다. 현행 owner_user_id/인증 계약을 유지했다.
  - 변경/Behavior change: 공용 PhoneVerificationSection에 기존 전화 입력과 Page 소유 OTP focus를 전달하고 발송 후 번호 요약/번호 변경·코드/인증·재발송으로 교체한다. 기본 폭은 코드/인증을 가로로, 내부280미만·큰 글자/서버 재확인은 세로로 표시한다. 편집만 열면 코드·세션 유지/복귀, 실제 번호 변경 시 기존 controller 초기화,6자리 전 확인 비활성, 재발송 시 코드 초기화, 서버 결과 복구 중 입력/재발송 차단을 적용했다. 이름 다음 키는 현재 표시된 입력으로 이동한다. Google 전송·저장 요약은 발송 전 유지하고 상세창에 목적·정책 링크를 둔다.
  - 디버깅/수정: debug-live로 didUpdateWidget 중단점에서 `idle -> code_sent; focus=false`를 직접 확인했다. 비동기 완료가 빠르면 중간 sending 프레임이 생략되므로 이전 상태가 sending인 경우에만 포커스하던 조건을 코드 단계 최초 진입으로 변경했다. 발송 처리에서 코드도 명시적으로 비운다. 추가 회귀의 발송/입력 뒤 rebuild 대기 누락과 실제 Stopwatch에 fake Flutter 시간만 진행하던 검증을 수정했으며 기존 elapsed 주입으로 재발송을 확인했다. 불필요한 재인증 오류가 편집 하단과 중복되던 새 UI 회귀는 인증 필요 시에만 inline 오류를 표시해 해소했다. 디버거 종료·이번 중단점 제거 완료.
  - 법률/약관: Firebase 공식 Phone Auth·개인정보 문서와 현행 개인정보 보호법 제17·22·28조의8을 확인했다. 일반 약관으로 완전 이동 가능/적법하다고 확정하지 않는다. 계약 이행에 필요한 국외 위탁·보관의 조건부 처리방침 공개 근거와 Google 자체 서비스 전반 이용의 근거를 구분해 실제 계약/필요 동의를 확정해야 한다. Authentication의 미국 처리·삭제 요청 전 보관·signOut과 사용자 삭제의 차이를 기록했다. 로컬 정책은 별도 Phone Auth 항목이 없고 공개 URL은 이번 웹 도구 접근 실패로 최신 게시본 일치 미검증이다. 공개 HTML/기존 연령·동의 본문은 변경하지 않았으며 상세창을 동의 수집으로 표시하지 않는다. PHONE_VERIFICATION_FLUTTER_PLAN12절·PRIVACY_REVIEW에 출처/후속 항목을 기록했다.
  - 파일/영향: 제품은 기존 profile_setup_page.dart·phone_verification_section.dart만 변경했다. 기존 profile_setup_page_test.dart에5회귀를 추가하고 기존 렌더러의 rebuild/스크롤·초기 캡처를 보완했다. 신규 제품 파일은 없다. 검토 PNG3개(초기/375px 인증/320px2배 글자)의 역할·의존성·사용 예를 모바일 계획12절에 기록했다. PROJECT_CONTEXT·ADR-0101·본 일지를 갱신했다. 인증 controller/autoDispose/API/DB/native/env·기존 route/접근권한/analytics는 유지한다.
  - 테스트: `flutter test --no-pub test/features/auth/application test/features/auth/data/repositories/phone_verification_repository_test.dart test/features/auth/data/services/firebase_phone_auth_service_test.dart test/features/auth/presentation test/features/auth/data/datasources/auth_remote_datasource_test.dart artifacts/phone_verification_2026-11-21/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --dart-define=PHONE_AUTH_RENDER_DIR=/private/tmp/shiftmate-phone-ui-20261122/render --reporter expanded` **127 pass**. 마지막 현재 입력 포커스 보완 뒤 화면 회귀 **35 pass**. 변경4 Dart파일 analyze **진단0**, 포맷·diff 공백 검사 통과. SDK 캐시 쓰기 제한은 검증 명령의 승인된 권한 확장으로 해소했다.
  - 렌더/검증: 가입/편집18조건+초기2조건 **PNG20개**,320/375/390·가로·태블릿·2배 글자·키보드·오류/완료를 확인했다. 기본 크기에서 발송 전후 인증 영역 높이가 증가하지 않는 회귀와6자리/autofill·자동 포커스·번호 편집/복귀·재발송·동일 서버 인증 결과 복구를 검증했다. 초기·375/320 인증·큰 글자·키보드 PNG를 직접 열어 확인했다. Flutter 전용 스킬 검색은2회 일치0건으로 기존 Cupertino 구현과 스킬 일반 폼/접근성 원칙을 적용했다. 로그와 전체 PNG는 `/private/tmp/shiftmate-phone-ui-20261122/`에 보존했다.
  - 롤백: 이번 인증 widget/호출부·회귀/렌더러·검토 PNG·문서 변경분만 복원한다. 작업 시작 widget은 위 임시 폴더의 phone_verification_section.before.dart다. 기존 미커밋 작업과 인증 필수 정책은 보존한다.
  - 한계/다음: 실문자·실기기 키보드/VoiceOver·원격 게시·개별 계약의 법적 적합성 검증은 미실행이다. 실제 수신자/이전·보관/삭제/적용 근거를 확정하고 정책2·3·6·7항 및 필요한 사전 동의/입증 기록을 보완한 뒤 안내의 추가 이동을 재평가한다.

## 2026-11-22 홈 소형 위젯 정보 배치 개선

- [DONE] (iOS/UI) 오늘/내일 소형의 여백과 정보 밀도를 근무 식별·시간·후속 근무의3구역으로 개선했다.
  - 목적/근거: 사용자 피드백에 따라 큰 코드/단일 시간/후속 코드 사이의 빈 공간을 유용한 정보에 배분한다. PROJECT_CONTEXT·ADR-0098/0099·IOS_WIDGET_GUIDE와 실제 SwiftUI/WidgetShift의 날짜/시간 계약을 직접 읽었다.
  - 변경/Behavior change: 헤더 아래에 사용자 색의 옅은 코드 배지와 근무명,18pt 시작·종료2열, 하단 후속일 코드/시간 또는 시간 없는 타입의 이름을 배치했다. 기존 time_label 검증을 통과한 HH:mm만 나누고 야간은 종료 레이블에 익일을 유지한다. 코드 배경은 light0.12/dark0.18, 단색에서는 윤곽선이다. 큰 글자는 compact, 긴 코드는 줄 나눔/줄임, 후속 시간이 가로로 안 들어가면 코드 우선/전체 VoiceOver로 제공한다. iOS15는 같은 정보의 단일 Text 대체 표시다. 미등록/시간 없음/미조회 상태와 기준 시각 제거를 유지한다.
  - 영향/파일: 제품 변경은 기존 ShiftMateWidget.swift의 소형 표시·전용 글자 metric뿐이다. 기존 WidgetRenderTests에 소형 좁은 크기+큰 글자와 실제 후속 근무 시간/큰 글자 fixture를 보강하고 기존 검토판3개를 갱신했다. 새 home-comparison.png는 직전 오늘/내일 소형과의 실제 렌더 비교이며 역할/의존성/사용 예를 IOS_WIDGET_GUIDE에 추가했다. PROJECT_CONTEXT·ADR-0100을 갱신했다. 중형/잠금/갤러리·provider는 시작 소스와 동일함을 직접 비교했다. Dart/공유 JSON·동기화/날짜/캐시·API/DB·서명/종류는 바꾸지 않았다.
  - 검증/결과: 기존 재현 도구의9조합×14조건+소형/직사각형 좁은 폭/큰 글자4조건+소형 후속 근무/큰 글자4조건 **PNG134개, TEST SUCCEEDED**. 오늘/내일·시간 있는 후속 근무·야간/시간 없음·큰 글자·긴 코드·140×140+최대 글자·다크/단색·미등록을 직접 열어 확인했다. 좁은 최대 글자에서 익일 종료 라벨이 잘리던 것을 보조 라벨 최소 축소 비율0.65로 조정한 최종 렌더를 재검증했다. unsigned simulator extension **BUILD SUCCEEDED**, 컴파일 warning/error0, diff 공백 검사 통과. 코드 배지의 검정/흰색 극단 사용자 색을 합성한 전경 대비는 light4.93:1/dark6.47:1로4.5이상이다. 데이터 계약/타임라인을 바꾸지 않아 Foundation/Dart 전체 회귀는 반복하지 않았다.
  - 도구/한계: 기존 render_widgets.py 명령의 출력 경로를 `/private/tmp/shiftmate-widget-home-20261122`로 지정했다. 해당 폴더에 build.log/render.log·PNG134개·시작 소스/임시 AppKit 합성기를 보존했다. 저장소의 비교/전체/예외 상태 검토판도 직접 확인했다. 독립 SwiftUI 렌더로 실제 WidgetKit 합성/배경 제거·VoiceOver 조작/기기·서명 인수를 대체하지 않는다. 테스트 Simulator는 작업 전 종료 상태로 복구했다.
  - 롤백: 이번 소형/렌더러·검토 자료/문서 변경분만 복원한다. 시작 소스는 위 임시 폴더의 ShiftMateWidget.before.swift다. 기존 미커밋 작업을 보존한다.

## 2026-11-22 위젯 문구 제거·잠금 시간 확대

- [DONE] (iOS/UI) 사용자 요청으로2주 행 이름과 오늘/내일 소형의 기준 시각을 제거하고 잠금 직사각형 시간을 크게 재배치했다.
  - 목적/변경: 중형의 이번 주/다음 주 라벨·30pt 예약 열/요일 빈 열을 없애7열이 전체 너비를 쓰게 했다. 소형의 updated_label 호출/표시를 제거했다. 잠금 직사각형은 `오늘 N · 나이트` 요약과 큰 `23:00–07:00`의2줄이며 시간은 caption12pt에서 기본22pt(ScaledMetric·상한26pt, 최소 축소0.85)로 확대하고 배치 우선순위를 높였다. 긴 요약은 줄이고 시간/VoiceOver 전체 원문은 유지한다.
  - 영향/문서: 제품 변경은 기존 ShiftMateWidget.swift만이다. 기존 렌더러에150×64의 좁은 잠금 슬롯과 좁은 폭+최대 글자2조건을 반영하고 기존 검토판3개를 최신 렌더로 갱신했다. 새 영구 파일은 없다. PROJECT_CONTEXT·IOS_WIDGET_GUIDE의 표시/신선도 설명과 ADR-0099를 갱신했다. 데이터/타임라인/캐시/Flutter/API/DB·kind/family·나머지 잠금 표시/서명은 유지한다.
  - 검증/결과: 기존 재현 도구의9조합×14조건+잠금 좁은 폭/큰 글자2조건 **PNG128개, TEST SUCCEEDED**. 오늘/내일의 기본·큰 글자·150×64·150×64+최대 글자·긴 코드/단색, 소형/중형의 문구 제거를 실제 PNG로 직접 확인했다. 최종 unsigned simulator extension **BUILD SUCCEEDED**, 컴파일 warning/error0·diff 공백 검사 통과. 표시 제거와 provider 진입부 동일도 확인했다. Foundation/Dart 계약을 바꾸지 않아 관련 전체 회귀는 반복하지 않았다.
  - 도구/한계: 명령은 앞선 디자인 작업과 같은 render_widgets.py를 사용하고 출력 경로만 `/private/tmp/shiftmate-widget-refine-20261122`로 지정했다. build.log/render.log·PNG128개·시작 소스 백업·AppKit 검토판 합성기는 해당 임시 폴더에 보존했다. 독립 SwiftUI 렌더로 실제 WidgetKit 합성·잠금 개인정보 가림/VoiceOver·실기기 인수를 대체하지 않는다. 테스트 Simulator는 작업 전 종료 상태로 복구했다.
  - 롤백: 이번 표시/렌더러·검토판/문서 변경분만 복원한다. 시작 소스는 위 임시 폴더의 ShiftMateWidget.before.swift이며 기존 미커밋 작업은 보존한다.

## 2026-11-22 위젯 디자인 검토·개선

- [DONE] (iOS/UI) widgets·UI/UX 스킬로 오늘/내일·2주/잠금 위젯을 검토하고 정보 위계·가독성·색조 대응을 개선했다.
  - 목적: 한눈에 대상일·근무 코드·시간을 읽고2주 근무에서 오늘을 쉽게 찾는다.
  - 확인 근거: PROJECT_CONTEXT의 위젯 절·IOS_WIDGET_GUIDE·ADR-0094~0097·Swift/Dart 계약/표시·동기화 코드를 직접 읽고 기존/동일 예시의 실제 SwiftUI 렌더를 비교했다. AGENTS의 현행 DDL과 drawio의 구형 calendars 구조 차이를 확인했으며 새 DB/개인 일정 요구를 유추하지 않았다. widgets의 디자인/레이아웃/단색/잠금/실행모델/검증 지침과 UI/UX의 색 외 식별·SwiftUI Dynamic Type 결과, Apple HIG/공식 accented 문서를 대조했다.
  - 변경/Behavior change: 홈 앱 이름을 대상일/2주 근무 제목으로 대체하고 소형은 코드·시간/후속일/작은 기준 시각 순서로 정리했다. 중형 오늘 날짜를 캡슐로 강조하고 연도 경계 범위에 연도를 표시한다. 잠금 직사각형은3줄, 미등록은 명확한 단일 문구다. iOS16이상 모드 경계를 두어 accented/vibrant에서는 근무색 배지를 비우고 오늘 윤곽/굵기·accent group을 사용한다. 큰 글자/긴 코드는 이름이 일부만 남지 않게 대체 레이아웃을 사용하고 중형은 지나친 축소 대신 줄인다. 전체 원문·후속일 이름/시간을 VoiceOver로 제공한다. 소형 내부 간격을 조정해 기본 크기에서40pt(동적 확대) 코드가 우선 배치되도록 확인했다. 기존2kind/오늘·내일·2주2행/잠금 익일 생략·모든 family·privacySensitive/removable background/타임라인/공유 JSON·Flutter/API/DB/서명은 보존했다.
  - 파일/문서: 기존 `ios/ShiftMateWidget/ShiftMateWidget.swift`만 제품 코드로 수정하고 #Preview6개를 추가했다. `artifacts/widget_redesign_2026-11-22/`의 render_widgets.py·WidgetRenderTests.swift·comparison/overview/edge-cases PNG3개의 역할/의존성/사용 예와 처음부터 설계할 역할별 요구를 IOS_WIDGET_GUIDE에 기록하고 PROJECT_CONTEXT·ADR-0098을 갱신했다. 이미지의 예시 기준일은2026-11-20이며 실제 계정 정보가 아니다.
  - 렌더/결과: 저장소의 재현 도구로 최종 제품 표시의 오늘5+내일4조합×14조건(라이트/다크·최대 시스템 글자·긴 코드/조합·미등록/시간 없음·로그아웃/만료·다음 주 미조회·연말·좁은 크기·accented/vibrant) **PNG126개, TEST SUCCEEDED**. 전후/전체/제약 검토판을 직접 열어 확인했다. 첫 렌더의 긴 코드+큰 글자에서 이름 일부가 남는 문제를 대체 코드행으로 수정했고, 미등록의 중복 문구를 없앤 최종 렌더를 다시 확인했다. 읽기 전용 WidgetFamily만 임시 표시 사본의 생성 인자로 바꾸며 View/데이터 로직은 실제 제품 코드다.
  - 검증: Foundation 제품 모델/기존 Dart fixture의 기존 회귀 **51 checks pass**. 최종 `xcodebuild -project ios/Runner.xcodeproj -target ShiftMateWidget -configuration Debug -sdk iphonesimulator ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO SYMROOT=/private/tmp/shiftmate-widget-design-20261122/build OBJROOT=/private/tmp/shiftmate-widget-design-20261122/obj build` **BUILD SUCCEEDED**, 제품/렌더 소스 compiler warning/error0, Preview6개의 iOS15 deployment compatibility 컴파일 통과. fullColor 토큰의 전경/보조 글자 및 검정/흰색 극단 근무색 배경까지 대비6경우는 **최저6.49:1**(4.5이상)이다. Python 렌더 도구 AST와 diff 공백 검사 통과. Dart/공유 계약 변경이 없어 Flutter 전체 회귀는 반복하지 않았다.
  - 재현/도구: `python3 artifacts/widget_redesign_2026-11-22/render_widgets.py --device 524FEE5D-56C5-41F0-AA12-C8DA996B1C05 --output /private/tmp/shiftmate-widget-design-final-20261122 --ruby /opt/homebrew/opt/ruby/bin/ruby --gem-home /opt/homebrew/Cellar/cocoapods/1.16.2/libexec`. 최종 render.log/renders와 xctest 결과는 해당 폴더, extension build.log/시작 소스 백업·AppKit 검토판 합성기는 `/private/tmp/shiftmate-widget-design-20261122/`에 있다. 기존 CocoaPods의 xcodeproj gem을 사용했고 새 패키지는 설치하지 않았다. 기본 sandbox에서 CoreSimulator 접근이 차단되어 관련 검증에만 승인된 확장 권한을 사용했다. 기본 Ruby에서 xcodeproj를 못 찾은 도구 오류는 기존 gem 경로로 해결했다. Pillow가 없어 PNG 배치는 macOS AppKit으로 생성했다.
  - 한계/다음: 독립 ImageRenderer의 모드별 표시 확인이며 실제 WidgetKit의 재착색/유리·StandBy 배경 제거·privacy/placeholder 합성·VoiceOver 조작·iOS15/16 실제 런타임·서명/실기기/배포 인수는 수행하지 않았다. 단순 redacted/배경 제거 모사 이미지는 유효한 인수로 세지 않았다. OS 자정/즉시 갱신은 기존처럼 보장하지 않는다. 테스트용 Simulator는 검증 후 원래 종료 상태로 복구했다.
  - 롤백: 이번 표시·검토 산출물/문서 추가분만 복원한다. 시작 시 위젯 소스 백업은 위 임시 폴더의 ShiftMateWidget.before.swift다. 기존 미커밋 인증/UI/위젯 작업을 보존한다.

## 2026-11-22 중형 위젯 이번 주·다음 주 2행 표시

- [DONE] (iOS/UI) 중형 위젯을 이번 주/다음 주 각7일의 두 행으로 바꾸고 중형의 갱신 시각을 제거했다.
  - 목적: 같은 중형 크기에서 앞으로2주의 근무를 확인하고 하단 갱신 문구 대신 달력 공간을 확보한다.
  - 변경/영향: 기존 ShiftMateWidget.swift의 중형을 공통 월~일 요일 헤더·이번 주/다음 주 각7일의 두 행·14일 날짜 범위로 배치했다. 날짜/사용자 근무 코드/색상·오늘 강조와 VoiceOver 전체 날짜/근무/시간을 유지한다. 중형의 updatedLabel 호출만 제거해 소형 갱신 시각은 유지한다. ShiftWidgetData.weekDates의 기본0인 week_offset에1을 전달해 다음 주를 계산한다. 기존 gallery 설명도2주 표시로 갱신했다. 소형/잠금·공유 JSON/갱신 동작·kind/서명/API/패키지는 보존했다.
  - 파일/문서: 기존 Swift 제품2파일/Swift 회귀와 PROJECT_CONTEXT·IOS_WIDGET_GUIDE·ADR-0097을 갱신했다. 새 영구 파일은 없다.
  - 검증: 제품 Foundation 모델과 기존 Dart fixture/Swift 회귀를 swiftc로 함께 실행해 **51 checks pass**(신규8: 다음 주 월/일·14일 중복 없음/연속·연말·미조회·DST23/25시간). SwiftUI ImageRenderer/XCTest로338x158 기본·300x140 축소 중형의 라이트/다크/큰 글자/긴 코드/미등록/다음 주 미조회/연말/좁은 폭/로그아웃/만료 **PNG10개**를 생성해 **TEST SUCCEEDED**. 정상/다크/큰 글자/좁은 폭/연말·월 경계/미조회 대표 이미지를 직접 확인했고 두 행/현재 날짜 강조·중형 갱신 문구 제거를 확인했다.
  - 빌드/분석: 기존 Runner workspace/scheme·arm64 simulator·unsigned 통합 빌드 **BUILD SUCCEEDED**, diff 공백 검사 통과. Flutter/Dart 소스·공유 계약은 변경하지 않아 해당 전체 회귀/분석은 반복하지 않았다. 최초 임시 렌더러의 읽기 전용 accessibilityReduceMotion 직접 주입이 컴파일 오류여서 도구에서 제거했다. 정적 표시로 애니메이션은 없으며 실제 OS 동작 줄이기 인수를 수행한 것으로 기록하지 않는다.
  - 도구/명령: `/private/tmp/shiftmate-widget-two-weeks-20261122/render_project.rb`는 기존 xcodeproj gem 기반 임시 프로젝트 생성기 사본, WidgetRenderTests.swift는 실제 Foundation/SwiftUI 표시 코드와 ImageRenderer/XCTest에 의존한다. 표시 사본은 widget 설정/bundle 진입부 제외·읽기 전용 family 인자 주입만 수행했다. `xcodebuild -project <해당폴더>/WidgetPreview.xcodeproj -scheme WidgetPreview -destination id=524FEE5D-56C5-41F0-AA12-C8DA996B1C05 -derivedDataPath <해당폴더>/render-build test`로 renders/*.png/render.log를 만든다. 앱은 앞선 작업과 같은 workspace/Runner/Debug/iphonesimulator·ARCHS=arm64/ONLY_ACTIVE_ARCH=YES/CODE_SIGNING_ALLOWED=NO 명령으로 확인했고 app-build.log와 swift-tests.log도 같은 폴더에 보관했다.
  - 한계/다음: 독립 SwiftUI 렌더이며 실제 WidgetKit host/기기·큰 글자/VoiceOver 조작·OS 갱신·서명/배포 인수는 수행하지 않았다. 테스트 시뮬레이터는 검증 후 원래 종료 상태로 복구한다. 실제 기기에서 중형 두 행의 가독성을 확인한다.
  - 롤백: 이번 중형 표시·날짜 helper/관련 회귀·문서 추가분만 복원한다. 기존 미커밋 변경은 보존한다.

## 2026-11-22 오늘·내일 위젯 분리와 잠금 시간 간소화

- [DONE] (iOS/FE) 방안1의 오늘/내일 위젯을 별도 항목으로 제공하고 잠금화면의 `익일` 표시를 제거했다.
  - 목적: 잠금화면의 제한된 공간에서 사용자 근무 코드·시간을 간결하게 읽고 내일 근무를 바로 선택한다.
  - 변경/영향: 기존 ShiftMateShiftWidget kind/5family를 `오늘 근무`로 유지하고 `내일 근무` kind의 소형/잠금 원형·직사각형·한 줄4family를 같은 extension의 WidgetBundle에 추가했다. 주간은 기존 오늘 항목의 중형을 유지한다. ShiftWidgetDay/DayContent가 같은 스냅샷의 현지 날짜를0/1일 이동하고 내일 소형 보조행은 모레를 표시한다. 잠금 시간과 VoiceOver는 익일 문구를 생략하고 홈 시간은 유지한다. 공유 JSON/API/타임라인·App Group/서명/extension ID·패키지/lock/앱 버전은 바꾸지 않았다.
  - 파일/문서: 기존 ShiftWidgetData.swift의 날짜/시간 표시 모델, ShiftMateWidget.swift의 provider/뷰/bundle, home_widget_store.dart의 두 kind reload와 기존 Dart/Swift 회귀를 수정했다. 저장/삭제 뒤 양쪽 갱신을 시도하며 먼저 실패한 kind가 있어도 다른 요청을 실행한다. PROJECT_CONTEXT·IOS_WIDGET_GUIDE와 ADR-0096을 갱신했다. 새 영구 파일은 없다.
  - 자동 검증: `flutter test --no-pub test/features/home_widget test/features/auth/presentation/providers/auth_provider_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter expanded` **33 pass**(위젯14·인증19). 새 실제 MethodChannel 회귀는 양쪽 kind/null 삭제·정상 갱신과 첫 kind의 false/PlatformException 실패 뒤에도 다른 kind 갱신을 검증했다. 변경 Dart2파일 분석 진단0·포맷 변경0·diff 공백 검사 통과.
  - Swift 검증: 기존 실제 Dart fixture와 제품 Foundation 모델/기존 Swift 회귀를 swiftc로 컴파일/실행해 **43 checks pass**. 오늘/내일의 다른 코드 선택, 잠금/홈 익일 분리, 모레·자정·UTC와 소유자 현지 날짜 차이·연말·DST23/25시간·대상일의 캐시 끝/미등록/로그아웃·OFF를 확인했다. Swift/Dart의2kind ID/App Group/키 일치·유일한 @main WidgetBundle·기존family 보존도 검사했다.
  - 렌더/도구: `/private/tmp/shiftmate-widget-day-20261122/render_project.rb`는 앞선 xcodeproj gem 기반 임시 프로젝트 생성기의 사본, WidgetRenderTests.swift는 제품 Foundation 모델/표시 코드와 SwiftUI ImageRenderer/XCTest에 의존한다. 임시 표시 사본은 widget 설정/bundle 진입부를 제외하고 읽기 전용 family를 테스트 인자로 주입했다. `xcodebuild -project <해당폴더>/WidgetPreview.xcodeproj -scheme WidgetPreview -destination id=524FEE5D-56C5-41F0-AA12-C8DA996B1C05 -derivedDataPath <해당폴더>/render-build test` **TEST SUCCEEDED**. 오늘5형식/내일4형식×라이트/다크/큰 글자/긴 코드/미등록/로그아웃 **PNG54개**를 renders/에 생성하고 대표 오늘/내일 소형·모레·잠금 직사각형·한 줄·큰 글자 원형/소형을 직접 확인했다.
  - 통합 빌드: 기존 workspace/scheme·arm64 simulator·unsigned 명령(`xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination id=524FEE5D-56C5-41F0-AA12-C8DA996B1C05 ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build`)으로 최종 **BUILD SUCCEEDED**. 같은 임시 폴더에 app-build.log/render.log/flutter-tests.log/analyze.log/swift-tests.log를 보관했다. 테스트용 시뮬레이터는 검증 후 원래 종료 상태로 복구한다.
  - 한계/다음: 독립 SwiftUI 렌더이며 실제 WidgetKit 갤러리2항목·설치 위젯 유지/잠금화면 개인정보 가림·기기 자정/갱신 예산·실서버/실계정/서명·배포 인수는 수행하지 않았다. Apple 포털/App Group/profile 준비와 실제 기기에서 두 항목 추가·로그아웃 정리는 기존 설정 가이드를 따라 확인한다.
  - 롤백: 이번 날짜 선택/위젯 bundle·kind·잠금 시간/갱신 연결·관련 회귀와 문서 변경분만 되돌린다. 기존 미커밋 변경은 보존한다.

## 2026-11-21 잠금화면 시계 위 한 줄 위젯 추가

- [DONE] (iOS/UI) accessoryInline을 기존 근무표 위젯에 추가했다.
  - 목적: 잠금화면 시계 위 한 줄에서 오늘 근무 코드·시간을 확인한다.
  - 변경/영향: 기존 SwiftUI family 등록·표시 분기만 확장하고 근무 없음/미동기화·시간 없는 타입·익일 표시를 유지한다. 기존 공유 JSON·타임라인·privacySensitive·로그아웃 정리를 재사용한다.
  - 변경/결과: 기존 ShiftMateWidget.swift의 iOS16이상 family에 accessoryInline과 단일 Text 분기를 추가했다. `오늘 N · 23:00 - 익일 07:00`, `오늘 OFF · 휴무`, `오늘 등록된 근무 없음`, `ShiftMate · 앱에서 동기화`를 상태에 맞게 표시하고 전체 근무명/코드/시간의 VoiceOver 레이블을 제공한다. 새 영구 파일/패키지·Flutter/API/DB·JSON/타임라인·서명/App Group 변경은 없다. PROJECT_CONTEXT·IOS_WIDGET_GUIDE를5종으로 갱신하고 ADR-0095에 표시 정책을 기록했다.
  - 검증: 실제 SwiftUI 표시 코드의 한 줄7상태(데이/익일 나이트/휴무/미등록/로그아웃/만료/긴 코드)×4조건(라이트/다크/큰 글자/좁은 폭160pt)의 PNG28개를 생성해 정상·야간·휴무/다크·미동기화/큰 글자·좁은 폭·미등록 대표 이미지를 직접 확인했다. 기본 폭300pt/높이32pt의 독립 렌더이며 시스템 가용 폭 부족 시 한 줄 끝을 줄인다. 렌더 XCTest **TEST SUCCEEDED**, 최종 Runner+ShiftMateWidget arm64 simulator 통합 **BUILD SUCCEEDED**, diff 공백 검사 통과. 기존 Flutter/공유 JSON/타임라인 소스는 변경하지 않아 해당 전체 회귀를 반복하지 않았다.
  - 도구/실행: `/private/tmp/shiftmate-inline-20261121/render_project.rb`는 앞선 xcodeproj gem 기반 임시 프로젝트 생성기의 사본, `WidgetRenderTests.swift`는 SwiftUI ImageRenderer/XCTest·실제 제품 Foundation/표시 코드에 의존하는 상태별 렌더러다. 표시 코드 사본은 앞선 검증처럼 @main 제외·읽기 전용 family 인자 주입만 수행했다. `xcodebuild -project <해당폴더>/WidgetPreview.xcodeproj -scheme WidgetPreview -destination id=524FEE5D-56C5-41F0-AA12-C8DA996B1C05 -derivedDataPath <해당폴더>/render-build test`로 renders/*.png와 render.log를 만든다. 앱 빌드는 위 초기 작업의 동일 workspace/scheme/arm64/unsigned 명령으로 실행했고 app-build.log에 보관했다. 기존 미커밋 변경은 보존한다.
  - 한계/다음: 실제 잠금화면 시계 위의 OS 날짜/레이아웃·개인정보 가림·탭/서명 인수는 미수행이다. 기존 App Group/서명 준비와 iOS16이상 잠금화면 사용자화에서 시계 위 날짜 영역의 ShiftMate 선택을 확인한다. 독립 SwiftUI 렌더를 실제 WidgetKit host 인수로 간주하지 않는다.
  - 롤백: 이번 inline 분기/뷰·family 항목과 문서 추가분만 복구한다. 기존4종/미커밋 변경은 보존한다.

## 2026-11-21 iPhone 홈·잠금 근무표 위젯4종

- [DONE] (FE/iOS) 홈 소형(오늘·내일)/중형(주간7일), 잠금 원형(오늘 코드)/직사각형(오늘 근무·시간)4종과 동기화/세션 정리를 구현했다.
  - 목적/범위: 기존 본인 근무 조회와 home_widget·App Groups·WidgetKit/SwiftUI를 연결한다. 날짜 전환 timeline, 앱 실행/복귀·근무 저장/삭제·근무 타입 수정 후 동기화, 로그아웃/탈퇴 정리를 포함한다. 월간·친구 근무·서버 백그라운드 동기화는 후속 범위다.
  - 변경/영향: features/home_widget의 동기화·JSON·home_widget 저장소3파일, WidgetKit/SwiftUI·Foundation 모델/extension 설정·privacy manifest·Widget.xcconfig, 기존 main/auth·근무/타입 서비스의 최소 연결과 회귀를 추가했다. Runner dependency/embedding·양측 App Group/공유 UserDefaults privacy를 연결했다. home_widget0.10.0만 새 의존성으로 추가했고 기존 Flutter/Firebase/OAuth/버전·서버/API/DB/env를 보존했다. 정본 IOS_WIDGET_GUIDE·PROJECT_CONTEXT·ADR-0094를 갱신했다.
  - 동작/결과: 유효 사용자 IANA timezone(없으면 기기값)의 월요일부터42일 확정 근무만 저장한다. 임시 draft/개인 일정/메모/JWT는 공유하지 않는다. 계정/요청 revision·직렬 저장 큐가 늦은 응답/저장 중 로그아웃을 막는다. 동일 계정 오프라인은 마지막 캐시를 유지하고 계정 전환/로그아웃/탈퇴 세션 종료/조회401·403은 삭제한다. native 자정·만료 entry, 미등록/미동기화 구분, 익일 시간·밝기 대비·긴 코드 줄 나눔·글자 확대 최대xxxLarge/VoiceOver 전체 레이블·privacySensitive·모든 family removable background를 적용했다. 앱 열기는 기존 인증 게이트를 따른다.
  - 자동 검증: `WIDGET_CONTRACT_OUTPUT=/private/tmp/shiftmate-widget-20261121/contract.json flutter test --no-pub test/features/home_widget/widget_sync_coordinator_test.dart test/features/auth/presentation/providers/auth_provider_test.dart test/features/calendar test/core/navigation/main_tab_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter expanded` **330 pass**. 이후 실제 서비스6개 mutation/실패 갱신 연결·로그아웃/탈퇴5경로를 추가한 최종 위젯/인증 subset **31 pass**(위젯12·인증19). 결과는 regression.log/final-tests.log다. 실제 Dart JSON과 제품 Swift Foundation 모델을 `swiftc`로 함께 컴파일/실행해 자정/기한·월요일·잘못된 캐시/시간대·익일·DST23/25시간 **21 checks pass**를 확인했다. 정확한 명령은 IOS_WIDGET_GUIDE를 따른다.
  - 분석/정합성: 수정 Dart9파일 포맷 변경0, 동일9파일 분석 진단0(final-analyze.log), plist/entitlements/manifest4개 lint·diff 공백 검사 통과. Xcode 프로젝트 수정 전 `/private/tmp/shiftmate-widget-20261121/before.pbxproj`와 비교해 기존 타깃의 build configuration(새 pod의 explicit modules 설정 외)·스크립트 보존, extension dependency/Thin Binary 전 embedding·양측 privacy resource를 검증했다. pub add는 신규1개만 보고했고 기존 미커밋 인증/UI는 유지한다.
  - native 빌드: 확장 standalone simulator SDK 빌드 성공. `flutter build ios --simulator --debug --no-pub --dart-define-from-file=.env`는 기존 Flutter3.38의 복수 ARCHS 판정에서 실패했다(산출 fat binary에는 두 아키텍처가 실제 존재). 제품 소스를 우회 수정하지 않고 `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination id=524FEE5D-56C5-41F0-AA12-C8DA996B1C05 ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build`로 최종 **BUILD SUCCEEDED**를 확인했다(app-arm64-build.log). Runner.app/PlugIns의 실제 extension·양측 privacy manifest/1C8F.1·동일1.0.0(6)·extension point도 검사했다. 기존 vendor의 deprecated/native 경고는 위젯 소스 경고로 취급하지 않는다.
  - 렌더/도구: `/private/tmp/shiftmate-widget-20261121/`의 render_project.rb는 기존 xcodeproj gem으로 독립 iOS XCTest 프로젝트를 만든다. WidgetRenderTests.swift는 SwiftUI ImageRenderer/XCTest·제품 Foundation 모델/표시 코드에 의존한다. 임시 표시 코드 사본은 `@main` 진입점만 제외하고 읽기 전용 widgetFamily를 테스트 인자로 주입한다. `xcodebuild -project <해당폴더>/WidgetPreview.xcodeproj -scheme WidgetPreview -destination id=524FEE5D-56C5-41F0-AA12-C8DA996B1C05 -derivedDataPath <해당폴더>/render-build test` 최종 **TEST SUCCEEDED**이며 158x158/338x158/76x76/172x76의4종×라이트/다크/큰글자/빈/긴코드/빈+큰글자/긴코드+큰글자 **PNG28개**를 renders/에 생성했다. 대표 이미지를 직접 읽어 큰 글자 넘침·긴 코드 잘림·빈 안내를 보완한 뒤 재검증했다. 임시 add_extension.rb는 Xcode target 연결에 사용한1회성 도구이며 저장소 신규 도구로 추가하지 않았다.
  - 한계/다음: 렌더는 OS WidgetKit host 자체가 아닌 독립 SwiftUI 이미지다. iOS15/16 실제 런타임·lock chrome/개인정보 가림·앱 열기·실제 OS 자정/갱신 예산·실서버/실계정/실기기 인수와 Apple Developer App Group/App ID/profile 등록·서명·업로드는 수행하지 않았다. OS의 정확한 자정/즉시 갱신은 보장하지 않으며6주 이후에는 앱 열기 안내를 표시한다. 실기기 설정은 IOS_WIDGET_GUIDE의 Xcode·서명 절을 따른다.
  - 롤백: 이번 위젯 소스·연결부·패키지/lock·native 추가분과 문서만 복구하며 기존 작업을 보존한다.

- [DONE] (FE/위젯 조사) 공유 링크 본문 대신 사용자가 붙여 준 대화로 요구사항을 확인했다.
  - 목적: 공유 대화 `https://chatgpt.com/share/6b01a9cc-a1d8-83ee-8929-84066234ddf7`를 기준으로 위젯 작업을 진행한다.
  - 초기 접근 확인: 웹 조회는 cache miss, 인앱 브라우저는 연결 host 사용 불가다. 공개 URL 직접 GET은 HTTP200이지만 대화 본문 없이 `Check out this chat` 링크와 메타데이터만 반환했다. 사용자에게 대화 요구사항 전달을 요청했다. 초기 조사에서는 플랫폼·크기·표시 정보·탭/갱신 동작을 확인하지 못했으며 후속 본문 제공으로 위 구현 범위를 확정했다.
  - 범위: 요구사항 확인과 기존 캘린더/네이티브 구조 조사. 기존 미커밋 변경을 보존하며 요구사항 확인 전 제품 코드/의존성/플랫폼 설정은 변경하지 않는다.
  - 조사 결과: AGENTS의 사용자당 캘린더1개 DDL과 drawio2개를 읽었다. drawio에는 이전 calendars/calendar_shares 구조가 남아 있어 현행 DDL과 동일하다고 간주하지 않았다. 기존 CalendarService의 인증 GET /calendar/range와 autoDispose calendarRangeProvider를 확인했다. pubspec에 홈 위젯 패키지, Runner entitlement에 App Groups, Android main manifest에 위젯 receiver는 없다. AppDelegate는 FlutterImplicitEngineDelegate를 사용한다. PROJECT_CONTEXT에 조사 상태를 추가했다.
  - 테스트: 문서·코드 정적 확인만 수행하며 구현/실기기 검증 완료로 간주하지 않는다.
  - 롤백: 이번 작업 기록과 관련 PROJECT_CONTEXT 추가분만 제거한다.
  - 결과: 사용자 제공 본문으로4종을 확정해 위 구현·검증·ADR-0094 기록까지 완료했다.

## 2026-11-21 공유 해제 시 빈 일정 카드 외곽 유지

- [DONE] (FE/UI) 공유 거절에서도 하단 네모 카드의 배경·테두리·크기와 날짜 헤더를 유지하고 내용만 빈칸으로 표시했다.
  - 목적/변경: 직전 빈 SizedBox로 카드 전체가 사라진 표시를 수정한다. 공용 CalendarScheduleCard의 선택적 내용 숨김으로 날짜 헤더를 유지하고 일정 수·본문·빈 일정 안내·footer는 숨긴다. 기본 동작은 유지한다.
  - 영향/테스트: 친구 페이지·공용 카드 옵션·기존 친구 화면 회귀. 공유 전후 카드 외곽/크기 유지와 빈 내용, 재조회 복구·일반 캘린더 회귀·분석/포맷을 확인한다. 권한/API/DB·range 상태 정책은 변경하지 않는다.
  - 구현/결과: 기존 CalendarScheduleCard에 기본 false인 is_content_hidden 옵션을 추가하고 FriendCalendarPage는 카드 전체를 항상 생성해 거절 상태만 전달한다. 기존 화면 회귀에 카드 BoxDecoration/날짜 헤더/안내·일정 수 숨김과 거절 전후 카드 Rect 동일 검증을 보강했다. PROJECT_CONTEXT와 ADR-0093의 빈칸 의미를 현재 동작으로 명확히 했다. 신규 영구 파일은 없다.
  - 검증: `flutter test --no-pub test/features/friend/presentation/pages/friend_calendar_page_test.dart test/features/calendar/presentation/widgets/calendar_schedule_header_test.dart test/features/calendar/presentation/pages/calendar_page_test.dart test/features/group/presentation/pages/group_calendar_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter expanded` **100 pass**, 수정 Dart3파일 analyze 진단0·포맷/공백 검사 통과.
  - 렌더/한계: `/private/tmp/shiftmate-friend-calendar-20261121/card_render_test.dart`는 앞선 임시 렌더러와 같은 Flutter/모의 Dio403·FontLoader·RepaintBoundary/dart:io/ui를 사용한다. `flutter test --no-pub <해당경로> --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로375x667·작은 화면 글자2배·가로 글자2배·태블릿의 card_*.png4개를 생성해 렌더1 pass, 대표 화면에서 카드/날짜와 빈 본문을 직접 확인했다. card-regression.log/card-render.log에 결과를 보관했다. 실기기/배포는 미수행이다.
  - 롤백: 이번 카드 옵션·친구 페이지·테스트/문서 추가분만 복구한다. 기존 인증/탭 변경은 보존한다.

## 2026-11-21 하단 바 위치 8px 하향

- [DONE] (FE/UI) 사용자 요청으로 플로팅 탭의 추가 하단8px 여백을 제거했다.
  - 목적/변경: 하단 바를8px 내려 화면 아래에 가깝게 배치한다. SafeArea의 시스템 여백/최소8px는 유지하고 본문 예약 높이는 기존 측정 흐름으로 갱신한다.
  - 범위: main_tab_page.dart의 바 외부 패딩, 기존 위치 회귀 기대값, 정본 문서. 다른 미커밋 변경은 보존한다.
  - 테스트/결과: 기존 main_tab_page_test.dart **22 pass**(탭 탐색·전체 화면 스와이프·바/본문 경계·안전영역·큰 글자/가로/다크), 변경2파일 analyze **진단0**, 포맷 **변경0**, diff 공백 검사 통과. `/private/tmp/shiftmate-nav-lower-20261121/`에4조건 PNG12개를 생성하고375×667의 친구 화면을 직접 확인했다. 바 하단은 기존625px에서633px로8px 내려가고 화면 끝까지34px 안전영역을 유지한다. 로그는 `/private/tmp/shiftmate-nav-lower-{test,analyze}.log`다. 실기기 인수는 수행하지 않았다.
  - 롤백: 바 외부 패딩의 하단값을0→8로 복구하고 해당 기대값/문서만 되돌린다.


## 2026-11-21 친구 공유 해제 화면을 빈 일정 영역으로 단순화

- [DONE] (FE/UI) 사용자 피드백에 따라 공유 거절 시 잠금 안내/재확인 버튼을 제거하고 달력은 유지하며 근무·일정 영역만 비웠다.
  - 목적: 공유 상태에 대한 별도 안내 없이 조용한 빈 화면을 제공한다.
  - 변경/영향: 친구 캘린더 UI와 관련 화면 회귀·문서. 정확한403 판정·캐시 폐기/늦은 응답 차단·다른 오류 알림 정책은 유지한다. 기존 월 이동/오늘/날짜 선택·화면 재진입으로 다시 조회하며 전용 재확인 버튼은 제공하지 않는다.
  - 테스트: 빈 일정/팝업·잠금·버튼 없음, 설정 접근·기존 조회 액션으로 복구, 캐시 제거와 기존 친구/탐색 회귀.
  - 구현/결과: 기존 FriendCalendarPage의 안내 위젯/import를 제거하고 CalendarPageBody는 항상 유지한다. is_access_denied일 때 schedule만 빈 SizedBox로 표시해 “일정 없음” 카드도 숨긴다. 기존 공용 range/provider의 정확한 거절 판정·캐시 폐기/동시성 방어는 수정하지 않았다. 기존 화면 테스트를 today 버튼 기반 재조회·빈 영역/설정/화면 크기 기대값으로 갱신했다. PROJECT_CONTEXT·ADR-0093을 현재 동작으로 갱신하고 ADR-0091의 안내 UI 대체를 기록했다. 새 영구 파일은 없다.
  - 검증: `flutter test --no-pub test/features/friend/presentation/pages/friend_calendar_page_test.dart test/features/calendar/application/calendar_range_notifier_test.dart test/core/navigation/main_tab_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter expanded` **52 pass**, 변경 Dart2파일 analyze **진단0**, 포맷/문서·소스 diff 공백 검사 통과. 관련 로그는 `/private/tmp/shiftmate-friend-calendar-20261121/empty-regression.log`다.
  - 화면/한계: 같은 폴더의 `empty_render_test.dart`는 기존 임시 렌더러를 빈 일정 UI에 맞춘 사본이며 Flutter/앱 코드·FontLoader·모의 Dio403·RepaintBoundary/dart:io/ui에 의존한다. `flutter test --no-pub <해당경로> --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 PNG4개(empty_phone/large_text/landscape/tablet)를 생성하고 렌더1 pass를 확인했다. 대표375x667의 달력/빈 일정 영역을 직접 확인했다. 실기기·배포는 미수행이다.
  - 롤백: 이번 친구 페이지/테스트·문서 추가분만 복구하면 직전 잠금 안내로 돌아간다. 다른 기존 작업은 보존한다.

## 2026-11-21 하단 플로팅 탭 배경과 화면 전환 연결

- [DONE] (FE/UI) 친구 상세 뒤로가기 스와이프에서 본문과 하단 탭 배경의 경계가 드러나는 구조를 수정했다.
  - 목적/원인: 본문 전환의 음영/배경이 하단에서 끊기지 않게 한다. 수정 전 실제375×667 화면·상단47/하단34px에서 Navigator 하단561px를 debug-live로 확인했고 신규 전체 화면 회귀가667px 기대/561px 실제로 실패했다. 기존 Column이 바 높이106px를 Navigator 바깥으로 분리한 것이 원인이다. 중단점/디버그 세션을 정리했다.
  - 변경/영향: MainTabPage는 Scaffold.extendBody로 route를 화면 끝까지 확장하고 기존 바를 겹쳐 놓는다. 실제 측정한 바/안전영역 높이를 AppTabNavigation.bottom_inset으로 전달해 각 페이지의 AppTabBody가 본문에만 여백을 예약한다. 기존 Cupertino 글꼴/바 크기·재질·간격·탭 이력·동작 줄이기·고대비·배지·root 폼 경로를 유지한다. **Behavior change**: 뒤로가기 중 음영/배경이 하단 안전영역까지 연결된다. API/DB/env/새 패키지·domain 상태 정책은 변경하지 않았다.
  - 파일/역할: 기존 core/navigation의 main_tab_page.dart·app_navigation.dart, 메인/친구 목록·캘린더·정보/알림/그룹 미리보기·캘린더·정보·받은 초대의9개 페이지에 본문 여백을 적용했다. 신규 저장소 파일은 없다. PROJECT_CONTEXT에 공통 위젯의 역할/의존성·새 탭 화면 적용법·렌더 사용 예를 기록하고 ADR-0092를 추가했다. 기존 인증 및 별도 친구 공유 해제 변경은 보존했다.
  - 검증 보완: 기존 main_tab_page_test.dart에375×667·844×390·768×1024(다크/2배)·768×1240(고대비/동작 줄이기/3.2배)의 실제 부분 드래그·취소/완료, route 하단·본문/바 경계·안전영역/바 위치 불변, 바 위/화면 맨 아래RGB 연속성(채널 오차2 이내)을 추가했다. 그룹 플래그true에서도 기존 그룹 복귀 시나리오가 실행되도록 모의 그룹/카드 선택을 보완했다. 기존 캘린더 토스트 회귀는2026-11-21의2주 마지막 토요일 다음날 셀이 없음을 디버거로 확인해 토요일에는 표시된 전날을 선택하도록 테스트만 수정했다.
  - 테스트: 기본 관련 회귀 `flutter test --no-pub test/core/navigation/main_tab_page_test.dart test/features/friend/presentation/pages/friend_list_page_test.dart test/features/friend/presentation/pages/friend_detail_page_test.dart test/features/friend/presentation/pages/group_calendar_preview_page_test.dart test/features/group/presentation/pages test/features/calendar/presentation/pages/calendar_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter expanded` **104 pass/1 skip**. 그룹 활성 main_tab_page+friend_list_page 회귀(`--dart-define=GROUP_API_ENABLED=true`) **41 pass**. 최종 친구 캘린더 통합 **16 pass**. 변경13 Dart파일 포맷 **변경0**, 변경 UI/회귀 정적 분석 **진단0**, diff 공백 검사 통과. SDK 캐시/분석 세션 쓰기 제한은 필요한 명령의 권한 확장 후 동일 검사 성공으로 해소했다.
  - 렌더/자료: 선택적 NAV_RENDER_OUTPUT의 PNG 생성은 tester.runAsync 안에서 실행한다. `/private/tmp/shiftmate-nav-render-final-20261121/`의 메인/친구/부분 스와이프 PNG12개를 생성하고 작은 화면·가로·큰 글자·다크 부분 전환을 직접 확인했다. 별도 렌더4 pass·픽셀 회귀4 pass. 로그는 `/private/tmp/shiftmate-nav-{tests-scoped-final,groups-final,friend-integration-final,render-final,pixels-final,analyze-final}.log`다. UI 점검 검색은 실제 플랫폼에 맞는 항목을 찾지 못해 스킬의 일반 고정 요소/안전영역 원칙과 로컬 Flutter Scaffold/route 구현을 근거로 적용했다.
  - 한계/다음: 실기기 제스처·프레임 성능·VoiceOver는 미실행이다. 앱 전체 다크 모드는 도입하지 않았다. 검증 중390×844/글자3.2배의 메인 일정 추가 Row에서 기존14px 가로 overflow를 관찰했으며 탭 전환 배치와 별개인 본문 접근성 후속 항목으로 남긴다. 최종3.2배 전환 검증은768×1240에서 수행했다.
  - 롤백: MainTabPage 배치·AppTabNavigation/AppTabBody·적용 페이지·이번 관련 테스트/문서만 함께 되돌린다. 기존 미커밋 인증/친구 공유 해제 변경과 데이터는 유지한다.

## 2026-11-21 친구 캘린더 공유 해제 안내 구현

- [DONE] (FE) 공유 거절을 전용 열람 불가 상태로 표시하고 수동 재확인으로 복구한다.
  - 목적/기획: 정확한 HTTP403/CALENDAR_ACCESS_DENIED만 오류 팝업 대신 잠금 아이콘·열람 불가 설명·다시 확인 버튼으로 표시한다. 친구 이름/설정/뒤로가기를 유지하며 서버 설정의 역방향을 추정하지 않는다.
  - 변경/영향: 친구 provider가 주입하는 거절 판정, 공용 range 상태의 선택적 접근 거절 처리와 캐시 폐기/이전 요청 무효화, 친구 페이지의 안내/재확인 및 관련 회귀. 재시도 중·일반 오류 후에도 거절 상태를 유지하고 성공 응답에서만 달력을 복구한다. 서버/DB/목록 API/공유 토글 정책은 유지한다.
  - 테스트: 최초403, 다른403/통신 오류, 재확인 성공/실패/중복 클릭, 기존 일정 제거·늦은 응답 차단, 설정 접근·작은 화면/큰 글자, 기존 캘린더·탐색 회귀와 분석/포맷.
  - 구현/파일: 기존 `calendar_range_state.dart`에 기본 false인 is_access_denied, `calendar_range_notifier.dart`에 선택적 access_denied_when과 접근 revision을 추가했다. 거절 시 모든 범위 데이터/로딩·요청 등록을 폐기하고 이전 revision의 성공·실패는 무시한다. 기존 `friend_calendar_range_provider.dart`만403/코드 판정을 주입한다. 기존 `friend_calendar_page.dart`는 해당 오류 팝업을 생략하고 스크롤 가능한 잠금 안내/설명/다시 확인 버튼을 표시한다. 재확인 중 disabled/spinner·성공 시 복구, 친구 설정의 접근성 이름·상하단 안전영역을 적용한다. 기존 AppTabBody 변경은 보존했다. 상태는 기존 autoDispose friend family가 소유하며 새 영구 파일/route/API/의존성은 없다. PROJECT_CONTEXT와 ADR-0091에 동작/경계를 기록했다.
  - 회귀/분석: `flutter test --no-pub test/features/calendar/application test/features/friend test/core/navigation/main_tab_page_test.dart test/features/calendar/presentation/pages/calendar_page_test.dart /private/tmp/shiftmate-friend-calendar-20261121/render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter expanded` **171 pass**(기존 관련 회귀+렌더1건). 새 회귀는 기존 range 테스트4건·친구 화면10건에 추가했다. 수정 Dart6파일 analyze 진단0·최종 포맷 변경0·diff 공백 검사 통과. 초기 테스트의 pending Dio 요청은100ms pump로 대기하고, fakeAsync 안에서 직접 await해 완료되지 않던 refresh는 pump 후 await하도록 고쳤다. 테스트 harness의 대기 문제이며 제품 코드 우회는 없다. Flutter SDK cache sandbox 거부는 승인된 같은 명령 재실행으로 해결했다.
  - 렌더/자료: `/private/tmp/shiftmate-friend-calendar-20261121/render_test.dart`는 기존 Flutter/앱·FontLoader(앱 TTF/패키지 CupertinoIcons)·RepaintBoundary·dart:io/ui에 의존하는 임시 화면 검증 스크립트다. `flutter test --no-pub <해당경로> --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로375x667·320x568 글자2배·844x390 글자2배/어두운 OS 선호·768x1024 어두운 OS 선호의 PNG4개를 생성한다. 최종4개 이미지를 직접 열어 아이콘·텍스트·스크롤 결과를 확인했다. 모의 상단44/하단34 안전영역·탭 예약96·동작 줄이기로 재확인 버튼44pt 이상과 스크롤 접근/오버플로 없음 확인. 앱의 기존 라이트 배경/텍스트 토큰을 유지하며 전면 다크 테마 도입은 아니다. regression.log/final-regression.log/render.log는 실행 결과다.
  - 한계/인수: 실제 두 계정의 원격 공유 토글/실기기·VoiceOver·빌드/스토어 배포는 이번에 수행하지 않았다. 이미 열린 화면의 권한 변경은 다음 서버 조회 응답에서 감지하며 자동 polling/push는 추가하지 않았다. 서버/DB/운영 설정과 사용자 기존 인증·하단 탭 작업은 보존했다.
  - 롤백: 이번 공용 range 옵션/상태·친구 provider/페이지·관련 테스트·문서 추가분만 복구하고 기존 하단 탭/인증 변경은 보존한다.

## 2026-11-21 친구 캘린더 공유 해제 시 오류 알림 조사

- [DONE] (FE/BE 진단) 공유 해제에 따른 정상적인 서버 권한 거절을 앱이 일반 오류 팝업으로 표시하는 경로를 확인했다.
  - 목적: 정상적인 공유 권한 거절과 앱 오류 표시의 연결 경로를 확인한다.
  - 범위: 앱의 친구 목록/설정/캘린더·공통 API 오류 처리와 로컬 서버 관련 코드 읽기, 가능한 재현 및 문서화. 제품 동작 수정·서버/DB 변경은 포함하지 않는다.
  - 원인/근거: 로컬 서버 `friendService.ts:237`은 owner=친구/viewer=나의 설정이 없거나 can_view=false이면 CALENDAR_ACCESS_DENIED를 throw하고, `friendController.ts:40`은 HTTP403/“친구 캘린더를 볼 수 없습니다.”로 응답한다. 앱 FriendListPage439행은 모든 친구를 캘린더로 이동시키고 FriendCalendarPage55행은 첫 프레임 후 조회한다. FriendService→handleApiError가 code/message/status를 보존한 ApiException을 생성하고 CalendarRangeNotifier가 last_error/error_revision에 저장한다. FriendCalendarPage211~218행은 오류 코드를 구분하지 않고 _showErrorDialog를 호출하며194행의 제목은 항상 “오류”다. 공유 차단 전용 화면 상태가 없는 것이 해당 알림의 원인이다.
  - 설정 방향: 서버 목록 SELECT의 fls.owner_user_id=:user_id는 나→친구 설정이다. 따라서 FriendModel.canView로 친구→나 열람 권한을 사전 판단할 수 없다. 목록에 친구가 유지되고 진입 가능한 이유와 구분한다. 근무표 레벨0이라도 can_view=false의 접근 거절이 우선한다. drawio2개는 calendars/calendar_shares가 남은 구형 도면임을 확인했으며 현행 AGENTS 단일 캘린더 DDL과 실제 코드를 기준으로 판단했다.
  - 검증: Dio 경계에 서버와 동일한403 JSON을 주입하고 실제 서비스·오류 변환·provider·화면을 사용하는 위젯 진단2건(나→친구 canView true/false 모두)에서 요청1회·“오류”/서버 문구 팝업·error_revision=1·loaded_months 비어 있음·미처리 예외 없음 확인. 기존 CalendarRangeNotifier10건과 함께 **12 pass**. 명령: `flutter test --no-pub /private/tmp/shiftmate-friend-calendar-20261121/diagnostic_test.dart test/features/calendar/application/calendar_range_notifier_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`(최초 실행은 임시로 test/features/friend/presentation/pages에 둔 같은 파일). 새 진단 파일의 역할은 공유 거절 UI 재현이며 기존 Flutter/Dio/Riverpod·앱 코드에 의존한다. 영구 테스트/제품 파일은 추가하지 않았다.
  - 한계/정리: DebugMCP 시작 호출이 완료되지 않아 중단하고 no-session을 확인한 뒤 중단점을 정리했다. 값 관찰 성공으로 기록하지 않는다. CLI 격리 재현은 성공했으나 사용자 실계정의 실제 응답/운영 로그·DB를 이번에 조회하지 않았으며 로컬 서버 코드를 배포 상태로 간주하지 않는다. 제품 동작·서버·DB는 변경하지 않고 PROJECT_CONTEXT와 이 일지만 갱신했다. 새 설계 결정이 없어 ADR 추가 없음.
  - 후속 수정 방향: CALENDAR_ACCESS_DENIED를 공유 비활성 상태로 분기하고 오류 팝업 대신 열람 불가 안내를 제공한다. 일반403 전체를 숨기거나 목록의 canView를 역방향 권한으로 사용하지 않는다. 이번 요청은 원인 조사이므로 구현하지 않았다.
  - 롤백: 이번 진단 문서 추가분만 복구하며 기존 미커밋 변경은 보존한다.

## 2026-11-21 휴대폰 인증 실기기 실패 조사

- [DONE] (FE/Auth 진단) 실기기 실패 지점을 Firebase SMS 요청의 internal-error로 확인하고, 사용자 확인으로 Stage Spark 유지에 따른 실문자 필수 조건 미충족을 확인했다. 결제 전환 후 실제 성공 인수는 남아 있다.
  - 목적: “휴대폰 인증을 완료하지 못했어요” 공통 안내로 가려진 발생 단계와 실행 오류를 구분한다.
  - 범위/변경: 관련 controller/repository/SDK adapter·설정·설치 FlutterFire/iOS SDK 코드를 읽고 기존 iPhone Debug 세션에서 중단점으로 확인했다. 이번에는 제품 코드·빌드/의존성·서버·콘솔/결제를 변경하지 않고 PROJECT_CONTEXT·콘솔 가이드·이 일지만 갱신했다. 기존 미커밋 변경은 보존했다. 새 영구 파일/설계 결정이 없어 ADR은 추가하지 않는다.
  - 실행 근거: `NativeFirebasePhoneAuthService.requestCode`의 verificationFailed callback → `phoneAuthError`에서 error.runtimeType=FirebaseAuthException, code=internal-error, message=“An internal error has occurred, print and inspect the error details for more information.”, stackTrace=null을 직접 읽었다. SMS 발송 요청에서 실패했으며 이후 SDK codeSent/번호 확인·서버 verify 단계의 성공을 확인한 결과가 아니다. 현재 Debug 구성은 Stage를 선택하고 .env의 Stage project ID=shift-mate-stage임을 비밀값 출력 없이 확인했다.
  - 필수 조건/결론: 사용자가 후속 질문에 **“Spark 유지 중”**이라고 Stage 상태를 재확인했다. [공식 Auth FAQ](https://firebase.google.com/docs/auth/faq-and-troubleshooting)는 SMS 서비스를 사용하려면 Cloud Billing 연결이 필요하다고 명시하고 [공식 한도](https://firebase.google.com/docs/auth/limits)는 검증 SMS를 Blaze 전용으로 명시한다. 현재 실문자 이용 조건 미충족은 확인된 차단 요인이다. 단, NSError의 underlying server response를 확보하지 못해 이번 internal-error의 원문이 BILLING_NOT_ENABLED였다고 단정하거나 다른 오류까지 해소됐다고 표현하지 않는다.
  - 오류 상세의 경계/제약: 설치 firebase_auth6.5.6의 FLTPhoneNumberVerificationStreamHandler.m은 convertToFlutterError를 호출하며, 이 변환은 NSError.userInfo의 underlying response를 추가 정보에 넣지 않는다. platform interface9.0.5도 callback에 code/message만 넘긴다. DAP output capture는 꺼져 있고 별도 native LLDB attach는 기존 디버거 연결 때문에 불가했다. devicectl은 기본 sandbox에서 초기화 timeout, 읽기 전용 권한 확장 후 기기 확인 성공. 연결 기기 log collect는 root 필요로 실패하여 원본 네이티브 오류 로그는 수집하지 못했다. 이 한계를 앱 버그나 결제 원문 확인으로 혼동하지 않는다.
  - 테스트/정리: 기존 SDK 테스트 `flutter test --no-pub test/features/auth/data/services/firebase_phone_auth_service_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` **3 pass**. 최초 실행의 Flutter SDK cache sandbox 쓰기 거부는 권한 확장 후 동일 명령 성공으로 해소했다. 문서 diff 공백 검사 통과. 조사 중 Dart 실행을 재개하고 조사용 중단점 전부 제거, 별도 LLDB 프로세스 종료. 사용자의 기존 디버그 앱은 종료하지 않았다. 실문자 성공·플랫폼 재빌드·운영 배포 검증은 수행하지 않았다.
  - 다음: Stage Firebase Console의 Usage and billing에서 Cloud Billing/Blaze를 연결한 뒤 실기기 SMS 요청→코드 입력→서버 증명→프로필 저장을 재검증한다. 연결 전에는 [공식 Flutter 테스트 안내](https://firebase.google.com/docs/auth/flutter/phone-auth)에 따른 콘솔 테스트 번호/고정 코드로 SMS 없이 흐름을 검증할 수 있으나 실문자 인수를 대체하지 않는다. 결제/콘솔 변경은 이번 조사에서 실행하지 않았다.
  - 롤백: 이번 세 문서의 진단 추가분만 복구한다. 기존 인증 구현/사용자 변경은 유지한다.

## 2026-11-21 Firebase Phone Auth 앱 재시도 보완

- [DONE] (FE/Auth) 만료·취소 등 복구 불가 challenge 오류 후 같은 번호로 새 요청 키를 사용해 인증을 재시작하도록 수정했다.
  - 목적: 응답 유실 후 만료된 세션/확정 실패의 키를 계속 재사용하는 앱 재시도 막힘을 해소한다.
  - 범위: phone controller 오류 분류/키 수명·회귀 테스트·문서. 서버·배포/콘솔/실문자는 변경하지 않는다. 통신 오류/일시적 서버 장애에는 기존 키를 보존한다.
  - 테스트: 기존 만료200 응답·서버 명시적 만료/취소/확정 실패·통신/503/429 재시도 키와 SDK 호출/인증 상태, 인증 회귀·분석/포맷을 확인한다.
  - 변경/영향: `_sendFailed`에서 PHONE_CHALLENGE_EXPIRED·PHONE_VERIFICATION_INVALID_RESPONSE 및 HTTP4xx(408/425/429 제외)의 _send_key를 폐기한다. 통신/불확실 실패·5xx·408/425/429는 키를 보존하고 Retry-After 대기를 지킨다. 다음 사용자 발송 시도에서 UUID를 만들며 자동 SMS 재요청은 하지 않는다. verify/프로필 저장 키·기존 가입/번호 변경 인증 조건·화면/route/native 설정은 유지한다.
  - 파일/역할: 기존 `lib/features/auth/application/phone_verification_controller.dart`의 challenge 오류 분류/키 수명만 수정했다. 기존 controller 테스트에는 실제 RemotePhoneVerificationRepository/Dio DTO의 만료200·타임아웃 복구와 확정/일시 실패9개를, 기존 profile_setup_page_test.dart에는 만료/취소 후 같은 번호 재인증·가입2개를 추가했다. AppTheme/화면 구조 변경은 없고 새 파일도 없다. mock SDK/repository·Dio/기존 앱 테스트에 의존하며 아래 인증 명령으로 재현한다. PROJECT_CONTEXT·모바일 계획·서버 요청서15절·ADR-0090에 목적/계약/영향/롤백을 최신화했다.
  - 진단/검증: 수정 전 신규 회귀5개 실패를 확인했다. debug-live로 해당 테스트를 실행해 만료 응답이 PHONE_VERIFICATION_INVALID_RESPONSE로 거부된 뒤 challenge=null이고 _send_key는 남아 있음을 확인했고, 실패 분기에서 확정 실패 키 폐기를 추가했다. 디버그 세션 종료/중단점 제거를 완료했다. 수정 후 `flutter test --no-pub test/features/auth --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` **166 pass**, 최종 만료 세션 fixture를 같은 key→같은 만료 응답으로 보강한 controller **23 pass**, 변경 Dart3파일 `flutter analyze --no-pub <3파일>` **진단0**, 포맷 변경0·diff 공백·문서 fence/로컬 링크·ADR 단일 선언 확인 통과.
  - 자료/한계: `/private/tmp/shiftmate-phone-retry-20261121/`의 before.log는 수정 전 실패, auth-final.log/controller-final.log는 회귀 결과, analyze.log/format-check.log는 정적 검증이다. Flutter SDK/현행 소스·모의 SDK/Dio에 의존한다. 이번에는 UI/native 변경이 없어 렌더/플랫폼 빌드·전체 앱/서버 DB 테스트·실문자·배포는 재실행하지 않았다. 서버가 취소 상태를200으로 숨기면 앱은 알 수 없으므로 서버의 명시적 오류 보완은 여전히 필요하다. 읽기 확인 시 서버 WORKLOG에도 해당 보완/배포가 TODO이며 이번에 서버 완료를 인수하지 않았다. 앱 범위 소스/문서만 수정했다.
  - 롤백: 이번 controller·테스트·문서 추가분만 복구하고 이전 미커밋 구현을 보존한다.

## 2026-11-21 Firebase Phone Auth 서버 완료 후 연동 검토

- [DONE] (FE/BE 검토) 완료된 서버와 모바일의 인증 계약을 대조하고 정상 연동 및 예외 경로2건을 재현했다. 수정 검토 항목은 아래에 남긴다.
  - 목적: 가입/변경번호 인증이 실제 서버와 호환되는지, 우회·연동 실패가 없는지 확인한다.
  - 범위: 로컬 서버 소스/문서·앱 소스 읽기와 검증, 결과 문서화. 배포/결제/실문자/운영 DB 변경은 포함하지 않는다.
  - 테스트: 양측 인증 테스트와 서버 계약/경계 검토, 필요한 경우 격리된 로컬 검증.
  - 확인한 서버: 인접 저장소 clean HEAD `f1664b7`(Firebase phone verification and atomic profile receipts). 서버 문서는 로컬 구현 완료·push/배포/Stage 실문자 미수행으로 기록되어 있다. 완료된 소스를 배포 완료로 간주하지 않았다.
  - 정상 계약: 두 POST 경로·앱 Bearer JWT·UUID Idempotency-Key·SIGNUP/PHONE_CHANGE·국내 숫자/E.164·challenge/proof 응답·본인 phone_verified_at/requires_profile_setup·JSON/multipart 저장이 일치한다. 서버는 최신 DB 전화번호·목적/소유자·Admin 토큰/이벤트 재사용·증명 만료/소비를 검사하고 User/증명/영수증을 transaction으로 저장한다. 미완료 업무 gate·가입 중 push/아바타와 기존 미변경 번호 부분 저장도 확인했다.
  - 재현1(P2, 앱/서버): challenge 생성 commit 후 응답 유실 → 해당 challenge 만료 → 같은 번호 재시도 시 서버는 기존 만료 세션을200으로 반환한다. 앱 DTO가 PHONE_VERIFICATION_INVALID_RESPONSE로 거부하지만 controller의 _send_key는 유지되어3회 모두 같은 키로 실패하고 SDK 호출0회다. 타임아웃에는 같은 키를 유지하되 만료/복구 불가 오류에는 키를 폐기하고 새 시도를 허용해야 한다. 서버도 만료 세션 재응답을 명시적410으로 구분해야 한다.
  - 재현2(P2, 서버): challenge 응답 유실 → 다른 요청이 새 challenge를 만들어 기존 세션 취소 → 기존 키 재시도 시 서버가 취소된 challenge도200으로 반환한다. 앱은 정상 발송 대상으로 받아 SDK requestCode1회를 실행하고 이후 verify400 PHONE_VERIFICATION_INVALID로 실패한다. 실제 문자는 발송하지 않았으며 SDK 발송 경로 진입만 확인했다. 서버 createChallenge의 기존 key 반환 전에 세션 활성/취소·목적/소비 상태를 검사하고 복구 불가 응답과 새 key 재시도 계약을 정해야 한다.
  - 테스트/결과: 앱 인증155 pass. 원본 서버를 수정하지 않고 `/private/tmp/shiftmate-phone-review-20261121/`에 소스/테스트/migration을 복사하고 기존 node_modules를 참조해 strict TypeScript build·단위5 pass·실제 PostgreSQL16/Express 통합19 pass. 추가 Flutter 실제 controller/repository/datasource ↔ loopback Express/일회용 PostgreSQL 계약 검증4개는 정상2개(가입 사진 multipart/편집 JSON·동일 key/타 필드 저장·재업로드 없음)와 위 결함의 현 동작 재현2개다. 이4개 통과를 결함 해결로 표시하지 않는다. Firebase SDK/Admin 외부 경계·S3는 테스트 fake이며 실문자/실제 ADC/IAM/서명/플랫폼 확인·원격 배포 검증은 아니다.
  - 파일/진단 역할: 기존 코드/정책을 변경하지 않고 PROJECT_CONTEXT·모바일 계획·서버 요청서14절·이 작업 로그를 최신화했다. 신규 제품 파일/ADR은 없다. 임시 review 폴더의 src/test/migrations/dist·node_modules symlink는 서버 격리 build/통합 검증용, build.log/phone-unit.log/phone-integration.log/flutter-auth.log/app-contract.log/app-fixture.log는 실행 근거다. app-fixture.cjs는 loopback Express와 dummy JWT·fake Admin/S3·테스트 전용 만료/취소 제어 경계, app_contract_test.dart는 실제 앱 HTTP/DTO/controller 정상·결함 재현용이다. Node/npm·Flutter·Docker PostgreSQL16·현행 코드에 의존하며 전용 DB 준비 → `node --test test/phoneVerificationIntegration.test.cjs`(고정 reset/env 포함) → `node app-fixture.cjs` → 앱 루트에서 `flutter test --no-pub /private/tmp/shiftmate-phone-review-20261121/app_contract_test.dart` 순서로 사용한다. 테스트 외 제품에 제어 경계를 추가하지 않았다.
  - 정리/다음: fixture 프로세스를 종료하고 검증용 `shiftmate-phone-review-20261121` 컨테이너·메모리 DB·임시 JWT/secret manifest를 제거했다. 기존 서버 저장소/운영 DB/콘솔/배포는 변경하지 않았다. 서버 요청서14절의2건을 수정한 뒤 재검증하며 Stage 배포/실제 Firebase 앱 확인·SMS 인수는 별도다.
  - 롤백: 검토 기록 추가분만 제거한다. 기존 미커밋 구현은 보존한다.

## 2026-11-21 Firebase Phone Auth 모바일 구현

- [DONE] (FE/Auth) Firebase 휴대폰 인증과 가입/번호 변경 저장 조건의 모바일 구현·모의 검증을 완료했다. 서버/실문자 연동은 인수 전이다.
  - 목적: 가입은 인증 증명 필수, 개인정보 편집은 최초 조회 번호에서 변경한 번호만 인증 후 저장하도록 한다.
  - 범위: Firebase SDK/초기화·인증 상태/공통 UI·서버 DTO/API·프로필 저장·회귀 테스트·문서. 기존 미커밋 가입 UI/빌드 변경을 보존한다. 서버 구현/결제·콘솔 변경은 포함하지 않는다.
  - 사용자 제공 상태: Stage shift-mate-stage / 운영 shift-mate-b9e32 모두 Phone 활성·KR 단독 SMS 허용, Spark 유지. Android SHA 미등록, Stage 개발 APNs / 운영 개발·프로덕션 APNs 등록. 기존 FCM/키 보존. 이는 사용자 확인 내용이며 이번에 콘솔을 직접 확인한 결과는 아니다.
  - 선행 한계: 현재 인접 서버에는 신규 phone challenge/verify가 없다. 작성한 요청서 계약으로 구현·모의 검증하며 실제 API 인수/Blaze·Android 지문·Stage APNs 환경/실문자는 별도 확인한다.
  - 테스트: 신규 SDK/controller/API·가입/편집·이미지/401 회귀, 포맷/분석·플랫폼 빌드와 문서/diff 검사.
  - 변경/영향: firebase_auth6.5.6 pin과 Auth native 의존성만 추가해 기존 core4.12.1/messaging16.4.3/Firebase iOS12.15.0·기존 lock 버전을 유지했다. 공통 initializer·전용 phone repository/SDK adapter·화면별 controller/state·공통 인증 입력을 추가했다. 가입/변경번호는 서버 증명 전 저장 차단, 편집 최초 GET/재시도·원번호 복귀 시 phone 생략, 코드/자동 인증·만료/재발송·늦은 callback/세션 정리·안전한 오류·멱등 재시도·JSON/multipart/401 증명 보존을 구현했다. User.phone_verified_at은 nullable 파싱하며 SDK 성공만으로 가입 완료하지 않는다. 기존 사용자 가입 UI/버전6·ShiftMate 소셜/JWT·FCM 설정/키·선택값/이미지 부분 저장을 보존했다.
  - native/파일 역할: iOS Thin Binary 단계의 Python 스크립트가 선택한 IOS_APP_ID의 callback scheme을 built Info.plist에 멱등 주입하고 OAuth URL type을 유지한다. FirebaseAuth12.15.0의 scheme 규칙과 Flutter plugin6.5.6의 SceneDelegate URL 전달을 직접 대조했다. 신규 앱7파일·SDK/HTTP/controller 테스트·fake helper·Python2파일·18조건 렌더러의 역할/의존성/사용 예는 PHONE_VERIFICATION_FLUTTER_PLAN.md11절에 기록했다. PROJECT_CONTEXT·ADR-0089 및 계획/서버 요청/콘솔 가이드·기존 가입/편집 요청서 상태를 최신화했다.
  - 테스트/결과: 최종 `flutter test --no-pub test/features/auth --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` **155개 통과**. SDK 자동/수동 경합·늦은 로그인/정리·번호/목적/만료·서버 재시도 같은 ID token/key·404/501/429·가입 완료 boolean·증명 없는 저장 차단·최신 GET·사진/401 증명/헤더/오류410 보존을 포함한다. `python3 -m unittest discover -s ios/scripts -p 'test_*.py'` **3개 통과**(환경별/멱등 실행·기존 plist 보존·잘못된 입력 선실패). 변경 Dart31파일 포맷·분석 error/warning0, 변경 파일 진단0. 전체 분석은 기존 미변경 naming info26건으로 종료1이며 해당 관련 없는 파일은 수정하지 않았다. User 코드 생성 성공, 기존 analyzer 언어 버전 안내는 실제 빌드 실패와 구분했다.
  - 전체 회귀/기존 실패: `flutter test --no-pub --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` **588 pass / 기존 skip1 / fail1**. 실패는 미변경 `test/features/calendar/presentation/pages/calendar_page_test.dart:1084`의 `3초 삭제 토스트는 달력·카드·추가 버튼의 위치와 크기를 바꾸지 않는다`에서 다음 날짜 셀 ancestor 조회가 비어 발생한다. 같은 테스트 단독 재실행과 수정 전 HEAD를 git archive한 독립 `/private/tmp/.../baseline`에서도 **동일 위치/오류 재현**을 확인했다. 전화 인증 회귀로 판단하지 않으며 목표 외 달력 코드는 수정하지 않았다. 전체 통과라고 표시하지 않는다.
  - 빌드/렌더: `flutter build ios --debug --no-codesign --no-pub --dart-define-from-file=.env` 성공(Xcode51.7초), built Runner.app의 Stage callback scheme/기존5개 URL type·remote-notification 보존 확인. `flutter build apk --debug --no-pub --dart-define-from-file=.env` 성공(Gradle111.7초). `flutter test --no-pub artifacts/phone_verification_2026-11-21/render_test.dart` 통과: 가입/편집 각각390·320·375px·글자2배·모의 키보드·가로·태블릿·완료·오류 **18조건**, 최소 버튼 크기/저장 gating·framework 오류 없음/PNG18개. 대표 정상·완료·큰 글자·키보드 이미지를 직접 확인했다. 실제 OS 키보드/스크린리더·실기기 앱 확인·실문자·서버 Admin/DB·Release/배포 결과가 아니다.
  - 진단/자료: 초기 provider initState 갱신의 Riverpod build 중 수정 오류를 debugger로 확인하고 초기 번호를 provider 생성 상태로 옮겨 해결했다. 렌더 테스트는 이미지 캡처를 runAsync로 감싸고 번호 변경 후 프레임을 반영해 해결했다. 디버그 세션 종료/중단점 제거를 확인했다. `/private/tmp/shiftmate-phone-auth-20261121/`의 before.patch는 작업 전 변경 보존 자료, codegen/format/analyze/auth/test-full/ios-build/android-build/render 로그는 로컬 진단, render/PNG는 UI 확인, baseline/은 원본 HEAD 실패 비교용이다. 저장소/Flutter SDK·Python·기존 환경 설정에 의존하며 재실행 명령은 위와 같다. 설정 비밀값은 문서/콘솔에 출력하지 않았다.
  - 최종 점검: adapter 최종 변경 포함 iOS Debug 재빌드10.9초 성공. 신규 phone provider 변수3개를 snake_case로 정리한 뒤 인증155개/분석을 재확인했다. 변경 Dart31파일 포맷 일치·diff 공백 검사, 관련 문서 fence/로컬 링크10개·JSON/신규 파일 역할 경로·ADR 단일 선언·drawio XML2개 검증 통과. 작업 전 patch로 원본 UI/pubspec을 독립 복원해 기존 빌드6 보존과 이번 pubspec 변경이 firebase_auth 추가뿐임을 확인했다.
  - 다음/한계: 서버 요청서의 challenge/verify·Admin 검증·DB 증명 소비/영수증/최신 번호 비교·프로필 응답을 구현/배포한 뒤 Stage 양측 인수. Blaze·Android SHA·Stage 프로덕션 APNs 필요 여부·실기기 silent APNs/reCAPTCHA/Play Integrity·실문자·기존 FCM/소셜·동의/보관/공개 정책을 확인하고 출시한다. 결제/콘솔/서버/DB/배포는 이번에 변경하지 않았다. 신규 API 없는 현재 서버에서는 가입/번호 변경이 준비 중 안내로 차단된다.
  - 롤백: 이번 인증 관련 변경만 되돌리고 이전 사용자 UI/버전/문서 변경은 유지한다.

## 2026-11-21 Firebase 콘솔·운영 사전 작업 조사

- [DONE] (운영 문서) Phone Auth 도입에 필요한 코드 외 Firebase/Google Cloud·Apple/Android 설정을 조사해 실행 체크리스트를 작성했다.
  - 목적: 프로젝트/결제·Phone 제공자·SMS 지역·앱 확인·서버 IAM·테스트/운영 인수 작업을 담당자가 수행할 수 있게 정리한다.
  - 범위: 공식 자료와 현재 저장소 설정 확인, 신규 설정 가이드와 기존 계획/컨텍스트 연결. 실제 콘솔/결제/IAM·키 발급·코드/배포 변경은 하지 않는다.
  - 변경/영향: FIREBASE_PHONE_AUTH_CONSOLE_SETUP.md에 F-01~F-11 담당/순서·콘솔 메뉴·설정값/비밀 전달 구분·완료 증거·Stage/운영 인수표와55개 미완료 체크리스트를 작성했다. Project/Blaze·Phone/KR·API key·Android 서명·iOS APNs/Encoded App ID·서버 ADC/IAM·테스트/App Check·정보 처리/장애 복구를 담았다. 모바일/서버 계획·기존 푸시 가이드·PROJECT_CONTEXT에 연결했고 신규 파일 역할/의존성/사용 예·롤백을 기록했다. 기존 ADR-0088을 유지하여 새 ADR은 추가하지 않았다.
  - 조사 근거: 현재 FirebaseEnvironmentOptions·pubspec·Android Gradle/서명·iOS Info.plist/entitlements·기존 푸시 문서·인접 서버 Firebase FCM/환경 검증을 읽었다. 공식 Firebase/Google Cloud의 Phone Auth·결제/요금/한도·SMS region·API key·IAM/Admin·App Check·예산 문서를 대조했다. KR 단가US$0.01/발송·일별 첫10건 미청구와 Blaze 연결 요건을 구분하고 가격/쿼터 재확인을 명시했다. 과거 운영 ID 기록과 실제 콘솔 미확인을 구분했으며 secret 원문은 읽어 출력하지 않았다.
  - 테스트/결과: git diff --check 통과. 설정 가이드·모바일 계획·서버 요청서3개의 로컬 링크10개/기존10절 앵커·fence/개행/공백·JSON 예시5개·필수 메타데이터·55개 체크박스, PROJECT_CONTEXT/푸시 링크와 요금 산식(청구대상1,000건=US$10)을 Python으로 확인했다. 기존 define 이름을 소스와 대조했다. 실제 콘솔/결제/IAM·키 발급·앱/서버 테스트·실문자·배포는 미수행이며 체크리스트를 완료 처리하지 않았다.
  - 다음: F-01~F-08 담당자가 환경별 설정/자료를 준비하고, SDK/서버 구현 후 F-09~F-11과 실기기 인수를 진행한다. App Check 강제는 대응 SDK/모니터링 후 별도로 판단한다.
  - 롤백: 이번 문서 추가/연결분만 제거하고 기존 사용자 변경과 인증 설계는 보존한다.

## 2026-11-21 Firebase Phone Auth 참고 글 검토

- [DONE] (문서 검토) 사용자 제공 Velog 예제를 공식 Firebase 규격·ShiftMate 계획과 비교하고 보완사항을 반영했다.
  - 목적: 예제에서 참고할 SDK 흐름과 프로젝트에 맞게 보완할 가입/번호 처리·timeout·운영 조건을 구분한다.
  - 범위: 제공 글·공식 문서·관련 현행 코드 확인, 기존 모바일/서버 계획과 컨텍스트·일지에 검토 결과 추가. 구현/패키지/콘솔/배포는 제외한다.
  - 변경/영향: 모바일 계획10절에 서비스/SDK 흐름 참고와 국내0 제거·이메일 계정 선생성/Firestore 제외·credential 생성과 인증 성공 구분·자동 완료·120초 timeout 의미·원문 오류/과거 비용/기기 경험 구분을 추가했다. 서버 요청서13절에 잘못된 +82010 번호 거부·가입 완료 증거·기한/실문자 인수를 연결하고 PROJECT_CONTEXT에 기록했다. 기존 ADR-0088/정책은 유지하여 새 ADR은 추가하지 않았다. 새 파일 없이 기존 두 계획의 역할/의존성/사용 예를 따른다.
  - 근거: 제공 글(2024-08-31)의 전체 코드/호출 순서를 읽고 공식 Flutter Phone Auth·password auth·현재 limits로 대조했다. 기존 auth repository/datasource·AuthWrapper·pubspec을 다시 확인했다. 이메일 계정 생성 뒤 연결 실패 시 잔여 계정 가능성은 호출 순서에 근거한 판단으로 명시했다.
  - 테스트/결과: git diff --check 통과. 두 문서의 로컬 링크/10절 앵커·fence/개행/공백·JSON 예시5개 파싱 통과. 번호 단순 결합과 국내0 제거 변환 예시를 Python 문자열로 확인했다. 문서 검증이며 Flutter SDK 실행/서버 테스트·SMS 검증 결과로 간주하지 않는다. 구현/패키지/콘솔/배포는 변경하지 않았다.
  - 롤백: 이번 검토 추가분만 제거하고 Firebase 방식 계획과 기존 사용자 변경은 보존한다.

## 2026-11-21 Firebase Phone Auth 방식으로 계획 변경

- [DONE] (FE/BE 문서) 사용자 요청에 따라 SENS + Redis OTP 계획을 Firebase Phone Auth 방식으로 대체했다.
  - 목적: 가입 인증 필수·편집 변경 번호 인증 조건을 유지하면서 SMS 발송/번호 검증을 Firebase에 맡긴다.
  - 범위: 공식 Firebase 문서·현행 Firebase/인증 코드 확인, 모바일 계획·서버 요청서·컨텍스트·ADR·관련 계약 갱신. 앱/서버 구현·콘솔 설정·배포는 포함하지 않는다.
  - 변경/영향: 모바일 계획190행/서버 요청서288행을 기반으로 Firebase SDK 발송/코드 확인 → Admin ID token 검증 → 앱 사용자/번호/목적 binding 증명 → 기존 프로필 원자 저장 방식으로 재작성했다. 후속 검토에서 iOS 알림 권한 분리와 idempotency/key 교체 조건을 보완했다. SENS/서버 Redis OTP·send API·180초/오답5회 정책은 폐기하고 기존 Redis 캐시는 보존한다. PROJECT_CONTEXT·ADR-0088·기존 가입/편집 후속 링크를 갱신했고 ADR-0087/이전 일지는 대체 이력으로 표시했다.
  - 근거/파일 역할: 기존 Flutter auth 경로·FirebaseEnvironmentOptions·initializePushFirebase·pubspec·iOS APNs/콜백·Android 서명 설정, 인접 서버 firebasePushProvider/환경검증을 직접 확인했다. Firebase 공식 Flutter/Android/iOS Phone Auth·Admin token/claims·native 세션 유지·쿼터 문서로 확인했다. 두 신규 계획 문서의 실제 역할/의존성/사용 예와 구현 예정 파일별 역할은 문서 및 PROJECT_CONTEXT에 기록했다.
  - 테스트/결과: git diff --check 통과. 두 계획 문서 fence·끝 개행·공백·필수 계약/메타데이터, JSON 예시5개 파싱, 로컬 링크4개, ADR-0088 단일 선언/0087 대체 표시, 기존 가입/편집 링크의 Firebase 방식 전환을 Python으로 확인했다. SENS/Redis 언급이 이전 방식 폐기·기존 캐시/선택적 제한 역할에만 남는지 검색 검토했다. 코드/패키지/콘솔 변경이 없어 Flutter/서버 테스트·빌드·실문자·migration/배포는 실행하지 않았다.
  - 다음: 서버 OpenAPI·프로젝트/Auth 권한·SDK 호환/플랫폼 설정·Google 번호 처리/보관·기존 회원/업무 API 이행을 확정하고 FE-1~FE-5와 서버 Stage 인수를 진행한다.
  - 롤백: 이번 문서 변경분만 되돌린다. 이전 SENS 계획은 이력으로 남기되 현행 계획으로 적용하지 않는다.

## 2026-11-21 휴대폰 인증 도입 계획·서버 요청

- 후속 대체: 아래 SENS/Redis OTP 계획은 사용자 요청으로 Firebase Phone Auth 방식(ADR-0088)으로 개정했다. 현행 계획은 상단 개정 작업과 PHONE_VERIFICATION 문서를 따른다.

- [DONE] (FE/BE 문서) 네이버 SENS + Redis OTP 기반 가입·전화번호 변경 인증 계획과 서버 전달 명세를 작성했다.
  - 목적: 가입 완료에는 인증을 필수로 하고, 개인정보 편집에서는 최초 조회 번호와 다른 번호를 저장할 때 인증하도록 계약을 정의한다.
  - 범위: 현행 Flutter 인증/프로필 코드·문서·DB 다이어그램 확인, 모바일 실행 계획과 서버 전달 명세 작성. 앱·서버 구현/배포는 이번 범위 밖이다.
  - 변경/영향: PHONE_VERIFICATION_FLUTTER_PLAN.md에 실제 코드별 FE 단계·최신 프로필 스냅샷·인증 상태/UX·저장 gating·테스트·배포 계획을 기록했다. PHONE_VERIFICATION_SERVER_HANDOFF.md에 보호된 send/verify·SIGNUP/PHONE_CHANGE 증명·기존 JSON/multipart 저장 확장·Redis/SENS 장애/제한·DB 영수증 일회성/재시도·환경변수·OpenAPI·인수를 정리했다. PROJECT_CONTEXT·ADR-0087과 기존 가입/편집 요청서 상단에 계획/구현 전 상태와 연결을 추가했다. 신규 문서의 역할/의존성/사용 예도 기록했다.
  - 근거: Flutter main/settings/profile/provider/repository/datasource/User·공통 Dio/오류/상수/build 설정, schema.drawio/visibility_flow.drawio, 인접 로컬 서버 routes/controllers/profile service·mutation·User·phone migration/utility·Redis·auth/rate limit·Google/Naver phone writer·account lock·OpenAPI를 직접 확인했다. SENS 발송/서명과 Redis 원자성/TTL은 공식 문서로 확인했다. drawio의 과거 calendar 모델·기존 문서의 과거 서버 상태와 실제 현행 소스 차이를 명시했다. 운영 DB/서버 배포·Redis 가용성을 확인한 것으로 기록하지 않는다.
  - 테스트/결과: git diff --check 통과. 신규 Markdown 2개의 fence 균형·문서 역할/의존성/사용 예, JSON 예시8개 파싱, 로컬 문서 링크7개, ADR-0087 중복 없음과 기존 계약의 후속 링크, drawio XML2개 파싱을 Python으로 확인했다. 문서 전용 변경이므로 Flutter/서버 테스트·실문자·migration·빌드/배포는 실행하지 않았다. 실제 구현 검증은 계획/요청서의 인수 항목으로 남겼다.
  - 롤백: 이번 신규 문서와 공통 문서 추가분만 제거하고 기존 미커밋 변경은 보존한다.
  - 다음: 서버 담당자와 OpenAPI·TTL/한도·기존 회원 이행/미완료 업무 API 접근·수탁/운영 정책을 확정한 뒤 서버 Stage 선준비와 FE-1~FE-5를 진행한다. 담당자 메시지 전송·서버 수정은 이번에 수행하지 않았다.

## 2026-11-16 심사 제출용 iOS 빌드 6

- [DONE] (FE/iOS) 현재 작업 트리를 App Store 제출용 1.0.0(6) IPA로 빌드했다.
  - 목적: UIScene 크래시 수정·세로 방향·네이버 SDK5.2.1·최신 가입 UI를 포함한 심사 재제출 파일을 생성한다.
  - 범위: 기존 빌드5 Archive/IPA를 보존하고 pubspec 빌드 번호를6으로 올린다. 기존 운영 .env·Release 서명·lock을 사용하며 기존 미커밋 소스와 사용자 데이터는 보존한다.
  - 테스트: Release Archive·App Store IPA 생성, 버전/운영 환경·UIScene/방향·SDK·서명/profile·ZIP 무결성·심볼을 확인한다.
  - 실행/결과: `flutter build ipa --release --no-pub --dart-define-from-file=.env --build-name=1.0.0 --build-number=6 --export-method=app-store` 종료0. Archive44.0초·IPA60.4초. `build/ios/ipa/ShiftMate.ipa` 24,731,032bytes, SHA-256 `dd5554bba77dd33411673d6eefb2a48ec53640a2232dab5ef69409a4476e0e3e`. `pubspec.yaml`은1.0.0+6, API 호환 번호1 유지. 기존 빌드5 해시/Archive 버전 확인 후 `build/ios/releases/1.0.0-5/`에 보존했다.
  - 검증 완료: IPA ZIP CRC·Apple Distribution deep/strict 서명·App Store profile/만료일·production APNs/Apple 로그인 권한·운영 API/Firebase/OAuth·Stage/로컬 API 문자열 부재·URL scheme 치환·단일 FlutterSceneDelegate·iPhone/iPad portrait/UIRequiresFullScreen·NidThirdPartyLogin5.2.1·Archive/IPA 버전6·Runner/App dSYM UUID 일치 및 diff 공백 검사 통과. 기존 기본 LaunchImage placeholder 경고1건은 유지한다. 이전 최신 코드의 인증125개/렌더 검증을 재사용했고 이번 변경은 빌드 번호/문서뿐이므로 앱 테스트를 재실행하지 않았다.
  - 산출물/자료: Archive/IPA/내보내기 설정·진단 자료의 역할/의존성/사용 예는 PROJECT_CONTEXT 상단을 따른다. `/private/tmp/shiftmate-appstore-build6-20261116.log`는 Flutter/Xcode 빌드 로그, `/private/tmp/shiftmate_appstore_build6_verify_20261116.py`는 이전 빌드 검증기를 확장한 Python 표준 라이브러리·codesign/security/xcrun 기반 검증 스크립트, `/private/tmp/shiftmate_appstore_build6_20261116/`는 추출 Payload와 credential 비포함 verification.json이다. `python3 /private/tmp/shiftmate_appstore_build6_verify_20261116.py`로 재현한다. 산출물/기존 .env/네이티브 설정에 의존하며 환경·기기·인증 자료는 커밋하지 않는다.
  - 영향/한계: 이번에 스토어 업로드·Connect 처리/빌드 선택·심사 재제출·새 IPA 실기기 설치를 하지 않았다. 앞선 개발 서명 Release6의 iPad 실행 확인과 이번 Distribution IPA 생성/검증을 구분한다. 설계 변경이 없어 새 ADR은 추가하지 않았다.
  - 요청 정정: 최초 요청을 기기 실행으로 해석해 Debug 실행을 시작했으나 사용자가 심사 제출용 파일 생성으로 정정했다. 해당 Flutter 세션55398을 Ctrl-C로 종료했다. 기기 실행 성공을 주장하지 않는다. `/private/tmp/shiftmate-build-run-20261116.log`는 중단된 시도의 임시 로그다.
  - 롤백: 이번 pubspec/문서 변경을 되돌리고 신규 산출물을 제거한다. 보존한 빌드5와 기존 소스는 유지한다.

## 2026-11-16 회원가입 개인정보 입력 디자인 통합

- [DONE] (FE/Auth) 회원가입에 개인정보 편집 입력 UI를 재사용하고 직종·회사 플레이스홀더를 제거했다.
  - 목적: 가입과 편집의 입력 디자인을 일치시킨다.
  - 변경/영향: 기존 profile_setup_page.dart의 편집 카드/필드·사진/이름·이메일·하단 버튼을 공통화하고 이전 가입 표시 코드를 제거했다. 가입 제목/완료 버튼·선택 정보/개인정보 안내와 기존 가입 완료/부분 수정 API 계약을 보존한다. 직종·소속/부서 placeholder는 양쪽 모두 null이다. 가입도 공통 포커스/다음 입력·이름 요약을 사용하며 사진 선택 중 이탈을 막는다. 기존 편집 검증/이탈 확인/실패 재시도는 유지한다. ADR-0086·PROJECT_CONTEXT에 변경/동작/역할을 기록했다. 새 영구 파일은 없다.
  - 테스트: 프로필24개 및 전체 인증125개 통과(`flutter test --no-pub test/features/auth --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`). 기존 회귀에서 같은 카드/입력 디자인·placeholder 부재·선택값 없이 가입·사진/타임존·자유 직종 전송·편집 부분 저장을 확인했다. 수정 Dart2파일 분석 진단0·포맷 변경0·diff 검사 통과. 신규 무관 테스트/소스 변경은 없다.
  - 화면 검증: 기존 artifacts/profile_edit_redesign_2026-11-11/render_test.dart를 /private/tmp/profile_input_20261116/render_test.dart로 복사해 양쪽 모드를 검증했다. 각14조건·PNG28개/측정JSON2개, 320/375/390px·가로·태블릿·2배 글자·동작 줄이기·모의 키보드·하단 스크롤/버튼 최소52/안전영역을 통과했다. 가입 일반/하단/작은화면 큰글자·편집 일반 PNG를 직접 열어 카드 일치와 빈 근무 입력을 확인했다. 임시 렌더러 역할/의존성/재현 명령은 PROJECT_CONTEXT를 따른다. 실제 OS 사진/키보드·실서버·VoiceOver 및 다크 테마는 미인수다.
  - 도구 이슈: SDK wrapper의 engine.stamp 및 Dart telemetry 캐시 쓰기 제한으로 최초 포맷/인증 실행이 중단됐다. 내장 Dart로 포맷했고 SDK 캐시 권한으로 인증/렌더/분석을 다시 실행해 완료했다. 첫 분석의 테스트 불필요 cast1건은 제거한 뒤 재검증했다. 로그는 /private/tmp/profile-input-auth-tests-20261116.log와 위 임시 폴더의 render.log에 보관한다.
  - 롤백: 이번 화면·관련 회귀·문서 변경만 되돌린다.

## 2026-11-16 작업별 커밋 분리 및 원격 푸시

- [DONE] (Git) 누적 변경을 작업별 14개 커밋으로 분리하고 origin/develop에 푸시했다. 최종 문서 정합성·검증 기록은 후속 문서 커밋으로 함께 보존한다.
  - 목적: 캘린더·공통 UI·친구/그룹·인증·iOS·웹 문서 변경을 검토·롤백 가능한 단위로 정리한다.
  - 변경/영향: 원격 develop의 기존 Google 전화번호 커밋850e45d를 먼저 반영하고 기존 작업 파일은 보존했다. 공통 문서는 항목별로 인덱스에서 분리하고 각 코드 커밋에 PROJECT_CONTEXT·WORKLOG 및 필요한 ADR을 함께 포함했다. pubspec의 빌드 번호/SDK 경로, Info.plist의 UIScene/방향 설정도 서로 분리했다. 마지막 문서 커밋은 기존 설명과 후속 정책의 정합성을 맞추고 원격의 Google 검증/병합 기록을 보존한다.
  - 작업 커밋: 42dc28b 그룹 nullable / 9cc41b2 피커 / 04cdcf3 일정 편집·삭제·캘린더 배치 / 5d3117b 색상·헤더 / 333a315 친구·그룹 탐색 / 05a2395 설정 / f9238ce 웹 정책 / c45f3b0 Google 탈퇴 / 95211c0 빌드5 / 1d13cf8 UIScene / 3724a9a 세로 방향 / 376f375 네이버 오류 / 4d3790c 네이버 SDK / 4d5edf1 로컬 API 주소.
  - 코드 보존/정리: 초기 binary patch에 대해 lib/test/ios/pubspec 범위의 역방향 적용 check가 통과해 기존 변경이 보존됐음을 확인했다. 새 vendor 원본에서 확인된 줄 끝 공백14곳(Gradle/Swift3파일)만 제거하고 출처 README·ADR·컨텍스트에 명시했다. 해당 Swift2파일 parse·podspec Ruby 구문·Info.plist lint도 통과했다. 로컬 API 안내를 실제 상수172.30.1.93에 맞췄다. 기능 동작의 추가 변경은 없다.
  - 테스트: 최종 작업 트리의 전체 Flutter559 pass·기존 skip1. GROUP_API_ENABLED/GROUP_P1_ENABLED=true의 친구 목록+그룹 전체45 pass. 전체 분석 error/warning0, 기존 미변경4파일 naming info26건으로 분석 종료코드1이며 무관 소스를 변경하지 않았다. 변경/신규 앱·테스트·렌더 Dart72개 포맷 변경0건, 측정JSON9개 파싱·PNG232개 signature/양수치수 확인, 전체 및 각 커밋 diff 공백 검사 통과. 기존 실기기/빌드 검증 이력은 보존하며 이번 작업에서 다시 빌드/설치하지 않았다.
  - 실행: `flutter test --no-pub --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=commit-validation-test-key --reporter=expanded`; 활성 그룹은 같은 define에 `test/features/friend/presentation/pages/friend_list_page_test.dart test/features/group --dart-define=GROUP_API_ENABLED=true --dart-define=GROUP_P1_ENABLED=true`; `flutter analyze --no-pub`. Flutter SDK 캐시 접근 권한으로 실행했고 로그·분리 계획·메시지·원본 patch는 /private/tmp/shiftmate-commit-split-20261116에 보관한다. 새 영구 파일은 이번에 추가하지 않았다.
  - 푸시/검증: 일반 `git push --set-upstream origin develop` 성공, 로컬HEAD=origin/develop=4d5edf174079c5f4bfe0cc2c43454e456516488a를 확인했다. 본 최종 문서 커밋까지 추가 push 후 원격HEAD 일치·작업 트리 clean을 다시 확인한다. main 병합·서버/스토어 배포는 이번 범위에 없다.
  - 롤백: 필요한 작업 커밋을 의존성 역순으로 git revert한다. 분리 전 작업/인덱스 patch와 vendor 공백 정리 전 사본은 위 임시 폴더에 보존한다. Git 일시 잠금은 파일이 사라진 것을 확인한 후 재실행했으며 잠금 파일을 강제로 삭제하지 않았다.

## 2026-11-16 로컬 디버그 API 주소 동기화

- [DONE] (FE/DEV) 기존 로컬 서버 주소 변경을 별도 커밋으로 정리한다.
  - 목적: 로컬 디버그 실행 주소와 실제 코드의 불일치를 해소한다.
  - 변경/영향: 기존 ApiConstants.base_url_local의 172.30.1.14→172.30.1.93 변경과 PROJECT_CONTEXT의 실행 안내를 함께 반영한다. USE_LOCAL_API 조건과 Stage/Production 주소는 유지한다.
  - 테스트: 전체 Flutter 559 pass·기존 skip 1, 전체 분석 error/warning 0·기존 미변경 naming info 26건 및 diff 공백 검사. 실제 로컬 서버의 현재 가용성은 이번에 검증하지 않았다.
  - 롤백: 이 커밋의 상수/문서 변경만 git revert한다.

## 2026-11-16 네이버 탈퇴→재가입 반복 재현 원인 추적

- [DONE] (FE/Auth) 네이버 탈퇴 후 SDK 재가입 -1005를 실제 재현하고 수정 SDK5.2.1 적용 후 사용자 해결 확인.
  - 목적: 이전 변경은 오류 안내만 개선했으며 반복 실패의 근본 원인은 해결하지 못했으므로, SDK 탈퇴/로그아웃/다음 로그인과 서버 도달을 구분한다.
  - 범위: 코드/공식 SDK 근거·실제 디버거 상태로 확인한 원인에 대해서만 관련 로직을 수정한다. 임의 대기/자동 재시도·패키지 변경으로 덮지 않는다.
  - 테스트: 사용자 실계정 재현의 단계·오류 코드·토큰 존재 여부만 관측하고 원문 credential을 저장/출력하지 않는다. 원인 수정 후 관련 회귀·분석·문서를 갱신한다.
  - 롤백: 이번 진단 중단점·원인 수정 diff만 제거하고 기존 미커밋 작업과 계정 데이터를 보존한다.
  - 준비(사용자 후속 요청): 실계정 재현용 SDK 로그인 반환55행·연결 해제 반환123행·서버 로그인 호출129행·탈퇴202 수신 후317행에 Flutter BP4개를 정리했다. 서버는 기존 진입814행을 보존하고 오류767행/성공785행을 추가한다. 양쪽 로컬 세션의 실행 상태·BP 목록을 확인하며 아직 새 실패 실행값은 관측하지 않았다. 재현 중 BP는 의도적으로 유지하고 결과 확인 후 이번 BP만 제거한다.
  - 공식 근거 확인: 현재 Podfile.lock의 NidThirdPartyLogin5.1.0과 동일한 로그아웃→재로그인 -1005가 네이버 공식 issue6에 보고되어 있으며, 공식5.2.0 release notes는 네이버앱 복귀 직후 -1005 수정을 명시한다. 현재 기기에서의 동일 원인 여부는 재현과 구분한다. SDK/lock/native/Flutter 의존성은 이번 준비에서 변경하지 않았다. 근거: https://github.com/naver/naveridlogin-sdk-ios-swift/issues/6 및 https://github.com/naver/naveridlogin-sdk-ios-swift/releases/tag/5.2.0 .
  - 재현 진행: 사용자가 이번 로컬 탈퇴 성공을 확인했다. 이는 사용자 관측이며 worker 물리 삭제 완료/다음 SDK 재가입 성공을 의미하지 않는다. 다음 재가입의 SDK 반환·서버 경계를 기다린다.
  - 실제 재가입 관측: NaverLoginService.loginWithNaver55행에 정지했다. 디버거에서 sdk_status=error, has_access_token=false, errorMessage의Code=-1005 포함=true, 네이버 token endpoint 포함=true를 boolean만 평가해 확인했다. Repository126행 await 이전의 실패라 이번 요청은 서버 로그인 호출129행에 도달하지 않았다. 원문 credential은 읽거나 출력하지 않고 검사 후 실행을 재개했다.
  - 수정 계획 확정: 공식 plugin4.0.0은 Flutter>=3.44.0이므로 현재3.38.5에서 직접 업그레이드할 수 없다(pub.dev 배포 메타데이터·공식 소스 확인). 공식3.0.4의 Dart/Android/Swift 호출 코드는 유지하는 저장소 로컬 호환 패키지로 네이티브 iOS 의존성만5.2.1 및 iOS15로 고정한다. 기존 앱 최소iOS15와 일치한다. 라이선스/출처/원본 대비 변경·복원 방법을 기록하고 lock·실제 iOS build를 검증한다. Flutter SDK 전체 업그레이드는 이번 범위에 포함하지 않는다.
  - 구현/검증 진행: 공식3.0.4 원본으로 로컬 호환 패키지를 구성해 app path dependency·pub lock을 반영했고 네이티브SDK5.2.1로 pod lock을 갱신했다. 커밋 정리 전 기존 Dart/bin/Android/Swift/Resources 소스21개는 원본과 byte 단위 동일함을 확인했다. 커밋 정리 과정에서 Android Gradle·Swift 3파일의 줄 끝 공백14곳만 제거했으며 줄 끝 공백을 제외한 원본 소스는 동일하다. package 메타데이터/CocoaPods·SPM iOS15·SDK exact pin 및 생성물 제외/출처 문서만 조정했다. 인증125개 통과·전체 analyze error/warning0/기존 미변경26개 naming info, Ruby podspec 구문·diff 검사 통과. 실제 unsigned Debug iOS build22.7초 성공, Runner.app에 포함된 NidThirdPartyLogin.framework 버전5.2.1/최소iOS15를 확인했다.
  - 의존성 범위: Dart lock 변경은 네이버1개뿐이다. Pod 버전 변경도 Nid5.1.0→5.2.1뿐이며 AppAuth/GTMAppAuth/GoogleSignIn의 checksum 변경은 로컬 캐시 전후 spec JSON 비교로 deprecated:true 메타데이터 추가만 확인했다. 첫 pod repo 갱신은 무관한 Firebase spec의 CDN HTTP2 오류로 실패했으나 네이버 spec이 갱신된 캐시를 사용한 --no-repo-update 재실행으로 정상 완료했다. pod 갱신 완료 전 최초 build는 구 lock 충돌로 중단됐고 갱신 완료 후 실제 build를 재실행해 통과했다.
  - 기기 적용 진행: 네이티브 변경은 hot reload로 바뀌지 않으므로 기존 로컬 iPhone 디버그 세션을 중지하고 같은 ShiftMate(debug local) 구성으로 전체 실행을 시작했다. main60행 startup BP를 추가했다. 서명/설치·새 세션과 실제 재가입 성공은 별도 확인 후 기록한다. 기존 Release6·스토어 Archive/IPA는 수정하지 않았다.
  - 기기 새 실행 확인: 기존 세션 종료 후 같은 iPhone에서 새 debug local 세션이 main60행에 도달했다. 새 세션 ID로 구분하고 startup BP를 제거해 실행을 재개했다. Dart define USE_LOCAL_API=true를 확인한다. 실제 사용자 네이버 재가입 결과는 아직 관측 전이다.
  - 실계정 인수 완료: 새5.2.1 앱으로 네이버 재가입을 요청한 뒤 사용자가 “해결됐음”을 확인했다. 수정 전 SDK 오류 실제 관측과 수정 후 같은 iPhone 새 실행/사용자 확인을 근거로 이번 로컬 문제 해결로 기록한다. 여러 회차·다른 기기/Release/스토어 배포 성공까지 확장해 주장하지 않는다. 양쪽 디버그 세션은 running이고 진단 BP는 이미 제거된 상태(목록0개)를 확인했다. 제거되어 있던 사용자 BP를 임의 재생성하지 않았다.
  - 최종 문서/출처: ADR-0085·PROJECT_CONTEXT·vendor README에 역할/의존성/사용 예·재평가·롤백을 기록했다. 공식 archive SHA-256이 이전 hosted pubspec.lock 값과 같음을 확인했고 원본 라이선스를 유지했다. Git 제외된 생성 lock/cache는 포함하지 않는다. 관련 diff/구문 검사를 완료했으며 커밋/푸시·스토어 Archive/IPA 생성·업로드/운영 배포는 하지 않았다.

## 2026-11-16 네이버 탈퇴 후 재가입 SDK 연결 오류

- [DONE] (FE/Auth) 네이버 token 발급 중 NSURLErrorDomain -1005 및 SDK 오류 원문 노출 처리.
  - 목적: 사용자 캡처의 nid.naver.com/oauth2.0/token 연결 유실과 서버 계정 충돌 응답을 구분하고 사용자용 재시도 안내로 변환한다.
  - 변경/영향: 기존 NaverLoginService·관련 회귀·문서만 수정하고 SDK/lock·서버/DB·탈퇴 접수 정책과 기존 미커밋 작업은 보존한다.
  - 테스트: 실제 설치 SDK 오류 전달 경로 확인, 수정 전 동일 오류 주입 재현, 서비스/Repository/Provider 테스트·Dart 분석·포맷 확인. 실기기 네트워크 유실의 근본 원인은 캡처만으로 확정하지 않는다.
  - 롤백: 이번 네이버 오류 처리·테스트·문서 추가분만 되돌린다.
  - 원인/변경: naver_login_flutter3.0.4의 iOS requestLogin 실패가 localizedDescription을 errorMessage로 반환하고 NaverLoginService가 그대로 Exception으로 전달해 다이얼로그까지 노출했다. SDK error 결과/PlatformException을 공통 ApiException으로 변환해 NAVER_NETWORK_ERROR·취소·토큰 미수신·일반 실패를 구분한다. 원문 URL/진단/token은 표시/저장/추가 로깅하지 않는다. 네이티브 재시도/SDK 교체/토큰 재전송·로그아웃/연결 해제 변경은 없다.
  - 재현/검증: 수정 전 실제 서비스에 캡처와 같은 SDK 오류를 주입한 임시 probe1개로 원문 전파를 확인했다. 새 회귀7개가 수정 전에 실패하고 기존8개는 통과했다. 수정 후 인증 기능 전체124개 통과, 최종 MethodChannel→실제 NaverLoginService→Provider→CupertinoAlertDialog의 안내·원문 비노출·로딩 해제·버튼 재시도를 포함한 서비스/페이지28개 통과, 변경 Dart3개 analyze 진단0·format/범위 diff 검사 통과다. SDK/API는 대체되므로 실제 네트워크 유실 해결·실계정 재가입 성공을 증명한 것은 아니다.
  - 디버거/한계: 실행 중인 로컬 iPhone 세션과 SDK 오류 분기BP를 확인했다. 테스트 debugAtCursor는 BP에 도달하지 않아 live 오류 값을 관측했다고 기록하지 않는다. 실제 원문 전달은 수정 전 실행 probe와 회귀로 재현했고 진단 BP를 제거해 기기 세션은 실행 상태로 유지했다. Apple QA1941의 -1005 정의만 원인 분류에 사용하며 연결이 끊긴 구체적 이유·탈퇴와의 인과관계는 미확정이다.
  - 파일/역할/산출물: 기존 naver_login_service.dart·naver_login_service_test.dart·login_page_test.dart와 PROJECT_CONTEXT·DECISIONS ADR-0084·WORKLOG만 이번 범위다. 신규 영구 파일/의존성/env/SDK/DB 변경은 없다. /private/tmp/shiftmate-naver-network/의 before 서비스 복사본·reproduce_test.dart·before-test.log/regression-before.log는 수정 전 재현, auth-after.log/final-tests.log/analyze.log는 실행 검증 자료이며 Flutter3.38.5·기존 lock·실제 서비스에 의존한다. probe는 flutter test로 실행하며 진단 자료는 커밋하지 않는다.
  - 적용 상태: 앱 소스 수정 완료이며 실기기 hot reload/새 빌드 설치·실계정 네이버 재가입 성공은 이번에 확인하지 않았다. 기존 iOS Release6·심사 Archive/IPA·Google/서버 수정과 staged 작업은 보존하고 커밋/업로드/배포는 하지 않았다.

## 2026-11-16 iPad 가로 창 전환 제한 조사

- [DONE] (iOS/UI) iPhone·iPad 세로 방향 고정 및 실물 iPad 창 resize 후 세로 유지 확인.
  - 목적: 사용자 요청에 따라 iPad에서 세로 화면을 유지할 수 있는지 확인한다. 후속 답변에서 iPhone·iPad 모두 세로 고정을 확정했다.
  - 근거/범위: 현재 Info.plist의 기본 및 ~ipad 방향 배열에 landscape가 있다. Apple의 최신 안내는 resizable 환경에서 방향 설정이 선호값일 수 있으며 UIRequiresFullScreen 호환 모드가 내부 scene 크기를 유지할 수 있음을 설명한다. 실제 동작 검증 없이 차단 완료로 표시하지 않는다.
  - 변경: 기존 Info.plist의 기본/~ipad 방향 배열을 portrait 한 개로 제한하고 UIRequiresFullScreen=true를 추가했다(Behavior change, ADR-0083). Flutter/Android 코드·기기군·SDK/lock·버전·UIScene 크래시 수정은 유지한다. 영구 신규 파일은 없다.
  - 테스트/결과: 같은 운영 define·CLI build6의 `flutter build ios --release --no-pub --dart-define-from-file=.env --build-name=1.0.0 --build-number=6` 성공(17.5초). 실제 Release bundle의 기본/~ipad 방향 배열이 portrait 하나이고 UIRequiresFullScreen=true·기존FlutterSceneDelegate·iPad profile 포함을 확인했다. deep/strict codesign·plutil lint·변경 코드/문서 공백 검사 통과. 빌드5 Archive/IPA 해시·pubspec5를 보존했다. 단순 native 설정 변경이라 구현을 반복하는 신규 테스트/전체 Flutter 테스트는 추가하지 않았다.
  - 실기기 결과: iPad Pro12.9형5세대 / iPadOS26.5.2에 검증한 Release-iphoneos/Runner.app을 업데이트 설치하고 재실행했다. 사용자가 창을 가로로 넓힌 뒤 ‘세로 화면으로 유지됨’을 답했다. 캡처에서도 세로 로그인 UI, resize 후Runner PID717 유지를 확인했다. 이번 변경 이후 로그인 성공을 새로 인수한 것은 아니다. iPhone 회전·iOS27.3 실기기 resize는 미검증이며 두 플랫폼의 실제 bundle 설정만 공통으로 확인했다.
  - 도구/한계: resizable app CLI는 연결된26.5.2 실기기에서 capability 미지원이라 사용자 직접 resize/화면으로 확인했다. sandbox의simctl help 접근 오류 후 별도 시뮬레이터 실행은 하지 않았다. UI/UX Pro Max 검색0건을 OS 동작 근거로 쓰지 않고 Apple 공식 문서를 사용했다. 창 크기 조절 손잡이 자체를 제거했다고 설명하지 않는다.
  - 파일/자료 역할: 기존 Info.plist만 제품 설정을 수정했고 PROJECT_CONTEXT·ADR-0083·출시 체크리스트를 갱신했다. `/private/tmp/shiftmate_portrait_20261116/`의 Info.before.plist·Runner.before.app은 변경 전 설정/직전 USB 앱 복원용, build.log는 빌드 출력, verification.json은 방향/scene/profile 검증, install.json·launch.json·process-after-resize.json은 기기 실행 근거, after-resize.png는 실제세로화면 캡처다. 현재 소스/.env/Xcode·개발 profile에 의존한다. 이전 USB 설치/실행 명령으로 재현하며 진단/캡처는Git에 추가하지 않는다. 신규 영구 파일은 없다.
  - 롤백: 이번 방향/창 설정과 문서 추가분만 되돌린다. 기존 소스·로그인/캘린더 데이터·빌드5 심사 산출물을 유지한다.

## 2026-11-16 USB iPad Release 실행 확인

- [DONE] (iOS) 개발자 모드를 켠 실물 iPad에 UIScene 수정본 Release 1.0.0(6) 설치·실행·네이버 로그인·완전 종료 후 복원 확인.
  - 목적: 사용자 요청에 따라 TestFlight 없이 USB 실기기에서 앱 시작을 확인한다.
  - 대상/범위: iPad Pro 12.9-inch (5세대), iPadOS 26.5.2, USB 페어링·Developer Mode Enabled를 확인했다. 심사 iPadOS 27.3/M3와 다른 환경이다. 현재 소스로 운영 define의 Release 앱을 만들고 대상 iPad에만 설치한다.
  - 변경/영향: 앱 소스/SDK/lock/기기군·스토어 설정은 변경하지 않았다. CLI 빌드 번호6을 실기기 검증용으로 주입했고 pubspec은1.0.0+5를 유지한다. 기존 빌드5 Archive/IPA 해시도 보존했다. 대상 iPad의 개발용 자동 서명/프로비저닝을 갱신하고 동일 Bundle ID 앱을 설치했다. 앱/서버 데이터 삭제는 수행하지 않았다. WORKLOG·PROJECT_CONTEXT·APP_STORE_RELEASE_CHECKLIST에 이번 실행 결과를 기록하며 설계 변경이 없어 추가 ADR은 없다.
  - 빌드/서명: `flutter build ios --release --no-pub --dart-define-from-file=.env --build-name=1.0.0 --build-number=6` 성공(44.7초). 최초 일반 device 빌드의 개발 profile에는 새 iPad가 없어, `xcodebuild build -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -destination 'id=<대상 iPad UDID>' -allowProvisioningUpdates -allowProvisioningDeviceRegistration SYMROOT=<프로젝트>/build/ios`로 대상 기기 등록/자동 서명을 갱신했다. 최종 profile의 기기 포함·codesign deep/strict·빌드6·단일 FlutterSceneDelegate·기기군[1]·AOT instruction symbol/커널 blob 부재를 확인했다.
  - 설치/실행: 문서의 과거 Debug 산출물 혼동을 피하고 검증한 `build/ios/Release-iphoneos/Runner.app`을 devicectl install app으로 직접 설치했다. 기기 앱 목록에서도1.0.0(6)을 확인했다. 첫 launch PID571 유지와 네이버 인증 화면을 관찰했고, 사용자가 직접 로그인을 완료하여 캘린더 표시를 보고했다. 이후 `device process launch --terminate-existing`로 완전 종료/재실행한 PID668과 실제 캘린더·로그인 세션 복원 화면을 확인했다. 디버거/console attach 없이 직접 실행했다.
  - 자료 역할/의존성/사용 예: `build/ios/Release-iphoneos/Runner.app`은 현재 소스·.env defines·Xcode 개발용 provisioning에 의존하는 USB 설치용 AOT 앱이다. `xcrun devicectl device install app --device <UDID> build/ios/Release-iphoneos/Runner.app`으로 설치하고 `device process launch --device <UDID> --terminate-existing com.hspark.shiftmate`로 시작한다. 기존 `build/ios/iphoneos/Runner.app` 경로의 산출물을 검증 없이 쓰지 않는다. 새 영구 소스 파일은 없다.
  - 로컬 진단 자료: `/private/tmp/shiftmate_ipad_release_20261116/`의 build.log·device-signing-build.log는 빌드 출력, verification.json은 비밀값 없는 패키징 검증, install.json·installed-app.json은 설치 결과, launch-*.json·process-*.json은 실행/PID 확인 결과, after-restart.png는 실제 재실행 화면이다. 원본 인증 화면 캡처는 확인 후 삭제한다. 기기/계정 정보가 있을 수 있어 진단 자료는 Git에 추가하지 않는다.
  - 검증 범위/한계: 운영 Dart API/Firebase/OAuth 설정을 사용하지만 개발 서명이라 APNs entitlement는development다. App Store Distribution/production APNs 검증과 구분한다. 실물 iPadOS26.5.2에서 시작·네이버 인증·완전 종료/세션 복원만 확인했다. iPadOS27.3 실기기·나머지OAuth·푸시 수신/탭·홈 전환 복귀·스토어 배포 경로는 새로 검증하지 않았다. 앞선iOS27.0 시뮬레이터 테스트1/Flutter16 pass 결과를 유지하며 이번에는 불필요하게 반복하지 않았다.
  - 마무리: 기존 IPA SHA-256 `23d38e5dbf81bd4a268785f5608c46d81d7d9d92588d8c05fc7642caa2295204`·Archive build5·pubspec5 보존을 확인했다. 재제출용 IPA6 생성/업로드는 수행하지 않았다. 문서 공백 검사를 확인한다.
  - 롤백: 이번 로컬 build6 앱과 문서 추가분만 제거한다. 소스 변경/기기 데이터 삭제는 없으며 설치 앱 복구가 필요하면 이전 개발 서명 빌드를 재설치한다. 개발자 모드/페어링·등록된 기기는 사용자 테스트 설정으로 유지한다.

## 2026-11-16 App Review 빌드 5 실행 크래시 확인

- [DONE] (iOS) 첨부 크래시 로그 2건 대조·UIScene 원인 재현·수정 및 시뮬레이터 검증.
  - 목적: 사용자 제공 Downloads의 두 .ips에서 동일한 `EXC_BREAKPOINT/SIGTRAP`, UIKit `___UIApplicationEvaluateRuntimeIssueForNoSceneLifecycleAdoption_block_invoke`를 확인했다. Runner UUID는 보관 빌드5와 일치한다.
  - 변경/영향: Info.plist에 단일 FlutterSceneDelegate/Main storyboard 설정을 추가하고 AppDelegate의 플러그인 등록을 didInitializeImplicitFlutterEngine(engine_bridge.pluginRegistry)로 옮겼다. 기존 RunnerTests의 자리표시자 테스트는 실제 Scene/FlutterViewController/주요 8개 플러그인 등록 검사로 교체했다. 설치 Flutter 3.38.5 헤더·migration·엔진 fallback 코드와 네이버/Google/Kakao callback 등록 코드를 직접 확인했다. Dart 코드·패키지/SDK·기기군·버전 번호는 변경하지 않는다. 파일 역할/의존성/실행 예는 PROJECT_CONTEXT 상단, 결정은 ADR-0082에 기록했다.
  - 심볼 결과: 원본 2건을 Xcode CrashSymbolicator.py와 기존 Archive/dSYMs로 처리해 Runner의 AppDelegate.main 프레임을 복원했다. 최상단 UIScene 검사 함수는 원본부터 식별되며 UIKitCore +3526812의 시스템 프레임 1곳은 OS 심볼 부재로 남는다. 완전 심볼리케이션으로 표시하지 않는다. 원본 로그는 읽기 전용이며 저장소에 복사/커밋하지 않는다.
  - 재현/네이티브 검증: Xcode27.1 / iOS27.0 iPad Air 11-inch(M4) 시뮬레이터. 수정 전 실행에서 `Application failed to launch: UIScene life cycle is required for apps built with this SDK`를 재현한 뒤 테스트 runner 대기/재시도를 중단했다(종료75, 테스트 통과로 세지 않음). 동일 구성의 수정 후 `xcodebuild test` → **TEST SUCCEEDED**, 네이티브 1 test / 0 failures. Scene 생성과 8개 플러그인 등록, Dart VM 시작, /app/version-policy 응답200을 확인했다. 초기 홈 화면 캡처는 앱 화면 검증 증거로 쓰지 않는다.
  - Flutter 검증: `flutter test --no-pub --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=release-preflight-test-key test/widget_test.dart test/core/push test/core/utils/korean_holidays_test.dart test/features/app_update/app_update_test.dart --reporter expanded` → 16 pass / 0 fail. plutil Info.plist lint와 이번 코드/문서의 git diff HEAD --check 통과. Dart 변경이 없어 전체 분석/전체 테스트를 반복하지 않았다. 네이티브 빌드의 기존 의존 패키지 deprecation 등의 warning은 이번 앱 소스에서 생긴 진단이 아니며 패키지를 수정하지 않았다.
  - 로컬 자료 역할/의존성/사용 예: `/private/tmp/shiftmate_scene_20261116/`의 before.log는 수정 전 실행 재현, after-ipad27.log·after-ipad27.xcresult는 Xcode native test 결과, flutter-tests.log는 Flutter 16개 회귀 출력, symbolicated-7C82.ips·symbolicated-31BF.ips는 Apple CrashSymbolicator 결과다. Xcode 결과는 `open /private/tmp/shiftmate_scene_20261116/after-ipad27.xcresult`로 확인한다. 빌드의 DerivedData/Products 및 홈 화면 캡처는 검증 후 정리하며 비밀값이 포함될 수 있는 진단 로그는 Git에 추가하지 않는다.
  - 환경/한계: 실행 중 호스트 여유 공간 약100MB와 테스트 완료 후 시뮬레이터 종료 상태를 관찰했다. 최종 로그/종료0으로 네이티브 통과를 확인했고 이번 임시 DerivedData 약1.4GB를 정리했다. 실제 심사 OS27.3/M3 실기기·Release 배포 실행·OAuth/푸시/복귀 인수·새 IPA/업로드/재제출은 미수행이다. 로컬 테스트 결과와 분리한다.
  - 롤백: 이번 AppDelegate·Info.plist scene 설정·RunnerTests·문서만 되돌린다. 기존 미커밋 변경과 빌드5 Archive/IPA는 유지하며 원래 시작 크래시가 재발할 수 있다.

- [DONE] (iOS/REVIEW) Guideline 2.1(a) 통지와 로컬 빌드/심볼의 1차 확인. 크래시 해결 완료가 아니다.
  - 목적: 제출 ID `b445e709-c2ae-4c17-ba7d-f3f476305e13`, 1.0(5), iPad Air 11-inch(M3) / iPadOS 27.3에서 실행 직후 종료되었다는 심사 통지를 확인한다.
  - 범위: 프로젝트 문서·앱 시작 경로·기존 Archive/dSYM·크래시 로그 유무를 읽기 전용으로 확인한다. 로그 없는 원인 추정에 따른 코드 변경은 하지 않는다.
  - 테스트/결과: 작업 폴더 전체 .ips/.crash 검색0건. Archive1.0.0(5)·SDK27.1·최소iOS15·기기군[1], IPA크기24,755,597bytes·기존SHA-256 일치·env asset 존재 확인. dwarfdump로 Runner/App 바이너리와dSYM의UUID 일치 확인(PROJECT_CONTEXT 상단). AppDelegate·main·Firebase/공휴일 초기화 경로를 직접 읽었으며 종료 원인은 미확정이다.
  - 환경/한계: 최초sandbox의CoreSimulatorService 접근 실패 후 읽기 전용 기기 목록 조회를 허용받아 성공했다. 로컬 시뮬레이터OS17.4/18.3/27.0/27.1 중 심사OS27.3은 없고 연결된 실물iPad도 없다. 이번에는 앱 빌드/설치/실행·디버깅·심볼리케이션·테스트를 수행하지 않았다. 코드 변경이 없어 신규 회귀 테스트/ADR은 없다.
  - 변경/문서: WORKLOG·PROJECT_CONTEXT·APP_STORE_RELEASE_CHECKLIST에 전달받은 거절 통지와 확인 결과/미완료 후속을 기록했다. 앱 코드·설정·빌드 번호/기존 산출물은 변경하지 않았다. Apple 공식 심볼리케이션/일반 크래시 조사 문서도 확인했다.
  - 롤백: 이번 조사 기록만 제거한다. 기존 미커밋 변경과 빌드 산출물은 유지한다.
  - 다음: 원본 크래시 로그 확보 후 UUID 일치 확인·심볼리케이션·원인 재현·수정·호환 기기 실행 검증을 진행한다.

- [TODO] (iOS/REVIEW) 실제 심사 OS27.3 Release 호환 기기 인수 및 새 빌드 검증/재제출.
  - 선행 완료: 원본 로그 확보·빌드 심볼 대조·UIScene 원인 규명·수정 전 재현·수정 후 iPad 시뮬레이터 테스트.
  - 완료 조건: Release 실기기 시작/복귀·OAuth·푸시 인수, 새 빌드 번호의 IPA 생성·업로드/선택·재제출. 현재 재제출/심사 통과 완료로 표시하지 않는다.

## 2026-11-14 심사 재제출용 iOS 빌드

- [DONE] (RELEASE) 현재 작업 트리로 App Store용 1.0.0(5) IPA 생성·검증
  - 목적: 사용자 요청에 따라 심사 재제출에 사용할 최신 앱 바이너리를 준비한다.
  - 변경/영향: 기존 미커밋 변경을 포함해 Release 운영 설정으로 빌드했다. `pubspec.yaml` 빌드 번호4→5, 스토어 버전1.0.0·Release API 호환 번호1 유지. 기존 빌드4의 해시·Archive 버전을 확인한 뒤 `build/ios/releases/1.0.0-4/`에 IPA/Archive를 보존했다. 신규 기능/설계 변경이 없어 ADR 추가는 없다.
  - 실행/산출물: `flutter build ipa --release --no-pub --dart-define-from-file=.env --build-name=1.0.0 --build-number=5 --export-method=app-store` 성공(Archive46.5초·IPA58.4초). `build/ios/archive/Runner.xcarchive`(Runner/App dSYM 포함), `build/ios/ipa/ShiftMate.ipa` 24,755,597bytes·SHA-256 `23d38e5dbf81bd4a268785f5608c46d81d7d9d92588d8c05fc7642caa2295204`. 산출물 역할/의존성/사용 예는 PROJECT_CONTEXT 상단, 재제출 상태는 APP_STORE_RELEASE_CHECKLIST 상단에 기록했다. APP_VERSION_POLICY 현재 빌드 번호도5로 갱신했다.
  - 테스트: 전체 `flutter test --no-pub --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=release-preflight-test-key --reporter expanded` →551 pass·기존 skip1. 전체 `flutter analyze --no-pub` →error/warning0·기존 미변경4파일 naming info26건으로 종료코드1. 무관 소스는 수정하지 않았다. IPA ZIP CRC·Apple Distribution deep/strict·App Store provisioning·production APNs/Apple 로그인·운영 API/Firebase/OAuth·URL scheme 치환·Stage/로컬 API 부재·1.0.0(5)/Bundle ID/iPhone전용/iOS15/SDK27.1 검증 통과. 기존 기본 LaunchImage placeholder 안내1건 유지.
  - 실행 환경 확인: sandbox에서 Flutter SDK engine.stamp 쓰기와 codesign 신뢰 저장소 접근이 제한되는 현상을 확인했고, 허용된 SDK/신뢰 저장소 접근으로 재실행해 빌드/서명 검증을 통과했다. 인증서/키체인 신뢰 설정 자체는 변경하지 않았다.
  - 로컬 검증 자료 역할/의존성/사용 예: `/private/tmp/shiftmate_release_20261114_tests.log`·`analyze.log`·`build.log`는 해당 Flutter 명령 출력이다. `/private/tmp/shiftmate_release_20261114_verify.py`는 Python표준라이브러리·macOS codesign/security에 의존해 추출 IPA를 검사하며 루트에서 `python3 /private/tmp/shiftmate_release_20261114_verify.py`로 실행한다(신뢰 저장소 접근 필요). 같은 prefix의 `verification.json`은 비밀값 없는 검사 결과/해시다. 추출본은 `/private/tmp/shiftmate_release_20261114_pst3c1cq/`다. 임시 로컬 자료이며 Git에 추가하지 않는다.
  - 롤백: 이번 버전/문서 변경만 복원하고 새 빌드5 산출물을 제거한다. 기존 소스 작업·환경/lock·보존한 빌드4는 유지한다.
  - 다음/한계: 업로드·Connect 처리/선택·심사 재제출·실기기/실계정 인수는 미수행. 운영 서버/스토어 설정과 개인정보 선언은 변경/재검증하지 않았다. 이번 작업은 로컬 빌드 준비까지다.

## 2026-11-13 Google 선택 전화번호 권한과 사진 수집 중단 연동

- [DONE] (FE/Auth) Google ID Token과 선택 전화번호 access token을 서버에 전달한다.
  - 목적: 사용자 요청에 따라 서버가 Google 사진을 신규 저장하지 않고, Google 제공 번호를 가입 화면에 미리 채우도록 한다.
  - 변경/영향: SDK의 계정별 authorizationClient·선택 동의 실패 fallback·Repository/DataSource 전송만 변경한다. 기존 가입 화면의 user.phone 미리 채움·사진 null 아바타와 탈퇴/로그아웃을 보존한다.
  - 테스트/결과: Google 서비스/저장소/DataSource·프로필 화면4파일70 pass 이후 신규 Google 가입 미리 채움 회귀를 포함한 인증 기능 전체117 pass/0 fail. 선택 동의 취소/권한 오류/빈 token fallback·서버 전송/phone 파싱·사진 null 아바타·기존 JWT 저장/실패 정리·가입/로그아웃/탈퇴를 확인했다. 변경 Dart7개 최종 analyze 진단0건·format 변경0건·관련 코드/문서 diff 공백 검사를 통과했다.
  - 수정 중 확인: 새 위젯 테스트가 화면 전체 person_fill 아이콘2개를 세어 실패한 것을 실제 profile_avatar 내부로 검증 범위를 좁혀 해결했다. 제품 화면은 변경하지 않았다.
  - 문서/설계: PROJECT_CONTEXT·ADR-0081·GOOGLE_SIGN_IN_SERVER_GUIDE의 현행 계약을 갱신했다. 신규 영구 파일/패키지/env/route/provider 수명·DB 변경은 없다.
  - 커밋 분리 검증: 원격 main 기준의 별도 작업 트리에 Google 전화번호 변경만 구성했다. 기존 iOS 탈퇴/다른 UI 미커밋 변경은 제외하고 서비스·테스트의 필요한 PlatformException import를 명시했다. 이 독립 소스 기준 인증 전체105 pass/0 fail·변경 Dart7개 analyze 진단0·format 변경0·diff 검사 통과다. 앞선117개는 기존 다른 로컬 작업이 포함된 작업 트리의 결과이며 구분한다.
  - 커밋/병합: 전화번호 변경은 기존 원격 커밋 `850e45d`로 origin/develop에 반영되어 있고 origin/main에는 `dff95c1`로 병합되어 있음을 2026-11-16 fetch 후 확인했다. 실제 앱 바이너리 배포/스토어 업로드는 수행하지 않으며 서버 배포 후 현재 앱 소스를 재빌드/설치해 테스트해야 한다.
  - 한계: 실제 Google API와 네이티브 동의 화면은 mock 경계 밖이므로 Stage iOS/Android 실계정 인수가 남는다. 서버 SQL 변경은 없다.
  - 롤백: 이번 Google 변경만 되돌리고 기존 미커밋 작업과 저장된 사용자 번호/사진은 유지한다. 작업 전 사본은 /private/tmp/shiftmate_google_phone_20261113/before다.

## 2026-11-13 Google 회원 탈퇴 iOS HTTP 400

- [DONE] (FE) Google 연결 해제 전 세션 복원·갱신 및 재인증/오류 처리
  - 목적: Google SDK HTTP 400으로 서버 탈퇴 요청이 중단되고 예외 원문이 표시되는 문제를 해결한다.
  - 변경/Behavior change: iOS는 SDK lightweight authentication으로 세션 복원·필요 시 token 갱신 후 User.google_id와 복원 account.id가 일치할 때만 disconnect한다. 세션 부재/불일치·원시 com.google.HTTPStatus: 400은 전용 예외로 기존 다시 로그인 안내에 연결한다. 기타 SDK 오류는 안전한 한국어 메시지, 예상 밖 탈퇴 오류도 고정 문구로 표시한다. 해제 실패를 성공으로 간주하지 않으며 서버 요청/로컬 JWT 삭제를 진행하지 않는다. 사용자의 다시 로그인 선택으로 로그아웃하고 전체 로그인 후 다시 탈퇴 확인을 받는다.
  - 범위/파일: 기존 google_login_service.dart·auth_repository_impl.dart·auth_provider.dart와 관련 기존 테스트4개 및 PROJECT_CONTEXT/ADR-0080/이번 일지다. 신규 영구 파일/패키지·UI 배치/라우트/테마/analytics·서버 API/DB/env는 없다. Android 직접 해제·ApiException/request_id·202/401/진행 중 처리·계정 캐시 정책은 유지하며 SDK 복원은 ShiftMate JWT auth_time을 바꾸지 않는다. 기존 미커밋 변경은 보존했다.
  - 근거/재현: 설치된 google_sign_in7.2.0/google_sign_in_ios6.3.0/GIDSignIn.m의 disconnect와 restore 코드를 직접 읽고 Google 공식 복원/해제 문서와 대조했다. 보관한 수정 전 실제 서비스에 제보와 같은 PlatformException을 주입해 원문 전파를 재현했다(probe1 pass). 실제 Google 응답 body/token 상태는 미확인이므로 제보 원인이 만료라고 확정하지 않는다.
  - 테스트/결과: 관련4파일44 pass, 인증 기능 전체111 pass/0 fail. 추가 회귀는 만료 모의 세션의 복원→해제 순서/대화형 인증 미호출·계정 부재/불일치의 해제 차단·400 재인증·initialize/restore/disconnect 기타 SDK 오류 비노출·서버 미호출/JWT 보존·provider 로딩 종료·설정 안내에서 로그인 화면 이동을 검증했다. 변경 Dart7개 analyze 진단0건, format 변경0, 범위 diff 검사 통과. 최초 unnecessary_import1건은 제거 후 재분석했다.
  - 디버거/한계: DebugMCP가 테스트 대신 기존 iPhone release 실행 구성을 선택해 중단점에 도달하지 못했고 stop/중단점 제거 후 no-session을 확인했다. 모의 SDK/서버 테스트로 검증했으며 실제 Google 계정 revoke·실기기 탈퇴/앱 재실행·운영 서버 호출 인수는 수행하지 않았다. 성공한 빌드/설치/배포를 확인한 것은 아니다. 실기기 반영에는 재빌드/설치가 필요하다.
  - 브랜치/산출물: Flutter 저장소에는 origin/main만 있어 현재 main 기반 로컬 develop을 만들고 작업을 보존했다. 커밋/푸시/운영 배포는 하지 않았다. /private/tmp/shiftmate_google_deletion_20261113/auth-final.log는 인증 전체 결과, baseline_test.dart와 before는 수정 전 모의 재현과 사본이다. 새 영구 산출물은 없다.
  - 롤백: /private/tmp/shiftmate_google_deletion_20261113/before에 보관한 변경 전 파일과 이번 diff를 기준으로 관련 변경만 복구한다. 기존 미커밋 화면/일정 변경은 되돌리지 않는다.
  - 다음: 로그인 직후/시간 경과/앱 재실행 후 실제 탈퇴를 확인한다. Google/Naver 사전 해제와 내부 삭제 분리의 기존 미합의 정책은 서버 PRIVACY_FE_CONTRACT_PROPOSAL에 남아 있으며 이번에 우회 정책을 추가하지 않았다.

## 2026-11-13 친구 추가 시트 전환 애니메이션·접기 개선

- [DONE] (FE/UI) 확대/축소의 실제 중간 프레임을 복구하고 최대 단계의 즉시 닫힘 방지
  - 목적: 사용자 제보의 높이 순간 전환과 최대→기본 복귀 대신 닫히는 동작을 수정한다.
  - 원인/재현: 기존 테스트의 drag→pumpAndSettle은 드래그 진행 중 프레임을 그리지 않아 AnimatedSize 제거 경로를 놓쳤다. 새 회귀에서 startGesture→move/pump→move/pump→up/pump를 수행하자 기대299px/실제742.72px 즉시 확대가 실패했다. DebugMCP의 _buildSheetTransition 진입/animate=true·단계 상태와 기존 조건 분기를 대조했다. 드래그 중 요소를 제거하고 종료 시 새 요소를 만들면 최종 크기에서 첫 레이아웃을 시작해 이전 높이 보간이 사라진다.
  - 변경/Behavior change: 드래그 전후 AnimatedSize 요소를 유지하고 높이·translation 복귀를260ms/easeOutCubic으로 보간한다. 흰 배경/반경24px 클리핑을 add-friend-visible-surface로 애니메이션 바깥에 두고 topCenter 정렬해 헤더가 움직이는 상단에 붙어 있고 축소 중 하단이 비지 않게 했다. 키보드 inset별 ValueKey는 IME 변경 프레임을 즉시 반영하며 같은 inset의 사용자 단계 전환은 보간한다. 동작 줄이기는 높이 애니메이션을 우회한다. 기존 GlobalKey는 KeyedSubtree로 옮겨 입력/포커스 subtree를 보존한다.
  - 접기/닫기: 최대 상태에서는 아래48px 이상이면 거리에 관계없이 기본으로 먼저 접는다. 기본 상태에서 시작한 아래120px 이상 제스처만 닫는다. 닫기 버튼·두 높이/최대88%와 개인 일정 기준·짧은 제스처 복귀/취소·검색/요청/알림 이동은 유지하며 자유 중간 크기는 추가하지 않는다.
  - 범위/파일: 기존 add_friend_modal.dart·add_friend_modal_test.dart와 PROJECT_CONTEXT·ADR-0079/0078 후속·이번 일지다. 테스트 scaffold는 resizeToAvoidBottomInset=false로 모달이 실제 popup처럼 키보드 inset을 직접 받게 한다. 역할/의존성/사용 예·렌더 경로는 PROJECT_CONTEXT에 기록했다. 신규 저장소 파일/패키지·다른 화면·API/DB/env/인증/권한/analytics/logging 변경은 없다.
  - 테스트/결과: 모달41 pass. 실제 드래그 프레임 뒤 종료 직후 높이 보존→80ms 중간 높이→완료를 확대/축소에서 검증했다. 중간 프레임의 헤더가 실제 표면 상단에 붙고 확대 시 하단이 고정되는 것도 확인했다. 키보드가 있는 단계 전환의 보간·inset280/200/100의 변경 프레임 즉시 반영·동작 줄이기 즉시 전환·확대 도중 반대 제스처가 현재 높이에서 접히는 연속성을 확인했다. 긴 아래 제스처의 최대→기본/다음 제스처 닫기와 기존 검색/요청/취소/레이아웃 회귀를 유지했다.
  - 키보드 검증 보정: 새 테스트의 기대512px/실제524px 차이를 조사했다. DebugMCP로 모달이 보는 keyboard_height=0.0·화면844.0을 확인했고 로컬 CupertinoPageScaffold의 resizeToAvoidBottomInset이 inset을 소비하는 구현과 대조했다. 실제 popup의 모달 직접 처리와 같은 테스트 조건으로 보정한 뒤 기대 가용 높이/모든 회귀가 통과했다. 프로덕션 scaffold/키보드 계약은 변경하지 않았다.
  - 통합/정적 검증: 기본 설정의 모달/친구 목록/메인 탭3파일76 pass, 그룹/P1 활성에 적용되는 같은 범위76 pass. 이전에 확인한 그룹 비활성 전용2개는 기본 설정에서 검증하고 활성 실행에만 기존 이름 필터를 적용했다. 변경 Dart2개 analyze 진단0건·format 변경0건·범위 git diff --check 통과. 이번 디버거 중단점은 모두 제거했다. 임시 소스 로그는 추가하지 않았다.
  - 렌더/실행: 실제 폰트의 motion_before/motion_release/motion_mid/motion_after와 기존 초기/확인/완료·최대·반응형 PNG를 /private/tmp/shiftmate_friend_motion_2026-11-13/render에 생성하고 전/중/후 프레임을 열어 확인했다. `ADD_FRIEND_RENDER_OUTPUT=/private/tmp/shiftmate_friend_motion_2026-11-13/render flutter test --no-pub test/features/friend/presentation/widgets/add_friend_modal_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`로 재현한다. 재현 실패 로그는 같은 임시 디렉터리의 repro.log, 최종 통합은 default-final.log/group-final.log이며 앞선3파일/그룹 실행 조건을 사용한다. SDK 캐시는 테스트/분석 명령 권한 확장, 포맷은 SDK Dart 직접 실행으로 처리했다.
  - 한계/배포: 모의 API/위젯 프레임과 렌더 검증이며 실제 기기/VoiceOver·운영 API·전체 앱 suite·빌드/설치/배포·커밋/푸시는 수행하지 않았다. 실기기 앱 반영에는 재빌드/설치가 필요하다.
  - 롤백: 이번 모달/테스트/문서만 되돌리고 기존 미커밋 변경은 보존한다. 수정 전 사본은 /private/tmp/shiftmate_friend_motion_2026-11-13/modal.before.dart·test.before.dart다.

## 2026-11-13 친구 추가 시트 높이 단계 제한

- [DONE] (FE/UI) 자유 크기 조절을 기본·최대·닫기 동작으로 제한
  - 목적: 사용자 요청에 따라 임의의 중간 높이가 남지 않게 하고 최대 높이를 개인 일정 추가 시트와 맞춘다.
  - 변경/Behavior change: _drag_height와 임의 높이 저장을 제거하고 _is_expanded bool만 유지한다. 기본은 기존 내용 기반 크기, 최대는 개인 일정 추가와 같은88%/키보드 시 가용 높이다. 가용 높이는 화면-상단viewPadding-키보드-12px를0~화면 높이로 제한한다. 헤더를 위48px 이상 밀면 최대, 아래48~119px는 기본, 아래120px 이상은 기본/최대에서 닫기로 정착한다. 짧은 움직임은 원래 단계로 복귀하고 속도만으로 닫지 않는다. 드래그 중 크기는 바꾸지 않고 아래 translation만180px까지 추적한다. 검색/입력 수정/요청 완료와 키보드 전환으로 선택 단계를 초기화하지 않는다.
  - 취소/애니메이션: 일반 높이와 translation 복귀180ms·키보드/드래그/동작 줄이기 즉시 배치·GlobalKey subtree 보존을 유지한다. PointerCancel과 onVerticalDragCancel은 거리/offset/진행 상태를 초기화하고 이후 비활성 onEnd를 무시해 취소로 확장/닫기가 실행되지 않게 한다.
  - 범위/파일: 기존 add_friend_modal.dart·add_friend_modal_test.dart 및 PROJECT_CONTEXT·ADR-0078/0077 후속·이번 일지다. 모달 테스트 helper는 CupertinoApp.builder에서 Navigator/popup 전체에 동일 MediaQuery와 RepaintBoundary를 적용하며, 기존 PersonalEventFormModal/intl 한국어 날짜 초기화에 의존해 실제 높이를 비교한다. 역할/의존성/사용 예는 PROJECT_CONTEXT의 친구 추가 검색 흐름에 기록했다. 신규 저장소 파일/패키지·개인 일정 시트/친구 서비스/provider/API/DB/env·탭/인증/공유 권한·analytics/logging 변경은 없다.
  - 테스트/결과: 모달37 pass. 기본/최대 두 높이·여러 거리에서 같은 최대 높이·짧은 고속 드래그 복귀·최대에서 기본으로 접기·기본/최대에서 아래로 닫기·드래그 중 크기 불변/취소·검색/입력/요청 후 최대 유지와 기존29개 기능/레이아웃 회귀를 확인했다. 화면390x844·375x667·667x375·768x1024와390x844/키보드320px의5조건에서 상단 안전영역까지 포함해 실제 개인 일정 추가 높이와 일치했다.
  - 통합/정적 검증: 기본 설정의 모달/친구 목록/메인 탭3파일72 pass, 그룹/P1 활성에 적용되는 같은 범위72 pass. 이전 작업에서 확인한 그룹 비활성 전용2개는 기본 설정에서 검증하고 활성 실행에만 기존 이름 필터를 적용했다. 변경 Dart2개 analyze 진단0건·format 변경0건·범위 git diff --check 통과. 자유 높이 변수/기존 상한 getter 잔존0건이다.
  - 조사/수정: 첫 검증에서 팝업 최대528px와 기대742.72px 차이를 확인했고, 기존 test helper의 MediaQuery가 home 내부에만 있어 root popup은 테스트 View의600px 높이를 사용함을 확인해 Navigator 위 builder로 옮겼다. 드래그 취소 회귀는 취소 뒤 최대 단계로 변하는 실패를 재현했다. DebugMCP로 _settleSheet 중단점의 TestGesture.cancel→PointerCancel→DragGestureRecognizer._checkEnd→onVerticalDragEnd 호출 스택을 확인했고 로컬 Flutter monodrag.dart의 승인된 drag 처리와 대조했다. Listener 취소 보호와 비활성 종료 guard로 해결한 뒤 전체 회귀를 통과했다. 이번 중단점은 모두 제거했다. 임시 소스 로그/무관한 제품 변경은 없다.
  - 렌더/실행: 실제 폰트의 초기/확인/완료·작은 화면/가로/태블릿/큰 글자/키보드/OS dark 선호·최대 단계 PNG12개를 /private/tmp/shiftmate_add_friend_detents_2026-11-13/render에 생성하고 최대 상태를 열어 확인했다. `ADD_FRIEND_RENDER_OUTPUT=/private/tmp/shiftmate_add_friend_detents_2026-11-13/render flutter test --no-pub test/features/friend/presentation/widgets/add_friend_modal_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`로 재현한다. 최종 통합 로그는 같은 디렉터리의 default-final.log/group-final.log이며 앞선 작업의3파일/그룹 실행 조건을 사용했다. SDK 캐시는 테스트/분석 명령 권한 확장, 포맷은 SDK Dart 직접 실행으로 처리했다.
  - 한계/배포: 모의 API/위젯 렌더 범위이며 실기기/VoiceOver·운영 API·전체 앱 suite·빌드/설치/배포·커밋/푸시는 수행하지 않았다. 실기기 앱 반영에는 재빌드/설치가 필요하다.
  - 롤백: 이번 모달/테스트/문서 변경만 되돌리고 기존 미커밋 변경은 보존한다. 작업 전 사본은 /private/tmp/shiftmate_add_friend_detents_2026-11-13/modal.before.dart·test.before.dart다.

## 2026-11-13 친구 추가 보조 안내 제거

- [DONE] (FE/UI) 가입 정보 입력·상대방 수락 안내 문구 제거
  - 목적: 사용자 요청에 따라 친구 추가 화면의 불필요한 설명을 줄인다.
  - 변경/범위: 기존 모달의 기본 입력 안내와 요청/완료 아래 수락 안내·관련 여백만 제거한다. 입력 오류/검색 실패/요청 상태·API와 탐색은 유지한다.
  - 테스트: 기존 모달 회귀·정적 분석·포맷·문구 잔존/범위 diff 확인. 단순 문구 삭제이므로 새 테스트/파일은 추가하지 않는다.
  - 결과/Behavior change: 기본 입력 안내와 요청/완료 아래 수락 안내를 제거했다. 기본 상태에는 오류용8px 간격도 만들지 않으며 버튼 아래 안내12px 간격과 미사용 can_request/is_pending 계산도 제거했다. 내용 기반 시트 높이가 그만큼 줄어든다. 라벨/placeholder·입력 오류·검색 실패·프로필/요청 상태·기존 단일 버튼과 API/탐색은 유지한다.
  - 검증: 기존 모달29개 pass·변경 Dart1개 analyze 진단0건·format 변경0건·삭제 문구 잔존0건·범위 diff 검사 통과. PROJECT_CONTEXT와 ADR-0077 후속 기록을 갱신했다. 새 테스트/파일/의존성·렌더·실기기 실행·빌드/설치·커밋/푸시는 수행하지 않았다.
  - 실행: `flutter test --no-pub test/features/friend/presentation/widgets/add_friend_modal_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`; `flutter analyze --no-pub lib/features/friend/presentation/widgets/add_friend_modal.dart`. SDK 캐시 접근은 같은 명령의 권한 확장, 포맷은 SDK Dart 직접 실행으로 처리했다.
  - 롤백: 이번 모달/문서 추가분만 되돌리고 기존 미커밋 변경을 보존한다.

## 2026-11-13 친구 추가 단일 계정 확인 구조

- [DONE] (FE/UI) 정확 일치 계정 한 명을 확인하는 간결한 폼으로 재구성
  - 목적: 사용자가 확정한 이메일/전화번호 유일성·정확 일치·단일 반환 요구에 맞춰 화면의 정보와 행동을 단순화한다.
  - 변경/Behavior change: 큰 도입·검색 결과 제목·결과 카드·별도 검색 버튼·공유 안내를 제거했다. 흰 시트/연회색 입력·좌우24px, 원형64px 사진/20px 이름/14px 이메일의 중앙 프로필, 최소52px 주요 버튼 하나를 사용한다. 친구 찾기→친구 요청 보내기→완료로 버튼을 교체하고 입력 수정 시 이전 프로필/오류를 지운다. 기존 친구/보낸 요청은 완료, 받은 요청은 기존 알림 확인으로 연결한다. 요청 성공은 상태를 확인한 뒤 완료로 닫는다.
  - 높이/수명: 고정65%/검색85% 확장을 제거하고 내용에 맞게 높이를 결정하며 화면92%-키보드 높이로 제한한다. 단일 본문 스크롤·고정 헤더/닫기/드래그를 유지하고 일반 변화만180ms로 전환한다. 키보드/드래그/동작 줄이기는 AnimatedSize 자체를 우회한다. GlobalKey로 시트 subtree를 보존해 전환 래퍼가 바뀌어도 입력/포커스가 유지된다. 앞선 API/정규화·검색 generation/해제 보호·요청 중복 방지·mounted 확인·보낸 상대 Set·domain provider 정책을 유지한다. 키보드 검색은 계정 확인만 하며 확인된 계정에서 자동 요청하지 않는다.
  - 범위/파일: 이번 코드 변경은 기존 lib/features/friend/presentation/widgets/add_friend_modal.dart와 test/features/friend/presentation/widgets/add_friend_modal_test.dart다. PROJECT_CONTEXT의 최신 정책/역할·의존성/사용 예/렌더 명령·롤백, ADR-0077/ADR-0076 대체 상태, FRIEND_API_GUIDE의 정확 일치/현행 UI 참조와 이번 일지를 갱신했다. 저장소 신규 파일/패키지·API/DB/env·탭 호출부/인증/공유 권한·analytics/logging 변경은 없다.
  - 테스트/결과: 모달29개 pass. 초기 시트400px 미만/확인600px 미만(390x844·기본 폰트)의 내용 기반 높이, 단일 프로필/주요 버튼 교체·입력 수정 복귀·키보드 확인의 자동 전송 방지·완료 닫기를 검증했다. 기존 검증/API 미호출·전화번호3형식·역순/초기화/해제 응답·없음/통신 실패·중복 방지/요청 재시도/관계 상태·닫기 후 응답·드래그/키보드 높이도 유지한다. 키보드320→100→0에서 입력/동일 FocusNode·실제 포커스를 보존하며, 완료 버튼이 화면/하단 안전영역 안에 있는지도 확인했다.
  - 통합/정적 검증: 기본 설정의 모달·친구 목록·메인 탭3파일64 pass, 그룹/P1 활성 조건에 적용되는 같은 범위64 pass. 그룹 비활성 전용 테스트2개는 기본 설정에서 검증하고 앞선 작업에서 확인한 이름 필터를 활성 실행에만 적용했다. 변경 Dart2개 analyze 진단0건·format --output=none --set-exit-if-changed 변경0건·범위 git diff --check 통과.
  - 시각 검증: 실제 Cafe24/Cupertino 폰트의 초기/확인/완료 및320x568·375x667·390x844·667x375·768x1024·3.2배 글자·480px 키보드·어두운 OS 선호/동작 줄이기 PNG11개를 /private/tmp/shiftmate_add_friend_single_2026-11-13/render에 생성해 확인했다. 주요 버튼 최소52px·닫기44px·텍스트 대비/줄바꿈·본문 안의 버튼 폭/하단 접근·스크롤·overflow 없음도 회귀로 확인했다. 시트는 OS 밝기와 관계없이 이번 승인 시안의 흰 표면을 유지하며 앱 전체 다크 테마를 추가한 것은 아니다.
  - 조사/수정: 첫 검증에서 드래그와 동작 줄이기의 Duration.zero AnimatedSize가 레이아웃 중 동기 listener를 호출해 RenderAnimatedSize 자기 레이아웃 무효화 오류를 재현했다. DebugMCP는 동적으로 생성된 이름의 테스트를 찾지 못했으나 정적 드래그 테스트의 모달 build 중단점에 진입했다. 실제 실패 스택과 로컬 Flutter RenderAnimatedSize._layoutStable/_restartAnimation·AnimationController._animateToInternal의 zero-duration notifyListeners 경로를 대조했다. 즉시 반영 조건에서 해당 위젯을 우회하고 같은 실패 테스트와 전체 회귀를 통과했다. 이번 중단점은 모두 제거했으며 테스트 디버그 종료 후 표시되는 기존 ShiftMate release 세션은 건드리지 않았다. 임시 소스 로그는 추가하지 않았다.
  - 실행/산출물: `ADD_FRIEND_RENDER_OUTPUT=/private/tmp/shiftmate_add_friend_single_2026-11-13/render flutter test --no-pub test/features/friend/presentation/widgets/add_friend_modal_test.dart test/features/friend/presentation/pages/friend_list_page_test.dart test/core/navigation/main_tab_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`. 그룹은 GROUP_API_ENABLED=true/GROUP_P1_ENABLED=true dart-define과 앞선 작업의 --name 정규식을 사용한다. 최종 로그는 같은 임시 디렉터리의 default-final.log/group-final.log다. SDK 캐시 접근은 테스트/분석 명령의 권한 확장, 포맷은 SDK Dart 직접 실행으로 처리했다.
  - 한계/배포: 모의 API와 위젯 렌더 검증이며 실제 기기/VoiceOver·운영 API·전체 앱 suite·빌드/설치/배포·커밋/푸시는 수행하지 않았다. 실행 중인 실기기 앱에 적용하려면 새 코드로 재빌드/설치해야 한다.
  - 롤백: 이번 모달/관련 테스트·문서만 되돌리고 앞선 검색 최신성/알림 이동 및 기존 미커밋 변경은 보존한다. 수정 전 모달/테스트 사본은 /private/tmp/shiftmate_add_friend_single_2026-11-13/modal.before.dart·modal_test.before.dart다.

## 2026-11-13 친구 추가 화면 재설계

- [DONE] (FE/UI) 검색 → 상대 확인 → 요청 흐름으로 친구 추가 시트 재설계
  - 목적: 승인된 디자인 제안에 따라 입력 공간을 넓히고 검색 결과·요청 상태를 가까이 배치한다.
  - 변경/Behavior change: 전체 너비 입력(16px)/검색48px·결과 카드/52px 요청·22px 도입·14px 보조 문구·좌우20px, 시트 상단24px/기본65%/최대폭560px로 재구성했다. 유효 검색 시 최소85% 높이를 확보한다. 헤더/닫기를 고정하고 나머지는 하나의 ListView로 스크롤한다. 검증은 인라인 오류, 검색 실패/결과 없음은 다른 안내, 요청 실패는 카드 아래 오류/재시도, 완료는 카드 안 수락 대기 상태다. 공유 안내를 펼쳐 확인할 수 있다. 명시적인 received 요청은 시트를 닫고 기존 알림 탭 또는 독립 NotificationPage로 연결한다.
  - 상태/안전성: 입력 수정/초기화마다 검색 generation을 무효화해 역순 응답/오류·notifier 해제 뒤 결과를 버린다. 검색 시작 시 이전 user를 제거한다. 전송 중 입력/지우기/검색/중복 요청을 막고 응답 뒤 mounted를 먼저 확인한다. 같은 시트에서 보낸 상대는 재검색해도 대기 상태를 보존한다. 키보드 높이 제한·헤더 드래그/닫기·동작 줄이기·안전영역·큰 글자 줄바꿈과 세로 프로필 배치를 제공한다. 어두운 헤더는 배경 대비를 계산해 제목/닫기를 읽을 수 있게 했다.
  - 범위/파일: 기존 lib/features/friend/presentation/widgets/add_friend_modal.dart·pages/friend_list_page.dart·providers/friend_provider.dart와 기존 add_friend_modal_test.dart·main_tab_page_test.dart, PROJECT_CONTEXT·DECISIONS(ADR-0076)·FRIEND_API_GUIDE·이번 일지를 수정했다. 파일 역할/의존성/사용 예와 렌더 명령은 PROJECT_CONTEXT의 ‘친구 추가 검색 흐름’에 기록했다. 저장소 신규 파일/패키지·API/DB/env·인증·기본 공개 권한·analytics/logging·domain provider 수명 정책 변경은 없다.
  - 테스트/결과: 최종 기본 설정의 친구 추가/친구 목록/탭 탐색 61 pass, 그룹/P1 활성 상태에 적용되는 같은 범위 61 pass. 친구 추가 자체26개가 입력 오류/API 미호출·전화번호3형식 정규화·키보드 제출/포커스/지우기·역순/초기화/해제 응답·결과 없음/통신 오류 복구·전송 중 중복/성공/재검색/실패 재시도·관계 상태/받은 요청·닫기 후 응답·헤더 드래그·키보드 전환을 확인했다. 실제 탭 통합 경로에서도 시트 해제→알림 탭 선택/조회→친구 목록 복귀와 root route 중복 없음을 확인했다.
  - 시각/접근성: 실제 Cafe24/Cupertino 폰트로 초기·결과·완료/320x568·375x667·390x844·667x375·768x1024·3.2배 글자·480px 키보드·어두운 헤더/동작 줄이기 조건의 PNG 11개를 /private/tmp/shiftmate_add_friend_2026-11-13/render에 생성하고 확인했다. 최소 입력52px/검색48px/요청52px·44px 닫기·본문 안의 버튼 폭/하단 접근·헤더 텍스트 대비4.5 이상·공유 설명까지 스크롤 접근·overflow 없음도 회귀로 검증했다. 어두운 전체 UI를 새로 도입한 것은 아니며 기존 밝은 본문을 유지한다.
  - 정적 검증: 변경 Dart5개 flutter analyze 진단0건. SDK Dart --suppress-analytics format --output=none --set-exit-if-changed 5파일 변경0건. 범위 git diff --check 통과.
  - 실행: 기본은 `ADD_FRIEND_RENDER_OUTPUT=/private/tmp/shiftmate_add_friend_2026-11-13/render flutter test --no-pub test/features/friend/presentation/widgets/add_friend_modal_test.dart test/features/friend/presentation/pages/friend_list_page_test.dart test/core/navigation/main_tab_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`. 그룹 검증은 같은 명령에 GROUP_API_ENABLED=true/GROUP_P1_ENABLED=true dart-define과 `--name '^(?!.*(탭 이동과 재선택은 달을 보존하고 오늘 버튼만 오늘로 이동한다|탭 내부 상세 화면은 뒤로가기로 같은 그룹 목록에 복귀한다)).*$'`를 적용한다. 최종 로그는 /private/tmp/shiftmate_add_friend_2026-11-13/default-final.log·group-final.log다.
  - 조사/실행 정리: 확대 검증에서 미리보기 전제의 기존 테스트2개를 그룹 활성 조건으로 실행해 ‘우리 병동’/group-room-preview-card 부재 실패를 확인했다. DebugMCP로 해당 테스트606행에서 group_api_enabled=false·미리보기 실제1개를 관찰했고 코드의 활성 그룹 분기/빈 모의 그룹 응답과 대조해 실행 조건 불일치를 확인했다. 이 두 테스트는 기본 설정에서 통과하며 활성 검증만 이름 필터로 분리했다. 무관한 제품/테스트 동작은 수정하지 않았다. Flutter가 지원하지 않는 --exclude-name 시도는 위 --name 정규식으로 정정했다. 디버거 세션 종료와 이번 중단점 제거를 확인했으며 임시 소스 로그는 추가하지 않았다. SDK 캐시 쓰기 제한은 동일 테스트/분석 명령의 권한 확장, 포맷은 SDK Dart 직접 실행으로 해결했다.
  - 한계/배포: API는 모의 service 응답이며 실기기/VoiceOver·운영 API·전체 앱 suite·빌드/배포·커밋/푸시는 수행하지 않았다. 앱 코드 반영 후 재실행해 확인할 수 있다.
  - 롤백: 이번 모달·받은 요청 호출부·검색 최신성·회귀/문서 변경만 되돌리고 기존 미커밋 변경은 보존한다. 작업 전 세 Dart 파일과 모달 테스트 사본은 /private/tmp/shiftmate_add_friend_2026-11-13/*.before.dart에 있다.

## 2026-11-12 친구·그룹 빈 목록 당겨 새로고침

- [DONE] (FE/UI) 빈 목록·짧은 목록에서도 새로고침 가능하도록 수정
  - 목적: 친구/그룹이 없거나 화면을 채우지 못해도 아래로 당겨 최신 목록을 조회할 수 있게 한다.
  - 범위: 친구 목록·실제 그룹 목록의 scroll/refresh 경로와 기존 회귀·문서. API/DB/권한·탭 상태는 유지한다.
  - 테스트: 빈/짧은 목록의 실제 당김 제스처·조회 재호출·성공/실패/중복·기존 탭/목록 회귀와 분석/포맷.
  - 원인/재현: 빈/오류 분기가 새로고침용 CustomScrollView를 반환하지 않았다. 실제 당김으로 빈 목록·진행 중·오류 복구의 신규6개 회귀가 조회횟수 expected2/actual1로 실패했고 기존Cupertino환경의 짧은목록2개는 통과했다. 로컬 Flutter Cupertino refresh 구현도 Bouncing/AlwaysScrollable 조합을 확인했다.
  - 변경/Behavior change: 친구/실제 그룹의 상태와 관계없이 root CustomScrollView·CupertinoSliverRefreshControl을 유지하고 Bouncing(parent:AlwaysScrollable)로 빈/짧은 목록과 여백에서도 당김을 받는다. 빈/오류는 SliverCenteredBody, 로딩은 SliverFillRemaining으로 구성한다. 요청 중 재조회는 막고 그룹 loadMore는 빈목록/음수overscroll을 제외한다. provider/API/DB/권한·탭keep-alive·가로전환·기존 재시도/카드 동작은 보존한다.
  - 파일/문서: 기존 scrollable_centered_body.dart의 중첩 스크롤 구현을 SliverCenteredBody로 전환하고 friend_list_page.dart·group_room_list_view.dart·기존관련test2개를 확장했다. 기존프레임의 다른Dart호출부가 없음을 검색 확인했다. PROJECT_CONTEXT의역할/의존성/사용예와ADR-0075를 기록했다. 신규저장소파일/패키지는 없다(앞선작업의untracked파일은보존).
  - 결과: 기본플래그 관련2파일24 pass, 활성그룹/P1의친구목록+그룹전체45 pass, 기본플래그 메인탭탐색/그룹미리보기27 pass. 공용프레임정리후 활성플래그관련2파일최종25 pass. 빈/짧은목록 당김·빈여백·pending중1회조회/컨트롤유지·응답후목록표시·오류→재시도복구·탭선택/가로전환·375x667/844x390·작은높이/글자3.2배·다크/동작줄이기를확인했다. 변경Dart5개분석진단0건·포맷변경0건·범위diff검사통과.
  - 실행: `flutter test --no-pub test/features/friend/presentation/pages/friend_list_page_test.dart test/features/group/presentation/widgets/group_room_list_view_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --dart-define=GROUP_API_ENABLED=true --dart-define=GROUP_P1_ENABLED=true --reporter=expanded`. 활성전체는친구목록테스트와`test/features/group`,기본탐색은`test/core/navigation/main_tab_page_test.dart test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`를같은테스트명령에서플래그없이실행했다.
  - 조사/정리: DebugMCP가동적생성테스트명을찾지못했고파일단위실행도기존release iPhone설정을선택해중단점관찰을못했다. 해당세션중지·이번45행중단점제거와no-session을확인했으며pending호출을종료했다. 원인검증은위실제위젯제스처/조회횟수회귀로수행했다. 임시로그는추가하지않았다.
  - 한계/배포: service/repository모의응답이며실기기인수·VoiceOver·운영API·전체앱suite·배포/커밋/푸시는수행하지않았다. 앱을재빌드/설치해야반영된다.
  - 롤백: 이번 새로고침 연결·physics/빈 상태 배치·관련 회귀/문서만 되돌리고 기존 미커밋 변경은 보존한다.

## 2026-11-12 개인정보처리방침의 화면 사용 안내 제거

- [DONE] (WEB) 정책 본문에서 표 스크롤 안내 문구 제거
  - 목적: 개인정보처리방침에 화면 사용 설명이 섞이지 않도록 사용자 요청을 반영한다.
  - 변경/영향:5개 표 앞 안내·전용 CSS·삭제된 안내의 aria-describedby 참조를 제거하고 변경 이력에서도 모바일 표시 개선 설명을 뺀다. 정책 내용·75%크기·표 구조/이름·스크롤·키보드 접근은 유지한다.
  - 테스트: 기존 HTML 구조/표/MD/연령·동의 보존 검증·안내 잔존/누락 참조·diff 검사.
  - 결과: 안내5개·전용CSS·aria-describedby5개를 제거했다. 공개 변경 이력의 화면 표시 설명을 HTML/MD에서 함께 제거했다. 정책 본문·연령/동의·75%치수·caption/scope/영역명/tabindex·스크롤은 유지한다. support는 변경하지 않았다.
  - 검증/문서: 기존임시 `python3 /private/tmp/shiftmate_privacy_content_audit_2026-11-12.py`로 HTML중첩·14절/5표·MD표 모든셀 동일·연령/동의 보존·ARIA참조 유효 검증 통과. 안내문구·CSS잔존0과scope/표영역5개를 정적 대조했다. PROJECT_CONTEXT·ADR-0074후속·DEPLOY_GUIDE최신hash를 갱신했다. 범위diff검사 통과. 신규파일/테스트·렌더·운영게시·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 안내와 관련 문서 변경만 되돌리며 이전 크기/표 수정은 보존한다.

## 2026-11-12 개인정보·고객지원 페이지 크기75% 조정

- [DONE] (WEB/UI) privacy.html·support.html의 표시 크기 축소
  - 목적: 사용자 요청에 따라 두 페이지의 글자·여백·본문 폭·표 크기를 기존의 약75%로 맞춘다.
  - 변경/영향: CSS 치수만 조정하고 개인정보/지원 본문·연령/동의 문구·링크는 유지한다. 모바일 breakpoint·브라우저 확대·표 구조/가로 스크롤·링크 최소 터치 높이는 유지한다.
  - 테스트: 모바일/가로/데스크톱 렌더·표 정렬·페이지 가로 넘침·본문/링크 보존·HTML 구조를 확인한다.
  - 결과/Behavior change: 본문16→12px, h1 30→22.5px/모바일26→19.5px, h2 21→15.75px, 최대 폭860→645px로 조정했다. 개인정보 표 최소 폭640/560/880→480/420/660px와 패딩·반경도75%다. breakpoint600·viewport1·터치44px·1px구분선·포커스 강조를 유지하고 support 내비게이션도44px로 통일했다. transform/zoom은 사용하지 않았다.
  - 검증: 두 실제 페이지의320/375/844/1440px·375px 본문200%/다크 선호·동작 줄이기12조건 통과. 본문12px(확대24px)·최대645px·표 정렬·페이지 가로 넘침 없음·링크/문의44px 이상을 확인하고375px 두 PNG를 열어 확인했다. CSS 이후 원문이 두 파일 모두 직전과 완전히 같아 본문/링크 변경이 없음을 확인했다. 기존 개인정보 태그 중첩·14절·5표 모든 MD셀·연령/동의 보존 검증과 범위 diff 검사도 통과했다.
  - 파일/도구: 기존 privacy.html·support.html·PROJECT_CONTEXT·ADR-0074후속·DEPLOY_GUIDE·이번 일지만 갱신했다. 저장소 신규 파일/의존성은 없다. 임시 Node CDP 측정 스크립트 `/private/tmp/shiftmate_web_scale_2026-11-12.mjs`의 역할/의존성/실행 예와 PNG/JSON 출력 위치는 PROJECT_CONTEXT에 기록했다.
  - 한계/배포: Chrome 렌더 범위이며 실제 Safari/VoiceOver·전체 Flutter/BE suite·운영 교체·커밋/푸시는 수행하지 않았다. 배포 연결 없이 로컬 수정/교체본 준비까지 완료했으며 두 파일 최신hash를 DEPLOY_GUIDE 상단에 갱신했다.
  - 롤백: 이번 두 HTML의 크기 조정과 관련 문서만 되돌리고 앞선 표/본문 정정은 보존한다.

## 2026-11-12 개인정보처리방침 모바일 표·내용 검토

- [DONE] (WEB) 모바일 표의 헤더/본문 정렬 수정 및 정책 내용 사실 대조
  - 목적: 휴대전화에서 개인정보처리방침 표의 열 제목과 내용이 분리되는 문제를 해결하고 현재 구현과 다른 문구를 정정한다.
  - 범위: 공개 개인정보 HTML·편집 정본 MD·관련 검토/배포 문서와 정본 프로젝트 문서. 기존 앱/서버 기능·개인정보 보관 정책을 임의 변경하지 않는다.
  - 테스트: 운영 HTML과 로컬 비교, 모바일/가로/확대 화면 렌더·표 구조/접근성 확인, 앱·인접 서버 코드 및 공식 안내 기반 내용 대조.
  - 원인/수정: 공개 GET200·로컬 SHA 일치 후375px에서5개 표 모두 헤더/본문 x·폭 불일치를 재현했다.600px 이하 table/tbody/tr/td/th의 display:block을 제거하고5개 native table을 표 안에서 가로 스크롤하도록 바꿨다. 기본640px·2열560px·4열880px 최소 폭·첫 열 비율·세로 구분선을 적용하고 caption·열/행 scope·영역명/안내·tabindex·focus outline을 제공했다.
  - 본문/Behavior change: 나만 보기 수집/공유 제외·친구 레벨0·비친구 그룹 근무표 노출 조건·Google/Firebase 통합 SDK 분석/진단·공휴일 API를 보완하고 그룹 ‘설명’을 실제 ‘시간대’로 정정했다. HTML/MD를 v1.1/최종수정2026-11-12로 동기화하며 최초 시행일·기존 보관기간은 유지했다. 사용자 답변 ‘이 내용에 대해서 수정하지마’에 따라 가입 연령 확인/항목별 동의 내용과 제9항 원문을 보존했다.
  - 내용 확인/한계: 전체 HTML/MD·FE DTO/가입/일정/공휴일·인접 BE profileMutation/profileService·Group·friendService/groupService SQL·private migration·SDK privacy manifest와 기존 운영자 확정 기록을 대조했다. Firebase 공식 안내의 FCM 설치ID 삭제 후180일 설명도 확인했다. 국외 처리의 실제 계약별 법인/국가/근거와 원격 보관 설정은 새로 단정하지 않고 기존 확인 필요 사항으로 PRIVACY_REVIEW 상단에 남겼다.
  - 결과:11조건×5표 정렬·헤더 동일 행·페이지 가로 넘침 없음·행 제목/접근성 참조가 모두 통과하고 ArrowRight로40px 스크롤했다. 폭320/375/390/430/600/601/768/844/1440,375px 본문200%·다크 선호·동작 줄이기를 포함했다. 수정 전후375px·가로·큰글자·마지막 열 PNG를 직접 확인했다. HTMLParser 태그 중첩·14개 절·MD/HTML 표5개 모든 셀 동일·연령/동의 원문 보존·범위 diff 검사를 통과했다.
  - 파일/문서: 기존 privacy.html·PRIVACY_POLICY.md·PRIVACY_REVIEW.md·DEPLOY_GUIDE.md·PROJECT_CONTEXT·ADR-0074·이번 일지. 저장소 신규 파일·의존성은 없다. 임시QA스크립트·공개본·PNG/JSON의 역할/의존성/실행 예는 PROJECT_CONTEXT에 기록했다. 실행: `node /private/tmp/shiftmate_privacy_render_2026-11-12.mjs`, `python3 /private/tmp/shiftmate_privacy_content_audit_2026-11-12.py`.
  - 실행 정리: sandbox의 Chrome 시작/loopback 접근 제한은 전용 임시 프로필의 권한 확장 실행으로 해결했다. 자체 HTMLParser가 self-closing void 태그를 잘못 판단한 실패는 handle_startendtag 처리 후 동일 검증 재실행으로 해결했다. 실제 HTML 중첩 오류는 없었다.
  - 배포/범위: 실제 iPhone Safari·VoiceOver·운영 게시·Flutter/BE 기능 변경·커밋/푸시는 수행하지 않았다. 확인된 배포 연결/실제 파일 경로가 없어 새 HTML과 SHA/롤백 가이드를 준비했다. 공개 URL의 오류가 이미 수정됐다고 보고하지 않는다. 수정 HTML SHA-256은 `02cf90b8accd0b1b463e01fd013e122af6e11de47489634088c2dcd66eb6f3e6`이다.
  - 롤백: 이번 개인정보 페이지·정책 정정·검토 문서 추가분만 되돌리고 기존 미커밋 변경을 보존한다.

## 2026-11-12 고객 지원 링크 추가

- [DONE] (FE/UI) 설정 지원 섹션에 실제 고객 지원 페이지 연결
  - 목적: 개인정보처리방침과 함께 앱에서 고객 지원 페이지에 접근할 수 있게 한다.
  - 변경/영향: 기존 운영 문서의 https://www.shiftmate.co.kr/support 주소를 확인하고 설정에 고객 지원 행을 추가한다. 외부 브라우저 열기와 실패/예외 안내를 기존 정책 링크 방식으로 제공한다. API/DB/인증 상태는 변경하지 않는다.
  - 파일: 기존 settings_page.dart·privacy_policy.dart·PROJECT_CONTEXT·DECISIONS·이번 일지. 신규 파일/의존성은 추가하지 않는다.
  - 결과/Behavior change: 설정 지원 섹션에 고객 지원 → 개인정보처리방침 → 버전 정보를 표시한다. openCustomerSupport가 실제 지원 URL을 외부 브라우저로 열며, 공용 helper로 실패/예외·화면 해제 안전 처리를 재사용한다. 기존 PrivacyPolicyLauncher/launchPrivacyPolicy/openPrivacyPolicy 호출 계약과 정책 URL/오류 문구를 유지했다. ADR-0073에 후속 근거를 기록했다.
  - 테스트: 기존 설정/로그인19 pass(정책 열기 성공·false/Exception 실패·재시도·화면 해제 및 설정 인증 동작 포함). 변경 Dart2개 분석 진단0건·포맷 변경0건·범위 diff 검사 통과. 신규 테스트는 추가하지 않았다.
  - 운영 URL: 읽기 전용 HTTPS GET으로 https://www.shiftmate.co.kr/support 의200·text/html; charset=utf-8과 고객지원 제목·문의 이메일 링크·개인정보 링크를 확인했다. 웹 도구 접근 실패·sandbox DNS 제한은 권한 확장 GET으로, Flutter SDK 캐시 쓰기 제한은 같은 테스트/분석 명령의 권한 확장으로 해결했다. 임시 본문은 /private/tmp/shiftmate_customer_support_2026-11-12.html에 저장했으며 저장소 산출물은 아니다.
  - 실행: `flutter test --no-pub test/features/auth/presentation/pages/settings_page_test.dart test/features/auth/presentation/pages/login_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`; `flutter analyze --no-pub lib/core/utils/privacy_policy.dart lib/features/auth/presentation/pages/settings_page.dart`; SDK Dart의 `--suppress-analytics format --output=none --set-exit-if-changed`로 변경 두 파일을 확인했다.
  - 한계: 실제 기기의 브라우저 이동/앱 복귀·VoiceOver·전체 suite·신규 지원 행의 주입 launcher 위젯 테스트는 수행하지 않았다. 빌드/업로드·커밋/푸시는 하지 않았다.
  - 롤백: 이번 고객 지원 행·URL 열기 확장·관련 문서만 되돌리고 앞선 미지원 메뉴 숨김과 기존 미커밋 변경은 보존한다.

## 2026-11-12 미지원 설정 메뉴 숨김

- [DONE] (FE/UI) 미지원 기능의 설정 진입 항목 제거
  - 목적: 앱 심사 재제출 전 현재 사용할 수 없는 기능이 설정에 노출되지 않게 한다.
  - 변경/영향: 설정의 미지원 8개 행과 빈 섹션을 제거하고 구현된 프로필 편집·근무 패턴·정책·버전·로그아웃·회원 탈퇴 경로를 유지한다. API/DB/인증 상태 변경은 없다.
  - 파일: 기존 settings_page.dart·PROJECT_CONTEXT·DECISIONS·이번 일지. 신규 파일은 만들지 않는다.
  - 결과/Behavior change: 기본 알림 설정·다크 모드·언어 및 지역·글꼴 크기·비밀번호 변경·로그인 생체 인증·공지사항·고객 센터 8개 행과 앱 설정/계정 및 보안 섹션을 제거했다. 미지원 표시 helper 옵션도 제거했고 근무 관리/지원 사이 기존24px 간격을 유지했다. PROJECT_CONTEXT의 현행 설명과 ADR-0073을 갱신했다.
  - 테스트: 기존 설정/프로필 화면30 pass. 프로필 편집 저장/취소·정책 열기/실패 재시도·탈퇴 접수/재인증 회귀를 확인했다. settings_page.dart 분석 진단0건, 포맷 변경0건, 범위 git diff --check 통과. lib의 준비 중/미구현/미지원 UI 표시 검색 결과 미지원 설정 잔존0건이다(알림 구독·업데이트 차단 등 기능 용어는 제외).
  - 실행: `flutter test --no-pub test/features/auth/presentation/pages/settings_page_test.dart test/features/auth/presentation/pages/profile_setup_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`; `flutter analyze --no-pub lib/features/auth/presentation/pages/settings_page.dart`; SDK Dart의 `--suppress-analytics format --output=none --set-exit-if-changed`로 변경 파일을 확인했다.
  - 한계/배포: 신규 테스트·의존성·설정 플래그는 추가하지 않았다. 기존 테스트와 정적 대조 범위이며 전체 suite·시각 렌더·실기기/VoiceOver·운영 API 인수·빌드/업로드·커밋/푸시는 수행하지 않았다. 심사에 반영하려면 이 변경을 포함한 새 앱 빌드가 필요하다.
  - 롤백: 이번 설정 표시·관련 문서 추가분만 되돌리고 기존 미커밋 변경은 보존한다.

## 2026-11-12 그룹 날짜 선택 네모 크기 통일

- [DONE] (FE/UI) 그룹 dots 선택 영역을 메인·친구 badge와 통일
  - 목적: 공용화 후에도 그룹 날짜 선택 네모가 작은 원인을 확인하고 기존 UI 통일 범위를 완성한다.
  - 원인/범위: _CellLayoutMetrics의 badge는58/아래4px, dots는50/아래3px이다. 상세 두 모드의 선택 영역만 공유하며 compact48/아래8px·근무 점/배지·행 높이는 유지한다.
  - 테스트: 동일 폭/행 높이에서 badge/dots 선택 네모의 실제 Rect 일치와 기존 화면 회귀·분석/포맷.
  - 결과/Behavior change: 상세 badge/dots를 같은 switch 분기의58px/아래4px metrics로 통합했다. 수정 전320px/행52에서 badge Rect(0,4,45.7,56), dots Rect(0,4,45.7,54)의 차이로 새 회귀가 실패했다. 수정 후12개 폭/행 높이 조합에서 크기·위치가 일치하며 네 화면68 pass. 실제/미리보기 그룹 모두 공용 metrics를 사용한다. compact·행 높이·표시 데이터·API/DB·provider/라우트는 유지한다.
  - 파일/검증: 기존 calendar_month_view.dart·group_calendar_page_test.dart 및 PROJECT_CONTEXT·ADR-0072 보완·이번 로그. 신규 파일은 없다. 변경 Dart2개 분석 진단0건·포맷 변경0건·diff 검사 통과. 실행: `flutter test --no-pub test/features/calendar/presentation/pages/calendar_page_test.dart test/features/friend/presentation/pages/friend_calendar_page_test.dart test/features/friend/presentation/pages/group_calendar_preview_page_test.dart test/features/group/presentation/pages/group_calendar_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`. SDK 캐시 접근은 같은 명령의 권한 확장으로 처리했다. 실기기/배포·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 선택 metrics·회귀·문서 추가분만 되돌린다.

## 2026-11-12 그룹 캘린더 UI 통일 구현

- [DONE] (FE/UI) 달력 액션·간격·일정 영역 공용화
  - 목적: 그룹만 달라진 버튼/달력 치수/선택일 영역을 메인·친구의 공용 표시 규칙으로 맞춘다.
  - 범위: 실제/미리보기 그룹과 재사용에 필요한 공용 위젯·호출부. 구성원/ACL/timezone·조회·편집 계약을 유지한다.
  - 테스트: 관련 캘린더 위젯 회귀, 작은/가로 화면·확대 글자, 정적 분석·포맷·시각 확인.
  - 변경/Behavior change: 실제/미리보기 그룹과 친구의 오늘 액션을 메인의 공용44x44 이상 버튼으로 통일하고 그룹 달력의 좌우8px/요일30px 예외를 제거했다. 기존 메인 배치를 CalendarPageBody로 추출해 네 화면에 적용했다. 근무/개인 일정 장식은 CalendarScheduleItem으로 추출해 그룹 구성원 행도 동일한 tint·왼쪽 선·반경·간격을 사용한다. 그룹 관리 버튼44x44/접근성 이름도 적용했다. 멤버·ACL/timezone·조회/편집·route/provider/dispose·API/DB/env 계약은 유지한다.
  - 후속 확인: 실제 폰트 PNG에서 글자3.2배 연월이 숫자 중간에서 줄바꿈되고 요일이32px 영역에서 잘리는 것을 확인했다. 공용 헤더의 연월 독립 행과 확대 요일 높이로 해결했으며 새 회귀가 연월 한 줄·요일 높이·다음 월/오늘의 실제 변경을 확인한다.
  - 검증 결과: 기본 플래그의 메인/친구/미리보기·전체 그룹·선택일 헤더·메인 탭 탐색·viewport controller/layout policy137 pass, P1 전용 기존1 skip. GROUP_API_ENABLED/GROUP_P1_ENABLED=true 전체 그룹22 pass. 실제/미리보기의7조건씩(320x568·375x667·390x844·667x375·768x1024·375px 글자3.2배·다크/동작 줄이기)에서 마지막 구성원 스크롤 접근·전체 폭/요일·오늘44px·월 이동을 검증했다. 변경 Dart11개 분석 진단0건·포맷 변경0건·diff 검사 통과.
  - 실행: `flutter test --no-pub test/features/calendar/presentation/pages/calendar_page_test.dart test/features/friend/presentation/pages/friend_calendar_page_test.dart test/features/friend/presentation/pages/group_calendar_preview_page_test.dart test/features/group test/features/calendar/presentation/widgets/calendar_schedule_header_test.dart test/core/navigation/main_tab_page_test.dart test/features/calendar/presentation/controllers/calendar_viewport_controller_test.dart test/features/calendar/presentation/models/calendar_layout_policy_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`. 활성 그룹은 `flutter test --no-pub test/features/group --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --dart-define=GROUP_API_ENABLED=true --dart-define=GROUP_P1_ENABLED=true --reporter=expanded`.
  - 시각/산출물: `GROUP_CALENDAR_RENDER_OUTPUT=/private/tmp/group_calendar_ui_2026-11-12`와 실제/미리보기 테스트의 `--name '공용 배치'`로 PNG14개를 생성했다.320px 실제 그룹·375px 미리보기·가로/확대 글자를 열어 확인했다. 저장소 신규 파일은 없고 테스트 helper는 기존 파일을 확장했다. PROJECT_CONTEXT·ADR-0072를 갱신했다.
  - 실행 중 정리: SDK 캐시 접근은 동일 테스트 명령의 권한 확장으로 처리했고 Dart 검증에는 --suppress-analytics를 사용했다. Semantics const/BoxBorder 캐스트 컴파일 오류와 테스트의 세로 스크롤 선택/스크롤 완료 프레임·확대 글자 버튼 스크롤 경고를 수정했다. 미리보기 전용 탐색 테스트까지 실제 그룹 플래그를 켠 최초 실행3건 실패는 기본 경로와 활성 그룹 suite를 각각 올바른 조건으로 재실행해 해소했다.
  - 한계: 모의 repository/service와 실제 위젯의 검증이며 운영 API·실기기 VoiceOver·전체 앱 suite·배포·커밋/푸시는 수행하지 않았다. 공용 테마는 기존 밝은 토큰을 유지하며 별도 다크 디자인을 추가하지 않았다.
  - 롤백: 이번 표시 공용화·관련 회귀·문서 추가분만 되돌리고 기존 미커밋 변경은 보존한다.

## 2026-11-12 그룹 캘린더 UI 통일 난이도 검토

- [DONE] (FE/UI 분석) 메인·친구 대비 그룹 캘린더 표시 구조 비교
  - 목적: 그룹 캘린더의 UI를 기존 캘린더와 맞출 때 필요한 범위와 난이도를 코드로 확인한다.
  - 범위: 공용 달력·선택일 카드·배치 및 실제/미리보기 그룹 경로. 앱 동작 수정은 포함하지 않는다.
  - 테스트: 관련 소스와 ADR-0016/0017·현행 레이아웃 정책을 대조한다.
  - 결과: 세 화면은 CalendarViewport/CalendarMonthView와 CalendarScheduleHeader를 공유한다. 실제/미리보기 그룹은 오늘 버튼54x36·별도 타이포/반경, 달력 좌우8px·요일30px를 지정하고 구성원 카드를 별도로 렌더링한다. 메인은 onToday 공용 액션, 친구는44x32 별도 오늘 버튼을 사용하므로 메인/친구도 모든 세부 값이 같지는 않다. 메인의 작은 높이/큰 글자 대응 LayoutBuilder는 친구/그룹의 단순 Column과 다르다.
  - 제안/영향: 표시 통일은 FE 범위에서 가능하다. 공용 액션·달력 치수·본문 배치를 정리하고 그룹의 멤버 식별/다중 근무/공개 안 함 표시를 유지하는 방향이다. 구성원별 본문까지 재설계하면 범위가 커지며 ADR-0017의 다중 소유자/ACL/timezone 상태를 유지해야 한다.
  - 파일/검증/한계: 기존 PROJECT_CONTEXT와 이번 로그만 추가했다. 코드 정적 대조만 수행했으며 앱 코드·API/DB·동작 변경, 테스트 실행·실기기 시각 확인은 없다. 새로운 설계 결정은 없어 ADR은 추가하지 않는다.
  - 롤백: 이번 조사 문서 추가분만 제거한다.

## 2026-11-12 근무·개인 일정 행 표시 통일

- [DONE] (FE/UI) 근무 삭제 문구와 개인 일정 화살표
  - 목적: 근무 일정도 충분히 왼쪽으로 밀면 삭제 문구를 표시하고 개인 일정의 수정 표시를 근무와 같은 화살표로 맞춘다.
  - 변경/영향: 메인 CalendarPage의 행 표시만 변경하며 기존 탭 편집·삭제 유예/되돌리기·서버 계약을 유지한다.
  - 파일: calendar_page.dart·PROJECT_CONTEXT·DECISIONS·이번 일지.
  - 결과/Behavior change: 근무 행도 기존 공용 삭제 배경의88px 기준부터 `삭제`를 표시하고 개인 일정의 연필/수정 표시를 근무와 같은14px 왼쪽 화살표로 교체했다. 신규 파일/의존성은 없다.
  - 테스트: 기존 calendar_page_test.dart46 pass. 탭 편집·짧은 스와이프 복귀·삭제 유예/되돌리기·혼합 삭제·실패 복귀·부분 스와이프 배경과 작은/가로/큰 글자·다크 토스트 회귀를 확인했다. 실행: `flutter test --no-pub test/features/calendar/presentation/pages/calendar_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --reporter=expanded`.
  - 정적 확인: 변경 Dart 파일 분석 진단0건·포맷 변경0건·git diff --check 통과. 최초 dart format의 SDK 캐시 권한 오류는 동일 검증의 권한 확장 실행으로 해결했다.
  - 문서/한계: PROJECT_CONTEXT·ADR-0071에 현재 표시와 기존 정책 유지 범위를 기록했다. 실기기 시각/VoiceOver·전체 suite·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 표시·문서 추가분만 되돌린다. 기존 미커밋 변경은 보존한다.

## 2026-11-12 그룹 생성자 탈퇴 후 상세 조회 수정

- [DONE] (FE) 그룹 생성자 nullable 응답 지원
  - 목적: 생성자 탈퇴 후 소유권이 승계된 그룹의 정보 화면이 파싱 예외로 실패하는 문제를 해결한다.
  - 변경/영향: GroupDetail 생성자 ID 타입/파서를 nullable로 맞추고 실제 repository 파싱 및 정보 화면 회귀를 추가한다. 앱만 수정하며 서버/DB 계약과 역할 기반 권한을 유지한다.
  - 테스트: 생성자 ID 문자열/null 응답 및 null 응답의 실제 정보 화면 로딩·승계된 OWNER 권한을 검증하고 관련 그룹 회귀·정적 분석·포맷을 확인한다.
  - 결과: 수정 전 새 null repository/화면 회귀2건 실패로 TypeError와 정보 미표시를 재현했다. 수정 후 GROUP_API_ENABLED/GROUP_P1_ENABLED=true 그룹 전체21 pass, 기본 플래그의 관련 두 파일7 pass·P1 전용 기존1 skip. 생성자 문자열/null 보존·그룹명/멤버 표시·활성 초대 버튼·오류/재시도 미표시를 확인했다. 변경 Dart3개 정적 분석 진단0건·포맷 변경0건·범위 diff 검사 통과.
  - 실행: `flutter test --no-pub test/features/group --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key --dart-define=GROUP_API_ENABLED=true --dart-define=GROUP_P1_ENABLED=true --reporter=expanded`; 기본 경로는 repository/management 두 테스트 파일에 플래그 없이 같은 명령을 실행했다. `flutter analyze --no-pub` 및 `dart format --output=none --set-exit-if-changed`에 변경 Dart3개를 전달했다.
  - 파일/문서: 기존 group_models.dart·group_repository_impl_test.dart·group_management_page_test.dart·PROJECT_CONTEXT·ADR-0070·이번 로그만 변경했다. 신규 파일/의존성은 없다. 기존 원인 조사 절은 수정 전 기록임을 명시했다.
  - 한계/배포: 모의 API 응답과 실제 모델/notifier/페이지로 검증했으며 실기기·운영 API 호출·회원 탈퇴 E2E·앱 배포·커밋/푸시는 수행하지 않았다. 수정 앱을 설치해야 반영된다.
  - 롤백: 이번 모델 두 줄·추가 회귀·문서 추가분만 되돌린다. 기존 미커밋 변경은 보존한다.

## 2026-11-12 그룹 소유자 회원 탈퇴 후 상세 조회 오류 조사

- [DONE] (FE/BE 분석) 소유권 자동 이전 후 그룹 정보 로딩 오류 원인 확인
  - 목적: 기존 소유자의 회원 탈퇴 후 그룹/캘린더는 유지되지만 그룹 정보 화면이 실패하는 원인을 코드와 재현 근거로 확인한다.
  - 범위: 회원 탈퇴/소유권 이전, 그룹 상세와 캘린더 API, Flutter 응답 파싱 및 오류 표시. 기능 수정은 이번 분석에 포함하지 않는다.
  - 원인: 서버는 OWNER 승계 후 탈퇴자를 물리 삭제하며 FK가 groups.created_by_user_id를 null로 익명화한다. 상세 API는 nullable 생성자 값을 반환하지만 Flutter GroupDetail.fromJson:209는 as String으로 읽어 TypeError를 발생시킨다. notifier의 error에 저장되고 그룹 정보 화면의 비ApiException 기본 문구로 표시된다. 캘린더/목록은 생성자 필드를 파싱하지 않아 유지된다.
  - 검증: 실제 모델을 import한 /private/tmp/group_owner_deletion_repro.dart에서 생성자 문자열일 때 상세 성공, null일 때 목록/캘린더 성공·상세 TypeError를 재현했다(exit 0). 오류: type 'Null' is not a subtype of type 'String' in type cast, group_models.dart:209:54. 실행: /opt/homebrew/share/flutter/bin/cache/dart-sdk/bin/dart /private/tmp/group_owner_deletion_repro.dart. 최초 불필요한 --suppress-analytics 옵션은 VM에서 거부돼 제거한 동일 실행으로 성공했다. SDK/프로젝트 소스 변경은 없다.
  - 파일/문서: PROJECT_CONTEXT의 ‘그룹 생성자 회원 탈퇴 후 상세 조회 오류 조사’와 이번 일지. 진단 스크립트는 순수 Dart 그룹 모델에 의존하고 저장소 밖 임시 파일이며 예시 문자열/null 응답만 사용한다. 신규 저장소 파일은 없다.
  - 한계/후속: 실제 장애 API 응답·운영 DB·배포 버전은 미수집이다. DebugMCP 기본 실행이 지정한 임시 Dart 대신 기존 Flutter iPhone 설정을 선택해 진단 입력의 중단점 관찰은 못 했으며 별도 Dart 실행 결과를 근거로 사용한다. 이번에 생성한 디버그 세션과 211행 중단점은 정리하고 다른 중단점은 보존한다. 앱/서버 기능 수정·배포·전체 suite는 수행하지 않았다. 후속 수정은 created_by_user_id nullable 타입/파서와 탈퇴 후 상세/화면 회귀 검증이다. 설계 변경은 없어 ADR을 추가하지 않는다.
  - 롤백: 이번 조사 문서 추가분만 제거한다. 기존 미커밋 변경은 보존한다.

## 2026-11-12

- [DONE] (FE/UI) 커스텀 색상 헤더의 스크롤 배경 고정
  - 목적: 헤더와 겹치지 않는 독립 패널 스크롤에도 헤더가 흰색으로 변하는 현상을 메인·친구 목록과 같은 정책으로 맞춘다.
  - 변경/Behavior change: 커스텀 navigationBar에 automaticBackgroundVisibility=false·backgroundColor=AppTheme.background_color를 추가하고 border=null을 유지했다. 기존 미리보기/패널·색상/저장 동작과 다른 상세 화면 헤더는 보존한다. 신규 파일/상태/의존성·API/DB/env 변경은 없다.
  - 파일/문서: 기존 커스텀 페이지/회귀와 header_background 렌더러의 커스텀 기대값·PROJECT_CONTEXT·ADR-0058 후속 결정·이번 일지. 기존 미커밋 변경을 보존했다.
  - 테스트: 수정 전6조건 모두 실제 드래그 후 #FFF8F9FB→#E6FFFFFF 전환으로 실패해 제보를 재현했다. 수정 후 색상/커스텀30 pass,6조건(작은/가로/글자3.2배/키보드/태블릿)에서 스크롤·최하단·맨 위 복귀의 렌더된 배경/경계 불변을 확인했다. 변경 Dart3개 분석 진단0건·포맷/diff 검사 통과.
  - 렌더/한계: 기존 헤더 렌더러의 임시 사본 /private/tmp/shift_custom_header_fixed_render_test.dart로1 pass. /private/tmp/shift_custom_header_fixed_2026-11-12의PNG22개/측정 JSON에서375x667·667x375의 커스텀 헤더가 전후 #FFF8F9FB로 동일하고 Flutter 예외0건임을 확인했다. 작은 화면 스크롤 후 PNG를 직접 확인했다. 기존 렌더 산출물은 당시 기록으로 보존한다. 전체 suite·실기기·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 헤더 속성·검증·문서 추가분만 되돌린다.

- [DONE] (FE/UX) 조절 중 적용색 상시 표시와 스크롤 패널 경계 정리
  - 목적: 사용자 정정에 따라 최종색을 보면서 휠/RGB/농도를 조절할 수 있게 한다.
  - 변경/Behavior change: 미리보기를 상단 고정으로 복구하고 키보드 시에도 숨기지 않는다. 미리보기와16px 간격으로 분리된 둥근 패널 안에서만 기준색/휠/RGB/농도/최근 색상을 스크롤한다. 외곽 테두리/클리핑은 고정해 이동 카드가 미리보기 밑에서 잘리던 경계를 해소했다. 본문 가용 높이420px 미만은 샘플32px·패딩12px·정보 Wrap으로 공간을 확보한다.
  - 파일/영향: 기존 커스텀 페이지·커스텀/프리셋 회귀·PROJECT_CONTEXT·ADR-0069·이번 일지. ADR-0065는 대체된 기록으로 표시했다. 신규 저장소 파일은 없다. 색상/농도 계산·최근 기록·휠 제스처·저장/취소·라우트/API/DB/env/상태와 기존 미커밋 작업은 보존했다.
  - 테스트: 관련4개 파일53 pass/조작 경고0건.320x568·375x667·667x375·글자3.2배·768x1024·키보드240px에서 실제 세로 드래그 시 미리보기/패널 Rect 고정·16px 간격·최근 색상 선택 즉시 고정 HEX 갱신을 확인했다. 농도 트랙의 실제 탭/드래그 중 샘플 색상 변경·미리보기 위치·스크롤 유지도 확인했다. 변경 Dart3개 분석 진단0건·포맷 변경0건·diff 검사 통과.
  - 시각/한계: 기존 농도 렌더러 임시 사본 /private/tmp/shift_custom_fixed_preview_render_test.dart로1 pass/PNG10개/측정 JSON을 /private/tmp/shift_custom_fixed_preview_2026-11-12에 생성했다. 실제 번들 폰트의320px 하단·키보드·844x390 가로에서 고정 미리보기/독립 패널을 직접 확인했고320/390px·글자2배·태블릿을 포함해 Flutter 예외0건이다. 기존 회귀의 패널 밖 x8px 드래그는 새 패널 내부 x20px로 보정했다. 전체 suite·실기기/VoiceOver·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 페이지 배치·관련 검증·문서 추가분만 되돌린다.

- [DONE] (FE/UX) 작은 화면의 선택일 헤더 겹침·잘림 방지
  - 목적: 날짜와 근무 인원·일정 수가 좁은 영역에서 경쟁해 글자가 잘리는 현상을 해결한다.
  - 원인/변경: 실제 폰트의320px 그룹 페이지에서 날짜가 두 줄이 되지만 콘텐츠 슬롯은28px인 문제를 수정 전 테스트로 재현했다. 고정 Row/SizedBox와 배율 임계값을 중첩 Wrap/최소28px로 바꿔 날짜/공휴일·요약이 실제 폭에 맞춰 줄을 나누고 헤더 높이를 확보한다. 실제/미리보기 그룹도 CalendarScheduleHeader에 요약 칩을 주입해 같은 규칙을 사용한다. 공간이 충분하면 기존 한 줄/44.5px를 유지한다.
  - 영향/Behavior change: 좁거나 확대된 헤더는 높아져 목록 공간이 줄며 긴 공휴일도 전체 내용을 줄바꿈한다. 메인·친구 일정/근무 설정의 공용 헤더에 함께 적용한다. 기존 미커밋 변경과 API/DB·권한·상태/탐색·env·의존성은 보존한다.
  - 파일/문서: 기존 calendar_schedule_card.dart·실제/미리보기 그룹 페이지·관련 기존 화면 테스트3개와 신규 calendar_schedule_header_test.dart, PROJECT_CONTEXT·ADR-0068·이번 로그를 갱신했다. 신규 검증 파일의 역할/의존성과 실행 예는 컨텍스트에 기록했다.
  - 테스트: 관련5개 파일97 pass. 신규32개 검증은 실제 Cafe24/Cupertino 폰트·폭320/375/390/430/667/768·배율1/1.1/1.25/2/3.2·굵은 글자에서 날짜/세 자리 요약/공휴일의 글리프 경계·겹침·줄 전환 및 선택적 액션을 확인한다. 실제 그룹320/375/390px, 미리보기320x568·375x667·667x375의 목록 스크롤도 확인했다. 변경 Dart7개 정적 분석 진단0건·포맷 변경0건·git diff --check 통과.
  - 검증 명령: `flutter test --no-pub test/features/calendar/presentation/widgets/calendar_schedule_header_test.dart test/features/calendar/presentation/pages/calendar_page_test.dart test/features/friend/presentation/pages/friend_calendar_page_test.dart test/features/group/presentation/pages/group_calendar_page_test.dart test/features/friend/presentation/pages/group_calendar_preview_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`.
  - 시각/한계: `/private/tmp/shift_schedule_header_2026-11-12`의PNG7개를 생성해320px 요약 줄 전환·375px 한 줄 유지·3.2배 긴 공휴일을 직접 확인했다. 최초 선택 경계 검증은 줄 끝 공백까지 측정해 실제 글리프만 검사하도록 보완했고, 테스트용 액션 텍스트는 앱 본문 스타일을 명시했다. debug-live로 실제 그룹 상세 build 호출 경로를 확인하고 이번 중단점을 제거했다. Flutter SDK 캐시 권한은 승인된 동일 테스트 실행으로 해결했다. 전체 suite·모든 페이지 최대 글자 크기·실기기/VoiceOver·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 배치·회귀·문서 추가분만 되돌린다.

- [DONE] (FE/UX) 일정 없음 안내의 세로 중앙 정렬
  - 목적: ‘등록된 일정이 없습니다’ 안내를 일정 본문 영역의 상하 중앙에 표시한다.
  - 변경/영향: 메인·친구의 CalendarScheduleCard가 빈 상태를 Expanded 안의 SingleChildScrollView로 표시해 상단에 배치하고 있었다. 기존 스크롤을 Center로 감싸 아이콘/문구 묶음을 본문 중앙에 둔다. 날짜 헤더·추가 버튼·카드 크기·일정이 있는 목록은 유지한다. 공간이 부족하면 기존처럼 스크롤한다.
  - 파일/문서: 기존 calendar_schedule_card.dart·PROJECT_CONTEXT·이번 로그만 갱신했다. 신규 파일·상태·의존성·설계 정책/API/DB 변경은 없다.
  - 테스트: 기존 메인/친구 캘린더 회귀52 pass. 변경 Dart 정적 분석 진단0건·포맷 변경0건·git diff --check 통과. 실행: `flutter test --no-pub test/features/calendar/presentation/pages/calendar_page_test.dart test/features/friend/presentation/pages/friend_calendar_page_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`. 실기기 시각 확인·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 빈 상태 정렬·문서 추가분만 되돌린다.

- [DONE] (FE) 하단 탭 재선택과 알림 목적지 경로 통일
  - 목적: 다른 탭에서 돌아올 때 탐색 이력을 보존하고, 현재 탭 재선택은 홈 복귀/친구·그룹 목록 전환으로 처리한다. 알림 바로가기는 목적지 탭의 실제 탐색 이력을 사용한다.
  - 변경/Behavior change: MainTabPage의 하단 탭 입력은 현재 탭이면 첫 route까지 pop하고, 친구 탭이 이미 목록이면 기존 PageController로 친구↔그룹을 전환한다. 다른 탭에서 복귀하면 기존 상세·선택 날짜를 유지한다. AppTabNavigation.openFriends는 목적지 목록을 고른 뒤 선택적 상세를 친구 Navigator에 연결한다. 알림 친구 수락/목록 보기·그룹 수락/바로가기는 이 경로를 사용하며 알림 Navigator에 상세를 쌓지 않는다. 첫 방문은 프레임 종료 후 적용하고 revision으로 오래된 요청을 무시한다.
  - 파일/영향: 기존 main_tab_page.dart·app_navigation.dart·friend_list_page.dart·notification_page.dart와 main_tab_page_test.dart, PROJECT_CONTEXT·ADR-0067·이번 로그. 신규 파일은 없다. 기존 목록 keep-alive/dispose·알림 갱신·실패/친구 누락/거절 UX·인증·공개 권한·analytics·API/DB/env 계약은 유지한다.
  - 테스트: 기본 분기의 메인 탭·친구 목록·그룹 미리보기·그룹 알림 provider4개 파일40 pass. GROUP_API_ENABLED=true의 새 탐색 회귀9 pass.375x667·768x1024의 실제 친구 캘린더 날짜/state 보존·친구 정보까지의 이력 홈 복귀,844x390의 목록 재선택·다크/동작 줄이기, 첫 방문 수락/목록 바로가기·기존 상세 정리·친구/그룹 목록으로 뒤로가기·그룹 상세에서 하단 재선택·알림 탭 복귀·실패/누락/거절을 확인했다. 수락 결과는 탐색 테스트에서 모의하며 기존 provider 테스트로 domain 처리를 함께 검증했다. 변경 Dart5개 분석 진단0건·포맷 변경0건·diff 검사 통과. SDK 캐시 권한 오류는 같은 테스트 명령의 승인된 권한 확장으로 해결했다. 추가 테스트의 빈 record 리스트 타입/중괄호 진단은 명시 타입/블록으로 해소했다.
  - 검증 명령: `flutter test --no-pub test/core/navigation/main_tab_page_test.dart test/features/friend/presentation/pages/friend_list_page_test.dart test/features/friend/presentation/pages/group_calendar_preview_page_test.dart test/features/friend/presentation/providers/group_notification_provider_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`; 활성 분기는 메인 탭 파일에 `--name '하단 재선택|알림.*경로|알림 수락 실패' --dart-define=GROUP_API_ENABLED=true`를 적용한다.
  - 한계/다음: 별도844x390 실제 친구 캘린더 탐색 시8.5px 하단 overflow를 관찰했다. 해당 페이지 배치는 이번에 수정하지 않았으며 정확한 지점/원인 확인과 해결은 별도 과제로 남는다. 가로 회귀는 목록 전환 범위로 분리했고 실제 상세 탐색은375px/태블릿에서 검증했다. debug-live로 기존 _selectTab 중단점/호출 경로를 확인하고 추가 중단점을 모두 제거했다. 전체 suite·실기기·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 탐색 처리·관련 테스트·문서 추가분만 되돌린다. 기존 미커밋 작업은 보존한다.

- [DONE] (FE/UX) 그룹 근무 시간 구분자 공백 보완
  - 목적: 그룹 화면에서도 ADR-0066의 `06:30 - 15:00` 표기를 적용한다.
  - 변경/영향: 실제 GroupCalendarPage._shiftTime과 GroupCalendarPreviewPage의 근무 템플릿4개에서 공백 없는 `–`를 ` - `로 교체했다. 야간 익일·시간 없음·시간 값/API/DB·기존 화면 배치는 유지한다.
  - 파일/문서: 기존 그룹 캘린더·그룹 미리보기 페이지와 각 테스트, PROJECT_CONTEXT·ADR-0066 보완 및 이번 로그. 신규 파일은 없다.
  - 테스트: 두 기존 테스트 파일12 pass, 변경 Dart4개 정적 분석 진단0건·포맷 변경0건·git diff --check 통과. Flutter SDK 캐시/lockfile 권한으로 샌드박스 실행이 실패해 권한 확장으로 같은 테스트를 실행·통과했다. 실기기 실행·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 시간 문자열·기대값·문서 추가분만 되돌린다.

- [DONE] (FE/UX) 근무·개인 일정 시간 구분자를 하이픈으로 통일
  - 목적: 근무 일정의 `~`, 개인 일정의 `-`, 근무 편집 요약의 `–` 혼용을 해소한다.
  - 변경/영향: 시간 구간을 공백을 포함한 ` - `로 통일한다. 공용 일정 카드·근무 타입 표시·편집 요약만 대상으로 하며 시간 값/저장/API/DB는 유지한다.
  - 파일/문서: calendar_schedule_card.dart·shift_type_info.dart·shift_type_form_modal.dart, 기존 메인·친구 캘린더/근무 타입 편집 테스트 및 PROJECT_CONTEXT·ADR-0066·이번 로그. 신규 파일은 없다. ShiftTypeInfo에 남아 있던 snake_case 분석 진단6건은 프로젝트 방식의 예외 선언으로, deprecated color.value 진단1건은 동일 ARGB 정수를 반환하는 toARGB32()로 정리했다.
  - 테스트: `flutter test --no-pub test/features/calendar/presentation/pages/calendar_page_test.dart test/features/friend/presentation/pages/friend_calendar_page_test.dart test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` 73 pass. 변경 Dart6개 정적 분석 진단0건·포맷 변경0건·git diff --check 통과. SDK wrapper의 cache 쓰기 및 Dart telemetry 파일 권한 문제는 SDK 내 dart 직접 호출과 `--suppress-analytics`로 해결해 분석/포맷 exit0을 확인했다. 실기기 실행·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 구분자·기존 테스트 기대값·관련 문서 추가분만 되돌린다.

- [DONE] (FE/UX) 커스텀 색상 미리보기 아래 스크롤 단절 수정
  - 목적: 색상 조절 카드가 고정된 ‘적용될 색상’ 아래에서 갑자기 잘려 보이는 현상을 해소한다.
  - 원인/변경: 고정 미리보기+별도 ListView 경계가 조절 카드를 자르고 있었다. 수정 전320/375px·큰 글자 실제 드래그에서 본문21.17px/미리보기0px 이동을 재현했다. 미리보기→16px 간격→조절 카드→최근 색상을 하나의 SingleChildScrollView/Column으로 연결했다. 초기 ListView 통합 시 발생한 화면 밖 미리보기 unmount를 제거해 기존 입력/미리보기 유지 계약도 보존했다.
  - 영향/Behavior change: 미리보기도 본문과 함께 스크롤하며 맨 위에서 다시 확인한다. 기존 미커밋 헤더 재질, 완료/뒤로가기·키보드 시 미리보기 접기·색상 계산/기록·휠 제스처·최대폭/안전영역은 유지한다. API/DB/env·domain state/provider·의존성 변경은 없다.
  - 파일/문서: 기존 커스텀 색상 페이지/테스트·PROJECT_CONTEXT·ADR-0065·이번 로그. 신규 저장소 파일은 없다. 농도 조작 테스트는 IgnorePointer 하위 슬라이더 대신 실제 gesture 영역을 눌러 기존 hit-test 경고2건도 해소했다.
  - 테스트: 관련4개 파일51 pass, 마지막 테스트 조작 대상 보완 후 커스텀19 pass/경고0건.320x568·375x667·667x375·375px 글자3.2배의 동일 스크롤 이동량·간격 유지·최근 색상 접근·맨 위 복귀, 기존 휠/HEX/RGB/농도·최근 기록·완료/취소를 확인했다. 변경 Dart2개 분석 진단0건·포맷 변경0건·git diff --check 통과.
  - 시각 검증/한계: 기존 header_background 및 custom_color_intensity 렌더러의 임시 사본을 /private/tmp에 실행해2 pass, PNG16개/측정 JSON2개를 /private/tmp/shift_custom_scroll_2026-11-12에 생성했다.375px 중간 스크롤의 두 카드 간격, 가로 하단의 최근 색상 접근,320px 키보드 입력을 직접 확인했다.320/390px·글자2배·키보드240px·844x390·768x1024의 실제 번들 폰트 렌더에 Flutter 예외0건이다. 최초 가로 회귀는 최대폭480 바깥을 드래그해 테스트 좌표를 본문 안으로 보정했다. debug-live로 페이지 build 중단점을 확인하고 이번 중단점을 제거했으며 기존 iPhone 실행 세션은 보존했다. 전체 suite/실기기/VoiceOver·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 커스텀 색상 배치·관련 검증·문서 추가분만 되돌린다.

- [DONE] (FE/UX) 구분선 중심 헤더를 공통 흰색 재질로 통일
  - 목적: 사용자 요청에 따라 친구 정보·근무 타입 추가/편집·색상/커스텀 색상 선택의 같은 배경/하단 선 방식을 1번 배경 변화 방식으로 바꾼다.
  - 변경/범위: 네 navigationBar는 공통 테마 배경을 사용하고 하단 선을 제거한다. 친구 추가 모달도 제목 아래 고정선을 제거하고 흰 헤더와 본문 배경을 구분한다. 기존 메인/친구/그룹 캘린더 및 목록 헤더의 배경 고정 예외와 카드 내부 선은 유지한다.
  - 변경/Behavior change: 네 navigationBar의 개별 backgroundColor를 제거하고 border=null로 공통 테마의 흰색 배경 전환만 사용한다. 친구 추가는 공통 테마의 고정 흰 헤더와 연한 본문으로 구분하며 선 제거로 본문 공간이 1px 늘어난다. 신규 앱 state/provider/공용 위젯은 없다.
  - 파일/문서: 기존 다섯 화면 구현 및 PROJECT_CONTEXT·ADR-0064·이번 일지, 신규 artifacts/header_background_2026-11-12/render_test.dart·PNG22개·measurements.json. 렌더러의 역할/의존성/재생성 명령은 컨텍스트에 기록했다. 동시에 진행된 작은 화면 작업의 ADR-0063/친구 추가 배치를 보존했다.
  - 테스트: 관련 기존 여섯 파일의54 pass, 검토 렌더1 pass.375x667·667x375에서 실제 헤더 색상 #FFF8F9FB→#E6FFFFFF·border=null·맨 위 복귀와 예외0건을 확인했다. 색상 선택375px는 실제 스크롤 여유0이라 색상을 유지하며 가로 화면에서 전환을 확인했다. 변경 Dart6개 정적 분석 진단0건·포맷 변경0건(최종 확인)·diff 검사 통과. 기존 색상 농도 슬라이더의 tap/drag hit-test 경고2건은 이전 작업 로그에도 있는 기존 경고이며 헤더 렌더에는 조작 경고가 없다.
  - 시각/한계: 친구 정보·근무 타입 편집의 스크롤 후 흰 헤더/선 없음, 친구 추가의 흰 헤더와 본문을 PNG로 확인했다. 로컬 SDK 캐시/telemetry 쓰기는 허용된 도구 실행으로 처리했다. 검토 렌더의 최초 실패는 스크롤 여유0에서도 이동을 요구한 조건을 수정했다. debug-live의 test/ 밖 렌더 검색은 기존 iPhone 세션만 반환해 실제 변수 확인은 못 했으며 이번 중단점만 제거하고 기존 세션은 유지했다. 최종 실측 JSON에 실제 스크롤 범위를 기록했다. 전체 suite·실기기/VoiceOver·배포·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 헤더 표시 및 문서 추가분만 되돌린다.

- [DONE] (FE/UX) 배경색 유지·하단 구분선 방식의 헤더 사용처 조사
  - 목적: 친구 정보·근무 타입·색상 선택을 포함해 배경색 변화 대신 선으로 헤더를 구분하는 화면을 찾는다.
  - 범위: 공용 테마와 전체 presentation 헤더 선언/진입 경로를 읽고 명시적 구분선과 기본 자동 배경 전환을 구분한다. 앱 코드는 변경하지 않는다.
  - 결과/변경: 화면 상단은 친구 정보(1px), 근무 타입 추가/편집(0.5px), 색상 선택(1px), 커스텀 색상 선택(1px)의 네 구현/다섯 화면이다. 추가로 친구 추가 모달의 제목 아래 고정선(1px)을 확인했다. 실제 색상은 검정이 아닌 outline_variant_color(#C1C7D2)다. 세부 진입/내부 카드 헤더/미사용 ShiftInputSheet 구분은 PROJECT_CONTEXT에 기록했다.
  - 테스트: lib 전체 navigationBar 및 수동 Border/구분선·관련 생성 호출·공용 테마를 읽고 로컬 Flutter SDK nav_bar.dart의 색상/경계 보간을 대조했다. 네 화면은 배경이 동일해 스크롤 시 색상은 그대로이고 경계만 나타날 수 있다. 런타임 테스트/실기기 확인은 수행하지 않았다.
  - 파일/영향: PROJECT_CONTEXT와 이번 일지만 갱신했다. 앱 코드·API/DB/동작/의존성/라우트 변경이나 신규 파일/ADR은 없다. 기존 미커밋 작업은 보존했다.
  - 롤백: 이번 조사 문서 기록만 제거한다.

- [DONE] (FE/UX) 작은 화면의 날짜·시간 및 입력 UI 배치 전반 검토
  - 목적: 제보된 시간 줄바꿈과 작은 화면에서의 유사한 배치 불안정을 코드·실제 레이아웃으로 확인하고 수정한다.
  - 확인/근거: 개인 일정3:2 분할은375px·글자1.25배에서 시간 줄바꿈을 재현했다.320px·글자2배의 날짜/시간 요약, 가로·큰 글자 연월 시트 넘침,568x320 친구 빈 목록/오류17px 넘침과 최대 글자 친구 추가22px 넘침도 확인했다. 시각 검증에서 최대 글자 연도 휠의2026년 일부 잘림을 추가 발견했다. debug-live로 폼의 실제 제약/분기와 친구 추가의 넘치는 최상위 Column을 확인했고 추가 중단점/세션은 정리했다.
  - 변경/Behavior change: 날짜/시간 필요 폭을 실제 폰트·배율로 측정하고 두 행의 공통 폭/배치를 결정한다. 부족하면 라벨/컨트롤을 통째로 아래로 옮긴다. 피커 요약/날짜 탐색도 필요한 폭에 따라 분리한다. 연월 시트는 화면 내 제한·본문 스크롤/고정 하단, 실제 폭을 반영한 휠 비율/세로 배치·배율 행 높이를 사용한다. 큰 글자의 피커 액션은 같은 폭의 취소/적용·이동과 기존 접근성 이름을 사용한다. 친구·그룹 상태 안내와 낮은 친구 검색 본문을 스크롤 가능하게 했다. 글자 축소/날짜·시간 말줄임은 사용하지 않으며 값 자체가 전체 폭보다 긴 최대 글자 조건은 전체 내용을 줄바꿈한다.
  - 파일/영향: 기존 개인 일정/날짜·시간·연월 피커, 친구 목록/추가 모달, 그룹 목록 및 관련 테스트를 갱신했다. 신규 ScrollableCenteredBody·PickerSelectionSummary·compact_layout_test.dart, artifacts/compact_layout_2026-11-12/PNG84개, SMALL_SCREEN_LAYOUT_REVIEW_2026-11-12.md를 추가했다. 역할/의존성/사용 예와 재생성 명령은 PROJECT_CONTEXT·검토 문서에 기록했고 ADR-0063을 추가했다. 기존/동시 진행 미커밋 변경을 보존하며 API/DB/env·상태/라우트/권한/저장·검색 계약은 유지한다.
  - 테스트: 전체 Flutter **436 pass/기존 skip1**, 새 작은 화면 회귀/렌더 **36 pass**, GROUP_API_ENABLED=true의 모의 친구·그룹 분기 **16 pass**, 기존 실제 메인 진입/키보드 폼 렌더 **1 pass/17조건**.12개 크기·배율 조합(320/360/375/390/430/768px·가로,1/1.1/1.25/2/3.2배)의 텍스트 박스/정렬·긴 시간/연도/종일 보존·저장 고정·연도 전체 표시·실제 휠 접근을 확인했다. 변경 Dart12개 분석 **진단0건**, 포맷 변경0건·diff 검사 통과. 전체 suite의 기존 색상 슬라이더 hit-test 경고2건은 이번 범위와 무관하며 새 회귀/렌더의 조작 경고는 없다.
  - 시각/한계:84개 PNG 중375px의1.1/1.25배 시간 정렬,320px 날짜/시간, 날짜 탐색의 큰 글자, 가로 연월과 최대 글자 시간/연도·월 휠을 직접 확인했다. 기존17조건 키보드 렌더는 /private/tmp/shift_small_screen_form_keyboard에 별도 생성했다. 모의 서비스/테스트 키보드 inset 기준으로 실기기 Dynamic Type/실제 키보드/VoiceOver·실서버 인수를 대체하지 않는다. 커밋/푸시·배포는 수행하지 않았다.
  - 마지막 보완: 동작 줄이기에서는 연월의 이번 달 선택에 jumpToItem을 사용한다. 새 회귀에서 두 휠을2000년1월로 이동시킨 뒤 이번 달을 실제 눌러 두 선택 인덱스/요약 동기화를12조건으로 확인했다. 작은 화면36개+기존 연월2개 총38 pass, 해당2개 파일 분석 진단0건이다. 시각 캡처는 이번 달 조작 전 생성하므로 기존84개와 동일하다.
  - 롤백: 이번 배치 수정·공용 위젯·회귀/산출물·문서 추가분만 되돌린다. 동시 진행 헤더 재질 변경(ADR-0064)과 기존 일정 편집/삭제 등 다른 미커밋 작업은 보존한다.

- [DONE] (FE/UX) 하단 캘린더·친구·알림 바 선택 이동 애니메이션
  - 목적: 사용자 확인에 따라 하단 세 탭의 선택 배경과 아이콘/글자 전환을 부드럽게 연결한다.
  - 변경/Behavior change: 탭별 배경 페이드를 단일 선택 배경의 AnimatedAlign 이동으로 변경하고 아이콘/라벨 색상은 ColorTween으로 보간했다.280ms easeOutCubic/동작 줄이기0ms를 공유하며 연속 선택도 현재 위치/색상부터 이어진다. 배경 IgnorePointer·폭1/3·기존 테마색/반경을 사용한다.
  - 파일/범위: 기존 MainTabPage·main_tab_page_test.dart·PROJECT_CONTEXT·ADR-0062·이번 일지. 신규 파일/의존성/controller는 없다. 친구·그룹 상단 전환과 각 탭 탐색/상태·배지/접근성·글라스·바 크기/여백·API/DB/env는 보존한다.
  - 테스트: 기존 메인 내비게이션9개(추가4개)와 친구 목록5개, 총14 pass.375x667·844x390·768x1024 다크/글자2배에서 중간 위치/색상 보간·연속 탭 시 위치 연속성·최종 위치/색상·바/버튼 Rect 동일·최소44px 터치와 동작 줄이기 즉시 확정을 확인했다. 기존 월/그룹 상태·상세 복귀·푸시 보류·로그인/가입/로그아웃 회귀도 통과했다. 변경 Dart2개 정적 분석 진단0건·포맷 변경0건·diff 검사 통과.
  - 검증 보완/한계: 가로 테스트는 빈 친구 화면의 기존7px 넘침과 분리하기 위해 친구1명 모의 상태를 사용했다. 다크 테마는 기존 대비 보정으로 선택/비선택 색상이 모두 흰색일 수 있어 실제 Color.lerp 결과로 검증한다. 기본 fixture 동작은 유지한다. 디버거의 매개변수 테스트 검색은 소스 템플릿 이름으로 실행했고 추가 중단점/세션을 정리했다. 전체 suite/실기기 시각·VoiceOver 인수·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 하단 바 애니메이션과 검증·문서 추가분만 되돌린다.

- [DONE] (FE/UX) 친구·그룹 탭 좌우 스와이프 전환
  - 목적: 상단 세그먼트 탭 외에 목록 본문의 좌우 스와이프로 친구·그룹을 전환한다.
  - 변경/Behavior change: FriendListPage의 IndexedStack을 PageView로 교체하고 상단 세그먼트·제목/액션을 동기화했다. 왼쪽은 그룹/오른쪽은 친구로 이동한다. 세그먼트 탭은250ms easeOutCubic 전환, 동작 줄이기에서는 즉시 전환한다. 내부 keep-alive 래퍼로 목록 state/스크롤 위치와 그룹 최초 진입 시 생성 정책을 보존하며 PageController는 dispose한다.
  - 파일/범위: friend_list_page.dart·기존 friend_list_page_test.dart 확장·group_calendar_preview_page_test.dart의 전환 대기3곳·PROJECT_CONTEXT/ADR-0061/이번 일지. 신규 파일/의존성은 없다. 기존 미커밋 헤더 고정과 다른 작업·API/DB/env·domain state/라우트/권한은 보존한다.
  - 테스트: 기본 분기 관련20 pass(친구 목록5·그룹 미리보기9·그룹 목록1·메인 탭5), GROUP_API_ENABLED=true의 모의 API 목록/그룹 위젯6 pass.390x800·375x667·844x390의 실제 양방향 스와이프/탭·선택 표시/제목/액션·세로 스크롤/복귀 위치·최초 그룹 요청1회, 다크/글자2배/동작 줄이기를 확인했다. 변경 Dart3개 분석 진단0건·포맷 변경0건·diff 검사 통과. 전체 suite/실기기·VoiceOver 인수·커밋/푸시·배포는 수행하지 않았다.
  - 검증 보완/한계: debug-live에서 기존 미리보기 테스트의 pump1회 시 PageController.page=0·진행 중 프레임4개를 확인해 애니메이션 종료 대기로 변경했다. 신규 세그먼트 검증은 private enum 제네릭의 실제 위젯 타입을 is predicate로 찾는다. 추가 중단점/디버그 세션은 정리했다. 실제 API 플래그를 메인 탭 기존 suite에도 확장 실행했을 때2건 실패했으나, 이 suite는 그룹 repository/초대 provider mock이 없고 미리보기 카드 키를 기대하므로 기본 플래그 전용임을 코드로 확인했다. 기본 메인 탭5개는 통과하며 실제 API 플래그는 전용 mock이 있는 이번 목록/그룹 테스트6개로 검증했다.
  - 롤백: 이번 전환 UI·추가 검증·문서만 되돌린다.

- [DONE] (FE/UX) 친구·그룹 목록 탭 헤더 배경 고정 확대
  - 목적: 사용자 후속 요청에 따라 친구·그룹 캘린더 상세뿐 아니라 친구/그룹 목록 탭에도 같은 배경 고정을 적용한다.
  - 확인/범위: FriendListPage가 친구/그룹 세그먼트의 헤더를 공유한다. 실제 GroupRoomListView와 미리보기 목록 모두 이 헤더 아래에 표시된다.
  - 변경/Behavior change: FriendListPage.navigationBar에 automaticBackgroundVisibility=false·backgroundColor=AppTheme.background_color·border=null을 적용했다. 친구·그룹 목록 스크롤/세그먼트 전환에도 기존 정지 상태 배경을 유지한다. 목록/새로고침/페이지네이션·스크롤 위치·제목/액션·기능 플래그·API/DB와 다른 미커밋 작업은 유지한다.
  - 파일/문서: 기존 friend_list_page.dart와 신규 friend_list_page_test.dart, PROJECT_CONTEXT·ADR-0058 후속 결정·이번 항목을 갱신했다. 신규 회귀 파일의 역할·의존성·실제/미리보기 실행 예는 PROJECT_CONTEXT에 기록했다.
  - 테스트: 기본 경로 관련 **11 pass**(신규 목록 회귀·기존 그룹 미리보기/그룹 목록), GROUP_API_ENABLED=true의 실제 목록 통합 회귀 **1 pass**.20명 친구/20개 그룹의 실제 스크롤·헤더 BoxDecoration 고정·그룹 전환/맨 위 복귀·친구 스크롤 위치 보존을 확인했다. 미리보기는 카드1개라 양수 스크롤 대신 목록 제스처/표시·헤더와 전환을 검증했다. 수정 Dart2개 정적 분석 **진단0건**·diff 검사 통과. 이번 범위는 관련 테스트로 검증하며 실기기 인수·배포·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 목록 헤더 설정·회귀·문서 추가분만 되돌린다.

- [DONE] (FE/UX) 메인 일정 영역의 남은 높이 채우기 복구와 작은 화면 넘침 수정
  - 목적: 사용자 정정에 따라40% 고정 배치를 제거하고, 달력 뒤 남은 공간을 채우면서 작은 화면의 전체 스크롤과 하단 탭 침범을 방지한다.
  - 확인/근거: 직전 비율 구현과 기존580px/큰 글자 전체 스크롤 분기를 읽었다. 실제 본문은 헤더/탭/안전영역을 제외한다.320x568/상단47·하단34px 안전영역에서 본문371px에 기존 달력204+간격24+고정카드280=508px를 배치하는 분기가 전체 스크롤을 유발한다. debug-live에서 LayoutBuilder의 실제 제약/분기 계산을 확인하고 추가 중단점/세션은 정리했다.
  - 변경/Behavior change:40% 상수를 제거하고 달력 뒤 일정/근무 카드에 Expanded를 복구했다. 본문에서 배율 기준 최소 일정144px와4/16px 간격을 뺀 높이를 달력 ConstrainedBox의 상한으로 사용한다. 짧은 달력은 실제 높이만 사용하며, 긴 달력만 내부 스크롤해 카드 공간을 확보한다. 일반 작은 세로 화면의 전체 스크롤/고정280px 카드를 제거했다. 달력 상한100px 미만의 극단적으로 낮은 본문과16px 글자가20px를 넘는 큰 글자는 기존 전체 스크롤 접근성 경로를 유지한다.
  - 파일/영향범위: calendar_page.dart·기존 calendar_page_test.dart·기존 artifacts/calendar_schedule_ratio_2026-11-12/render_test.dart와 새 artifacts/calendar_remaining_space_2026-11-12/PNG16개/measurements.json, PROJECT_CONTEXT·ADR-0060/폐기한ADR-0059·작업 일지. 렌더러 역할/의존성/사용 예는 컨텍스트에 기록했다. 기존40% PNG는 당시 기록으로 보존한다. 달력 셀/750px 정책·일정 입력/수정/삭제·토스트·친구/그룹·API/DB/라우트/provider 정책은 유지한다.
  - 테스트: 최종 전체 Flutter **381 pass/기존 skip1**, 관련 페이지/렌더 **47 pass**. 실제 월 이동의4/5/6주·월/2주/주·작은 화면/근무 설정 전환·목록 스크롤과 카드/달력 위치·하단 탭 경계를 검증했다. 변경 Dart3개 분석 진단0건·포맷 변경0건·diff 검사 통과. 전체 실행의 기존 색상 슬라이더 tap/drag 경고2건 외 관련 페이지/최종 렌더의 조작 경고0건이다.
  - 시각 결과: 실제 MainTabPage 세로6조건의 카드 높이는147/153/215/247/335/427px로 남은 높이를 채우며 모두 탭 위16px에 고정된다.320x568은 실제 목록을 스크롤해도 달력/카드 Rect 동일, 근무 설정도 같은 Rect이고 완료 버튼에 접근한다.750px 화면의8월6주 월은 카드144px를 확보하고 달력만 스크롤한다. [작은 화면](../artifacts/calendar_remaining_space_2026-11-12/small320.png)·[근무 설정](../artifacts/calendar_remaining_space_2026-11-12/small320_shift.png)·[일반 화면](../artifacts/calendar_remaining_space_2026-11-12/normal.png)·[6주 월](../artifacts/calendar_remaining_space_2026-11-12/six_weeks_scrolled.png)을 시각 확인했다. 가로/큰 글자2배의 기존 예외도 버튼 접근/예외0건을 확인했다.
  - 한계/정리:6주 달력 스크롤 후 상단 버튼이 화면 밖에 있으므로 렌더는 맨 위 복귀 후 실제 근무 추가 버튼을 누르도록 수정했고 최종 hit-test 경고0건이다. 실제 기기/VoiceOver 인수·배포·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 수정과 문서/검증만 되돌린다.

- [DONE] (FE/UX) 메인 캘린더 하단 일정 영역의 화면 크기별 공간 배분 통일
  - 후속 상태: 사용자 정정으로40% 구현은 폐기했으며 최신 동작은 위 남은 높이 복구 항목/ADR-0060을 따른다. 아래는 당시 구현·검증 기록이다.
  - 목적: 화면 크기에 따라 하단 일정 영역의 비율이 달라지는 문제를 개선한다.
  - 확인/근거: 기존 일반 화면은 달력의 고정 행 높이 이후 남은 공간을 Expanded로 채우고, 본문580px 미만/큰 글자에서는 일정 영역을 글자 배율에 따른280px로 배치했다. 일정/근무 설정 카드는 같은 슬롯을 공유한다. 현재 코드·ADR-0004/0007/0016·정본 문맥과 도면의 구형 구조 차이를 확인했다.
  - 변경/Behavior change: 일정/근무 설정 카드를 실제 본문 LayoutBuilder 높이의40% SizedBox에 고정하고, 나머지 상단 공간에 달력 전용 세로 스크롤을 배치했다.40%는 사용자 지정 수치가 아닌 이번 초기 구현값이다. 기존 달력 행 높이·750px 미만2주·형식/확장·월 탐색·목록 내부 스크롤·삭제 오버레이/헤더 배경은 유지한다.6주 월은 달력 스크롤이 필요할 수 있고 짧은 달력은 상단 슬롯 내 여백이 생긴다.40%가 글자 배율 기준144px 미만이거나16px 글자가20px보다 커지면 기존 전체 스크롤/280px×배율로 전환해 가로/큰 글자 조작을 보장한다.
  - 파일/영향범위: calendar_page.dart·기존 calendar_page_test.dart·신규 artifacts/calendar_schedule_ratio_2026-11-12/render_test.dart/PNG10개/measurements.json·PROJECT_CONTEXT/ADR-0059/본 항목. 렌더러의 역할·의존성·재생성 명령은 PROJECT_CONTEXT에 기록했다. 친구/그룹 공용 위젯·라우트/권한/analytics·API/DTO/DB/env·provider 수명과 기존 미커밋 일정 입력/수정/삭제·서버 변경은 보존한다.
  - 테스트: 최종 전체 Flutter **381 pass/기존 skip1**, 메인 페이지 **46 pass**, 실제 MainTabPage 렌더 **1 pass**.320/390/375/430/768px·740/750px 경계·실제 월 이동의4/5/6주·월/2주/주·근무 설정 전환의 카드 Rect·가로/큰 글자 fallback/추가 버튼·기존 일정/삭제/헤더 회귀를 확인했다. 변경 Dart3개 정적 분석 진단0건·포맷 변경0건·git diff --check 통과. 전체 실행의 기존 근무 색상 슬라이더 tap/drag hit-test 경고2건은 이번 변경과 무관하며 앞선 작업 로그에도 기록돼 있다. 관련 페이지/렌더 조작 경고0건이다.
  - 시각 검증: 실제 메인 탭에 상단47px/하단34px 안전영역·정확한 MediaQuery 크기·번들폰트를 사용했다.6개 세로 화면에서 본문/카드 높이371/148.4,553/221.2,615/246,647/258.8,735/294,827/330.8px로 모두40%다.844x390 가로·320x568 글자2배는 전체 스크롤 예외로 추가 버튼에 접근하며 예외0건이다.실제8월6주 달력의 스크롤 전후 카드 Rect 동일을 검증하고 [작은 화면](../artifacts/calendar_schedule_ratio_2026-11-12/small320.png)·[일반 화면](../artifacts/calendar_schedule_ratio_2026-11-12/normal.png)·[6주 스크롤](../artifacts/calendar_schedule_ratio_2026-11-12/six_weeks_scrolled.png)을 시각 확인했다. 작은 카드에서는 일정 행 일부만 보이며 내부 목록 스크롤로 확인한다.
  - 검증 보완/한계: 새 달력 스크롤이 기존 헤더 회귀의 첫 스크롤 검색 대상에 포함돼 일정 카드 내부로 검색 범위를 좁혔다. debug-live 테스트 중단점은 제거했다. 좁은 화면의 기본 테스트 폰트로 발생한 너비 왜곡은 실제 번들폰트 로드로 해결했다. 새 렌더러는 surface만 바꿨을 때의 기본 MediaQuery 크기를 명시적으로 일치시켰고 직접 onPageChanged 호출 대신 실제 월 이동 버튼으로6주 월을 검증했다. 실기기/VoiceOver 인수·배포·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 메인 레이아웃·검증·문서 추가분만 되돌리고 기존 미커밋 작업은 보존한다.

- [DONE] (FE/UX) 캘린더 일정 목록 스크롤의 상단 헤더 색상 전환 수정
  - 목적: 달력 아래의 독립 일정 목록을 스크롤해도 캘린더/친구 이름/그룹 이름 헤더의 배경을 유지한다.
  - 원인/근거: 로컬 Flutter SDK의 CupertinoNavigationBar가 depth0 세로 ScrollUpdateNotification의 extentBefore로 배경/경계를 보간한다. 실제 헤더와 목록의 겹침을 검사하지 않아 달력 아래 목록도 공통 반투명 흰 배경을 활성화했다. debug-live에서 목록161.17px 이동·달력 Rect 동일·헤더 BoxDecoration 색상/경계 변경을 확인했고 수정 전 테스트도 그 차이로 실패했다. 임시 중단점과 디버그 테스트 세션은 정리했다.
  - 변경/Behavior change: CalendarPage·FriendCalendarPage·GroupCalendarPage·GroupCalendarPreviewPage의 기존 헤더에 automaticBackgroundVisibility=false·backgroundColor=AppTheme.background_color·border=null을 지정했다. 스크롤 중에도 기존 정지 상태의 배경/경계를 유지한다. 작은 화면 메인 전체 스크롤에서도 고정하며 ADR-0044의 캘린더 예외를 ADR-0058에 기록했다.
  - 영향범위: 네 캘린더 화면 헤더 표시만 변경한다. 공통 테마·다른 페이지의 자동 전환·제목/뒤로가기/설정·달력/목록·탭/라우트/provider·서버/API/DB는 유지한다. 기존 미커밋 일정 수정/삭제/피커 작업은 보존했다.
  - 파일/문서: 네 페이지·기존 네 페이지 테스트를 갱신했다. 신규 test/helpers/calendar_header_assertions.dart는 실제 세로 목록 이동/맨 위 복귀의 헤더 색상·경계/달력 Rect를 확인하며 역할·의존성·호출 예를 PROJECT_CONTEXT에 기록했다. PROJECT_CONTEXT·DECISIONS/ADR-0058·이번 작업 일지를 최신화했다.
  - 테스트: 신규 실제 스크롤 회귀 **4 pass**, 전체 Flutter **373 pass/기존 skip1**, 수정 Dart9개 정적 분석 **진단0건**. 각 목록의 실제 양수 스크롤과 맨 위 복귀 전후 헤더 BoxDecoration 동일·달력 Rect 동일·예외0건을 확인했다. 관련 화면의 기존 날짜/근무/설정/수정/삭제 테스트도 전체 실행에서 통과했다. 실행: `flutter test --no-pub --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`; 분석은 이번 Dart9개 대상으로 수행했다.
  - 검증 보완/한계: 초기 테스트의 잘못된 ListView/제네릭 finder·중첩 가로 스크롤 식별과 MediaQuery 기본 높이를 실제 화면/세로 목록에 맞춰 보완했다. UI/UX 스킬의 Flutter 목록/고정 영역 지침과 기존 토큰을 확인했으며 레이아웃 재구성은 하지 않았다. 전체 테스트에서 기존 근무 색상 슬라이더의 tap/drag hit-test 경고2건은 동일하게 관찰됐으며 실패는 없다. 실기기 인수·배포·커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 헤더 설정과 관련 검증·문서 추가분만 되돌리며 기존 미커밋 작업은 보존한다.

- [DONE] (FE/UX) 되돌리기 토스트 아래로 쓸어 닫기
  - 목적: 삭제 알림을 아래로 끌어 화면에서 닫을 수 있게 한다.
  - 변경/Behavior change: CalendarDeleteToast에 down Dismissible/표시 전용 onDismiss를 추가했다. 높이50%/기본 아래 fling 판정·수축 없음·이동/복귀180ms·동작 줄이기0ms다. 위/가로·짧은 끌기는 닫지 않고 되돌리기 탭을 유지한다. 제스처 안 Semantics 경계로 접근성 닫기와 독립 Undo/liveRegion을 보존한다.
  - 상태/영향: CalendarPage는 알림 revision별 표시 상태만 숨긴다. 닫아도3초/접근성10초 삭제 타이머·pending map은 유지하며 즉시 전송하지 않는다. 추가 삭제는 새 알림/묶음 Undo를 제공하고 이전 알림의 늦은 닫기 콜백은 무시한다. 기존 서버 실패 복귀·앱 비활성화/dispose/계정 취소·본문/카드/탭 배치를 유지한다. 서버/API/DB·라우팅/provider·기존 미커밋 입력/공개 레벨 작업은 변경하지 않았다.
  - 파일/문서: 기존 토스트/페이지·페이지 회귀와 입력 렌더러를 갱신하고 PROJECT_CONTEXT·ADR-0057·EVENT_API_GUIDE에 정책/영향/롤백을 기록했다. 새 TOAST_DISMISS_RENDER_OUTPUT 옵션과 `artifacts/toast_dismiss_2026-11-12`의 PNG21개/measurements.json 역할·의존성·재생성 예를 컨텍스트에 기록했다. 이전 산출물은 보존한다.
  - 테스트: 최종 전체 Flutter **369 pass/기존 skip1**, 페이지 회귀 **37 pass**(이번 추가7개), 실제 메인 렌더1 pass. 토스트 본문/Undo 위에서 아래 끌기·동작 줄이기·위/가로/짧은 복귀·3초 후 요청1회/Undo 요청0회·추가 삭제/늦은 콜백·실패 복귀/재시도·실제 SemanticsAction.dismiss를 검증했다. 변경 Dart4개 분석 진단0건·포맷 변경0건·diff 검사 통과. 관련 페이지/렌더 hit-test 경고0건이다. 전체 실행에서는 변경하지 않은 근무 색상 슬라이더 테스트의 tap/drag hit-test 경고2건을 관찰했으며 테스트 실패는 없다.
  - 시각 검증: 실제 MainTabPage7조건(320/375/390px·큰글자2배·가로/태블릿·다크/동작줄이기)의 표시/40px 드래그/닫힘 PNG21개를 생성했다. 본문/카드 Rect 동일·탭 위 간격16px·버튼48px/큰글자56px·닫힘 후 항목 계속 숨김·예외0건을 확인했다. normal_drag와 large_text_dismissed를 시각 확인했다. [드래그](../artifacts/toast_dismiss_2026-11-12/normal_drag.png), [닫힘](../artifacts/toast_dismiss_2026-11-12/normal_dismissed.png).
  - 검증 보완/한계: debug-live로 초기 제스처 래퍼가 메시지/Undo semantics를 합치는 원인을 확인하고 내부 container/explicitChildNodes 경계로 해결했다. 실제 접근성 액션 테스트의 핸들은 finally에서 정리하며 임시 중단점/테스트 디버그 세션은 제거했다. UI/UX 스킬의 dragging movements 결과와 기존 토큰/컨트롤을 기준으로 접근성 dismiss/기존 Undo를 유지했다. 실제 기기·VoiceOver 인수/배포·커밋/푸시는 하지 않았다.
  - 롤백: 이번 토스트 제스처/표시 상태와 관련 회귀·문서 추가분만 되돌린다.

- [DONE] (FE/UX) 날짜 확인 확정·오늘 위치·피커 시트 끌어 닫기
  - 목적: 날짜 선택을 확인 버튼으로 확정한 뒤 시간으로 연결하고, 오늘 버튼 재배치와 기존 개인 일정 시트 같은 끌어 닫기를 제공한다.
  - 변경/Behavior change: 날짜 셀 탭/오늘은 시트 내부 선택·요약만 갱신하고 하단 고정 확인에서 날짜를 반환한다. 오늘은 월 내비게이션 오른쪽으로 옮겼다. 확인 후 해당 시간 휠을 열고 시작/종료 입력 구분과 기존 제목 완료/종일 안내는 유지한다. 날짜/시간 공통 PickerSheetFrame이 손잡이/본문 최상단의 아래 끌기를 실제 시트 이동에 연결한다. 실제120px 이상은 취소(null) 닫기, 짧은 고속 끌기는 선택을 보존하고180ms 복귀/동작 줄이기0ms다. 본문 중간·중첩 시간 휠·달력 가로 넘김·프로그램 스크롤은 닫기를 유발하지 않는다.
  - 상태/영향: 확인 전 끌기/취소는 임시 날짜/시간을 폼에 반영하지 않고 다음 피커를 열지 않는다. 시간 끌기 취소 시 이미 확인한 날짜는 유지한다. 부모 폼 제목과 기존 입력·공개 레벨1~5·생성/수정/저장 계약은 보존한다. 공용 시간 피커를 쓰는 근무 타입에도 끌기 취소가 적용되며 반환값은 기존 null 계약이다. 연월 빠른 이동 시트 자체·서버/DB·토스트는 이번 변경에서 건드리지 않았다. 이전 미커밋 서버/DB·폼/삭제 작업은 유지했다.
  - 파일/문서: 날짜/시간/개인 일정 폼·기존 날짜/폼/페이지 회귀·입력 렌더러를 갱신했다. 신규 picker_sheet_frame.dart는 Cupertino/AppTheme/ScrollController 기반으로 body/footer/onDismiss를 받으며 dispose에서 컨트롤러를 정리한다. 신규 picker_sheet_drag_test.dart는 실제 팝업/intl/WidgetTester로 끌기 경계/제스처 분리를 검증한다. 역할/의존성/사용 예와 새 PICKER_CONFIRM_RENDER_OUTPUT 렌더 옵션·PNG24개/measurements.json을 PROJECT_CONTEXT에 기록하고 ADR-0056·EVENT_API_GUIDE·기존 계획의 최신 정책을 연결했다. 과거 PNG는 보존했다.
  - 테스트: 최종 전체 Flutter **362 pass/기존 skip1**, 관련 날짜/시간/폼/메인/끌기 **97 pass**, 실제 MainTabPage 렌더1 pass. 날짜 선택만으로 미반환·확인 후 시간·오늘 상단 위치/선택/확정 분리·미확정 취소·부모 폼 복귀/저장값을 검증했다. 끌기16개는 날짜/시간별 손잡이/본문 충분한 닫기·70px 고속 복귀/값 보존·실제119/121px 경계·큰글자 중간 스크롤과 휠/달력 가로 분리를 확인했다. 변경 Dart9개 정적 분석 진단0건·포맷 변경0건·diff 검사 통과.
  - 시각 검증: 320/375/390px·큰글자2배·가로/태블릿·다크/동작줄이기의 토스트/날짜/시간/공개 범위와 일반 미확정 선택/드래그 PNG24개를 생성했다. 예외/조작 경고0건·확인 버튼48px/큰글자72px·화면/안전영역 내 하단·오늘이 달력 위에 있음과 기존 토스트 본문 Rect 동일을 확인했다. normal_calendar/normal_start_time/large_text_calendar를 시각 확인했다. 큰 글자에서 취소가 세로로 줄바꿈되던 부분은 버튼 좌우 padding을 줄여 가로 표기를 유지했다. [날짜 확인](../artifacts/picker_confirm_drag_2026-11-12/normal_calendar.png), [드래그](../artifacts/picker_confirm_drag_2026-11-12/normal_drag.png).
  - 검증 보완/한계: 렌더에서 Transform 래퍼 자체를 drag 대상으로 삼아 생긴 hit-test 경고는 실제 본문 스크롤 좌표를 사용하는 조작으로 바로잡았고 최종 경고0건을 확인했다. 실제 OS/기기/VoiceOver·실서버 인수와 기존 메인3배/전체 다크 테마는 범위 밖이다. 커밋/푸시·배포는 수행하지 않았다.
  - 롤백: 이번 날짜 확정/오늘 배치·공용 프레임/끌기와 관련 회귀/렌더·문서 추가분만 되돌린다. 기존 공개 레벨/서버·DB·개인 일정 수정/삭제 기능은 보존한다.

- [DONE] (FE/BE/POLICY) 개인 일정 공개 레벨1~5 제한
  - 목적: 레벨0 친구는 근무표만, 개인 일정은1부터 공개할 수 있다는 사용자 기획을 반영한다.
  - 변경/Behavior change: 개인 일정 생성 기본값·연속 슬라이더/숫자·접근성 최소를1로 바꾸고 선택은1~5만 제공한다.0 버튼/모든 친구 기본 설명을 제거했다. CalendarService는 공개/private 모두 생성/수정0/-1/6을 HTTP 전에 INVALID_VISIBILITY_LEVEL로 거절한다. 기존0 응답은 읽기를 유지하고 편집 시1 이상으로 보정해 저장한다는 안내를 표시한다. 원본0·private/정밀시각은 저장 전까지 유지한다. 근무표0·친구0~5 설정과 기존 근무표만 공유 설명·나만 보기 독립 의미는 유지한다.
  - 서버/DB 영향: 인접 서버 route/service·Event min1/max5/default1·개인 일정 OpenAPI 범위와 신규 DDL/정본 도면을 갱신했다. 증분 restrict_event_visibility_levels.sql은 기존 events0만1로 보정하고 기본값/DB CHECK를 맞춘다. transaction·잠금 획득 대기5초·범위 밖 preflight/재실행을 제공하고 다른 필드/근무표/친구 설정·공개 view는 보존한다. 구형 앱의0 요청은 서버 적용 후400이며 기존0 노출 해소에는 서버 배포와 SQL 적용이 필요하다. 실제 운영에는 적용하지 않았다.
  - 파일/문서: 기존 personal_event_form_modal/calendar_service·폼/서비스 회귀와 입력 렌더러, 루트 schema/visibility_flow·로컬 AGENTS의 개인 일정 DDL만 갱신했다. PROJECT_CONTEXT·ADR-0055·EVENT_API_GUIDE와 인접 서버 컨텍스트/ADR-0046/작업 일지·수정/비공개 가이드를 정합화했다. 신규 서버 SQL·EVENT_VISIBILITY_GUIDE와 공개 범위 PNG7개/measurements.json의 역할/의존성/사용 예는 양 컨텍스트에 기록했다. 서버 gitignore는 신규 비밀 없는 SQL만 예외 처리한다. 기존 미커밋 수정/입력/삭제 작업과 과거 PNG는 보존했다.
  - 테스트: 최종 전체 Flutter **343 pass/기존 skip1**, 폼/서비스 **61 pass**, 실제 메인 렌더1 pass. 생성 기본1·1~5 선택/저장·0 미노출·접근성1 하한·private 레벨 보존·기존0 편집 안내/저장·HTTP 전0/-1/6 차단과1/5 경계 전송을 검증했다. 변경 Dart5개 분석 진단0건·포맷 변경0건·양 저장소 diff 검사·JSON/XML 파싱 통과. 실제 메인7조건(320/375/390px·큰글자2배·가로/태블릿·다크/동작줄이기)에서 min1/max5/default1·0 미노출/예외0건을 확인했다. normal_visibility PNG를 시각 확인했다. [공개 범위](../artifacts/personal_event_visibility_2026-11-12/normal_visibility.png).
  - 서버 검증: TypeScript strict build·서비스/인증 HTTP12 pass·이번 전용 PostgreSQL/실제 HTTP9 pass. 기존0→1 외 필드 동일·이상값6 preflight 원자 거절·재실행/기본1/DB0·-1·6 거절·레벨0 친구/그룹 근무만 조회·private/ACL·수정/삭제 경합을 확인했다. 전체93 pass/17 fail/13 skip, 변경 전91 pass/17 fail/13 skip과 실패 이름이 동일해 신규 실패0개다. 기존 비공개 배포 파일/Apple 계약 실패는 범위 밖이다. 생성한 전용 컨테이너/네트워크는 정리했다.
  - 결과/한계: 앱/서버 로컬 구현·자동 검증 완료. 신규 패키지/env·Stage/운영 배포/운영 데이터 보정·실기기/원격 인수·커밋/푸시는 수행하지 않았다. 서버 적용 순서·구형 요청 호환과 안전 롤백은 인접 EVENT_VISIBILITY_GUIDE를 따른다.
  - 롤백: 이번 개인 일정 레벨 정책/검증·문서 추가분만 되돌리되 보정된1을0으로 바꾸거나 private/ACL을 제거해 개인 일정을 다시 노출하지 않는다.1~5를 유지하는 호환 소스로 복구한다.

- [DONE] (FE/UX) 삭제 토스트 오버레이와 개인 일정 입력 단계 개선
  - 목적: 삭제 토스트를3초로 줄이고 본문 배치를 움직이지 않으며, 캘린더 날짜/휠 시간과 다음 입력 연결을 제공한다.
  - 변경/Behavior change: 메인 본문을 Stack의 원래 크기로 배치하고3초(접근성 탐색10초) 토스트를 Positioned 오버레이로 전환했다. 본문 밖 배리어 없이 다른 날짜/탭 조작을 유지하고 기존 계정/revision·묶음 취소·앱 비활성화/dispose 미전송 취소 정책은 보존한다. 사용자가 앱 종료 제약을 수용해 영속 큐는 추가하지 않았다. 날짜 휠/별도 적용을 TableCalendar 월간 날짜 탭 즉시 선택으로 바꿨고, 월 이동/연월 빠른 이동·오늘/범위/날짜 semantics·요일색을 제공한다. 시간은 기존24시간 휠을 유지하며 화면 높이 제한/스크롤·고정 취소/적용을 보완했다.
  - 입력 단계/영향: 신규 제목 완료 → 시작 날짜 → 시작 시간 → 종료 시간 → 공개 범위 스크롤. 당일 종료를 기본으로 하고 다른 날짜는 종료일에서 직접 선택한다. 종일은 시작/종료 날짜만 고른다. 빈 제목은 오류/제목 포커스, 피커 취소는 안내 중단/입력 보존이다. 직접 날짜 편집은 해당 시간만 열며 수정 모드에는 생성 전체 흐름을 강제하지 않는다. 신규 안내에서 시작이 종료 이상이면 시작+1시간을 종료 기본값으로 제안하며 자정 넘김도 반영한다. 원본 정밀 시각·종일 배타적 종료·수동 start<end 검증은 유지했다. 피커 중복 진입/닫기와 route.completed 후 다음 진입을 적용한다. 공용 시간 피커의 근무 타입 호출에는 높이/스크롤/전환 완료 대기만 공유된다.
  - 파일: calendar_page.dart·date_picker_sheet.dart·time_picker_sheet.dart·personal_event_form_modal.dart와 기존 페이지/날짜/폼 회귀3개를 갱신했다. 신규 `artifacts/calendar_input_flow_2026-11-12/render_test.dart`·PNG22개/measurements.json의 실제 MainTabPage/모의 서비스·번들폰트 의존성과 재생성 예를 PROJECT_CONTEXT에 기록했다. PROJECT_CONTEXT·DECISIONS(ADR-0053/0054)·EVENT_API_GUIDE·기존 편집 계획의 최신 안내를 반영했다. 기존 미커밋 편집·API/폼·과거 렌더 산출물은 보존했으며 새 패키지/서버/DB/env·provider/라우팅/analytics 변경은 없다.
  - 테스트: 최종 전체 Flutter **331 pass/기존 skip1**, 관련 입력/페이지 회귀76개·실제 메인 렌더1개 통과. 제목 완료의 실제 IME done·빈 제목·중복 진입·날짜/시간 취소·종일·직접 편집·늦은 시작의 자정 종료 제안/저장·월 경계/범위/연월 취소를 검증했다. 토스트 전후 달력/카드/추가 버튼 Rect와 스크롤 분기 동일·바깥 날짜 탭·3초 경계·기존 삭제/실패/계정 회귀를 확인했다. 공용 피커를 쓰는 근무 타입/그룹/폼 저장 등 전체 회귀도 통과했다. 변경 Dart8개 정적 분석 진단0건·최종 포맷 변경0건·diff 검사 통과.
  - 시각 검증: 실제 MainTabPage7조건(320/375/390px·큰글자2배·가로/태블릿·다크와 동작줄이기)의 토스트/캘린더/시간 휠·일반 공개 범위 PNG22개를 생성했다. 예외0건·토스트와 탭 간격16px·버튼48px/큰글자56px·본문 Rect 동일이다. normal_toast/normal_calendar/normal_start_time/large_text_calendar를 시각 확인하고 큰글자에서 두 자리 날짜가 셀을 벗어나 줄바꿈되던 것을 FittedBox/한 줄 표시로 보완한 최종 렌더를 확인했다. [토스트](../artifacts/calendar_input_flow_2026-11-12/normal_toast.png), [날짜 캘린더](../artifacts/calendar_input_flow_2026-11-12/normal_calendar.png), [시간 휠](../artifacts/calendar_input_flow_2026-11-12/normal_start_time.png).
  - 검증 보완/한계: debug-live에서 공개 범위 Padding의 빈 부분 대신 실제 `친구에게 공개` 컨트롤이 화면 안에 있고 누를 수 있음을 확인해 검증 대상을 수정했다. 렌더의 ensureVisible이 날짜 그리드의 가로 PageView도 이동시키는 문제는 실제 세로 스크롤/날짜 탭으로 재현 경로를 바꿨다. 임시 중단점/디버그 세션은 정리했다. UI 스킬 검색은 날짜/포커스 흐름에 맞는 결과가 없어 기존 코드·사용자 요청·위젯/시각 검증을 기준으로 세부를 결정했다. 토스트는 잠시 본문 일부를 덮을 수 있으며 레이아웃/바깥 조작을 유지한다. 실기기 키보드 전환·휠 촉감/VoiceOver·실서버 저장 인수는 미수행이고 기존 메인3배 넘침/전체 다크 테마는 범위 밖이다. 커밋/푸시·배포는 하지 않았다.
  - 롤백: 이번 토스트 시간/배치와 날짜·시간 피커/입력 연결 및 관련 검증/문서 추가분만 되돌린다. 기존 개인 일정 수정 기능과 사용자 데이터는 유지한다.

- [DONE] (FE/UX) 메인 일정 삭제 토스트와 되돌리기
  - 목적: 메인에서 실수로 삭제한 개인 일정/근무를 잠시 되돌릴 수 있게 한다.
  - 변경/영향범위: 본인 개인 일정·근무를 화면에서 먼저 숨기고5초(접근성 탐색10초) 후 기존 DELETE를 보낸다. 연속 삭제는 묶고 시간을 다시 시작하며 되돌리기는 미확정 묶음을 모두 취소한다. 원본 캐시는 보존해 ID/private·시각/레벨/선택정보·근무 스냅샷 재생성 없이 복원한다. 삭제 실패는 항목을 다시 표시하고 오류 하나로 안내한다. 개인 일정404/잘못된 ID 처리·그룹 캐시 무효화와 근무 GET mutation 보정을 적용했다. 근무 삭제 대기/요청 중 입력 진입을 잠가 재저장 경합을 막는다.
  - 수명/Behavior change: 앱 비활성화/화면 dispose/계정 변경은 미전송 예약을 취소한다. 이미 보낸 요청의 이전 계정/revision 완료 결과는 무시한다. 탭 변경은 IndexedStack 수명에 따라 유예 시간을 유지한다. 요청 시작 후에는 되돌릴 수 없으며 미확정 삭제는 영속 저장하지 않는다. 친구/그룹 읽기 전용 화면·서버 DELETE/DB/env·라우팅/analytics는 유지한다.
  - 파일: 기존 calendar_page.dart·calendar_range_notifier.dart와 페이지/notifier 회귀를 갱신했다. 신규 calendar_delete_toast.dart는 Cupertino/AppTheme 표시 위젯이며 페이지가 count/onUndo를 주입한다. 신규 artifacts/calendar_delete_undo_2026-11-12/render_test.dart·PNG7개/measurements.json은 실제 MainTabPage·모의 서비스·번들폰트 렌더를 담당한다. 역할/의존성/재생성 예를 PROJECT_CONTEXT에 기록했다. PROJECT_CONTEXT·DECISIONS(ADR-0052)·EVENT_API_GUIDE·기존 편집 계획의 최신 정책 안내를 반영하고 기존 미커밋 개인 일정 수정·폼/검증은 보존했다.
  - 테스트: 최종 전체 Flutter **321 pass/기존 skip1**, 관련 페이지/notifier/렌더 **40 pass**. 기본5초/접근성10초 경계·짧은 스와이프/요청 중 숨김·원본값/다일·유예 중 재조회·연속 시간 재시작·혼합 삭제의 취소/확정/부분 실패·404/오류 집계·계정 변경 전후·dispose/앱 비활성화·늦은 GET의 근무 갱신/삭제 보정을 검증했다. 변경 Dart6개 정적 분석 진단0건·포맷 변경0건·diff 검사 통과.
  - UI/결과: 토스트 단독은320/375px·가로/태블릿·글자1/3배·라이트/다크32조건에서 예외0건·버튼48px 이상·하단34px 안전영역/좌우여백·접근성 버튼/탭/포커스를 확인했다. 실제 메인 렌더7개는320/375/390px·글자2배·가로/태블릿·다크에서 예외0건, 토스트와 탭 간격16px·버튼48px/확대56px이다. normal/large_text/dark PNG를 시각 확인했다. [기본 화면](../artifacts/calendar_delete_undo_2026-11-12/normal.png), [큰 글자](../artifacts/calendar_delete_undo_2026-11-12/large_text.png).
  - 검증 보완/한계: 이전 즉시 DELETE 기대를 새 유예 정책으로 갱신했다. debug-live로 버튼의 내부 SemanticsNode에 되돌리기/버튼/탭·포커스가 있음을 확인해 상위 버튼 key 대신 semantics label을 검증하고 핸들을 테스트 종료 전 해제했다. CLI에서 실제 메인 글자3배는 삭제 전부터65px 수평 넘침이 있음을 확인해 목표 밖 기존 화면 수정은 하지 않았다. 신규 토스트만3배까지, 실제 메인은 기존 지원 확인 범위2배까지 검증했다. 다크 검증은 신규 토스트 가독성/배치 범위이며 기존 앱 전체 테마의 인수를 뜻하지 않는다. SDK 캐시 제한은 검증 명령 권한으로 해결했다. 디버그 세션/추가 중단점은 정리했다. 실기기/VoiceOver·실제 서버 DELETE 인수·배포/커밋/푸시는 수행하지 않았다.
  - 롤백: 이번 삭제 예약/필터·토스트·근무 조회 보정 및 관련 테스트/렌더·문서 추가분만 되돌린다. 기존 미커밋 편집 기능과 사용자 데이터를 보존한다.

- [DONE] (FE/BE) 메인 캘린더 개인 일정 탭 수정 구현
  - 목적: 승인된 탭 수정·스와이프 삭제 UX와 서버 저장/캐시 갱신 흐름을 구현한다.
  - 변경/영향범위: 공통 PersonalEventFormValue/수정 전용 DTO·PUT service, 기존 시트 편집 초기화/무변경 저장 차단·정밀 시간/종일 종료 복원·null 삭제·구조화 저장 결과/목록 재확인을 구현했다. 메인 행 탭·연필/수정·스와이프 삭제 텍스트/처리 피드백·접근성 삭제 액션·계정 완료 확인을 연결했다. notifier 원자 교체/늦은 GET 보정·그룹 캐시 무효화·선택일 유지/새 시작일 이동을 추가했다. 공용 개인 일정 시간/장소 Wrap은 읽기 전용 행의 큰 글자 넘침도 보완한다.
  - 파일: event_api_model/calendar_service/calendar_range_notifier·personal_event_form_modal/calendar_page/calendar_schedule_card·기존 회귀4개·PROJECT_CONTEXT/DECISIONS(ADR-0051)/EVENT_API_GUIDE/기존 계획. 신규 `artifacts/personal_event_edit_2026-11-12/render_test.dart`·PNG19개/measurements.json의 역할/의존성/재현은 컨텍스트에 기록했다. 인접 서버 route/controller/service/OpenAPI·새 eventEditing 단위/HTTP 및 기존 eventPrivacyIntegration·EVENT_EDIT_GUIDE/컨텍스트/ADR-0045/작업 일지도 반영했다. 기존 미커밋 폼 디테일/테스트/문서를 보존했다.
  - 테스트: 최종 전체 Flutter **308 pass/기존 skip1**. 변경 Dart13개 분석 진단0건·포맷 변경0건·양 저장소 diff 검사 통과. 신규 수정/캐시/폼/페이지 회귀16개가 UTC/null·ID/private 확인·무변경/정밀 시각·종일 기간·실패/재시도/404·제스처 분리/삭제 중 잠금·계정 변경·다일 선택일/기간 이동을 검증했다. 실제 MainTabPage 진입 렌더1 test/PNG19개·측정 통과:320/375/390px·글자2배·키보드inset·가로/태블릿·동작줄이기, 예외0건·저장높이52/확대76·키보드 위 위치. 목록/스와이프/삭제 중/수정·큰글자·키보드 PNG를 시각 확인했다.
  - 서버 검증: strict build·관련 서비스/인증HTTP10 pass, 실제 전용 PostgreSQL16/HTTP8 pass. 소유권/soft-delete·null 삭제·기간 이동·private 공개 전환/친구·그룹 필터·timestamps/삭제 경합을 확인했다. 전체91 pass/17 fail/13 skip, 변경 전 HEAD 사본86 pass/17 fail/15 skip과 실패17개 이름이 동일해 신규 실패0개다. 기존 비공개 배포 파일·Apple 계약 실패/로컬 Git 제외 파일 차이는 범위 밖으로 보존했다. 이번에 생성한 DB 컨테이너/네트워크는 제거했다.
  - 검증 보완: debug-live에서 신규 테스트의 저장 호출0회/저장중false를 확인해 입력 후 프레임 대기를 보완했다. 서버 UPDATE RETURNING timestamp가 createdAt/updatedAt으로 매핑되는 값을 직접 확인하고 수정 응답 fallback을 추가했다. 렌더에서 큰글자 시간/장소 넘침, 무변경 버튼 대비·삭제 중 방향 변경 문제를 찾아 보완했다. 렌더 측정 I/O는 tester.runAsync로 실행한다. 선택일은 시각 성분을 정규화해 다일 마지막 날에도 유지한다. 중단점/세션·임시 서버 디버그 파일을 정리했다. 검사 범위가 넓어 생긴 목표 밖 포맷4개는 원본으로 복구했다.
  - 결과/한계: 로컬 구현·자동 검증 완료. DB migration/env·서버 배포/Stage·운영 원격 인수·실기기/VoiceOver·다크 테마 인수·커밋/푸시는 수행하지 않았다. 서버 PUT을 배포해야 원격 저장이 가능하다. 실제 기기·인증 사용자별 저장/조회 인수는 후속 작업이다.
  - 롤백: 이번 수정 기능 관련 변경만 되돌리고 기존 생성/삭제·private 필터/데이터를 보존한다.

- [DONE] (FE/UX/PLAN) 개인 일정 수정·삭제 동시 제공 UX 검토
  - 목적: 기존 왼쪽 스와이프 삭제 디자인을 유지하면서 탭 수정의 발견성과 제스처 충돌 처리를 구체화한다.
  - 변경/영향범위: 현행 행·Dismissible·삭제 회귀를 직접 확인했다. 기존 계획3.1절에 행 탭 수정+왼쪽 스와이프 삭제, 개인 일정의 chevron→연필/수정, 빨간 배경/삭제 텍스트·처리 피드백·제스처 판별·스크린리더 삭제 액션을 제안했다. 삭제는 노출 버튼 탭이 아닌 dismiss 성립 시 요청하는 현행 방식으로 유지한다. `_docs/PERSONAL_EVENT_EDIT_PLAN.md`·`PROJECT_CONTEXT.md`·`WORKLOG.md`만 보완하고 앱 코드는 변경하지 않았다. 이전 계획의 개인 일정 chevron 유지 제안은 이번 제안으로 대체한다.
  - 테스트: 현행 코드/삭제 테스트와 기존 빈 목록 캡처를 확인했다. 캡처는 일정 행 검증 근거가 아님을 명시했다. 계획의 표시/상태/롤백·컨텍스트 링크 및 `git diff --check`를 확인한다. 문서만 변경해 Flutter 테스트/새 UX 렌더·실기기 인수는 실행하지 않았다. 확정 전 제안이므로 ADR은 추가하지 않았다.
  - 롤백: 이번 UX 계획 보완분만 제거한다.

- [DONE] (FE/PLAN) 메인 캘린더 개인 일정 탭 수정 기능 계획
  - 목적: 근무와 구분되는 본인 개인 일정을 탭해 기존 값을 수정하는 기능의 구현 범위와 인수 기준을 정한다.
  - 변경: 현행 캘린더/폼/상태/API·인접 서버 route/controller/service/모델/OpenAPI·양쪽 도면을 직접 확인하고 [개인 일정 수정 계획](PERSONAL_EVENT_EDIT_PLAN.md)을 작성했다. 개인 일정 탭→기존 시트 편집 모드, 서버 PUT 선행 계약, 선택정보 null 삭제·종일 종료일 복원·private 보존, 날짜 전체 캐시 교체/늦은 GET 보정·오류/인수/롤백·구현 순서를 정리했다. 확인 사실과 구현 제안을 구분했다.
  - 영향범위/파일: 신규 `_docs/PERSONAL_EVENT_EDIT_PLAN.md`, 기존 `_docs/PROJECT_CONTEXT.md`·`_docs/WORKLOG.md` 추가분. 앱/서버 구현·배포·커밋/푸시는 수행하지 않고 기존 미커밋 폼/테스트/문서를 보존했다. 신규 문서의 역할/의존성/사용 예를 컨텍스트에 기록했다. 정책 확정 전 계획이므로 새 ADR은 추가하지 않았다.
  - 테스트: 계획 9개 절·근거 파일16개 존재·컨텍스트 상대 링크·구현 전 상태 확인 스크립트 및 `git diff --check` 통과. 문서만 변경하여 Flutter/서버 테스트·수정 API 실응답 인수는 실행하지 않았다. 로컬 코드의 수정 API 부재를 확인한 것이며 원격 배포 상태는 미확인이다.
  - 다음: 계획의 서버 PUT 계약 검토/구현·검증 후 Flutter DTO/service→notifier→폼→메인 연결→회귀/실기기 인수 순서로 진행한다.
  - 롤백: 이번 계획 및 문서 추가분만 제거한다.

## 2026-11-11

- [DONE] (FE/UI) 개인 일정 입력 디테일 정리
  - 목적: 날짜/시간의 연도 보조 표시와 기간 계산 문구를 제거하고 장소·메모를 기본으로 펼치며 공개 레벨 조작을 부드럽게 한다.
  - 변경: 헤더 연도·기간/다음날/종일 합계와 미사용 계산 함수를 제거했다. 장소·메모는 기본 펼침이며 접어도 입력을 보존한다. 공개 슬라이더는 연속 double 위치/정수0~5 선택값을 분리하고 드래그 중 즉시 추적·놓기/숫자 선택 시180ms easeOutCubic 정렬을 적용했다. 동작 줄이기는 정렬 애니메이션을 생략하고 접근성 증감은 정수1단위를 유지한다. 레벨1~5 공개 안내에서 `열람을 허용한 친구 중,`을 제거했다.
  - 영향범위/파일: 기존 personal_event_form_modal.dart·폼/저장 회귀2개·기존 시트 렌더러·PROJECT_CONTEXT/DECISIONS(ADR-0050)/EVENT_API_GUIDE. 렌더러는 기본 펼침 메모를 직접 검사하며 PERSONAL_EVENT_RENDER_OUTPUT으로 출력 경로를 지정할 수 있다. 신규 파일·API/DB/서버·provider/라우트 변경·커밋/푸시는 없다. 날짜 선택기/다른 연도 날짜 표시·시간 검증·종일 배타적 종료·기존 닫기 거리는 유지한다.
  - 테스트: 관련 위젯31개 통과. 기본 펼침/접기 보존·문구 제거·연속 드래그의2px 갱신/정수 저장·정렬 애니메이션/동작 줄이기·private 전환 레벨 복원·시간/종일/저장/닫기 회귀를 확인했다. 기존 실제 캘린더 진입 렌더1 test/17개 PNG·measurements.json 통과: 320/375/390px·큰글자2배·키보드inset·가로·태블릿에서 예외0건/저장·입력 접근 확인. 산출물은 /private/tmp/personal_event_details_2026-11-11에 생성해 과거 PNG를 보존했고 기본·상세·레벨3·375px을 시각 확인했다. 변경 Dart4개 정적 분석 진단0건·포맷 변경0건·diff 검사 통과.
  - 검증 과정/한계: 최초 슬라이더 회귀의2px 이동은 실제 반올림 경계를 넘었으므로 같은 정수여야 한다는 불필요 기대를 제거하고 연속 위치 변화·정수 정렬/저장을 검증했다. debug-live는 신규 테스트를 탐색하지 못해 CLI 회귀와 로컬 SDK 드래그/반올림 구현으로 확인했고 추가한 중단점은 제거했다. SDK 캐시/도구 기록 쓰기 제한은 승인된 검증 명령으로 해결해 종료0을 확인했다. 기존 라이트 폼·모의 API/키보드inset 기준이며 실제 기기 조작감·VoiceOver/다크 테마 인수는 수행하지 않았다.
  - 롤백: 이번 UI 변경과 관련 문서/검증만 되돌리고 기존 시트 닫기 거리 변경은 보존한다.

- [DONE] (FE/UX) 개인 일정 시트 닫기 거리 강화
  - 목적: 짧고 빠른 끌기만으로 닫히는 동작을 수정하고 시트를 충분히 내렸을 때만 닫는다.
  - 변경: 공통 _endSheetDrag의 기존64px 또는 아래속도700px/s 조건을 실제 시트 이동120 논리px 이상 조건으로 대체했다. 짧은 끌기는 빨라도 원위치로 복귀하고 입력을 보존한다. 손잡이와 본문 상단 양쪽에 적용한다.
  - 영향범위/파일: personal_event_form_modal.dart·기존 폼 테스트·PROJECT_CONTEXT·DECISIONS(ADR-0049). 확인 없는 닫기·저장 중 차단·중간 본문 스크롤·가로 슬라이더·API/DB는 유지한다. 신규 파일·커밋/푸시는 없다.
  - 테스트: 구코드에서70px/2000px/s 끌기로 시트가 닫히는 회귀를 먼저 재현했다. 양쪽 경로의 짧은 고속 끌기 복귀/입력 유지2개와 실제 시트119px/121px 이동의 경계4개를 추가하고 기존 충분한 끌기/저장 중 차단 테스트를 조정했다. 인식 시작 때 이동한 양도 측정해 합산하며 본문 좌표의 소수 오차를 피하도록 경계 양옆을 검증한다. 최종 전체 Flutter291 pass·기존 skip1, 변경 Dart2개 정적 분석 진단0건·포맷 변경0건·diff 검사 통과.
  - 검증 한계: 위젯 제스처 기준이며 실기기 조작감 인수는 수행하지 않았다. DebugMCP의 신규 테스트 탐색이 되지 않아 CLI 회귀로 확인했고 추가했던 중단점은 정리했다. 화면 구도/크기/색상 변경은 없다.
  - 롤백: 이번 거리 판정·관련 테스트/문서만 되돌린다.

- [DONE] (GIT/QA/DOCS) 누적 변경사항 작업별 커밋 및 푸시
  - 목적: 사용자 요청에 따라 누적 구현·테스트·문서·검증 산출물을 작업 단위로 분리해 원격 저장소에 보존한다.
  - 변경: 디자인 검토 자료·공통 내비게이션/설정/그룹 UI·색상 선택·근무 타입·프로필·개인 일정의 6개 커밋으로 분리했다. 공통 파일의 인증 전환/폼 저장·통합 테스트는 인덱스에서 해당 작업 부분만 분리해 각 커밋에 관련 컨텍스트·ADR·작업 기록을 포함했다. 앱 코드 추가 수정은 없으며 기존 변경 Dart 51개가 최종 인덱스와 바이트 단위로 일치함을 확인했다.
  - 영향범위: 기존 미커밋 구현·테스트·문서·시안/PNG/측정 JSON과 이번 검증 기록. 기존 ADR/상세 컨텍스트의 후속 정책 안내는 마지막 문서 정합성 커밋으로 정리한다. 서버 배포·스토어 작업은 포함하지 않는다.
  - 테스트: 전체 Flutter 285 pass·기존 skip 1. 변경 Dart 51개 분석 진단 0건·포맷 변경 0건. 별도 인덱스 스냅샷에서 내비게이션/설정/시간대 14개·색상/기존 폼 호환 40개·근무 타입/저장/provider 24개·프로필/가입/설정 30개 통과. GROUP_API_ENABLED/GROUP_P1_ENABLED=true 그룹 관리 2개 통과. 측정 JSON 10개 파싱 및 staged/unstaged diff 검사 통과. 최초 SDK 캐시·Dart 도구 기록 쓰기 제한은 검증 명령 권한을 확보해 종료 코드 0으로 재확인했다.
  - 결과/커밋: `1b39f9e` 디자인 검토, `7b96cce` 고정 글라스 탭/공통 UI, `2171d42` 색상 농도/제스처, `de7c55c` 근무 타입, `e4e24df` 프로필, `1b7017e` 개인 일정/private. 일반 push 성공과 HEAD=origin/main=`1b7017e706dd8afd8b9e96dd9e76c124bd436256`을 확인했다. 이번 최종 검증·상세 문서 정합성 기록은 후속 문서 커밋으로 보존하고 추가 푸시한다.
  - 검증 한계: 이번 검증은 기존 자동 회귀·분리 경계·정적 검사이며 실기기/VoiceOver·실제 푸시·원격 사용자별 private 응답 인수를 새로 수행하지 않았다. 기존 후속 인수 항목은 유지한다.
  - 롤백: 작업별 커밋을 의존성 역순으로 git revert한다.

- [DONE] (FE/UI) 개인 일정 상단 스크롤 끌어 닫기와 폐기 확인 제거
  - 목적: 본문 스크롤 최상단에서 아래로 끌어 시트를 닫고 작성 여부와 관계없이 확인 없이 닫도록 사용자 요청을 반영한다.
  - 범위: 개인 일정 닫기/본문 스크롤 제스처·회귀·문서. 저장 중 차단과 제목/시간/API 검증은 유지한다.
  - 변경: 본문 depth0·사용자 dragDetails·최상단 음수 overscroll을 기존 시트 이동/닫기에 연결했다. AlwaysScrollable+Clamping physics로 짧은 콘텐츠와 플랫폼 차이를 처리하고 본문/손잡이 드래그 상태를 구분한다. 짧은 끌기는 복귀하고 중간 스크롤은 목록만 이동한다. 변경 감지·내용 버리기/계속 작성 dialog·이탈 확인 분기를 제거해 손잡이/본문 상단 끌기·닫기 버튼·OS 복귀가 즉시 닫히게 했다. 저장 중 차단·필수/API 검증·실패 보존은 유지하고 중복 pop을 방지한다.
  - 영향범위: 개인 일정 폼/회귀·PROJECT_CONTEXT/DECISIONS/EVENT_API_GUIDE/서버 요청서의 최신 닫기 정책. 화면 모양/생성·private API/서버·DB/글로벌 테마·provider/analytics는 변경하지 않는다.
  - 테스트: 폼/저장24개 통과. 최상단 작성 후 끌기/손잡이 이동·짧은 끌기 복귀/입력 유지·긴 메모 중간 스크롤은 목록만 이동·작성 후 X/OS 복귀의 확인 없는 닫기/저장 요청0회·저장 중 손잡이/본문/OS 복귀 차단·기존 슬라이더/private/시간 검증을 확인했다. 전체 Flutter285 pass·기존 skip1. 기존 실제 캘린더 진입 렌더1 test/17개 PNG·측정 통과, 작은 화면/큰글자/키보드 조건 예외0건. 변경 Dart2개 정적 분석 진단0건·포맷·diff 검사 통과. 제품 코드의 폐기 확인 문자열/상태/분기 제거도 확인했다.
  - 결과: ADR-0048과 기존 모달 문서의 본문 끌기/즉시 닫기·롤백/한계를 갱신했다. 신규 파일/서버 변경·커밋/푸시는 없다. 기존 미커밋 작업은 보존한다.
  - 검증 한계: 모의 위젯/키보드inset 기준으로 실제 OS/VoiceOver/실기기 인수를 대체하지 않는다. 최상단/끝 바운스는 clamping이며 최상단 끌기는 시트 이동으로 전달한다.
  - 롤백: 이번 닫기/본문 스크롤 변경과 관련 테스트/문서만 되돌린다.

- [DONE] (FE/UI) 개인 일정 슬라이드업 모달과 인라인 공개 레벨
  - 목적: 사용자 요청대로 일정 추가를 아래에서 올라오는 시트로 표시하고 친구 공개/나만보기와 0~5 레벨을 화면에서 직접 조절한다.
  - 범위: 개인 일정 폼·기존 진입 흐름 확인·관련 회귀/렌더·문서. 기존 생성/private API와 저장/이탈 정책을 유지한다.
  - 변경: 기존 root popup 애니메이션에 화면88%/최대폭560/반경28의 시트·손잡이·닫기를 적용했다. 캘린더 dim 배경/고정 저장을 유지하고 키보드 위 가용높이에 맞춘다. 상단 드래그는 실시간 이동/복귀와 기존 폐기 확인을 연결하며 본문 스크롤·가로 슬라이더와 분리했다. 공개 방식 세그먼트·친구 공개 전용0~5 정수 CupertinoSlider/숫자 탭·의미 설명으로 공개 선택 시트를 대체했다. private 전환 시 레벨을 보존한다.
  - 영향범위: 폼·관련 폼 회귀·신규 실캘린더 진입 렌더·PROJECT_CONTEXT/DECISIONS/EVENT_API_GUIDE/서버 요청서 최신 UI 설명. CalendarPage 진입부는 직접 확인했으며 코드 수정 없이 기존 root modal/콜백을 재사용한다. API/DB/서버·글로벌 테마·provider/analytics는 변경하지 않는다.
  - 테스트: 전체 Flutter281 pass·기존 skip1. 폼/저장 회귀20개 통과: 실제 native slider 드래그/정수 저장·숫자0~5·private/공개 복원·바깥 탭 차단·시트 상단/하단·손잡이 이동/폐기/복귀·미변경 닫기·기존 시간/입력/이탈/비동기 저장. 렌더 별도1 test·17개 PNG/measurements.json 통과: 실제 MainTabPage/CalendarPage 일정 추가 버튼·모의 API·320/375/390px·큰글자2배·키보드inset·가로·태블릿·private/레벨3에서 예외0건. 시트 상단 최소59px·하단 키보드 위·저장52/확대76·본문 입력 접근/고정 저장·저장라벨 픽셀을 확인했다. 390×844 기본 시트 top101.28/높이742.72이며 주요 기본/레벨/private/키보드 PNG를 시각 확인했다. 최종 Dart3개 정적 분석 진단0건·포맷·diff 검사 통과.
  - 검증 과정: 최초 단일 move로 만든 슬라이더 테스트에서 값0이 유지되는 현상은 debug-live로 값/좌표를 확인하고 SDK _handleDragStart/_handleDragUpdate를 대조했다. 인식 시작 뒤 갱신 이벤트가 없던 테스트 제스처를 두 단계 move로 수정해 실제 드래그를 검증했다. 중단점/세션을 정리했다. 렌더 미사용 import 경고는 제거했다. SDK 캐시 쓰기는 승인된 검증 명령으로 실행했다.
  - 결과: [슬라이드업 모달](../artifacts/personal_event_sheet_2026-11-11/normal.png), [레벨3](../artifacts/personal_event_sheet_2026-11-11/visibility.png), [나만 보기](../artifacts/personal_event_sheet_2026-11-11/private.png). ADR-0047과 신규 렌더 파일 역할/의존성/재생성·키보드/닫기 정책을 기록했다. 이전 시안/렌더와 기존 미커밋 작업은 보존한다.
  - 검증 한계: 위젯/모의 API·키보드inset/라이트 테마 기준으로 실제 OS 키보드·스크린리더·실기기/원격 인증 사용자별 인수를 대체하지 않는다. 서버 배포·커밋/푸시는 하지 않았다.
  - 롤백: 이번 모달/공개 조절·관련 검증/문서만 되돌린다.

- [DONE] (FE/UI/API) 개인 일정 구도 재정리와 나만 보기 연동
  - 목적: 사용자 피드백에 따라 카드/중첩 입력 위주의 화면을 가벼운 행 중심 구도로 다시 구성하고 배포 완료된 나만 보기 계약을 연결한다.
  - 범위: 개인 일정 폼·이벤트/그룹 DTO·서비스 응답 확인·회귀/렌더·문서. 서버 배포 완료는 사용자 확인이며 로컬 구현과 대조한다.
  - 변경: 중첩 카드/입력 테두리·두꺼운 영역 제목을 제거해 흰 바탕·26px 제목·시작/종료 행·얇은 구분선·공개/선택정보 행으로 재구성했다. 시간에만 작은 중립 배경을 사용하고 기본375/390px에서 장소/메모 진입까지 보인다. 기존 저장/이탈/입력 보존·날짜/종일 계약을 유지한다. 나만 보기를 실제 선택 가능하게 하고 is_private boolean 전송·일정/그룹 응답 파싱·생략 false 호환을 추가했다. private 생성 응답 true 불일치는 성공으로 닫지 않는다.
  - 영향범위: 폼·event API 모델/service·그룹 domain/파서·관련 테스트4개·새 렌더·문서. 서버/DB/글로벌 테마·인증/라우트·provider 수명/analytics는 변경하지 않았다. 서버 정본 가이드·실제 route/service/뷰와 계약을 대조했으며 배포 완료는 사용자/서버 문서 기록 기준이다.
  - 테스트: 전체 Flutter 회귀277 pass·기존 skip1. 관련 폼/모델/service/그룹/저장29개와 렌더1 test가 통과했다. 공개/private 명시 boolean·레벨 보존·구형 응답·private 취소/공개 전환·응답 불일치·기존 시간/저장/이탈을 검증했다. 17개 PNG/measurements.json: 320/375/390px·큰글자2배·키보드inset·가로·태블릿·공개시트·private에서 예외0건, 저장52px/확대76·하단 안전영역·입력 접근·375/390px 첫 화면 추가정보 노출을 측정했다. 재페인트 후 저장 글자의 흰 픽셀 존재도 확인했다. 최종 코드10개 정적 분석 진단0건·포맷·diff 검사 통과.
  - 검증 보완: 캡처 라벨 확인 중 render 파일의 debug-live 중단점이 연결되지 않아 세션/중단점을 정리하고 렌더러 재페인트·직접 픽셀 검사를 추가했다. 최신 PNG를 별도 임시 경로에서도 시각 확인했다. 두 테스트/렌더 lint는 블록 문법으로 수정했다. SDK 쓰기는 승인된 검증 명령으로 실행했다.
  - 결과: [새 구도](../artifacts/personal_event_layout_2026-11-11/normal.png), [나만 보기](../artifacts/personal_event_layout_2026-11-11/private.png), [375px](../artifacts/personal_event_layout_2026-11-11/phone375.png). ADR-0046과 신규 렌더 역할/의존성/재현·서버 요청서 후속 완료 상태·API 가이드를 갱신했다. 별도 담당자 메시지 없이 문서만 제공한다는 사용자 지시를 유지한다.
  - 검증 한계: 모의 위젯/키보드inset·Dio/repository 응답 검증으로 실제 OS/VoiceOver·원격 인증 사용자별 생성/친구·그룹 실응답 인수를 대체하지 않는다. private 응답 확인은 생성 후 계약 확인이며 서버 필터를 대체하거나 저장을 취소하지 않는다. 실서버 배포/DB migration 재실행·커밋/푸시는 하지 않았다.
  - 롤백: 이번 구도/연동·검증·문서 변경만 되돌린다. 서버 private 필터/컬럼은 유지한다.

- [DONE] (FE/UI/API) 개인 일정 추가 재설계 적용과 나만 보기 서버 요청서
  - 목적: 승인된 제목·일시·공개 범위·선택 정보·하단 저장 배치와 입력 보호/오류 UX를 실제 Flutter에 적용한다.
  - 범위: 개인 일정 폼·기존 DTO 확인·회귀/렌더·문서. 서버 코드를 직접 확인해 나만 보기의 DB/API/친구·그룹 필터/호환성/인수 가이드를 작성했다.
  - 변경: 제목22 → 날짜/시간/종일/기간 → 설명형 공개 범위 → 접는 장소/메모 → 하단 단일 저장을 적용했다. 날짜/시간 공용 시트·선택일09~10시·레벨0·생성 DTO를 유지한다. 입력/시간 인접 오류·첫 오류 포커스/스크롤·이탈 확인·저장 중 차단·실패 보존/다시 저장을 추가하고 반복 미지원 행·장소 팝업·숫자 트랙·전체 본문 아래로 끌어 닫기를 제거했다.
  - 영향범위: 폼·새 폼 회귀·기존 저장 회귀·전용 렌더·PROJECT_CONTEXT/DECISIONS/EVENT_API_GUIDE/서버 요청서. AppTheme/CalendarPage/서버·API·DB·provider 수명/analytics는 변경하지 않았다.
  - 테스트: 전체 `flutter test --no-pub --reporter expanded --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` 268 pass·기존 skip 1. 폼/저장 회귀 14개가 기본 DTO/trim·선택정보 접힘 보존·레벨0~5/나만보기 선택차단·제목/동일·역전시간 검증·종일1/3일·다음날9시간·시간복원·날짜보정·이탈/성공/미변경·저장 예외/재시도/중복 차단을 확인했다. 렌더 별도 1 test·16개 PNG/measurements.json 통과: 320/375/390px·큰글자2배·모의 키보드inset·가로·태블릿·공개시트에서 예외0건, 저장 최소높이52/확대76·안전영역/키보드 위 위치·스크롤 전후 고정·입력 접근을 측정했다. 주요 기본/선택/큰글자/키보드/저장오류/공개시트 PNG를 시각 확인했다. 변경/신규 Dart 4개 정적 분석 진단0건, 포맷 변경0건·diff 검사 통과.
  - 검증 과정: 최초 컴파일의 non-const Semantics에 붙인 const를 바로 수정했다. 선택정보 테스트의 입력 직후 커서 reveal 예약 프레임이 ensureVisible을 되돌리는 문제는 debug-live로 제목 포커스true·scroll offset41·선택버튼 y780~828/본문 y44~764를 확인했고, 테스트가 입력 프레임을 먼저 기다리도록 수정해 해결했다. 중단점/세션을 정리했다. lint9건은 실제 컴파일 규칙/프로젝트 snake_case 관례에 맞춰 해결했다. SDK 캐시 쓰기는 승인된 검증 명령으로 실행했다.
  - 결과: [기본 화면](../artifacts/personal_event_redesign_2026-11-11/normal.png), [선택 정보](../artifacts/personal_event_redesign_2026-11-11/details.png), [저장 오류](../artifacts/personal_event_redesign_2026-11-11/save_error.png). ADR-0045와 파일 역할/의존성/사용·재생성/롤백을 기록했다. [서버 요청서](PERSONAL_EVENT_PRIVACY_SERVER_HANDOFF.md)에 is_private boolean·본인 보존/친구·타인그룹 차단·엄격한 검증·view 컬럼순서 보존 증분 migration·OpenAPI·선배포/인수·private 공개 방지 롤백을 작성했다. 나만 보기는 서버 지원 준비 중 선택불가이며 is_private 요청 필드는 아직 추가하지 않았다.
  - 검증 한계/다음: 앱 기존 라이트 테마·모의 위젯/키보드inset 기준이며 실제 OS/VoiceOver·Stage/운영 저장·서버 migration은 미인수다. 서버 담당자 구현/배포/권한별 실응답 인수 후 별도 Flutter DTO/나만보기 활성화가 필요하다. 외부 담당자 메시지/이슈 등록·커밋/푸시·배포는 수행하지 않았다.
  - 롤백: 이번 화면·관련 계약 준비/테스트·문서 변경만 되돌린다. 기존 미커밋 작업은 보존한다.

- [DONE] (UI/PLAN) 개인 일정 추가 화면의 입력 데이터와 재설계안
  - 목적: 일반 캘린더의 일정 입력 항목을 검토하고 ShiftMate의 실제 데이터 계약에 맞는 요소·배치·크기·색상을 제안한다.
  - 범위: 기존 폼/테마/스키마/공개 흐름·공식 캘린더 문서 확인, 대화용 시안 및 문서. Flutter 앱·API·DB 구현은 변경하지 않는다.
  - 변경: 제목 → 날짜/시간 → 설명형 공개 범위 → 선택 장소/메모 → 하단 단일 저장의 대화용 시안과 크기/색상 규격을 제안했다. 기존 레벨0/09~10시 기본값과 종일 배타적 종료를 보존한다. 현재 미지원 반복·알림·색상·참석자 및 나만 보기의 별도 정책 필요성을 구분했다. 파일 역할·의존성·사용 예·Behavior change 제안·drawio 구형 구조 확인은 PROJECT_CONTEXT에 기록했다.
  - 영향범위: 대화용 HTML 시안과 이 작업의 컨텍스트/로그만 변경. 기존 미커밋 작업과 Flutter·API·DB·ADR은 보존한다.
  - 테스트: Node VM으로 조각/ID 유일성/리터럴 마크업·JS 문법·제목/공백 검증과 첫 포커스·모의 저장·역전/같은 시간·종일1/3일·다음날9시간·시간 복원·레벨0~5 설명·이탈 확인/계속작성/초기화 통과. preview wrapper 생성 통과 및 diff 검사 확인. headless Chrome 실행은 환경상 종료134로 실패했으며 실제 브라우저·Flutter·실기기·큰글자·키보드·VoiceOver 시각 검증은 미수행이다.
  - 결과: `artifacts/personal_event_proposal_2026-11-11/personal-event-editor.html`을 대화에 제시한다. Google 공식 일정 생성/Events API 문서로 일반 필드를 확인했다. 시안 저장은 로컬 검증만 하며 서버에 전송하지 않는다. 앱 적용·정책 채택·커밋/푸시는 하지 않았다.
  - 롤백: 이번 시안과 문서 항목만 제거한다.

- [DONE] (FE/UI) 글라스 하단 내비게이션과 상단 바 재질 통일
  - 목적: 사용자가 요청한 은은한 글라스 내비게이션을 적용하고 화면 제목/뒤로가기와 시각적 일관성을 맞춘다.
  - 변경: 좌우 16/최대 너비 480/반경 28/일반 높이 64의 둥근 플로팅 하단 바·선택 배경·18px 제한 블러, 공통 테마의 반투명 상단 바를 적용했다. 설정/근무 패턴의 별도 불투명 헤더 override를 제거했다. 제목과 기존 뒤로가기 동작·일정 카드와 바 사이 16px 간격을 유지한다. 고대비에서는 불투명/블러 끄기, 동작 줄이기에서는 선택 색상 전환을 생략한다.
  - 영향범위: 공통 내비게이션/테마·명시적 배경을 지정한 설정/근무 템플릿 헤더와 관련 검증·문서. API/DB 변경 없음.
  - 테스트: 기존 탭·달력·설정·프로필·근무 템플릿 provider 회귀 50개 통과. 실제 위젯 렌더 1 test/12개 PNG(세 탭·375/320px·큰 글자 2배·가로·고대비·동작 줄이기·하단 다크 재질·설정/프로필 헤더) 예외 0건. 카드 간격 모두 16px·최소 터치 44px·바 최대 너비 480px·안전영역 34+8px·99+ 배지 경계 안 좌표를 확인했다. 배지 보정 후 탭 회귀와 렌더를 재확인했다. 변경/신규 Dart 5개 정적 분석 진단 0건·포맷 변경 0건·diff 검사 통과.
  - 결과: [하단 바](../artifacts/glass_navigation_2026-11-11/calendar.png), [설정 헤더](../artifacts/glass_navigation_2026-11-11/settings.png), [큰 글자](../artifacts/glass_navigation_2026-11-11/text2.png). 신규 렌더러/PNG/JSON의 역할·의존성·재생성 명령과 롤백을 PROJECT_CONTEXT에 기록하고 ADR-0044를 추가했다. 구현은 Flutter 글라스 스타일이며 시스템 Liquid Glass 광학 효과가 아니다. 초기 명령의 존재하지 않는 테스트 경로와 렌더러 import/테스트 전용 lint를 수정했고, 시각 확인에서 발견한 큰 글자 99+의 둥근 경계 잘림도 슬롯/숫자 확대 제한/위치 검증으로 해결했다.
  - 검증 한계: 앱 기존 라이트 테마·모의 위젯 기준이며 dark_navigation은 하단 재질/전경만 확인한다. 실제 OS/VoiceOver/기기 프레임 성능·OS 투명도 줄이기는 미확인이다. 커밋/푸시·배포는 하지 않았다.
  - 롤백: 이번 글라스 표시·테마/헤더/검증·문서 변경만 되돌린다.

- [DONE] (FE/UI) 메인 캘린더 카드와 하단 탭 사이 여백 보정
  - 목적: 달력 아래 일정 카드가 하단 내비게이션 경계에 붙는 표시를 개선한다.
  - 변경: `calendar_page.dart` 일반 Expanded 배치의 마지막에 `AppTheme.spacing_md` 16px 여백을 추가했다. 기존 작은 화면 스크롤 배치와 간격을 맞추고 근무 설정 모드도 같은 슬롯을 사용한다.
  - 영향범위: 메인 캘린더 표시와 문서. 글라스 내비게이션은 디자인 의견만 제공한다.
  - 테스트: 기존 캘린더/탭 회귀 18개 통과, 변경 Dart 정적 분석 진단 0건·포맷 변경 0건. 기존 렌더러의 임시 사본으로 일반/근무 설정/375px/320px/큰 글자 2배/가로 화면 6개를 확인했고 예외 0건·카드와 탭 간격 모두 16px이었다(스크롤 배치는 목록 끝 기준). 일반/큰 글자 PNG도 시각 확인했다.
  - 결과: PROJECT_CONTEXT의 선택일 카드 배치 설명을 갱신했다. 임시 렌더 소스 `/private/tmp/calendar_spacing_render_test.dart`와 PNG/측정값 `/private/tmp/calendar_spacing_2026-11-11/`는 기존 렌더러의 모의 provider·번들 폰트를 재사용하며 `flutter test --no-pub /private/tmp/calendar_spacing_render_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`로 재확인한다. 실기기 확인은 수행하지 않았다. 단순 간격 보정으로 새 정책 ADR은 추가하지 않았다.
  - 롤백: 이번 하단 간격 한 줄과 해당 문서/산출물 변경만 되돌린다.

- [DONE] (FE/UI) 프로필 정보 위계와 필수 기호 보정
  - 목적: 사용자의 후속 피드백에 따라 데이터의 소속 영역과 제목/라벨/입력값을 한눈에 구분한다.
  - 변경: 기본·근무·계정 정보를 16px 패딩/반경 카드로 묶었다. 20px 제목/영역 아이콘·14px 굵은 라벨·16px 입력값과 계정의 읽기 전용 배경으로 위계를 분리했다. 이름/휴대폰은 빨간 *로 표시하고 접근성 필수 안내를 유지한다.
  - 영향범위: 편집 표시·관련 검증/렌더·문서. 저장·가입·API/DB 동작은 유지한다.
  - 테스트: 프로필/가입·설정·렌더 총 31 tests pass. 기존 위계 검증에 카드별 필드 소속과 `이름 *`/`휴대폰 번호 *` 표기를 반영했다. 기존 14개 렌더를 재생성해 320/375/390px·큰 글자2배·키보드·가로/태블릿의 예외 0건·고정 저장/입력/이메일 접근을 확인했다. 변경/관련 Dart 3개 정적 분석 진단 0건·포맷 및 diff 검사 통과.
  - 결과: [수정 화면](../artifacts/profile_edit_redesign_2026-11-11/normal.png), [근무·계정 카드](../artifacts/profile_edit_redesign_2026-11-11/normal_bottom.png). PROJECT_CONTEXT와 ADR-0043 후속 설명을 갱신했다. 실제 OS/VoiceOver/서버 인수는 기존 미확인 범위이며 배포·커밋/푸시는 하지 않았다.
  - 롤백: 이번 카드/타이포/기호와 검증·문서 보정만 되돌린다.

- [DONE] (FE/UI) 승인된 프로필 수정 재설계 적용
  - 목적: 사용자가 승인한 사진/이름 요약·편집 정보 중심 디자인을 실제 Flutter 화면에 반영한다.
  - 변경: 편집 전용 사진/이름 요약·기본/선택 근무/읽기 전용 계정 정보 배치, 52px 입력/저장·72px 사진·16/14 타이포·480 최대 너비, 변경 감지·포커스 이탈 검증/첫 오류 이동·이탈 확인·하단 서버 오류/재시도. 기존 가입 표시·저장 흐름은 유지했다. AppTheme에 새 편집 오류 문구용 대비 6.20:1 색상 토큰을 추가했다.
  - 영향범위: 프로필 화면·관련 회귀/렌더·문서. 가입 동작과 부분 수정/사진/API/DB 계약을 보존한다.
  - 테스트: `flutter test --no-pub --reporter expanded --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` 전체 256 pass·기존 skip 1. 프로필/가입 23개와 설정 복귀·선택값 삭제·미변경 전화 예외·이미지 첨부·실패 후 사진/입력 보존·재시도·사진 선택/저장 중 이탈/중복 차단을 확인했다. 렌더러 별도 1 test 통과·14개 PNG 예외 0건(320/375/390px·큰 글자2배·이름/소속 키보드 inset·가로·태블릿·저장 오류). 하단 버튼 위치 고정·52px/큰 글자76px·계정/입력 접근을 측정했다. 변경 Dart 5개 정적 분석 진단 0건·포맷 변경 0건 및 diff 검사 통과.
  - 결과: [기본 화면](../artifacts/profile_edit_redesign_2026-11-11/normal.png), [변경 후 저장](../artifacts/profile_edit_redesign_2026-11-11/edited.png), [계정 정보](../artifacts/profile_edit_redesign_2026-11-11/normal_bottom.png). PROJECT_CONTEXT의 파일 역할/의존성/재생성/롤백과 ADR-0043을 기록했다.
  - 검증 과정: 최초 테스트는 변경 후 새 버튼 활성화 프레임을 기다리지 않아 실패했다. debug-live로 입력값 반영·버튼 콜백 null·예약된 프레임을 직접 확인하고 프로필/설정 테스트에 pump를 추가했다. 설정 취소 테스트는 새 뒤로가기/폐기 확인에 맞춰 변경했다. 전체 검증의 최초 누락 Stage define은 기존 문서의 테스트 sentinel로 재실행했다. 임시 중단점과 디버그 세션은 정리했다.
  - 검증 한계: 실제 OS 키보드·갤러리/S3·실서버·VoiceOver는 미확인이고 앱 기존 라이트 테마 범위다. 서버 인수 선행 조건은 기존과 동일하다. 배포·커밋/푸시는 하지 않았다.
  - 롤백: 이번 편집 UI·검증·문서 변경만 되돌린다.

- [DONE] (UI/PLAN) 프로필 수정 화면 재설계 제안
  - 목적: 가입 공용 폼을 확인하고 편집 목적에 맞는 요소·배치·크기·색상을 구체화한다.
  - 범위: 기존 화면/테마/ADR-0037·0038 검토와 대화용 시안. 앱 구현과 API/DB 변경은 포함하지 않는다.
  - 변경: 사진/이름 요약·기본/선택 근무 정보·계정 정보 순으로 재배치한 대화용 시안과 논리 픽셀/기존 AppTheme 색상 규격을 제안했다. 신규 파일 역할·의존성·사용 예·Behavior change 제안은 PROJECT_CONTEXT에 기록했다.
  - 테스트: Node VM의 ID 유일성·리터럴 조각·JS 문법·미변경 비활성·이름 미리보기·모의 저장·필수 오류/첫 오류 포커스·취소 복원·선택 정보 비우기 확인 및 diff 검사 통과. 실제 브라우저/사진 선택·Flutter·실기기·접근성 검증은 미수행이다.
  - 결과: `artifacts/profile_edit_proposal_2026-11-11/profile-editor.html`을 대화에 제시한다. 예시 데이터와 시스템 폰트/라이트 테마를 사용한다. 앱 적용·정책 채택·ADR 추가·커밋/푸시는 하지 않았다.
  - 롤백: 이번 시안과 문서 항목만 제거한다.

- [DONE] (FE/UI) 근무 타입 시간 지정 기본값과 뒤로가기 표현 보정
  - 목적: 사용자 요청대로 신규 타입은 시간 지정 상태로 시작하고 다른 화면과 같은 뒤로가기 디자인을 사용한다.
  - 변경: 신규 폼의 시간 지정 기본값을 켜고 상단 취소를 26px 뒤로가기 화살표와 접근성 라벨로 바꾼다. 기존 무시간 타입의 편집 상태는 유지한다.
  - 영향범위: 근무 타입 폼·관련 회귀/렌더·문서. API/DB/시간 선택 시트는 변경하지 않는다.
  - 테스트: 폼/저장 회귀와 전용 렌더러 총 24 tests pass. 신규 기본 켬·기존 무시간 편집 해제·뒤로가기 폐기·한쪽 시간 저장 차단·저장 중 뒤로가기 비활성/실패 입력 보존을 확인했다. 12개 PNG 재생성·수집 예외 0건, 신규 추가 화면 시각 확인, 변경 Dart 4개 정적 분석 진단 0건·포맷 및 diff 검사 통과.
  - 결과: [신규 기본 상태](../artifacts/shift_type_redesign_2026-11-11/create.png). PROJECT_CONTEXT와 ADR-0042에 기본값/뒤로가기 후속 정책을 반영했다. 실제 OS 키보드·VoiceOver·실서버 확인은 기존과 같이 미수행이다.
  - 롤백: 이번 초기값/뒤로가기/검증·문서 보정만 되돌린다.

- [DONE] (FE/UI) 승인된 근무 타입 편집 재설계 적용
  - 목적: 근무 타입의 표시 결과와 편집 순서를 연결하고 시간 없는 타입을 명시적으로 설정한다.
  - 변경: 작은 요약 미리보기·이름/표시 코드/색상 순서·시간 지정 스위치·다음 날/총 시간·하단 저장·필드 인접 오류를 적용한다.
  - 영향범위: 공용 근무 타입 추가/편집 폼·관련 회귀/렌더 검증·프로젝트 문서. 기존 API/색상 계약을 유지한다.
  - 테스트: `flutter test --no-pub --reporter expanded --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` 전체 249 pass·기존 skip 1. 시간 해제 null 요청/꺼짐→켜짐 후 기존 시간 저장·필수 입력 인접 오류/포커스·한 시간만 선택 후 저장 차단·다음 날/분 단위/동일 시간 0시간·키보드 입력 연결·색상 농도·저장 중 취소/뒤로가기 차단과 실패 후 입력 보존을 검증했다. 변경 Dart 4개 분석 진단 0건, 포맷 및 diff 검사 통과.
  - 결과: [편집 화면](../artifacts/shift_type_redesign_2026-11-11/normal.png), [시간 요약](../artifacts/shift_type_redesign_2026-11-11/normal_bottom.png), [오프](../artifacts/shift_type_redesign_2026-11-11/no_time.png). 전용 렌더러 1 test 통과·12개 PNG 프레임워크 예외 0건. 320×568/390×844·글자 2배·모의 키보드·가로·태블릿에서 저장 최소 높이 52/안전영역·스크롤 전후 고정 위치·입력 접근을 측정하고 주요 PNG를 시각 확인했다. PROJECT_CONTEXT의 기존 폼 설명과 ADR-0041/과거 방향서 후속 상태를 갱신했다.
  - 검증 보완: 최초 전체 명령은 필수 Stage 키 옵션 누락으로 상수 테스트 1건이 실패했으며 문서에 기록된 테스트 키로 재실행해 전체 통과했다. 렌더러의 작은 화면에서 지연 생성된 필드 탐색 실패를 확인해 유한한 폼을 SingleChildScrollView로 유지했고, 작은 화면의 오류 포커스와 렌더를 함께 검증했다. API/DB·서버 코드는 변경하지 않았다.
  - 검증 한계: 키보드는 MediaQuery inset 주입이며 실기기·VoiceOver·실서버 저장/재진입은 미확인이다. 기존 앱 라이트 테마 범위를 유지했으며 배포/커밋/푸시는 하지 않았다.
  - 롤백: 이번 폼/검증/문서 변경만 되돌리고 기존 미커밋 작업을 보존한다.

- [DONE] (UI/PROPOSAL) 근무 타입 편집 화면 재설계 제안
  - 목적: 현재 편집 화면의 정보 위계와 시간 없는 타입 설정 방식을 검토한다.
  - 변경: 실제 폼·공용 테마·관련 ADR에 근거한 대화용 시안을 작성한다.
  - 영향범위: 제안 시안과 문서이며 앱 구현·채택된 정책은 변경하지 않는다.
  - 테스트: HTML ID 중복·리터럴 마크업·JS 구문 검사 통과. Node VM에서 다음 날 9시간 계산·시간 지정 해제·코드 미리보기·필수 이름·예시 복원 동작을 확인했다. 실제 브라우저/Flutter 렌더는 미실행이다.
  - 결과: `artifacts/shift_type_proposal_2026-11-11/shift-type-editor.html`에 편집 가능한 제안 시안을 작성하고 PROJECT_CONTEXT에 역할/의존성/사용 예와 ADR-0009 변경 가능성을 기록했다. 채택 전 제안이므로 새 ADR은 추가하지 않았다.
  - 롤백: 이번 제안 산출물과 문서 항목만 제거한다.

- [DONE] (FE/UI) 프리셋 색상 카드 위아래 여백 정렬
  - 목적: 12개 프리셋 카드의 아래쪽 여백만 넓게 표시되는 문제를 수정한다.
  - 변경: 중첩 GridView에 `padding: EdgeInsets.zero`를 명시해 카드 자체 16px 패딩만 사용하도록 수정했다. 아래 safe-area 34px이 중복 적용되던 원인을 제거했다.
  - 영향범위: 프리셋 카드 레이아웃·렌더 검증·문서.
  - 테스트: 수정 전 렌더 측정 위 17/아래 51로 실패를 재현했다. 수정 후 테두리 포함 위/아래 모두 17px이다. 색상 선택 회귀+렌더러 총 10 tests pass, 화면 10종 예외 0건, 변경 Dart 2개 분석 진단 0건·최종 포맷 변경 0건·diff 검사 통과. 재생성한 프리셋 PNG를 시각 확인했다.
  - 결과: [프리셋 화면](../artifacts/custom_color_intensity_2026-11-11/preset.png)의 위아래 내부 여백을 정렬했다. measurements.json의 preset.card_spacing과 렌더러에 대칭 검증을 추가했다. 기능/저장/설계 정책 변경이 없는 레이아웃 결함 수정으로 새 ADR은 추가하지 않았다.
  - 롤백: GridView 패딩 명시와 이번 검증·문서 항목만 되돌린다.

- [DONE] (FE/UI) 농도 조절을 커스텀 색상으로 통합
  - 목적: 승인된 분석에 따라 프리셋 빠른 선택과 커스텀 세부 조정의 역할을 분리한다.
  - 변경: 농도 UI 이동, 기준색/적용색 표시 구분, 커스텀 왕복·최근 색상의 기준 색상/농도 보존.
  - 영향범위: 색상 선택 UI·공용 선택 값/계산·테스트·렌더·문서. 기존 API의 불투명 혼합/저장 형식을 유지한다.
  - 테스트: 전체 Flutter 244 pass·기존 skip 1. 커스텀 왕복/취소/프리셋 재선택, 기준 HEX/RGB와 최종색 분리·0/50/100%, 근무 타입 수정 요청의 농도 25%, 최근 v2 저장/재복원·잘못된 기록의 v1 fallback, 휠/농도 트랙 실제 포인터 회귀 통과. 별도 렌더러 1 test 통과·10개 PNG 예외 0건(320×568/390×844/글자 2배/모의 키보드/가로/태블릿·프리셋·농도 영역). 변경 Dart 7개 분석 진단 0건·최종 포맷 변경 0건 및 diff/산출물 검사 통과.
  - 결과: 프리셋 농도 슬라이더 제거 및 `선택한 색상 조절` 진입, 기준색 편집/최종색 고정 미리보기, 커스텀 RGB 아래 농도 통합 완료. SharedPreferences v2로 기준색/농도를 보존하고 v1 최종 RGB도 유지한다. 농도 트랙 탭 동작은 기존 사용자 경험을 유지했으며, 폼 통합 테스트에는 새 로컬 저장 경로의 모의 저장소를 추가했다. ADR-0040·컨텍스트·메타데이터 안내·수정 방향을 최신화했다. [프리셋](../artifacts/custom_color_intensity_2026-11-11/preset.png), [농도 조절](../artifacts/custom_color_intensity_2026-11-11/intensity_bottom.png).
  - 검증 한계: 키보드는 MediaQuery inset 주입이며 실기기 입력/VoiceOver/실서버 저장 인수는 미확인이다. 서버/DB·배포·커밋/푸시는 변경하지 않았다.
  - 롤백: 이번 UI/선택 값 전달 변경만 되돌리고 직전 디자인/제스처 수정은 보존한다. 기존 최근 색상 저장 키는 삭제하지 않는다.

- [DONE] (UI/REVIEW) 프리셋·커스텀 색상 농도 역할 검토
  - 목적: 사용자 제안의 6자리 HEX/불투명도 전제를 확인하고 농도 조절 위치 변경 여부를 판단한다.
  - 범위: 실제 색상 계산·프리셋·커스텀 왕복·저장 값과 UI/UX 대안 분석. 이번 검토에서 앱 구현은 변경하지 않는다.
  - 검증: 실제 calculateShiftColor·프리셋 12개·커스텀 왕복·DTO 직렬화와 ADR-0010/0011을 대조했다. 6자리 HEX는 RGB이고 Flutter ARGB의 alpha는 별도임을 공식 문서로 확인했다. 앱 프리셋 alpha는 전부 FF, 선택 시 농도 100이다. 현재 농도는 흰색과의 불투명 혼합이며 RGB만으로 원래 기준색/농도를 유일하게 복원할 수 없다. 기존 계산 회귀에는 #4355B8/50% → #A1AADC가 명시돼 있다. 앱 변경이 없어 테스트를 반복 실행하지 않았다.
  - 판단/제안: 실제 투명도 도입이나 프리셋 alpha 역산은 권장하지 않는다. 프리셋은 빠른 선택, 커스텀은 휠/RGB/HEX/농도 세부 조정으로 역할을 분리하는 변경을 권장한다. 농도만 바꾸려 해도 한 단계 더 진입하는 비용이 있다. 프리셋에서 현재 색상 편집 진입을 명확히 하고, 커스텀 왕복의 base_color/color_intensity 보존 및 입력 기준색/최종 적용색 구분을 함께 설계해야 한다. 현재 왕복은 최종 RGB만 전달하고 완료 시 농도를 100으로 바꾸므로 슬라이더만 옮겨서는 부족하다.
  - 근거/상태: UI 배치 권고는 이 앱의 선택/편집 흐름을 기준으로 한 판단이다. UI UX Pro Max 검색은 재검색 후에도 역할 분리에 직접 맞는 결과가 없어 검색 결과를 근거로 채택하지 않고 공통 일관성/라벨 원칙을 참고했다. [Flutter Color](https://api.flutter.dev/flutter/dart-ui/Color-class.html), [HEX 형식](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Values/hex-color). 이번에는 분석만 완료했으며 UI/저장 정책 채택·앱 구현·새 ADR 추가는 하지 않았다.
  - 롤백: 이번 검토 기록만 제거한다.

- [DONE] (FE/FIX) 색상 휠 드래그와 세로 스크롤 충돌 해결
  - 목적: 휠에서 시작한 드래그가 화면 스크롤로 넘어가는 사용자 보고를 재현하고 수정한다.
  - 변경: 원 내부에서 누르는 즉시 전용 PanGestureRecognizer가 제스처를 수락한다. 원 밖 모서리/여백은 부모 스크롤에 남긴다. 첫 손가락만 색상을 조절하고 종료/취소 추적 정리는 Flutter recognizer에 맡긴다. 렌더러의 스크롤 시작점도 휠 중앙에서 바깥 여백으로 수정했다.
  - 영향범위: 커스텀 색상 위젯·회귀 테스트·관련 문서. 디자인/색상 계산/저장 계약은 유지한다.
  - 테스트: 수정 전 실제 포인터 이벤트 테스트에서 예상 scroll 0 대비 실제 45로 실패를 재현했고, debug-live로 해당 테스트 중단점 진입을 확인한 뒤 추가 중단점/세션을 정리했다. 로컬 Flutter SDK에서 VerticalDrag의 hit slop과 Pan의 더 큰 pan slop 임계값 경쟁을 확인했다. 수정 후 휠 연속 세로/대각선 이동·바깥 모서리 시작·원 밖 이동 후 취소/재조작·두 번째 손가락의 색상 가로채기 방지 등 추가 4개와 관련 회귀/렌더러 총 37 tests pass. 캡처 8개 예외 0건, 변경 Dart 3개 분석 진단 0건·포맷 변경 0건·diff 검사 통과.
  - 결과: 휠 드래그 중 scroll 0 유지·연속 색상 변경, 휠 밖 드래그의 스크롤과 취소 후 재사용을 확인했다. ADR-0039와 PROJECT_CONTEXT에 동작을 기록했다. 실기기 손가락 인수는 미수행이며 배포/커밋/푸시는 하지 않았다.
  - 롤백: 이번 제스처 처리와 추가 테스트만 되돌려 직전 디자인을 유지한다.

- [DONE] (FE/UI) 커스텀 색상 선택 화면 재디자인
  - 목적: 사용자 요청에 따라 색상 미리보기·직접 입력·RGB 조절의 배치와 밀도를 다시 정리한다.
  - 변경: 미리보기와 HEX 입력을 한 카드로 묶고 색상 휠·RGB·최근 색상의 위계를 개선한다.
  - 영향범위: 커스텀 색상 화면과 관련 테스트·검증 이미지·문서. 색상 계산/반환 및 로컬 최근 색상 저장 계약은 유지한다.
  - 테스트: 커스텀/프리셋 색상·근무 타입 폼 회귀 및 렌더러 총 33 tests pass. 320×568/390×844/가로/태블릿·글자 2배·모의 키보드 inset·동작 줄이기의 8개 캡처 예외 0건. 최근 색상 마지막 버튼/키보드 중 HEX 접근을 검증했다. 변경 Dart 3개 분석 진단 0건·포맷 변경 0건 및 diff 검사 통과.
  - 결과: HEX 입력 상단 통합, 넓어진 RGB 슬라이더, 최근 색상 선택 체크/줄바꿈/눌림 반응 적용. 렌더 확인 중 큰 글자의 HEX 잘림을 발견해 세로 배치로 해결했다. [최신 화면](../artifacts/custom_color_redesign_2026-11-11/normal.png). 기존 전체 비교 이미지는 이전 상태로 보존한다. PROJECT_CONTEXT 파일 역할/재생성/롤백 및 ADR-0038 후속 설명을 최신화했다.
  - 검증 한계: OS 키보드 대신 inset 주입 검증이다. 실기기·VoiceOver·다크 테마는 미확인이며 배포/커밋/푸시는 하지 않았다.
  - 롤백: 이번 화면 재배치와 관련 테스트/문서만 되돌려 직전 공통 UI 상태로 복구한다.

## 2026-11-10

- [DONE] (FE/UI/QA) 공통 폼 디자인 및 고정 하단 탭 적용 (11월 11일 완료)
  - 목적: 사용자가 승인한 디자인 수정 방향을 실제 앱에 반영한다.
  - 변경: 설정·근무/개인 일정·색상·그룹 수정·알림 UI와 캘린더/친구/알림 탭, 인증/푸시 진입을 정리한다.
  - 영향범위: Flutter UI·내비게이션·관련 테스트·문서. 서버 API/DB/권한 정책은 유지한다.
  - 테스트: 전체 Flutter 테스트 236 pass·기존 skip 1. GROUP_API_ENABLED/GROUP_P1_ENABLED=true의 그룹 관리 테스트 별도 2 pass. 변경 Dart 31개 분석 진단 0건·최종 포맷 변경 0건. 실제 위젯 렌더러 1 test 통과, 28개 캡처에서 수집된 Flutter 예외 0건. 320×568/390×844·글자 2배·HEX/메모 키보드 inset·최근 색상 스크롤을 검증했다. PNG·문서 링크·diff 검사 통과.
  - 결과: 캘린더/친구/알림 고정 탭, 오늘 헤더, 친구/그룹 상단 전환, 공통 폼 크기·준비 중 설정·색상 스크롤/한글화·그룹 시간대 선택을 적용했다. 탭 날짜/상세 이력 보존, 로그인/가입/로그아웃, 폼 중 푸시 보류, 저장 중복 방지 및 실패 후 입력 보존을 모의 테스트했다. ADR-0038 및 관련 컨텍스트/푸시 안내를 최신화했다. [수정 화면 비교](../artifacts/design_update_2026-11-10/comparison.png), [수정 방향 및 구현 결과](UI_DESIGN_DIRECTION_2026-11-10.md).
  - 검증 한계: 키보드는 실제 OS 촬영이 아닌 MediaQuery inset 주입이다. 실기기 입력·VoiceOver·실제 푸시·실서버 시간대 저장은 미확인이다. 서버/DB·빌드 번호·배포·커밋/푸시는 변경하지 않았다.
  - 롤백: 이번 UI/내비게이션 변경과 관련 테스트·문서만 되돌린다. 이전 검토 산출물은 보존한다.

- [DONE] (UI/PLAN/DOCS) 디자인 불일치 화면 및 하단 내비게이션 수정 방향 수립
  - 목적: 사용자에게 확인받은 디자인 검토 결과를 화면별 개선안과 공통 기준으로 구체화한다.
  - 변경: 기존 검토와 현재 하단 바·화면 진입 코드를 대조해 내비게이션 구조, 폼/타이포 기준, 적용 순서와 완료 조건을 작성한다.
  - 영향범위: 수정 방향 문서와 PROJECT_CONTEXT/WORKLOG. 구현 전 제안이며 앱 코드·API·DB 변경 없음.
  - 테스트: 기존 검토와 하단 바·메인/친구·인증/푸시 진입점을 대조했다. 방향서 로컬 링크 및 diff 검사 통과. 문서 변경만 있어 앱 테스트·렌더링은 반복하지 않았다.
  - 결과: [수정 방향서](UI_DESIGN_DIRECTION_2026-11-10.md)에 세 탭 구조·친구/그룹 세그먼트·역할별 크기·화면별 변경·적용 순서·회귀 조건을 작성했다. 현재 구현과 권장안을 구분했으며 채택/구현 전이므로 ADR은 추가하지 않았다.
  - 롤백: 이번 수정 방향 문서와 해당 컨텍스트/로그 항목만 제거한다.

- [DONE] (UI/REVIEW/DOCS) 앱 전체 화면 디자인 일관성 및 모바일 UI 관례 점검
  - 목적: 사용자 요청에 따라 전체 화면에서 공용 디자인과 다르거나 일반적인 모바일 UI 관례에서 벗어난 화면을 찾는다.
  - 변경: 사용자가 두 기준의 동일 비중을 선택했다. 공용 토큰·19개 페이지 정의·관련 폼/위젯·진입점·기존 ADR을 직접 읽고 ui-ux-pro-max 및 Apple HIG와 대조했다. Flutter 실제 위젯 15개 사례를 모의 데이터로 렌더링하고 8개 발견을 파일/이미지/측정 근거와 함께 보고서로 정리했다.
  - 영향범위/파일: `_docs/{UI_DESIGN_AUDIT_2026-11-10,PROJECT_CONTEXT,WORKLOG}.md`, `artifacts/design_audit_2026-11-10/`의 검토 전용 렌더러·측정 JSON·화면 PNG 15개·비교 PNG. 앱 lib/·서버·DB·기존 디자인 정책 변경 없음.
  - 테스트: 최종 검토용 렌더러 1 test 완료, 15개 사례의 수집 Flutter 예외 0. Dart 분석 진단 0건. PNG 실제 폰트/아이콘/자산 로드·시각 확인. 320×568의 커스텀 색상 콘텐츠 초과 147.4·드래그 전후 scroll 0, 알림 버튼 57.8×34·하단 친구/알림 88.8×36·색상 변경 101.9×28.8을 측정했다. 390×844 글자 2배의 커스텀 색상은 현재 내용이 들어가므로 실패로 분류하지 않았다. 최종 포맷·diff·문서 링크 검사 통과.
  - 결과: 작은 화면 색상 하단 접근 불가와 활성처럼 보이는 미구현 설정을 우선 후보로 정리했다. 별도 0.8 배율, 하단 메뉴 구성, 그룹 수정 폼, 대비/언어 차이도 검토했다. 기존 의도·플래그 조건·참조 없는 ShiftAddPage를 구분했다. 코드 변경·설계 채택이 없어 새 ADR은 없다. 검토용 생성 코드의 인자/비동기/자산 캡처 문제는 최종 재생성 전 수정했으며 실기기·키보드·전체 상태 검증은 미수행이다.
  - 롤백: 이번 검토 보고서·산출물 폴더 및 컨텍스트/로그 항목만 제거한다. 앞선 스킬 설치 기록은 보존한다.

- [DONE] (DEV/DOCS) UI UX Pro Max 외부 스킬 설치 및 사용법 확인
  - 목적: 사용자 지정 GitHub 스킬을 Codex에서 사용할 수 있게 설치하고 Flutter 프로젝트용 호출 예시를 제공한다.
  - 변경: 원본 README·manifest·Codex 플랫폼 설정과 검색 진입점/의존성·데이터 경로를 확인했다. 공식 `skill-installer` 도우미로 원본 커밋 `6ae86f61f520d6ca229d2f40e070410638c908c5`의 `.claude/skills/ui-ux-pro-max`를 `/Users/parkhyunseo/.agents/skills/ui-ux-pro-max`에 설치했다. manifest의 Claude 전용 실행 경로 11곳을 실제 경로와 `python3`로 맞췄다.
  - 영향범위: 사용자 공용 Codex 스킬 및 `_docs/{PROJECT_CONTEXT,WORKLOG}.md`. 앱 코드·UI·서버·DB·패키지 의존성 변경은 없다.
  - 테스트: Python 3.13.0 및 manifest/reference/Flutter CSV 존재 확인. `search.py "safe area accessibility" --stack flutter -n 2` 접근성 결과 2건, `search.py "calendar scheduling productivity" --design-system -p ShiftMate --json`의 Calendar & Scheduling App 분류·JSON 생성 및 persistence=null 확인. 명령 모두 종료 코드 0. 설치 75개 파일은 manifest 실행 예시 외 원본 SHA-256 일치, `git diff --check` 통과. 앱 변경이 없어 Flutter 테스트는 반복하지 않았다.
  - 결과: 설치·검색 실행 완료. PROJECT_CONTEXT에 파일 역할/의존성/호출 예/롤백을 기록했다. 생성 결과의 웹 패턴 및 Flutter 3.44.x 대상 안내를 실제 프로젝트 규칙·버전에 대조해 사용하는 기준도 기록했다. `--persist`·앱 UI 수정·커밋·푸시는 수행하지 않았다. 설계·정책 변경이 없어 기존 ADR 유지.
  - 롤백: 이번에 추가한 스킬 디렉터리와 문서 항목만 제거한다.

- [DONE] (GIT/QA/DOCS) 현재 변경사항 검토·정리 및 커밋·푸시
  - 목적: 사용자 요청에 따라 기존 작업물을 검토·검증하고 원격 저장소에 보존한다.
  - 변경: 프로필 편집·사진 변경과 서버 요청서의 기존 변경 16개 파일을 검토한다. 별도 기기 진단 TODO는 미완료 상태로 보존한다.
  - 영향범위: 현재 Flutter 저장소 변경과 검증 문서. 서버 구현·배포·스토어 작업은 포함하지 않는다.
  - 테스트: `flutter test --no-pub --reporter expanded --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` 전체 227 pass·기존 skip 1. 변경 Dart 12개 `dart analyze` 진단 0건, `dart format --output=none --set-exit-if-changed` 변경 0건. staged/unstaged diff 검사 통과. Flutter SDK 캐시 쓰기 제한 후 검증 명령을 권한을 받아 재실행해 정상 종료했다.
  - 결과: 기존 구현·관련 테스트·문서를 직접 검토했으며 추가 앱 코드 수정은 없다. 16개 파일을 `44595b6` (`feat: 설정 프로필 편집 및 사진 변경 추가`)으로 커밋하고, 이전 로컬 커밋 `9516c5a`와 함께 origin/main에 일반 push했다. push 성공 및 로컬 HEAD=origin/main=`44595b6e1540bd1d5cb499909b0ed830fb90805e`를 확인했다. 이번 완료 기록은 후속 문서 커밋으로 보존한다. 새 설계·정책 변경이 없어 기존 ADR-0037을 유지한다.
  - 다음: 서버 배포·실기기 사진 교체는 기존 후속 인수 항목으로 유지하며 별도 iPhone 진단 TODO도 미완료 상태로 보존한다.
  - 롤백: 정리 커밋을 일반 git revert로 되돌린다.

- [TODO] (DEV/QA) VS Code의 지정 iPhone 미표시 원인 확인
  - 목적: Flutter CLI에 표시된 `00008030-0015756A266B802E`가 VS Code 기기 선택에 없는 원인을 확인한다.
  - 변경: 우선 Xcode/Flutter 기기 탐색과 VS Code SDK·daemon 로그를 읽어 비교한다. 기존 staged 프로필 수정 작업은 유지한다.
  - 영향범위: 로컬 개발 도구 진단 및 필요한 복구. 앱/서버 동작은 변경하지 않는다.
  - 테스트: 동일 UDID의 Xcode·Flutter·VS Code 탐색 결과 비교 예정.
  - 롤백: 진단만 수행한 경우 불필요하며 도구 설정 변경이 필요하면 변경·복구 방법을 기록한다.

- [DONE] (FE/DOCS) 설정 프로필 수정·사진 변경 클라이언트 및 서버 요청서 준비
  - 목적: 설정의 프로필 편집 진입점을 실제 저장 기능으로 연결한다. 다른 미구현 설정 메뉴는 요청 범위에서 제외한다.
  - 변경: `ProfileSetupPage.edit`가 기존 입력 UI·검증·사진 선택/미리보기를 재사용한다. 일반 수정 API에 변경 필드만 JSON/선택 이미지 multipart로 보내며 저장 후 설정의 사용자 정보·이미지 cache를 갱신한다. 선택값 빈 문자열 삭제, 저장 중 입력/뒤로가기/중복 요청 방지, 실패 후 재시도를 제공한다. Dio 401 갱신 후 multipart clone 재전송을 추가했다.
  - 근거: Flutter auth/profile 흐름, ADR-0024~0025, 인접 서버 authRoutes/authController/profileService 직접 확인. 일반 수정은 JSON·선택값 빈 문자열 삭제를 지원하며 사진 업로드는 가입 완료에만 존재하고 직종은 현재 4개 코드로 제한된다.
  - 영향범위: 프로필 편집 UI·인증 상태·관련 테스트·문서. 사용자 답변에 따라 사진 변경도 포함하고 서버 수정은 직접 수행하지 않으며 요청 문서를 준비한다.
  - 파일: `lib/features/auth/presentation/pages/{profile_setup_page,settings_page}.dart`, auth provider/repository/datasource·image upload entity, `lib/core/network/api_client.dart`, 기존 auth 테스트 5개 및 `_docs/{PROJECT_CONTEXT,DECISIONS,PROFILE_EDIT_SERVER_HANDOFF}.md`.
  - 테스트: `flutter test --no-pub --reporter expanded --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` 전체 227 pass·1 skip(기존 skip 유지). 초기값/이름만 전송/선택값 삭제/전화 검증/변경 없는 저장/사진 미리보기·전송/실패 재시도/중복 저장 방지/설정 복귀·취소/가입 완료 boolean 보존/동일 URL cache 재조회 및 실제 Dio adapter의 multipart header·401 갱신 후 파일/필드 동일 재전송을 검증했다. 변경 Dart 12개 분석 진단 0건·포맷 변경 0건, diff 검사 통과. 최초 추가 테스트의 MIME 헤더 대소문자 기대값을 HTTP 규칙에 맞게 수정한 뒤 전체 통과했다. SDK cache 쓰기 제한은 검증 명령만 승인된 권한으로 재실행했다.
  - 결과: Flutter 코드·모의 테스트 및 서버 요청 자료 준비 완료. ADR-0037 추가. 서버 일반 수정에 사진 parser/저장 처리와 자유 직종 DB/model/service/route/OpenAPI 확장이 필요하다. 확인한 것은 로컬 서버 코드이며 실제 Stage/운영의 배포 상태와 실기기 사진 교체는 미확인이다. 서버 코드 수정·배포·담당자 메시지 발송·새 빌드 업로드·커밋/푸시는 수행하지 않았다.
  - 다음: [서버 요청서](PROFILE_EDIT_SERVER_HANDOFF.md)를 담당자에게 전달하고 서버 테스트·Stage 실기기 인수 및 운영 선배포 후 Flutter 새 빌드를 제출한다.
  - 롤백: 이번 프로필 편집 진입점 및 저장 관련 변경만 되돌린다.

## 2026-11-09

- [DONE] (GIT/QA/DOCS) 미커밋 변경 확인 및 커밋 정리
  - 목적: 사용자 요청에 따라 현재 남은 변경을 확인하고 완료된 작업을 Git에 보존한다.
  - 변경: Debug 전용 호환 번호·실행 구성, 개인정보처리방침 공용 helper와 로그인/설정 링크·테스트, 빌드 1.0.0+4 및 출시 기록의 총 14개 파일을 검토하고 모두 보존한다. 추가 앱 코드 수정·기존 변경 삭제 없음.
  - 영향범위: 기존 미커밋 변경과 이번 검증 기록. 신규 기능·서버·스토어 조작은 포함하지 않는다.
  - 롤백: 정리 커밋을 일반 git revert로 되돌린다.
  - 테스트: `flutter test --no-pub --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key` 전체 214 pass·1 skip. Debug 번호 0/예상값 0 및 -1/기본값 1 상수 테스트 각각 2 pass. 변경 Dart 7개 분석 진단 0건·포맷 변경 0건, 실행 JSON·git diff 검사 통과. SDK 캐시/텔레메트리 쓰기 제한으로 최초 실행이 종료된 뒤 해당 검증 명령만 권한을 받아 재실행하여 정상 종료했다. 실제 자격증명 대신 테스트용 Stage 키를 사용했다.
  - 결과: `chore: 개인정보 정책 링크 및 빌드 4 출시 변경 정리` 로컬 커밋으로 보존한다. 아래 11월 8일의 미커밋 표시는 당시 상태 이력이며 이번 기록으로 대체한다. 기존 포털 게시·업로드 기록을 보존했으며 이번 작업에서 원격 push·스토어 재검증·빌드 생성은 하지 않았다. 새 설계/정책 결정이 없어 ADR 추가 없음.
  - 다음: 실기기 정책 링크 열기/복귀 및 최종 심사 전 동작 확인은 기존 후속 항목으로 유지한다.

## 2026-11-08

- [DONE] (FE/QA) 지정 iPhone SE에서 Debug 실행
  - 목적: 사용자 지정 기기 00008030-0015756A266B802E(iPhone SE 2세대, iOS 18.7.8)에서 현재 ShiftMate를 실행한다.
  - 변경: 기존 기본 Debug 구성과 동일하게 `.env`를 로드하고 Stage API·정상 호환 번호 1로 빌드/설치/실행한다. 앱 소스·서버 정책은 변경하지 않는다.
  - 영향범위: 지정 기기의 개발용 앱과 로컬 Debug 산출물. 제출용 Archive/IPA·심사 상태는 유지한다.
  - 테스트: 지정 기기에서 Xcode Debug 빌드 22.7초·설치/실행 28.9초 완료, 파일 동기화·Dart VM Service 연결 및 Hot reload 사용 가능 상태를 확인했다. Stage `/app/version-policy` GET 200을 시작/복귀 로그에서 확인했다. 화면별 기능 검증은 사용자 테스트로 남긴다.
  - 결과: `flutter run --debug --dart-define-from-file=.env -d 00008030-0015756A266B802E`를 기존 Xcode 빌드 위치 설정과 함께 실행했다. Debug 세션은 유지하며 앱 소스·서버 설정·제출용 빌드는 변경하지 않았다. 기존 다른 iPhone 세션은 종료하지 않았다.
  - 롤백: Debug 실행을 종료하거나 기존 TestFlight 앱으로 복구한다.

- [DONE] (STORE/DOCS) 크롬 App Store Connect 개인정보 설문 작성·게시
  - 목적: 사용자 요청에 따라 빌드 4의 실제 앱/서버/SDK 수집 항목을 포털에 반영한다.
  - 변경: 15개 데이터 유형·이용 목적·사용자 연결·추적 응답을 항목별로 작성·저장했다. 사용자 확인에 따라 보관하는 문의 내용도 고객 지원에 포함했다. 모든 유형은 사용자 연결 있음·추적 없음이다.
  - 영향범위: App Store 개인정보 선언과 근거 문서. 앱 코드·서버 수집 동작·최종 심사 제출은 변경하지 않는다.
  - 근거: 빌드 4의 GoogleSignIn/Firebase/Kakao PrivacyInfo.xcprivacy, 서버의 계정·기기·친구 관계·일정/프로필 및 운영 로그 구성, 사용자 문의 보관 확인.
  - 테스트: 포털 15개 유형·항목별 목적/연결/추적 저장, 설정 미완료 항목 없음·게시 버튼 활성, 사용자 동의 후 게시 완료 문구를 확인했다. 새로고침 후 게시 기록·15개 유형·모든 목적·연결 정보 유지와 미완료 설정 없음을 재확인했다. 앱 코드 변경이 없어 Flutter 테스트는 반복하지 않았다.
  - 결과: 2026-11-08 23:09(Asia/Seoul) Apple의 정확성·준수·갱신 의무 동의 문구에 사용자 동의를 받은 후 게시했다. 포털의 ‘현서 박 님이 몇 초 전에 게시함’을 직접 확인했다. 수집 선언을 반영했으며 수집 동작·정책 자체를 변경하지 않았다. 상세 목적 표는 APP_STORE_RELEASE_CHECKLIST 상단을 참조한다.
  - 다음: 실기기에서 빌드 4 정책 링크 열기/복귀 및 제출 환경 로그인 등 최종 동작 확인. App Review 제출은 미수행이다.
  - 롤백: 포털 개인정보 답변 편집으로 이전 상태를 복원한다. 심사 제출은 하지 않는다.

- [DONE] (FE/BUILD) 정책 링크 적용·설정 진입점 및 빌드 4
  - 목적: 제공된 패치의 미적용 작업을 실제 프로젝트에 반영하고 로그인 전후 개인정보처리방침 접근을 제공한다.
  - 변경: 패치 검토 후 로그인/설정에서 공용 외부 열기·실패 안내를 재사용하고 빌드를 1.0.0+4로 준비한다. 기존 Debug 테스트 변경은 보존한다.
  - 영향범위: 정책 링크 UI·테스트·빌드 번호·출시 기록. OAuth/동의 계약·API 호환 번호·서버 정책은 변경하지 않는다.
  - 롤백: 이번 링크/빌드 번호 변경만 되돌리고 보존한 기존 IPA를 선택한다.
  - 테스트: 로그인 전/설정 링크 성공·실패·플랫폼 예외·재시도·320×568/글자 2배·dispose 뒤 응답 및 로그인/설정/프로필/인증/업데이트 회귀 44개 통과. 변경 Dart 7개 분석 진단 0건, 최종 포맷 변경 0건·diff 검사 통과. IPA ZIP CRC, Apple Distribution deep/strict, App Store profile·production APNs/Apple 권한·Team ID, 1.0.0(4)/iPhone/iOS 15, AOT 운영 API·정책 host/path·업데이트 경로/Store ID 및 URL launcher 확인. Stage/로컬 API 문자열 부재 확인. 실기기 브라우저 열기·복귀는 미확인.
  - 결과: 제공 패치 중 앱/테스트/버전 변경을 적용하고 공용 helper로 설정 메뉴까지 확장했다. `build/ios/ipa/ShiftMate.ipa` 24,705,749 bytes, SHA-256 `6083946096dfe8537f6a7ab3273d860bf0df769fc82866131eb2eaae3bb6ac74`. 빌드 3은 `build/ios/releases/1.0.0-3/`에 보존했다. Transporter에서 2026-11-08 22:43(Asia/Seoul) 전송 완료를 확인했다. Connect 처리 완료 후 기존과 동일한 표준 암호화/프랑스 미배포 답변을 저장해 빌드 4의 제출 준비 완료를 확인하고 기존 빌드 3을 4로 교체·저장했다. 22:48 새로고침 후 빌드 4·저장 비활성 상태를 재확인했다. 심사 계정 비밀번호 등은 기록하지 않았다. 기존 LaunchImage 안내 1건 유지.
  - 문서: PROJECT_CONTEXT에 신규 helper 역할·의존성·사용 예/상태·롤백, 출시 체크리스트에 빌드/포털 근거를 기록했다. 기존 URL 열기 방식을 재사용하고 정책/인증 계약 변경이 없어 새 ADR은 추가하지 않았다. 이번 변경은 아직 커밋·푸시하지 않았다.
  - 다음: 실기기 정책 링크 열기/복귀 확인과 앱 개인정보 유형·이용 목적·연결/추적 답변 및 게시. 포털의 개인정보 설문은 게시 비활성/미작성 상태를 확인하고 사용자가 확정한 수집함 선택 후 데이터 유형 화면까지 다시 열어 두었다. 유형은 선택·저장하지 않았고 게시·최종 심사 제출은 수행하지 않았다.

- [DONE] (FE/QA) 배포된 버전 정책과 실기기 구버전 차단 확인
  - 목적: 서버 최소 호환 번호보다 1 낮은 앱에서 필수 업데이트 화면을 확인한다.
  - 변경: Debug 전용 DEBUG_API_COMPATIBILITY_VERSION 옵션과 로컬 v0 실행 구성을 추가했다. 사용자 정정에 따라 대상은 Stage가 아닌 172.30.1.14:3000 로컬 서버다. 사용자 서버 실행 후 최소값 1의 공개 응답을 확인했다. Profile/Release 번호 1 및 제출 IPA는 유지했다.
  - 영향범위: 명시적으로 옵션을 준 Debug 빌드·실행 구성·검증 기록. 서버 env/프로세스는 사용자가 설정·실행했고 이번 작업에서 직접 변경하지 않았다.
  - 롤백: 테스트 번호를 정상 호환 번호로 복구하고 정상 앱을 재실행한다.
  - 테스트: 기본 상수/업데이트 회귀 12개 통과, Debug 번호 0 적용 2개 및 음수 fallback 2개 통과. 변경 Dart 분석 진단 0건·포맷 변경 0건·실행 JSON·git diff --check 통과. Stage/운영 공개 GET 200·최소값 0 확인. 로컬 서버 실행 전 연결 거절을 확인하고 사용자 실행 후 무인증 GET 200·no-store·최소값 1·정상 Store ID 확인. 연결 iPhone에서 테스트 구성을 실행했고 사용자가 ‘업데이트가 필요해요’ 표시를 직접 확인했다. 디버그 중단점은 제거했다.
  - 결과: 유효한 구버전 번호 0과 로컬 최소값 1의 차단 확인 완료(화면은 사용자 확인). 음수 앱 번호나 운영 정책 인상으로 테스트하지 않았다. 실제 Store 이동·복귀 및 정상 번호 1 재실행은 후속 확인 항목이다. ADR-0036 및 APP_VERSION_POLICY에 옵션·파일 역할·실행/복구 절차를 기록했다.
  - 다음: 테스트 화면에서 업데이트 버튼·앱 복귀를 확인하고 기본 debug local 구성으로 완전 재실행하여 번호 1을 사용한다. 현재 테스트 번호 0 화면을 확인할 수 있도록 사용자 세션은 종료하지 않았다. 이번 변경은 아직 커밋·푸시하지 않았다.

- [DONE] (GIT/DOCS) 남은 미커밋 작업 전체 정리 및 푸시
  - 목적: 후속 사용자 요청에 따라 이전 커밋에서 제외한 작업도 원격에 보존한다.
  - 변경: 프로필 이미지 인증·계정 전환 캐시 무효화·로컬 디버그·iPhone 전용 설정·출시/개인정보 문서·스토어 스크린샷과 기존 작업 기록을 함께 정리한다.
  - 영향범위: 현재 Flutter 저장소의 잔여 변경 전체. 서버 저장소 main·운영 배포·심사 제출은 변경하지 않는다.
  - 롤백: 추가 커밋을 git revert하며 원격 강제 push는 하지 않는다.
  - 테스트: 변경 Dart 9개 파일 정적 분석 진단 0건·포맷 변경 0건. JSON/XML/plist·Xcode 설정·HTML·Markdown 구조, RGB PNG 9개와 ZIP 일치/CRC, 자격증명 패턴 미포함 및 환경 파일/IPA ignore 확인 통과. 앞서 동일 코드의 전체 테스트 206 pass·1 skip 결과를 유지하며 코드 수정 없이 재실행하지 않았다. staged diff 검사 통과, git ls-remote의 origin/main과 로컬 HEAD가 a123a07e78176a0e4d37600e1aacc4992b7473cc로 일치함을 확인했다.
  - 결과: 잔여 변경 35개 파일을 `a123a07`(프로필 이미지 인증 수정 및 출시 준비 자료 정리)로 커밋하고 origin/main에 정상 push했다. 환경 파일·서명 비밀값·Archive/IPA는 제외했다. 서버 운영 배포·앱 업로드·심사 제출은 수행하지 않았다.

- [DONE] (GIT/DOCS) 작업 커밋·푸시 및 서버 담당자 전달 가이드 작성
  - 목적: 완료한 기능을 원격 저장소에 보존하고 서버 적용 작업을 전달 가능하게 정리한다.
  - 변경: 사용자 선택으로 업데이트 기능·서버 가이드만 분리하고 기존 프로필 이미지·로컬 디버그·출시 자료는 제외. 서버 기능 90ece07을 origin/codex/app-compatibility-policy에, FE 기능/가이드 c27b263을 origin/main에 push 완료. APP_VERSION_SERVER_HANDOFF 가이드와 전달 패치를 준비했다.
  - 영향범위: Git 기록·원격 기능 브랜치·관련 문서. 운영 배포·심사 제출 미수행.
  - 롤백: 일반 revert로 변경을 되돌리며 원격 강제 push는 사용하지 않는다.
  - 테스트: 선택한 커밋 스냅샷에서 정적 분석 진단 0건·전체 테스트 204 pass/1 skip. 기존 작업 트리의 206 pass와 별도로 검증했다. 잠금 파일 일치·가이드 상대 링크/코드블록·자격증명 패턴 미포함·패치 역방향 적용 검사·서버 원격 HEAD=90ece07 확인 및 git diff --cached --check 통과.
  - 결과: 프론트 기능 20개 파일·서버 기능 13개 파일을 각 저장소에 보존. 서버 가이드는 코드 반영·초기 최소값 0·무인증 조회·Stage/운영 수용 기준·추후 인상 순서·롤백·회신 양식을 포함한다. 기존 비대상 변경은 작업 트리에 유지하며 실제 메시지 전송·서버 배포·심사 제출은 수행하지 않았다.
  - 다음: 서버 담당자가 origin 기능 브랜치를 검토·병합하고 최소값 0으로 배포한 뒤 가이드의 검증 결과를 회신한다.

- [DONE] (DOCS) 출시 스크린샷 폰트 상업 이용 라이선스 확인
  - 목적: Figma 홍보 문구 및 원본 앱 화면 글꼴의 스토어 이미지 이용 가능 여부를 확인한다.
  - 변경: Figma 실제 폰트 목록과 공식 라이선스·로컬 원문을 대조하고 출시 체크리스트에 근거를 남긴다.
  - 영향범위: 검증 기록만 변경. 디자인·앱 코드 변경 없음.
  - 롤백: 이번 검증 기록 추가만 제거한다.
  - 테스트: Figma 텍스트 32개 Noto Sans KR Black/Medium/Regular 집계. Noto 공식 OFL·SIL FAQ 확인, Cafe24 원문 PDF 각 2페이지 PDFKit 렌더링 후 판독, git diff --check 통과. Poppler 미설치·텍스트 레이어 부재를 렌더링으로 해결. 앱 테스트 미실행.
  - 결과: 제작 PNG의 상업적 홍보 사용 허용, 이미지 내 출처 표기·추가 구매 불필요 확인. 폰트 자체 판매 금지·폰트 파일 재배포 고지 조건과 구분하여 체크리스트·컨텍스트 기록. 앱 바이너리 고지 및 다른 콘텐츠 권리 확인은 별도이며 앱 전체 적법성을 확정하지 않는다. 설계·정책 변경이 없어 ADR 추가 없음.

- [DONE] (FE/BE/BUILD) 서버 최소 지원 버전 기반 업데이트 안내 및 재빌드
  - 목적: 서버 변경으로 호환되지 않는 구버전 앱의 사용자를 스토어 업데이트로 안내한다.
  - 변경: 사용자 확정대로 앱 내부 API 호환 번호 1과 서버 최소 정수를 비교(스토어 버전·빌드와 독립). 공개 정책 API, 시작/복귀 전역 게이트·환경/플랫폼 캐시·스토어 이동/실패 재시도, url_launcher 6.3.2, OpenAPI·설정표·운영/롤백 문서 및 ADR 추가. 새 iOS 1.0.0(2) 빌드 생성. 이전 빌드 1 보존.
  - 영향범위: 버전 정책 조회·앱 진입 흐름·관련 문서·빌드 산출물. 실제 서버 배포·심사 제출은 별도다.
  - 롤백: 버전 정책 비활성화 또는 이번 게이트 연결·API 추가만 되돌린다.
  - 테스트: 변경 파일 analyzer 진단 0건, Flutter 전체 206 pass·1 skip. 서버 TypeScript build 및 신규 HTTP/설정 5개+기존 환경/Google/푸시를 합쳐 23개 통과. 최소값 경계·플랫폼/URL·무인증·캐시 격리/손상/장애·중복 조회·dispose·스토어 실패·복귀·상세/다이얼로그 차단·작은 화면 검증. IPA ZIP CRC·Apple Distribution deep/strict·App Store profile·production 권한·1.0.0(2)/iPhone/SDK·AOT 새 게이트/정책 API/운영 API/Store ID·스토어 플러그인 및 git diff --check 통과. 기본 LaunchImage 안내 유지. url_launcher 6.3.3의 SDK 비호환은 6.3.2 고정으로 해결.
  - 결과: `build/ios/ipa/ShiftMate.ipa`, SHA-256 `9ea369145c838bbb64052e52bd373a6ca970bb4ac5dd33f5ca3368aa9174332f`. 서버는 기존 main을 보존한 develop 기반 `codex/app-compatibility-policy` 로컬 커밋 `90ece07` 및 전달 패치로 준비. 상세 역할/명령/영향/롤백은 APP_VERSION_POLICY·출시 체크리스트 기록.
  - 다음: 서버 API 실제 배포·실기기 Store 이동/복귀·Connect 업로드. 지원 앱 스토어 공개 뒤 최소 호환 번호 인상. 서버 배포·원격 push·앱 업로드·심사 제출 미수행.

- [DONE] (BUILD/DOCS) iOS App Store 제출용 빌드 생성
  - 목적: 사용자 요청에 따라 현재 작업 트리의 iPhone Release Archive 및 배포 파일을 준비한다.
  - 변경: 심사 로그인 정보와 보조 계정 메모 입력을 첨부 화면으로 확인(비밀번호 미기록). Xcode 27.1/SDK 27.1, Flutter 3.38.5/Dart 3.10.4 및 `.env`/네이티브 설정 일치 확인 후 현재 작업 트리로 Release 1.0.0(1) Archive·App Store IPA 생성. 앱 소스·의존성·버전 설정 추가 변경 없음.
  - 영향범위: 로컬 빌드 산출물·출시 문서. 심사 제출·스토어 출시는 요청 범위에 포함하지 않는다.
  - 롤백: 이번 빌드에서 생성한 산출물과 필요한 빌드 설정 변경만 제거하며 기존 작업 트리는 유지한다.
  - 테스트: 기존 전체 테스트 196 pass·1 skip. 전체 분석 error/warning 0, 기존 무관 info 33건으로 종료 코드 1. Archive 앱 설정 검증 통과. IPA ZIP CRC·Apple Distribution deep/strict 서명·App Store profile·iPhone 전용/버전/SDK·production APNs·Apple entitlement·OAuth callback·AOT 운영 API 포함/Stage·로컬 API 부재 및 git diff --check 통과. 기본 LaunchImage placeholder 안내 1건을 확인하고 기존 시작 화면 유지.
  - 결과: `build/ios/archive/Runner.xcarchive`, `build/ios/ipa/ShiftMate.ipa`(24,618,369 bytes). SHA-256 `41a1f1d62f2633a3dee4bb1931f7983685259f87a9acea43c0a5bd25baf22747`. 산출물 역할·의존성·재현 명령·롤백을 출시 체크리스트에 기록. 새 설계/정책 결정이 없어 ADR 추가 없음.
  - 다음: Xcode Validate App·Connect 업로드 및 빌드 선택. 실제 기기/TestFlight 운영 로그인·푸시·공유 검증, 개인정보·연령·콘텐츠 권리·출시 방식 확인은 후속. 업로드·심사 제출·출시 미수행.

- [DONE] (DOCS) Google 심사 계정 2개 회원가입 완료 반영
  - 목적: 계정 생성·가입과 제출 준비 완료를 구분한다.
  - 변경: 사용자 제공 review1/review2 계정 생성 및 ShiftMate 가입 완료 기록. 친구·그룹 연결·예시 데이터·제출 환경 로그인·Connect 저장은 미확인으로 구분.
  - 영향범위: 출시 체크리스트·컨텍스트·작업 로그만 변경.
  - 롤백: 이번 계정 준비 상태 기록만 되돌린다.
  - 테스트: 사용자 보고 대조·비밀번호 비기록·git diff --check 통과. 직접 로그인·앱 실행 미수행.
  - 다음: 두 계정 친구·그룹 연결 및 예시 근무표 준비, Connect 로그인 정보 입력, 제출 환경 접근 확인. 설계·정책 변경 없음.

- [DONE] (DOCS) App Store Connect 저장 완료 및 남은 심사 준비 반영
  - 목적: 사용자 보고로 확인한 등록 상태와 미완료 항목을 구분한다.
  - 변경: 저작권·연락처·메타데이터·URL·심사 메모·가격/국가·스크린샷 저장 완료(사용자 보고), 잔여 5개 항목 및 자동 출시 설정 기록. 과거 포털 미입력 설명보다 최신 보고를 우선한다.
  - 영향범위: 출시 체크리스트·컨텍스트·작업 로그. 앱·포털 설정 변경 없음.
  - 롤백: 이번 상태 기록만 되돌린다.
  - 테스트: 사용자 보고 대조·문서 일관성·전화번호 원문 비복사·기존 공개 지원 이메일 유지·git diff --check 통과. 포털 직접 재검증 및 앱 테스트 미수행.
  - 결과: 출시 체크리스트 최신 상태표·컨텍스트 갱신. 새 설계/정책 결정이 없어 ADR 추가 없음.
  - 다음: Google 심사 계정·제출용 빌드·개인정보 설문·연령 등급·콘텐츠 권리 확인 후 출시 방식 재확인. 심사 미제출 유지.

- [DONE] (DESIGN/DOCS) 첨부 화면 기반 App Store 스크린샷 4장 제작
  - 목적: 실제 앱 화면에 기능 소개 문구를 더해 iPhone 출시용 이미지를 준비한다.
  - 변경: 사용자 선택 개인 Figma 팀에 실제 화면·편집 가능한 홍보 문구·배경으로 4종 제작. 1290×2796 및 1179×2556 각 4장, 미리보기·ZIP 저장. 출시 체크리스트·컨텍스트에 파일 역할/의존성/사용 예 기록.
  - 영향범위: 출시 디자인 산출물·관련 문서. 앱 코드·DB 변경 없음.
  - 롤백: 이번 문서 추가 및 새 Figma 파일만 제거한다.
  - 테스트: Apple 공식 규격 확인, Figma 이미지 4개·홍보 텍스트 16개·폰트·프레임 크기 검사, 전체 구성 및 RGB 변환 후 시각 검수. PNG 크기·8bit RGB·알파/tRNS 부재·CRC·압축 데이터 길이·ZIP 무결성 및 git diff --check 통과. Pillow 미설치로 미리보기 조합 시도 중단 후 Figma 전체 프레임 export 사용. 앱 코드 변경이 없어 Flutter 테스트 미실행.
  - 결과: [Figma 편집본](https://www.figma.com/design/bkMSAJCfP2X28FuyNJu1Ej?node-id=2-2), `artifacts/app_store_screenshots/ShiftMate_AppStore_Screenshots.zip`. 앱 설계·정책 변경이 없어 ADR 추가 없음.
  - 다음: 사용자 디자인 검토 및 App Store Connect 등록. 실제 등록·심사 제출은 미수행.

- [DONE] (FE) 보호된 프로필 이미지 인증 요청 수정
  - 목적: 서버에서는 조회되지만 앱에서는 표시되지 않는 프로필 이미지 요청의 인증 누락을 해결한다.
  - 변경: 이미지 표시 5곳과 기존 Dio 인증 흐름 확인 후 공용 이미지 위젯 적용.
  - 영향범위: 설정·가입·친구 프로필 이미지.
  - 롤백: 이번 공용 위젯과 호출부 변경만 되돌린다.
  - 테스트: 이미지 인증·설정·가입·친구 화면·인증 Provider 테스트 총 29개 통과. 변경 파일 정적 분석 오류 없음, git diff --check 통과. 전체 분석은 기존 무관 파일의 lint info 33건으로 종료 코드 1.
  - 결과: 관리 이미지 5곳을 공용 Dio byte 조회로 전환하여 Bearer·refresh 재사용, 외부 이미지 무인증 유지. 빈 URL/오류 fallback과 계정 전환 무효화 적용. ADR-0034·컨텍스트 갱신.
  - 다음: 활성 디버그 대상이 없어 실제 기기의 URL·응답 상태 및 화면 표시는 미검증. Stage 앱 재실행 후 확인 필요.


- [DONE] (FE) 로컬 서버 디버그 실행 옵션 추가
  - 목적: 172.30.1.14:3000 서버로 디버그 실행한다.
  - 변경: 기존 Stage 실행을 유지하고 ShiftMate (debug local) 구성과 USE_LOCAL_API Debug 옵션, Android Debug HTTP 허용 추가.
  - 영향범위: API 상수·VS Code 실행 설정·개발용 네트워크 설정.
  - 롤백: 이번 로컬 옵션 변경만 되돌린다.
  - 테스트: Dart 포맷 변경 없음, flutter analyze 대상 파일 오류 없음, 실행 구성 JSON·manifest XML 검증 및 git diff --check 통과. 실제 기기 서버 연결은 미검증.

## 2026-10-18

- [DONE] (DOCS/WEB) 심사 제출용 개인정보 HTML 공개 문체 정리
  - 목적: 이용자에게 불필요한 구현/검토 메모를 운영 문서로 분리한다.
  - 변경: 기존 정책 본문과 외부 서비스 공식 자료 대조, 시행일·운영 보관 적용 최종 확인 요청.
  - 영향범위: 개인정보 MD/HTML·검토 기록. 서버 재게시 없음.
  - 롤백: 이번 본문 갱신만 되돌린다.
  - 테스트: HTML 구조·14개 절·링크·시행일/정책값·검토 표현 제거 검사 및 git diff --check 통과. Google/Firebase/Apple/AWS/카카오/네이버 공식 개인정보 자료 확인. 브라우저 시각 QA 미실행.
  - 결과: MD/HTML 공개 문안 v1.0 작성. 날짜·보관 절차 적용·이미지 백업 없음은 사용자 확인. 국외 이전 계약별 완결성은 별도 검토 필요로 내부 기록.
  - 다음: 실제 계약별 고지 대조 후 서버 담당자 HTML 재게시·공개 GET/앱/Connect 확인. 운영 명령·공개 배포·심사 제출 미수행.

- [DONE] (DOCS/FE) BE-05 사용자 구현·검증 완료 확인 반영
  - 목적: 사용자가 직접 완료했다고 알린 최신 상태를 반영한다.
  - 변경: BE-05 구현·검증 완료(사용자 확인)로 상태 갱신. Codex 직접 실행 검증과 구분.
  - 영향범위: 진행표·검토/계약 문서·출시 컨텍스트. 프로그램·서버 변경 없음.
  - 롤백: 이번 상태 기록만 되돌린다.
  - 테스트: 사용자 최신 명시 진술과 진행/계약 문서 상태 대조, git diff --check 통과. 프로그램 테스트를 실행했다고 기록하지 않음.
  - 다음: 나머지 운영 적용/방침 확정 항목 진행. BE-05 완료를 다른 검증의 완료로 확대하지 않는다.

- [DONE] (DOCS/OPS) main 배포 완료와 운영 검증 대기 분리
  - 목적: 최신 사용자 전달 상태를 구현/배포/실행 증거별로 정확히 반영한다.
  - 변경: BE-01~04 코드 배포 완료, 실삭제/cleanup/감시/보관 검증 대기, 개인 AWS/Gmail 및 S3 versioning off 확인 기록.
  - 영향범위: 개인정보 문서. 실제 서버 변경·운영 명령 실행 없음.
  - 롤백: 이번 문서 갱신만 되돌린다.
  - 테스트: 최신 사용자 전달과 코드 배포/검증 상태·계정 유형/versioning 문구 대조, HTML 구조 검사·git diff --check 통과.
  - 다음: Stage 실삭제·monitor 및 timer/메일 실수신·보관 적용 증거. 시행일·최종 방침은 아직 미확정.

- [DONE] (DOCS/OPS) 운영 완료 답변 철회 및 백업 사실 정정
  - 목적: 최신 사용자 정정을 정본으로 반영하고 미확인 작업을 완료 처리하지 않는다.
  - 변경: BE-01~04·보관 정책 운영 검증 미완료, 수동 DB 백업 존재·기간 미확정, 이미지 백업 미확인 기록.
  - 영향범위: 정책 MD/HTML·진행/검토 문서. 실제 서버·DB·백업 변경 없음.
  - 롤백: 이번 기록 정정만 되돌린다.
  - 테스트: 사용자 최신 정정과 항목별 문서 대조·HTML 구조/수동 백업 문구·내부 경로 비노출 검사·git diff --check 통과.
  - 다음: 운영 담당자 배포/실행/정리/감시/보관 증거 및 미확정 사실 회신 후 정책 최종화. 최종화 작업은 TODO 유지.

- [TODO] (DOCS/WEB) 개인정보처리방침 최종본 확정
  - 목적: 공개 검토 문구를 제거하기 전에 최종 본문에 필요한 운영 사실을 확정한다.
  - 변경: 기존 승인 내용을 유지하고 운영 배포/보관 절차, 별도 백업, 시행일/계정 구성/BE-05 상태를 사용자에게 묶어 확인 요청.
  - 영향범위: 정책 MD/HTML 최종화. 아직 최종본·게시 완료 아님.
  - 롤백: 최종화 변경 전 기존 검토본 유지.
  - 테스트: 답변 수신 후 최종 문구·HTML 구조·잔여 검토 표현 검사 예정.

- [DONE] (DOCS/OPS) AWS S3 서울 리전·복제/CDN 미사용 반영
  - 목적: 사용자 확인값으로 이미지 저장 위치의 미확정 항목을 줄인다.
  - 변경: ap-northeast-2, 복제 없음, CDN 없음 기록 및 정책 MD/HTML 동기화.
  - 영향범위: 개인정보 문서. 서버·S3 설정 변경 없음.
  - 롤백: 이번 문서 갱신만 되돌린다.
  - 테스트: MD/HTML 서울 리전·복제/CDN 없음 문구와 HTML 구조 검사, git diff --check 통과.
  - 다음: 별도 백업·계약 법인·파기 증거 및 타 외부 서비스 처리 내역 확인. 공개 재게시 미수행.

- [DONE] (DOCS/OPS) 프로필 이미지 AWS S3 저장 사실 정정
  - 목적: 사용자 정정에 따라 홈서버/외부 저장 설명을 바로잡는다.
  - 변경: 정책 MD/HTML·검토/요청서·작업표의 이미지 저장을 AWS S3로 변경. 리전·복제·CDN·파기 증거는 대기.
  - 영향범위: 개인정보 문서. 저장소·프로그램·서버 변경 없음.
  - 롤백: 이번 문서 변경만 되돌린다.
  - 테스트: AWS 공식 S3 리전/개인정보 안내 확인, MD/HTML S3 문구·기존 설명 제거·HTML 구조 검사·git diff --check 통과.
  - 다음: 버킷 리전·복제·CDN·백업 국가와 계약 법인 확인. 실제 서버·S3 설정 변경 및 공개 재게시 미수행.

- [DONE] (DOCS/FE) BE 개인정보 작업 인수 및 가입 계약 FE 회신안
  - 목적: BE-01~04 구현 증거·운영 대기를 반영하고 BE-05 합의점을 구체화한다.
  - 변경: 전달서와 서버 소스·현재 revision 대조, 정책 검토본 갱신, FE 화면/DTO/SDK 경계 회신안 작성.
  - 영향범위: 정책 MD/HTML·진행표·FE 계약 제안 문서. 실제 API/DB/가입 동작 변경 없음.
  - 롤백: 이번 문서 갱신만 되돌린다.
  - 테스트: 전달서 두 개·BE 현재 c1af0f7 및 clean 상태·핵심 이미지/기기/worker/retention 소스와 FE 인증/프로필/SDK 경계 대조, HTML 14개 절·문구·구조 검사, git diff --check 통과. BE 보고 테스트는 FE 재실행하지 않았다.
  - 결과: FE_PRIVACY_CONTRACT_REPLY.md 후보 DTO/라우팅/오류/SDK 경계·QA 작성. 정책 MD/HTML·작업표·검토·요청서·컨텍스트/ADR 인수 상태 갱신. 새 파일 역할·의존성·사용 예 기록.
  - 다음: BE-01~04 운영 적용 증거, BE-05 운영 동의 범위·API/DTO 합의 후 FE 계약 테스트/구현. 서버 배포·신규 가입 필드·SDK 순서 변경·외부 전송 미수행.

- [DONE] (DOCS/OPS) 개인정보 문서 수정과 프로그램·운영 요청 분리
  - 목적: 공개 검토본과 실제 구현의 불일치를 담당·완료 기준별로 처리한다.
  - 변경: 제공자별 해제·연령 정책·국내 저장 설명 정정, FE/BE/운영 작업표·백엔드 전달 요청서 작성.
  - 영향범위: 정책 MD/HTML·검토/작업 요청 문서. 실제 서버·백엔드 코드 변경 없음.
  - 롤백: 이번 문서 변경을 되돌린다.
  - 테스트: 공개 정책 GET 200·검토본 확인, Google/Naver FE·Apple/Kakao BE 경로 및 기기/푸시 코드 대조, HTML 구조·14개 절·제공자별 문구 검사와 git diff --check 통과.
  - 결과: 정책 MD/HTML 정정, PRIVACY_ACTION_PLAN.md·BACKEND_PRIVACY_REQUEST.md 작성 및 역할/의존성/사용 예 연결. 로컬 문서 수정 완료와 미구현 프로그램/미확인 운영을 분리했다.
  - 다음: 요청서를 서버 담당자에게 전달 후 항목별 증거 회신. FE 계약/링크 작업은 작업표에 별도 TODO. 실제 코드 수정·서버 게시·메시지 전송 미수행. 설계 변경 없음.

- [DONE] (DOCS/WEB) 공개 지원 URL 확인 및 개인정보처리방침 검토본 작성
  - 목적: 사용자 제공 www 지원 URL 확인과 코드 근거 기반 정책 문서 작성.
  - 변경: 프론트·인접 백엔드 읽기 조사, 정책 MD/HTML 및 운영 확정 항목 정리.
  - 영향범위: 프론트 저장소 문서·정적 HTML. 백엔드·서버 설정 변경 없음.
  - 롤백: 이번 정책 문서·HTML 갱신만 되돌린다.
  - 테스트: www 지원 200/HTML·정책 404 확인, 개인정보 보호법 제30조·Firebase 공식 처리 안내 확인, HTML 구조·14개 절·링크·채택 정책값 검사·git diff --check 통과. Chrome 미리보기 도구 timeout으로 시각 검증 미완료.
  - 결과: `PRIVACY_POLICY.md`, `PRIVACY_REVIEW.md` 추가, 동일 본문 privacy.html·가이드·출시 문서 갱신. 역할·의존성·사용 예는 컨텍스트·검토 문서에 기록.
  - 다음: 운영 보관 설정·잔여 기기/이미지 파기·국외 이전·가입 제한 확인 후 최종화·시행일 확정·게시. 서버 변경/배포 미수행. 사용자 승인 보관 정책은 ADR-0032 기록.

- [DONE] (DOCS/WEB) 서버 담당자 전달용 HTML·배포 가이드 작성
  - 목적: 사용자가 지정한 기존 홈서버에서 지원·정책 페이지를 제공하도록 전달 자료를 만든다.
  - 변경: 독립형 support/privacy HTML과 Nginx 전달·검증·롤백 가이드. 개인정보 미확정 운영 항목은 공개 전 초안으로 표시한다.
  - 영향범위: 신규 정적 파일·배포 문서·출시 문서. 서버 설정과 배포는 담당자가 수행.
  - 롤백: 이번 파일·문서 추가를 되돌린다.
  - 테스트: HTMLParser로 두 HTML 태그 구조·viewport·내부 링크·지원 이메일 및 외부 스크립트/폼 없음 확인, 개인정보 초안 표시 확인, git diff --check 통과.
  - 파일: `_docs/app_store_web/{support.html,privacy.html,DEPLOY_GUIDE.md}`. 파일 역할·의존성·사용 예는 가이드와 PROJECT_CONTEXT에 기록.
  - 다음: 담당자가 운영 정책 확정·배포 후 HTTP/TLS·브라우저·API 회귀 결과 공유. 로컬 시각 검증·Nginx 검사·공개 배포는 미실행. 설계 변경 없음.

- [DONE] (DOCS/OPS) 홈서버·DNS 화면 증거 기록
  - 목적: 기존 DNS를 유지하고 실제 필요한 서버 설정을 구분한다.
  - 변경: @/api/stage-api 동일 IP, www CNAME 화면 및 개인 홈서버 운영 진술 반영.
  - 영향범위: 출시 체크리스트·작업 로그.
  - 롤백: 이번 기록만 되돌린다.
  - 테스트: 사용자 DNS 화면의 호스트·타입·값 대조, Nginx 공식 정적 제공·프록시 역할 확인, git diff --check 통과.
  - 다음: 홈서버 HTTPS 진입점 확인. DNS·서버 변경 미수행.

- [DONE] (DOCS/OPS) 기존 도메인의 정책 페이지 제공 방향 기록
  - 목적: 사용자 요청대로 shiftmate.co.kr에서 개인정보처리방침을 제공할 준비를 한다.
  - 변경: 정적 HTML·예정 URL·DNS/TLS/서버 연결 확인 과제 기록.
  - 영향범위: 출시 체크리스트·프로젝트 컨텍스트.
  - 롤백: 이번 문서 변경만 되돌린다.
  - 테스트: Apple 공식 개인정보 URL 요건 확인, 저장소 서버 배포 설정 검색, 도메인 조회 시 도구·네트워크 제약 확인(실제 도메인 장애로 단정 불가), git diff --check 통과.
  - 다음: 기존 서버·DNS/TLS 구성 확인 후 HTML 내용 확정·제공. HTML 생성·공개 배포 미실행.

- [DONE] (DOCS/OPS) 최초 출시 범위·공개 지원 이메일 확정 기록
  - 목적: 사용자 확정값과 웹 안내 페이지 요건을 반영한다.
  - 변경: 대한민국 한정·무료·IAP 없음, 공개 지원 이메일 sspp8585@gmail.com 기록. 앱 서비스와 지원/정책 웹페이지 구분.
  - 영향범위: 출시 체크리스트·프로젝트 문서·ADR.
  - 롤백: 이번 확정 기록만 되돌린다.
  - 테스트: 사용자 확정값·Apple 필수 지원/개인정보 URL 요건 대조, git diff --check 통과.
  - 다음: 실제 데이터 처리 확인 후 정책·지원 안내 초안과 공개 위치 준비. 포털 등록·웹 게시 미수행.

- [DONE] (IOS/OPS) 최초 출시 iPhone 전용 설정
  - 목적: 사용자 요청에 따라 iPad 네이티브 지원을 후속 업데이트로 미룬다.
  - 변경: Debug/Profile/Release 기기 지원을 iPhone으로 제한하고 출시 문서·ADR 갱신.
  - 영향범위: iOS 빌드 기기 지원·스크린샷 준비 범위. Behavior change: iPad 전용 지원 제외.
  - 롤백: TARGETED_DEVICE_FAMILY를 1,2로 복구한다.
  - 테스트: plutil 프로젝트 구문 검사 통과, xcodebuild -showBuildSettings로 Runner Debug/Profile/Release 모두 TARGETED_DEVICE_FAMILY=1 확인, git diff --check 통과.
  - 다음: 제출 Archive의 UIDeviceFamily=[1] 확인. 이번 작업에서 전체 빌드·실기기 실행은 수행하지 않았다. iPad 지원은 ADR-0030의 후속 과제로 기록.

- [DONE] (DOCS/OPS) 2번 App Store 등록 정보 초안 및 자산 점검
  - 목적: 계약 차단과 독립적으로 등록용 문구·촬영 계획을 준비한다.
  - 변경: 구현 근거 기반 한국어 메타데이터 초안, 아이콘·기기 지원·공개 URL 상태 확인.
  - 영향범위: 출시 체크리스트·프로젝트 문서.
  - 롤백: 이번 문서 추가분만 되돌린다.
  - 테스트: 구현 서비스·화면 호출 확인, PNG 헤더 1024×1024 RGB 확인 및 이미지 시각 확인, 메타데이터 글자·UTF-8 키워드 제한 검사, Apple 공식 필드·스크린샷 규격 확인, git diff --check 통과.
  - 결과: 출시 문서에 이름·부제·설명·홍보문구·키워드 초안과 촬영 5종 계획을 추가했다. 등록 완료 체크는 유지했다.
  - 다음: 배포 국가·가격·공개 지원 채널·게시 위치 확정 후 지원/정책 URL 준비. 촬영·Archive·실기기 검증 미실행. 설계 변경 없어 ADR 추가 없음.

- [DONE] (DOCS/OPS) 대한민국 규정 준수 활성화 및 계약 추가 조치 부재 확인
  - 목적: 최신 화면으로 규정 준수 완료와 남은 계약 차단을 구분한다.
  - 변경: DSA·대한민국 전자상거래법 활성화 확인, 계약 행의 추가 수락 UI 없음(사용자 보고) 기록.
  - 영향범위: 출시 체크리스트·작업 로그 및 문의 초안.
  - 롤백: 이번 기록만 되돌린다.
  - 테스트: 최신 화면의 활성화 상태·갱신일과 문의 초안 대조, git diff --check 통과.
  - 다음: Apple 지원에 계약 적용 상태 문의. 문의 미전송, 원인 미확정.

- [DONE] (DOCS/OPS) 계약 팝업 지속 증거 및 지원 문의 초안 정리
  - 목적: 반복 안내를 중단하고 확인된 사실로 지원 진단을 준비한다.
  - 변경: DSA 완료 후에도 계약 팝업 지속 화면 확인, 지원 문의 초안 추가.
  - 영향범위: 출시 체크리스트·작업 로그.
  - 롤백: 이번 문서 기록만 되돌린다.
  - 테스트: 제공 화면과 문의 초안의 계약명·날짜·상태 대조, git diff --check 통과.
  - 다음: 무료 앱 계약의 추가 조치 유무 확인 후 필요 시 사용자가 지원 문의. 문의 미전송.

- [DONE] (DOCS/OPS) DSA 완료 및 대한민국 연락처 입력 상태 반영
  - 목적: 사용자 화면에 확인된 규정 준수 진행 상태를 갱신한다.
  - 변경: DSA 완료·활성화 확인, 대한민국 연락처 입력·BRN 아니요 선택 중 기록.
  - 영향범위: 출시 체크리스트·작업 로그.
  - 롤백: 이번 기록 변경만 되돌린다.
  - 테스트: Apple 공식 대한민국 규정 준수 안내·DSA 활성화 화면 대조, git diff --check 통과.
  - 다음: 사용자 연락처 확인·인증·최종 저장. 앱 추가 차단 해결 여부는 미확인.

- [DONE] (DOCS/OPS) DSA 신고 화면 및 무료 계약 상태 기록
  - 목적: 사용자 선택의 적용 조건과 실제 계약 상태를 구분한다.
  - 변경: DSA 두 번째 선택지는 선택 중이며 저장 미확인, 무료 앱 계약 활성화됨(새로운 계약 사용 가능) 표시 확인.
  - 영향범위: 출시 체크리스트·작업 로그.
  - 롤백: 이번 기록만 되돌린다.
  - 테스트: Apple 공식 DSA 적용 조건과 화면 문구 대조, git diff --check 통과.
  - 다음: 배포 계획에 맞는 사용자 신고·저장 결과 확인. 차단 원인은 미확정.

- [DONE] (DOCS/OPS) 계약 수락 후 앱 추가 차단 지속 기록
  - 목적: 재시도 결과와 다음 진단 경로를 남긴다.
  - 변경: 사용자 보고로 같은 팝업 지속 확인. 계약 수락 완료는 유지하고 Business 계약 상태 확인으로 전환한다.
  - 영향범위: 출시 체크리스트·작업 로그.
  - 롤백: 이번 문서 기록만 되돌린다.
  - 테스트: Apple 공식 계약 상태·유료 계약 안내 확인, git diff --check 통과.
  - 다음: 비즈니스 계약 상태 확인. 원인·해결 시점은 미확정이며 문의 전송 없음.

- [DONE] (DOCS/OPS) 개발자 계약 수락 증거 반영
  - 목적: 새로 제공된 계약 화면에 따라 현재 상태를 정정한다.
  - 변경: 2026-10-14 발행 Program License Agreement의 2026-10-18 수락을 기록한다.
  - 영향범위: 출시 체크리스트·작업 로그.
  - 롤백: 이번 문서 변경만 되돌린다.
  - 테스트: 계약명·발행일·수락일 화면 대조, git diff --check 통과.
  - 다음: Connect 새로고침 후 앱 추가 재시도. 이전 안내 원인은 미확정. 설계/정책 변경 없음.

- [DONE] (DOCS/OPS) App Store Connect 접근 및 계약 업데이트 안내 기록
  - 목적: 앱 추가를 막는 현재 포털 상태를 추적한다.
  - 변경: 사용자 화면으로 Apps 접근 완료와 개발자 계약 업데이트 미완료를 구분한다.
  - 영향범위: 출시 체크리스트·작업 로그.
  - 롤백: 이번 문서 변경만 되돌린다.
  - 테스트: 사용자 제공 화면의 Apps·계약 업데이트 문구 대조, git diff --check 통과.
  - 다음: 계정 소유자의 계약 검토·동의 후 앱 추가 재시도. 계약 동의·앱 생성은 미완료 유지.

- [DONE] (DOCS/OPS) 멤버십 화면 증거 반영
  - 목적: 사용자 제공 화면의 계정 유형·Team ID·갱신일을 심사 준비 기록에 반영한다.
  - 변경: 개인 계정 확인, Team ID 일치, 갱신일 2027-08-05 기록. Active 표시와 판매자명은 화면에서 확인되지 않아 미확인 유지.
  - 영향범위: 출시 체크리스트와 작업 로그.
  - 롤백: 이번 기록 변경만 되돌린다.
  - 테스트: 사용자 제공 화면과 기록 대조, git diff --check 통과.
  - 다음: App Store Connect Apps 접근·보류 계약 확인. 설계/정책 변경 없음.

- [DONE] (DOCS/OPS) App Store 심사 준비 문서화 및 1번 로컬 점검
  - 목적: 첨부 체크리스트를 지속 갱신 가능한 심사 준비 문서로 정리한다.
  - 변경: 사용자 확인(개발자 등록·결제 완료), 로컬 iOS 설정, Apple 포털에서 추가 확인할 항목을 기록한다.
  - 영향범위: `_docs/APP_STORE_RELEASE_CHECKLIST.md`, 프로젝트 문서. 앱 동작 변경 없음.
  - 롤백: 이번 문서 추가 및 연결만 되돌린다.
  - 테스트: Bundle ID·Team·APNs·Apple entitlement·iOS 15·버전 확인, Xcode 16.2 확인, 서명 조회 0건(접근 범위 한계로 부재 단정 불가), Apple 공식 App ID/SDK 문서 확인, git diff --check 통과.
  - 결과: `_docs/APP_STORE_RELEASE_CHECKLIST.md`에 원본 1~10번과 사용자 확인 완료 2건·로컬 근거·포털 후속 절차를 기록했다. 전체 1번은 진행 중이며 완료로 처리하지 않았다.
  - 다음: 멤버십 Active·계정 종류·App Store Connect 접근·App ID 및 배포 서명 확인. 제출용 Xcode 26 이상 환경 확보. 설계/정책 변경이 없어 ADR 추가 없음.

- [DONE] (CHORE) Cafe24 폰트 작업 정리 및 Git 반영
  - 목적: 본문 Air·제목 Ssurround 최종 적용 상태를 검증하고 커밋·푸시한다.
  - 변경: 폰트 자산·라이선스, pubspec 등록, Cupertino 텍스트 및 색상 선택 화면 폰트 연결, ADR·프로젝트 문서와 실기기 설치 기록을 함께 정리한다.
  - 영향범위: 앱 타이포·폰트 번들·프로젝트 문서.
  - 롤백: 생성 커밋을 git revert한다.
  - 테스트: 관련 Dart 3개 정적 분석 진단 0건, 기존 색상 선택 위젯 테스트 16건 통과, git diff --check 통과.
  - 결과: 최종 적용 상태와 10월 14일 실기기 검증 이력을 하나의 커밋으로 정리한다. 커밋 메시지: `feat: Cafe24 기본 폰트 및 제목 폰트 적용`.

## 2026-10-14

- [DONE] (FE/OPS) Cafe24 재적용 및 릴리즈 설치
  - 목적: 사용자 요청으로 본문 Air·제목 Ssurround 구성을 재적용한다.
  - 변경: pubspec 폰트 등록, 공용 테마와 색상 선택 화면 연결 복원.
  - 영향범위: 앱 타이포·폰트 번들·지정 iPhone. Behavior change: Cafe24 표시 재활성화.
  - 롤백: ADR-0029의 적용 해제를 다시 수행한다.
  - 테스트: 변경 Dart 3개 분석 진단 0건, dart format 완료, Release 빌드 성공(24.5초), 두 폰트 번들 등록·원본 일치 확인, 지정 iPhone 설치·실행 성공, git diff --check 통과.

- [DONE] (FE/OPS) Cafe24 폰트 적용 해제 및 릴리즈 재설치
  - 목적: 사용자 요청에 따라 폰트 적용 전 표시로 복구한다.
  - 변경: 테마·색상 선택 화면·pubspec의 이번 폰트 변경을 복구하고 기존 TTF·라이선스는 비활성 보관한다.
  - 영향범위: 앱 타이포와 번들. Behavior change: Cafe24 사용 해제.
  - 롤백: ADR-0028의 폰트 등록과 테마 연결을 재적용한다.
  - 테스트: 관련 Dart 3개 정적 분석 진단 0건, 서명된 Release 빌드 성공(26.4초), Release FontManifest에 Cafe24 family 없음 확인, 지정 iPhone devicectl 설치·실행 성공, git diff --check 통과.

- [DONE] (OPS) 지정 iPhone 릴리즈 설치
  - 목적: 사용자 요청에 따라 디버그를 종료하고 릴리즈 앱을 설치한다.
  - 변경: `.env` define과 기존 iOS 빌드 경로 설정으로 release 실행.
  - 영향범위: `00008130-00124C6A1E12001C` 기기 앱, Release의 Production API/Firebase 설정.
  - 롤백: 같은 기기에 기존 debug 실행 명령으로 재설치한다.
  - 테스트: Release Xcode 빌드 성공(50.6초). 기본 iphoneos 경로가 기존 Debug 산출물을 가리켜 디버그 엔진 오류가 발생했으므로, AOT App.framework(8,631,488 bytes)가 있는 `build/ios/Release-iphoneos/Runner.app`을 devicectl로 직접 설치·실행 완료. 디버그 세션 및 조사 중단점 정리 완료.

- [DONE] (FE) 실기기 폰트 미적용 제보 조사
  - 목적: 실기기에서 기본 폰트가 적용되지 않아 보이는 원인을 확인한다.
  - 변경: 빌드 폰트 자산·화면 스타일·실행 상태를 확인했으며 사용자 적용 확인으로 추가 수정 없이 종료했다.
  - 영향범위: 폰트와 iOS 개발 실행 상태.
  - 롤백: 조사 기록만 추가했으며 생산 코드 변경은 없다.
  - 테스트: iOS 앱 FontManifest에 두 폰트 등록 확인. 사용자가 실기기 폰트 적용을 확인하여 추가 수정 없이 조사를 종료했다.

- [DONE] (FE/DOCS) Cafe24 기본 폰트 적용
  - 목적: 제공된 폰트를 앱에 포함하고 본문 Air·제목 Ssurround를 공용 테마에 적용한다.
  - 변경: TTF 등록, Cupertino 기본 텍스트 및 화면별 폰트 지정 통일.
  - 영향범위: 앱 텍스트 타이포와 폰트 번들. Behavior change: 글꼴과 글자 폭이 변경된다.
  - 파일: `assets/fonts/`, `pubspec.yaml`, `lib/core/theme/app_theme.dart`, 색상 선택 화면 2개, 프로젝트 문서.
  - 롤백: 이번 폰트 자산·pubspec·테마·화면·문서 변경을 함께 되돌린다.
  - 테스트: 변경 Dart 3개 정적 분석 진단 0건, 기존 색상 선택 위젯 테스트 16건 통과, FontManifest의 두 family와 번들 TTF 원본 일치 확인, dart format 및 git diff --check 통과. 실기기 시각 검증은 미실행.
  - 다음: 앱 완전 재시작 후 실기기에서 한글·숫자·텍스트 배율별 줄바꿈을 확인한다.

## 2026-08-29

- [DONE] (FE/DOCS) Production FCM 원인 확정 후 불필요한 진단 변경 정리
  - 목적: 실제 원인인 Production Firebase Project ID 불일치와 무관한 APNs/token lifecycle 코드·테스트·문서를 제거하고 필요한 환경 설정만 남긴다.
  - 변경: `AppDelegate`의 APNs token override, push coordinator의 token single-flight·진단 로그, 이에 종속된 단위 테스트·ADR·운영 설명을 모두 원복했다. Production Firebase는 확인된 실제 Project ID `shift-mate-b9e32`만 필수로 남기고, FCM에 불필요하며 Console에서 확인되지 않은 Storage bucket은 빈 값으로 정리했다.
  - 영향범위: Production Firebase compile-time 설정과 푸시 운영 문서. 푸시 runtime 코드의 최종 tracked diff는 없다.
  - 파일: `.env`, `_docs/{PUSH_NOTIFICATION_GUIDE,WORKLOG}.md`
  - 테스트: `flutter analyze --no-fatal-infos lib/main.dart lib/core/push test/core/push` 진단 0건, `flutter test test/core/push` 4건 통과, Production `.env`를 주입한 `flutter build ios --release --no-codesign` 성공, `git diff --check` 통과.
  - 롤백: `.env`의 Production Project ID와 푸시 가이드의 Production 식별자 설명을 이전 값으로 되돌린다.
  - 다음: CI/App Store 빌드 secret에도 Production Project ID `shift-mate-b9e32`를 반영하고 TestFlight에서 FCM token과 `/devices/current` 200을 확인한다.

## 2026-08-27

- [DONE] (CHORE) 개인 일정 삭제·프로필 흐름 개선 변경 정리 및 원격 반영
  - 목적: 작업 트리에 완료된 개인 일정 삭제, 가입 완료 상태 정렬, 프로필 입력 UX 변경을 하나의 검증 가능한 Git 이력으로 정리해 `origin/main`에 반영한다.
  - 변경: 전체 diff를 검토해 서버 `requires_profile_setup` 정본화, 프로필 설정 키보드/직종/휴대폰/문구/카드 반경 개선, 개인 일정 DELETE·스와이프·캐시 제거를 하나의 커밋 범위로 확정했다. 프로필 이미지·기기 timezone iOS plugin lockfile과 신규 캘린더 서비스 테스트도 누락 없이 포함했다.
  - 영향범위: 인증 상태·가입 화면 분기, 프로필 설정 입력 UX와 직종 서버 선배포 계약, 본인 개인 일정 삭제 API/화면/range 캐시, 관련 테스트, iOS lockfile과 프로젝트 문서. Behavior change: 가입 화면은 서버의 영속 완료 상태만 사용하고, 자유 직종과 한국 휴대폰 표시를 제공하며, 메인 캘린더의 본인 개인 일정을 왼쪽 스와이프로 삭제할 수 있다.
  - 파일: 현재 작업 트리의 인증·캘린더 생산 코드 10개, 인증·캘린더 테스트 7개, `ios/Podfile.lock`, `_docs/{PROJECT_CONTEXT,DECISIONS,PROFILE_ONBOARDING_SERVER_REQUIREMENTS,WORKLOG}.md`.
  - 테스트: 변경 Dart 17개 파일 `flutter analyze` 진단 0건, 인증 72건, 캘린더 서비스·range notifier 6건, 개인 일정 삭제 위젯 3건이 통과했다. `dart format` 변경 없음과 `git diff --check` 통과를 확인했다.
  - 롤백: 원격 반영 후 필요 시 생성 커밋을 `git revert`한다.
  - 다음: 서버의 자유 직종 1~20자 계약을 선배포한 뒤 Stage에서 가입 완료 재개·비의료 직종 저장·개인 일정 삭제 200/404/500을 실기기 검증한다.

## 2026-08-26

- [DONE] (FE/DOCS) 프로필 설정 입력 UX·중립 문구·카드 반경 개선
  - 목적: 프로필 설정 화면에서 키보드를 쉽게 닫고 직종을 직접 입력하며, 의료계에 한정되지 않은 근무 정보 문구와 한국 휴대전화 표시 형식을 제공하고 카드 하단 반경 잘림을 제거한다.
  - 변경: 화면 배경 탭과 목록 드래그로 현재 포커스를 해제한다. 직종 action sheet를 최대 20자 직접 입력 필드로 바꾸고 기존 enum은 한국어 표시명으로 초기화한다. 소속 문구를 `재직 중인 회사·기관 및 부서`로, 상단 카피를 ShiftMate 환영/일정 관리 안내로 교체했다. 휴대폰 formatter가 입력 중 10·11자리 한국 번호에 하이픈을 즉시 표시하고 `010` 또는 기존 `01[16789]` 형식을 검증하되 API에는 숫자만 보낸다. 정보 카드는 내부를 16px로 clip하고 outline을 foreground에 그려 하단 radius 잘림을 제거했다. 서버 자유 입력 선배포 조건과 ADR-0027을 문서화했다.
  - 영향범위: 프로필 설정 presentation, 가입 완료 `job_type` 입력 계약, 위젯 테스트, 가입 서버 요구·프로젝트 문서. Behavior change: 직종은 enum 선택이 아니라 선택 자유 문자열이 되며 화면의 휴대전화 번호는 하이픈 형식으로 표시된다. 현재 서버 enum 제약이 유지된 환경에서는 자유 직종이 거절되므로 서버 migration/service/OpenAPI를 Flutter보다 먼저 배포해야 한다.
  - 롤백: 이번 프로필 설정 UI·formatter·테스트·문서 변경을 함께 되돌린다.
  - 파일: `lib/features/auth/presentation/pages/profile_setup_page.dart`, `test/features/auth/presentation/pages/profile_setup_page_test.dart`, `_docs/{PROJECT_CONTEXT,DECISIONS,PROFILE_ONBOARDING_SERVER_REQUIREMENTS,WORKLOG}.md`.
  - 테스트: 프로필 formatter/위젯 10건과 인증 전체 72건이 통과했다. 인증 코드·테스트 정적 분석 진단 0건, `dart format`, `git diff --check`를 통과했다.
  - 다음: 서버의 `ck_users_job_type`, TypeScript union, service/route/OpenAPI enum을 1~20자 자유 문자열로 먼저 전환한 뒤 Stage에서 비의료 직종 가입·재조회와 iOS/Android 키보드·카드 모서리를 실기기 확인한다.

- [DONE] (FE) 개인 일정 삭제 API 연결 및 근무 일정과 동일한 삭제 UX 적용
  - 목적: 서버의 개인 일정 삭제 계약을 Flutter에 연결하고, 캘린더에서 개인 일정을 근무 일정과 동일한 스와이프 흐름으로 삭제할 수 있게 한다.
  - 변경: `CalendarService.deleteEvent()`가 body 없이 `DELETE /api/v1/events/{event_id}`를 호출하고 성공 응답 ID를 반환하도록 연결했다. 메인 캘린더 개인 일정에 근무 일정과 같은 chevron·왼쪽 스와이프·둥근 삭제 배경을 적용하고 `confirmDismiss`에서 API를 호출한다. `200`은 응답 ID를 다일 일정의 모든 날짜 캐시에서 제거하며, `404 EVENT_NOT_FOUND`는 요청 ID를 제거하고 이미 삭제 안내를 표시한다. `400 INVALID_EVENT_ID`는 안내 후 현재 범위를 재조회하고, `500`·네트워크 오류는 항목을 유지한다. 같은 ID의 요청 중복 실행을 차단하고 친구·그룹 읽기 전용 UI는 유지했다. ADR-0026에 삭제 상태 정책을 기록했다.
  - 영향범위: 개인 일정 삭제 API, 메인 캘린더 선택일 개인 일정 스와이프 UI, range 캐시 mutation, 관련 테스트·프로젝트 문서. Behavior change: 본인 개인 일정은 근무 일정과 동일하게 왼쪽 스와이프로 서버 삭제할 수 있다. 친구·그룹의 타인 일정은 계속 삭제할 수 없다.
  - 롤백: 이번 작업의 개인 일정 삭제 연결 및 UI·테스트·문서 변경을 함께 되돌린다.
  - 파일: `lib/features/calendar/{data/services/calendar_service.dart,application/calendar_range_notifier.dart,presentation/pages/calendar_page.dart,presentation/widgets/calendar_schedule_card.dart}`, 캘린더 서비스·notifier·페이지 테스트, `_docs/{PROJECT_CONTEXT,DECISIONS,WORKLOG}.md`.
  - 테스트: 신규 서비스 2건, notifier 4건, 개인 일정 삭제 위젯 3건이 통과했다. 캘린더 페이지 전체에서는 신규 삭제 테스트를 포함한 12건이 통과했고 변경 범위 밖 기존 `750px 경계 화면은 기존 월 보기를 유지한다`의 RenderFlex 11px overflow 1건만 기존과 동일하게 실패했다. 변경 대상 정적 분석 진단 0건, `dart format`, `git diff --check`를 통과했다.
  - 다음: Stage에서 본인 일정 삭제 `200`, 같은 ID 재삭제 `404`, 네트워크·500 재시도, 삭제 후 개인·친구·그룹 캘린더 재조회 제외를 실제 계정으로 확인한다.

## 2026-08-22

- [DONE] (FE) 서버 가입 완료 정본 기반 인증·프로필 설정 흐름 정렬
  - 목적: 서버의 `requires_profile_setup`을 가입 화면 분기 정본으로 사용하고, 프로필 완료 JSON/multipart 계약 및 오류 처리를 Flutter에서 일관되게 적용한다.
  - 변경: OAuth 인증 응답과 `AuthState`의 화면 분기 필드를 `requires_profile_setup`으로 통일했다. 로그인 페이지·앱 재시작 복구·푸시 pending 이동은 이 영속 완료 상태만 사용하며, 서버의 `is_new_user`는 더 이상 Flutter 화면 상태나 분기 조건에 사용하지 않는다. 기존 프로필 설정의 JSON/multipart 업로드·기기 timezone 전송·구조화 오류 전달 구현은 서버 ADR-0033/OpenAPI와 일치함을 확인하고 회귀 테스트를 갱신했다.
  - 영향범위: OAuth 로그인 후 화면 분기, 앱 재시작 인증 복구, 가입 프로필 완료 요청과 오류 UX.
  - 롤백: 이번 변경 커밋을 revert해 기존 인증 상태 필드와 화면 분기 로직으로 복구한다.
  - 파일: `lib/{main.dart,features/auth/domain/entities/user.dart,features/auth/presentation/{providers/auth_provider.dart,pages/login_page.dart}}`, 생성 `user.freezed.dart`, 인증 테스트와 `_docs/{PROJECT_CONTEXT,DECISIONS,WORKLOG}.md`.
  - 테스트: 인증 datasource·repository·provider·로그인/프로필 설정 위젯 테스트 전체 42건 통과, `flutter analyze lib/features/auth lib/main.dart` 진단 0건, `dart format`, `git diff --check` 통과.
  - 다음: Stage 서버 배포 뒤 JSON·multipart 프로필 완료와 앱 종료 후 가입 재개 E2E를 확인한다.

## 2026-08-20

- [DONE] (CHORE) 회원가입 프로필 이미지·타임존 UI 변경 커밋 및 푸시
  - 목적: 2026-08-19 구현·문서·테스트 변경을 검증 가능한 하나의 Git 이력으로 정리해 원격 `main`에 반영한다.
  - 변경: 2026-08-19의 프로필 이미지 선택·미리보기·multipart 전송, 기기 timezone 자동 수집, 패키지·iOS 권한, 테스트·서버 요구·ADR 문서를 하나의 커밋으로 정리해 `origin/main`에 푸시한다.
  - 영향범위: 회원가입 프로필 이미지 선택, 자동 타임존 수집, multipart 계약, 관련 테스트·문서의 Git 이력.
  - 파일: 2026-08-19 작업 항목에 기록된 변경 파일 전체와 `_docs/WORKLOG.md`.
  - 테스트: 인증 영역 `flutter analyze --no-fatal-infos` 진단 0건, 인증 테스트 67건, `plutil -lint ios/Runner/Info.plist`, `git diff --check`가 통과했다. 전체 테스트의 변경 범위 밖 기존 캘린더 750px 경계 overflow 1건은 2026-08-19 항목에 별도 기록했다.
  - 롤백: 원격 반영 후 필요 시 해당 커밋을 `git revert`한다.
  - 다음: 서버 multipart/object storage 선배포 후 Stage E2E를 진행한다.

## 2026-08-19

- [DONE] (FE/DOCS) 회원가입 프로필 이미지 설정 및 타임존 입력 제거
  - 목적: 신규 사용자가 가입 과정에서 프로필 이미지를 설정할 수 있게 하고, 직접 선택할 필요가 없는 타임존 입력은 화면에서 제거한다.
  - 변경: 가입 화면 아바타에 사진 보관함 선택 버튼과 즉시 미리보기를 추가했다. 선택 시 최대 1024x1024·품질 85를 요청하고 최종 5MB 제한을 적용하며, 이미지가 있으면 `profile_image` multipart part로, 없으면 기존 JSON으로 가입 완료 API를 호출한다. 타임존 행·picker는 제거하고 `flutter_timezone`이 조회한 기기 IANA identifier를 시스템 필드로 전송하되 실패 시 기존 사용자 값/앱 기본값을 유지한다. `ProfileImageUpload` 값 객체, `image_picker`·`flutter_timezone`, iOS 사진 권한 설명을 추가했다. 현재 서버에 업로드 parser/storage가 없음을 코드로 확인해 object storage·검증·오류·배포 요구를 서버 문서에 보완하고 ADR-0025를 기록했다.
  - 영향범위: 회원가입 프로필 설정 UI, 인증 presentation/repository/datasource의 가입 완료 계약, iOS 사진 보관함 권한, Flutter 의존성, 관련 테스트와 서버 요구·프로젝트 문서. Behavior change: 사용자는 타임존을 직접 고르지 않고 아바타에서 선택 프로필 이미지를 가입 요청에 첨부할 수 있다. 이미지 미선택 JSON 경로는 유지된다.
  - 파일: `lib/features/auth/presentation/pages/profile_setup_page.dart`, `presentation/providers/auth_provider.dart`, `data/repositories/auth_repository_impl.dart`, `data/datasources/auth_remote_datasource.dart`, `domain/entities/profile_image_upload.dart`, 인증 테스트 5개, `pubspec.yaml`, `pubspec.lock`, `ios/Runner/Info.plist`, `_docs/PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 인증 영역 67건과 프로필 화면 5건이 통과했다. JSON/multipart 분기, 파일명·MIME·텍스트 field, 이미지 선택 미리보기, 타임존 행 미노출과 기기 timezone 전달을 검증했다. 인증 코드·테스트 정적 분석 진단 0건, `dart format`, `plutil`, `git diff --check`를 통과했다. 전체 테스트에서는 이번 변경의 병렬 가입 테스트 2건을 timezone loader 주입으로 안정화했으며, 변경 범위 밖의 기존 `calendar_page_test.dart` 750px 경계 RenderFlex 11px overflow 1건만 별도 재현됐다.
  - 롤백: 이미지 선택 값 객체·multipart 분기·두 패키지·iOS 권한과 관련 UI/테스트/문서를 제거하고 타임존 선택 행·picker 및 기존 완료 요청 계약을 복원한다.
  - 다음: 서버 담당자가 가입 완료 endpoint의 multipart parser와 object storage 업로드를 Stage에 선배포한 뒤 Android/iOS 권한 허용·거절, 취소, 5MB/MIME 오류, 재시도와 친구·그룹 화면의 CDN 이미지 표시를 E2E 검증한다.

## 2026-08-17

- [DONE] (FE/DOCS) 가입 프로필 필수·선택 UI 및 서버 계약 정립
  - 목적: 신규 사용자가 필수 기본 정보와 선택 근무 정보를 명확히 구분해 입력하고, 앱을 종료했다가 다시 로그인해도 미완료 가입 흐름을 정확히 재개할 수 있게 한다. 현재 서버에 없는 근무 정보 저장·가입 완료 계약은 백엔드가 구현 가능한 요구 문서로 확정한다.
  - 변경: `ProfileSetupPage`를 컴팩트한 프로필 안내, `필수` 기본 정보 카드, `선택` 근무 정보 카드, 개인정보 안내와 하단 단일 CTA로 재구성했다. 이름·휴대폰·타임존만 가입 완료를 막고 직종·소속은 비워도 저장한다. 휴대폰 숫자 입력/10~11자리 검증, timezone picker, 직종 action sheet, 로딩·구조화 오류 표시를 연결했다. User·Repository·DataSource·Notifier에 `phone`, `job_type`, `workplace`, `requires_profile_setup`과 idempotent `POST /auth/profile/complete` 계약을 추가했다. 앱 재시작 시 서버 완료 상태를 우선하고 구버전 서버는 phone 유무로 fallback한다. 계정 전환 시 근무 유형 원본/표시 상태만 무효화하고 파생 Provider가 불필요한 API를 시작하지 않게 정리했다. 서버 요청서에 현재 구현 확인 결과, DB migration/backfill, Express 계층, validation/error/privacy/OpenAPI/test, 서버 선배포·롤백을 확정하고 ADR-0024를 추가했다. 미사용 `riverpod_generator`를 제거하고 `build.yaml`로 실제 Freezed/JSON 입력만 제한해 생성 코드를 재동기화했다.
  - 영향범위: Flutter 프로필 설정 화면, 인증 User/Repository/DataSource/Provider 계약, 인증 테스트, 가입 완료 API·DB·배포 요구 문서와 프로젝트 문서. Behavior change: 기본 정보가 유효하면 근무 정보를 입력하지 않고도 완료할 수 있고, 완료 여부는 OAuth 생성 순간이 아닌 서버 영속 상태로 복원된다. 기존 캘린더·공개 범위 규칙은 변경하지 않는다.
  - 파일: `lib/features/auth/**`, `lib/core/constants/api_constants.dart`, `test/features/auth/**`, `pubspec.yaml`, `pubspec.lock`, `build.yaml`, `_docs/PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 롤백: 신규 가입 완료 endpoint 계약과 User 필드, 프로필 설정 UI·테스트·문서 변경을 함께 복원한다.
  - 테스트: 인증 전체 65건이 통과했고, 390x844 프로필 화면의 필수·선택 위계/단일 CTA/필수 검증/선택값 생략·전달, datasource method/path/body/응답·구조화 오류, 재실행 미완료 복원과 완료 상태 해제를 검증했다. 변경 대상 9개 파일 analyzer 진단 0건, `dart format`, Freezed/json_serializable 생성(10 outputs), `git diff --check`, 문서 code fence 균형을 통과했다. Stage Kakao sentinel을 주입한 전체 테스트는 180 pass·1 skip이며 변경 범위 밖의 기존 `calendar_page_test.dart` 750px 경계 RenderFlex 11px overflow 1건만 기존과 같이 실패했다. sentinel 없는 기본 전체 테스트 명령은 카카오 키 필수 테스트도 함께 실패하므로 전체 검증에는 `--dart-define=KAKAO_NATIVE_APP_KEY_STAGE=...`가 필요하다.
  - 다음: 서버 담당자가 `_docs/PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md` 순서대로 migration과 완료 endpoint를 Stage에 선배포한 뒤 카카오·네이버·Google·Apple 신규/미완료 사용자 E2E를 통과하고 Flutter Production을 배포한다.

- [DONE] (FE/DOCS) 카카오 Native App Key Stage/Production 빌드 분리
  - 목적: Debug(Stage)와 Profile/Release(Production)가 서로 다른 Kakao Native App Key와 callback URL Scheme을 사용하도록 Dart·Android·iOS 빌드 설정을 일치시킨다.
  - 변경: 기존 Production `KAKAO_NATIVE_APP_KEY`를 보존하고 Stage용 `KAKAO_NATIVE_APP_KEY_STAGE`를 추가했다. `AppConstants`는 Debug에서 Stage, Profile/Release에서 Production 값을 선택하고 `main.dart`는 현재 빌드에 필요한 변수명을 포함해 누락 오류를 낸다. Android는 debug build type의 Manifest placeholder만 Stage로 덮어쓰며 Profile/Release 기본값은 Production으로 유지한다. iOS Debug xcconfig는 Stage 값을 공용 `KAKAO_NATIVE_APP_KEY`로 매핑하고 Profile/Release는 Production 값을 사용한다. 서버 요청 문서는 환경별 App ID/Admin Key 계약으로 바꾸고 ADR-0023에 빌드 환경 경계를 기록했다.
  - 영향범위: Flutter Kakao SDK 초기화 키, Android/iOS Kakao callback URL Scheme, 로컬/CI 환경변수, Stage/Production 서버 App ID 검증과 인증 문서. Behavior change: Debug는 Stage Kakao 앱에서 토큰을 발급받고 Profile/Release는 Production Kakao 앱을 사용한다. application ID/Bundle ID는 같아 두 앱을 동시에 설치하지 않는다.
  - 파일: `lib/core/constants/app_constants.dart`, `lib/main.dart`, `android/app/build.gradle.kts`, `ios/Flutter/Debug.xcconfig`, `ios/Flutter/Profile.xcconfig`, `ios/Flutter/Release.xcconfig`, `test/core/constants/app_constants_test.dart`, `_docs/KAKAO_LOGIN_SERVER_REQUEST.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: Stage sentinel Dart define을 주입한 상수 선택 테스트와 기존 카카오 datasource/repository 회귀를 포함한 20건이 통과했다. 변경 Dart 3개 파일 analyzer 진단 0건, Android Debug/Release Manifest 병합 Gradle 80개 task 성공 및 Stage/Production scheme 선택, iOS Debug xcconfig Stage build setting 매핑, plist 문법, `dart format`, 문서 code fence 균형, `git diff --check`를 검증했다. Android Gradle에는 기존 Kotlin `jvmTarget` deprecation과 외부 플러그인 Manifest namespace 경고만 남아 있다.
  - 롤백: `AppConstants`를 단일 `KAKAO_NATIVE_APP_KEY`로 되돌리고 Android debug override와 iOS Debug Stage 매핑, 신규 상수 테스트, ADR-0023 및 환경별 문서 기록을 함께 제거한다.
  - 다음: 로컬 `.env`, `android/secrets.properties`, `ios/Flutter/Secrets.xcconfig`에 같은 Stage Native App Key를 `KAKAO_NATIVE_APP_KEY_STAGE`로 추가한다. Stage 서버에는 Stage `KAKAO_APP_ID`와 worker Admin Key를 주입하고 Android debug key hash 및 iOS Bundle ID를 Stage Kakao 앱에 등록한 뒤 실기기 로그인을 검증한다.

## 2026-08-16

- [DONE] (FE/DOCS) 카카오 네이티브 SDK 설정 명확화 및 서버 구현 요청서 작성
  - 목적: Flutter의 실제 카카오 SDK 토큰 로그인과 Dart/네이티브 키 주입 경계를 코드·테스트로 고정하고, Express가 운영에서 적용해야 할 토큰 앱 소속 검증·레거시 Web 경로 정리·환경변수·테스트 계약을 전달한다.
  - 변경: `main.dart`의 Debug 전용 assert를 모든 빌드에서 동작하는 `StateError` 검증으로 바꾸고 `.env` Dart define과 Android/iOS 네이티브 build setting에 같은 Native App Key를 각각 주입해야 한다는 오류 안내·Gradle 주석을 명확히 했다. 카카오 SDK Access Token이 `POST /auth/kakao/token`의 정확한 body로 전달되고 서버 성공 뒤 ShiftMate JWT가 저장되는 datasource/repository 테스트를 추가했다. token endpoint 오류는 공용 `handleApiError()`로 변환해 `KAKAO_TOKEN_APP_MISMATCH`의 코드·메시지·request ID를 보존한다. ADR-0022에 SDK token 단일 운영과 서버 App ID 검증 결정을 기록하고, `_docs/KAKAO_LOGIN_SERVER_REQUEST.md`에 프론트 완료 범위, 서버 `access_token_info.app_id` 검증, Web route·환경변수 제거, Admin Key worker, OpenAPI·테스트·배포·롤백 인수 조건을 작성했다.
  - 영향범위: Flutter 카카오 초기화 실패 정책, Android 빌드 설정 안내, 카카오 token endpoint 오류 타입, 인증 datasource/repository 회귀 테스트, 프로젝트 인증 정책과 서버 전달 문서. Behavior change: Release에서도 Dart define Native App Key가 없으면 빈 키로 실행하지 않고 시작 즉시 실패하며, 구조화된 카카오 서버 오류가 일반 문자열 대신 `ApiException`으로 보존된다. 서버 코드는 변경하지 않는다.
  - 파일: `lib/main.dart`, `lib/features/auth/data/datasources/auth_remote_datasource.dart`, `android/app/build.gradle.kts`, `test/features/auth/data/datasources/auth_remote_datasource_test.dart`, `test/features/auth/data/repositories/auth_repository_impl_test.dart`, `_docs/KAKAO_LOGIN_SERVER_REQUEST.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 인증 전체 테스트 56건 통과. 신규 카카오 endpoint/method/body/응답 파싱, SDK token 전달 후 JWT 저장, App ID 불일치 오류 코드·메시지·request ID 보존을 검증했다. 변경 Dart 코드·테스트 4개 파일의 `flutter analyze --no-fatal-infos`는 진단 0건이고 `dart format`, 문서 code fence 28개 균형, 서버 참조 파일 존재 확인, `git diff --check`를 통과했다.
  - 롤백: `main.dart`를 Debug assert 기반 키 검증으로 복원하고 카카오 Dio 오류를 문자열 `Exception`으로 되돌린 뒤 신규 테스트·ADR-0022·서버 요청서와 프로젝트 컨텍스트 기록을 함께 제거한다. 서버가 구조화 오류 계약을 배포한 뒤에는 오류 변환을 먼저 서버 계약과 분리한다.
  - 다음: 서버 담당자가 `_docs/KAKAO_LOGIN_SERVER_REQUEST.md` 순서대로 `KAKAO_APP_ID` 검증과 SDK token 단일 endpoint를 구현하고 Stage iOS/Android 실기기 로그인·탈퇴 E2E를 통과한다. Production Android keystore 확정 후 실제 Release key hash를 Kakao Native App Key에 등록한다.

## 2026-08-14

- [DONE] (FE) 설정 화면 회원 탈퇴 버튼 및 비동기 탈퇴 API 연동
  - 목적: 사용자가 설정 화면에서 복구 불가 영향을 확인한 뒤 회원 탈퇴를 요청하고, 서버 접수 즉시 로컬 인증·계정 캐시를 정리해 로그인 화면으로 이동한다.
  - 변경: 로그아웃 아래에 별도 `회원 탈퇴` 액션을 추가하고 일정·근무표·친구·그룹 정보 삭제와 복구 불가를 최종 확인하게 했다. `DELETE /auth/account`에 boolean `confirmation=true`를 보내고 해당 요청은 글로벌 access token 자동 refresh에서 제외했다. Google 현재 계정은 SDK `disconnect()`, Naver 현재 token은 `logOutAndDeleteToken()`으로 서버 요청 전 연결을 해제한다. `202`는 로컬 JWT·소셜 세션·계정 Provider 캐시를 정리하고 로그인으로 이동하며, `401`·`ACCOUNT_DELETION_IN_PROGRESS`도 로컬 세션을 종료한다. `REAUTHENTICATION_REQUIRED`는 설정 화면을 유지하고 재로그인·재확인을 안내하며, 기타 미접수 오류는 인증 상태를 유지한다. 서버 `request_id`를 `ApiException`에 보존해 실패 로그에 남긴다.
  - 영향범위: Flutter 인증 datasource/repository/notifier, Google·Naver SDK 경계, 설정 화면, 인증 단위·위젯 테스트와 프로젝트 문서. DB 스키마와 서버 구현은 변경하지 않는다.
  - 파일: `lib/core/constants/api_constants.dart`, `lib/core/network/api_client.dart`, `api_error_handler.dart`, `api_exception.dart`, `lib/features/auth/data/datasources/auth_remote_datasource.dart`, `data/repositories/auth_repository_impl.dart`, `data/services/google_login_service.dart`, `naver_login_service.dart`, `presentation/providers/auth_provider.dart`, `presentation/pages/settings_page.dart`, `test/features/auth/**`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 롤백: 탈퇴 endpoint·SDK 연결 해제·Notifier 분기·설정 버튼과 관련 테스트·ADR-0021·프로젝트 컨텍스트를 함께 제거한다. `ApiException.request_id`와 `skip_auth_refresh`를 다른 흐름이 사용하게 된 후에는 해당 의존성을 먼저 분리한다.
  - 테스트: 전체 인증 테스트 53건이 통과했다. 탈퇴 요청 method/path/boolean body·refresh 제외, `request_id` 보존, Google/Naver 연결 해제, 202 로컬 정리, 403 재인증 상태 유지, 409 세션 정리, 설정 버튼·복구 불가 확인·로그인 전환을 검증했다. 변경 파일 17개 정적 분석은 진단 0건, `dart format`과 `git diff --check`는 통과했다. 전체 테스트는 167 pass·1 skip이고 변경 범위 밖의 기존 `calendar_page_test.dart`의 `750px 경계 화면은 기존 월 보기를 유지한다` 1건만 기존과 같은 RenderFlex 11px overflow로 실패했다. 전체 analyze의 기존 38건(프로필 picker 미사용 warning 1건, 프로젝트 snake_case/deprecated info 37건)은 변경 범위 밖이며 변경 대상 분석에는 진단이 없다.
  - 다음: Stage에서 카카오·네이버·Google·Apple 계정별 실기기 탈퇴, 10분 경과 재인증, 202 후 일반 API 차단과 백그라운드 삭제 완료를 서버 로그·DB·provider 콘솔에서 확인한다.

## 2026-08-13

- [DONE] (DESIGN) 프로필 설정 필수·선택 정보 위계 개선
  - 목적: 신규 사용자가 반드시 입력해야 하는 기본 정보와 건너뛸 수 있는 근무 정보를 즉시 구분하고, 선택 정보 때문에 가입 완료가 막힌다고 오해하지 않게 한다.
  - 변경: 상단의 중복 완료 액션과 큰 장식 영역을 제거하고 프로필 안내를 컴팩트하게 재구성했다. 기본 정보에는 `필수` 배지·필수 표시·이메일 인증 상태를, 근무 정보에는 `선택` 배지와 `지금 입력하지 않아도 괜찮아요` 상시 안내를 추가했다. 선택 필드 초기값은 비워 두고 하단의 단일 `저장하고 시작하기` 버튼은 이름·휴대폰만 검증하도록 구성했다. focus/error 상태, 44px 이상 터치 영역, 작은 화면 대응과 하단 안전영역도 반영했다. 디자인 규칙과 현재 Flutter/API 계약에 없는 시안 필드의 구현 전제도 문서화했다.
  - 영향범위: `design/signup input personal data`의 프로필 설정 HTML 시안·디자인 규칙과 프로젝트 문서. Behavior change: 근무 정보가 비어 있어도 완료할 수 있고, 완료 액션은 하단 버튼 하나만 표시된다. Flutter/API/DB 동작은 변경하지 않는다.
  - 파일: `../design/signup input personal data/code.html`, `../design/signup input personal data/DESIGN.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 롤백: HTML 시안의 필수·선택 위계, 단일 하단 액션, 검증 스크립트와 디자인/프로젝트 문서 항목을 이전 버전으로 복원한다.
  - 테스트: inline JavaScript 구문, 필수·선택 배지 및 선택 안내 존재, 완료 CTA 단일 노출, 선택 근무 필드의 `required` 미사용을 정적으로 검증했다. `git diff --check`를 통과했다. 연결 가능한 미리보기 브라우저가 없어 실제 렌더 캡처는 수행하지 않았으며, 검증되지 않은 `screen.png`는 덮어쓰지 않았다.

- [DONE] (FIX) 로그인 콘텐츠 수평 중앙 정렬을 레이아웃 제약으로 통일
  - 목적: 로그인 헤더와 소셜 버튼 그룹을 고정 px 이동 없이 화면의 좌우 중앙에 배치한다.
  - 변경: 페이지 콘텐츠를 `Align(alignment: Alignment.center)`와 가용 가로 너비를 채우는 `SizedBox`에 배치했다. 세로 `Column`에 `CrossAxisAlignment.center`를 명시하고, 소셜 버튼 `Wrap`도 전체 너비에서 `WrapAlignment.center`를 적용해 px 기반 좌우 보정 없이 중앙을 계산하게 했다. 3개·4개 버튼 구성의 실제 그룹 중심이 페이지 중심과 일치하는 회귀 검증을 추가했다.
  - 영향범위: 로그인 콘텐츠와 소셜 버튼 그룹의 수평 정렬, 로그인 위젯 테스트, 프로젝트 문서. Behavior change: 수평 위치는 고정 이동값이 아니라 부모의 실제 가용 너비를 기준으로 결정된다. OAuth/API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/auth/presentation/pages/login_page.dart`, `test/features/auth/presentation/pages/login_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 롤백: 수평 전체 너비와 중앙 정렬 제약, 회귀 테스트와 문서 기록을 이전 구조로 복원한다.
  - 테스트: 로그인 페이지 위젯 테스트 7건 통과. 3개·4개 버튼 그룹 중심과 페이지 중심 일치, 좁은 화면 자동 줄바꿈, 작은 높이 스크롤, 로딩 상태를 검증했다. 변경 Dart 파일 `flutter analyze --no-fatal-infos` 진단 0건, `dart format`과 `git diff --check` 통과.

## 2026-08-11

- [DONE] (FIX) 로그인 화면 세로 간격 복원
  - 목적: Google 버튼 추가 후 헤더와 소셜 로그인 영역 사이가 과도하게 벌어져 화면이 상·하로 분리되어 보이는 문제를 수정한다.
  - 변경: 헤더 위·아래의 flex `Spacer`를 제거하고 앱 아이콘·설명·소셜 버튼·로딩·약관을 하나의 중앙 콘텐츠 그룹으로 묶었다. 헤더 설명과 소셜 버튼 사이는 64px 고정 간격으로 배치하고, `SingleChildScrollView`와 viewport 최소 높이 제약으로 작은 화면에서는 전체 콘텐츠를 스크롤할 수 있게 했다. 390x844 세로 좌표와 390x360 overflow 회귀 테스트를 추가했다.
  - 영향범위: 로그인 화면 세로 배치, 로그인 위젯 테스트와 프로젝트 컨텍스트. Behavior change: 화면 높이에 따라 234px까지 늘어나던 헤더-버튼 간격이 64px로 고정되고, 작은 높이에서는 RenderFlex overflow 대신 스크롤한다. OAuth/API/DB 계약과 소셜 버튼 순서·크기는 변경하지 않는다.
  - 파일: `lib/features/auth/presentation/pages/login_page.dart`, `test/features/auth/presentation/pages/login_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 롤백: 로그인 페이지의 중앙 그룹/스크롤 배치와 회귀 테스트·문서 항목을 이전 `Spacer` 배치로 되돌린다.
  - 테스트:
    - 수정 전 390x844에서 헤더-버튼 간격 234px(기대 64px), 390x360에서 하단 RenderFlex 16px overflow를 회귀 테스트로 재현했다.
    - 수정 후 로그인 페이지 위젯 테스트 7건과 전체 인증 테스트 39건 통과.
    - 변경 Dart 파일 `flutter analyze --no-fatal-infos`: 진단 0건. `dart format`과 `git diff --check` 통과.
  - 다음: iOS/Android 실기기에서 Safe Area가 있는 화면과 접근성 글자 크기를 포함해 중앙 그룹 위치와 작은 높이 스크롤을 확인한다.

- [DONE] (FE/DOCS) Google 소셜 로그인 구현 및 서버 요구문서 작성
  - 목적: Google ID Token을 ShiftMate 서버에서 검증하는 로그인 흐름을 Flutter 인증 계층과 로그인 화면에 추가하고, 후속 Express 구현에 필요한 확정 계약을 문서화한다.
  - 변경:
    - `google_sign_in` 7.2.0을 고정하고 앱 전역 SDK singleton을 한 번만 초기화하는 `GoogleSignInSdk`/`GoogleLoginService` 경계를 추가했다. Android는 Web client ID를 `serverClientId`로, iOS는 iOS client ID와 Web client ID를 전달하며 `authenticate()` 결과의 ID Token만 반환한다.
    - ID Token 누락, 취소, 지원/설정 오류를 사용자용 예외로 구분했다. 서버 토큰 교환 실패와 앱 로그아웃은 Google 로컬 세션을 best-effort로 정리하고, ShiftMate JWT는 서버 성공 후에만 저장한다.
    - `/auth/google/token` public endpoint, `{ "id_token": "..." }` datasource, Repository/Notifier 흐름과 nullable `User.google_id`를 추가했다. 서버 정수 `expires_at`은 실제 Express 계약인 Unix epoch milliseconds로 수정했다.
    - 로그인 화면을 64x64 아이콘·20px 간격의 반응형 `Wrap`으로 바꿨다. Google은 항상 노출하고 Apple 플래그는 유지하며, 카카오→네이버→Google→Apple 순서, 좁은 화면 줄바꿈, 접근성 레이블과 공용 로딩 비활성·반투명을 적용했다.
    - iOS `Info.plist`에 `GOOGLE_REVERSED_CLIENT_ID` build setting을 사용하는 URL scheme을 추가하고 CocoaPods를 동기화했다. Android는 `google-services.json` 없이 빌드한다.
    - 실제 Express route/controller/service/User/environment/OpenAPI/migration 구조를 기준으로 ID Token 검증, 이메일 자동 연결 금지, transaction, 오류, 환경변수, Google Cloud, Stage/Center 배포·롤백을 `_docs/GOOGLE_SIGN_IN_SERVER_GUIDE.md`에 결정 완료 상태로 작성했다. 서버 코드는 수정하지 않았다.
    - Google 인증 흐름·환경·파일 역할을 프로젝트 컨텍스트에, ID Token 서버 검증과 이메일 자동 연결 금지 정책을 ADR-0020에 반영했다.
  - 영향범위: Flutter 인증 SDK/data/repository/state/User 모델·로그인 UI, iOS URL scheme/Pod, 패키지 lockfile, 인증 테스트와 프로젝트 문서. Behavior change: Google 버튼이 모든 로그인 화면에 나타나며 정수 로그인 만료 시각을 millisecond로 해석한다. 기존 카카오·네이버와 Apple 기능 플래그 정책은 유지한다.
  - 파일: `lib/features/auth/data/services/google_login_service.dart`, 인증 datasource/repository/entity/provider/page 및 생성 코드, `lib/core/constants/api_constants.dart`, `app_constants.dart`, `lib/core/network/api_client.dart`, `ios/Runner/Info.plist`, `ios/Flutter/*.xcconfig`, `ios/Podfile.lock`, `pubspec.yaml`, `pubspec.lock`, `assets/icons/google.png`, `test/features/auth/**`, `_docs/GOOGLE_SIGN_IN_SERVER_GUIDE.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트:
    - 전체 인증 service/datasource/repository/provider/login UI 테스트 37건 통과. 초기화 1회, 플랫폼별 client ID, ID Token 반환·누락, 취소·설정 오류, 로그아웃, endpoint/body, 서버 성공 후 JWT 저장, 실패 시 Google 정리, `is_new_user`, 로그인 응답과 `AuthToken`의 millisecond 파싱, 176x176 에셋/64x64 버튼, 390px 한 줄·좁은 화면 줄바꿈, 접근성과 로딩 비활성화를 검증했다.
    - 변경 생산 코드·인증 테스트 `flutter analyze --no-fatal-infos`: 진단 0건.
    - 형식 검증용 Google client ID를 주입한 Android debug APK와 iOS simulator debug Runner 빌드 통과. 빌드된 iOS 앱의 Google URL scheme이 주입한 reversed client ID로 해석된 것도 확인했다.
    - `pod install --repo-update` 통과, `Info.plist` lint 통과, Google 아이콘 176x176 RGBA 확인, 서버 가이드 JSON 예시 3개 파싱·code fence 14개 균형·참조 서버 파일 존재 확인, `dart format`과 `git diff --check` 통과.
    - 전체 Flutter 테스트는 151 pass, 1 skip이며 기존 `calendar_page_test.dart`의 `750px 경계 화면은 기존 월 보기를 유지한다` 1건만 기존과 동일한 RenderFlex 11px overflow로 실패했다. 전체 analyze 38건(기존 profile picker 미사용 warning 1건과 naming/deprecated info 37건)은 Google 변경 파일 밖이며 변경 대상 분석에는 진단이 없다.
  - 롤백: Google service/API/Repository/Provider/User 필드/버튼, iOS URL scheme, 패키지·Pod, 테스트와 Google 문서/ADR 항목을 함께 되돌린다. 실제 서버 배포 뒤 장애가 나면 서버 `GOOGLE_AUTH_ENABLED=false`를 먼저 적용하고 nullable `google_id` 데이터가 존재하면 DB 컬럼은 보존한다.
  - 다음: `_docs/GOOGLE_SIGN_IN_SERVER_GUIDE.md` 순서대로 Express `google-auth-library`, route/service/User/OpenAPI와 guarded migration을 구현한다. Google Cloud Web/iOS/Android client와 빌드별 SHA-1·SHA-256, 실제 secret을 준비해 Stage iOS/Android 실기기 E2E를 통과한 뒤 Center 서버를 먼저 활성화하고 앱을 배포한다.

## 2026-08-06

- [DONE] (FE) 소셜 로그인 원형 아이콘 표시 크기 확대
  - 목적: 실제 로그인 화면에서 64x64 터치 영역 안의 44x44 이미지가 작게 보이는 문제를 해결한다.
  - 변경: 카카오·네이버·Apple 원형 이미지를 터치 영역과 동일한 64x64로 확대해 버튼 내부의 10px 사방 여백을 제거했다. 기존 중앙 가로 배열, 버튼 중심 간 84px 거리(64px 버튼 + 20px 간격), 로딩 비활성화와 인증 handler를 유지했다.
  - 영향범위: 로그인 화면 소셜 아이콘의 시각 크기, 위젯 테스트와 프로젝트 컨텍스트. Behavior change: 세 원형 아이콘의 지름이 44px에서 64px로 확대된다. OAuth/API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/auth/presentation/pages/login_page.dart`, `test/features/auth/presentation/pages/login_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 로그인 위젯 테스트에서 세 버튼과 세 이미지가 모두 64x64인지, 동일 Y 좌표·중심 간 84px 거리·접근성 레이블과 Apple 기능 플래그 노출을 검증했다. 전체 인증 테스트 21건 통과, 변경 코드·테스트 `flutter analyze --no-fatal-infos` 진단 0건, `dart format` 통과.
  - 롤백: 원형 이미지 크기를 44x44로 복원하고 테스트·문서 기대값을 되돌린다.
  - 다음: Stage iOS/Android 실제 기기에서 확대된 아이콘의 선명도와 눌림·로딩 피드백을 확인한다.

- [DONE] (FE) 소셜 로그인 버튼을 원형 아이콘 가로 배열로 변경
  - 목적: 새로 추가된 카카오·네이버·Apple 원형 이미지를 로그인 화면에서 일관된 크기의 가로형 소셜 로그인 버튼으로 사용한다.
  - 변경: 기존 세로형 전체 너비 브랜드 버튼을 `assets/icons/kakao.png`, `naver.png`, `apple.png`를 사용하는 중앙 정렬 한 행으로 교체했다. 각 원형 이미지는 44x44로 표시하고, 접근 가능한 64x64 `CupertinoButton` 터치 영역과 버튼 사이 20px 간격을 적용했다. 공용 로그인 중에는 아이콘을 유지한 채 세 버튼을 비활성화·반투명 처리하고 행 아래에 로딩 표시를 제공한다. 기존 카카오·네이버·Apple handler, 사용자 취소 처리와 `APPLE_LOGIN_ENABLED` 플래그는 유지했다.
  - 영향범위: 로그인 화면 소셜 로그인 UI, 신규 원형 이미지 세 개, 로그인 페이지 위젯 테스트와 프로젝트 컨텍스트. Behavior change: Apple 기능 플래그가 켜진 화면에서는 세 로그인 버튼이 세로형 전체 너비 버튼 대신 원형 아이콘 한 행으로 표시된다. OAuth/API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/auth/presentation/pages/login_page.dart`, `test/features/auth/presentation/pages/login_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 로그인 위젯 테스트 3건에서 카카오·네이버 기본 노출, Apple 플래그 노출, 64x64 터치 영역, 44x44 아이콘, 동일 Y 좌표, 중심 간 84px 거리, 신규 에셋 경로·176x176 원본 규격과 접근성 레이블을 검증해 통과했다. 전체 인증 테스트 21건 통과, 변경 코드·테스트 `flutter analyze --no-fatal-infos` 진단 0건, `dart format`과 `git diff --check` 통과.
  - 롤백: 로그인 페이지의 소셜 로그인 영역과 위젯 테스트를 기존 세로형 전체 너비 버튼으로 복원하고 관련 문서 항목을 되돌린다.
  - 다음: Stage iOS/Android 실제 기기에서 아이콘 선명도, 눌림·로딩 피드백과 Apple 기능 플래그 활성화 시 세 provider 인증 진입을 확인한다.

- [DONE] (FE/DOCS) Apple 소셜 로그인 구현 및 서버 구현 가이드 작성
  - 목적: Flutter 앱에서 Apple 인증을 시작해 검증 가능한 인증 결과를 서버에 전달하고, 기존 ShiftMate JWT·신규 사용자 프로필 흐름에 연결한다. 이어서 Express 서버가 같은 계약을 안전하게 구현할 수 있는 검증·계정 연결·토큰 철회·배포 가이드를 제공한다.
  - 변경:
    - Flutter 3.38.5/Dart 3.10.4 호환 `sign_in_with_apple` 7.0.1을 고정하고 lockfile·iOS Pod를 갱신했다.
    - 서버 challenge가 플랫폼별 nonce/state/client ID/callback을 확정하고, Apple SDK 결과를 서버가 검증한 뒤에만 기존 ShiftMate JWT를 secure storage에 저장하는 Repository 흐름을 추가했다.
    - iOS 네이티브와 Android 웹 인증을 `AppleSignInSdk` 경계로 분리하고 state 불일치, 사용자 취소, 지원 불가, Android Custom Tab 2분 timeout을 처리했다.
    - `/auth/apple/challenge`, `/auth/apple`, `/auth/apple/callback` 상수와 public endpoint, `AuthNotifier.loginWithApple()`, 신규 사용자 명시 boolean 우선 파싱을 추가했다.
    - 로그인 화면은 `APPLE_LOGIN_ENABLED=true`일 때만 342x54 공식 검은색 Apple 버튼을 노출한다. 사용자 취소는 오류 alert로 표시하지 않는다.
    - iOS entitlement/Xcode capability와 Android `signinwithapple://callback` activity를 추가했다.
    - Express 실제 route/controller/service/model/migration/OpenAPI/환경변수 구조에 맞춰 challenge 1회 소비, Apple code/JWKS 검증, 이메일 자동 연결 금지, AES-256-GCM refresh token 저장/revoke, DB DDL, 오류, 테스트, Stage/Center 배포·롤백을 `_docs/APPLE_SIGN_IN_SERVER_GUIDE.md`에 확정했다.
    - Apple 인증 정책을 ADR-0019와 프로젝트 컨텍스트에 반영하고 오래된 `schema.drawio`가 최종 DDL 정본이 아님을 명시했다.
  - 영향범위: 인증 데이터·상태·로그인 UI, iOS/Android 네이티브 설정, 패키지 의존성, 인증 테스트와 프로젝트 문서. Behavior change: `APPLE_LOGIN_ENABLED=true` 빌드에만 세 번째 로그인 버튼이 나타난다. 기본값 false이므로 서버 배포 전 기존 카카오·네이버 로그인 화면은 유지된다.
  - 파일: `lib/features/auth/data/models/apple_auth_models.dart`, `data/services/apple_login_service.dart`, 인증 datasource/repository/entity/provider/page, `lib/core/constants/api_constants.dart`, `app_constants.dart`, `lib/core/network/api_client.dart`, `ios/Runner/Runner.entitlements`, `ios/Runner.xcodeproj/project.pbxproj`, `ios/Podfile.lock`, `android/app/src/main/AndroidManifest.xml`, `pubspec.yaml`, `pubspec.lock`, `test/features/auth/**`, `_docs/APPLE_SIGN_IN_SERVER_GUIDE.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트:
    - Apple service/datasource/repository/provider/login page 단위·위젯 테스트 16건 통과
    - 변경 생산 코드·테스트 15개 대상 `flutter analyze --no-fatal-infos`: 진단 0건
    - `APPLE_LOGIN_ENABLED=true` Android debug APK 빌드 통과
    - `APPLE_LOGIN_ENABLED=true` iOS simulator debug Runner 빌드 통과
    - 전체 Flutter 테스트: 135 pass, 1 skip. 기존 `calendar_page_test.dart`의 `750px 경계 화면은 기존 월 보기를 유지한다` 1건은 기존과 같은 RenderFlex 11px overflow로 실패하며 Apple 변경 파일과 겹치지 않는다.
    - 전체 analyze는 변경 밖 기존 생성 코드 duplicate ignore·미사용 profile picker warning과 naming/deprecated info 41건으로 종료 코드 1이며, 변경 대상 analyze는 0건이다.
    - 서버 가이드 JSON 예시 6개 파싱, Markdown code fence 46개 균형, 참조한 서버 route/controller/service/model/migration 파일 존재 확인, `git diff --check` 통과
  - 롤백: 앱 빌드에서 `APPLE_LOGIN_ENABLED=false`로 버튼을 즉시 숨긴다. 코드 롤백 시 Apple 모델·서비스·API/Repository/Provider/UI, 패키지·Pod, iOS entitlement/Xcode capability, Android callback, 테스트와 문서를 함께 되돌린다. 기존 카카오·네이버 로그인과 앱 JWT 저장 계약은 변경하지 않는다.
  - 다음: `_docs/APPLE_SIGN_IN_SERVER_GUIDE.md` 순서대로 서버 migration·세 endpoint·Apple token 검증·계정 삭제/revoke를 구현하고 Apple Developer App ID/key/Service ID/provisioning/private relay 설정을 완료한다. Stage iOS/Android 실기기 E2E와 롤백 리허설 통과 후 서버·앱 기능 플래그를 Production에서 활성화한다.

## 2026-08-03

- [DONE] (FE) FCM 푸시 알림 및 기기 등록 구현
  - 목적: 로그인 사용자 기기를 서버에 등록하고 Android/iOS에서 foreground·background·종료 상태의 푸시를 수신해 알림 페이지로 연결한다.
  - 변경:
    - Firebase/FCM/local notification/package info/UUID 버전을 정확히 고정하고 secure storage 10.3.1 호환 API로 갱신
    - Debug Stage, Profile/Release Production `FirebaseOptions`를 build define으로 분리하고 설정 누락 시 기존 앱은 유지하면서 push만 비활성화
    - secure storage 설치 UUID, 인증 기기 API, 로그인·앱 시작·token refresh·5분 debounce resume 동기화와 logout installation ID 전달 구현
    - foreground OS 자동 표시를 끄고 high 채널 local banner·미읽음 갱신·최근 notification ID 영속 중복 제거 구현
    - background handler, initial/opened message, root navigator pending destination으로 인증·프로필 완료 후 항상 `NotificationPage` 이동
    - iOS Runner/RunnerTests/Podfile 15.0, APNs entitlement, remote notification/fetch background mode와 Android notification 권한/channel 설정
    - `flutter_local_notifications 22.2.0`이 공식 최소 API 24를 선언해 계획의 Android API 23은 manifest 강제 override 없이 API 24로 조정하고 ADR-0018에 근거 기록
  - 영향범위: 앱 초기화, 인증 lifecycle, 알림 상태, 네이티브 빌드 설정과 패키지 의존성. 기존 인앱 알림 API는 유지한다.
  - 파일: `lib/core/push/**`, `lib/main.dart`, 인증 datasource/repository, `android/app`, `ios/Runner`, `pubspec.yaml`, `test/core/push/**`, `_docs/PUSH_NOTIFICATION_GUIDE.md`
  - 테스트:
    - 변경 파일 `flutter analyze --no-fatal-infos`: 0건
    - push 단위 테스트 4건 통과
    - Android API 24 debug APK 빌드 통과
    - iOS 15 simulator debug Runner 빌드 통과
    - 전체 Flutter 테스트 123 pass, 1 skip. 기존 `calendar_page_test.dart`의 `750px 경계 화면은 기존 월 보기를 유지한다` 1건은 이번 변경과 무관한 overflow로 실패
    - `git diff --check` 통과
  - 롤백: 서버 enqueue/worker를 먼저 끄고 신규 push coordinator와 Firebase 의존성·네이티브 설정을 제거한 이전 앱으로 복귀한다. 설치 UUID는 민감 credential이 아니며 앱 삭제 전까지 유지한다.
  - 다음: 환경별 Firebase 앱/define, APNs key, service account와 실제 Android/iOS 기기를 준비해 6개 알림·권한·token refresh·최신 기기 전환·background/terminated 탭을 Stage E2E로 확인한다.

## 2026-08-02

- [DONE] (FIX) 그룹 보낸 초대 Provider dispose 후 상태 갱신 방지
  - 목적: P1 그룹 정보 화면에서 권한 없는 멤버의 관리자 전용 초대 조회와 `autoDispose` 이후 상태 갱신 예외를 제거한다.
  - 변경: 그룹 정보 화면의 `initState`에서 역할 확인 없이 실행하던 보낸 초대·친구 목록 조회를 제거했다. OWNER/ADMIN의 P1 보낸 초대 영역이 실제 Provider를 구독한 상태에서만 최초 조회를 예약하고, MEMBER는 관리자 endpoint를 호출하지 않는다. outgoing invitation의 load/create/cancel은 비동기 완료 직후 `mounted`를 확인해 notifier가 dispose됐으면 state를 읽거나 쓰지 않고 종료한다.
  - 영향범위: 그룹 관리 화면의 보낸 초대 조회, outgoing invitation notifier, 관련 테스트·문서. 서버 권한과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/group/application/group_providers.dart`, `lib/features/group/presentation/pages/group_management_page.dart`, `test/features/group/application/group_invitation_notifier_test.dart`, `test/features/group/presentation/pages/group_management_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/GROUP_FRONTEND_IMPLEMENTATION_PLAN.md`, `_docs/WORKLOG.md`
  - 테스트: 수정 전 재현 테스트에서 dispose 후 403 완료 시 동일한 `Bad state`와 P1 MEMBER의 관리자 API 호출 1회를 확인했다. DebugMCP로 catch 시 `error=GROUP_PERMISSION_DENIED(403)`, `mounted=false`를 확인했으며 수정 후 같은 지점이 state 접근 전 반환되는 것을 재검증했다. P1 회귀 테스트 4건, 기본 그룹 테스트 10건(1건 skip), `GROUP_P1_ENABLED=true` 그룹 테스트 11건 통과. 변경 파일 `flutter analyze` 진단 0건, `dart format`, `git diff --check` 통과.
  - 롤백: 역할별 조회 조건과 notifier dispose 보호를 이전 구현으로 복원한다.
  - 다음: 실제 MEMBER 계정으로 그룹 정보 진입 시 보낸 초대 endpoint가 호출되지 않고, OWNER/ADMIN 화면 이탈 중 요청 완료에도 예외가 없는지 Stage에서 확인한다.

- [DONE] (UI) 그룹 멤버의 미설정 근무 문구 제거
  - 목적: 선택일에 설정된 근무가 없는 공개 멤버는 불필요한 `근무 없음` 문구 없이 이름과 개인 일정만 표시한다.
  - 변경: 실제 그룹 캘린더에서 근무 객체가 없을 때 근무 설명의 간격·문구와 근무 코드 배지를 렌더링하지 않도록 변경했다. 근무 객체가 있으나 시간이 없는 경우의 `근무명 · 시간 없음`과 DENIED 멤버의 `캘린더 공개 안 함`은 기존대로 유지한다.
  - 영향범위: 실제 그룹 캘린더의 선택일 멤버 카드, 관련 테스트·프로젝트 문서. 근무·일정 집계와 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/group/presentation/pages/group_calendar_page.dart`, `test/features/group/presentation/pages/group_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/GROUP_FRONTEND_IMPLEMENTATION_PLAN.md`, `_docs/WORKLOG.md`
  - 테스트: 실제 그룹 화면 테스트 2건에서 미설정 근무 문구 미표시, 시간 없는 실제 근무 상세 유지, 날짜 점 제외, DENIED 잠금을 검증해 통과했다. 전체 그룹 기능 테스트 9건 통과, 변경 Dart 파일 `flutter analyze` 진단 0건, `dart format`, `git diff --check` 통과.
  - 롤백: 근무 객체가 없는 멤버에게 `근무 없음` 설명을 다시 표시한다.
  - 다음: 실제 API에서 근무·개인 일정이 모두 없는 멤버 카드와 개인 일정만 있는 멤버 카드의 높이·정렬을 기기에서 확인한다.

- [DONE] (UI) 그룹 보기의 시간 없는 근무 점 표시 제외
  - 목적: 그룹 캘린더 날짜 셀에서 시작·종료 시간이 모두 있는 근무만 색상 점으로 표시하고, `시간 없음` 근무는 선택일 상세에만 남긴다.
  - 변경: 실제 그룹 API 화면의 날짜 점 후보를 `start_time`과 `end_time`이 모두 존재하는 근무로 제한했다. 시간 없는 근무는 기존처럼 근무 인원에 집계하고 선택일 멤버 카드에 `시간 없음`으로 표시한다. 결정적 미리보기 데이터는 근무자 템플릿이 모두 시간을 가지며 휴무는 이미 점에서 제외되므로 코드를 변경하지 않고 fallback 회귀만 확인했다.
  - 영향범위: 실제 그룹 캘린더 날짜 셀의 근무색 점, 관련 테스트·프로젝트 문서. 근무 인원 집계와 선택일 상세, 미리보기 데이터, API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/group/presentation/pages/group_calendar_page.dart`, `test/features/group/presentation/pages/group_calendar_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/GROUP_FRONTEND_IMPLEMENTATION_PLAN.md`, `_docs/WORKLOG.md`
  - 테스트: 시간 있는 근무의 점 유지, 시간 없는 근무의 점 제외, `근무 1명` 집계와 `플렉스 · 시간 없음` 상세 유지를 검증하는 실제 그룹 화면 테스트 2건 통과. 전체 그룹 기능 테스트 9건과 `GROUP_API_ENABLED=false` fallback 미리보기 테스트 8건 통과. 변경 Dart 파일 `flutter analyze` 진단 0건, `dart format`, `git diff --check` 통과.
  - 롤백: 그룹 날짜 셀의 근무색 점 생성 조건을 기존의 색상 존재 여부 기준으로 복원하고 관련 테스트·문서를 되돌린다.
  - 다음: 실제 API 데이터에서 시간이 없는 사용자 정의 근무가 포함된 날짜를 선택해 기기 렌더를 확인한다.

## 2026-08-01

- [DONE] (FE) 그룹 API 기반 프론트 기능 구현
  - 목적: 더미 그룹 방·그룹 캘린더를 실제 그룹 P0/P1 API에 연결하고, 그룹 생성·목록·상세·캘린더·초대·알림·권한별 관리 기능을 제공한다.
  - 변경: `features/group`에 entity/Repository/DataSource/Riverpod 계층을 추가하고 그룹 P0/P1 endpoint 15개를 연결했다. 그룹 방 탭은 P0 플래그에서 실제 목록·생성·받은 초대·캘린더로 전환되며, 목록 새로고침/페이지네이션과 초대 행별 처리 상태를 제공한다. 실제 그룹 캘린더는 멤버별 `owner_user_id`·`SELF/VISIBLE/DENIED`를 보존하고 전월~다음월 범위를 그룹 IANA timezone으로 배치한다. `DENIED`는 잠금 상태로 남기고 공개된 row만 근무·일정 수에 집계하며 현지 자정의 event 종료일은 배타 처리한다. OWNER/ADMIN은 P0 친구 초대를 사용할 수 있고, P1 플래그에서는 그룹 수정·초대 목록/취소·멤버 제거/역할·탈퇴·소유권 이전·삭제를 역할표에 맞게 노출한다. 그룹 알림 4종과 payload를 추가하고 PENDING+actions 및 받은 초대 API 결과가 모두 유효할 때만 버튼을 표시하며 그룹 초대 응답을 친구 요청 API와 분리했다. 계정 전환 시 그룹 Provider를 무효화하고, 동시 401 요청은 하나의 refresh Future를 기다린 뒤 원 요청을 한 번만 재시도하도록 인증 인터셉터를 보완했다. `timezone` 0.11.1과 앱 시작 timezone DB 초기화를 추가했다.
  - 영향범위: 친구 화면의 그룹 방 탭과 미리보기 fallback, 그룹 목록·생성·캘린더·초대·관리 신규 화면, 알림 모델/상태/화면, 인증 계정 캐시, Dio 401 갱신, 의존성·테스트·프로젝트 문서. Behavior change: `GROUP_API_ENABLED=true` 빌드에서는 더미 카드 대신 실제 서버 그룹 기능을 사용한다. 플래그 기본값은 false라 기본 빌드는 기존 미리보기를 유지하고, `GROUP_P1_ENABLED=true`일 때만 관리 mutation을 노출한다. 개인/친구 캘린더 API와 DB 계약은 변경하지 않는다.
  - 파일: `lib/features/group/**`, `lib/features/friend/presentation/pages/friend_list_page.dart`, `notification_page.dart`, `lib/features/friend/presentation/providers/notification_provider.dart`, `lib/features/friend/presentation/widgets/notification_item.dart`, `lib/features/friend/data/models/notification_model.dart`, `lib/features/auth/presentation/providers/auth_provider.dart`, `lib/core/constants/api_constants.dart`, `app_constants.dart`, `lib/core/network/api_client.dart`, `lib/main.dart`, `pubspec.yaml`, `pubspec.lock`, `test/features/group/**`, `test/features/friend/data/models/group_notification_model_test.dart`, `test/features/friend/presentation/providers/group_notification_provider_test.dart`, `_docs/GROUP_FRONTEND_IMPLEMENTATION_PLAN.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 신규 그룹/알림 테스트 11건에서 목록 summary/탭, 응답 파싱·unknown enum·소유자/색상/UTC 보존, 3개월 범위·동일 월 요청 병합, Asia/Seoul 날짜 변환·배타 종료일, DENIED 잠금/실제 row 집계, PENDING/EXPIRED 알림과 친구/그룹 응답 API 분리, 만료 409 서버 재조회, P1 플래그 off/on UI를 검증해 통과했다. 기존 그룹 미리보기 fallback 테스트 8건도 통과했다. 변경 생산 코드·신규 테스트 대상 `flutter analyze` 진단 0건, `git diff --check` 통과. 전체 테스트는 115건 통과 후 변경하지 않은 메인 캘린더의 기존 `390x750` RenderFlex 11px overflow 1건만 실패했고 이 테스트는 단독으로도 같은 오류가 재현된다. 프로젝트 전체 analyze는 변경 밖의 기존 naming info·생성 코드 중복 ignore·미사용 profile picker 진단 때문에 종료 코드 1이지만 변경 대상 진단은 없다. 현재 debug origin의 `GET /groups` 비인증 연결 확인은 `192.168.0.5:3000`에서 서버가 실행 중이지 않아 curl 연결 단계에서 실패했으므로 실제 Stage/API 응답 검증으로 판정하지 않았다.
  - 롤백: 배포 설정에서 `GROUP_P1_ENABLED=false`, 이어서 `GROUP_API_ENABLED=false`로 실제 기능을 숨기면 서버 데이터 변경 없이 기존 `GroupCalendarPreviewPage`로 즉시 복귀한다. 코드 롤백 시 신규 그룹 모듈과 알림 분기, API 상수, timezone 초기화, 인증 캐시 무효화와 문서/테스트를 함께 되돌린다.
  - 다음: 실제 Stage origin·인증 계정·서버 이미지와 migration 적용 시각을 확보해 `_docs/GROUP_FRONTEND_IMPLEMENTATION_PLAN.md`의 P0 인수 목록을 수행하고, 통과 후 P0/P1 플래그를 순차 승인한다. 메인 캘린더 750px 기존 overflow는 그룹 범위와 분리된 후속 수정 항목으로 처리한다.

## 2026-07-29

- [DONE] (DOCS/BE) 그룹 기능 서버 개발 요청서 작성
  - 목적: 더미 데이터로 동작하는 그룹 방·그룹 캘린더를 실제 서버 데이터로 전환할 수 있도록 그룹 생성, 목록, 상세, 멤버십·초대, 그룹 캘린더 범위 조회와 권한 계약을 구현 가능한 수준으로 정의한다.
  - 변경: 1,358줄의 `_docs/GROUP_API_SERVER_REQUEST.md`를 추가해 P0/P1 endpoint 15개, `groups`·`group_members`·`group_invitations` 제안 DDL/인덱스, OWNER/ADMIN/MEMBER 권한, 초대·소유권 이전·soft delete transaction, 기존 친구 ACL을 재사용하는 정규화 그룹 캘린더 응답과 `calendar_access`, 초대 알림, 오류·환경변수·성능·테스트·Swagger·배포 완료 조건을 정의했다. 현재 drawio의 `calendars/calendar_shares`가 최종 단일 캘린더 DDL과 다름을 명시하고, 공개 권한·최대 멤버·timezone 등 서버팀 확인 항목을 분리했다.
  - 영향범위: 서버 개발 요청 문서, 프로젝트 컨텍스트, 친구 기능 설계와 작업 로그. Flutter 코드와 현재 API/DB 동작은 변경하지 않는다.
  - 파일: `_docs/GROUP_API_SERVER_REQUEST.md`, `_docs/PROJECT_CONTEXT.md`, `_docs/FRIEND_FEATURE_DESIGN.md`, `_docs/WORKLOG.md`
  - 테스트: JSON 예시 20개를 `jq`로 전부 파싱했고 Markdown code fence 78개가 짝을 이루는지, endpoint 15개와 문서 연결 경로가 존재하는지 확인했다. `git diff --check`가 통과했으며 문서 전용 변경이므로 Flutter 테스트는 실행하지 않았다.
  - 롤백: 신규 요청 문서와 프로젝트 컨텍스트·친구 기능 설계·작업 로그의 연결 항목을 제거한다.
  - 다음: 서버팀이 문서 마지막 확인 요청 8개에 답변하면 확정 정책을 ADR과 실제 migration/OpenAPI에 반영한다.

- [DONE] (UI) 그룹 방 목록의 중복 본문 제목 제거
  - 목적: 내비게이션 바와 하단 탭에 이미 표시되는 `그룹 방` 문구를 본문에서 반복하지 않고 첫 그룹 카드를 바로 노출한다.
  - 변경: 그룹 방 목록 상단의 `그룹 방` 제목과 뒤따르던 12px 간격을 제거해 16px 목록 padding 다음에 `우리 병동` 카드가 바로 표시되게 했다. 테스트는 `그룹 방` 문구가 내비게이션과 footer 두 위치에만 남는지 검증한다.
  - 영향범위: 친구 화면의 그룹 방 목록 본문과 관련 테스트·문서. Behavior change: 목록 본문의 중복 섹션 제목이 사라진다. 내비게이션 제목, footer 탭, 그룹 카드와 진입 동작은 유지한다.
  - 파일: `lib/features/friend/presentation/pages/friend_list_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 그룹 미리보기 위젯 테스트 8건 통과, 변경 코드·테스트 `flutter analyze` 진단 0건, `dart format`, `git diff --check`가 통과했다.
  - 롤백: 그룹 카드 위에 `그룹 방` 제목과 12px 간격을 복원한다.
  - 다음: 실제 기기에서 그룹 카드의 상단 16px 여백이 내비게이션 아래에서 자연스럽게 보이는지 확인한다.

- [DONE] (UI) 메인·친구 선택일 헤더를 그룹 보기와 정렬
  - 목적: 메인·친구 캘린더의 선택일 날짜 영역 높이와 일정 수 표현을 그룹 보기와 같은 시각 규칙으로 맞춘다.
  - 변경: 공용 `CalendarScheduleHeader`를 그룹 헤더와 같은 본문 44px 높이(세로 8px 여백 + 28px 콘텐츠, 0.5px 구분선 포함 실측 44.5px)로 조정했다. `N개의 일정` 일반 문구는 `CalendarScheduleSummaryChip`을 사용한 `일정 N개` pill로 교체하고, 일정이 없는 날도 `일정 0개`를 표시한다. 메인 근무 입력의 `완료` 버튼도 28px 콘텐츠 높이로 맞췄으며, 그룹의 `근무 N명`·`일정 N개`는 전용 중복 구현 대신 같은 공용 pill을 사용한다.
  - 영향범위: 메인 일정 카드, 메인 근무 입력 카드, 친구 일정 카드, 그룹 선택일 요약 pill과 관련 테스트·문서. Behavior change: 메인·친구 선택일 헤더가 60px에서 44.5px로 줄고 일정 수가 pill로 표시되며, 근무 입력 `완료` 버튼은 36px에서 28px로 줄어든다. 데이터/API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/calendar_schedule_card.dart`, `lib/features/calendar/presentation/pages/calendar_page.dart`, `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`, 메인·친구·그룹 캘린더 테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 메인·친구·그룹 캘린더 위젯 테스트 23건과 전체 Flutter 테스트 107건이 통과했다. 세 화면의 선택일 헤더 실측 높이 44.5px, `일정 N개` 문구, 공용 그룹 요약 pill을 검증했다. 변경 코드·테스트 `flutter analyze` 진단 0건, `dart format`, `git diff --check`가 통과했다.
  - 롤백: 공용 헤더의 60px 구조와 `N개의 일정` 문구, 그룹 전용 요약 pill 구현을 복원한다.
  - 다음: 실제 iOS/Android 기기에서 긴 날짜·공휴일명과 일정 pill, 근무 입력 `완료` 버튼이 좁은 화면에서도 자연스럽게 배치되는지 확인한다.

- [DONE] (UI) 메인·친구 선택일 날짜 형식을 그룹 보기와 통일
  - 목적: 세 캘린더 하단 상세 헤더가 동일한 한국어 날짜 표현을 사용하게 한다.
  - 변경: 공용 `CalendarScheduleHeader`의 `yyyy.MM.dd` 형식을 그룹 보기와 같은 `M월 d일 EEEE`로 변경하고, 메인·친구 캘린더 테스트 기대값을 같은 형식으로 갱신했다.
  - 영향범위: 메인 일정 카드, 메인 근무 입력 카드, 친구 일정 카드의 선택일 날짜 문자열과 관련 테스트·문서. Behavior change: 선택일이 `7월 29일 수요일` 형태로 표시된다. 데이터/API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/calendar_schedule_card.dart`, 메인·친구 캘린더 테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 메인·친구·그룹 캘린더 위젯 테스트 23건과 전체 Flutter 테스트 107건이 통과했다. 변경 코드·테스트 `flutter analyze` 진단 0건, `dart format`, `git diff --check`가 통과했다.
  - 롤백: 공용 헤더 날짜 포맷을 `yyyy.MM.dd`로 복원한다.
  - 다음: 실제 기기에서 긴 요일 이름과 우측 일정 수/근무 액션이 좁은 화면에서도 자연스럽게 배치되는지 확인한다.

- [DONE] (UI) 그룹 선택일 헤더 보조 문구 제거
  - 목적: 그룹 하단 일정 영역의 헤더를 날짜와 근무·일정 요약에 집중하도록 간결하게 만든다.
  - 변경: `선택일 근무 현황` 문구와 그 아래 2px 간격을 제거해 날짜가 헤더의 단일 제목으로 표시되게 했다.
  - 영향범위: 그룹 캘린더 선택일 상세 헤더와 관련 테스트·문서. Behavior change: 하단 카드 헤더에는 날짜와 근무·일정 요약만 표시된다. 데이터/API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 그룹 미리보기 테스트 8건 통과, 변경 코드·테스트 `flutter analyze` 진단 0건, `dart format`과 `git diff --check` 통과.
  - 롤백: 선택일 날짜 위에 보조 문구와 2px 간격을 복원한다.
  - 다음: 실제 기기에서 날짜와 우측 요약 chip의 수직 정렬을 확인한다.

- [DONE] (UI) 그룹 캘린더 배경·하단 일정 영역 패밀리룩 정렬
  - 목적: 메인·친구 캘린더처럼 달력을 페이지 배경색에 자연스럽게 연결하고, 선택일 구성원 일정 목록은 별도 surface 영역으로 분리한다.
  - 변경: 그룹 달력의 흰색 전용 surface와 하단 border를 제거해 페이지 `background_color`에 직접 배치했다. 캘린더와 선택일 상세 사이는 8px로 맞추고, 선택일 헤더·요약 chip·구성원 스크롤 목록을 좌우 16px 여백, 흰색 surface, 16px 반경, 1px outline의 단일 카드 영역으로 묶었다. 헤더와 목록은 0.5px 선으로 구분하고 카드 하단에는 시스템 안전영역을 포함한 최소 16px 여백을 적용했다.
  - 영향범위: 그룹 캘린더 미리보기의 달력 배경, 캘린더와 선택일 상세 사이 간격, 하단 목록 외곽 영역과 관련 위젯 테스트·문서. Behavior change: 달력은 흰색 구획이 아니라 페이지 배경과 이어지고, 하단 선택일 정보는 독립된 카드 영역으로 보인다. 데이터 생성/API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 그룹 미리보기 테스트 8건과 전체 Flutter 테스트 107건이 통과했다. 변경 코드·테스트 `flutter analyze` 진단 0건과 `dart format`이 통과했으며, 달력 배경색/무경계, 하단 surface 카드의 색·반경·outline, 헤더 구분선, 하단 16px 안전 여백을 검증했다.
  - 롤백: 그룹 달력의 흰색 surface·하단 border와 카드 밖 선택일 헤더/구성원 목록 구조를 복원한다.
  - 다음: 실제 iOS/Android 기기에서 5·6주 월의 카드 높이와 홈 인디케이터 위 목록 스크롤을 확인한다.

- [DONE] (REFACTOR) 메인·친구·그룹 캘린더 공통화
  - 목적: 세 캘린더의 날짜 탐색·반응형 레이아웃·날짜 셀 렌더링을 공통 컴포넌트로 통합하고, 메인·친구의 중복된 3개월 조회 캐시를 공용 상태로 분리한다.
  - 변경: `CalendarDayPresentation`과 badge/dots indicator, 750px 반응형 `CalendarLayoutPolicy`, 2000.01~2050.12 월 이동 `CalendarViewportController`, 공용 연월 헤더·수평 알림 경계·날짜 셀을 조합한 `CalendarViewport`/`CalendarMonthView`를 추가하고 세 화면을 이전했다. 메인·친구의 전월~다음월 조회·날짜별 병합·월별 in-flight/loaded/loading·오류 상태·로컬 mutation 반영은 loader 주입형 `CalendarRangeNotifier`로 통합했다. 메인은 본인 range provider, 친구는 friend ID family provider를 사용하고 로그인/로그아웃 시 계정 범위 캐시를 무효화한다. 메인 편집 draft, 친구 설정, 그룹 구성원 상세와 실제 API가 없는 그룹 더미 데이터는 화면별 책임으로 유지했으며 설계는 ADR-0016에 기록했다.
  - 영향범위: 메인·친구·그룹 캘린더의 프레젠테이션, 메인·친구 캘린더 조회/캐시 상태, 인증 전환 시 캐시 무효화, 관련 테스트·아키텍처 문서. 외부 화면 동작과 API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/application/calendar_range_state.dart`, `calendar_range_notifier.dart`, `lib/features/calendar/presentation/controllers/calendar_viewport_controller.dart`, `models/calendar_day_presentation.dart`, `models/calendar_layout_policy.dart`, `providers/calendar_range_provider.dart`, `widgets/calendar_viewport.dart`, `widgets/calendar_month_view.dart`, 메인·친구·그룹 페이지, `friend_calendar_range_provider.dart`, `auth_provider.dart`, 신규 단위 테스트 3개, 기존 세 화면 테스트, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 공용 range notifier 3건, viewport controller 3건, layout policy 2건과 세 캘린더 위젯 테스트 23건을 묶은 31건이 통과했다. 전체 Flutter 테스트 107건, 변경 대상 17개 경로 `flutter analyze` 진단 0건, `dart format`, `git diff --check`가 통과했다. 프로젝트 전체 분석은 이번 변경 밖의 기존 네이밍 lint·미사용 요소·생성 코드 ignore·deprecated API 등 96건으로 종료 코드 1이며 변경 대상 진단은 없다.
  - 롤백: 신규 공용 application/controller/model/viewport/provider와 ADR-0016을 제거하고, 메인·친구의 로컬 3개월 맵·로딩 집합 및 세 페이지의 기존 헤더/날짜 셀 구현을 복원한다. 인증 provider의 두 range 무효화와 신규 단위 테스트·문서도 함께 되돌린다.
  - 다음: 실제 iOS/Android 기기에서 빠른 연속 월 스와이프, 요청 실패 후 재시도, 메인 compact↔badge 전환과 그룹 5·6주 월을 확인한다. 실제 그룹 API 계약이 확정되면 멤버 ID를 포함한 별도 aggregate state 필요 여부를 ADR-0016 기준으로 재평가한다.

- [DONE] (FE) 그룹 뷰 디자인 개선
  - 목적: `design/group_view ver2` 참고 시안의 캘린더·오늘 상태 정보 계층을 현재 ShiftMate의 Shift Harmony 패밀리룩에 맞게 그룹 캘린더 미리보기에 반영한다.
  - 변경: 중복된 상단 멤버 섹션을 제거하고 내비게이션에 `우리 병동`과 `4명` 요약을 배치했다. 메인·친구 캘린더의 공용 `CalendarMonthHeader`를 재사용하고, 둥근 outline 캘린더 카드와 셀별 `N명 근무` 문구를 full-width 흰색 surface 및 실제 근무색 점 최대 4개로 교체했다. 오늘은 공통 primary 밑줄, 선택일은 8% primary tint와 2px primary dark outline을 사용하며 선택된 주말의 의미 색상을 유지한다. 선택일 헤더는 날짜와 `근무 N명`·`일정 N개` chip으로 정리했다. 구성원 카드는 16px surface 카드, 멤버 고유색 아바타, 근무색 왼쪽 바·점·코드 배지와 이름→근무명·시간→개인 일정 순서로 재구성했다.
  - 영향범위: 그룹 캘린더 미리보기 화면, 관련 위젯 테스트와 프로젝트 문서. Behavior change: 그룹 멤버 요약은 별도 겹침 아바타 영역 대신 내비게이션 count로 표시되고, 달력의 근무 인원 문구는 근무 타입 색상 점으로 표시된다. 실제 그룹 API/DB 및 내 캘린더·단일 친구 캘린더는 변경하지 않는다.
  - 파일: `lib/features/friend/presentation/pages/group_calendar_preview_page.dart`, `test/features/friend/presentation/pages/group_calendar_preview_page_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`
  - 테스트: 390x844 렌더 이미지를 생성해 월 전체, 선택일 헤더, 구성원 카드의 잘림과 목록 스크롤을 확인했다. 그룹 미리보기 테스트를 8건으로 확장해 근무색 점의 개수·색상, full-width calendar surface, 선택일 tint/outline, 선택된 토·일요일 의미 색상, 이름/근무 시간/개인 일정 순서, 0명 근무, 390x740 2주 보기와 친구 탭 진입을 검증했다. 대상 2개 Dart 파일 `flutter analyze --no-fatal-infos` 진단 0건, 전체 Flutter 테스트 99건, `dart format`과 `git diff --check`가 통과했다. 프로젝트 전체 분석은 이번 변경 밖의 기존 네이밍 충돌·미사용 요소·생성 코드 ignore·deprecated API 등 96건으로 종료 코드 1이며 변경 대상 진단은 없다.
  - 롤백: 이번 그룹 뷰 레이아웃·테스트·문서 변경만 이전 구현으로 복원한다.
  - 다음: 실제 iOS/Android 기기에서 5주·6주 월과 긴 구성원 이름·일정의 가독성을 확인하고, 실제 그룹 API 계약이 확정되면 더미 생성기를 서버 조회 결과로 교체한다.

- [DONE] (CHORE) 근무 타입 코드 중복·키보드 수정 커밋 및 푸시
  - 목적: 입력 완료 시점의 중복 표시와 중복 오류 후 첫 탭 키보드 복원 작업을 검증 가능한 Git 이력으로 정리해 원격 저장소에 반영한다.
  - 변경: 코드 입력 중 컨트롤러 재할당과 즉시 중복 표시를 제거하고 대문자 변환을 `TextInputFormatter`로 이동한 변경, 입력 완료 후 중복 표시 정책, 중복 오류 상태에서 코드 필드 첫 탭 키보드 복원 구조를 하나의 수정 커밋으로 정리해 `origin/main`에 푸시한다. 구현 근거와 동작 계약은 PROJECT_CONTEXT 및 ADR-0015에 함께 기록했다.
  - 영향범위: 근무 타입 추가·수정 폼의 대문자 정규화, 중복 표시 시점, 오류 상태 렌더링, 포커스·플랫폼 키보드 입력 연결과 관련 Git 이력. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 변경 코드·테스트 `dart format` 변경 0건, `flutter analyze --no-fatal-infos` 진단 0건, 전체 Flutter 테스트 98건 및 `git diff --check` 통과. 신규·수정 코드 접두어 입력 중 중복 미표시, 입력 완료 후 실제 중복 표시, 중복 표시 후 첫 탭 키보드 복원과 첫 수정 후 입력 연결 유지를 검증했다.
  - 롤백: 원격 반영 후 필요 시 해당 커밋을 `git revert`하고 푸시한다.
  - 다음: 실제 iOS/Android 기기에서 입력 완료 전후 중복 표시와 중복 오류 후 첫 탭 키보드 동작을 확인한다.

## 2026-07-26

- [DONE] (FIX) 중복 코드 표시 후 코드 필드 첫 탭 키보드 복원
  - 목적: 중복 코드 입력 완료 후 빨간 오류가 표시된 상태에서 코드 필드를 다시 탭하면 커서만 생기고 키보드는 두 번째 탭에서야 열리는 문제를 해결한다.
  - 변경: 디버거로 포커스 획득 흐름을 확인한 결과, 오류 표시를 지우는 포커스 리스너가 `EditableText`의 플랫폼 입력 연결보다 먼저 실행되어 코드 입력 분기를 다시 빌드하는 것이 원인이었다. 포커스 획득 시에는 오류 상태를 변경하지 않고 실제 코드가 수정될 때만 오류를 숨기도록 변경했다. 중복 상태는 `ValueNotifier`로 국소 관리하고 코드 `CupertinoTextField`는 안정적인 자식으로 계속 마운트했으며, 빨간 테두리는 `Stack`의 `IgnorePointer` 오버레이로 분리해 오류 표시 변경이 입력 필드를 교체하지 않게 했다. 완료 버튼과 안내 문구는 동일 상태를 관찰해 기존 중복 차단 동작을 유지한다.
  - 영향범위: 근무 타입 추가·수정 폼의 중복 오류 재편집 포커스, 플랫폼 키보드 입력 연결, 오류 테두리 렌더링. Behavior change: 중복 오류 상태에서 코드 필드를 다시 탭하면 기존 빨간 표시가 첫 실제 수정 전까지 유지되며, 키보드는 첫 탭부터 열린다. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 수정 전 `FocusNode.hasFocus=true`인데 `TestTextInput.isVisible=false`인 첫 탭 실패를 재현하고 디버거에서 포커스 리스너 실행 순서를 확인했다. 수정 후 중복 빨간 표시→키보드 숨김→코드 필드 첫 탭에서 포커스·키보드 활성화→첫 코드 수정 후에도 키보드 유지와 오류 제거를 검증했다. 근무 타입 폼 테스트 16건과 전체 테스트 98건이 통과했고, 변경 코드·테스트 `flutter analyze --no-fatal-infos`는 0건, `dart format`과 `git diff --check`도 통과했다. 전체 프로젝트 분석은 이번 변경 파일 밖의 기존 warning/info 96건으로 종료 코드 1이며 변경 대상 진단은 없다.
  - 롤백: `ValueNotifier` 기반 중복 상태와 별도 오류 테두리 오버레이를 제거하고, 코드 입력 행을 중복 상태와 함께 다시 빌드하던 이전 구조 및 관련 테스트·문서를 복원한다.
  - 다음: 실제 iOS/Android 기기에서 중복 표시 후 키보드를 닫고 코드 필드를 한 번 탭해 키보드가 즉시 열리는지 확인한다.

- [DONE] (FIX) 근무 패턴 코드 중복 검사를 입력 완료 시점으로 변경
  - 목적: 기존 코드로 시작하는 신규/수정 코드 입력 중 조기에 중복 오류가 표시되고 입력 포커스가 해제되어 키보드가 닫히는 문제를 해결한다.
  - 변경: `TextEditingController` 리스너가 소문자를 대문자로 다시 쓰며 재진입하고 커서 선택 변화에도 폼 전체를 재빌드하던 흐름을 제거했다. 대문자 변환은 입력 연결 안에서 동작하는 `TextInputFormatter`로 옮겼다. 코드 중복 UI는 입력 중 숨기고 키보드 완료·다른 필드 이동·본문 터치로 코드 포커스가 빠진 뒤에만 현재 전체 코드로 판정한다. 중복 표시 후 재편집할 때는 실제 코드가 변경되는 시점에 기존 안내를 숨기고 다음 입력 완료 때 재검사한다. 최종 저장 검증과 서버 `DUPLICATE_CODE` 처리는 유지했으며 정책은 ADR-0015에 기록했다.
  - 영향범위: 근무 타입 추가·수정 폼의 대문자 정규화, 코드 중복 검증 표시 시점, 완료 버튼 상태와 키보드 입력 연결. Behavior change: 기존 코드와 같은 접두어를 입력하는 동안에는 중복 경고를 표시하지 않고, 코드 입력을 끝낸 뒤 전체 값이 실제로 같을 때만 경고와 완료 비활성화를 표시한다. API/DB 계약은 변경하지 않는다.
  - 파일: `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`, `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`, `_docs/PROJECT_CONTEXT.md`, `_docs/DECISIONS.md`, `_docs/WORKLOG.md`
  - 테스트: 수정 전 회귀 테스트에서 `FocusNode.hasFocus=true`인데 `TestTextInput.isVisible=false`인 키보드 입력 연결 해제를 재현했다. 수정 후 신규 `D→DE`, 수정 `D→DE` 입력 중 중복 미표시·포커스/키보드 유지, 실제 중복 `E`의 입력 완료 후 표시와 조합 입력 중 컨트롤러 미재할당을 포함한 근무 타입 폼 테스트 16건 및 전체 테스트 98건이 통과했다. 대상 코드·테스트 `flutter analyze --no-fatal-infos` 0건과 `dart format`을 통과했다. 전체 분석은 이번 변경 파일 밖의 기존 warning/info 96건으로 종료 코드 1이며 변경 대상 진단은 없다.
  - 롤백: `_UpperCaseTextInputFormatter`와 입력 완료 중복 표시 상태를 제거하고 코드 컨트롤러 리스너의 즉시 대문자 재할당·즉시 중복 판정 흐름 및 이전 테스트·문서를 복원한다.
  - 다음: 실제 iOS/Android 기기에서 신규·수정 코드에 `D→DE`처럼 입력하고 키보드 유지, 완료 후 중복 표시, 한글/영문 키보드 전환을 확인한다.

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
