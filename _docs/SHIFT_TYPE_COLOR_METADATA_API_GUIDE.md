# 근무 타입 색상 메타데이터 API·DB 마이그레이션 가이드

## 1. 목적과 범위

근무 타입 색상 설정 화면에서 사용자가 기준 색상을 선택하고 색상 농도를 조절한 뒤
다시 화면에 진입했을 때 같은 기준 색상과 농도를 복원하기 위한 서버 변경 계획이다.

- 대상 API: `GET/POST /api/v1/shift-types`,
  `PUT /api/v1/shift-types/:shift_type_id`
- 대상 DB: PostgreSQL `shift_types`
- 대상 서버: Express + Sequelize
- 이번 작업 범위: 구현 전 API 계약, DB migration, 배포·검증·롤백 계획 수립
- 이번 작업에서 제외: 서버/Flutter 실행 코드 수정, 실제 DB migration 실행

## 2. 확인된 상태

### Flutter 적용 전 문제

- 기존 `ShiftColorPickerPage`는 `initial_color` 하나만 받아 이를 `_base_color`로 사용하고
  `_color_intensity`를 항상 `1`로 초기화했다.
- 적용 시 `Color.lerp(AppTheme.surface_color, _base_color, _color_intensity)`로 만든
  최종 `Color` 하나만 이전 화면에 반환했다.
- 기존 `ShiftTypeApiModel`, `CreateShiftTypeRequest`, `UpdateShiftTypeRequest`도 최종 `color`
  하나만 파싱·전송했다.
- 이 문제는 2026-07-20 Flutter 구현에서 기준 색상·정수 농도 별도 상태와 고정 흰색 계산으로 해결했다.

따라서 예를 들어 파란 기준 색상에 50% 농도를 적용해 저장하면 DB에는 흰색과 혼합된
최종 색상만 남는다. 하나의 최종 색상은 여러 기준 색상·농도 조합으로 만들 수 있으므로
기준 색상과 농도를 정확히 역산할 수 없다.

### Express 서버

- 실제 서버 모델과 `GET/POST/PUT /shift-types` 구현에는 `base_color`,
  `color_intensity` 계약과 레거시 fallback이 반영되어 있다.
- 운영용 `migrations/add_shift_type_color_metadata.sql`,
  `migrations/backfill_shift_type_color_metadata.sql`도 서버 저장소에 존재한다.
- 서버는 migration 또는 `sequelize.sync()`를 자동 실행하지 않으며
  `migrations/` SQL을 개발자가 백업 후 수동 적용한다.
- Swagger/OpenAPI는 현재 서버 저장소에 구현되어 있지 않다.
- 서버의 2026-07-20 WORKLOG 기준 연결된 실제 DB에는 두 신규 컬럼이 아직 없어
  migration 적용 전 신규 서버의 근무 타입·캘린더 조회가 PostgreSQL `42703`으로 실패한다.
  실제 앱 연동 검증 전 DB expand migration 적용과 API 200 응답 확인이 선행되어야 한다.

### 문서와 실제 서버 스키마 차이

Flutter 저장소의 기존 DDL 문서는 `shift_types.color int`로 적혀 있지만,
현재 서버의 `migrations/final_schema.sql`과 Sequelize 모델은 `color text`를 사용한다.
본 계획은 실행 중인 서버 계약과 서버 최종 스키마인 `text #AARRGGBB`를 기준으로 한다.
구현 시 Flutter 저장소의 DDL 문서와 `schema.drawio`도 실제 서버 스키마에 맞춰 갱신해야 한다.

`schema.drawio`와 `visibility_flow.drawio`에는 현재 제거된 `calendars`,
`calendar_shares`가 남아 있어 AGENTS.md의 single-calendar-per-user 최종 DDL보다 오래된
구조임도 확인했다. 색상 메타데이터는 공개 범위 계산에 관여하지 않으므로 이번 계획에서
노출 로직을 바꾸지는 않으며, 다이어그램 전체 동기화는 실제 DB 구조 정합성 작업으로 별도 수행한다.

## 3. 결정할 데이터 모델

### 권장 컬럼

| 컬럼 | 타입 | null | 기본값 | 역할 |
| --- | --- | --- | --- | --- |
| `color` | `text` | 허용 | 없음 | 기존 화면과 캘린더 API가 쓰는 최종 렌더링 색상 |
| `base_color` | `text` | 허용 | 없음 | 농도 적용 전 기준 색상, `#AARRGGBB` |
| `color_intensity` | `smallint` | 불허 | `100` | 기준 색상 농도, 정수 `0..100` |

`color`는 제거하거나 의미를 바꾸지 않는다. 기존 앱과
`calendar/range`, 친구 캘린더, 근무표 스냅샷 응답의 호환성을 위해
최종 렌더링 색상의 단일 기준값으로 계속 사용한다.

`base_color`가 nullable인 이유는 다음과 같다.

- 기존 `color` 자체가 nullable이다.
- migration과 서버 배포 사이에 구버전 서버가 기록한 행을 허용해야 한다.
- 서버 롤백 시 구버전 코드가 신규 컬럼을 쓰지 않아도 저장이 실패하지 않아야 한다.

색상 조회 시 `base_color`가 없으면 서버와 Flutter 모두
`base_color = color`, `color_intensity = 100`으로 해석한다.

### 농도 단위

`color_intensity`는 부동소수점이 아닌 `smallint 0..100`을 사용한다.

- 화면이 사용자에게 퍼센트 정수로 표시된다.
- JSON과 DB 사이의 부동소수점 오차를 피할 수 있다.
- Flutter 슬라이더도 구현 시 1% 단위로 양자화해 표시값·저장값·최종 색상을 일치시킨다.

### 최종 색상 계산 규칙

농도는 테마 변화와 무관하게 불투명 흰색 `#FFFFFFFF`를 혼합 기준으로 고정한다.
각 RGB 채널은 아래 식으로 계산하고 가장 가까운 정수로 반올림한다.
알파 채널은 신규 메타데이터 요청에서 `FF`로 고정한다.

```text
result_channel =
  round(255 + (base_channel - 255) * color_intensity / 100)
```

예:

```text
base_color      = #FF4355B8
color_intensity = 50
color           = #FFA1AADC
```

최종 `color`는 서버에서 위 규칙으로 계산한다. 클라이언트가 `color`까지 함께 보낼 수는
있지만 계산 결과와 다르면 요청을 거부해 세 필드가 서로 어긋나지 않게 한다.

## 4. API 계약

### 공통 형식

- Base URL: `/api/v1`
- 인증: Bearer access token
- Content-Type: `application/json`
- 색상 문자열: 대문자로 정규화한 `#AARRGGBB`
- 신규 `base_color`: 새 앱 요청은 불투명 `#FFRRGGBB`만 허용
- `color_intensity`: JSON 정수 `0..100`
- `base_color`와 `color_intensity`는 하나의 원자적 설정값으로 취급

### 생성 요청

```http
POST /api/v1/shift-types
```

권장 신규 요청:

```json
{
  "code": "D",
  "name": "데이",
  "base_color": "#FF4355B8",
  "color_intensity": 50,
  "start_time": "06:30:00",
  "end_time": "15:00:00",
  "sort_order": 1
}
```

호환성 규칙:

| 입력 | 서버 처리 |
| --- | --- |
| `base_color` + `color_intensity` | 최종 `color`를 서버에서 계산하고 세 값을 저장 |
| 위 두 값 + `color` | 계산한 값과 `color`가 같을 때만 저장 |
| 기존 `color`만 전달 | `color`와 `base_color`를 같은 값으로, 농도를 `100`으로 저장 |
| 색상 필드 모두 생략 | 기존 nullable 정책대로 세부 색상 없이 저장 |
| 신규 필드 중 하나만 전달 | `400 INVALID_COLOR_METADATA` |

### 수정 요청

```http
PUT /api/v1/shift-types/:shift_type_id
```

권장 신규 요청:

```json
{
  "base_color": "#FF4355B8",
  "color_intensity": 50,
  "start_time": "06:30:00",
  "end_time": "15:00:00"
}
```

부분 수정 규칙:

| 입력 | 서버 처리 |
| --- | --- |
| 색상 관련 필드 없음 | 기존 세 값을 모두 유지 |
| `base_color` + `color_intensity` | 최종 `color`를 재계산하고 세 값을 한 트랜잭션에서 갱신 |
| 기존 `color`만 전달 | 구버전 요청으로 처리해 `base_color=color`, 농도 `100`으로 갱신 |
| `color: null`만 전달 | 기존 색상 삭제 의미를 유지해 `color`, `base_color`를 `null`, 농도를 `100`으로 갱신 |
| 신규 필드 중 하나만 전달 | `400 INVALID_COLOR_METADATA` |
| 신규 필드와 불일치하는 `color` | `400 COLOR_METADATA_MISMATCH` |

### 목록·생성·수정 응답

기존 응답 필드를 제거하지 않고 각 근무 타입 객체에 두 필드를 추가한다.

```json
{
  "success": true,
  "data": {
    "shift_type_id": "uuid",
    "code": "D",
    "name": "데이",
    "color": "#FFA1AADC",
    "base_color": "#FF4355B8",
    "color_intensity": 50,
    "sort_order": 1,
    "start_time": "06:30:00",
    "end_time": "15:00:00",
    "crosses_midnight": false,
    "duration_minutes": 510
  }
}
```

목록 응답의 실제 최상위 구조는 기존
`data.template_id`, `data.template_name`, `data.shift_types[]`를 유지한다.

레거시 행의 `base_color`가 `null`이면 응답 직렬화 단계에서 다음 fallback을 적용한다.

```text
base_color      = color
color_intensity = 100
```

`calendar/range`, 친구 캘린더, 근무표 응답은 설정 화면 복원에 사용되지 않으므로
이번 변경에서 메타데이터를 추가하지 않는다. 기존 `shift_type_color` 최종 색상만 유지한다.

### Validation 및 오류 코드

| 코드 | HTTP | 조건 |
| --- | --- | --- |
| `INVALID_COLOR_FORMAT` | 400 | `color`이 `#AARRGGBB` 형식이 아님 |
| `INVALID_BASE_COLOR_FORMAT` | 400 | `base_color`이 신규 요청의 `#FFRRGGBB` 형식이 아님 |
| `INVALID_COLOR_INTENSITY` | 400 | 정수가 아니거나 `0..100` 범위 밖 |
| `INVALID_COLOR_METADATA` | 400 | `base_color`, `color_intensity` 중 하나만 전달 |
| `COLOR_METADATA_MISMATCH` | 400 | 함께 전달한 `color`가 서버 계산 결과와 다름 |

기존 성공/실패 envelope와 인증·소유권 오류 계약은 바꾸지 않는다.

## 5. Express 구현 계획

### 5.1 Model

`src/models/ShiftType.ts`

- attribute와 creation attribute에 `base_color`, `color_intensity` 추가
- Sequelize field:
  - `base_color`: `DataTypes.TEXT`, `allowNull: true`
  - `color_intensity`: `DataTypes.SMALLINT`, `allowNull: false`,
    `defaultValue: 100`

### 5.2 Validation

`src/routes/calendarRoutes.ts`

- POST/PUT에 `base_color`, `color_intensity` validator 추가
- 단일 필드 validator 이후 controller/service 경계에서 두 필드 동시성 검증
- 신규 `base_color`는 `#FFRRGGBB`, 기존 `color`는 현재 `#AARRGGBB` 계약 유지
- 알 수 없는 추가 필드를 일괄 허용하는 현재 동작은 이번 범위에서 바꾸지 않음

### 5.3 Controller

`src/controllers/calendarController.ts`

- 생성·수정 body에서 두 신규 필드를 추출해 service에 전달
- validation 오류는 기존 response envelope로 반환
- 색상 메타데이터 오류를 위 표의 안정적인 오류 코드로 매핑

### 5.4 Service

`src/services/shiftTemplateService.ts`

- `normalizeColor()`를 재사용하되 기준 색상의 불투명 조건을 별도 검증
- 흰색 혼합 계산 함수를 한 곳에 추가
- 생성·수정 모두 동일한 색상 입력 해석 함수를 사용
- 최종 `color`, `base_color`, `color_intensity`를 기존 transaction 안에서 함께 저장
- 응답 객체에 두 신규 필드 추가
- 구버전 `color` 단독 요청은 100% 메타데이터로 dual-write
- 신규 사용자 기본 템플릿을 만드는 `DEFAULT_SHIFT_TYPES` 직접 생성 경로도
  `base_color=color`, 농도 `100`을 함께 기록하도록 수정

`src/services/calendarService.ts`

- `getShiftTypes()`의 설정 목록 응답에 신규 필드와 레거시 fallback 추가
- `work_shifts`와 calendar range의 `shift_type_color` 생성 로직은 변경하지 않음

### 5.5 API 문서

- 서버에는 현재 Swagger/OpenAPI가 구현되어 있지 않으므로 존재하지 않는 spec 경로를 만들었다고
  기록하지 않는다.
- 서버 구현 시 서버 `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`,
  `migrations/final_schema.sql`, `AGENTS.md`의 최종 DDL을 갱신한다.
- 추후 Swagger가 도입되면 이 계약을 `/api-docs` 사양에 옮긴다.

## 6. DB 마이그레이션 계획

운영 DB에서는 `DROP SCHEMA`가 있는 `migrations/final_schema.sql`을 실행하지 않는다.
아래 단계용 별도 SQL 파일을 만들고 백업 후 개발자가 수동으로 한 번씩 실행한다.

### Phase 0. 적용 전 감사와 백업

대상 환경과 DB 백업본을 확인한 뒤 다음 쿼리 결과를 작업 로그에 남긴다.

```sql
SELECT
  COUNT(*) AS total_count,
  COUNT(*) FILTER (WHERE color IS NULL) AS null_color_count,
  COUNT(*) FILTER (
    WHERE color IS NOT NULL
      AND color !~ '^#[0-9A-Fa-f]{8}$'
  ) AS invalid_color_count
FROM shift_types;

SELECT color, COUNT(*)
FROM shift_types
WHERE color IS NOT NULL
  AND color !~ '^#[0-9A-Fa-f]{8}$'
GROUP BY color
ORDER BY COUNT(*) DESC;
```

`invalid_color_count > 0`이면 현재 서버의 `formatShiftTypeColor()`가 허용하는
과거 숫자/6자리 형식을 조사해 명시적인 정규화 SQL을 별도 검토한다.
확인되지 않은 값을 임의 변환하지 않는다.

### Phase 1. Expand migration

제안 파일:
`migrations/add_shift_type_color_metadata.sql`

```sql
ALTER TABLE shift_types
  ADD COLUMN IF NOT EXISTS base_color text,
  ADD COLUMN IF NOT EXISTS color_intensity smallint;

COMMENT ON COLUMN shift_types.base_color
  IS '색상 농도 적용 전 기준 색상. #AARRGGBB';
COMMENT ON COLUMN shift_types.color_intensity
  IS '기준 색상 농도 정수 퍼센트. 0~100';
```

첫 migration에서는 신규 컬럼을 nullable로 추가한다. 구버전 API 인스턴스가 실행 중이어도
기존 insert/update가 실패하지 않으며 테이블 전체 backfill과 제약 검증을 한 번에 묶지 않는다.

### Phase 2. 서버 dual-read/dual-write 배포

- 신규 서버는 새 요청에서 세 색상 값을 함께 기록한다.
- 구버전 행은 읽을 때 `base_color=color`, 농도 `100`으로 fallback한다.
- 구버전 앱의 `color` 단독 쓰기도 세 값으로 변환한다.
- 모든 API 인스턴스가 신규 코드인지 확인한다.
- `npm run build`와 health check를 통과한 뒤 다음 단계로 진행한다.

### Phase 3. Backfill 및 제약 적용

제안 파일:
`migrations/backfill_shift_type_color_metadata.sql`

적용 전 invalid color가 0건임을 다시 확인한다.

```sql
UPDATE shift_types
SET
  color = UPPER(color),
  base_color = UPPER(color),
  color_intensity = 100
WHERE color IS NOT NULL
  AND (
    base_color IS NULL
    OR color_intensity IS NULL
  );

UPDATE shift_types
SET color_intensity = 100
WHERE color_intensity IS NULL;

ALTER TABLE shift_types
  ALTER COLUMN color_intensity SET DEFAULT 100,
  ALTER COLUMN color_intensity SET NOT NULL;

ALTER TABLE shift_types
  ADD CONSTRAINT ck_shift_types_color_intensity
  CHECK (color_intensity BETWEEN 0 AND 100) NOT VALID;

ALTER TABLE shift_types
  ADD CONSTRAINT ck_shift_types_base_color_format
  CHECK (
    base_color IS NULL
    OR base_color ~ '^#[0-9A-F]{8}$'
  ) NOT VALID;

ALTER TABLE shift_types
  VALIDATE CONSTRAINT ck_shift_types_color_intensity;

ALTER TABLE shift_types
  VALIDATE CONSTRAINT ck_shift_types_base_color_format;
```

실제 migration SQL은 재실행 안전성을 위해 `pg_constraint` 존재 여부를 확인하는
`DO $$ ... $$` 구문으로 제약 추가를 감싸야 한다.

`base_color NOT NULL` 또는 `color ↔ base_color` 쌍 제약은 이번 migration에 추가하지 않는다.
이를 추가하면 API 롤백으로 구버전 서버가 다시 실행될 때 기존 `color`만 쓰는 요청이 실패한다.
구버전 서버 폐기와 롤백 기간 종료가 별도 확인된 뒤 강화 여부를 재평가한다.

색상 메타데이터는 필터·정렬·join 조건이 아니므로 인덱스는 추가하지 않는다.

### Phase 4. 최종 스키마·다이어그램 동기화

- 서버 `migrations/final_schema.sql`
- 서버 `AGENTS.md` 최종 DDL
- 서버 `_docs/PROJECT_CONTEXT.md`, `_docs/WORKLOG.md`, 필요 시 `DECISIONS.md`
- Flutter 저장소의 DDL 설명과 `schema.drawio`

위 자료를 실제 적용된 `text`, `base_color`, `smallint` 구조로 맞춘다.
다이어그램은 계획만으로 먼저 고치지 않고 migration 확정·적용 결과와 일치시킨다.

## 7. 배포 순서

```text
DB 백업·데이터 감사
  → Phase 1 확장 SQL
  → 신규 Express 배포(dual-read/dual-write)
  → GET/POST/PUT 계약 검증
  → Phase 3 backfill·제약 SQL
  → Flutter 배포
  → 최종 DDL·문서·schema.drawio 동기화
```

서버를 Flutter보다 먼저 배포한다. 신규 응답 필드는 구버전 Flutter가 무시할 수 있지만,
신규 Flutter가 구버전 서버에 메타데이터를 보내면 최종 색상만 저장되거나 신규 필드가
유실될 수 있기 때문이다.

## 8. Flutter 구현

### 2026-07-20 적용 상태

- `ShiftTypeApiModel`이 `base_color`, `color_intensity`를 파싱하고 레거시 응답은
  `base_color=color`, 농도 100으로 fallback한다.
- 생성 요청과 색상을 적용한 수정 요청은 최종 `color`를 생략하고
  `base_color`, `color_intensity`를 함께 전송한다.
- 편집 화면에서 색상 선택 결과를 적용하지 않으면 색상 관련 필드를 모두 생략한다.
- 색상 선택 화면은 `ShiftColorSelection`으로 최종 색상·기준 색상·정수 농도를 반환하고,
  편집 재진입 시 서버 응답의 기준 색상과 농도를 초기 상태로 복원한다.
- 미리보기는 테마 surface가 아니라 고정 흰색 `#FFFFFFFF`를 사용하는 서버 채널 계산과 일치한다.

- 색상 결과값 모델을 `Color` 하나가 아니라
  `final_color`, `base_color`, `color_intensity`를 가진 값 객체로 변경
- `ShiftTypeApiModel`에 `baseColor`, `colorIntensity` 추가
- 레거시 응답 fallback:
  - `base_color ?? color`
  - `color_intensity ?? 100`
- `CreateShiftTypeRequest`, `UpdateShiftTypeRequest`에 신규 필드 추가
- `ShiftColorPickerPage`는 기준 색상과 농도를 초기값으로 받아 복원
- 슬라이더 상태를 1% 단위로 양자화
- 프리셋/커스텀 색상 변경 시 농도 100% 초기화 정책은 현재 동작 유지
- 최종 색상은 서버 규칙과 같은 불투명 흰색 혼합으로 미리보기

이 단계는 서버 contract test와 Phase 1 배포가 완료된 후 진행한다.

## 9. 검증 계획

### DB

- 신규 컬럼 타입, default, nullability 확인
- 기존 모든 유효 색상 행이 `base_color=color`, 농도 `100`으로 backfill됐는지 확인
- 농도 `-1`, `101` insert/update가 제약으로 거부되는지 확인
- 잘못된 `base_color`이 제약으로 거부되는지 확인
- soft-deleted `shift_types`도 누락 없이 backfill됐는지 확인

```sql
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns
WHERE table_name = 'shift_types'
  AND column_name IN ('color', 'base_color', 'color_intensity')
ORDER BY ordinal_position;

SELECT COUNT(*) AS missing_metadata_count
FROM shift_types
WHERE color IS NOT NULL
  AND (base_color IS NULL OR color_intensity IS NULL);
```

### API

- 신규 POST 0%, 50%, 100%의 최종 `color` 계산
- 신규 PUT 후 GET 재조회 시 세 필드 보존
- 기존 `color` 단독 POST/PUT가 농도 100%로 저장
- 신규 필드 부분 전달과 범위 밖 농도 거부
- final color 불일치 거부
- 색상 필드가 null인 기존 근무 타입 조회
- 다른 사용자의 `shift_type_id` 수정 거부
- `calendar/range`와 친구 캘린더의 기존 `shift_type_color` 회귀 없음

현재 서버 `package.json`에는 test script가 없다. 구현 작업에서는 최소한
TypeScript `npm run build`, 개발 DB 대상 API contract test, SQL 검증 쿼리를 수행하고,
자동화 테스트 도입 여부와 실행 명령을 서버 작업 로그에 사실대로 기록한다.

### Flutter

- 50% 적용 → 저장 → API 재조회 → 설정 재진입 시 50%와 기준 색상 복원
- 0%, 100%, 프리셋, 커스텀 색상 왕복
- 레거시 응답에서 100% fallback
- 생성·수정 요청 JSON
- 최종 색상 미리보기와 서버 응답 일치

## 10. 롤백 계획

### Flutter 롤백

기존 앱으로 되돌려도 `color`가 계속 존재하므로 최종 색상 표시는 유지된다.
신규 메타데이터만 편집 화면에서 사용되지 않는다.

### 서버 롤백

구버전 서버는 신규 컬럼을 무시하고 기존 `color`를 계속 읽고 쓸 수 있다.
`base_color`를 nullable로 유지했으므로 롤백 중 구버전 쓰기도 차단되지 않는다.
롤백 뒤 생성·수정된 행은 신규 서버 재배포 시 읽기 fallback과 재-backfill 대상으로 처리한다.

### DB 롤백

앱과 서버를 먼저 구버전으로 되돌리고 신규 컬럼 의존이 없음을 확인한 뒤 실행한다.
컬럼 삭제는 기준 색상·농도 정보가 소실되므로 사전 백업이 필수다.

```sql
ALTER TABLE shift_types
  DROP CONSTRAINT IF EXISTS ck_shift_types_base_color_format,
  DROP CONSTRAINT IF EXISTS ck_shift_types_color_intensity,
  DROP COLUMN IF EXISTS base_color,
  DROP COLUMN IF EXISTS color_intensity;
```

기존 `color`는 삭제·재계산하지 않으므로 사용자가 마지막으로 본 최종 색상은 보존된다.

## 11. 구현 완료 기준

- [ ] Phase 0 감사 결과와 백업 식별자를 서버 작업 로그에 기록
- [ ] 두 단계 migration SQL 작성·검토·개발 DB 적용
- [ ] Sequelize model, route validation, controller, service 수정
- [ ] GET/POST/PUT에 신규 필드와 레거시 fallback 적용
- [ ] 기존 calendar/work-shift 응답 회귀 검증
- [ ] Flutter 모델·요청·picker 상태 복원 구현
- [ ] 서버 build, API contract, DB 검증, Flutter test/analyze 통과
- [ ] 서버/Flutter PROJECT_CONTEXT, DECISIONS, WORKLOG 최신화
- [ ] 최종 DDL과 `schema.drawio`를 실제 적용 결과에 맞춰 갱신
- [ ] Swagger/OpenAPI가 실제 도입된 경우에만 해당 spec 갱신
