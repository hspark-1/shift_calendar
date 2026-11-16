# ShiftMate 지원·개인정보처리방침 페이지 전달 가이드

## 2026-11-12 정책 외 화면 사용 안내 제거 — 최신 교체본

- privacy.html에서 표 사용 안내5개와 관련CSS/ARIA참조를 제거했고, 공개 변경 이력도 개인정보 처리 변경만 남겼다. 정책 본문·75%크기·표 스크롤과support는 유지한다. 최신privacy SHA-256은 `c6584bf896d9d3c47dfa55071cc024fef89ed1c2cc943b4f44c5c0b945557d8d`, support는 아래75%교체본의 `c9163d45be924ab4a73f614e54b2d2029efa66e5aa226c6cee94dd857e77799f` 그대로다. 아래 이전privacy hash는 당시 이력이다.
- HTML구조·14절/5표·MD표 셀·연령/동의 보존·안내 잔존0/누락참조0·diff검사를 통과했다. 운영 배포는 수행하지 않았다. 교체/원격 확인/롤백은 아래 절차를 따른다.

## 2026-11-12 두 페이지75% 크기 조정 — 최신 교체본

- `privacy.html`과 `support.html`을 함께 교체한다. 글자·여백·최대 폭·표 크기를75%로 줄였고 본문/링크/정책 문구는 직전 파일과 동일하다. 내비게이션·문의 버튼44px·브라우저 확대·표 가로 스크롤은 유지한다. 아래 이전 privacy 단독 교체본/hash와 고객지원 미변경 설명은 당시 이력이다.
- 최신 SHA-256: privacy `6f4306bd6352ddfe8d4d19b4e203376ffcda68d9b3e07fb52f0d80660e3b4553`, support `c9163d45be924ab4a73f614e54b2d2029efa66e5aa226c6cee94dd857e77799f`.
- 축소 직전 로컬본 hash: privacy `02cf90b8accd0b1b463e01fd013e122af6e11de47489634088c2dcd66eb6f3e6`, support `34867bdcc0c4726b1c6f09b2b1cf1bc2810391ad5beed18b915a9cc13446a3a2`. 이는 원격 반영 여부를 뜻하지 않는다. 두 운영 파일을 각각 비공개 경로에 백업하고 교체 실패 시 해당 백업을 복원한다.
- 검증:320/375/844/1440px·375px 본문200%/다크 선호·동작 줄이기 조건을 두 페이지에 적용해12조건 통과.375px 두 페이지 PNG를 확인했다. 원문 보존·개인정보 표/MD 셀·연령/동의 원문·HTML 구조 검증도 통과했다. 결과는 `/private/tmp/shiftmate_web_scale_2026-11-12`에 있다.
- 운영 배포는 수행하지 않았다. 담당자가 기존 `/privacy`·`/support`의 실제 정적 파일 경로에 교체한 뒤 HTTPS GET200·위 최신hash·모바일 표시/상호 링크를 확인한다. URL은 유지하므로 앱 새 빌드는 필요하지 않다.

## 2026-11-12 교체용 문안 v1.1 — 로컬 수정·검증 완료

- 배포 대상: 이 디렉터리의 `privacy.html`을 기존 `https://www.shiftmate.co.kr/privacy` 응답 파일에 교체한다. `PRIVACY_POLICY.md`·검토/작업 문서·임시QA스크립트는 공개 디렉터리에 복사하지 않는다. 고객지원 HTML·앱 바이너리·API/Nginx 라우팅은 변경하지 않는다.
- 변경:600px 이하 table block 변환을 제거하고5개 표를 내부 가로 스크롤로 제공한다. 나만 보기/그룹 공유·SDK·공휴일 API·그룹 시간대 설명을 정정했다. 사용자 지시에 따라 연령/항목별 동의 문구와 기존 보관 정책은 유지한다. 내용 근거와 남은 국외 처리 확인 사항은 PRIVACY_REVIEW 상단을 참조한다.
- 교체본 SHA-256: `02cf90b8accd0b1b463e01fd013e122af6e11de47489634088c2dcd66eb6f3e6`. 교체 전 공개본은 `859e3da0fcabceceb84a5f39f0c8b2572bb2f9d9ba1837915bc89d2902063e02`였다. 해당 공개본을 비공개 경로에 백업한 뒤 기존 파일 경로/권한으로 교체하고 실패 시 백업을 복원한다. 기존 정적 파일 교체만으로 서비스되는 경우 앱 새 빌드는 필요하지 않다.
- 검증:11개 viewport/본문 확대/시스템 선호 조건에서 표 정렬·본문 가로 넘침·키보드 스크롤·HTML/MD표 동기화를 확인했다.375px 수정 전후·가로·큰글자·마지막 열 PNG와 measurements.json은 `/private/tmp/shiftmate_privacy_qa_2026-11-12`에 있다.
- 운영 반영 상태: 현재 세션에는 확인된 서버 배포 연결/경로가 없어 직접 교체하지 않았다. 아래 `/var/www/shiftmate/privacy.html`은 기존 전달 예시이며 실제 경로를 확인한 값이 아니다. 담당자가 교체한 뒤 인증서 검증을 유지한 HTTPS GET200·위 SHA 일치·375px Safari에서 표 내부 좌우 스크롤과 지원 링크를 확인한다. 운영 페이지가 이미 바뀌었다고 간주하지 않는다.
- 아래 v1.0/초안/404 설명은 당시 이력이다. 현재 원격 페이지는 이 작업 시작 시200·v1.0이었으며 이번 수정 파일은 v1.1이다.

## 최신 전달물 — 공개 문안 v1.0

`privacy.html`과 `PRIVACY_POLICY.md`를 2026-10-18 최초 시행 공개 문체로 갱신했다. 검토 배너·운영 메모·미확정 자리표시자는 제거했다. 아래 과거 초안 상태 설명보다 이 기록을 우선한다. 서버에는 HTML만 전달한다. 계약별 외부/국외 처리 고지 대조는 PRIVACY_REVIEW의 최신 주의사항을 확인하고 완료한 뒤 심사에 제출한다. 서버 재게시·공개 검증은 담당자 수행 사항이다.


기준일: 2026-10-18. 대상: 홈서버 운영 담당자. 이 문서의 명령은 담당자가 서버 환경에 맞게 실행할 예시이며 실제 배포는 수행하지 않았다.

## 2026-10-18 후속 작성·확인

- 실제 지원 주소는 `https://www.shiftmate.co.kr/support`, GET 200 확인. 개인정보 주소는 `https://www.shiftmate.co.kr/privacy`, GET 404로 게시 전이다. 아래 루트 도메인 경로 예시는 실제 운영의 www 호스트에 맞춰 적용한다.
- `PRIVACY_POLICY.md`는 사용자 채택 정책·코드 근거로 갱신한 본문, `privacy.html`은 같은 본문의 검토본이다.
- 먼저 `PRIVACY_REVIEW.md`의 잔여 기기/이미지 삭제·국외 이전·작업 기록 보관·연령 제한 등 공개 전 확인 목록을 완료한다. 정책 채택만으로 운영 적용 완료로 처리하지 않는다.
- 실제 서버에 적용하거나 게시하는 작업은 이번에 수행하지 않았다.

## 후속 수정 인계

- 공개 개인정보 URL도 이후 GET 200으로 확인했다. 아래 최초 404 기록은 조회 이력이며 현재 페이지는 검토본 공개 상태다.
- 로컬 MD/HTML은 제공자별 연결 해제·정책/운영 증거 구분·연령 제한 문구를 정정했으며 서버 재게시 전이다.
- `PRIVACY_ACTION_PLAN.md`: 문서/프로그램/운영 작업표.
- `BACKEND_PRIVACY_REQUEST.md`: 서버 담당자가 구현/운영하고 증거를 회신할 요청서. 두 가이드는 공개 디렉터리에 복사하지 않는다.

## 전달 파일과 완료 상태

| 파일 | 역할 | 상태·의존성 | 사용 예 |
|---|---|---|---|
| `support.html` | 공개 문의 방법·탈퇴 요청 경로 | 공개 이메일 확정. 외부 CSS·JS·이미지·빌드·API 의존성 없음 | `/support`의 응답 본문 |
| `privacy.html` | 개인정보처리방침 검토용 HTML | **공개 전 초안**. 서버 운영 정책 확인 및 담당자 최종 작성 필요. 외부 자산 의존성 없음 | 확정 후 `/privacy`의 응답 본문 |
| `DEPLOY_GUIDE.md` | 파일 전달·Nginx 연동·검증·롤백 | 서버 설정·권한·TLS는 담당자가 확인 | 이 문서는 공개 디렉터리에 복사하지 않음 |

앱은 iPhone 전용 최초 출시, 대한민국 한정·무료·IAP 없음이다. 공개 문의 이메일은 `sspp8585@gmail.com`이다. 두 HTML은 UTF-8 한국어, 모바일 반응형, 내부 CSS만 사용하며 폼·분석 스크립트·자동 API 호출이 없다. `/support`와 `/privacy`로 서로 연결된다.

## 요청하는 최종 URL

| URL | 서버 파일 예시 |
|---|---|
| `https://shiftmate.co.kr/support` | `/var/www/shiftmate/support.html` |
| `https://shiftmate.co.kr/privacy` | `/var/www/shiftmate/privacy.html` |

`api.shiftmate.co.kr`, `stage-api.shiftmate.co.kr`의 API 라우팅은 유지한다. 루트 홈페이지는 이번 전달 범위에 필수가 아니며 별도 필요하면 `/support`로 연결할 수 있다.

DNS 관리 화면에는 `@`·`api`·`stage-api`가 동일 IP로 설정되어 있었다. 서버의 현재 공인 IP와 일치하면 추가 DNS 변경 없이 진행할 수 있다. 화면 확인만 했으며 실제 전파 상태는 검증하지 않았다.

## 개인정보처리방침 공개 전 확인

`privacy.html`은 그대로 공개하거나 심사 URL로 제출하지 않는다. ‘운영 확인 필요’가 남은 이유는 프론트 코드만으로 보유 기간·위탁·파기 정책을 확인할 수 없기 때문이다. 정책 확정은 서버 담당자와 개인정보 운영 책임자가 진행한다.

- [ ] 개인정보처리자 명칭·담당자·시행일·변경 안내 확정
- [ ] 실제 수집·저장 항목, 필수/선택, 처리 목적·근거·수집 경로 대조
- [ ] 로그인 제공자별 데이터 및 친구·그룹 공유 대상·항목·권한·철회 확인
- [ ] 계정·일정·로그·문의·기기·파일·백업의 보유 및 삭제 기한 확정
- [ ] 탈퇴 비동기 작업의 완료·오류·재처리·소셜 연결 해제·백업 파기 확인
- [ ] 외부 서비스 수신자·위탁/제공 관계·처리 국가·국외 이전·근거 확인
- [ ] 권리 행사·본인 확인·아동 이용·안전성 조치·구제 안내 확정
- [ ] Nginx 로그·홈페이지 쿠키·문의 이메일 처리까지 정책과 대조
- [ ] 초안 안내 상자, 제목의 ‘공개 전 초안’·‘검토 초안’, `.pending` 문구를 최종 본문으로 교체
- [ ] 확정본에서 `robots`의 `noindex,nofollow` 제거 여부 결정(검색 노출 선택 사항이며 접근 인증 수단이 아님)

빠른 잔여 문구 검사 예시:

```bash
rg -n '운영 확인 필요|공개 전 초안|검토 초안' privacy.html
```

공개 준비가 끝나면 위 검색에 결과가 없어야 한다. 문구를 단순 삭제하는 것이 아니라 실제 정책으로 채운 뒤 검토한다.

현재 작성 근거는 프론트의 `User`, `AuthRemoteDataSource.completeProfile/deleteAccount`, `DeviceRemoteDataSource.syncCurrentDevice`, `EventApiModel`, `FriendService`와 관련 프로젝트 문서다. 탈퇴 API의 `202 Accepted`는 삭제 완료가 아니라 접수 성공이다. 서버 검증 없이 즉시 삭제·정해진 보관 기간·국외 이전 없음 등을 약속하지 않는다.

## 서버 준비·파일 배치

1. `shiftmate.co.kr` 요청을 받는 기존 HTTPS 설정을 찾는다. API용 `server_name`만 있으면 담당자가 루트 도메인 전용 서버 설정을 추가한다. `www`를 운영하면 루트 주소로 리다이렉트한다.
2. TLS 인증서가 `shiftmate.co.kr`을 포함하는지 확인한다. `*.shiftmate.co.kr` 또는 API 전용 인증서만으로 루트 도메인이 포함되는 것은 아니다.
3. 기존 HTML과 수정할 Nginx 설정 파일을 백업한다. 파일명·위치는 서버 담당자가 관리한다.
4. **정책 확정 후**, 전달 파일 중 HTML 두 개만 서버의 준비 디렉터리에 복사한다. 서버 내 해당 디렉터리에서 다음 예시를 실행한다.

```bash
sudo install -d -m 755 /var/www/shiftmate
sudo install -m 644 support.html /var/www/shiftmate/support.html
sudo install -m 644 privacy.html /var/www/shiftmate/privacy.html
```

Nginx 실행 계정이 상위 디렉터리를 탐색하고 파일을 읽을 수 있어야 한다. 소유권·SELinux/AppArmor·컨테이너 볼륨은 현재 운영 방식에 맞춘다. 두 페이지는 로그인·접근 토큰 없이 공개할 문서다.

## Nginx 설정 예시

다음 `location`들만 **`shiftmate.co.kr`을 처리하는 기존 HTTPS `server` 블록 안에 병합**한다. 서버 블록 전체를 덮어쓰거나 API의 `proxy_pass`·포트·인증서 경로를 교체하지 않는다. 같은 경로의 기존 `location`이 있으면 중복 생성하지 않고 병합한다.

```nginx
location = /support {
    alias /var/www/shiftmate/support.html;
    default_type text/html;
    charset utf-8;
}

location = /privacy {
    alias /var/www/shiftmate/privacy.html;
    default_type text/html;
    charset utf-8;
}

location = /support/ {
    return 301 /support;
}

location = /privacy/ {
    return 301 /privacy;
}
```

`alias`로 확장자가 없는 URL을 단일 HTML 파일에 연결한다. `default_type`은 HTML Content-Type을 명시한다. 전역 인증·접근 제한·캐시·다운로드 헤더·`error_page` 상속에 따라 실제 응답이 달라질 수 있으므로 최종 응답을 확인한다. 광범위한 파일 공개 규칙 대신 위 두 경로만 제공한다.

설정 변경 후:

```bash
sudo nginx -t
```

성공했을 때만 reload한다. systemd 운영 예시는 다음과 같다. Docker/NAS는 해당 관리 도구의 검증·reload 방식으로 대체한다.

```bash
sudo systemctl reload nginx
```

## 배포 후 검증 및 인계 결과

가능하면 홈서버 밖의 네트워크에서도 확인한다. `curl -k`로 인증서 오류를 숨기지 않는다.

```bash
curl -I https://shiftmate.co.kr/support
curl -I https://shiftmate.co.kr/privacy
curl -I https://shiftmate.co.kr/support/
curl -I https://shiftmate.co.kr/privacy/
curl --fail --show-error https://shiftmate.co.kr/privacy -o /tmp/shiftmate_privacy_check.html
rg -n '운영 확인 필요|공개 전 초안|검토 초안' /tmp/shiftmate_privacy_check.html
curl --fail --show-error https://stage-api.shiftmate.co.kr/api/v1/health
```

- [ ] `/support`, `/privacy`: 인증 없이 `200`, `Content-Type: text/html`과 UTF-8 본문
- [ ] TLS 인증서 정상·도메인 일치, 쿠키/로그인/인증 챌린지 불필요
- [ ] 끝 슬래시 경로는 대응하는 기본 경로로 정상 리다이렉트
- [ ] GET 응답이 HTML 문서이며 앱 다운로드나 JSON 오류가 아님
- [ ] 지원 이메일과 두 페이지 간 링크 동작
- [ ] iPhone Safari에서 글자·표·링크가 읽히며 가로 넘침 없음
- [ ] 개인정보처리방침 초안 안내·미확정 문구 없음
- [ ] 기존 API health 응답 유지, 운영 API도 기존 점검 절차로 회귀 확인

서버 담당자는 배포 시각, 최종 URL, 응답 상태·Content-Type, 정책 시행일, 정책 검토 완료 여부와 API 회귀 결과를 공유한다. 그 결과를 받은 뒤 `_docs/APP_STORE_RELEASE_CHECKLIST.md`를 갱신한다.

검증이 끝나면 App Store Connect의 Support URL에 `/support`, Privacy Policy URL에 `/privacy` 전체 HTTPS 주소를 입력한다. Flutter 로그인·설정 화면에서 정책 URL로 이동하는 기능은 별도 앱 작업이다. 현재 로그인 안내는 일반 텍스트이며 이 파일 전달만으로 앱 내 연결이 완료되지는 않는다.

## 롤백

- HTML 내용만 변경했다면 백업한 파일을 복구한다. 정책 이전 버전의 보관·고지 규칙도 따른다.
- Nginx 문제가 있으면 추가·수정한 해당 도메인 설정만 백업으로 복구한다.
- `nginx -t` 성공 후 운영 방식에 맞춰 reload하고 기존 API health를 재확인한다.
- 기존에 공개·심사 제출한 정책 URL은 페이지를 없애지 말고 정상 동작하는 직전 확정본으로 복구한다.

## 이번 제작 검증과 한계

HTML 구문 구조·모바일 viewport·링크·외부 자산 의존성·이메일·초안 표시를 로컬에서 검사했다. 서버 Nginx 실행 환경이 없어 실제 설정 검사·공개 HTTP/TLS·실기기 브라우저 검증은 서버 담당자가 수행한다. HTML 파일만으로 개인정보 운영 정책의 법적 적합성을 검증한 것은 아니다.

근거: [Nginx alias/default_type 공식 문서](https://nginx.org/en/docs/http/ngx_http_core_module.html), [Apple 개인정보 URL 안내](https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy), [Apple 지원 URL 안내](https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/).
