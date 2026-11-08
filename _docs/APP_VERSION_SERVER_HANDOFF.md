# 서버 담당자 전달: 앱 API 호환 버전 정책

## 요청 요약

앱에 **App Store 버전/빌드와 별도인 API 호환 번호**를 추가했다. 서버는 플랫폼별 최소 호환 번호를 인증 없이 내려주고, 앱은 자신의 번호가 그보다 낮으면 이용을 차단하고 스토어 업데이트로 안내한다.

| 항목 | 전달 값 |
|---|---|
| 현재 앱 내부 호환 번호 | `1` (`AppConstants.api_compatibility_version`) |
| 새 iOS 앱 | 표시 버전 `1.0.0`, 빌드 `2` |
| iOS 업데이트 URL | `https://apps.apple.com/kr/app/id6831957246` |
| 서버 저장소 | `hspark-1/shift_calendar_server` |
| 준비된 기능 브랜치 | [codex/app-compatibility-policy](https://github.com/hspark-1/shift_calendar_server/tree/codex/app-compatibility-policy) (`develop` 기반, origin push 완료) |
| 준비된 커밋 | [90ece07](https://github.com/hspark-1/shift_calendar_server/commit/90ece07) — `feat: expose app API compatibility update policy` |
| 전달용 패치 | `artifacts/app_update_backend/0001-app-compatibility-policy.patch` |
| 초기 최소 호환 번호 | `0` — 차단 비활성 |

서버 코드는 이미 구현·로컬 검증했다. **실제 서버 배포, 운영 env 변경, DB 변경은 수행하지 않았다.** 기존 서버 main의 미커밋 작업은 변경하지 않았다. 브랜치 반영과 패치 적용 중 한 방법만 사용한다.

## 1. 서버 코드 반영

현재 작업 트리에 미커밋 변경이 있으면 해당 작업을 보존하고 별도 작업 트리에서 검토한다. 기존 저장소의 브랜치·배포 정책을 따른다.

```bash
git fetch origin
git show --stat origin/codex/app-compatibility-policy
git diff origin/develop...origin/codex/app-compatibility-policy
```

검토 후 커밋 `90ece07`을 develop에 반영하고 배포용 브랜치에는 기존 절차대로 전달한다. 대안으로 별도 서버 작업 브랜치에서 아래 패치를 적용할 수 있다. 이미 해당 커밋이 있으면 중복 적용하지 않는다.

```bash
git am /전달받은/0001-app-compatibility-policy.patch
```

변경 파일·역할:

| 파일 | 작업 내용 |
|---|---|
| `src/services/appVersionPolicyService.ts` | 플랫폼별 env → DTO, 정수/스토어 URL/메시지 검증 |
| `src/controllers/appVersionPolicyController.ts` | no-store 응답, 안전한 503 및 request ID·구조화 로그 |
| `src/routes/appVersionPolicyRoutes.ts` | 무인증 공개 GET, express-validator query 검증 |
| `src/routes/index.ts` | v1 router에 신규 route mount |
| `src/index.ts` | API 시작 시 양 플랫폼 정책 설정 검증 |
| `src/openapi/appVersionPolicyOpenApi.json`, `src/openapi.ts` | Swagger 요청·응답·오류 명세 |
| `test/appVersionPolicy.test.cjs` | 실제 로컬 HTTP·설정·검증 실패 회귀 |
| `.env.example`, `_docs/*` | 비활성 기본값, 운영 계약·ADR-0040·작업 기록 |

**DB migration·seed·테이블 변경은 없다.** 기존 인증·일정 API의 응답 형식이나 인가 규칙을 변경하지 않는다.

## 2. FE에서 요구하는 API 계약

```http
GET /api/v1/app/version-policy?platform=IOS
```

- `platform`: 필수 문자열 `IOS` 또는 `ANDROID`.
- 로그인·Bearer 토큰이 없어도 조회돼야 한다. 로그인 전에 앱이 요청한다.
- `Cache-Control: no-store`, 기존 request ID 미들웨어 적용.
- CDN/Nginx에서 로그인으로 리다이렉트하거나 별도 인증을 요구하지 않는다.

초기 성공 응답:

```json
{
  "success": true,
  "data": {
    "schema_version": 1,
    "platform": "IOS",
    "minimum_compatibility_version": 0,
    "update_url": "https://apps.apple.com/kr/app/id6831957246",
    "message": "안정적인 서비스 이용을 위해 최신 앱으로 업데이트해 주세요."
  }
}
```

필드명·대소문자·타입을 그대로 유지한다. 최소값은 0~2147483647 정수, 메시지는 최대 300자다. 최소값이 양수일 때 유효한 스토어 URL이 필요하다. iOS URL은 HTTPS `apps.apple.com`의 위 App ID, Android는 HTTPS Google Play의 `com.hspark.shiftmate`로 제한한다.

| 경우 | 응답 |
|---|---|
| 정상 | 200, `success=true`, 위 DTO |
| platform 누락·잘못된 값·배열 | 400, `error.code=VALIDATION_ERROR` |
| 정책 설정 오류 | 503, `error.code=APP_VERSION_POLICY_UNAVAILABLE`, request ID |

설정 오류에 env 값·토큰·URL 원문을 노출하지 않는다. 기존 logError가 오류 코드·변수 이름·request ID만 남긴다. 잘못된 설정이면 API 시작 검증도 실패한다.

## 3. 초기 환경 설정

각 환경의 실제 API env에 다음 값을 설정한다. **현재 앱의 번호가 1이므로 지금 2로 설정하면 이번 앱도 차단된다.**

```dotenv
APP_UPDATE_IOS_MIN_COMPATIBILITY_VERSION=0
APP_UPDATE_IOS_URL=https://apps.apple.com/kr/app/id6831957246
APP_UPDATE_IOS_MESSAGE="안정적인 서비스 이용을 위해 최신 앱으로 업데이트해 주세요."
APP_UPDATE_ANDROID_MIN_COMPATIBILITY_VERSION=0
```

- 최소값 기본값은 각 플랫폼 0이다. iOS URL 기본값도 위 확인된 주소다.
- Android 최소값을 양수로 올릴 때는 실제 앱이 제공되는 `APP_UPDATE_ANDROID_URL`도 설정한다. Android 최초 출시 범위는 별도 확인한다.
- Stage와 운영은 독립 설정이다. env 변경 후 **새 env를 읽도록 API 프로세스/컨테이너를 재생성**한다. env 파일만 수정하거나 기존 컨테이너를 단순 재시작하는 것만으로 반영됐다고 간주하지 않는다.
- 워커 전용 secret이나 DB migration은 추가하지 않는다.

## 4. 코드 및 배포 후 검증

서버 작업 트리에서:

```bash
npm ci
npm run build
node --test test/appVersionPolicy.test.cjs test/environmentValidation.test.cjs test/googleAuth.test.cjs test/pushNotification.test.cjs
```

작성 당시 strict TypeScript와 위 선택 테스트 23개가 통과했다. 전체 npm test 및 운영 환경 E2E를 통과했다고 기록한 것은 아니다.

최소값 0으로 Stage 먼저 배포한 뒤 실제 공개 API를 확인한다.

```bash
curl --fail --silent --show-error --include 'https://stage-api.shiftmate.co.kr/api/v1/app/version-policy?platform=IOS'
curl --silent --show-error --include 'https://stage-api.shiftmate.co.kr/api/v1/app/version-policy?platform=INVALID'
```

수용 기준:

- [ ] 토큰 없이 200, `Content-Type: application/json`, no-store, request ID.
- [ ] schema_version=1, platform=IOS, minimum_compatibility_version=0, 해당 App Store URL.
- [ ] 잘못된 플랫폼은 400 VALIDATION_ERROR.
- [ ] Android 정책은 별도 조회 가능하고 기본값 0.
- [ ] 빌드 2 앱의 로그인·캘린더·친구·그룹 기능이 기존대로 동작.
- [ ] Stage에서만 최소값 2로 올려 내부 번호 1의 차단·스토어 버튼·앱 복귀·‘다시 확인’을 검증한 뒤 최소값 0으로 복원.
- [ ] 최소값을 0으로 되돌리면 캐시가 있는 앱도 정상 응답 후 차단 해제.

Stage 확인 후 기존 배포 절차로 운영에 최소값 0을 반영하고 아래를 검증한다.

```bash
curl --fail --silent --show-error --include 'https://api.shiftmate.co.kr/api/v1/app/version-policy?platform=IOS'
```

운영에서 실사용자를 대상으로 차단 테스트를 하지 않는다. 스토어 링크 열림과 업데이트 후 앱 동작은 실제 기기에서 별도 확인한다.

## 5. 추후 서버 호환 규격 변경 순서

1. 서버에 새 규격을 추가하면서 구 규격도 유지한다.
2. 새 규격을 지원하는 앱의 내부 번호를 예컨대 2로 올려 배포하고, 실제 대한민국 스토어에서 업데이트 가능한지 확인한다.
3. 그다음 해당 플랫폼 서버 최소값을 2로 올린다. 내부 번호 1은 차단, 2 이상은 허용한다.
4. 앱 검증·운영 관찰 후 기존 API 제거처럼 호환을 깨는 서버 변경을 진행한다. 계속 foreground인 앱·게이트 없는 과거 앱의 요청 가능성도 고려해 서버의 하위 호환 정책을 별도로 판단한다.

스토어 버전·빌드만 올리면 내부 호환 번호는 바뀌지 않는다. 반대로 최소값을 올려도 스토어에 앱이 자동 등록되거나 업데이트가 자동 설치되지는 않는다.

## 6. 장애·롤백

- 앱은 시작/foreground 복귀에 최대 5초 정책 확인을 한다. 상시 polling은 하지 않는다.
- 정상 정책은 API 환경·플랫폼별로 저장한다. 캐시도 없는 최초 조회 실패는 허용한다. 이미 확인한 차단은 네트워크/404/503에도 유지한다.
- 이 게이트가 없는 기존 빌드 1에는 사후 차단을 소급 적용할 수 없다. 서버 인증/인가나 구 API 요청 거부를 대체하는 장치가 아니다.
- 긴급 해제는 최소값 0(또는 이전 허용값)으로 낮추고 API를 재생성한 뒤 200 응답을 확인한다. 앱의 재확인/복귀로 해제된다.
- **차단 해제 전에 endpoint부터 제거하지 않는다.** 기존 차단 캐시 때문에 404에도 이용 차단이 남는다. 코드 롤백 시에도 먼저 완화된 정책을 정상 응답시키고 공개 endpoint를 유지한다.

## 7. 서버 담당자 회신 양식

```text
반영 브랜치/커밋:
배포 환경 및 시각(Asia/Seoul):
DB 변경: 없음
iOS 최소 호환 번호:
Android 최소 호환 번호:
무인증 정책 GET 상태 / request ID:
Stage 차단·스토어 이동·복귀·해제 결과:
운영 정책 GET 검증 결과:
미완료 항목:
롤백/긴급 해제 확인 결과:
```

이 문서는 서버 담당자 전달용이며, 작성 자체가 배포 완료를 뜻하지 않는다. 실제 메시지 전송은 하지 않았다. 상세 앱 상태·캐시·파일 역할은 [APP_VERSION_POLICY.md](APP_VERSION_POLICY.md)를 참고한다.
