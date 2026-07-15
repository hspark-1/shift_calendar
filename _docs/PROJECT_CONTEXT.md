# 프로젝트 컨텍스트

## 프로젝트 개요

**Shift Calendar**는 교대 근무 일정 관리 및 공유를 위한 Flutter 모바일 애플리케이션입니다.

### 주요 기능

- 교대 근무 일정 관리 (데이/이브닝/나이트 등)
- 캘린더 기반 일정 조회 및 편집
- 친구 간 일정 공유
- 카카오 OAuth 로그인

### 기술 스택

- **프레임워크**: Flutter (Cupertino 디자인)
- **상태관리**: Flutter Riverpod 2.6.1
- **네트워크**: Dio 5.7.0
- **인증**: 카카오 Flutter SDK
- **로컬 저장소**: Flutter Secure Storage, Shared Preferences
- **코드 생성**: Freezed, JSON Serializable, Riverpod Generator

### UI 디자인 시스템

- 디자인 기준은 Shift Harmony 문서(`../design/DESIGN.md`,
  `../design/design prompt/DESIGN.md`,
  `../design/design prompt/flutter_fe_development_prompt_shift_harmony.md`)를 따른다.
- 앱 구조는 기존 Flutter Cupertino 기반을 유지하고, Material 3 전환은 하지 않는다.
- 공용 색/타이포/반경/보더 토큰은 `lib/core/theme/app_theme.dart`에 둔다.
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
    선택일은 흰색 surface 배경과 2px primary dark outline 사각형, 굵은 날짜 텍스트로 표시하며
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
    버튼을 표시한다. 날짜 헤더 오른쪽에는 36px 높이의 compact `완료` 버튼을 배치하고,
    별도 하단 완료 버튼과 근무 타입 수 배지는 표시하지 않는다. 원형 버튼은 한 행 최대 5개,
    최대 2행으로 배치해 타입 1~10개를 내부 스크롤 없이 노출한다. 버튼 안에는 코드와 이름을
    표시하며, 선택 시 해당 타입 색상의 tint와 굵은 outline을 사용한다.
    버튼을 누르면 `_schedules`에 선택 근무를 임시 저장한 뒤 다음 날로 자동 이동한다.
    날짜 헤더/완료 버튼, 버튼 그리드, 안내 문구는 하나의
    `surface_container_low_color` 카드 영역 안에 둔다. 근무 추가 모드에서는
    진입 전 `CalendarFormat`과 확장 상태를 저장한 뒤 `CalendarFormat.month`와 확장 보기를
    활성화해 60px 날짜 셀 아래에 근무 코드를 표시한다. 입력 중에는 수직 드래그 확장/축소를
    잠그고, 완료/취소 시 진입 전 달력 형식과 확장 상태를 복구한다. 근무 추가 모드 자체는 2주
    보기로 전환하지 않지만 화면 높이가 750px 미만이면 전역 반응형 규칙에 따라 2주 보기를 유지한다.
    다음 날 자동 이동은 `_selected_day`와 `_focused_day`를 함께 갱신해 월/2주 보기의 표시 페이지가
    선택일을 따라가게 하며, 캘린더·공휴일 데이터 추가 조회는 월 경계를 넘을 때만 실행한다.
    근무 설정 카드 내부는 12px padding을 사용한다.
  - `lib/features/calendar/presentation/widgets/shift_type_button.dart`: 근무 타입 선택 버튼 위젯.
    기존 `ShiftTypeButtonGroup`은 근무 추가 페이지/시트에서 Provider 기반 원형 버튼을 표시하고,
    `ShiftTypeSelectionGrid`는 메인 캘린더가 전달한 정렬된 `ShiftTypeInfo` 목록을 실제 너비와
    높이에 맞춰 최대 5열로 배치한다. 메인 그리드는 코드/이름, 선택 상태, 접근성 label을
    제공하며 선택 콜백으로 코드만 반환한다.
  - `lib/features/calendar/presentation/widgets/year_month_picker_sheet.dart`: 메인 캘린더와 근무 추가
    화면이 함께 사용하는 연도/월 선택 하단 시트. 현재 선택값 요약, `이번 달` 빠른 이동,
    연도·월 휠, 취소/이동 액션을 Shift Harmony surface/primary 토큰으로 표시한다.
    호출 화면은 자신의 `TableCalendar.firstDay`/`lastDay`와 같은 연도 범위를 전달하고,
    반환된 월의 1일을 focused day로 사용한다.
  - `lib/features/calendar/presentation/widgets/date_picker_sheet.dart`: 개인 일정의 시작일/종료일처럼
    일 단위 날짜를 선택하는 공용 하단 시트. 연도/월 선택 시트와 같은 핸들, 선택값 요약 카드,
    빠른 `오늘` 액션, surface 기반 피커 카드, 취소/적용 버튼을 제공한다. 호출 화면이 최소/최대
    날짜를 전달하며, 결과는 시간이 제거된 로컬 `DateTime`으로 반환한다.
  - `lib/features/calendar/presentation/widgets/time_picker_sheet.dart`: 개인 일정의 시작시간/종료시간처럼
    시·분 단위 시간을 선택하는 공용 하단 시트. 선택 시간을 오전/오후 형식으로 요약하고,
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
    페이지가 다음 일요일로 함께 이동하는 회귀도 확인한다. 또한 선택된 토요일/일요일의 의미 색상과
    surface 배경·2px primary dark outline, 날짜·근무 배지 셀의 레이아웃 예외, 확장/compact 보기의
    마지막 행 선택 사각형이 달력 경계 안에 포함되는지 검증한다.
  - `lib/features/calendar/presentation/widgets/bottom_action_bar.dart`: 메인 하단 내비게이션.
    친구, 오늘, 알림 이동 액션과 미읽음 알림 배지를 표시하며 기본적으로 상단 outline을 그린다.
  - `test/features/calendar/presentation/widgets/shift_type_button_test.dart`:
    `ShiftTypeSelectionGrid`가 320x128 영역에서 타입 1~10개를 스크롤/오버플로우 없이 표시하는지,
    10개를 5개씩 2행으로 배치하는지, 선택 코드를 콜백으로 전달하는지 검증한다.
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
    `ShiftTemplateSettingsPage`에서 편집/삭제 액션을 주입받아 사용한다.
  - `lib/features/calendar/presentation/widgets/shift_type_form_modal.dart`: 근무 타입 추가/편집 화면.
    `CupertinoPageRoute`로 진입하며, 본문은 `SafeArea(bottom: false)`와 내부 bottom padding을
    함께 사용해 안내 문구가 홈 인디케이터/화면 끝에 붙어 잘려 보이지 않게 한다. 시간 선택
    팝업은 하단 안전영역만큼 컨테이너 높이와 spacer를 늘려 피커 휠이 화면 하단에 겹치지 않게 한다.
  - `lib/features/auth/presentation/pages/settings_page.dart`: 설정 화면. `../design/stitch_shift_schedule_planner (3)/code.html`
    시안의 중앙 `설정` 헤더, 프로필 카드, 근무 관리/앱 설정/계정 및 보안/지원 카드 섹션,
    정적 토글, 별도 로그아웃 버튼을 Cupertino 커스텀 위젯으로 구현한다. 설정 화면 내부에는
    하단 내비게이션을 두지 않고, 메인 캘린더에서 push된 페이지로 뒤로가기를 제공한다.
    상단 `설정` 헤더와 뒤로가기는 `CupertinoPageScaffold.navigationBar`에 두어 메인
    캘린더의 `CupertinoNavigationBar`와 route 전환 시 같은 헤더 transition을 타게 한다.
    프로필/설정 섹션/로그아웃 버튼만 본문 `ListView`에서 스크롤한다.
    다른 화면보다 크게 보이지 않도록 설정 화면 전용 `_settings_scale = 0.8`을 사용해
    프로필, 섹션, 행, 아이콘, 토글, 로그아웃 버튼 치수를 축소한다. 섹션 카드는
    행 배경/구분선을 `ClipRRect`로 먼저 클리핑하고, `foregroundDecoration`이 primary
    tint 1px outline을 마지막에 그려 같은 크기의 내부 surface가 border를 덮지 않게 한다.
    실제 구현된 항목은 `ShiftTemplateSettingsPage`로 이동하는 근무 패턴 설정과 로그아웃이다.
    프로필 편집, 기본 알림 설정, 다크 모드, 언어 및 지역, 글꼴 크기, 비밀번호 변경,
    로그인 생체 인증, 공지사항, 고객 센터는 `_showFeatureUnavailableAlert()`로
    "준비 중인 기능" alert를 표시하고 상태를 변경하지 않는다. 버전 정보는
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

**에러 처리 흐름**:

```
DioException → handleApiError() → ApiException → UI (CupertinoAlertDialog)
```

### 메인 캘린더 조회/표시 흐름

```
CalendarPage
  → CalendarService.getCalendarRange()
  → GET /api/v1/calendar/range
  → CalendarRangeResponse(work_shifts, events)
  → WorkShiftApiModel / EventApiModel 날짜별 맵
  → TableCalendar + 선택 날짜 일정 카드
```

- 메인 캘린더의 저장된 근무표 표시는 서버가 반환한 `WorkShiftApiModel`을 기준으로 한다.
- 메인 달력은 근무 코드 배지를 기본 노출하고, compact 보기에서는 기존 색상 점을 표시한다.
  화면 높이 750px 미만에서는 2주 보기로 고정하며, 750px 이상에서는 기존 월/2주/주 형식 전환을
  유지한다. 좌우 기간 이동 동작은 두 경우 모두 유지한다.
- `work_shifts` 응답의 `shift_type_code`, `shift_type_name`, `shift_type_color`,
  `start_time`, `end_time`은 저장된 근무표 표시용 스냅샷이다.
- `shiftTypesProvider`는 현재 계정의 근무 타입 설정 조회 및 근무 입력 원형 버튼 표시용으로만 사용한다.
- 저장된 근무표를 화면에 그릴 때는 `shiftTypesProvider`의 코드별 캐시로 색상/이름/시간을 재해석하지 않는다.
- 메인 캘린더 근무 추가 모드는 서버 저장 전 `_schedules`에 임시 선택값을 쌓는다.
  진입 시 기존 `CalendarFormat`/확장 상태를 저장하고 월 확장 보기를 활성화하며, 입력 중에는
  확장/축소 드래그를 잠근다. 완료/취소 시 기존 달력 형식과 확장 상태를 복구한다.
  선택일의 원형 버튼에서 근무 타입을 누르면 다음 날로 자동 이동하고, 근무 설정 카드 내부 `완료` 버튼을
  눌렀을 때 변경된 항목만 `WorkShiftService.batchUpsertWorkShifts()`로 저장한다.
- 로그인/로그아웃으로 계정이 바뀌면 근무 타입, 근무 템플릿 설정, 친구, 알림 Provider 캐시를 무효화한다.

### 개인 일정 생성/표시 흐름

```
CalendarPage
  → PersonalEventFormModal
  → CalendarService.createEvent()
  → POST /api/v1/events
  → EventApiModel
  → 선택 날짜 일정 목록에 즉시 반영
```

- 메인 캘린더 선택일 카드는 일정 수에 맞춰 높이가 줄어들고, 일정이 가용 높이를 넘을 때만 목록을
  내부 스크롤한다. `일정 추가하기...`는 목록 바로 다음의 구분선 없는 primary 인셋 액션으로 표시하며
  개인 일정 추가 모달을 띄운다.
- 선택일의 근무 일정은 왼쪽 스와이프로 삭제한다. `Dismissible.onUpdate.progress`와 항목 너비로
  현재 노출 폭을 계산하고, 그 폭 자체를 가진 12px radius 삭제 배경을 오른쪽 정렬해 부분 스와이프
  중에도 노출 영역의 양쪽 모서리가 둥글게 보이게 한다. 삭제 API는 기존처럼 `confirmDismiss`에서
  호출하며 실패 시 항목을 원래 위치로 복원한다.
- 입력 필수값은 `title`, `all_day`, `start_at`, `end_at`, `visibility_level`이다.
- 선택값은 `place`, `memo`이며, 빈 문자열은 요청에서 제외한다.
- `owner_user_id`, `created_by_user_id`는 서버가 인증 사용자 기준으로 채운다.
- 프론트는 로컬 `DateTime`을 UTC ISO 문자열로 변환해 요청하고, 응답의 `start_at`/`end_at`은 로컬 시간으로 파싱해 표시한다.
- 종일 일정은 `end_at`을 배타적 종료 시각으로 사용한다. 하루짜리 종일 일정은 선택일 00:00부터 다음 날 00:00까지로 저장한다.
- 공개 판단은 서버 책임이다. 내 일정을 친구가 볼 때 서버는 `friend_level_settings.owner_user_id = 내 user_id`,
  `friend_level_settings.friend_user_id = 조회자 user_id`, `can_view=true`,
  `friend_level >= events.visibility_level` 조건을 적용한다.
- API 서버 요청 문서는 `_docs/EVENT_API_GUIDE.md`에 둔다.
- 파일 역할/의존성/사용 예:
  - `lib/features/calendar/presentation/widgets/personal_event_form_modal.dart`:
    개인 일정 입력 모달. `CalendarPage`에서 `showCupertinoModalPopup`으로 호출하고
    저장 시 `CreateEventRequest`를 반환한다. 모달은 전체 화면 고정 높이로 표시하고,
    키보드 표시 시 모달 자체를 리사이즈하지 않는다. 리스트가 맨 위에 있을 때 아래로
    스와이프하면 닫힌다. 기본 정보/일시/공개 설정은 디자인 시안 기반 카드형 섹션으로
    구성한다. 장소 행은 선택 시 입력 다이얼로그를 띄워 `place` 값을 편집하고, 반복 행은
    현재 API 미지원으로 `안 함` 고정 안내만 제공한다. 공개 레벨은 0~5 세그먼트 트랙에서
    탭 또는 좌우 드래그로 선택한다. 시작일/종료일은 공용 `DatePickerSheet`, 시작시간/종료시간은
    공용 `TimePickerSheet`에서 선택한다. 날짜 선택 결과가 기존 반대편 날짜를 넘어가면 시작일과
    종료일의 선후 관계를 자동 보정하며, 시간은 기존 `Duration` 상태와 저장 검증 흐름을 유지한다.
  - `_docs/EVENT_API_GUIDE.md`: 개인 일정 생성 API, 입력 필수/선택값,
    공개 레벨 규칙, 서버 DDL 확인 요청을 정리한 서버 구현 문서다.

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
  고정하고, 750px 이상에서는 월 보기와 56px 행을 사용한다. 근무 코드 배지, 흰색 surface 배경과
  2px primary dark outline 선택 사각형, 오늘 밑줄을 사용하며 일요일은 accent red, 토요일은
  primary blue로 표시한다. 선택 후에도 해당 요일 의미 색상을 유지한다. 달력 내부에는
  `CalendarStyle.tablePadding`으로 8px 하단 여유를 두어 `PageView`가 마지막 행의 4px offset 선택
  사각형까지 포함하도록 한다. 일정 카드 앞에는 별도 8px 간격을 두어 달력 표 본문부터 카드까지
  총 16px을 확보한다.
- 선택일 일정 카드는 메인 캘린더와 같은 날짜 헤더, 일정 수, 근무/개인 일정 항목, 빈 상태 표현을
  사용한다. 친구 일정은 읽기 전용이므로 일정 추가와 스와이프 삭제 액션은 제공하지 않는다.
  카드 아래에는 시스템 하단 안전영역과 최소 16px 여백을 적용해 화면 바닥 및 홈 인디케이터와
  맞닿지 않게 한다.
- `FriendDetailPage`에서 친구 삭제가 성공하면 `Navigator.pop(true)`로 삭제 결과를
  `FriendCalendarPage`에 반환하고, `FriendCalendarPage`가 자기 자신을 닫아 친구 리스트로
  복귀한다.
- `FriendDetailPage`의 친구 레벨/캘린더 공유 토글은 화면 안에서 먼저 변경하고, 상단 `Save`를
  눌렀을 때 기존 `PUT /api/v1/friends/:friend_user_id/settings` API로 `friend_level`과
  `can_view`를 함께 저장한다. 저장 전 뒤로가기는 변경값을 폐기한다.
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
    화면 높이별 2주/월 읽기 전용 달력 및 선택일 일정 카드를 표시한다. `FriendService`의 공개
    필터링 결과를 `WorkShiftApiModel`/`EventApiModel`로 렌더링하고 공용 `YearMonthPickerSheet`를 사용한다.
  - `test/features/friend/presentation/pages/friend_calendar_page_test.dart`: 가짜 `FriendService`로
    명시적 `MediaQuery` 높이 740px에서 2주 보기 고정, 750px에서 월 보기 유지 여부를 검증한다.
    390x800 월 보기에서는 중복 프로필 제거, 선택된 토요일/일요일의 의미 색상, surface 배경·2px
    primary dark outline 사각형 선택 표시, 근무 시간 포맷,
    마지막 행 선택 사각형이 달력 경계 안에 포함되는지, 달력과 선택일 일정 카드 사이 및 카드 하단의
    최소 16px 여백, 3개월 뒤에서 오늘로 복귀할 때 빌드 중 setState 예외가 없는지와 연/월 이동
    시트 노출을 검증한다.

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
  `payload.related_user_id`와 일치하는 친구를 찾아 `FriendCalendarPage`로 이동한다.
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

- DB 문서상 `shift_types.color`는 Flutter `Color` 정수값(`0xAARRGGBB`) 기준이다.
- 실제 API 응답은 정수 또는 문자열(`#AARRGGBB`, `#RRGGBB`, `0xAARRGGBB`, 10진수 문자열)로 들어올 수 있다.
- 클라이언트는 `lib/core/utils/color_parser.dart`의 `parseApiColorValue()`로 응답 색상을 정규화한다.
- 서버의 근무 타입 생성/수정 validation은 `color` 요청값을 `#AARRGGBB` 문자열로 요구한다.
  `CreateShiftTypeRequest`와 `UpdateShiftTypeRequest`는 `formatApiColorValue()`를 사용해
  Flutter `Color` 정수값을 요청용 문자열로 변환한 뒤 전송한다.
- 사용 예: `ShiftTypeApiModel.color`, `WorkShiftApiModel.shiftTypeColor` 파싱 시 `parseApiColorValue()`를,
  근무 타입 생성/수정 요청 직렬화 시 `formatApiColorValue()`를 공통 사용한다.

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
