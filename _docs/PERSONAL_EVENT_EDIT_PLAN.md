# 메인 캘린더 개인 일정 탭 수정 계획

작성일: 2026-11-12 (Asia/Seoul). 상태: 후속 로컬 구현·자동 검증 완료, 배포/원격·실기기 인수 전. 아래는 구현 전 계획 기록이며 최종 동작은 PROJECT_CONTEXT 상단 구현 절·ADR-0051·EVENT_API_GUIDE와 WORKLOG를 따른다.

구현 보완: 기존 생성 callback/popup의 CreateEventRequest 계약은 유지하고, 공통 PersonalEventFormValue와 별도 UpdateEventRequest·구조화 onUpdate 결과를 추가했다. 수정에 필요한 공용 시간/장소 줄바꿈 보완·렌더 파일이 추가됐다. 성공/재조회 시 그룹 캘린더 캐시도 무효화한다. 신규 렌더 역할/재현·검증 한계는 PROJECT_CONTEXT에 기록했다.

후속 삭제 정책(2026-11-12): 사용자 요청으로 개인 일정/근무 삭제에 토스트 되돌리기를 추가했다. 아래 Undo 미도입은 당시 계획이며, 최신3초 오버레이·취소·수명 정책은 ADR-0053/PROJECT_CONTEXT 상단 절을 따른다. 날짜 캘린더/시간 휠·제목 완료 입력 연결은 ADR-0054, 날짜 확인 확정·오늘 위치/피커 끌기 취소는 ADR-0056을 따른다.

## 1. 목적과 범위

메인 캘린더 하단 선택일 목록에서 **본인 개인 일정 행을 한 번 탭하면 기존 값을 수정**할 수 있게 한다.

- 수정 필드: 제목, 시작/종료 날짜·시간, 종일, 공개 방식(`is_private`), 공개 레벨, 장소, 메모.
- 기존 추가 시트를 생성/수정 두 모드로 재사용한다. 별도 상세 화면을 거치지 않는다.
- 근무 행의 동작, 개인 일정 왼쪽 스와이프 삭제, 친구·그룹 화면의 읽기 전용 정책을 유지한다.
- 반복, 알림, 참석자, 일정 색상, 새 전역 상태관리 계층은 범위 밖이다.
- 이번 작업은 계획/문서만 작성한다. 아래 API·DTO·메서드명과 동작은 **구현 제안**이며 현행 기능으로 해석하지 않는다.

## 2. 확인한 사실과 근거

| 확인한 사실 | 직접 확인한 코드/문서 |
| --- | --- |
| 개인 일정 행은 삭제용 Dismissible로 감싸져 있고 탭 콜백은 없다 | `CalendarPage._buildEventItem()`, `CalendarEventItem` |
| 공용 카드에는 화면별 `event_item_builder` 확장 지점이 있다 | `calendar_schedule_card.dart`의 `CalendarScheduleCard` |
| 기존 폼은 `initialDate`와 `CreateEventRequest` 저장 콜백만 받고 생성 기본값으로 초기화한다 | `personal_event_form_modal.dart`의 생성자·initState·_save |
| 목록 모델에 편집할 모든 필드는 있으나 owner ID·updated_at은 없다 | `EventApiModel` |
| 프론트 서비스는 개인 일정 생성/삭제/기간 조회를 제공하며 updateEvent는 없다 | `calendar_service.dart` |
| notifier의 addEvent는 새 기간에 추가만 한다. 이전 기간 전체에서 같은 ID를 먼저 제거하지 않는다 | `calendar_range_notifier.dart`, `addEventToCalendarDateMap()` |
| 진행 중 range 응답은 현재 맵에 데이터를 병합한다. 수정 후 늦게 오는 구응답을 막는 일정 mutation 처리는 없다 | `CalendarRangeNotifier._loadRange()` |
| 로컬 인접 서버에 개인 일정 POST·GET·DELETE가 있고 PUT/PATCH 수정 route는 없다 | `../shift_calendar_server/src/routes/calendarRoutes.ts`, controller/service, `src/openapi/calendarOpenApi.json` |
| 서버 본인 조회/삭제는 owner_user_id=JWT 사용자·deleted_at IS NULL로 제한한다 | 서버 `getEvents()`·`deleteEvent()` |
| 서버 모델은 is_private를 지원하고 친구/그룹의 타인 private 일정을 제외한다 | 서버 `src/models/Event.ts`, `_docs/EVENT_PRIVACY_GUIDE.md`, 서버 정본 drawio |
| 메인 range는 autoDispose이고 계정 변경 시 인증 provider가 관련 캐시를 무효화한다 | `calendar_range_provider.dart`, `auth_provider.dart`, `main.dart` |

Flutter 루트 `schema.drawio`·`visibility_flow.drawio`도 확인했다. calendars/calendar_shares를 포함한 구형 도면으로 현행 단일 사용자 캘린더와 다르다. 현행 코드·AGENTS DDL·서버 정본 도면의 owner 기반 모델과 private 정책을 따른다. 서버 원격 배포 상태와 수정 endpoint 실응답은 이번 작업에서 검증하지 않았다.

## 3. 화면과 상호작용 제안

1. 메인 선택일 카드의 개인 일정 **행 전체**를 탭 영역으로 만든다. 공용 위젯 자체에 편집 권한을 부여하지 않고 메인의 `event_item_builder`에서 연결한다.
2. `showCupertinoModalPopup`으로 기존 시트를 열고 제목을 `개인 일정 수정`, 저장 버튼을 `변경사항 저장`으로 표시한다. 닫기/저장 접근성 라벨도 수정 모드에 맞춘다.
3. 제목·장소·메모·종일·날짜/시간·private·레벨과 슬라이더 위치를 원본 일정에서 초기화한다. 사용자가 탭한 날짜가 다일 일정 중간 날이어도 일정 전체의 원래 기간을 복원한다.
4. 본인 개인 일정 피드에서만 수정 진입을 제공한다. 목록 DTO에 owner ID가 없으므로 프론트에서 임의 소유자 판정을 추가하지 않는다. 최종 권한 검증은 서버에서 한다.
5. 터치 영역은 최소 44×44 논리px, 버튼 의미/제목·시간을 스크린리더로 제공한다. 개인 일정의 기존 왼쪽 chevron은 `연필 + 수정` 표시로 교체해 탭 결과를 알리고, 삭제는 기존 왼쪽 스와이프로 제공한다. 근무 행의 chevron은 유지한다. 탭과 가로 스와이프가 서로 실행되지 않는지 검증한다. 구체 표시/처리는 아래 3.1절을 따른다.
6. 편집 시 실질 변경이 없으면 저장을 비활성화하고 API를 호출하지 않는다. trim·빈 선택정보 null 정규화 후 비교하며 private 상태의 레벨도 보존한다.
7. 저장 중 spinner·입력/중복 저장/이탈 차단을 유지한다. 실패하면 입력을 보존하고 `다시 저장`으로 재시도한다. 오류는 필드 인접 또는 하단 기존 오류 영역에 표시한다.
8. 닫기 버튼/OS 복귀/손잡이·본문 최상단 끌기는 현행 ADR-0048/0049에 따라 폐기 확인 없이 닫는다. 충분한 시트 이동 120 논리px 기준과 바깥 탭 닫기 차단을 유지한다.
9. 성공 시 서버 응답을 반영한 후 시트를 닫는다. 현재 선택일이 새 일정 기간에 포함되면 선택일/보는 월을 유지하고, 기간 밖이면 수정된 시작일로 선택일/보는 월을 이동한다. 필요한 월·공휴일만 기존 로딩 흐름으로 불러온다.

### 3.1. 수정·삭제를 함께 제공하는 UX 보완 (2026-11-12)

현행 `_RoundedDeleteDismissible`은 왼쪽으로 미는 동안 노출 폭에 맞춘 둥근 빨간 배경/휴지통을 보여주고, dismiss가 성립하면 `confirmDismiss`에서 DELETE 요청을 보낸다. 노출된 휴지통을 별도 버튼으로 눌러야 하는 구조는 아니다. 삭제 성공/실패·404 처리는 기존 페이지 테스트로 확인할 수 있다. 이 메커니즘을 유지하는 제안이다.

| 상태/입력 | 표시 | 결과 |
| --- | --- | --- |
| 평상시 개인 일정 | 기존 제목·시간·장소·메모 구성 + 오른쪽 `연필 아이콘 + 수정` | 행 전체 탭 또는 수정 표시 위치 탭으로 동일한 편집 시트 열기 |
| 왼쪽으로 미는 중 | 기존 빨간 휴지통 배경과 둥근 모서리. 충분한 노출 폭에서 `삭제` 글자를 함께 표시 | 가로 드래그 중에는 편집 시트를 열지 않음 |
| 짧게 밀고 놓기 | 기존처럼 원래 위치로 복귀 | 삭제 요청0회·수정 진입0회 |
| dismiss 성립 | 삭제 처리 중 행의 탭/추가 삭제 입력 차단, 처리 중 피드백 | 기존 DELETE 성공 후 제거, 실패 시 원위치 복구·오류 안내 |
| 수정 시트 | `개인 일정 수정` 제목·기존 값·하단 `변경사항 저장` | 성공 시 닫기/목록 갱신, 실패 시 입력 보존 |

- **표시 역할**: 기존 왼쪽 chevron만 유지하면 새 탭 수정 동작을 설명하지 못한다. 개인 일정의 오른쪽은 수정을 안내하고, 삭제는 가로 이동으로 드러나는 빨간 영역이 안내한다. `수정`은 기존 primary 토큰·본문 보조 크기를 사용하고 채운 버튼 배경은 추가하지 않는다. 제목 공간을 확보하며 작은 화면/큰 글자에서는 줄바꿈·행 높이 확장을 허용한다.
- **탭/드래그 판별**: 탭 인식기를 Dismissible의 child에 조합하고 pointerDown에서 수정 시트를 열지 않는다. Flutter 제스처 판별에서 탭이 확정된 경우만 수정한다. 스와이프 인식 이후 손을 뗐을 때 탭 콜백이 실행되면 안 된다. 삭제 요청 중에는 같은 ID로 수정이 시작되지 않아야 한다.
- **삭제 배경**: 기존 폭/반경·red 토큰·휴지통 위치를 보존한다. `삭제` 텍스트는 공간이 확보된 때만 표시해 좁은 노출 폭에서 잘림/overflow가 생기지 않도록 한다. 배경은 진행 중 동작 설명이며 별도 누르기 버튼처럼 표현하지 않는다. 삭제 실행 거리/속도 정책은 기존 값을 유지한다.
- **처리 피드백**: 기존 `_deleting_event_ids`는 중복 요청만 막고 setState를 통한 로딩 표시가 없다. 구현 시 개인 일정 행에만 삭제 처리 상태를 반영해 spinner/접근성 `삭제 중`을 제공한다. 수정 중 저장 역시 기존 spinner·입력/이탈 차단을 사용한다. 삭제 성공은 행 제거·일정 수 갱신으로, 수정 성공은 시트 닫힘·최신 행 표시로 확인된다.
- **접근성**: 일정 행을 `… 일정 수정`이라는 단일 주 액션으로 제공하고 시각적 연필/수정 라벨의 중복 낭독을 피한다. 터치 없이도 동일 삭제 기능을 사용할 수 있도록 본인 개인 일정 행에 스크린리더 `삭제` 사용자 지정 액션을 연결한다. 타인/근무 행에 개인 일정 수정 액션을 붙이지 않는다.
- **삭제 범위**: 다일 일정의 어느 날짜에서 실행해도 기존처럼 해당 event_id 전체를 삭제한다. 새로운 삭제 확인창·복원(Undo) 기능은 이 보완안에 추가하지 않는다. 현행 DELETE 계약에는 복원 API가 없으므로 복원이 가능한 것처럼 표시하지 않는다. 시트 닫기의 확인 없는 폐기 정책과도 구분한다.
- **검토 근거/한계**: 페이지/공용 행 코드·삭제 위젯 테스트를 직접 읽고 기존 `artifacts/glass_navigation_2026-11-11/calendar.png`를 확인했다. 해당 캡처는 빈 목록이므로 개인 일정 행 디자인의 시각 검증으로 사용하지 않는다. UI/UX 스킬의 로컬 검색에서 제스처 충돌·처리 피드백 지침을 참고했으며 위 조합은 현행 앱 요구에 맞춘 제안이다. 실제 수정 행·스와이프 중간·삭제 중 상태의 렌더/실기기 검증은 구현 단계에서 수행한다.
- **Behavior change(예정)**: 개인 일정의 평상시 오른쪽 표시가 왼쪽 chevron에서 연필/수정으로 바뀌고, 삭제 배경의 텍스트·처리 중 피드백/접근성 액션을 보완한다. 기존 삭제 요청/성공·오류 처리/근무 행 디자인은 유지한다. 롤백은 개인 일정의 표시/탭 연결·피드백 보완만 되돌린다.

## 4. 폼·시간·요청 데이터 설계

- 폼에 선택적 `initial_event`와 생성/수정 모드를 추가한다. 새 입력은 기존 선택일·09~10시·레벨0·공개 기본값을 유지한다.
- 생성 전용 DTO를 수정 요청에 직접 재사용하지 않는다. 기존 모델 파일에 중립적인 폼 값(`PersonalEventFormValue`)과 별도 `UpdateEventRequest`를 정의하고 페이지에서 create/update DTO로 변환하는 방향을 사용한다. 기존 생성 콜백·팝업 반환 타입·모의 service/test의 사용처도 함께 갱신한다.
- 생성 DTO의 빈 장소/메모 생략 규칙은 유지한다. 수정 DTO는 삭제 의도를 표현하도록 **빈 장소/메모를 명시적 null**로 보낸다.
- 종일 응답 `end_at`은 배타적 종료다. 예: 11/12 00:00~11/15 00:00이면 폼에는 11/12~11/14로 복원하고 저장 시 11/15 00:00으로 변환한다. 로컬 날짜 생성자 `DateTime(year, month, day - 1/+1)`를 사용해 달력 날짜를 계산한다.
- 시간 일정은 응답의 로컬 시작/종료를 복원하고 전송 시 UTC ISO로 변환한다. 종일 토글을 왕복해도 입력 시간과 private 전환 전 레벨을 유지한다.
- 날짜/시간을 수정하지 않았으면 원래 instant를 보존한다. 제목만 변경하는데 초/밀리초가 0으로 잘리거나 타임존 변환으로 기간이 달라지지 않도록 한다. 실제 시간 변경 시 기존 분 단위 피커 값을 적용한다.
- 날짜 피커는 현행 2000~2050 범위를 사용한다. 범위 밖 원본을 읽었다면 조용히 clamp/덮어쓰지 않고 원본을 보존하고 날짜 변경 가능 범위를 안내한다.
- 제목 공백, 종료≤시작, 레벨 범위, boolean 타입을 검증한다. 날짜 선후 자동 보정과 기존 공용 DatePickerSheet/TimePickerSheet를 재사용한다. 이 기능 때문에 기존 전체 폼을 별도 Form 체계로 리팩토링하지 않는다.

## 5. 서버 수정 API 제안 — 선행 의존성

`PUT /api/v1/events/{event_id}`를 추가한다. 전체 편집값 교체 계약으로 정하고 부분 수정 API를 혼합하지 않는다.

```json
{
  "title": "수정한 약속",
  "memo": null,
  "place": null,
  "all_day": false,
  "start_at": "2026-11-12T09:00:00.000Z",
  "end_at": "2026-11-12T10:00:00.000Z",
  "visibility_level": 2,
  "is_private": true
}
```

- JWT 필수. path UUID를 검증하고, 편집 가능한 위 8개 필드는 모두 전달한다. memo/place는 string 또는 null, 나머지는 필수다. 필드 생략으로 기존 값을 지우거나 private를 false로 되돌리지 않는다.
- `title`은 trim 후 비어 있지 않아야 한다. `all_day`·`is_private`는 실제 JSON boolean, 레벨은 실제 정수0~5, 시간은 유효한 UTC ISO 및 start<end여야 한다. 선택 문자열은 trim·빈 값 null을 적용한다.
- Router(auth + express-validator) → Controller(응답 wrapper) → Service → Sequelize/PostgreSQL 흐름을 따른다. route 외 서비스 직접 호출에서도 검증한다.
- 변경 조건은 `event_id + owner_user_id=JWT user_id + deleted_at IS NULL`이다. 요청의 owner/creator로 대상을 바꾸지 않는다. 삭제와 경합해도 삭제 행을 되살리지 않도록 조건부 UPDATE와 RETURNING으로 결과를 얻고, 영향 행0이면 404로 처리한다.
- 응답: HTTP200 `{success:true,data:EventApiModel,message:"일정이 수정되었습니다."}`. 기존 ID·created_at을 보존하고 updated_at을 갱신한다. data에는 is_private를 포함한 전체 최신 편집 필드를 반환한다.
- 오류: 400 `INVALID_EVENT_ID`/`INVALID_TITLE`/`INVALID_EVENT_TIME`/`INVALID_VISIBILITY_LEVEL`/`INVALID_EVENT_PRIVACY`/`VALIDATION_ERROR`, 401 인증 오류, 404 `EVENT_NOT_FOUND`, 500 `INTERNAL_SERVER_ERROR`. 타인 ID·없는 ID·삭제된 ID는 같은 404로 구분하지 않는다.
- 실패 로그는 기존 request_id/구조화 logger를 사용하고 title/memo/place 본문을 기록하지 않는다. OpenAPI의 PUT 요청/성공·오류 스키마와 서버 테스트를 함께 추가한다.
- 기존 events 컬럼으로 구현 가능하므로 이 제안에는 DB migration·seed·새 env가 필요하지 않다. private 컬럼/친구·그룹 필터는 유지한다.
- 1차 제안은 마지막으로 성공한 저장이 적용되는 정책이다. 현행 Flutter DTO에는 updated_at이 없고 충돌 검사용 version/If-Match도 없으므로 동시 편집 충돌 감지가 된다고 주장하지 않는다. 충돌 검사가 필요해지면 별도 API/DTO 계약으로 다룬다.

서버 변경 대상: `src/routes/calendarRoutes.ts`, `src/controllers/calendarController.ts`, `src/services/calendarService.ts`, `src/openapi/calendarOpenApi.json`, 관련 서버 테스트·프로젝트 문서. 이번 계획 작성에서는 서버 파일을 변경하지 않는다.

## 6. 저장 결과와 캐시 일관성

```text
CalendarPage의 개인 일정 탭
  → PersonalEventFormModal(initial_event)
  → 폼 값 → UpdateEventRequest
  → CalendarService.updateEvent(event_id, request)
  → Dio → PUT /events/{event_id} → 서버 최신 EventApiModel
  → CalendarRangeNotifier.replaceEvent(event)
  → 날짜별 목록/정렬/일정 수/관련 날짜 표시 갱신 → 시트 닫기
```

1. `replaceEvent()`는 모든 날짜 맵에서 같은 ID를 제거한 다음 새 기간에 `addEventToCalendarDateMap()`으로 다시 넣고 **한 번의 state 변경**으로 발행한다. 다일 축소/확장·월 이동에서도 이전 날짜 잔여 항목과 중복이 없어야 한다.
2. 수정 전에 시작된 range 요청이 나중에 도착해 구값을 덮는 경우를 처리한다. 진행 중 요청에는 요청 시작 이후 성공한 일정 mutation의 최신 모델/삭제 표시를 병합 결과에 재적용한다. 관련 요청 완료 후 불필요한 보정 기록을 정리한다. 전역 새 캐시 계층은 만들지 않는다.
3. 저장 요청은 비관적 반영으로 처리해 성공 전 목록을 바꾸지 않는다. 성공 응답의 ID가 요청 ID와 일치하는지 확인하고, private=true 요청의 응답은 is_private=true를 확인한다.
4. 응답 불일치·응답 유실/timeout은 서버에 이미 저장됐을 수 있다. 단순히 저장 실패=미반영으로 안내하지 않고 목록 재조회로 확인할 수 있게 한다. private 확인 실패 시 성공으로 닫지 않고 기존 EVENT_PRIVACY_NOT_CONFIRMED 방식의 안내와 재조회 경로를 제공한다. 이는 서버 변경 취소를 의미하지 않는다.
5. 404는 수정 대상이 더 이상 유효하지 않으므로 해당 ID의 로컬 항목을 제거하고 안내 후 편집을 종료한다. 저장 콜백 결과를 성공/실패/대상 없음으로 구분해 오류 문자열만으로 시트 종료를 제어하지 않는다. 다른 400/500·네트워크 오류는 폼 입력을 유지한다.
6. 같은 ID에 수정/삭제가 겹치거나 빠른 연속 탭으로 여러 시트가 뜨지 않도록 메인 페이지의 진입/처리 상태를 잠근다. 완료 시 mounted·시작한 계정의 동일성을 확인하고 로그아웃/계정 변경 뒤 이전 응답을 새 캐시에 쓰지 않는다. controllers/focus/scroll과 autoDispose 정책은 유지한다.
7. 친구 캘린더 수정 진입은 추가하지 않는다. 별도로 캐시된 그룹 본인 일정 등 실제 소비처를 확인해 수정된 본인 데이터가 남는 캐시는 필요한 범위만 무효화한다. 다른 사용자 캐시를 클라이언트에서 원격 갱신하는 기능은 이 계약에 없다.

## 7. 구현 순서와 파일 책임

| 순서 | 작업/파일 | 완료 기준 |
| --- | --- | --- |
| 1 | 서버 PUT 계약·소유권·validation·OpenAPI·테스트 | 본인 수정 성공, 타인/삭제/없는 ID 동일404, 선택정보 null 삭제·private 검증 통과 |
| 2 | `data/models/event_api_model.dart`, `data/services/calendar_service.dart` | 중립 폼 값·수정 DTO·updateEvent, UTC/null/ID/private·오류 검증 |
| 3 | `application/calendar_range_notifier.dart` | 원자적 replaceEvent와 늦은 조회 응답 보정 |
| 4 | `presentation/widgets/personal_event_form_modal.dart` | 생성/수정 초기값·라벨·비동기 결과·종일 역변환·변경 감지, 기존 생성 UX 회귀 통과 |
| 5 | `presentation/pages/calendar_page.dart` | 메인 개인 일정만 탭 연결·시트 중복 방지·응답 반영·선택일 정책 |
| 6 | 기존 모델/service/notifier/폼/페이지 테스트, 관련 문서 | 아래 인수 기준·분석/포맷·문서 검증 완료 |

공용 `calendar_schedule_card.dart`는 메인의 기존 builder 확장 지점을 우선 사용해 변경을 최소화한다. Flutter 신규 파일 없이 기존 책임 범위에서 확장하는 계획이다. 실제 구현 시 새 파일이 필요하면 역할/의존성/사용 예를 PROJECT_CONTEXT에 기록한다. 새 route·analytics 도구는 추가하지 않고 기존 root popup·ApiException 오류 처리 흐름을 사용한다.

## 8. 테스트와 완료 기준

- DTO/service: PUT path/body·8개 필드·null 삭제·명시 boolean·UTC·같은 ID 응답·private 응답 확인·400/401/404/500/timeout.
- 폼: 모든 원본 필드 복원, 무변경 요청0회, 제목만 수정해 시간 정밀도 보존, 장소/메모 삭제, 공개↔private 및 레벨 보존, 저장 실패·재시도·중복/이탈 차단.
- 기간: 시간/야간/다일, 종일1일/다일의 종료일 왕복, 월/연도 경계·윤일, 종일 전환 복원, 기기 로컬 시간 변환. DST 환경도 가능한 테스트 환경에서 검증한다.
- notifier: 기간 이동/축소/확장 후 이전 날짜 잔여0·ID 중복0·시작순 정렬·다른 일정/근무 보존, 수정 전 시작한 GET이 수정 후 완료되는 경우, 삭제와의 경합·dispose.
- 메인: 탭은 수정만, 스와이프는 삭제만 실행. 다일 중간 날짜 탭·선택일 유지/이동·월 이동 후 재방문·계정 변경 중 응답·빠른 연속 탭을 검증한다. 친구/그룹에는 수정 액션이 없어야 한다.
- 서버: 실제 인증/DB를 사용하는 격리 테스트로 본인·타인·삭제 행·잘못된 UUID·시간·null 삭제·private 공개 필터·created_at 보존·updated_at 갱신·삭제 경합·OpenAPI를 확인한다.
- UI: 320/375/390px, 큰 글자2배, 키보드 표시에서 수정 시트 입력/저장 접근·overflow 없음, 접근성 라벨·터치 영역·기존120px 닫기·가로 스와이프 회귀. 실기기 키보드/스크린리더는 별도 인수 기록을 남긴다.
- 구현 완료 후 관련 `flutter test --no-pub --dart-define=KAKAO_NATIVE_APP_KEY_STAGE=test-stage-key`와 변경 파일 `flutter analyze`·`dart format --output=none --set-exit-if-changed`·`git diff --check`를 실행한다. 서버는 해당 저장소 지침과 스크립트에 맞춰 build·단위/격리DB 테스트를 수행한다.

완료 조건: 본인 개인 일정 탭부터 서버 저장·시트 종료·즉시 목록 반영·재조회 일치까지 확인하고, 기존 생성/삭제/근무 입력/타인 읽기 전용 회귀가 통과한다. 앱만 구현하고 수정 API를 모의 처리한 상태를 기능 완료로 기록하지 않는다.

## 9. 배포·롤백·기록

- 서버 계약 검증·선배포 → Stage 본인/타인/private 인수 → Flutter 연결·회귀 → 실제 기기 인수 순서로 진행한다. 기존 GET/POST/DELETE 응답은 호환되게 유지한다.
- **Behavior change(예정)**: 메인 개인 일정 탭이 편집 시트를 연다. 편집 성공 시 제목·기간·공개/선택정보 및 관련 날짜 목록이 바뀐다. 생성·삭제·근무·친구/그룹의 편집 권한은 바꾸지 않는다.
- Flutter 롤백: 탭 연결·편집 모드·수정 DTO/service·replace 처리와 해당 회귀만 되돌려 기존 추가/삭제로 복구한다. 기존 미커밋 폼 디테일 변경은 보존한다.
- 서버 롤백: PUT 신규 route만 비활성화하거나 호환 버전으로 복구한다. 저장된 개인 일정과 기존 private 컬럼/필터는 유지한다. 이미 수정한 사용자 데이터를 임의로 되돌리지 않는다.
- 계획 문서 롤백: 이 파일과 PROJECT_CONTEXT·WORKLOG의 이번 추가분만 제거한다.
- 구현 착수 시 WORKLOG TODO를 새로 만들고 목적/변경/영향/테스트/롤백을 기록한다. 구현 정책 확정 시 DECISIONS에 ADR을 추가한다. 이번에는 검토 전 제안을 확정 정책으로 기록하지 않는다.

이 파일의 역할은 Flutter·서버 공동 구현 계획과 인수 기준이다. 위 현행 코드·API 문서·도면에 의존하며, 구현 작업 분리와 서버 계약 검토 시 사용한다.
