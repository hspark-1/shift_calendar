# 아키텍처 결정사항

## ADR-0001: 메인 캘린더 근무표 표시는 CalendarRange 응답 스냅샷을 사용

- 배경(문제)
  - 메인 캘린더가 `/calendar/range` 응답의 `shift_type_color`, `shift_type_name`, `start_time`, `end_time`을 받지만, 실제 화면 표시에서는 `shiftTypesProvider`의 코드별 캐시를 다시 참조하고 있었다.
  - 다른 계정 사용 후 로그인하면 이전 계정의 근무 타입 캐시가 남아, 서버 응답과 다른 색상/이름/시간으로 근무표가 표시될 수 있었다.
- 선택지(대안)
  - A. 계정 전환 시 `shiftTypesProvider`만 무효화하고 기존 표시 구조 유지
  - B. 메인 캘린더 저장 근무표 표시는 `WorkShiftApiModel` 응답 스냅샷을 직접 사용하고, `shiftTypesProvider`는 입력/설정용으로 제한
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - `/calendar/range`의 `work_shifts`는 저장된 근무표를 화면에 표시하기 위한 완성 데이터다.
  - 저장된 근무표 표시에 현재 템플릿 Provider를 다시 적용하면 계정 캐시, 템플릿 변경, 과거 스냅샷 표시에서 불일치가 생긴다.
  - 근무 입력 버튼과 근무 타입 설정 화면은 현재 계정의 최신 타입 목록이 필요하므로 `shiftTypesProvider`를 유지한다.
- 결과/영향(좋은 점/트레이드오프)
  - 메인 달력의 저장된 근무표 색상/이름/시간은 서버 응답과 일치한다.
  - 근무 추가 모드의 임시 선택 표시는 계속 `shiftTypesProvider`를 사용한다.
  - 로그인/로그아웃 시 계정 단위 Provider 캐시를 무효화해 입력/설정 화면의 stale cache 가능성도 줄인다.
- 추후 과제(언제 다시 평가)
  - 서버가 `/calendar/range`에서 근무 타입 표시 필드를 제거하거나, 클라이언트 캐시 키를 사용자 단위로 구조화할 때 재평가한다.

## ADR-0002: 개인 일정 생성은 기존 events 스키마와 공개 레벨 필드를 사용

- 배경(문제)
  - 메인 캘린더의 `일정 추가하기`가 placeholder 상태였고, 개인 일정 생성 화면과 서버 API 계약이 필요했다.
  - 최종 DB DDL에는 이미 `events.title`, `memo`, `place`, `all_day`, `start_at`, `end_at`, `visibility_level`이 정의되어 있다.
- 선택지(대안)
  - A. 일정 카테고리/색상 등 신규 컬럼을 추가해 더 풍부한 입력 화면을 만든다.
  - B. 현재 최종 DDL의 `events` 컬럼만 사용해 생성 화면과 API 계약을 먼저 고정한다.
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - 사용자가 요청한 개인 일정 추가에 필요한 최소 정보는 기존 `events` 스키마로 충족된다.
  - 공개 범위는 이미 `events.visibility_level`과 `friend_level_settings.friend_level` 비교로 정의되어 있어 신규 ACL 테이블이 필요 없다.
  - 미확정 필드를 먼저 추가하면 서버 DDL, API, 화면이 동시에 흔들릴 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - 프론트는 `POST /api/v1/events`로 기존 스키마에 맞는 요청을 보낸다.
  - 서버는 인증 사용자로 `owner_user_id`, `created_by_user_id`를 채운다.
  - `start_at`/`end_at`은 UTC 저장, 프론트 로컬 표시를 기준으로 한다.
  - 종일 일정은 `end_at`을 배타적 종료 시각으로 해석한다.
  - 일정별 색상/카테고리는 이번 범위에 포함하지 않는다.
- 추후 과제(언제 다시 평가)
  - 일정 색상, 반복 일정, 알림, 참석자, 카테고리 요구사항이 확정되면 `events` 확장 ADR을 별도로 작성한다.

## ADR-0003: Shift Harmony 디자인은 Cupertino 구조 안에서 공용 토큰으로 적용

- 배경(문제)
  - 디자인 문서의 Shift Harmony 색상/표면/반경 기준과 기존 Flutter 화면의 `CupertinoColors.systemBlue`,
    `systemGroupedBackground`, 파일별 흰색 카드/그림자 스타일이 섞여 있었다.
  - 개인 일정 모달, 캘린더, 친구, 알림, 근무 설정 화면이 서로 다른 카드 반경과 보조색을 사용해
    같은 앱 안에서 화면 톤이 달라 보였다.
- 선택지(대안)
  - A. 화면별로 필요한 색상만 직접 수정하고 기존 하드코딩을 유지한다.
  - B. `AppTheme`에 Shift Harmony 토큰을 중앙화하고, 기존 Cupertino 화면 구조는 유지한 채
    페이지/위젯이 공용 토큰을 참조하도록 바꾼다.
  - C. Material 3 기반으로 앱 전체를 재작성한다.
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - 프로젝트 문서와 기존 구현은 Cupertino 기반이며, 라우팅/상태/API 흐름을 바꾸지 않고 시각 언어만 통일하는 것이 이번 요청 범위에 맞다.
  - 공용 토큰을 사용하면 이후 화면 추가 시 배경, 카드, outline, primary 색상 기준을 재사용할 수 있다.
  - Material 3 전환은 컴포넌트, 네비게이션, 테스트 범위가 커져 현재 디자인 통일 작업의 리스크를 키운다.
- 결과/영향(좋은 점/트레이드오프)
  - `AppTheme`가 `#F8F9FB` 배경, `#0061A4` primary, surface/outline/text/radius 토큰과 `cardDecoration()`을 제공한다.
  - 캘린더, 친구, 알림, 근무 관련 화면은 흰색 surface + 얇은 outline + 16px 카드 반경을 기본으로 맞춘다.
  - 근무 타입 색상, 공휴일, 성공/오류/소셜 로그인 색상은 의미 색상으로 유지한다.
  - 현재 프로젝트의 snake_case 네이밍 규칙과 Flutter analyzer의 lowerCamelCase lint는 계속 충돌할 수 있다.
- 추후 과제(언제 다시 평가)
  - 실제 기기 확인 후 카드 반경을 8px로 낮출지, 16px를 유지할지 디자인 문서 간 차이를 정리한다.
  - Plus Jakarta Sans/Inter 폰트 asset을 프로젝트에 포함할지 결정한다.

## ADR-0004: 750px 미만 메인·친구 캘린더는 2주 보기로 고정

- 배경(문제)
  - 메인 캘린더와 친구 캘린더는 화면 높이 750px 미만에서 행 높이만 52px로 줄이고 월 형식은 그대로 표시했다.
  - 작은 화면에서 월 전체와 선택일 일정 영역을 함께 배치하면 일정 영역의 세로 공간이 제한된다.
- 선택지(대안)
  - A. 월 형식을 유지하고 행 높이와 내부 컴포넌트를 더 축소한다.
  - B. 두 캘린더 모두 화면 높이 750px 미만에서는 2주 형식을 고정하고, 750px 이상에서는 각 화면의 기존 형식을 사용한다.
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - 기존 코드가 이미 반응형 행 높이의 경계값으로 750px을 사용하므로 같은 기준을 형식 선택에도 적용할 수 있다.
  - `TableCalendar.calendarFormat`에 반응형 형식을 전달하면 데이터 조회나 날짜 선택 흐름을 바꾸지 않고 표시 주수만 제한할 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - 750px 미만에서는 메인 캘린더의 일반/compact/근무 추가 상태와 친구 캘린더가 모두 2주 형식을 유지한다.
  - 750px 이상에서 메인 캘린더는 기존 `_calendar_format` 상태에 따라 월/2주/주 형식을 사용하고,
    친구 캘린더는 기존 월 형식을 사용한다.
  - 작은 화면에서는 한 화면에서 월 전체를 동시에 볼 수 없으며 좌우 스와이프로 기간을 이동한다.
- 추후 과제(언제 다시 평가)
  - 실제 기기에서 2주 달력과 선택일 일정 카드의 공간 배분을 확인하고 750px 경계값 변경이 필요할 때 재평가한다.

## ADR-0005: 캘린더 날짜 의미 색상과 선택 상태를 서로 다른 시각 요소로 표현

- 배경(문제)
  - 메인·친구 캘린더는 선택일과 오늘의 날짜 글자색을 primary blue로 덮어썼다.
  - 이 때문에 선택된 평일과 토요일의 글자색이 같고, 선택된 일요일·공휴일의 accent red 의미가 사라졌다.
  - 기존 8% primary tint와 24% 투명 outline만으로는 작은 날짜 셀에서 선택 경계가 약하게 보였다.
- 선택지(대안)
  - A. 선택일을 solid primary 배경과 흰색 글자로 표시해 날짜 의미 색상을 선택 중에는 숨긴다.
  - B. 토요일·일요일·공휴일 글자색은 유지하고 선택 상태를 별도의 surface 배경과 강한 outline으로 표시한다.
  - C. 토요일 색상을 일반 평일 색상으로 바꿔 primary 선택 색상과의 충돌만 제거한다.
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - 날짜의 의미와 사용자의 현재 선택은 동시에 성립할 수 있는 상태이므로 하나의 글자색을 공유하지 않아야 한다.
  - 기존 `AppTheme.surface_color`와 `primary_dark_color`를 사용하면 신규 색상 토큰 없이 Shift Harmony 체계를 유지할 수 있다.
  - 기존 선택 박스 크기·오프셋·애니메이션은 유지할 수 있어 마지막 행 클리핑과 반응형 달력 동작에 미치는 영향이 작다.
- 결과/영향(좋은 점/트레이드오프)
  - 토요일은 선택 후에도 primary blue, 일요일과 메인 캘린더 공휴일은 선택 후에도 accent red를 유지한다.
  - 선택일 배경은 당시 흰색 surface로 결정했으며, 후속 ADR-0012에서 8% primary tint로 변경한다.
  - 오늘은 날짜 의미 색상을 유지하고 기존 primary 밑줄로 구분한다.
  - 당시 친구 캘린더에는 일요일·토요일 의미 색상만 적용했으며, 공휴일 적용은 ADR-0006에서 확장한다.
- 추후 과제(언제 다시 평가)
  - 실제 기기에서 2px outline의 시각적 무게를 확인한다.

## ADR-0006: 공휴일 API 결과를 앱 공용 로컬 캐시로 관리

- 배경(문제)
  - 메인 캘린더는 `KoreanHolidays` 전역 메모리와 페이지 내부 `_holidays`를 이중 관리했고, 앱 종료 시 조회 결과가 사라졌다.
  - 친구 캘린더는 공휴일 데이터를 조회하지 않아 같은 날짜를 메인과 다르게 표시했다.
- 선택지(대안)
  - A. 친구 캘린더에도 별도 페이지 공휴일 캐시를 추가한다.
  - B. `KoreanHolidays`를 메인·친구 캘린더의 단일 원천으로 사용하고 API 결과를 `SharedPreferences`에 영속 저장한다.
  - C. 서버의 친구 캘린더 응답에 공휴일을 포함한다.
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - 공휴일은 사용자나 친구 일정 소유권과 무관한 공통 날짜 데이터이므로 화면별 또는 서버 응답별 복제가 필요하지 않다.
  - 프로젝트에 이미 포함된 `SharedPreferences`로 날짜·이름·조회 완료 월을 저장하면 신규 의존성 없이 다음 실행에서도 재사용할 수 있다.
  - 기존 요청 월 앞뒤 1개월 lazy loading과 공공데이터포털 API 계약을 유지할 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - 앱 시작 시 로컬 공휴일 캐시를 복원하고, 이후 메인·친구 캘린더의 월 요청 결과를 같은 메모리와 로컬 저장소에 병합한다.
  - 두 캘린더 모두 공휴일 날짜를 accent red로, 선택일 카드에 공휴일명을 표시한다.
  - 메인 캘린더의 페이지 전용 `_holidays` 캐시는 제거된다.
  - 로컬 캐시는 API 요청 수를 줄이는 대신 이미 조회 완료로 저장된 월을 자동 재조회하지 않는다.
- 추후 과제(언제 다시 평가)
  - 임시공휴일 발표 등으로 이미 저장한 월의 갱신 정책이 필요해지면 캐시 저장 시각과 TTL 또는 수동 새로고침을 추가한다.

## ADR-0007: 근무 설정 진입 전후 달력과 하단 카드 크기를 유지

- 배경(문제)
  - 선택일 일정 카드와 근무 설정 카드는 같은 하단 위치를 사용하지만, 일정 카드는 loose `Flexible`
    제약에서 콘텐츠 높이로 줄어들고 근무 설정 카드는 남은 높이를 채워 외부 크기가 달랐다.
  - 근무 설정 진입 시 달력을 월/확장 보기와 60px 행으로 강제해 달력 높이까지 달라졌고,
    하단 영역에 전달되는 가용 높이도 변경됐다.
- 선택지(대안)
  - A. 두 하단 카드에 화면별 고정 높이를 부여하고 달력이 넘치면 전체 화면을 스크롤한다.
  - B. 달력의 현재 형식·확장 상태·행 높이를 유지하고, 두 카드를 같은 tight `Expanded` 슬롯에 배치한다.
  - C. 근무 설정용 월/60px 달력을 유지하고 일반 일정 카드도 항상 그 기준만큼 축소한다.
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - 같은 부모 제약을 사용하면 별도 화면 높이 상수 없이 750px 반응형 규칙과 월/2주/주 형식을 재사용할 수 있다.
  - compact 상태에서는 이미 근무를 표시하는 marker가 있어 48px 행을 유지해도 근무 입력 상태를 확인할 수 있다.
  - 고정 높이나 전체 스크롤을 추가하지 않아 하단 내비게이션과 작은 화면의 기존 레이아웃을 유지할 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - `+` 버튼 전후 `TableCalendar.calendarFormat`과 `rowHeight`가 바뀌지 않는다.
  - 선택일 일정 카드와 근무 설정 카드가 같은 외부 너비·높이를 사용한다.
  - 일정이 적거나 없는 경우에도 선택일 일정 카드는 남은 하단 높이를 채운다.
  - 근무 설정 진입 시 항상 월/60px 확장 달력을 보여주던 동작은 제거된다.
- 추후 과제(언제 다시 평가)
  - 실제 기기에서 compact marker의 가독성과 일정이 없는 카드의 빈 공간 비율을 확인하고,
    필요하면 두 카드 내부 콘텐츠 정렬만 조정한다.

## ADR-0008: 근무 타입 수정은 PUT 응답으로 현재 세션 표시를 동기화

- 배경(문제)
  - 근무 타입 수정 시 설정 Provider의 공용 `is_loading`과 별도 로딩 다이얼로그가 함께 활성화되어
    목록 화면이 새로고침되는 것처럼 보였다.
  - 수정 성공 후 이미 받은 `UpdateShiftTypeResponse.data`를 목록에 반영하면서도
    `shiftTypesProvider`를 무효화해 같은 데이터를 다시 GET했다.
  - 메인 `CalendarPage`는 하위 설정 route가 열린 동안 dispose되지 않고 `/calendar/range`에서 받은
    `_workShifts`와 `_loadedMonths` 메모리 스냅샷을 유지하므로, 수정 응답을 전달받지 못한 채
    이전 코드·이름·색상·시간을 계속 표시했다.
- 선택지(대안)
  - A. 설정 저장 후 근무 타입 GET과 캘린더 range GET을 모두 강제 재호출한다.
  - B. 설정 route를 닫을 때 수정 결과를 여러 Navigator 반환값으로 전달하고 캘린더를 다시 조회한다.
  - C. 수정 PUT 응답을 계정 범위의 표시 업데이트 상태로 발행해 설정 목록·근무 입력 캐시·이미 로드된
    캘린더 스냅샷의 해당 타입만 교체한다.
- 결정(무엇을 선택)
  - C를 선택한다.
- 근거(왜)
  - PUT 응답은 서버가 확정한 최신 근무 타입 전체 필드를 포함하므로 추가 GET 없이 표시 원천으로 사용할 수 있다.
  - 메인 캘린더의 초기/재진입 표시는 ADR-0001대로 `/calendar/range` 응답을 사용하되, 같은 세션에서
    서버가 확정한 수정 응답만 명시적으로 덮어쓰면 계정 캐시 오염 없이 즉시 일관성을 맞출 수 있다.
  - 코드가 변경되어도 수정 전 코드를 함께 보관하면 이미 로드된 `WorkShiftApiModel`과 `_schedules`에서
    해당 근무 타입을 정확히 찾아 새 응답값으로 교체할 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - 수정 요청 중 설정 목록의 공용 로딩 상태와 로딩 다이얼로그를 사용하지 않는다.
  - 성공 시 설정 목록, 근무 입력용 유효 타입 목록, 메인 캘린더의 코드·이름·색상·시간이 PUT 응답으로 갱신된다.
  - 캘린더 range API와 근무 타입 GET을 추가 호출하지 않는다.
  - 표시 업데이트 상태는 메모리 전용이며 로그인/로그아웃 시 다른 계정 범위 Provider와 함께 무효화한다.
- 추후 과제(언제 다시 평가)
  - 서버가 `work_shifts` 응답에 `shift_type_id`를 포함하면 코드 비교 대신 ID 기반 캘린더 패치로 전환한다.
  - 앱 재실행 후에도 `/calendar/range`가 수정 전 타입 메타데이터를 반환한다면 프론트 캐시 문제가 아니므로
    서버의 work shift 조회 join/스냅샷 정책을 별도 점검한다.

## ADR-0009: 근무 타입 시작·종료 시간은 개별 삭제하고 저장 시 쌍을 검증

- 배경(문제)
  - 근무 타입 폼의 시작·종료 시간에는 각각 X 버튼이 있지만 어느 버튼을 눌러도 두 시간이 동시에 삭제되어, 버튼이 속한 행만 수정하려는 사용자의 의도와 달랐다.
  - 서버 요청은 시작·종료 시간이 둘 다 있거나 둘 다 없는 계약을 유지해야 한다.
- 선택지(대안)
  - A. 어느 X 버튼이든 두 시간을 동시에 삭제해 폼 상태를 항상 유효하게 유지한다.
  - B. 각 X 버튼은 해당 시간만 삭제하고, 한쪽만 남은 중간 상태는 허용하되 완료 시 기존 쌍 검증으로 저장을 막는다.
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - 각 행의 X 버튼 동작이 시각적 대상과 일치해 사용자가 시작·종료 시간을 독립적으로 다시 선택할 수 있다.
  - 저장 시점의 기존 검증을 유지하면 API의 시간 쌍 계약을 변경하지 않고 편집 자유도만 높일 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - 시작 시간 X는 시작 시간만, 종료 시간 X는 종료 시간만 비운다.
  - 한쪽 시간만 남은 상태에서 완료하면 기존 입력 오류 다이얼로그를 표시한다.
  - 코드·이름의 키보드 완료 액션과 시작 시간 적용은 이름·시작 시간·종료 시간으로 입력 대상을
    순차 이동하며, 시간 선택을 취소하면 다음 단계로 자동 이동하지 않는다.
  - 시간 표시 형식, 공용 `TimePickerSheet`, `HH:mm:ss` API 요청과 DB 구조는 변경하지 않는다.
- 추후 과제(언제 다시 평가)
  - 실제 기기에서 키보드 완료 액션과 시작→종료 시간 시트 전환 속도를 확인하고, 종료 시간 적용 뒤
    저장까지 자동화해야 한다는 사용자 요구가 확인되면 별도로 재평가한다.

## ADR-0010: 동적 근무 색상의 글자는 배경 대비로 전경색을 결정

- 배경(문제)
  - 근무 색상 농도는 투명도를 낮추지 않고 `surface_color`와 선택 색상을 불투명 혼합해 옅게 만든다.
  - 미리보기·목록·캘린더 배지는 흰색 글자를 고정 사용하고, 근무 선택 버튼은 옅어진 근무 색상
    자체를 글자색으로 사용해 낮은 농도에서 배경과 글자의 명도 차이가 사라졌다.
- 선택지(대안)
  - A. 농도 최솟값을 제한해 너무 옅은 색상을 저장하지 못하게 한다.
  - B. 저장 색상은 유지하고 화면별로 임의 명도 기준을 두어 흰색/검은색을 선택한다.
  - C. 공용 대비 계산으로 선호 전경색을 우선 사용하되 4.5:1 미만이면 공용 어두운색/밝은색 중
    대비가 높은 색을 선택한다.
- 결정(무엇을 선택)
  - C를 선택한다.
- 근거(왜)
  - 사용자가 선택한 색상과 기존 불투명 저장 계약을 바꾸지 않고 글자 가독성만 보정할 수 있다.
  - 같은 계산을 미리보기·설정 목록·근무 선택 버튼·캘린더 배지에 적용해 화면별 기준 차이를 막는다.
  - 충분히 대비되는 근무 색상은 기존 선호 전경색을 그대로 유지할 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - 옅은 근무 색상에서는 코드가 `on_surface_color`, 어두운 배경에서는 `surface_color`로 표시된다.
  - 저장되는 근무 색상, 색상 농도 계산, API 요청 및 DB 값은 변경하지 않는다.
  - 일부 밝은 프리셋은 기존 흰색 코드 대신 어두운 코드로 보일 수 있다.
- 추후 과제(언제 다시 평가)
  - 다크 테마에서 동적 canvas 색상이 도입되면 대비 계산의 기본 canvas와 전경 토큰을 재평가한다.

## ADR-0011: 근무 타입의 최종 색상과 기준 색상·농도를 함께 보존

- 배경(문제)
  - 현재 색상 선택 화면은 불투명 흰색과 기준 색상을 농도만큼 혼합한 최종 `Color` 하나를 반환한다.
  - 현재 API와 DB도 최종 `color`만 저장하므로, 50% 등으로 저장한 뒤 다시 진입하면 저장된
    최종 색상이 새 기준 색상이 되고 농도는 100%로 초기화된다.
  - 하나의 최종 색상은 여러 기준 색상·농도 조합으로 만들 수 있어 기존 값만으로 원래 설정을
    유일하게 복원할 수 없다.
- 선택지(대안)
  - A. 최종 `color`만 유지하고 화면 진입 시 가장 가까운 프리셋·농도를 추정한다.
  - B. 기준 색상과 농도를 하나의 JSONB 컬럼에 저장한다.
  - C. 기존 최종 `color`를 유지하고 `base_color text`,
    `color_intensity smallint` 컬럼을 명시적으로 추가한다.
- 결정(무엇을 선택)
  - C를 선택한다.
  - `color`는 기존 앱과 캘린더 응답을 위한 최종 렌더링 색상으로 유지한다.
  - `base_color`는 nullable `#AARRGGBB`, `color_intensity`는 기본값 100의
    정수 퍼센트 `0..100`으로 저장한다.
  - 신규 요청의 최종 `color`는 서버가 불투명 흰색 `#FFFFFFFF` 혼합 규칙으로 계산한다.
- 근거(왜)
  - 추정 방식은 커스텀 색상에서 원래 설정을 정확히 복원할 수 없다.
  - 명시적 컬럼은 JSONB보다 타입·범위 검증과 API 계약이 단순하다.
  - 기존 `color`를 유지하면 구버전 Flutter와 `calendar/range`, 친구 캘린더,
    근무표 스냅샷의 색상 표시를 깨지 않고 단계적으로 배포할 수 있다.
  - 농도를 정수 퍼센트로 저장하면 현재 UI 표시와 일치하고 부동소수점 직렬화 오차를 피한다.
- 결과/영향(좋은 점/트레이드오프)
  - 색상 설정 화면은 저장·재조회 후 기준 색상과 농도를 그대로 복원할 수 있다.
  - 구버전 `color` 단독 요청과 레거시 행은 `base_color=color`, 농도 100%로 해석한다.
  - `base_color`는 서버 롤백 호환성을 위해 nullable로 유지하며 API 계층에서 필드 쌍의
    일관성을 검증한다.
  - 최종 색상 계산 로직을 Express와 Flutter가 같은 규칙으로 구현하고 계약 테스트해야 한다.
  - DB·서버·Flutter를 순서대로 배포해야 하며 두 신규 컬럼만큼 저장 공간이 늘어난다.
  - Flutter는 `ShiftTypeApiModel`의 레거시 fallback, `ShiftColorSelection`,
    고정 흰색 기반 정수 퍼센트 계산과 생성/수정 요청 직렬화를 적용한다.
  - 편집 화면에서 색상 선택 결과를 적용하지 않았다면 색상 메타데이터를 보내지 않아
    이름·시간만 수정할 때 서버의 기존 기준 색상과 농도를 유지한다.
- 추후 과제(언제 다시 평가)
  - 구버전 서버 롤백 기간이 종료되면 `color`와 `base_color`의 DB 쌍 제약 강화 여부를 검토한다.
  - 농도 UI가 1%보다 세밀한 값을 요구하면 정수 단위를 basis point로 확장하는 별도 ADR을 작성한다.
  - 구현·migration·롤백의 상세 절차는
    `_docs/SHIFT_TYPE_COLOR_METADATA_API_GUIDE.md`를 따른다.

## ADR-0012: 캘린더 선택일 배경에 낮은 농도의 primary tint 사용

- 배경(문제)
  - ADR-0005는 날짜 의미 색상과 선택 상태를 분리하기 위해 흰색 surface와 2px primary dark
    outline을 사용했다.
  - 실제 화면에서는 페이지 배경과 흰색 선택 배경의 차이가 작아 선택 상태가 outline에만
    의존하는 인상이 남았다.
- 선택지(대안)
  - A. 기존 흰색 surface 배경을 유지한다.
  - B. 날짜 의미 색상을 유지하면서 선택 배경만 8% primary tint로 바꾼다.
  - C. solid primary 배경과 흰색 날짜 글자를 사용한다.
- 결정(무엇을 선택)
  - B를 선택한다.
- 근거(왜)
  - 기존 2px primary dark outline과 같은 색 계열의 낮은 농도 tint를 사용하면 선택 상태가
    선명해지면서 토요일 primary blue, 일요일·공휴일 accent red 글자 의미를 유지할 수 있다.
  - 선택 박스 크기·오프셋·애니메이션과 날짜 콘텐츠 레이아웃을 변경하지 않는다.
- 결과/영향(좋은 점/트레이드오프)
  - 메인·친구 캘린더 선택일은 `primary_color` 8% 배경과 2px `primary_dark_color` outline으로
    표시된다.
  - 날짜 글자색, 오늘 밑줄, 근무 코드 배지와 API/DB 계약은 변경하지 않는다.
  - 테마 primary 색상이 변경되면 선택 배경 색도 함께 변경된다.
- 추후 과제(언제 다시 평가)
  - 다크 테마를 도입할 때 8% tint의 실제 대비와 outline 조합을 재평가한다.

## ADR-0013: 네이버 로그인은 네이티브 SDK의 앱 우선 인증을 사용

- 배경(문제)
  - 기존 구현은 앱 내부 `InAppWebView`에서 네이버 OAuth 페이지를 열고 custom callback URL의
    fragment를 직접 파싱했다.
  - 이 방식은 네이버 앱이 설치된 기기에서도 앱 내부 계정 입력 화면으로 진입할 수 있으며,
    Flutter UI가 OAuth URL 생성·외부 앱 스킴 처리·Access Token 파싱까지 책임졌다.
- 선택지(대안)
  - A. 기존 WebView implicit OAuth와 수동 callback 파싱을 유지한다.
  - B. 네이버 네이티브 SDK에서 네이버 앱만 허용하고 앱이 없으면 로그인할 수 없게 한다.
  - C. 네이버 네이티브 SDK에서 네이버 앱을 우선하고, 앱이 없을 때만 SDK 브라우저로 fallback한다.
- 결정(무엇을 선택)
  - C를 선택한다.
  - Flutter 3.38.5와 호환되고 iOS에서
    `appPreferredWithInAppBrowserFallback`을 설정하는 `naver_login_flutter` 3.0.4를 고정한다.
  - 네이티브 SDK가 발급한 Access Token만 기존 `POST /api/v1/auth/naver/token` 서버 교환
    API에 전달하며 앱 JWT 저장 계약은 변경하지 않는다.
- 근거(왜)
  - 네이버 앱 설치 사용자는 앱의 기존 로그인 세션을 활용할 수 있고 앱 내부에서 계정 정보를
    직접 입력하지 않는다.
  - 네이버 앱 미설치 사용자도 로그인할 수 있어 앱 전용 방식보다 접근성이 높다.
  - URL callback과 토큰 발급을 공식 네이티브 SDK에 맡겨 Flutter의 수동 OAuth 처리 범위를
    제거한다.
- 결과/영향(좋은 점/트레이드오프)
  - `flutter_inappwebview`, `url_launcher` 의존성과 WebView 로그인 위젯을 제거한다.
  - iOS는 Bundle ID `com.hspark.shiftmate`와 전용 URL Scheme `com.hspark.shiftmate`,
    Android는 패키지명 `com.hspark.shiftmate`를 네이버 개발자 센터와 일치시켜야 한다.
  - Android/iOS 빌드 환경에 Naver Client ID와 Client Secret을 별도로 주입해야 한다.
  - 사용자가 네이버 앱을 설치하지 않은 경우에는 네이버 SDK가 제공하는 브라우저 인증 화면이 열린다.
- 추후 과제(언제 다시 평가)
  - Flutter SDK를 3.44 이상으로 올릴 때 `naver_login_flutter` 최신 안정 버전으로 갱신하고
    iOS 앱 우선 동작과 Android 로그인 결과 모델을 회귀 검증한다.
  - 실제 iOS/Android 기기에서 네이버 앱 설치·미설치·사용자 취소 세 경로를 각각 확인한다.

## ADR-0014: 출시 전 앱 브랜드와 플랫폼 식별자를 ShiftMate로 통일

- 배경(문제)
  - 사용자 노출 이름, Dart 패키지명, Android 애플리케이션 ID에 초기 프로젝트명인
    `Shift Calendar`와 `shift_calendar`가 남아 있었고 iOS Bundle ID·OAuth 설정의
    `com.hspark.shiftmate`와 일치하지 않았다.
  - 앱은 Play Store와 Apple Developer에 등록하기 전인 로컬 개발 단계이므로 설치·배포
    신원을 확정하기 전에 식별자를 정리할 수 있다.
- 선택지(대안)
  - A. 사용자에게 보이는 이름만 `ShiftMate`로 바꾸고 내부 패키지 식별자는 유지한다.
  - B. 표시 이름, Dart 패키지, Android/iOS 식별자와 개발 도구 표시 이름을 모두 통일한다.
  - C. 스토어 등록 이후에 식별자를 마이그레이션한다.
- 결정(무엇을 선택)
  - B를 선택한다.
  - 브랜드·플랫폼 표시 이름은 `ShiftMate`, Dart 패키지는 `shift_mate`,
    Android namespace/applicationId와 iOS Bundle ID는 `com.hspark.shiftmate`를 사용한다.
  - 캘린더 기능을 설명하는 폴더·클래스·API 도메인 용어의 `calendar`는 유지한다.
- 근거(왜)
  - 출시 전에 Android와 iOS의 앱 신원, OAuth 플랫폼 등록값, 코드 내부 명칭을 맞추면
    스토어 등록 후 변경할 수 없는 Android applicationId의 불일치를 방지할 수 있다.
  - 기능 용어와 브랜드를 구분하면 캘린더 도메인 코드까지 불필요하게 이름을 바꾸지 않아도 된다.
- 결과/영향(좋은 점/트레이드오프)
  - Android의 기존 로컬 설치와 새 applicationId 앱은 서로 다른 앱으로 취급되므로 기존
    로컬 앱 데이터는 자동 이전되지 않는다.
  - 네이버·카카오 개발자 콘솔의 Android 패키지명은 `com.hspark.shiftmate`로 등록하고,
    카카오는 같은 패키지명에 사용하는 빌드 서명 키 해시를 함께 등록해야 한다.
  - Dart 패키지명 변경에 따라 절대 import와 테스트 참조를 함께 갱신해야 한다.
- 추후 과제(언제 다시 평가)
  - Play Store와 Apple Developer 등록 전에 최종 조직 도메인과 앱 식별자가
    `com.hspark.shiftmate`인지 한 번 더 확인한다.
  - 스토어 등록 후에는 Android applicationId를 변경하지 않는다.

## ADR-0015: 근무 타입 코드 중복은 입력 완료 후 표시

- 배경(문제)
  - 근무 타입 코드 컨트롤러 리스너가 텍스트뿐 아니라 포커스 진입 시의 커서 선택 변화에도
    `setState`를 호출해 폼 전체를 반복 재빌드했다.
  - 소문자 입력은 같은 리스너가 컨트롤러 값을 대문자로 다시 쓰면서 리스너를 재호출했고,
    재현 테스트에서 코드 `FocusNode`는 활성인데 키보드 입력 연결이 닫히는 상태가 확인됐다.
  - 기존 코드 `D`로 시작하는 신규 코드 `DE`를 입력할 때 첫 글자 `D`만으로 중복 테두리와
    안내가 나타나 사용자가 입력을 끝내기 전에 오류로 판단됐다.
  - 입력 완료 후 중복 오류가 표시된 상태에서도 포커스 획득 리스너가 오류 UI를 즉시 제거하며
    코드 입력 분기를 다시 빌드하면, `FocusNode`는 활성인데 플랫폼 키보드는 첫 탭에 연결되지
    않고 두 번째 탭에서야 열리는 후속 문제가 재현됐다.
- 선택지(대안)
  - A. 기존 즉시 중복 검사를 유지하고 일정 시간 debounce 후 표시한다.
  - B. 최대 길이 3자를 모두 채웠을 때만 중복을 표시한다.
  - C. 대문자 변환은 `TextInputFormatter`에서 처리하고, 중복 UI는 코드 필드의 포커스가
    빠지는 입력 완료 시점에만 계산한다.
- 결정(무엇을 선택)
  - C를 선택한다.
  - 새 코드를 입력하는 동안은 중복 테두리·안내를 표시하지 않는다. 입력 완료로 이미 표시된
    중복 오류는 코드 필드를 다시 탭하는 것만으로 제거하지 않고 실제 텍스트가 변경될 때 제거한다.
  - 키보드 완료, 다른 필드 이동, 본문 터치처럼 코드 편집이 끝나 포커스가 빠지면 현재 전체
    코드를 비교해 중복 UI와 완료 비활성화를 적용한다.
  - 중복 상태는 `ValueNotifier`로 국소 갱신한다. 코드 입력 필드는 오류 상태 변화와 무관하게
    동일한 위젯 자식으로 유지하고, 오류 테두리는 `Stack`의 포인터 비활성 오버레이로 분리한다.
  - 최종 저장 검증과 서버 `DUPLICATE_CODE` 처리는 그대로 유지한다.
- 근거(왜)
  - debounce는 사용자의 실제 입력 완료 여부를 알 수 없고 느린 입력에서 같은 조기 오류가 재발한다.
  - 코드 길이는 1~3자이므로 3자 고정 검사는 유효한 1~2자 코드의 중복을 제때 표시하지 못한다.
  - 포커스 이탈은 코드 입력을 끝내고 다음 작업으로 이동했다는 명시적 신호이며, 입력 포매터는
    컨트롤러 재할당 없이 대문자 계약을 유지한다.
  - 포커스 획득 리스너 안에서 입력 위젯을 교체하지 않으면 Flutter가 `EditableText`와 플랫폼
    키보드 사이의 입력 연결을 첫 탭부터 안정적으로 열 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - 신규·수정 모두 기존 코드 접두어를 입력하는 동안 경고 없이 키보드와 코드 포커스를 유지한다.
  - 입력 완료된 전체 코드가 실제로 중복일 때만 기존 accent red 테두리·안내와 완료 비활성화를
    표시한다.
  - 중복 표시 후 코드 필드를 처음 다시 탭해도 키보드가 열리며, 첫 실제 수정에서 오류 표시만
    제거되고 코드 필드와 키보드 입력 연결은 유지된다.
  - 중복 코드를 입력한 채 완료를 누르는 경우의 최종 검증, API 요청, DB 구조는 변경하지 않는다.
  - 사용자가 코드 필드에 머무는 동안에는 중복 여부를 즉시 볼 수 없고, 다음 입력 대상으로
    이동한 뒤 확인한다.
- 추후 과제(언제 다시 평가)
  - 실제 iOS/Android 키보드의 조합 입력과 자동 대문자 동작을 회귀 확인하고, 코드 입력 완료를
    별도 버튼으로 명시해야 한다는 요구가 생기면 재평가한다.

## ADR-0016: 세 캘린더는 표시 계약을 공유하고 화면별 기능은 조합한다

- 배경(문제)
  - 메인·친구는 같은 날짜 셀과 3개월 조회 규칙을 각각 구현했고, 그룹은 별도
    `TableCalendar`와 요일·선택·오늘 셀을 다시 구현해 디자인 수정이 세 경로로 퍼졌다.
  - 반대로 메인 근무 편집, 친구 공개 필터 결과, 그룹 다중 구성원 상세는 기능과 데이터 원천이
    달라 하나의 거대한 공용 페이지로 합치면 조건 분기와 결합도가 커진다.
- 선택지(대안)
  - A. 세 페이지를 `UniversalCalendarPage` 하나로 만들고 mode별 조건문으로 모든 기능을 처리한다.
  - B. 각 페이지를 유지하고 색상·간격 값만 같은 상수로 맞춘다.
  - C. 월 탐색/반응형 정책, 날짜 표시 모델, viewport/날짜 셀, 메인·친구 조회 상태만
    공통화하고 편집·설정·구성원 상세는 페이지가 조합한다.
- 결정(무엇을 선택)
  - C를 선택한다.
  - API/더미 데이터를 `CalendarDayPresentation`의 badge/dots로 변환한 뒤
    `CalendarViewport`와 `CalendarMonthView`가 공통 렌더링한다.
  - 750px 반응형 행 높이와 2000.01~2050.12 월 경계는 policy/controller가 담당한다.
  - 메인과 친구의 전월~다음월 조회, 날짜별 병합, 중복 요청, 로딩·오류는 loader를 주입받는
    `CalendarRangeNotifier`가 담당한다. 메인은 자체 range API, 친구는 friend ID별 API를 주입한다.
  - 그룹은 실제 API가 없으므로 range notifier에 넣지 않고 표시 계층만 재사용한다.
- 근거(왜)
  - 안정적인 시각·탐색 규칙을 한 경로에서 검증하면서도 화면별 도메인 차이를 명시적으로 유지한다.
  - loader 주입은 서버가 공개 필터링한 친구 결과와 본인 결과를 같은 캐시 알고리즘으로 처리하되
    API 권한 계약을 UI에 섞지 않는다.
  - 월별 in-flight Future를 공유하면 빠른 이동이나 중복 lifecycle 호출로 같은 범위를 다시
    요청하지 않고, 서로 다른 범위는 독립적으로 완료될 수 있다.
- 결과/영향(좋은 점/트레이드오프)
  - 날짜 선택 tint/outline, 오늘 밑줄, 주말 색, badge/dots, 작은 화면 규칙의 수정 지점이
    공용 위젯과 policy로 줄어든다.
  - 메인·친구의 근무·일정 조회 캐시는 Riverpod domain state가 되고, focused/selected 날짜와
    메인 편집 draft는 page UI state로 남는다.
  - 메인의 저장/삭제/일정 생성 응답은 notifier에 직접 반영해 추가 GET 없이 현재 화면을 갱신한다.
  - 공용 계층의 API가 세 화면에 영향을 주므로 policy/notifier 단위 테스트와 세 페이지 위젯
    테스트를 함께 실행해야 한다.
  - 그룹 데이터가 실제 API로 전환될 때는 그룹 전용 loader/aggregate 계약을 별도로 설계해야 한다.
- 추후 과제(언제 다시 평가)
  - 그룹 캘린더 API와 멤버별 공개 규칙이 확정되면 `CalendarRangeState`를 그대로 쓸 수 있는지,
    구성원 ID를 포함한 별도 aggregate state가 필요한지 재평가한다.
  - 주/일 보기나 여러 캘린더 중첩 표시가 추가되면 `CalendarDayPresentation`의 indicator 계약을
    확장하되 페이지별 도메인 객체를 공용 위젯에 직접 전달하지 않는다.

## 1. Navigation/Route 구조

### 라우팅 방식

- **방식**: Flutter 기본 `Navigator` + `CupertinoPageRoute` 사용
- **패키지**: `go_router` 등 외부 라우팅 라이브러리 미사용
- **이유**: 현재 화면 구조가 단순하고, 인증 상태에 따른 분기가 명확하여 기본 Navigator로 충분

### 화면 진입 조건

- **인증 상태 기반 분기**: `main.dart`의 `AuthWrapper`에서 처리
  - `AuthStatus.initial`: 스플래시 화면 (`_SplashScreen`)
  - `AuthStatus.authenticated`:
    - 신규 사용자 (`is_new_user == true`): `ProfileSetupPage`
    - 기존 사용자: `CalendarPage`
  - `AuthStatus.unauthenticated`: `LoginPage`

### 구현 위치

```12:88:lib/main.dart
class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    switch (authState.status) {
      case AuthStatus.initial:
        return const _SplashScreen();
      case AuthStatus.authenticated:
        if (authState.is_new_user && authState.user != null) {
          return ProfileSetupPage(user: authState.user!);
        }
        return const CalendarPage();
      case AuthStatus.unauthenticated:
        return const LoginPage();
    }
  }
}
```

### 화면 전환

- 일반 화면 전환: `Navigator.push(CupertinoPageRoute(...))`
- 인증 후 전환: `Navigator.pushReplacement(CupertinoPageRoute(...))`

---

## 2. 상태관리 규칙

### 사용 라이브러리

- **Flutter Riverpod 2.6.1** 사용
- **Riverpod Generator** 사용 (코드 생성)

### Provider 타입별 사용 규칙

#### 1. StateNotifierProvider

- **용도**: UI 상태가 변경 가능한 경우 (예: 인증 상태)
- **예시**: `authProvider`

```52:55:lib/features/auth/presentation/providers/auth_provider.dart
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
```

#### 2. FutureProvider

- **용도**: 비동기 데이터를 한 번만 로드하는 경우 (예: 근무 타입 목록)
- **예시**: `shiftTypesProvider`

```7:22:lib/features/calendar/presentation/providers/shift_types_provider.dart
final shiftTypesProvider = FutureProvider<List<ShiftTypeInfo>>((ref) async {
  final service = ref.watch(shiftTypeServiceProvider);
  final response = await service.getShiftTypes();
  return response.data.shiftTypes.map((apiModel) {
    return ShiftTypeInfo(
      code: apiModel.code,
      name: apiModel.name,
      color: apiModel.colorValue ?? CupertinoColors.systemGrey,
      sort_order: apiModel.sortOrder ?? 0,
      start_time: apiModel.startTimeDisplay,
      end_time: apiModel.endTimeDisplay,
    );
  }).toList();
});
```

#### 3. Provider

- **용도**: 의존성 주입 및 서비스 인스턴스 제공
- **예시**: `dioProvider`, `tokenServiceProvider`, `shiftTypeServiceProvider`

### UI State vs Domain State 구분

#### UI State

- **위치**: `presentation/providers/` 또는 페이지 내부 `State` 클래스
- **예시**:
  - `_is_loading` (로딩 상태)
  - `_is_shift_add_mode` (UI 모드)
  - 폼 입력값 (`TextEditingController`)

#### Domain State

- **위치**: `domain/entities/` 또는 `presentation/providers/`의 상태 모델
- **예시**:
  - `AuthState` (인증 상태)
  - `User` (사용자 정보)
  - `ShiftTypeInfo` (근무 타입 정보)

### dispose/autoDispose 정책

- **StateNotifier**: 자동으로 dispose됨 (Riverpod이 관리)
- **FutureProvider**: `autoDispose` 미사용 (캐시 유지)
- **수동 리소스**: `TextEditingController` 등은 `dispose()`에서 명시적으로 해제

---

## 3. API 통신 규칙

### HTTP 클라이언트

- **라이브러리**: Dio 5.7.0
- **인스턴스 생성**: `ApiClient.createDio()` → `dioProvider`로 제공

### 인터셉터 구조

#### 1. 로깅 인터셉터

- 요청/응답/에러 로그 출력

```37:57:lib/core/network/api_client.dart
static Interceptor _createLogInterceptor() {
  return InterceptorsWrapper(
    onRequest: (options, handler) {
      print('🚀 REQUEST[${options.method}] => PATH: ${options.path}');
      return handler.next(options);
    },
    onResponse: (response, handler) {
      print('✅ RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      return handler.next(response);
    },
    onError: (error, handler) {
      print('❌ ERROR[${error.response?.statusCode}] => PATH: ${error.requestOptions.path}');
      return handler.next(error);
    },
  );
}
```

#### 2. 인증 인터셉터

- **토큰 자동 주입**: 요청 시 `Authorization: Bearer {token}` 헤더 추가
- **토큰 갱신**:
  - 만료 임박 시 미리 갱신 (`isTokenExpired()`)
  - 401 에러 시 자동 갱신 후 재시도
- **공개 엔드포인트**: 로그인/회원가입/토큰 갱신은 토큰 주입 스킵

```59:168:lib/core/network/api_client.dart
static Interceptor _createAuthInterceptor(Dio dio) {
  final tokenService = TokenService();
  // ... 토큰 갱신 로직
  return InterceptorsWrapper(
    onRequest: (options, handler) async {
      if (_isPublicEndpoint(options.path)) {
        return handler.next(options);
      }
      if (await tokenService.isTokenExpired()) {
        await refreshToken();
      }
      final token = await tokenService.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        final refreshed = await refreshToken();
        if (refreshed) {
          // 원래 요청 재시도
        }
      }
      return handler.next(error);
    },
  );
}
```

### 에러 매핑 방식

#### 1. DioException → ApiException 변환

- **위치**: `core/network/api_error_handler.dart`
- **함수**: `handleApiError(DioException error)`

```5:51:lib/core/network/api_error_handler.dart
Exception handleApiError(DioException error) {
  if (error.response != null) {
    final data = error.response!.data;
    if (data is Map<String, dynamic> && data.containsKey('error')) {
      final errorData = data['error'] as Map<String, dynamic>;
      return ApiException(
        code: errorData['code'] as String? ?? 'UNKNOWN_ERROR',
        message: errorData['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
        statusCode: error.response!.statusCode,
      );
    }
    // ... 네트워크 오류 처리
  }
  // ... 타임아웃 처리
}
```

#### 2. ApiException 구조

```1:15:lib/core/network/api_exception.dart
class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  // ...
}
```

#### 3. 서비스 레이어에서 사용

- 모든 `DioException`은 `handleApiError()`로 변환

```29:31:lib/features/calendar/data/services/shift_type_service.dart
} on DioException catch (e) {
  throw handleApiError(e);
}
```

### API 응답 형식

- **성공 응답**: `{ "success": true, "data": {...} }`
- **에러 응답**: `{ "success": false, "error": { "code": "...", "message": "..." } }`

### DTO/Entity 분리

- **API Model (DTO)**: `data/models/*_api_model.dart` (서버 응답 형식)
- **Entity**: `domain/entities/*.dart` (앱 내부 도메인 모델)
- **변환**: Service 레이어에서 API Model → Entity 변환

---

## 4. UI 컴포넌트 규칙

### 디자인 시스템

- **스타일**: Apple Cupertino 디자인 가이드라인 준수
- **테마**: `core/theme/app_theme.dart`에 중앙 집중식 정의

### 테마 구조

#### 컬러

```7:11:lib/core/theme/app_theme.dart
static const Color primary_color = CupertinoColors.systemBlue;
static const Color secondary_color = CupertinoColors.systemGrey;
static const Color background_color = CupertinoColors.systemGroupedBackground;
static const Color surface_color = CupertinoColors.white;
```

#### 타이포그래피

- `heading_large` (34px, bold)
- `heading_medium` (22px, bold)
- `heading_small` (17px, w600)
- `body_large` (17px, normal)
- `body_medium` (15px, normal)
- `body_small` (13px, normal)

### 공용 위젯 위치

- **위치**: `lib/shared/widgets/` (현재 비어있음, 향후 확장 예정)
- **피처별 위젯**: `features/{feature}/presentation/widgets/`
- **예시**: `ShiftBadge`, `ShiftTypeButton`, `BottomActionBar`

### 컴포넌트 예시

```6:61:lib/features/calendar/presentation/widgets/shift_badge.dart
class ShiftBadge extends ConsumerWidget {
  const ShiftBadge({
    super.key,
    required this.shift_type,
    this.size = 16,
    this.show_label = false,
  });
  // ... 구현
}
```

---

## 5. 폴더 구조 규칙

### 전체 구조

```
lib/
├── core/                    # 공통 인프라
│   ├── constants/          # 상수 (API 엔드포인트, 앱 설정)
│   ├── network/            # 네트워크 (Dio, 에러 처리)
│   ├── services/           # 공통 서비스 (토큰 관리)
│   └── theme/              # 테마
├── features/               # 기능별 모듈
│   ├── auth/               # 인증
│   ├── calendar/           # 캘린더/근무표
│   └── schedule/            # 일정 (향후 확장)
└── shared/                 # 공용 위젯/유틸
    └── widgets/
```

### Feature 폴더 구조

```
features/{feature}/
├── data/                   # 데이터 레이어
│   ├── datasources/        # 원격/로컬 데이터 소스
│   ├── models/             # API 모델 (DTO)
│   ├── repositories/       # Repository 구현체
│   └── services/           # API 서비스 (선택적)
├── domain/                 # 도메인 레이어
│   ├── entities/           # 엔티티 (Freezed)
│   ├── repositories/      # Repository 인터페이스
│   └── usecases/           # UseCase (향후 확장)
└── presentation/           # 프레젠테이션 레이어
    ├── pages/              # 화면 (Page)
    ├── providers/          # 상태 관리
    └── widgets/            # 피처별 위젯
```

### 네이밍 컨벤션

- **변수명**: `snake_case` (예: `_is_loading`, `work_date`)
- **함수명**: `camelCase` (예: `getShiftTypes()`, `handleKakaoLogin()`)
- **클래스명**: `PascalCase` (예: `AuthNotifier`, `WorkShiftService`)
- **파일명**: `snake_case.dart` (예: `auth_provider.dart`, `api_client.dart`)

---

## 6. 비동기/로딩/에러 UX 통일

### 로딩 상태 표시

#### 1. 전체 화면 로딩

- **스플래시**: `CupertinoActivityIndicator` 사용

```91:139:lib/main.dart
class _SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ... 앱 아이콘
            const CupertinoActivityIndicator(),
          ],
        ),
      ),
    );
  }
}
```

#### 2. 버튼 내부 로딩

- 버튼 내부에 `CupertinoActivityIndicator` 표시

```172:175:lib/features/auth/presentation/pages/login_page.dart
child: _is_loading
    ? const Center(
        child: CupertinoActivityIndicator(color: Color(0xFF191919)),
      )
```

#### 3. 다이얼로그 로딩

- API 호출 중 모달 다이얼로그로 로딩 표시

```661:666:lib/features/calendar/presentation/pages/calendar_page.dart
showCupertinoDialog(
  context: context,
  barrierDismissible: false,
  builder: (context) =>
      const CupertinoAlertDialog(content: CupertinoActivityIndicator()),
);
```

### 에러 표시

#### 1. 에러 다이얼로그

- **표준 형식**: `CupertinoAlertDialog` 사용
- **에러 메시지 매핑**: `ApiException.code` 기반 사용자 친화적 메시지 변환

```627:642:lib/features/calendar/presentation/pages/calendar_page.dart
void _showErrorDialog(String message) {
  showCupertinoDialog(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: const Text('오류'),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          child: const Text('확인'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    ),
  );
}
```

#### 2. 에러 메시지 추출

- **원칙**: 서버에서 전달받은 `ApiException.message`를 그대로 사용
- **이유**: 서버에서 이미 사용자 친화적인 메시지를 제공하므로 클라이언트에서 재매핑 불필요
- **구현**: 하드코딩된 switch-case 제거, `error.message` 직접 반환

```730:738:lib/features/calendar/presentation/pages/calendar_page.dart
/// 에러 메시지 추출
String _getErrorMessage(dynamic error) {
  if (error is ApiException) {
    // 서버에서 전달받은 message를 그대로 반환
    return error.message;
  }
  // ApiException이 아닌 경우 기본 메시지 반환
  return '알 수 없는 오류가 발생했습니다.';
}
```

#### 3. Provider 에러 필드 타입

- **타입**: `dynamic` (예외 객체 보존)
- **이유**: `String?`으로 저장하면 `ApiException` 객체가 문자열로 변환되어 타입 체크 실패
- **구현**: catch 블록에서 `e.toString()` 대신 `e` 자체를 저장

```8:13:lib/features/calendar/presentation/providers/shift_template_settings_provider.dart
class ShiftTemplateSettingsState {
  final String? templateId;
  final String? templateName;
  final List<ShiftTypeApiModel> shiftTypes;
  final bool is_loading;
  final dynamic error;  // String? → dynamic으로 변경
```

```70:75:lib/features/calendar/presentation/providers/shift_template_settings_provider.dart
    } catch (e) {
      state = state.copyWith(
        is_loading: false,
        error: e,  // e.toString() 대신 e 자체 저장
      );
    }
```

### 비동기 처리 패턴

#### 1. FutureProvider 사용

- 한 번만 로드되는 데이터 (예: 근무 타입 목록)

```7:22:lib/features/calendar/presentation/providers/shift_types_provider.dart
final shiftTypesProvider = FutureProvider<List<ShiftTypeInfo>>((ref) async {
  final service = ref.watch(shiftTypeServiceProvider);
  final response = await service.getShiftTypes();
  return response.data.shiftTypes.map((apiModel) => ...).toList();
});
```

#### 2. StateNotifier + 수동 호출

- 사용자 액션에 따른 비동기 처리 (예: 로그인, 근무 저장)

```86:106:lib/features/auth/presentation/providers/auth_provider.dart
Future<bool> loginWithKakao() async {
  state = state.copyWith(is_loading: true, error: null);
  try {
    final authResponse = await _repository.loginWithKakao();
    state = AuthState(
      status: AuthStatus.authenticated,
      user: authResponse.user,
      is_new_user: authResponse.is_new_user,
    );
    return true;
  } catch (e) {
    state = state.copyWith(
      is_loading: false,
      error: e.toString().replaceAll('Exception: ', ''),
    );
    return false;
  }
}
```

### 스켈레톤 UI

- 현재 미구현 (향후 확장 가능)

---

## Flutter 작업 체크리스트

### 화면 추가 시

- [ ] Route 등록 (필요시 `AuthWrapper` 수정)
- [ ] 접근 권한 확인 (인증 필요 여부)
- [ ] Analytics/Logging 추가 (향후)

### API 추가 시

- [ ] DTO/Entity 분리 (`data/models/` vs `domain/entities/`)
- [ ] 에러 매핑 (`handleApiError()` 사용)
- [ ] Mock/Test 가능성 고려 (향후)

### 상태 추가 시

- [ ] Provider 타입 선택 (StateNotifier vs FutureProvider vs Provider)
- [ ] dispose/autoDispose 정책 확인
- [ ] UI State vs Domain State 구분

### 에러 처리 시

- [ ] `ApiException`으로 변환 (`handleApiError()`)
- [ ] 사용자 친화적 메시지 매핑 (`_getErrorMessage()`)
- [ ] `CupertinoAlertDialog`로 표시

---

## 8. 한국 공휴일 기능

### API 선택

- **사용 API**: 공공데이터포털 - 한국천문연구원 특일 정보 API (`getRestDeInfo`)
- **이유**:
  - 공식적인 법정 공휴일 데이터 제공
  - 대체공휴일 정보 포함
  - 무료 사용 가능 (API 키 필요)
- **API 엔드포인트**: `http://apis.data.go.kr/B090041/openapi/service/SpcdeInfoService/getRestDeInfo`

### 데이터 로딩 전략

- **Lazy Loading**: 현재 보고 있는 월 기준으로 앞뒤 한 달씩 총 3개월만 조회
- **캐싱**: 앱 공용 연도별 메모리 캐시 + `SharedPreferences` 영속 캐시 + 월별 로드 상태 추적
- **앱 초기화**: `main.dart`에서 로컬 캐시를 복원하고 메인·친구 캘린더가 같은 데이터 원천 사용
- **중복 호출 방지**: 동일한 연도/월 조합의 동시 요청은 하나의 Future 공유
- **구현 위치**: `lib/core/utils/korean_holidays.dart`

### 공휴일 표시 규칙

- **공휴일**: 빨간색으로 표시 (일요일과 동일)
- **토요일**: primary blue, **일요일**: 빨간색으로 표시
- **공휴일 이름**: 하단 일정 리스트의 날짜 오른쪽 하단에 한 줄 accent red 라벨로 표시하며,
  공휴일 유무와 관계없이 날짜·일정 수 헤더 높이를 동일하게 유지

### 구현 세부사항

1. **공휴일 데이터 구조**

   - `_holiday_cache`: 연도별 공휴일 날짜 Set
   - `_holiday_name_cache`: 날짜별 공휴일 이름 Map
   - `_loaded_month_ranges`: 연도별 로드된 월 범위 추적
   - `korean_holidays_cache_v1`: 날짜·이름·조회 완료 월을 저장하는 버전 1 JSON 로컬 캐시

2. **성능 최적화**

   - 월별 3개월만 조회 (12회 → 3회 API 호출로 75% 감소)
   - 중복 호출 방지 (동일 요청 Future 공유 후 캐시 반환)
   - 월별 로드 상태 추적 (앱 재시작 후에도 이미 로드된 월 범위는 스킵)
   - 연도 경계의 날짜는 요청 연도가 아니라 실제 날짜 연도 캐시에 저장

3. **UI 통합**
   - `table_calendar`의 `holidayPredicate` 사용
   - `CalendarBuilders`로 공휴일/주말 스타일링
   - 메인·친구 캘린더 하단 일정 리스트의 날짜 오른쪽 하단에 공휴일 이름을 한 줄로 동적 표시

### 환경 변수

- `.env` 파일에 `DATA_GO_KR_API_KEY` 설정 필요
- `.env.example`에 템플릿 제공

---

## 9. 근무 템플릿 설정 기능

### API 엔드포인트

- **템플릿 조회**: `GET /api/v1/shift-templates/current`
- **템플릿 이름 변경**: `PUT /api/v1/shift-templates/current`
- **근무 타입 목록 조회**: `GET /api/v1/shift-types` (기존)
- **근무 타입 추가**: `POST /api/v1/shift-types`
- **근무 타입 수정**: `PUT /api/v1/shift-types/:shift_type_id`
- **근무 타입 삭제**: `DELETE /api/v1/shift-types/:shift_type_id`

### 데이터 모델 구조

#### 템플릿 관련 모델

- `ShiftTemplateApiModel`: 템플릿 기본 정보 (template_id, template_name, owner_user_id)
- `ShiftTemplateVersionApiModel`: 템플릿 버전 정보 (version_no, effective_from)
- `UpdateTemplateNameRequest`: 템플릿 이름 변경 요청

#### 근무 타입 관련 모델

- `CreateShiftTypeRequest`: 근무 타입 추가 요청 (code, name, color, start_time, end_time, sort_order)
- `UpdateShiftTypeRequest`: 근무 타입 수정 요청 (Partial Update 지원)
- `DeleteShiftTypeResponse`: 근무 타입 삭제 응답

### 상태 관리

- **Provider 타입**: `StateNotifierProvider`
- **이유**:
  - 사용자 액션에 따른 상태 변경 (추가/수정/삭제)
  - 로딩 상태 및 에러 상태 관리 필요
  - 여러 API 호출을 순차적으로 처리
- **상태 구조**:
  ```dart
  class ShiftTemplateSettingsState {
    final String? templateId;
    final String? templateName;
    final List<ShiftTypeApiModel> shiftTypes;
    final bool is_loading;
    final String? error;
  }
  ```

### UI 디자인

- **디자인 시스템**: iOS Cupertino 디자인 가이드라인 준수
- **주요 컴포넌트**:
  - `CupertinoListSection.insetGrouped`: iOS 스타일 리스트 섹션
  - `CupertinoListTile`: 리스트 아이템
  - `CupertinoDatePicker`: 시간 선택 피커 (24시간 형식)
  - `CupertinoActionSheet`: 색상 선택 시트

### 시간 처리

- **시간 형식**:
  - 서버: "HH:mm:ss" (예: "07:30:00")
  - UI 표시: "HH:mm" (예: "07:30")
- **시간 선택**: `CupertinoDatePicker` with `CupertinoDatePickerMode.time`
- **24시간 형식**: `use24hFormat: true` 사용
- **시간 제거**: 각 X 버튼은 해당 시간만 제거하며, 한쪽만 남은 중간 상태는 허용
- **저장 검증**: 완료 시 시작시간/종료시간은 둘 다 있거나 둘 다 없어야 함

### 유효성 검사

1. **코드 중복 검사**

   - 같은 템플릿 내에서 코드는 유니크해야 함
   - 편집 모드에서는 자기 자신 제외

2. **시간 일관성 검사**

   - 시작시간과 종료시간은 둘 다 있거나 둘 다 없어야 함
   - 하나만 있는 경우 validation error

3. **필수 필드 검사**
   - 코드, 이름은 필수
   - 색상, 시간, 정렬 순서는 선택

### 에러 처리

- **에러 코드 매핑**:
  - `TEMPLATE_NOT_FOUND`: 활성 템플릿을 찾을 수 없음
  - `SHIFT_TYPE_NOT_FOUND`: 근무 타입을 찾을 수 없음
  - `DUPLICATE_CODE`: 같은 템플릿 내 코드 중복
  - `IN_USE`: 사용 중인 근무 타입 삭제 불가
  - `FORBIDDEN`: 다른 사용자의 리소스 접근 시도
  - `VALIDATION_ERROR`: 입력값 검증 실패

### Partial Update 처리

- `UpdateShiftTypeRequest`는 제공된 필드만 업데이트
- 시간 필드는 특별 처리:
  - 둘 다 null이면 스케줄 삭제
  - 둘 다 값이 있으면 스케줄 업데이트/생성
  - 하나만 null이면 validation error (클라이언트에서 체크)

### 네비게이션

- **진입 경로**: 설정 페이지 → "근무 설정" 메뉴
- **화면 전환**: `Navigator.push(CupertinoPageRoute(...))`
- **모달**: 근무 타입 추가/편집은 별도 페이지로 전환 (CupertinoPageRoute)

### 파일 구조

```
lib/features/calendar/
├── data/
│   ├── models/
│   │   ├── shift_template_api_model.dart (신규)
│   │   └── shift_type_api_model.dart (확장)
│   └── services/
│       ├── shift_template_service.dart (신규)
│       └── shift_type_service.dart (확장)
├── presentation/
│   ├── pages/
│   │   └── shift_template_settings_page.dart (신규)
│   ├── providers/
│   │   └── shift_template_settings_provider.dart (신규)
│   └── widgets/
│       ├── shift_type_card.dart (신규)
│       └── shift_type_form_modal.dart (신규)
```

---

## 캘린더 확장 보기 모드 (2026-01)

### 문제 정의

- 기존 달력은 위로 스크롤 시 월 → 2주 → 1주로 축소되는 기능만 존재
- 사용자가 한눈에 근무 코드를 확인하기 어려움 (작은 원형 마커만 표시)
- 달력 영역을 확장하여 날짜별 근무 코드를 직접 표시하는 기능 필요

### 결정 사항

#### 1. 드래그 감지 방식: Listener vs GestureDetector

**선택: `Listener` 위젯 사용**

- **이유**:

  - `GestureDetector`는 `TableCalendar`의 내부 `PageView` 제스처와 충돌
  - `Listener`는 포인터 이벤트 레벨에서 동작하여 다른 제스처 인식기와 독립적
  - `behavior: HitTestBehavior.translucent` 설정으로도 해결되지 않음

- **구현**:

```dart
Listener(
  onPointerDown: _onPointerDown,
  onPointerMove: _onPointerMove,
  onPointerUp: _onPointerUp,
  child: TableCalendar(
    availableGestures: AvailableGestures.horizontalSwipe,
    // ...
  ),
)
```

#### 2. 날짜 셀 높이 관리

**선택: 고정 높이 SizedBox 사용**

- **문제**: 근무 코드가 있는 날짜와 없는 날짜의 높이가 달라 UI가 불균형
- **해결**: 모든 날짜 셀에 고정 높이(56px) 적용
  - 날짜 숫자 영역: 28px
  - 근무 코드 영역: 16px
  - 여백: 2px

```dart
return SizedBox(
  height: 56, // 고정 높이
  child: Column(
    children: [
      SizedBox(height: 28, child: /* 날짜 숫자 */),
      const SizedBox(height: 2),
      SizedBox(height: 16, child: /* 근무 코드 */),
    ],
  ),
);
```

#### 3. 이전/다음 달(Outside Days) 처리

**선택: `outsideBuilder` 추가 및 투명도 적용**

- **문제**: 기본적으로 이전/다음 달 날짜는 확장 모드가 적용되지 않음
- **해결**: `outsideBuilder`에서 `isOutside: true` 파라미터로 투명도(0.4) 적용

```dart
outsideBuilder: (context, date, focused) {
  if (_is_expanded_view) {
    return _buildExpandedDayCell(
      date: date,
      textColor: textColor,
      isOutside: true, // 투명도 0.4 적용
    );
  }
  // ...
},
```

#### 4. 확장/축소 전환 임계값

**선택: 50픽셀**

- **이유**: 사용자의 의도적인 드래그와 실수로 인한 터치를 구분
- **동작**:
  - 아래로 50px 이상 드래그: 확장 모드 활성화
  - 위로 50px 이상 드래그: 확장 모드 비활성화

### 관련 파일

```
lib/features/calendar/presentation/pages/calendar_page.dart
├── _is_expanded_view: 확장 모드 상태
├── _pointer_start_y: 드래그 시작 위치
├── _calendarRowHeight: 동적 행 높이 getter
├── _buildExpandedDayCell(): 확장 모드용 날짜 셀 빌더
├── _onPointerDown/Move/Up(): 포인터 이벤트 핸들러
└── CalendarBuilders 내 각 빌더에 확장 모드 분기 추가
```

---

## 근무표 스와이프 삭제 서버 연동 (2026-01)

### 문제 정의

- 근무 일정 스와이프 삭제 시 로컬에서만 삭제되고 서버에 반영되지 않음
- `_schedules` 맵에 `shiftTypeCode`만 저장되어 삭제 API에 필요한 `work_shift_id`가 없음

### 결정 사항

#### 1. work_shift_id 저장 방식

**선택: 별도의 `_work_shift_ids` 맵 추가**

- **대안 1**: `_schedules`의 타입을 `Map<DateTime, WorkShiftApiModel?>`로 변경
- **대안 2**: 별도의 `_work_shift_ids: Map<DateTime, String>` 맵 추가

- **선택 이유**:
  - 기존 코드의 변경 최소화 (기존 `_schedules` 사용 코드 그대로 유지)
  - 삭제 API에 필요한 `work_shift_id`만 별도 관리
  - 메모리 효율성 (전체 모델 대신 ID 문자열만 저장)

```dart
// 기존 (유지)
final Map<DateTime, String?> _schedules = {};

// 신규 (추가)
final Map<DateTime, String> _work_shift_ids = {};
```

#### 2. 삭제 시점 처리: onDismissed vs confirmDismiss

**선택: `confirmDismiss` 사용**

- **대안 1**: `onDismissed`에서 API 호출 후 실패 시 상태 복원
- **대안 2**: `confirmDismiss`에서 API 호출 후 결과에 따라 삭제 허용/취소

- **선택 이유**:
  - UX 측면에서 더 자연스러움 (삭제 애니메이션 완료 전에 결과 확인)
  - 실패 시 UI가 원래 상태로 자동 복원됨 (별도 상태 복원 로직 불필요)
  - Flutter의 권장 패턴 (`confirmDismiss`는 이런 용도로 설계됨)

```dart
Dismissible(
  confirmDismiss: (_) => _confirmDeleteWorkShift(_selected_day),
  onDismissed: (_) {
    // confirmDismiss에서 이미 처리됨
  },
  // ...
)
```

#### 3. 로컬 전용 데이터 처리

**선택: work_shift_id가 없으면 로컬에서만 삭제**

- **문제**: 근무 추가 모드에서 추가 후 저장하지 않은 데이터는 `work_shift_id`가 없음
- **해결**: `work_shift_id` 유무로 분기
  - 있으면: 서버 API 호출 후 로컬 삭제
  - 없으면: 로컬에서만 삭제 (서버에 저장 안 된 데이터)

```dart
if (workShiftId == null) {
  // 로컬에만 있는 데이터 (서버에 저장 안 됨)
  setState(() {
    _schedules.remove(normalizedDate);
  });
  return true;
}
```

### API 연동

- **엔드포인트**: `DELETE /api/v1/work-shifts/:work_shift_id`
- **서비스**: `WorkShiftService.deleteWorkShift(String workShiftId)`
- **응답**: 성공 시 200 OK

### 관련 파일

```
lib/features/calendar/presentation/pages/calendar_page.dart
├── _work_shift_ids: 날짜별 work_shift_id 매핑
├── _confirmDeleteWorkShift(): 삭제 확인 및 서버 API 호출
└── _buildScheduleItem(): Dismissible에 confirmDismiss 적용

lib/features/calendar/data/services/work_shift_service.dart
└── deleteWorkShift(): 기존 삭제 API 메서드 (변경 없음)
```
