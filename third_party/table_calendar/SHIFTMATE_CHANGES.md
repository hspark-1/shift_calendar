# ShiftMate 로컬 패치

기준은 현재 설치되어 있던 Aleksander Woźniak의 `table_calendar` **3.2.0**이다.
원본 `lib/`, `README.md`, `LICENSE`, `pubspec.yaml`을 보존하고 아래만 변경했다. README의 행 끝 공백2곳은 커밋 검사에 맞춰 정리했다.
원본: <https://github.com/aleksanderwozniak/table_calendar>, Apache-2.0.

- `lib/src/shared/utils.dart`: `CalendarFormat.threeWeeks` 추가.
- `lib/src/widgets/calendar_core.dart`: 21일 단위 페이지 수/이동·표시 범위와3행 추가.
- `lib/src/table_calendar_base.dart`: 21일 기준 페이지 인덱스와3행 높이 추가.
- `lib/src/table_calendar.dart` / `table_calendar_base.dart`: 기본 포맷 목록에3주 추가.
- `pubspec.yaml`: 현재 분석기가 경고하는 폐기된 author 필드만 제거했다. 원저자 저작권/라이선스와 README는 유지한다.

수정한 Dart 파일 상단에 변경 고지를 남겼다. 기존1주/2주·월간 계산은 보존한다.
`lib/table_calendar.dart`는 공개 진입점이며 `lib/src/customization/`의 스타일/빌더,
`lib/src/widgets/`의 헤더/셀/페이지, `lib/src/shared/`의 날짜/포맷을 사용한다.
Flutter·기존 intl/simple_gesture_detector 의존성은 원본과 같다.

앱 `pubspec.yaml`의 `path: third_party/table_calendar`로 사용하며 다른 패키지는
갱신하지 않는다. 로컬 .gitignore는 패키지 단독 검사에서 생성되는 캐시/라이브러리 pubspec.lock만 제외하며 앱 루트 lock은 유지한다. 예: `TableCalendar(calendarFormat: CalendarFormat.threeWeeks, ...)`.
날짜는 원본과 같은 UTC 날짜 성분/주 시작 기준을 사용하고3주 페이지는21일씩 이동한다.

검증: 앱 루트에서 다음 명령으로 실제 행 수/연속 날짜·21일 스와이프/연도 경계·
마지막 행 선택·첫/끝 범위 및 기존 포맷을 검사한다.

```sh
flutter test --no-pub test/features/calendar/presentation/widgets/calendar_three_week_test.dart
```

정확한 검증 결과와4화면/경계·근무 입력/렌더는 `_docs/WORKLOG.md`를 따른다.
롤백은 앱 의존성을 원래 hosted `table_calendar`로 되돌리고3주 참조/정책을 복원한 뒤
`flutter pub get`을 실행한다. 향후 원본 버전 갱신 시 이 작은 패치를 다시 대조한다.
