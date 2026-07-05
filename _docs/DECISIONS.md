# 아키텍처 결정사항

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
- **캐싱**: 연도별 캐시 + 월별 로드 상태 추적
- **중복 호출 방지**: 동일한 연도/월 조합의 동시 요청 방지
- **구현 위치**: `lib/core/utils/korean_holidays.dart`

### 공휴일 표시 규칙

- **공휴일**: 빨간색으로 표시 (일요일과 동일)
- **토요일/일요일**: 빨간색으로 표시
- **공휴일 이름**: 하단 일정 리스트의 날짜 헤더에 표시

### 구현 세부사항

1. **공휴일 데이터 구조**

   - `_holiday_cache`: 연도별 공휴일 날짜 Set
   - `_holiday_name_cache`: 날짜별 공휴일 이름 Map
   - `_loaded_month_ranges`: 연도별 로드된 월 범위 추적

2. **성능 최적화**

   - 월별 3개월만 조회 (12회 → 3회 API 호출로 75% 감소)
   - 중복 호출 방지 (동일 요청 대기 후 캐시 반환)
   - 월별 로드 상태 추적 (이미 로드된 월 범위는 스킵)

3. **UI 통합**
   - `table_calendar`의 `holidayPredicate` 사용
   - `CalendarBuilders`로 공휴일/주말 스타일링
   - 하단 일정 리스트에 공휴일 이름 동적 표시

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
- **시간 제거**: 시작시간/종료시간 중 하나를 제거하면 둘 다 제거 (일관성 유지)

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
