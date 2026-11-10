# 프로필 수정·사진 변경 서버 요청서

작성일: 2026-11-10 (Asia/Seoul)
대상: `shift_calendar_server` Express/Sequelize 서버 담당자
상태: Flutter 구현·로컬 모의 검증 완료, 서버 요청 준비 완료. **서버 구현·배포·실기기 연동은 별도 인수 필요.**

## 전달할 요청

설정의 프로필 카드를 눌러 가입 때와 같은 입력 UI에서 이름·휴대폰·직종·소속·사진을 수정합니다.
기존 `POST /api/v1/auth/profile`에 JSON 부분 수정 호환성을 유지하면서 `profile_image` 파일 1개의
multipart 부분 수정을 추가해 주세요. 사진만 바꾸는 요청도 성공해야 합니다.
직종은 기존 Flutter 가입 화면과 동일하게 자유 입력 1~20자로 확장해 주세요.
가입 완료 API를 일반 편집에 호출하지 않으며 일반 수정으로 `profile_completed_at`을 생성하거나 변경하지 않습니다.

## 확인한 현재 구현과 수정 위치

2026-11-10 인접 서버 저장소의 아래 코드를 직접 읽었습니다. 운영·Stage 배포 상태를 확인한 기록은 아닙니다.

| 파일 | 확인한 사실 / 요청 변경 |
|---|---|
| `src/routes/authRoutes.ts` | `/profile/complete`에만 `profileImageUploadMiddleware`가 있음. 일반 `/profile`에도 인증 뒤 multipart parser를 추가하고, parser 뒤 필드 validation을 실행. 일반 수정의 직종 enum validator 제거 |
| `src/controllers/authController.ts` | `updateProfile`은 `req.body`만 service에 전달. 가입 완료에만 upload/실패 object 정리가 있음. 일반 수정에서도 검증된 선택 이미지를 처리하도록 공용 service로 분리 |
| `src/services/profileService.ts` | 일반 수정은 생략 필드 유지, 선택값 `null`/빈 문자열 삭제, transaction·전화 중복 검사 지원. 일반 수정에 내부 `profile_image_key` 처리 추가. `normalizeJobType` enum을 자유 문자열 검증으로 교체 |
| `src/models/User.ts` | `job_type`의 TypeScript union과 Sequelize `isIn` 제한이 있음. nullable string·1~20자 검증으로 변경. `toJSON()`의 비공개 key/완료 시각 제외 및 완료 boolean 유지 |
| `migrations/add_profile_completion_support.sql`, `migrations/final_schema.sql` | `ck_users_job_type`가 4개 enum 제한. 배포 DB에는 후속 migration, 새 설치 schema에도 길이 제한 반영 |
| `src/middlewares/profileImageUpload.ts` | 기존 memory parser·파일 1개·5MB 제한 및 JPEG/PNG/WebP 내용/MIME 검증 재사용 |
| `src/services/profileImageStorageService.ts` | 환경 prefix/사용자 UUID/새 UUID key로 S3 저장. 비공개 `private, no-store` 및 기존 환경변수 재사용 |
| `src/utils/accountDataLock.ts` | 계정별 advisory lock. 사진 변경과 탈퇴/정리 작업의 경쟁 제어에 기존 lock 규칙 재사용 |
| `src/utils/profileImageLocation.ts`, `src/controllers/profileImageController.ts` | 이미지 URL은 `/api/v1/profile-images/:user_id`의 인증된 안정 경로. key/원본 S3 URL 노출 및 redirect 없이 유지 |
| `src/openapi/profileAuthOpenApi.json` | 일반 수정 multipart·자유 직종·부분 수정/삭제 규칙·오류 예시 추가 |

## 요청 계약

```http
POST /api/v1/auth/profile
Authorization: Bearer <access_token>
```

사진이 없으면 `application/json`:

```json
{"name":"새 이름","job_type":"서비스 기획자","workplace":""}
```

사진이 있으면 `multipart/form-data`:

```text
profile_image: <JPEG/PNG/WebP 파일 1개>
name: 새 이름                 # 변경한 경우만
job_type: 서비스 기획자       # 변경한 경우만
workplace:                   # 빈 문자열 = 명시적으로 삭제
```

boundary는 Dio가 생성합니다. `profile_image` 하나만 있어도 유효하며 가입용 필수값 전체를 요구하지 않습니다.
문자열 `"null"`을 삭제 표식으로 해석하지 않습니다.

| 필드 | 수정 계약 |
|---|---|
| `name` | 생략 시 유지. 포함 시 trim 후 1~50자, 빈 문자열/null 거부 |
| `phone` | 생략 시 유지. 포함 시 기존 휴대폰 검증·정규화·중복 검사. Flutter는 변경한 한국 휴대폰을 숫자로 전송 |
| `timezone` | 기존 JSON 계약 유지. 편집 UI는 값을 보내지 않아 저장된 타임존을 유지 |
| `job_type` | 생략 시 유지, JSON null 또는 빈 문자열/공백은 삭제, 그 외 trim 후 1~20자 자유 문자열. 기존 NURSE/DOCTOR/EMT/OTHER도 유지 |
| `workplace` | 생략 시 유지, JSON null 또는 빈 문자열/공백은 삭제, 그 외 trim 후 1~100자 |
| `profile_image` | 생략 시 사진 유지. 포함 시 기존 형식/내용 검사 후 파일 교체. 이번 Flutter 화면은 사진 삭제 동작을 제공하지 않음 |
| `profile_image_url` | 기존 JSON 동작 유지. Flutter 편집은 이 필드를 보내지 않음. 외부 임의 URL 주입을 허용하지 않음 |

`profile_image`와 `profile_image_url`이 함께 오면 모호한 우선순위 대신 400 `VALIDATION_ERROR`로 거부하는 계약을 요청합니다.
`user_id`, `profile_image_key`, `profile_completed_at` 등 클라이언트 입력은 저장 대상을 결정하는 데 쓰지 않습니다.

성공은 기존 HTTP 200 wrapper와 **최신 전체 본인 프로필**을 반환합니다.

```json
{
  "success": true,
  "data": {
    "user_id": "<현재 인증 사용자 UUID>",
    "email": "reviewer@example.com",
    "name": "새 이름",
    "phone": "010-1234-5678",
    "timezone": "Asia/Seoul",
    "job_type": "서비스 기획자",
    "workplace": null,
    "profile_image_url": "/api/v1/profile-images/<현재 인증 사용자 UUID>",
    "requires_profile_setup": false
  },
  "request_id": "<request id>"
}
```

완료 boolean은 기존 DB 상태에서 계산합니다. 일반 수정 응답을 무조건 false로 만들지 않습니다.
이미지 URL은 기존 설정에 따라 API origin 절대 URL도 허용하지만 비공개 storage key·서명 URL은 응답에 넣지 않습니다.
Flutter는 성공 응답으로 `authProvider.user`를 갱신하고 사진을 보냈을 때 byte Provider를 무효화해 같은 URL도 다시 조회합니다.

## 요청 처리·파일 교체·실패 정리

```text
Router
 → auth rate limit / authMiddleware
 → profileImageUploadMiddleware (JSON도 통과)
 → 필드 validation
 → Controller
 → Profile service (검증·계정 lock·storage 조정)
 → Sequelize transaction / PostgreSQL + 기존 S3 service
```

1. 입력 필드와 이미지를 검증하고 기존 인증 사용자 ID를 사용합니다. 사진 변경은 동일 계정 데이터 lock으로 직렬화합니다.
2. lock 안에서 활성 계정을 재확인한 뒤 새 UUID object를 업로드합니다. 외부 storage I/O 동안 DB transaction을 열어 두지 않습니다.
3. DB transaction에서 활성 계정을 다시 검사하고 row lock을 얻어 **요청에 포함된 필드만** 수정합니다.
   선택 사진이 있으면 소유자 검증을 거친 새 key와 API 이미지 URL도 같은 transaction으로 저장합니다.
   `profile_completed_at`, 인증 ID, 이메일은 유지합니다.
4. 업로드/검증/전화 중복/DB 실패 시 기존 프로필·사진을 유지하고 이번 요청의 새 object만 정리합니다.
5. DB commit 뒤 이전 관리 object를 정리합니다. 새 key와 같은지·같은 소유자인지 확인하고 외부 OAuth URL을 object key로 삭제하지 않습니다.
   정리 실패는 요청 ID와 내부 오류 코드로 기록하고 재시도 가능한 정리 작업에 남깁니다.
   이미 commit된 프로필을 뒤늦게 실패 응답으로 바꾸거나 현재 새 object를 삭제하면 안 됩니다.
6. 기존 사진이 과거 S3 URL만 가진 경우 `legacyProfileImageKey`로 검증 가능한 소유 key만 정리합니다.
   탈퇴 worker와 교체가 경합해 삭제된 계정에 새 object가 남지 않는지 확인합니다.

이 순서는 **요청하는 구현 조건**입니다. 현 서버 일반 수정에는 사진 처리가 없으므로 현재 동작으로 오인하지 마세요.
이름·전화·직종·소속·파일 내용·토큰은 로그에 남기지 않습니다. structured log의 event/error code/request ID만 기존 로깅 규칙에 맞춰 사용합니다.

## DB·환경변수·호환성

- 사진 변경에 새 컬럼은 필요 없습니다. 기존 `profile_image_key`와 `profile_image_url`을 재사용합니다.
- 직종 후속 migration은 기존 enum check만 제거하고 trim 길이 1~20자 check로 교체합니다. 기존 데이터를 재작성하지 않습니다.
- 기존 가입 endpoint·일반 JSON 부분 수정·인증 이미지 GET·친구 공개 범위를 유지합니다.
- 직종 자유 입력 정책은 ADR-0027 및 `PROFILE_ONBOARDING_SERVER_REQUIREMENTS.md`에서 이미 요청했지만, 이번 확인의 로컬 서버에는 아직 enum이 있습니다. 실제 적용·배포 증거로 인수해 주세요.
- 새 환경변수는 요청하지 않습니다. 업로드 사용 시 기존 `PROFILE_IMAGE_STORAGE_REGION`, `PROFILE_IMAGE_STORAGE_BUCKET`,
  `PROFILE_IMAGE_STORAGE_PREFIX`(local/test/stage/center), 선택 endpoint/force-path-style 및 API base URL 설정과 기존 AWS 인증 방식을 재사용합니다.
  비밀값은 문서/로그/PR에 붙이지 않습니다. Stage는 Stage prefix·설정, 운영은 center 설정을 유지합니다.
- 자유 직종 저장 후 enum 제약으로 단순 rollback하면 실패합니다. 데이터를 임의 변환/삭제하지 말고 자유 직종 호환을 유지하는 서버 버전으로 복구합니다.

## 서버 인수 체크리스트

- [ ] JSON 이름만 변경할 때 생략된 전화/직종/소속/사진/타임존 유지
- [ ] 사진만 첨부한 multipart 및 사진+일부 필드 수정 성공
- [ ] JSON null/빈 문자열 및 multipart 빈 문자열의 선택값 삭제, 생략값 유지
- [ ] 직종 자유 문자열·기존 4개 코드 모두 저장/조회, 공백/길이/잘못된 자료형 검증
- [ ] 이미지 MIME/내용 불일치·손상·미지원 형식·5MB 초과·파일 2개·잘못된 part 이름 거부
- [ ] 401/계정 비활성·탈퇴 진행 상태, 전화 중복 409 `PHONE_ALREADY_EXISTS` 및 unique 경쟁 오류
- [ ] storage 실패 503 `PROFILE_IMAGE_STORAGE_UNAVAILABLE`, 이미지 오류 400 `INVALID_PROFILE_IMAGE`, 초과 413 `PROFILE_IMAGE_TOO_LARGE`
- [ ] 기존 `VALIDATION_ERROR`/`INVALID_PHONE`/`INVALID_TIMEZONE`/`INVALID_JOB_TYPE`와 `{success:false,error:{code,message},request_id}` 유지
- [ ] DB 실패 시 새 object 정리 및 기존 값 유지, commit 뒤 이전 object 정리 실패 재처리
- [ ] 연속·동시 교체/탈퇴 경합에서 현재 사진 소실·고아 object 없음
- [ ] 프로필 완료 시각/boolean 불변, 친구/그룹 응답에 전화·소속 비노출, private/no-store 이미지 응답 유지
- [ ] OpenAPI request schema에 JSON/multipart 모두 추가하고 위 정상·오류·회귀 테스트 통과
- [ ] migration/seed(기존 데이터 보존, 추가 seed 불필요)/롤백 영향 기록 및 서버 문서 갱신

## 배포·실기기 확인과 롤백

1. 서버 DB/코드/OpenAPI/테스트를 먼저 준비하고 Stage에 적용합니다.
2. Stage 실제 iPhone에서 기존 정보 표시 → 사진 선택/취소/권한 거절/미리보기 → 부분 저장 → 설정 즉시 갱신 → 재로그인/재실행 유지 확인.
3. 사진과 함께 선택 근무 정보 삭제, 실패 후 재시도, 토큰 갱신 뒤 파일 재전송, 친구 화면 최신 사진 조회를 확인합니다.
4. 운영 migration·서버 배포 후 같은 계약을 확인하고 마지막에 Flutter 새 빌드를 제출합니다.
5. Flutter 롤백은 이번 편집 연결을 되돌리는 이전 빌드로 복구합니다. 서버는 기존 JSON과 자유 직종·사진 GET 호환을 유지합니다.

클라이언트 검증: 전체 Flutter 테스트 227 pass·기존 skip 1, 변경 Dart 12개 분석 진단 0건·포맷 변경 0건.
사진 multipart는 Dio adapter로 byte stream·인증 header·파일/선택 필드·401 refresh 재전송을 검증했습니다.
실제 API의 이미지 저장·S3 정리·재로그인 유지와 실기기 사진 권한/교체는 이 결과에 포함하지 않습니다.

## 이 파일의 역할·의존성·사용 예

- 역할: 서버 담당자가 바로 구현·검증·배포할 수 있는 프로필 수정 인수 계약.
- 의존성: 기존 auth/profile·가입 완료·비공개 이미지 서버 코드, ADR-0024/0025/0027/0034 및 Flutter `ProfileSetupPage.edit`.
- 사용 예: 이 문서의 `전달할 요청`과 요청 계약을 서버 작업 이슈에 첨부하고 인수 체크리스트와 Stage 결과를 회신받습니다.
- 이번 작업은 요청 자료 준비이며 서버 코드 수정·배포·담당자 메시지 전송은 수행하지 않습니다.
