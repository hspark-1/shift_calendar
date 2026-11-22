# iPhone 근무표 위젯

## 범위와 진입

2026-11-21의 홈/잠금 위젯에 2026-11-22 사용자 선택 방안1(오늘/내일 별도 항목)을 적용했다. 같은 extension의 WidgetBundle이 위젯 추가 목록에 **오늘 근무**와 **내일 근무**를 제공한다. WidgetKit 기본 탭 동작으로 ShiftMate를 열고 기존 인증/가입 게이트를 따른다. 새 route/analytics 이벤트는 없다. 월간·친구 근무표·개인 일정·네트워크 백그라운드 갱신은 후속 범위다.

| 표시 위치 | family | 오늘 근무 항목 | 내일 근무 항목 | 최소 iOS |
| --- | --- | --- | --- | --- |
| 홈 소형 | systemSmall | 오늘 코드/이름·시작/종료 + 내일 코드/시간 | 내일 코드/이름·시작/종료 + 모레 코드/시간 | 15 |
| 홈 중형 | systemMedium | 이번 주·다음 주 각7일의2행 근무표 | 제공하지 않음 | 15 |
| 잠금 원형 | accessoryCircular | 오늘 코드 | 내일 코드 | 16 |
| 잠금 직사각형 | accessoryRectangular | 오늘 코드/이름/시간 | 내일 코드/이름/시간 | 16 |
| 잠금 시계 위 한 줄 | accessoryInline | 오늘 코드/시간 | 내일 코드/시간 | 16 |

오늘 항목의 중형은 기존 kind를 유지하면서 이번 주·다음 주2행으로 확장했다(ADR-0097). 공통 월~일 요일 아래 각 행에 날짜/코드를 표시한다. ADR-0099 사용자 후속으로 왼쪽의 이번 주·다음 주 라벨/예약 공간을 제거해7개 날짜 셀이 전체 너비를 사용한다. 상단에는14일 날짜 범위, 현재 날짜에는 기존 강조를 제공한다. 중형과 오늘/내일 소형 모두 갱신/기준 시각 문구를 표시하지 않는다(ADR-0099). 별도 날짜 설정 없이 원하는 항목을 추가하면 된다. 소형 헤더·잠금 원형/직사각형/한 줄에 오늘/내일을 표시하며 각 현지 자정 이후에도 선택한 상대 날짜를 유지한다.

잠금 시간은 `23:00 - 07:00`처럼 **익일 문구를 생략**한다(ADR-0096). 사용자 정의 코드/이름은 그대로 표시하며 VoiceOver의 잠금 시간도 동일하다. 홈 시간은 기존 `23:00 - 익일 07:00`을 유지한다. 시간 없는 타입은 한 줄에서 `내일 OFF · 휴무`, 미등록은 `내일 등록된 근무 없음`, 로그아웃/미동기화/대상일 만료는 `ShiftMate · 앱에서 동기화`다. OFF를 임의 생성하거나 미동기화를 근무 없음으로 처리하지 않는다.

2026-11-22 디자인 검토(ADR-0098)로 홈의 앱 이름을 대상일/`2주 근무`로 대체하고 근무 코드에 기존 앱의 파랑 계열 강조를 사용한다. 배경·보조 글자는 light/dark별 토큰이다. 글자 확대는 기존 최대xxxLarge이며 코드/이름이 가로로 안 들어가면 줄을 나누고, 세로 공간까지 부족하면 코드/시간을 우선한다. 중형의 긴 코드는 읽을 수 없을 정도로 축소하지 않고 줄임 표시한다. 전체 원문은 VoiceOver에 보존한다. 잠금 직사각형은 대상일·코드·이름 요약과 큰 시간의2줄로 배치한다(ADR-0099). 시간은 caption12pt에서 기본22pt/동적 최대26pt로 확대하며 요약행만 끝을 줄인다. 시간을 우선하고 최소 축소 비율은0.85다. 시간의 구분자는 공간 절약을 위해 `23:00–07:00`으로 표시하며 원래 시간/VoiceOver는 보존한다. 원형/한 줄은 기존 역할을 유지한다.

중형의 오늘 날짜는 fullColor에서 채운 캡슐, accented/vibrant에서 윤곽선으로 구분한다. 근무색은 fullColor의 낮은 농도 배경에만 사용하며 단색 모드에서는 배지를 비우고 코드·날짜/윤곽·굵기를 유지한다. `widgetAccentable`은 코드/핵심 제목/오늘에 적용하고 iOS16부터 renderingMode를 읽는다. iOS15 홈은 fullColor 대체 레이아웃이다. 모든 family의 privacySensitive·removable containerBackground와 기존 시스템 여백을 유지한다.

## 홈 소형의 공간·정보 재배치 (ADR-0100)

사용자 후속 피드백으로 큰 코드와 작은 후속일 코드 사이에 남던 공간을 재구성했다. 대상일/날짜 헤더 아래에 **코드 배지+근무명**, **시작/종료2열**, **내일/모레 코드와 시간**을 배치한다. 기본 시간은18pt로 기존 단일 caption 시간행보다 크게 읽는다. 야간은 종료 레이블에 `익일 종료`를 표시해 홈의 익일 의미를 유지한다. 코드 배경은 저장된 사용자 색을 밝은 모드0.12/어두운 모드0.18 농도로만 사용하며 글자는 기존 대비 토큰이다. accented/vibrant에서는 배경을 비우고 윤곽선을 사용한다.

소형의 추가 정보는 기존 스냅샷의 **후속일 시간/이름**이다. `time_label` 검증을 통과한 시작/종료만 HH:mm 두 열로 나누며 근무 중/남은 시간·실제 출퇴근 상태를 계산하지 않는다. 시간 없는 타입은 이름과 `시간 지정 없음`, 미등록은 `근무 미등록`으로 유지한다. 미조회 후속일은 동기화 필요다.

큰 글자/세로 공간 부족은 compact 배치, 긴 코드/이름은 적응형 줄 나눔/줄임 표시를 사용한다. 후속일의 긴 코드나 큰 글자 때문에 시간을 넣을 수 없으면 코드만 시각 표시하고 전체 코드·이름/시간은 VoiceOver로 읽는다. iOS15는 같은 정보의 단일 Text/줄임 표시 대체 경로다. 기본 여백과 기준 시각 제거를 유지하며 중형/잠금 레이아웃은 이 후속 작업으로 수정하지 않는다.

## 디자인 요구사항과 처음부터의 설계

근거는 기존 오늘/내일 선택(ADR-0096), 중형2주/갱신 문구 제거(ADR-0097), 제품의 날짜·근무 코드/이름/색/시간 계약이다. 특정 직종, 출퇴근 중 상태, 남은 시간, 다음 휴무 계산 요구는 확인되지 않았으므로 추가하지 않는다.

| 형태 | 먼저 답할 질문 / 정보 순서 | 디자인 결정 |
| --- | --- | --- |
| 소형 오늘/내일 | 언제의 근무인가 → 코드·이름 → 시간 → 내일/모레 | 대상일+날짜/요일 헤더, 근무 코드 배지/이름, 시작·종료2열, 구분선 아래 후속일 코드/시간. 미등록은 `근무 미등록`으로만 표시해 휴무와 구분 |
| 중형2주 | 이번 주/다음 주에 무슨 근무인가 → 오늘 위치 | `2주 근무`+날짜 범위, 월~일 공통 헤더와2행. 오늘 날짜 캡슐, 연도가 바뀌면 범위 양끝에 연도. 갱신 시각 없음 |
| 잠금 원형 | 오늘/내일에 무슨 코드인가 | 시스템 원형 배경+대상일/코드만. 꾸밈/시간·진행률 없음 |
| 잠금 직사각형 | 근무 요약 → 큰 시간 | 대상일·코드·이름을 상단 한 줄에 묶고 하단에 큰 시간. 긴 요약은 줄이되 시간은 우선 배치 |
| 잠금 한 줄 | 대상일·코드·시간을 한 번에 | 기존 단일 Text와 잠금 익일 생략 유지. 시스템이 한 줄 폭/글꼴을 관리 |

- **신선도:** 사용자 후속 요청(ADR-0099)으로 소형의 `M.d HH:mm 기준`을 제거했다. 모든 홈 위젯은 갱신 시각을 숨긴다. 스냅샷의 updated_at 검증/오프라인 캐시·앱 복귀 동기화·만료 처리는 그대로 유지하며 실시간 갱신으로 바뀐 것은 아니다.
- **상태:** 미등록/시간 없는 사용자 타입/OFF/미조회/만료를 합치지 않는다. 미조회·만료는 `동기화 필요`와 앱에서 확인 안내, 범위 내 빈 날짜는 미등록이다. `OFF`를 생성하거나 코드로 시간/직종을 추정하지 않는다.
- **접근성:** 날짜·텍스트·윤곽으로 의미를 전달하고 색에만 의존하지 않는다. 보조행과 주간 날짜 셀도 코드·이름·시간 전체를 읽는다. 실제 VoiceOver 조작/개인정보 가림·OS 합성 결과는 별도 기기 인수다.
- **변경 범위:** 표시·접근성·갤러리 설명·Xcode Preview6개만 개선했다. 데이터/API/DB/상태/타임라인/kind/오늘·내일 family·탭/서명은 유지한다. 근무일 상세 딥링크·별도 월간/친구 위젯은 요구/라우팅 계약 확인 후 별도 검토한다.

디자인 근거는 [Apple Widgets HIG](https://developer.apple.com/design/human-interface-guidelines/widgets)와 [accented/Liquid Glass 지침](https://developer.apple.com/documentation/widgetkit/optimizing-your-widget-for-accented-rendering-mode-and-liquid-glass)이다. 스킬에서 전반적인 앱 재생성 대신 위젯의 정보 위계·Dynamic Type·색 외 식별 규칙을 적용했다.

## 데이터와 상태 흐름

```text
AuthWrapper (인증·프로필 완료/계정·시간대 변경, 앱 resumed)
  → WidgetSyncCoordinator.setSession / sync
  → CalendarService.getCalendarRange → 기존 인증 Dio → GET /calendar/range
  → 응답의 workShifts만 ShiftWidgetSnapshot으로 변환
  → home_widget 0.10.0 → App Group UserDefaults의 JSON 단일 키
  → WidgetCenter.reloadTimelines(ofKind:) (오늘/내일 각각)
  → ShiftTimelineProvider → SwiftUI family별 화면

근무 추가/수정/배치/확정 삭제·근무 타입 수정/삭제 성공
  → 서비스 provider의 on_changed → sync(force: true)

로그아웃 시작 / 탈퇴 접수·세션 종료
  → AuthNotifier → setSession(owner_id: null)
  → 늦은 조회 무효화 → 직렬 저장 큐의 JSON 삭제 → reload 요청
```

- UI/domain state는 기존 캘린더가 소유한다. 위젯 coordinator는 서버 확정 응답만 보관하며 화면의 임시 근무 draft/되돌리기 삭제 예약을 사용하지 않는다. 삭제 서버 확정이 성공해야 새 데이터를 조회한다.
- 위젯 전용 provider는 앱 수명 동안 존재하며 dispose에서 진행 중 응답을 무효화한다. 계정/요청 revision과 직렬 저장 큐로 이전 계정·수정 이전 요청·저장 중 로그아웃이 새 데이터 위에 쓰는 일을 막는다. 일반 복귀 요청은 진행 중 조회를 합치며 mutation은 새 revision으로 강제 조회한다.
- 인증된 가입 완료 사용자만 동기화한다. 로그인/프로필 완료·계정 ID/시간대 변경은 세션 경계를 다시 설정한다. 프로필 저장의 로딩/오류 변경만으로 동기화를 반복하지 않는다. Android/web은 no-op다.
- 동일 계정·시간대의 마지막 캐시는 오프라인 시작에서 유지한다. 다른 계정은 새 조회 전에 삭제한다. 최초 미인증 판정·로그아웃·탈퇴 접수/401/탈퇴 진행 중 세션 종료에서는 삭제하며, 탈퇴 재인증 필요/실패는 로그인 상태와 캐시를 유지한다.
- Dio 오류는 기존 ApiException 계약을 사용한다. 조회401/403이면 공유 데이터도 비운다. 네트워크/5xx는 마지막 데이터를 유지하며 다음 복귀/변경에서 재시도한다. 위젯 실패는 인증/근무 저장을 실패시키지 않고 고정 메시지만 기록한다. 계정/근무/토큰 원문을 로그에 남기지 않는다. 저장소를 사용할 수 없으면 OS 위젯 내용의 즉시 제거를 보장할 수 없으며 다음 앱 동기화/정리에서 재시도해야 한다.

## 공유 계약과 날짜

- App Group: `group.com.hspark.shiftmate`
- Extension bundle ID: `com.hspark.shiftmate.ShiftMateWidget`
- 오늘 kind: `ShiftMateShiftWidget` (기존 ID 보존)
- 내일 kind: `ShiftMateTomorrowShiftWidget`
- JSON 키: `shiftmate_widget_snapshot_v1`
- 버전: `schema_version=1`

```json
{"schema_version":1,"owner_id":"계정UUID","timezone":"Asia/Seoul","updated_at":"2026-11-21T00:00:00.000Z","start_date":"2026-11-16","end_date":"2026-12-27","shifts":[{"date":"2026-11-21","code":"N","name":"나이트","color":4283657726,"start_time":"23:00:00","end_time":"07:00:00"}]}
```

두 kind는 동일 JSON 키/스키마를 읽는다. reload는 두 kind를 모두 시도하고 하나가 실패해도 다른 요청을 생략하지 않는다. 계정 ID는 캐시 귀속 검사에만 사용한다. 이메일·이름·프로필 사진·근무 ID·메모·개인 일정·JWT/refresh token은 공유하지 않는다. `saveWidgetData(..., null, deleteFile: false, appGroupId: ...)`로 키를 제거하고 갱신을 요청한다. SDK의 새 per-call appGroupId 인자를 사용하므로 전역 groupId 초기화에 의존하지 않는다.

서버 사용자 IANA timezone이 유효하면 사용하고, 없거나 잘못되었으면 기기 IANA timezone을 사용한다. work_date는 날짜 성분을 유지하며 UTC instant로 재해석하지 않는다. 해당 시간대의 이번 주 월요일부터 42일을 기존 API로 조회하고 전체 스냅샷을 교체한다. 시간대 식별자를 확보하지 못하면 임의 시간대를 만들지 않고 동기화를 실패시킨다.

Swift는 버전/시간대/정확한 날짜/갱신 시각/93일 미만의 범위를 검증한다. 각 현지 자정의 entry와 마지막 조회일 다음 날의 만료 entry를 만든다. Calendar 날짜 덧셈을 사용하므로 DST의23/25시간 날에도 날짜를 건너뛰지 않는다. ShiftWidgetDayContent가 같은 entry의 현지 날짜에0일(오늘)/1일(내일)을 더해 근무를 선택한다. 내일 소형의 보조행은2일 뒤인 모레다. 내일의 대상일이 조회 범위를 벗어나면 마지막 조회일 당일부터 동기화 안내를 표시하며, 기존 자정 entry가 이 경계를 포함한다. 만료 후 과거 근무를 반복하지 않는다. **OS가 timeline 적용/갱신 시점을 관리하므로 즉시 반영과 정확한 자정 실행을 보장하지 않는다.** 마지막 entry 이후1시간에 재조회 기회를 요청하지만 extension 자체는 서버 통신을 하지 않는다. 앱을 오래 열지 않거나 다른 기기에서 변경하면 앱을 열기 전 최신 변경은 알 수 없다.

## Xcode·서명 설정

코드에는 Runner/extension의 entitlement와 target capability, target dependency, `Embed App Extensions`가 연결되어 있다. embedding은 `Thin Binary` 앞에 두어 Flutter 빌드 의존성 순환을 피한다. extension은 Flutter/Pods를 링크하지 않으며 `Widget.xcconfig → Generated.xcconfig`에서 앱 버전/빌드 번호만 공유한다. 앱의 iOS15 최소 지원을 유지한다. Runner/확장의 공유 UserDefaults 접근은 `PrivacyInfo.xcprivacy`의 App Group 사유 `1C8F.1`로 선언한다.

실기기/배포 전에 Apple Developer 팀에서 다음을 확인해야 한다. 로컬 entitlement만으로 포털 등록·배포 profile 준비가 완료되는 것은 아니다.

1. `ios/Runner.xcworkspace`를 열고 기존 팀을 확인한다.
2. Apple Developer에서 위 App Group과 extension App ID가 등록되어 있는지 확인한다.
3. Runner와 ShiftMateWidget 양쪽의 Signing & Capabilities에서 같은 App Group을 연결한다.
4. 개발·배포 provisioning profile 양쪽에 해당 entitlement가 포함되도록 갱신하고 서명 빌드한다.
5. 앱 실행·로그인/가입 완료 후 위젯 추가 목록에서 ShiftMate의 `오늘 근무` 또는 `내일 근무`를 선택한다. 홈 소형과 잠금3형식은 둘 다 제공하며 중형 주간은 오늘 항목에만 있다. 한 줄은 잠금화면 사용자화에서 시계 위 날짜 영역을 누르고 원하는 항목을 고른다.

이번 작업은 Apple 포털/권한을 변경하거나 운영 업로드를 하지 않는다. 실제 서명/App Group 전달·잠금화면 개인정보 가림·앱 열기·실제 OS 자정 갱신은 실기기 인수 대상이다. 결과는 WORKLOG를 따른다.

## 파일 역할·의존성·사용 예

| 신규 파일 | 역할 / 의존성 / 사용 예 |
| --- | --- |
| `lib/features/home_widget/data/shift_widget_snapshot.dart` | 근무 API 모델+timezone을 사용하는 JSON 계약/42일 범위 계산. coordinator에서 `rangeFor(now, timezone)`와 `toJson()` 호출 |
| `lib/features/home_widget/data/home_widget_store.dart` | 테스트 가능한 저장소 경계와 home_widget adapter. `write(json)`/`write(null)` 후 두 kind의 `reload()` |
| `lib/features/home_widget/application/widget_sync_coordinator.dart` | Riverpod·기존 CalendarService·FlutterTimezone·저장소의 앱 수명 동기화 경계. `setSession(owner_id: user.id, timezone: user.timezone)` / `sync(force: true)` |
| `ios/ShiftMateWidget/ShiftWidgetData.swift` | Foundation JSON 검증·날짜/시간·주간/자정 및 ShiftWidgetDay/DayContent의 날짜 선택. provider의 `decode`/`entryDates`, UI의 `ShiftWidgetDayContent(reference_date:snapshot:day:)` 사용 |
| `ios/ShiftMateWidget/ShiftMateWidget.swift` | WidgetKit provider/entry·오늘5family/내일4family와 공통 SwiftUI 표시. `@main ShiftMateWidgetBundle`이2개 configuration을 제공 |
| `ios/ShiftMateWidget/Info.plist` | WidgetKit extension point·표시 이름. extension INFOPLIST_FILE로 참조 |
| `ios/ShiftMateWidget/ShiftMateWidget.entitlements` | Runner와 같은 App Group. extension CODE_SIGN_ENTITLEMENTS로 참조 |
| `ios/ShiftMateWidget/PrivacyInfo.xcprivacy` | 공유 UserDefaults required-reason API 사유. Runner/extension Resources에 포함 |
| `ios/Flutter/Widget.xcconfig` | 기존 Flutter 생성 설정의 버전값 재사용. extension3개 build configuration에서 참조 |
| `test/features/home_widget/widget_sync_coordinator_test.dart` | Flutter test·timezone·모의 저장소/Dio/MethodChannel로 날짜/민감 필드/경합/실제 mutation 연결을 검증. 아래 명령 사용 |
| `ios/ShiftMateWidgetTests/ShiftWidgetDataTests.swift` | 실제 Swift 제품 모델과 Dart 출력 fixture를 함께 실행하는 Foundation 단독 회귀. 아래 swiftc 명령 사용. 앱에 포함하지 않음 |
| `_docs/IOS_WIDGET_GUIDE.md` | 구현 계약·서명 인수·실행/검증/롤백 안내. 이번 작업의 정본 |

기존 `main.dart`는 auth/lifecycle 연결, `auth_provider.dart`는 세션 종료 정리, 근무/타입 서비스의 선택적 on_changed는 성공 후 갱신 신호만 담당한다. 기존 반환값/에러/API 응답은 유지한다.

## 디자인 검토 산출물·재현

`artifacts/widget_redesign_2026-11-22/`는 실제 SwiftUI 표시를 검토하기 위한 자료다. 예시 근무/기준일2026-11-20을 쓰며 실제 계정/서버 데이터가 아니다.

| 신규 파일 | 역할 / 의존성 / 사용 예 |
| --- | --- |
| `WidgetRenderTests.swift` | 제품 Foundation/SwiftUI와 ImageRenderer/XCTest의9개 조합(오늘5+내일4)×14조건+소형/잠금 직사각형 좁은 폭·큰 글자4개+소형 후속일 근무/큰 글자4개(총134PNG) 렌더러. 라이트/다크·최대 글자·긴 코드·둘의 조합·미등록/시간 없음·로그아웃/만료·다음 주 미조회·연말·좁은 폭(잠금 직사각형150×64 포함)·accented/vibrant를 PNG로 출력 |
| `render_widgets.py` | Python3·기존 Ruby/xcodeproj gem·Xcode/Simulator로 임시 프로젝트/제품 표시 사본을 만들어 위 렌더러 실행. 아래 명령 사용. 제품 소스는 수정하지 않으며 읽기 전용 WidgetFamily만 테스트 생성 인자로 치환 |
| `comparison.png` | 같은 기준일/데이터의 전후 소형·중형·잠금 직사각형 비교. 실제 렌더 PNG를 배치한 검토판 |
| `home-comparison.png` | ADR-0100 직전/이후의 오늘·내일 홈 소형을 비교하는 실제 렌더 검토판. SwiftUI PNG와 macOS AppKit 배치에 의존하며 이 문서/응답에서 열어 검토 |
| `overview.png` | 개선 후 오늘/내일·2주/잠금 전 형식의 라이트·다크 예시. 최종 디자인 검토용 |
| `edge-cases.png` | 큰 글자·긴 코드·미등록/미조회·단색 모드 등 대표 제약 조건의 실제 렌더 모음 |

```sh
python3 artifacts/widget_redesign_2026-11-22/render_widgets.py --device <실행할-Simulator-UUID> --output /private/tmp/shiftmate-widget-design-render --ruby /opt/homebrew/opt/ruby/bin/ruby --gem-home /opt/homebrew/Cellar/cocoapods/1.16.2/libexec
```

로컬에서 확인한 기존 xcodeproj gem 경로를 예시로 사용했다. 환경에 맞는 Ruby/GEM_HOME을 전달하며 새 gem을 설치하지 않는다. 명령은 지정한 시뮬레이터를 사용하므로 종료 상태라면 먼저 실행한다. 표시 사본은 widget 설정/bundle/Preview를 제외한다. 제품 파일의 `#Preview`6개는 Xcode에서 실제 WidgetKit 갤러리/family를 검토하는 진입점이며 자동 실행 인수 결과가 아니다.

ImageRenderer는 실제 WidgetKit host가 아니다. accented/vibrant 환경 분기·텍스트 대비는 확인하지만 OS의 재착색/투명 유리 배경·StandBy 배경 제거·privacySensitive에 의한 가림·시스템 placeholder 합성을 재현하거나 인수 완료로 간주하지 않는다. 정확한 실행 결과·확장 빌드·확인한 이미지는 WORKLOG를 따른다.

## 검증 명령

```sh
mkdir -p /private/tmp/shiftmate-widget-20261121
WIDGET_CONTRACT_OUTPUT=/private/tmp/shiftmate-widget-20261121/contract.json flutter test --no-pub test/features/home_widget test/features/auth/presentation/providers/auth_provider_test.dart --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key
xcrun swiftc -module-cache-path /private/tmp/shiftmate-widget-20261121/swift-cache ios/ShiftMateWidget/ShiftWidgetData.swift ios/ShiftMateWidgetTests/ShiftWidgetDataTests.swift -o /private/tmp/shiftmate-widget-20261121/data-tests
/private/tmp/shiftmate-widget-20261121/data-tests /private/tmp/shiftmate-widget-20261121/contract.json
xcodebuild -project ios/Runner.xcodeproj -target ShiftMateWidget -configuration Debug -sdk iphonesimulator ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build
```

Flutter3.38의 generic simulator 빌드가 `arm64 x86_64`를 하나의 요구 아키텍처처럼 판정하면, 실행 가능한 simulator UUID를 지정한 `xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Debug -sdk iphonesimulator -destination id=<UUID> ARCHS=arm64 ONLY_ACTIVE_ARCH=YES CODE_SIGNING_ALLOWED=NO build`로 검증한다. 실제 수행/결과·렌더 도구는 WORKLOG에 기록한다. 모의·unsigned 빌드 통과를 실계정/실기기 인수로 기록하지 않는다.

## 영향·롤백

Behavior change는 오늘/내일 선택·잠금 익일 문구 생략과 중형2주 표시/갱신 문구 제거, ADR-0098의 홈 제목·코드 강조/오늘 캡슐·잠금3줄/긴 코드 줄임·소형 기준 시각 문구였다. 후속 ADR-0099로 중형 행 라벨/모든 홈 기준 시각을 제거하고 잠금 직사각형을 큰 시간 중심2줄로 바꿨다. ADR-0100은 소형을 코드 배지/시작·종료/후속일 시간3구역으로 재배치한다. 기존 kind/family와 공유 JSON/타임라인 정책을 보존하며 양쪽 kind의 저장/삭제 후 갱신을 요청한다. 중형 다음 주의 날짜가 조회 범위 밖이면 ·/VoiceOver 동기화 필요로 표시해 범위 내 미등록(—)과 구분한다. 기존 서버/API/DB/env·Android 위젯·라우팅·권한 정책·앱 버전·App Groups/서명/extension ID·패키지/lock은 이번 후속 작업에서 변경하지 않는다.

배포 전 롤백은 이번 위젯 Dart/native/test·호출부·패키지/lock·Xcode target/entitlement·문서 diff만 복구하고 pub get/pod install 후 재빌드한다. 이미 제공한 빌드의 공유 데이터를 지우려면 제거 전에 기존 `setSession()` 정리를 실행해야 한다. 로컬 코드를 되돌리는 것만으로 설치 기기의 공유 캐시가 삭제되지는 않는다. 기존 미커밋 인증/UI 변경은 보존한다.

## 공식 근거

- [home_widget0.10.0](https://pub.dev/packages/home_widget), 설치한0.10.0 Dart/Swift 소스의 per-call appGroupId/null 삭제/UIScene 지원을 대조했다.
- [Apple TimelineProvider](https://developer.apple.com/documentation/widgetkit/timelineprovider), [위젯 갱신](https://developer.apple.com/documentation/widgetkit/keeping-a-widget-up-to-date).
- [Apple UserDefaults required-reason API](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype)의 `1C8F.1`.

- [Apple removable widget background](https://developer.apple.com/documentation/widgetkit/displaying-the-right-widget-background): 모든 family에서 containerBackground를 명시한다.

- [Apple WidgetBundle](https://developer.apple.com/documentation/swiftui/widgetbundle), [StaticConfiguration](https://developer.apple.com/documentation/widgetkit/staticconfiguration): 같은 extension의 별도 kind로 오늘/내일 항목을 제공한다.
