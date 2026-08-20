# 프로젝트 컨텍스트

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
    같은 16px 수평·8px 수직 padding, 28px 콘텐츠 슬롯, 날짜/공휴일 타이포와 0.5px 하단
    구분선을 사용해 그룹 선택일 헤더와 동일한 44.5px 실측 높이를 유지한다. 선택일은
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
  - `lib/features/calendar/presentation/widgets/bottom_action_bar.dart`: 공용 하단 footer.
    기본 메인/근무 추가 구성에서는 친구·시간, 오늘, 알림 이동 액션과 미읽음 알림 배지를
    표시한다. 화면이 `BottomActionBarItem` 목록을 주입하면 같은 surface·상단 outline·pill
    스타일로 화면 전용 액션과 선택 상태를 표시하며, 친구 탭은 이 방식으로 친구 리스트와
    그룹 방을 전환한다.
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
    `../design/shift_type-setting/code.html` 시안과 친구 설정 화면의 컴팩트한 구조를 기준으로
    좌측 화살표/중앙 제목/우측 `완료` 내비게이션, 원형 코드 미리보기, 색상 변경 pill,
    코드·이름 카드와 근무 시간 카드를 표시한다. 앱 설정 화면의 `_settings_scale = 0.8`과
    같은 본문 배율을 사용해 상단 내비게이션 바는 공통 치수를 유지하고, 미리보기는 76.8px,
    코드·이름 및 시간 행은 44.8px, 본문 기본 글자는 12.8px로 표시한다. 카드 반경·아이콘·
    내부 간격·안내 문구도 같은 비율로 축소한다. 코드는 최대 3자와 대문자로 제한하고 입력값을
    원형 미리보기에 즉시 반영한다. 대문자 변환은 컨트롤러 값을 입력 중 다시 쓰지 않고
    `TextInputFormatter`에서 처리해 키보드 입력 연결과 포커스를 유지한다. 입력 중에는 중복
    UI를 표시하지 않으며, 키보드 완료 액션이나 다른 영역 이동으로 코드 필드의 포커스가
    빠진 뒤 호출 화면이 전달한 현재 템플릿의 `existingTypes`와 대소문자 구분 없이 비교한다.
    편집 중인 타입 자체는 비교에서 제외한다. 입력 완료된 코드가 중복이면
    코드 입력 글자색은 기본 본문 색상으로 유지하고 코드 입력 행의 영역 테두리와
    `이미 사용 중인 코드입니다.` 안내를 accent red로 표시한다. 이때 `완료`를 비활성화하며,
    코드 필드에 다시 포커스를 두는 것만으로 오류 UI를 갱신하지 않아 첫 탭에 키보드 입력 연결을
    복원한다. 사용자가 코드를 실제로 수정하면 기존 테두리·안내를 제거하고 다음 편집 완료 시점에
    다시 검사한다. 중복 상태는 `ValueNotifier`로 관리하되 코드 `CupertinoTextField`는 안정적인
    자식으로 계속 마운트하고, 오류 테두리는 입력 필드와 분리된 포인터 비활성 오버레이로 그려
    오류 UI 변경 중에도 `EditableText`의 플랫폼 입력 연결을 유지한다.
    이 검사는 로컬 사전 검증이고 최종 저장 시 기존 검증과 서버 `DUPLICATE_CODE` 처리는 유지한다.
    색상 변경은 `ShiftColorPickerPage`를 전체 화면으로 열고,
    사용자가 `적용`으로 반환한 최종 색상·기준 색상·정수 농도를 폼 상태에 함께 반영한다.
    편집 진입 시 `ShiftTypeApiModel.baseColor`와 `colorIntensity`를 선택 화면 초기값으로 전달해
    저장된 농도를 복원한다. 생성 요청은 `base_color`·`color_intensity`를 항상 함께 보내고,
    편집에서 색상을 적용하지 않았다면 두 필드를 모두 생략해 기존 서버 값을 유지한다.
    시작·종료 시간 동시 유무 검증과 시간 요청 계약은 유지한다. 설정된 시간 옆 삭제
    액션은 18px `CupertinoIcons.xmark_circle_fill`과 accent red를 사용하며 누른 행의 시간만 비운다.
    한쪽 시간만 남은 중간 편집 상태는 허용하지만 완료 시에는 기존 동시 유무 검증으로 저장을 막는다.
    삭제 버튼의 36px 슬롯·18px 아이콘·12px 외부 여백에서 계산한
    21px 우측 시각 inset을 코드·이름 입력과 아이콘 없는 시간 선택 텍스트에도 적용해 모든 우측
    콘텐츠의 끝을 같은 세로선에 맞춘다.
    원형 코드 미리보기의 글자색은 선택 근무 색상과의 대비율로 정해, 색상 농도를 낮춰 배경이
    surface에 가까워져도 코드가 함께 옅어져 보이지 않게 한다.
    코드·이름 입력은 각각 전용 `FocusNode`를 사용하며 처음 포커스를 받을 때 기존 텍스트의
    끝으로 커서를 이동한다. 키보드의 완료 액션은 코드→이름→시작 시간 순으로 이동하고,
    시작 시간 시트에서 `선택한 시간 적용`을 누르면 종료 시간 시트를 연다. 종료 시간 적용 후에는
    텍스트 포커스를 남기지 않는다. 시간 시트 취소 시에는 다음 단계로 자동 이동하지 않는다.
    폼 본문 바깥을 터치하거나 스크롤하면 현재 텍스트 포커스를 해제해 키보드를 닫는다.
    `CupertinoPageRoute`로 진입하며, 본문은 `SafeArea(bottom: false)`와 내부 bottom padding을
    함께 사용해 안내 문구가 홈 인디케이터/화면 끝에 붙어 잘려 보이지 않게 한다. 시작·종료 시간은
    개인 일정과 같은 공용 `TimePickerSheet`를 열며, 기존 `TimeOfDay` 폼 상태와 시트의 `Duration`
    결과를 변환해 `HH:mm:ss` API 요청 계약을 유지한다.
  - `lib/features/calendar/presentation/widgets/shift_color_picker_page.dart`: 근무 타입 색상 선택 화면.
    `../design/shift-color-pick/code.html` 시안을 Cupertino 구조로 구현한다. 상단 내비게이션 바는
    커스텀 색상 선택 화면과 동일한 좌측 화살표/중앙 제목/우측 `적용` 조합을 사용하고,
    앱 설정·근무 타입 편집 화면과 같은 `_body_scale = 0.8`을 적용해 76.8px 선택 색상 미리보기,
    41.6px 프리셋 원과 축소된 HEX·색상명·카드·간격·슬라이더를 표시한다. 본문은 12개 프리셋,
    색상 농도 카드, 커스텀 색상 버튼 순서로 구성하며 프리셋 제목 옆 별도 개수 안내는 표시하지
    않는다. 커스텀 색상 버튼은
    `ShiftCustomColorPickerPage`를 전체 화면으로 연다. 프리셋 행과 커스텀 버튼은 최소 44px
    터치 영역을 유지한다. 프리셋 또는 커스텀 색상을 화면 내부 상태로만 편집하고, 좌측 화살표는
    값을 반환하지 않으며 우측 `적용`만 `ShiftColorSelection`의 최종 색상·기준 색상·정수 농도를
    호출 화면으로 반환한다. 상단 미리보기는
    공용 surface·outline·radius 카드 안에서 별도 편집 배지 없이 선택 색상 원을 왼쪽에 두고,
    세로 구분선 오른쪽 정보 열에 `선택한 색상` 안내·색상명·HEX pill을 배치한다. 색상명은
    디자인 기준 24px, 본문 배율 적용 후 19.2px 고정 슬롯 안에 한 줄로 렌더링해 이름별 폰트
    fallback line metrics가 달라도 프리셋·농도·커스텀 섹션의 Y 좌표가 바뀌지 않게 한다.
    색상 농도는 서버 계약의 고정 흰색 `#FFFFFFFF`와 선택한 기준 색상을 정수 0~100 퍼센트로
    혼합하고 alpha를 항상 1로 고정한다. 각 RGB 채널을 서버와 같은 식으로 반올림해 테마 변경과
    무관하게 최종 색상을 일치시킨다. 0%는 불투명 흰색, 100%는 불투명 원본 색이며 중간값은
    배경이 비치지 않는 옅은 색이다. 농도 카드는 한글 제목·설명, 퍼센트 pill, 양끝 색상 미리보기와 전체 너비
    `CupertinoSlider`를 제공한다. 슬라이더 핸들을 기존처럼 드래그할 수 있고, 트랙의 임의 위치를
    탭하거나 핸들이 없는 위치에서 바로 가로 드래그를 시작해도 해당 농도로 이동한다.
  - `lib/features/calendar/presentation/widgets/shift_custom_color_picker_page.dart`: 커스텀 근무 색상
    선택 전체 화면. `../design/custom-color-pick/code.html` 시안을 Cupertino 구조와 0.8 본문
    밀도로 구현한다. 선택 색상 미리보기·HEX 표시/6자리 입력, `CustomPainter`의 sweep/radial
    gradient 색상 휠, Red/Green/Blue 0~255 슬라이더, 최대 6개 최근 색상 단축 선택을 제공한다.
    휠과 RGB 컨트롤은 같은 카드의 반응형 `Row`에서 휠을 왼쪽, RGB를 오른쪽에 배치한다.
    390px 화면에서 휠은 약 172px이며 최대 176px이고, RGB 슬라이더는 세로만 0.8 배율로 축소해
    우측 열의 가로 폭을 유지한다. 본문 `ListView`에는 `NeverScrollableScrollPhysics`를 적용해
    사용자 세로 드래그에도 최초 위치를 유지한다. HEX 입력과 화면·카드 외부 여백은 기존 위치를
    유지한다.
    색상 휠 좌표는 중심 거리와 각도를 HSV 채도·색조로 변환하고, 모든 입력은 단일
    불투명 `Color` 상태를 통해 미리보기·HEX·RGB·휠 마커에 즉시 동기화한다. `ShiftColorPickerPage`
    가 `CupertinoPageRoute`로 열며, 뒤로가기는 값을 반환하거나 최근 기록을 저장하지 않고 `적용`만
    선택 색상을 반환한다. 완료 색상은 기존 `shared_preferences` 의존성을 사용해
    `shift_custom_recent_colors_v1` 문자열 목록에 6자리 RGB HEX로 저장한다. 최신 색상을 맨 앞에
    두고 중복은 기존 위치에서 제거하며 최대 6개만 유지한다. 진입 시 유효한 값만 복원하고
    중복·잘못된 값·초과 항목은 정규화하며, 기록이 없으면 빈 상태를 표시한다.
  - `test/features/calendar/presentation/widgets/shift_type_form_modal_test.dart`: 근무 타입 편집 화면의
    좌측 화살표/우측 완료 헤더와 본문 80% 치수, 컴팩트 카드 구조와 76.8px 미리보기,
    3자 대문자 코드 동기화와 조합 입력 중 컨트롤러 미재할당, 신규·수정 코드가 기존 코드
    접두어와 같아지는 입력 중에도 중복 UI를 표시하지 않고 포커스·키보드 입력 연결을 유지하는지,
    편집 대상 자체를 제외한 대소문자 무관 코드 중복을 입력 완료 후 기본 글자색과 accent red
    테두리로 표시하고 완료를 비활성화하는지, 중복 표시 상태에서 키보드를 닫은 뒤 코드 필드를
    처음 탭해도 키보드가 열리고 실제 코드 수정 후에도 입력 연결이 유지되는지,
    코드·이름·시간 선택·삭제 아이콘의 우측 좌표 일치, 시간 개별 삭제,
    코드→이름→시작 시간→종료 시간 포커스 이동, 최초 포커스의 커서 끝 이동, 본문 터치 키보드 닫기,
    옅은 근무 색상 미리보기의 어두운 코드 전경색, 저장된 기준 색상·50% 농도 복원,
    색상 적용 후 메타데이터 수정 요청, 색상 무변경 편집의 필드 생략, 생성 요청의 기본
    기준 색상·100% 농도와 뒤로가기 폐기 계약, 기존 액션 시트 대신 전체 화면 색상 선택 페이지로
    진입하고 선택값을 반영하는 흐름을 검증한다.
  - `test/features/calendar/presentation/providers/shift_template_settings_provider_test.dart`:
    근무 타입 수정 요청이 진행되는 동안 설정 상태를 공용 로딩으로 전환하지 않는지, 서버 PUT 응답
    모델을 설정 목록에 그대로 반영하는지, 같은 응답을 기존 `shiftTypesProvider` GET 캐시 위에
    합성해 근무 입력용 표시 목록을 갱신하는지 검증한다. 가짜 템플릿/근무 타입 서비스를 주입해
    실제 네트워크 없이 Provider 상태 전이를 재현한다.
  - `test/features/calendar/presentation/widgets/shift_color_picker_page_test.dart`: 색상 선택 화면의
    좌측 화살표/우측 적용 헤더와 본문 80% 치수, surface 카드 안의 선택 원→구분선→색상명/HEX
    좌우 좌표·정보 세로 순서와 편집 아이콘 미노출, 프리셋→색상 농도→커스텀 순서와 프리셋
    개수 문구 미노출, 모든 프리셋의
    색상명 슬롯 높이·스크롤 오프셋·각 섹션 Y 좌표 불변,
    고정 흰색 혼합의 0·50·100% 계산, 저장된 기준 색상·농도 초기 복원,
    농도 트랙 탭·임의 위치 드래그 이동, 적용 시 최종 색상·기준 색상·농도 반환과
    뒤로가기 폐기, 전체 화면 커스텀 색상 적용을 검증한다.
  - `test/features/calendar/presentation/widgets/shift_custom_color_picker_page_test.dart`: 커스텀 색상
    화면의 80% 치수와 사용자 세로 드래그 차단, 같은 카드 안의 휠 왼쪽·RGB 오른쪽 좌표 관계와 RGB
    슬라이더의 가로 1.0/세로 0.8 배율, HEX·RGB·색상 휠·최근 색상 간 동기화, 완료 색상
    반환과 뒤로가기 폐기, 로컬 최근 색상의 빈 상태·복원·최신순 저장·중복 제거·6개 상한을 검증한다.
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
    실제 구현된 항목은 `ShiftTemplateSettingsPage`로 이동하는 근무 패턴 설정,
    로그아웃, 회원 탈퇴이다. 회원 탈퇴는 로그아웃 아래의 별도 destructive 액션으로 노출하고,
    일정·근무표·친구·그룹 정보 삭제와 복구 불가를 최종 확인한 뒤만 요청한다.
    요청 중에는 로그아웃과 탈퇴 버튼을 모두 비활성화해 중복 요청을 막는다.
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
- schema v1과 `destination=NOTIFICATIONS`만 수용하고 모든 탭은 세부 화면 대신 `NotificationPage`로 이동합니다.
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
  직종·소속·프로필 이미지는 선택이다. 타임존 행은 노출하지 않고 `flutter_timezone`으로 조회한
  기기 IANA timezone을 시스템 필드로 전송한다. 조회 실패 시 서버 사용자 값 또는 앱 기본값을 쓴다.
- 가입 화면의 아바타를 누르면 `image_picker`로 사진 한 장을 선택한다. 앱은 최대 1024x1024,
  품질 85로 요청하고 5MB 초과 결과는 전송하지 않는다. 이미지를 선택하지 않으면 기존 JSON,
  선택하면 텍스트 필드와 `profile_image` 파일을 포함한 multipart 요청을 같은 완료 endpoint로 보낸다.
  서버 object storage 계약과 선배포 조건은 `_docs/PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md`를 따른다.
- 서버 응답의 `requires_profile_setup`을 가입 화면 분기의 정본으로 사용한다. 서버 전환기에는
  해당 필드가 없을 때만 휴대폰 유무로 미완료를 판단해, 앱 종료·재실행 후에도 입력 화면을
  재개한다. OAuth의 `is_new_user`는 계정 생성 여부를 위한 호환 필드다.
- `../design/signup input personal data/code.html`은 프로필 설정의 UI/UX 검토용 HTML 시안이다.
  기본 정보는 `필수` 배지와 필수 표시를 사용하고, 근무 정보는 `선택` 배지 및
  `지금 입력하지 않아도 괜찮아요` 안내를 항상 노출한다. 선택 근무 정보가 비어 있어도
  하단의 단일 `저장하고 시작하기` 동작을 막지 않는다. Flutter 화면과 클라이언트 계약은 구현됐고,
  서버의 DB/API/응답 변경과 선배포 조건은 `_docs/PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md`를
  정본으로 따른다.
- 파일 역할/의존성/사용 예:
  - `lib/features/auth/data/datasources/auth_remote_datasource.dart`: 카카오 SDK 로그인,
    서버 토큰 교환, 프로필 조회·수정과 로그아웃 HTTP 요청을 담당한다.
    신규 사용자 프로필 완료 시 `completeProfile()`이 전용 POST 요청을 보낸다.
  - `lib/features/auth/presentation/pages/profile_setup_page.dart`: 필수 기본 정보와 선택 근무 정보를
    분리하고, 프로필 이미지 선택·미리보기와 기기 timezone 자동 조회 후 가입 완료 API를 호출한다.
  - `lib/features/auth/domain/entities/profile_image_upload.dart`: 선택 이미지의 byte, 파일명, MIME type을
    data 계층까지 전달한다. datasource가 multipart의 `profile_image` part로 변환한다.
  - `test/features/auth/data/datasources/auth_remote_datasource_test.dart`:
    실제 네트워크 대신 Dio 인터셉터로 요청을 가로챈다. 카카오·네이버 SDK Access Token과 Google
    ID Token이 각 `/auth/kakao/token`, `/auth/naver/token`, `/auth/google/token` 요청의 정확한 필드로 전달되는지,
    Google 응답의 `google_id`와 millisecond `expires_at`, 프로필 수정·가입 완료의 POST
    메서드·경로·선택값 생략·응답 파싱을 검증한다. 카카오 App ID 불일치 응답과 프로필 구조화
    오류의 코드·메시지·request ID 보존도 검증한다.
  - `test/features/auth/presentation/pages/profile_setup_page_test.dart`: 390x844 화면에서 필수·선택
    위계, 단일 CTA, 필수 검증과 선택값 생략/전달을 검증한다.
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
- Google은 현재 사용자의 `google_id`가 있을 때 `GoogleSignIn.disconnect()`를 호출한다.
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
- `AuthResponse`는 `data.is_new_user` boolean을 우선 파싱하고 기존 서버 메시지 판정은 하위 호환
  fallback으로만 유지한다.
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

### 개인 일정 생성/표시 흐름

```
CalendarPage
  → PersonalEventFormModal
  → CalendarService.createEvent()
  → POST /api/v1/events
  → EventApiModel
  → 선택 날짜 일정 목록에 즉시 반영
```

- 메인 캘린더 선택일 카드는 달력 아래 남은 `Expanded` 하단 슬롯을 채운다. 일정이 가용 높이를
  넘을 때만 목록을 내부 스크롤한다. `일정 추가하기...`는 카드 하단의 구분선 없는 primary 인셋
  액션으로 표시하며 개인 일정 추가 모달을 띄운다.
- 선택일 카드의 공휴일명은 날짜 아래에 별도 줄을 만들지 않고 날짜 오른쪽 하단에 한 줄 accent red
  라벨로 표시한다. 공휴일명이 길면 말줄임해 오른쪽 일정 수를 유지하며, 공휴일 유무와 관계없이
  날짜·일정 수 헤더 높이는 동일하게 유지한다.
- 선택일의 근무 일정은 왼쪽 스와이프로 삭제한다. `Dismissible.onUpdate.progress`와 항목 너비로
  현재 노출 폭을 계산하고, 그 폭 자체를 가진 12px radius 삭제 배경을 오른쪽 정렬해 부분 스와이프
  중에도 노출 영역의 양쪽 모서리가 둥글게 보이게 한다. 삭제 API는 기존처럼 `confirmDismiss`에서
  호출하며 실패 시 항목을 원래 위치로 복원한다.
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
  - 근무 타입 기준 색상·농도 영속화 계획:
    `_docs/SHIFT_TYPE_COLOR_METADATA_API_GUIDE.md`
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
  - `_docs/SHIFT_TYPE_COLOR_METADATA_API_GUIDE.md`: 근무 타입 색상 설정의 기준 색상과
    농도를 재진입 시 복원하기 위한 API 계약, Express 변경 지점, PostgreSQL
    expand/backfill/enforce migration, 배포·검증·롤백 순서를 정리한 구현 전 계획 문서다.
    현재 서버 저장소의 모델·route·controller·service와 migration 운영 규칙에 의존하며,
    서버·Flutter 구현 및 실제 DB 적용 전 계약 검토에 사용한다.
  - `test/features/calendar/data/models/event_api_model_test.dart`: 일정 날짜별 매핑의 자정
    배타적 종료 처리와 일정 ID 중복 제거·시작 시각 정렬을 검증한다.

### 친구 추가 검색 흐름

```
FriendListPage
  → AddFriendModal
  → SearchUserNotifier.searchUser()
  → FriendService.searchUser()
  → GET /api/v1/users/search?query=...
```

- 친구 추가 모달의 검색창과 검색 버튼은 하나의 `TapRegion`으로 묶는다. 검색창 밖의 모달 영역을
  터치하면 검색 `FocusNode`를 해제해 가상 키보드를 닫고, 검색창이나 검색 버튼 내부 터치는 기존
  입력·검색 동작을 유지한다.
- 상단 헤더 높이는 `AddFriendModal`의 `_headerHeight` 단일 상수로 관리하며, 드래그 핸들을 포함해
  66px을 사용한다. 취소 액션은 `body_medium` 14px/w600, 중앙 제목은 `body_large` 16px/w700을
  적용하고 44px 최소 터치 영역을 유지한다. 제목은 왼쪽 액션 너비와 무관하게 시트 정중앙에 배치한다.
- 로컬 입력 검증 말풍선은 검색 행을 `CompositedTransformTarget`으로 삼고 모달 최상위 `Stack`의
  `CompositedTransformFollower`로 그린다. 말풍선은 검색/결과 `Column`의 높이에 포함되지 않으므로
  표시 전후에 검색 전·오류·결과 없음 안내와 검색 결과 카드의 위치가 바뀌지 않는다.
- 시트 높이는 사용자가 선택한 높이와 `화면 높이 - 키보드 높이 - 상단 8% 여백` 중 작은 값으로
  제한한다. `MediaQuery.viewInsets.bottom`이 제공하는 키보드 전환 프레임은 추가 보간 없이 직접
  반영해 키보드가 닫히는 동안 시트가 최대 높이로 팽창했다가 기본 높이로 축소되지 않게 한다.
- 검색 전·오류·결과 없음 안내는 가용 결과 영역 안에서 중앙 정렬하되, 큰 텍스트나 큰 키보드로
  콘텐츠 높이가 영역을 넘으면 내부 스크롤을 허용해 `RenderFlex` 오버플로를 방지한다.
- 검색 성공 시 단일 사용자 카드는 고정 높이나 최소 높이를 사용하지 않는다. 프로필 행, 공용 간격,
  친구 관계 상태 또는 친구 요청 버튼과 카드 내부 패딩의 실제 높이에 따라 세로 크기를 결정하고,
  결과 영역보다 커지는 경우 바깥 `SingleChildScrollView`가 스크롤을 담당한다.
- 파일 역할/의존성/사용 예:
  - `lib/features/friend/presentation/widgets/add_friend_modal.dart`: 이메일/전화번호 입력 검증과
    정규화, 단일 사용자 검색 결과, 친구 요청 액션, 드래그 가능한 시트와 키보드 포커스/높이 대응을
    담당한다. `FriendListPage`가 `showCupertinoModalPopup`으로 표시한다.
  - `test/features/friend/presentation/widgets/add_friend_modal_test.dart`: 큰 키보드·확대 텍스트에서
    안내 영역이 넘치지 않는지, 검색창 밖 터치로 포커스가 해제되는지, 키보드 닫힘 중 시트 목표
    높이가 기본 높이를 초과하지 않는지와 검색 결과 카드가 내부 요소 높이로 축소되는지 검증한다.

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

### 친구·그룹 방 footer, 실제 그룹 API와 미리보기 fallback

```
FriendListPage footer
  → 친구 리스트 | 그룹 방 리스트
  → GROUP_API_ENABLED=true: GroupRoomListView → GroupCalendarPage
  → GROUP_API_ENABLED=false: `우리 병동` 카드 → GroupCalendarPreviewPage
```

- 친구 탭은 메인 화면과 같은 `BottomActionBar`를 화면 하단에 고정하고 `친구 리스트`,
  `그룹 방` 두 항목을 표시한다. 선택 항목은 8% primary tint, primary dark outline과
  굵은 텍스트로 구분한다.
- `친구 리스트`를 선택하면 기존 API 기반 친구 목록·새로고침·빈 상태·친구 추가 액션을
  그대로 사용한다. `그룹 방`을 선택하면 내비게이션 제목을 `그룹 방`으로 바꾸고 친구 추가
  액션을 숨긴 뒤, 본문의 중복 `그룹 방` 제목 없이 현재 더미 데이터에 대응하는 `우리 병동`
  카드와 4명 겹침 아바타를 바로 표시한다. 친구 목록 상단의 기존 그룹 미리보기 아이콘은
  footer/목록 경로로 대체한다.
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
    친구 목록과 그룹 방 목록을 페이지 내부 상태로 전환한다. 공용 `BottomActionBar`에
    `BottomActionBarItem` 두 개를 주입한다. 그룹 API 플래그가 켜지면 실제 목록·받은 초대·생성
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
    개인 일정 순서, 월/2주 반응형 렌더링, 0명 날짜의 휴무 상세, footer의 친구/그룹 방 양방향
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

### 푸시 수신 파일과 상태 규칙

- `lib/core/push/firebase_environment_options.dart`: Debug Stage/Profile·Release Production 옵션 선택
- `lib/core/push/installation_id_service.dart`: secure storage 설치 UUID 생성·검증·재사용
- `lib/core/push/device_remote_datasource.dart`: 인증 기기 API와 safe response parsing
- `lib/core/push/push_coordinator.dart`: 권한, APNs/FCM token, lifecycle, local banner, persistent dedupe
- `lib/core/push/push_providers.dart`: Riverpod coordinator와 pending navigation 상태
- UI state는 `pendingPushNotificationNavigationProvider`가 소유하고, 서버 알림 domain state와 미읽음 개수는 기존 `notificationProvider`가 소유합니다.
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
