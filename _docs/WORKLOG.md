# 작업 로그

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
