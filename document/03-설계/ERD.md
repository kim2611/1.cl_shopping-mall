# ERD / 스키마 설계

> 상태: **1차 완성판** (14차 라운드까지 반영 — 소프트 삭제 vs UNIQUE 충돌 일괄 수정) → **실제 DB에 적용됨** (Flyway `V1`~`V3`, `backend/src/main/resources/db/migration/`)

## 전 테이블 공통 규칙 (프로젝트 표준)
- PK 필수
- 공통 컬럼 5종 필수:
  - `del_yn` — 삭제여부 (`'Y'`/`'N'`, 기본 `'N'`, 논리 삭제용)
  - `created_by` — 최초작성자
  - `created_at` — 최초작성일
  - `updated_by` — 최종수정자
  - `updated_at` — 최종수정일

## PK 채번 규칙
모든 PK는 **"4자리 대문자 테이블 코드 + 13자리 숫자"** (총 17자, `VARCHAR(17)`)를 사용한다.
- 숫자 부분은 `'SEQ_' + 테이블명(대문자) + '_01'` 이름의 PostgreSQL 시퀀스를 `NEXTVAL`로 1씩 증가시켜 채번하고 `LPAD`로 13자리 0-padding한다. 한 테이블에 시퀀스가 여러 개 필요해지면 `_01`, `_02`...로 확장한다.
  - 예) `accounts.id` 기본값 = `'ACCT' || LPAD(NEXTVAL('SEQ_ACCOUNTS_01')::TEXT, 13, '0')`
- 서브타입 테이블(`admins`/`general_accounts`)의 PK는 `accounts.id` 값을 그대로 복사해 쓰는 FK 겸 PK라 별도 시퀀스가 없음.
- **예외**: `files.id`는 PK 자체가 URL로 직접 서빙되는 공개 식별자라 이 규칙을 적용하지 않고 기존과 동일하게 UUID를 유지한다 — 접두코드+순번 조합은 값 추측이 오히려 쉬워 아래 보안 규칙과 충돌하기 때문.
- **주의**: 이 PK는 내부 조인/식별용이며 URL 등 클라이언트에 절대 노출하지 않는다. 외부 노출용 식별자는 기존과 동일하게 `products.uuid` / `board_posts.uuid` / `files.id`(UUID)를 사용한다.

## 자료형 규칙
특정 DBMS 전용 자료형은 가급적 자제한다 (Oracle/MySQL/MSSQL 등으로 옮길 때 그대로 못 쓰는 것들).
- **`BOOLEAN` 금지** → `CHAR(1)` `'Y'`/`'N'` + `CHECK`로 대체하고, 컬럼명도 `del_yn`과 동일하게 **`*_yn`** 접미사로 통일한다. (`is_default` → `default_yn`, `is_active` → `active_yn`, `is_primary` → `primary_yn`)
- **`TIMESTAMPTZ` 금지** → `TIMESTAMP`로 대체(타임존 정보 없이 저장, 필요하면 애플리케이션에서 UTC로 통일).
- **`UUID`는 예외로 유지**: `products.uuid`/`board_posts.uuid`/`files.id`는 [보안 규칙](#보안-규칙-프로젝트-표준)상 추측 불가능한 외부 공개 식별자여야 해서, 자료형을 바꾸면 그 목적 자체가 흔들린다. 다른 DBMS로 옮길 때는 `CHAR(36)` 문자열 저장으로 대체 가능(현재는 미적용).

## 공통 코드 규칙
값의 종류가 적고 의미를 이름으로 표시해야 하는 분류/상태성 컬럼(계정유형, 각종 상태, 등급, 부서, 결제수단, 게시판종류 등)은 `CHECK`로 하드코딩한 varchar 대신 `common_codes`를 참조하는 **`*_code_id`** 컬럼으로 관리한다. (예: `department` → `department_code_id`)

`common_codes`는 `parent_id` 자기참조로 계층을 표현한다 — 고정 개수의 그룹핑 컬럼(`group1`/`group2`..) 방식보다 깊이 제한이 없고, 이미 `categories`에서 쓰던 self-ref 패턴과 일관된다.

### `code_group`과 `parent_id`는 서로 다른 질문에 답한다 (겹치지 않음)
- `code_group` — "이 코드가 어느 분류에 속하는가" (모든 행에 필수, 평평한 태그, `WHERE code_group = 'X'`로 바로 조회)
- `parent_id` — "이 코드가 같은 분류 안에서 어떤 코드의 하위인가" (대부분 `NULL`, 계층이 실제로 존재하는 극소수 그룹에서만 사용)

`code_group`을 없애고 `parent_id` 트리만으로 표현하는 방법(그룹 자체를 루트 노드로 등록)도 가능하지만, 그러면 "그룹별 목록 조회"처럼 제일 흔한 조회가 재귀 쿼리가 되고 그룹 노드와 실제 선택값을 구분할 표식이 추가로 필요해진다. 이 프로젝트는 계층이 필요한 그룹이 드물어서 평소엔 `code_group`으로 바로 조회하고, 계층이 필요한 경우에만 `parent_id`를 얹는 현재 구조를 유지한다.

**비정규화 주의**: 자식 코드의 `code_group`은 parent 행의 `code_group`과 항상 같아야 한다 — DB가 자동으로 강제하지는 않으므로 시드/입력 시점에 지켜야 하는 애플리케이션 규칙이다.

### 코드 값(`common_codes.code`) 자체도 비식별화한다
`code` 컬럼에는 `'ADMIN'`, `'ACTIVE'`처럼 의미가 그대로 읽히는 문자열을 쓰지 않는다. **"code_group별 4~5자리 대문자 접두어 + 4자리 숫자"** 형태(예: `DEPR0001`)로, 값만 봐서는 무엇인지 알 수 없게 채번한다.
- 접두어는 `code_group`마다 하나씩 정하고, 숫자는 그 접두어 안에서 `0001`부터 순서대로 부여한다 (그룹별 개별 카운트 — 전역 시퀀스 아님).
- 실제 의미(화면 표시용 텍스트)는 항상 `code_name`에만 담는다. **`code`는 순수 식별자, `code_name`이 라벨.**
- 애플리케이션도 `code` 문자열을 파싱/비교해 분기하지 않고, FK인 `*_code_id`(= `common_codes.id`)로만 참조한다 — [PK 채번 규칙](#pk-채번-규칙)과 같은 이유(값 자체에서 의미가 드러나지 않게).
- `code`가 무의미한 값이 되면서 의미를 남겨둘 곳이 필요해져 `description`(상세 설명, nullable) 컬럼을 추가했다. `code_name`은 화면에 보여줄 짧은 라벨, `description`은 그보다 상세한 설명 — 역할이 다르다.

| 테이블.컬럼 | code_group | 접두어 예시 | 실제 의미(code_name) |
|---|---|---|---|
| accounts.account_type_code_id | ACCOUNT_TYPE | `ACTP` | 관리자/일반회원 (2종 — 9차 라운드에서 판매자/구매자 구분 제거) |
| accounts.status_code_id | ACCOUNT_STATUS | `ACST` | 활성/정지/탈퇴 |
| admins.department_code_id | DEPARTMENT | `DEPR` | (조직에 맞게 등록) |
| admins.admin_level_code_id | ADMIN_LEVEL | `ADLV` | 최고관리자/일반관리자 |
| general_accounts.grade_code_id | GENERAL_GRADE | `GGRD` | 일반/실버/골드/VIP 등 |
| companies.approval_status_code_id | COMPANY_APPROVAL_STATUS | `CAPR` | 승인대기/승인완료/승인거절 |
| companies.grade_code_id | COMPANY_GRADE | `CGRD` | 일반/우수 |
| company_role_permissions.permission_code_id | COMPANY_PERMISSION | `CPRM` | 상품/주문/정산조회/직원관리/배송/회사정보관리 (6종, 회사가 임의로 늘릴 수 없는 고정 목록) |
| company_owner_change_requests.status_code_id | OWNER_CHANGE_STATUS | `OWST` | 접수/검토중/승인/반려 |
| products.status_code_id | PRODUCT_STATUS | `PRST` | 판매중/품절/숨김 (옵션 조합 상태에도 재사용) |
| orders.status_code_id | ORDER_STATUS | `ORST` | 주문대기/결제완료/배송중/배송완료/취소 |
| payments.method_code_id | PAYMENT_METHOD | `PYMT` | 카드/계좌이체/가상계좌 |
| payments.status_code_id | PAYMENT_STATUS | `PYST` | 대기/완료/실패/환불 |
| refunds.method_code_id | REFUND_METHOD | `RFMT` | 원결제수단/계좌이체/적립금전환 |
| refunds.status_code_id | REFUND_STATUS | `RFST` | 요청/처리중/완료/실패 |
| board_posts.board_code_id | BOARD_TYPE | `BDTP` | 공지사항/FAQ(+하위카테고리)/이벤트(공지 하위) |
| coupons.issue_type_code_id | COUPON_ISSUE_TYPE | `CPIT` | 공용코드/개별발급 |
| coupons.discount_type_code_id | COUPON_DISCOUNT_TYPE | `CPDT` | 정률/정액 |
| coupons.status_code_id | COUPON_STATUS | `CPST` | 사용가능/만료/중지 |
| account_coupons.status_code_id | ACCOUNT_COUPON_STATUS | `ACPS` | 발급됨/사용됨/만료 |
| deliveries.status_code_id | DELIVERY_STATUS | `DLST` | 상품준비중/발송/배송중/배송완료/실패 |
| delivery_status_histories.status_code_id | DELIVERY_STATUS | `DLST` | deliveries와 동일 그룹 |
| stock_histories.change_type_code_id | STOCK_CHANGE_TYPE | `STCT` | 입고/출고/주문차감/취소복원/재고조정 |
| settlements.status_code_id | SETTLEMENT_STATUS | `STST` | 정산대기/정산확정/지급완료 |
| admin_permissions.permission_code_id | ADMIN_PERMISSION | `APRM` | 상품/주문/회원/정산/게시판/쿠폰/회사/통계/권한관리 (9종) |
| reactions.reaction_type_code_id | REACTION_TYPE | `RCTP` | 좋아요/싫어요 |
| product_option_combinations.status_code_id | PRODUCT_STATUS | `PRST` | products와 동일 그룹 재사용 (조합=SKU 판매 가능 여부) |
| product_options.selection_type_code_id | OPTION_SELECTION_TYPE | `OSTP` | 필수/선택 (옵션 축 단위) |
| product_option_values.status_code_id | OPTION_VALUE_STATUS | `OVST` | 판매중/품절/단종 (옵션 값 단위) |
| notifications.notification_type_code_id | NOTIFICATION_TYPE | `NTTP` | 공지등록/이벤트당첨/주문·배송·환불/쿠폰/재입고/리뷰요청/댓글/회사승인/정산완료/문의답변/대량등록결과 (15종) |
| notifications.target_type_code_id | NOTIFICATION_TARGET_TYPE | `NTGT` | 주문/배송/쿠폰/게시물/리뷰/댓글/정산/회사/상품 중 어느 테이블을 가리키는지 |
| notification_settings.notification_type_code_id | NOTIFICATION_TYPE | `NTTP` | notifications와 동일 그룹 |
| admin_activity_logs.target_type_code_id | ADMIN_LOG_TARGET_TYPE | `ALTG` | 계정/상품/주문/쿠폰/공통코드/회사 중 어느 테이블을 가리키는지 |
| temp_bulk_import_batches.import_type_code_id | BULK_IMPORT_TYPE | `BITP` | 상품등록/송장등록/재고변경 |
| temp_bulk_import_batches.status_code_id | BULK_IMPORT_STATUS | `BIST` | 업로드됨/검증중/일부실패/반영완료/취소됨/만료됨 |
| temp_*_import_rows.status_code_id | IMPORT_ROW_STATUS | `IRST` | 대기/성공/실패 (3종 임시 테이블 공용) |

시드 예시는 `schema.sql` 하단 주석 참고 (예: `ACCOUNT_TYPE` 그룹의 "관리자"는 `code='ACTP0001'`).

`del_yn`은 소프트 삭제 플래그(공통 규칙)이지 분류값이 아니므로 이 규칙 대상에서 제외.

## 설계 방식
- [x] A. `schema.sql`(DDL) 초안 작성 → IntelliJ **DDL Data Source**로 실제 DB 연결 없이 시각화 → 검토/수정 반복 → 최종 확정 시 VM Postgres에 실제 적용

## 시각화 방법 (IntelliJ Ultimate)
1. `Database` 툴 창 → `+` → `Data Source > DDL Data Source`
2. `schema.sql` 지정, dialect: PostgreSQL
3. 생성된 가상 스키마 우클릭 → `Diagrams > Show Visualization`
4. `schema.sql` 수정 후 데이터소스 새로고침하면 다이어그램 갱신
5. 확정되면 VM 실제 Postgres(`jdbc:postgresql://127.0.0.1:5432/shopping_mall`)에 적용 (또는 Flyway 마이그레이션화)

## 계정 구조 (관리자/일반회원 — 9차 라운드부터)
'회원' 대신 **'계정(accounts)'**으로 관리는 유지하되, 계정 종류는 **관리자/일반회원 2가지뿐**이다. "판매자"는 더 이상 계정 종류가 아니라 일반 계정이 [회사 구조](#회사-구조-companies)를 통해 추가로 가질 수 있는 자격이다.

```
accounts (공통: password, name, phone_1/phone_2/phone_3, account_type_code_id, status_code_id)
  ├─ account_emails (1:N, primary_yn으로 대표 이메일 표시 — email 정규화)
  ├─ account_login_histories (1:N, 로그인 성공/실패 이력)
  ├─ account_terms_agreements (1:N, 약관 동의 이력)
  ├─ admins  (department_code_id, admin_level_code_id)
  └─ general_accounts (grade_code_id, points) — 구매 기본 프로필. company_members를 통해 회사에 소속되면 판매자 역할도 겸함
```
- 서브타입 테이블의 PK는 `account_id`이며 동시에 `accounts.id`를 참조하는 FK (class-table inheritance 패턴)
- `orders`/`carts`/`reviews`/`wishlists`/`point_histories`의 계정 관련 FK → `general_accounts.account_id` (구매/찜 행위는 일반회원만)
- `addresses`는 `accounts.id` 참조 (배송지는 계정 타입 무관하게 가질 수 있음)
- 전화번호는 계정당 최대 3개(`phone_1`~`phone_3`)까지 단순 컬럼으로 보관(정규화하지 않음). 이메일은 계정당 여러 개일 수 있어 `account_emails`로 정규화하고, `primary_yn` + 부분 유니크 인덱스로 대표 이메일이 계정당 0~1개로 유지되도록 강제.
- **로그인 식별**: 계정에 등록된 이메일 중 대표(`primary_yn='Y'`) 여부와 무관하게 아무 이메일로나 로그인 가능하도록 한다 — `account_emails.email`이 전역 `UNIQUE`라 어느 이메일로 조회해도 계정이 하나로 특정되기 때문. 대표 이메일은 알림 발송 등 "어디로 보낼지" 결정에만 쓰고, 인증 가능 여부와는 분리한다.

## 회사 구조 (companies) — 9차 라운드
"회사"는 사업자 단위이며 `accounts`와 1:1이 아니다. `company_members`를 통해 여러 일반 계정이 한 회사에 소속될 수 있고, 한 계정이 여러 회사에 동시에 소속될 수도 있다(다대다) — "1명이 여러 회사를 운영"하는 경우가 이 구조에서 자연히 성립한다.

```
companies (business_name, business_reg_no, bank_account_no, approval_status_code_id, grade_code_id, owner_account_id)
  ├─ company_grade_policies (1:1, grade_code_id별 수수료율/혜택)
  ├─ company_shipping_policies (1:1, 기본배송비/무료배송조건/도서산간)
  ├─ company_roles (1:N, 회사가 자유롭게 정의하는 직책 — 예: '대표', 'MD')
  │    └─ company_role_permissions (1:N, 직책이 가지는 권한 — 권한 "종류"는 COMPANY_PERMISSION 공통코드로 고정)
  └─ company_members (1:N, 계정×회사×직책 — 다대다의 핵심)
```
- `products`/`deliveries`/`settlements`/`coupon_targets`의 판매자 관련 FK → `companies.id` (기존 `sellers.account_id` 자리를 대체)
- **대표자(`companies.owner_account_id`)**: 직책 체계와 별개로 회사의 최종 책임자를 명시하는 컬럼. 직책이 잘못 구성돼도(예: 특정 권한을 가진 사람이 아무도 없어짐) 시스템이 항상 책임자를 확실히 알 수 있도록 함. 직접 `UPDATE`를 허용하지 않고, `company_owner_change_requests`(접수→검토중→승인/반려) 승인 절차를 거치도록 애플리케이션에서 강제한다 — 의도적으로 번거롭게 만들어 오남용/분쟁을 줄이는 게 목적.
- **권한 vs 직책**: 권한의 "종류"(상품관리/주문관리/정산조회 등)는 시스템에 고정된 목록(공통코드)이라 회사가 마음대로 새 종류를 만들 수 없다. 반면 "직책"의 이름과 어떤 권한들을 묶을지는 회사가 자유롭게 정의한다 — `admin_permissions`(관리자용, 전역 고정 목록에서 개인별로 부여)와는 별개의 체계.

## 보안 규칙 (프로젝트 표준)
- 클라이언트에 직접 노출되는(URL/API 응답) 리소스는 내부 PK 대신 **UUID 공개 식별자**를 사용한다 (OWASP IDOR/BOLA 대비).
  - `products`/`board_posts`: 내부 조인용 `id`(코드+시퀀스 PK) + 외부 노출용 `uuid` 컬럼 병행
  - `files`: 직접 URL로 서빙되는 경우가 많아 PK 자체를 UUID로 사용 — [PK 채번 규칙](#pk-채번-규칙)의 코드+순번 예외
  - **주의**: UUID는 추측/전수조사를 어렵게 하는 defense-in-depth일 뿐, 매 API 요청마다 소유권/인가 검증(BOLA 방지)을 반드시 별도로 수행해야 함 — UUID가 인가 체크를 대체하지 않음
  - 내부 PK(코드+13자리 순번)는 접두 코드로 테이블까지 유추되고 숫자는 순증가라 오히려 추측이 쉬움 — 절대 URL/응답에 그대로 노출하지 않는다.
- 파일은 `files` 공통 테이블에서 관리하고, 각 엔티티는 전용 연결 테이블(`product_files` 등)로 참조한다. `parent_type/parent_id` 형태의 폴리모픽 연관은 FK 무결성이 약해지므로 지양 — 새 엔티티가 파일이 필요하면 `xxx_files` 연결 테이블을 추가하는 패턴을 따른다.
- `files.stored_path`(실제 저장 경로/S3 key 등)는 클라이언트에 직접 노출하지 않는다.

## 엔티티 목록 (초안 - `schema.sql` 참고)
55개 테이블. 9차 라운드(계정/회사 구조 개편 + 대량등록)에서 바뀌거나 새로 생긴 것은 각 그룹 안에 표시했습니다. `refunds`는 13차 라운드에서 신설.

| 엔티티 | 설명 | 주요 관계 |
|---|---|---|
| common_codes | 공통 코드 (self-ref, description 포함, 프로젝트 전반의 분류값) | self 1:N, 20개+ 테이블에서 `*_code_id`로 참조 |
| terms | 약관 (버전 관리, 개정 시 새 행) | N:1 common_codes(TERMS_TYPE), 1:N account_terms_agreements |
| accounts | 계정 (공통, **관리자/일반회원 2종뿐**, phone_1~3) | 1:1 admins 또는 general_accounts, 1:N addresses, 1:N account_emails |
| account_emails | 계정 이메일 (정규화, primary_yn) | N:1 accounts |
| account_login_histories | 로그인 성공/실패 이력 | N:1 accounts, N:1 common_codes(LOGIN_RESULT) |
| account_terms_agreements | 계정별 약관 동의 이력 | N:1 accounts, N:1 terms |
| admins | 관리자 상세 (department/admin_level → 공통코드) | 1:1 accounts |
| general_accounts | 일반회원 상세 (구매 기본 프로필: 등급/적립금) — **구 buyers** | 1:1 accounts, 1:1 carts, 1:N orders/reviews/wishlists/point_histories, 1:N company_members |
| companies | **[NEW] 회사** (사업자 정보, 대표자 컬럼 포함) — accounts와 비1:1, 구 sellers 대체 | N:1 general_accounts(owner), 1:N products/deliveries/settlements, 1:N company_members |
| company_grade_policies | 회사 등급별 수수료율/혜택 (초안) — 구 seller_grade_policies | N:1 common_codes(COMPANY_GRADE) |
| company_shipping_policies | 회사 배송비 정책 — 구 seller_shipping_policies | 1:1 companies |
| company_roles | **[NEW]** 회사가 자유롭게 정의하는 직책 | N:1 companies, 1:N company_role_permissions |
| company_role_permissions | **[NEW]** 직책-권한 연결 (권한 종류는 공통코드 고정) | N:1 company_roles, N:1 common_codes(COMPANY_PERMISSION) |
| company_members | **[NEW]** 계정-회사-직책 연결 (다대다 핵심, "1인 다회사" 지원) | N:1 companies, N:1 general_accounts, N:1 company_roles |
| company_owner_change_requests | **[NEW]** 회사 대표자 변경 신청/승인 절차 | N:1 companies, N:1 general_accounts(3역할), N:1 common_codes, N:1 admins(처리자) |
| addresses | 배송지 (address_name으로 별칭 저장, default_yn 최대 1개) | N:1 accounts |
| categories | 상품 카테고리 (self-ref 대/중/소) | 1:N products, self 1:N |
| products | 상품 (id=내부PK, uuid=외부 공개 식별자) | N:1 companies, N:1 categories, 1:N product_files, 1:N product_options, 1:N product_attributes |
| files | 파일 공통 테이블 (PK=UUID) | N:1 accounts(uploaded_by), 1:N product_files, 1:N banners |
| product_files | 상품-파일 연결 (thumbnail_yn로 대표이미지 표시) | N:1 products, N:1 files |
| product_attributes | 상품 스펙/속성 (소재/원산지 등, 표시 전용) | N:1 products |
| product_options | 상품 옵션 축 (예: 사이즈, 색상, 필수/선택 여부) | N:1 products, 1:N product_option_values |
| product_option_values | 옵션 값 (예: S/M/L, 판매중/품절/단종) | N:1 product_options, 1:N product_option_combination_values |
| product_option_combinations | 실 구매 단위 옵션 조합 = SKU (재고/추가금액) | N:1 products, 1:N product_option_combination_values |
| product_option_combination_values | 조합-옵션값 연결 | N:1 product_option_combinations, N:1 product_option_values |
| wishlists | 찜/위시리스트 | N:1 general_accounts, N:1 products |
| carts | 장바구니 (계정당 1개) | 1:1 general_accounts, 1:N cart_items |
| cart_items | 장바구니 항목 (옵션 조합 선택 가능) | N:1 carts, N:1 products, N:1 product_option_combinations(선택) |
| orders | 주문 (discount_amount 포함, 배송비는 deliveries에 분산, 배송지는 스냅샷 컬럼이 원본) | N:1 general_accounts, N:1 addresses(선택, 역참조용), 1:N order_items, 1:1 payments, 1:N deliveries(회사별 분리) |
| order_items | 주문 항목 (상품명+가격+옵션 스냅샷, 소속 배송 연결) | N:1 orders, N:1 products, N:1 product_option_combinations(선택), N:1 deliveries, 1:N order_claims, 1:1 settlement_items(정산 시) |
| order_claims | 취소/반품/교환/환불 신청 (항목 단위, 부분 클레임 지원, refund_amount=승인액) | N:1 order_items, N:1 common_codes(유형/사유/상태), 1:N refunds(선택) |
| point_histories | 적립금 변동 이력 (stock_histories와 동일 패턴) | N:1 general_accounts, N:1 common_codes(POINT_CHANGE_TYPE), N:1 orders(선택) |
| payments | 결제 (주문당 1건, 고객→쇼핑몰, amount는 최초 결제액 그대로 유지) | 1:1 orders, 1:N refunds |
| refunds | **[NEW]** 환불 실제 처리 이력 (payments의 짝, 원장 패턴) | N:1 payments, N:1 order_claims(선택), N:1 common_codes(환불수단/상태) |
| reviews | 리뷰 (조회수/좋아요/싫어요 포함) | N:1 products, N:1 general_accounts |
| board_posts | 게시물 (공지/FAQ/상품문의 통합, uuid 공개 식별자, secret_yn/answered_yn) | N:1 common_codes, N:1 accounts, N:1 products(선택), 1:N comments |
| comments | 댓글 (게시물/리뷰 통합, 대댓글) | N:1 board_posts 또는 N:1 reviews(배타적), self 1:N(대댓글), N:1 accounts |
| coupons | 쿠폰 정의 (공용코드/개별발급, 최소주문금액/최대할인한도, 적용범위) | 1:N account_coupons, 1:N coupon_targets |
| coupon_targets | 쿠폰 적용 대상 (카테고리/상품/회사 한정 시) | N:1 coupons, N:1 categories 또는 products 또는 companies(배타적) |
| account_coupons | 계정별 쿠폰 보유/사용 | N:1 coupons, N:1 accounts, N:1 orders(사용 시) |
| deliveries | 배송 (**회사별 1건** — 한 주문에 회사가 여럿이면 여럿) | N:1 orders, N:1 companies, 1:N order_items, 1:N delivery_status_histories |
| delivery_status_histories | 배송 상태 변경 이력 | N:1 deliveries |
| stock_histories | 재고 변동 이력 | N:1 products, N:1 product_option_combinations(선택), N:1 orders(선택) |
| settlements | 회사 정산 (기간 단위, 지급 계좌는 생성 시점 companies 계좌 스냅샷) | N:1 companies, 1:N settlement_items |
| settlement_items | 정산에 포함된 주문 항목 | N:1 settlements, 1:1 order_items |
| admin_permissions | 관리자 기능별 권한 (다대다, 전역 고정 목록) | N:1 admins, N:1 common_codes |
| admin_activity_logs | 관리자 활동 감사로그 (느슨한 대상 참조) | N:1 admins, N:1 common_codes(액션유형/대상유형) |
| reactions | 좋아요/싫어요 개별 투표 기록 | N:1 board_posts 또는 comments 또는 reviews(배타적), N:1 accounts |
| notifications | 인앱 알림 피드 (읽음여부 포함) | N:1 accounts(수신자), N:1 common_codes(유형/대상종류), target_id로 다양한 테이블을 느슨하게 참조 |
| notification_settings | 계정별 알림 유형 수신 설정 | N:1 accounts, N:1 common_codes(유형) |
| banners | 메인 배너/기획전 노출 관리 | N:1 files, N:1 common_codes(노출위치) |
| temp_bulk_import_batches | **[NEW]** 대량등록 업로드 배치 헤더 (상품/송장/재고 공용) | N:1 companies, N:1 accounts(업로더), N:1 common_codes(종류/상태) |
| temp_product_import_rows | **[NEW]** 상품 대량등록 - 엑셀 행 (검증 전 원본) | N:1 temp_bulk_import_batches, N:1 products(성공 시) |
| temp_tracking_import_rows | **[NEW]** 송장번호 대량등록 - 엑셀 행 | N:1 temp_bulk_import_batches, N:1 deliveries(성공 시) |
| temp_stock_import_rows | **[NEW]** 재고/가격 대량변경 - 엑셀 행 | N:1 temp_bulk_import_batches, N:1 stock_histories(성공 시) |

## 이번 라운드 설계 결정 (2026-08-06)
- **게시판**: `boards` 같은 별도 테이블 대신 `common_codes`(code_group='BOARD_TYPE')로 게시판 종류를 관리. 이벤트는 NOTICE 코드의 `parent_id`로 등록해 "공지의 하위 카테고리"를 재귀 구조로 표현. 게시판이 늘어나도 스키마 변경 없이 코드 추가만으로 대응 가능.
- **리뷰 통합 여부**: 리뷰는 게시물(board_posts)에 합치지 않고 별도 유지. 주문/평점에 강하게 묶여 있고 조회 패턴(상품별 평점 집계)이 게시물과 다르기 때문. 대신 view_count/like_count/dislike_count 컬럼과 댓글 연결 방식은 게시물과 동일하게 맞춰 일관성 유지.
- **댓글 통합**: `comments` 테이블 하나에 `post_id`/`review_id`를 각각 nullable FK로 두고 `CHECK (num_nonnulls(post_id, review_id) = 1)`로 정확히 하나만 채워지도록 강제 (배타적 FK). files에서 지양했던 문자열 기반 `parent_type/parent_id` 폴리모픽과 달리 실제 FK 제약이 걸려 무결성이 유지되면서도 테이블은 하나로 통합됨. `parent_id`(자기참조)로 대댓글 지원.
- **쿠폰**: `coupons`(정의) + `account_coupons`(계정별 보유/사용) 2테이블 구조. `coupons.issue_type`(SHARED_CODE/TARGETED)으로 공용 코드형과 개별 발급형을 한 테이블에서 표현하고, `account_coupons`의 `UNIQUE(coupon_id, account_id)` 제약이 "계정당 1회"를 두 방식 모두에 대해 자동으로 보장.
- **배송 추적**: `orders.status`(주문 생애주기)와 분리해 `deliveries`(현재 배송 상태) + `delivery_status_histories`(상태 변경 이력)로 분리. "추적"이라는 요구사항 자체가 이력을 의미한다고 판단해 이력 테이블까지 포함.
- **재고 이력**: 이번 라운드에서는 보류. 기존 테이블을 건드리지 않는 순수 추가 테이블이라 나중에 추가해도 지금 추가하는 것과 비용 차이가 거의 없다고 판단 — 필요해지는 시점에 다시 논의.
- **등급 컬럼**: `admins.admin_level`, `buyers.grade`는 기존에 있었고, 이번에 `sellers.grade`를 추가해 세 서브타입 모두 등급 컬럼을 갖추도록 통일. 실제 권한/혜택 로직은 추후 별도 논의.
- **공통 코드 구조**: 그룹핑 컬럼(예: group_code1/2/3)을 여러 개 두는 방식 대신 `parent_id` 자기참조 방식을 채택. 이미 `categories`에서 쓰고 있는 패턴과 일관되고, 계층 깊이에 제한이 없음.

## 2차 라운드 설계 결정 (2026-08-06)
- **PK 채번 규칙 도입**: 모든 PK를 `BIGSERIAL` → `VARCHAR(17)`("4자리 대문자 테이블코드 + 13자리 시퀀스 숫자")로 전환. 숫자는 `SEQ_<테이블명>_01` 시퀀스의 `NEXTVAL`을 `LPAD`로 0-padding해 채번. `files.id`만 예외로 UUID 유지 — 공개 URL로 직접 쓰이는 PK에 코드+순번을 쓰면 오히려 추측이 쉬워져 기존 보안 규칙과 충돌하기 때문. 상세는 [PK 채번 규칙](#pk-채번-규칙) 참고.
- **공통 코드 전면 적용**: `department`, `admin_level`, `approval_status`, `grade`, `account_type`, `status` 등 "값의 종류가 적고 이름으로 의미를 표시하는" 컬럼을 모두 `common_codes`를 참조하는 `*_code_id`로 전환. 이번 라운드에서 새로 추가한 게시판/쿠폰/배송 관련 컬럼(`issue_type`, `discount_type`, 각종 `status`, `method`)도 처음부터 이 방식으로 설계. 상세 매핑은 [공통 코드 규칙](#공통-코드-규칙) 표 참고.
- **연락처 정규화**: `accounts.phone`을 `phone_1`/`phone_2`/`phone_3` 3개 컬럼으로 확장(정규화하지 않음 — 개수가 고정적이고 적어 별도 테이블의 이점이 적다고 판단). 반대로 이메일은 개수 제한이 없고 "여러 개일 수 있다"는 요구가 명확해 `account_emails` 별도 테이블로 정규화하고, `is_primary` + 부분 유니크 인덱스(`account_id WHERE is_primary`)로 계정당 대표 이메일이 최대 1개로 유지되도록 실제 제약을 걸었다(단순 boolean 컬럼만 두는 것보다 무결성이 보장됨).

## 3차 라운드 설계 결정 (2026-08-06)
- **공통 코드 값(code) 비식별화**: 처음엔 `code`에 `'ADMIN'`, `'ACTIVE'`처럼 의미가 읽히는 문자열을 넣었으나, 이것도 PK처럼 "값만 봐서는 알 수 없게" 채번하는 것으로 정정. `code_group`별 4~5자리 대문자 접두어 + 4자리 숫자(그룹별 개별 카운트) 형태로 통일. 실제 의미는 `code_name`에만 담고, 애플리케이션도 `code` 문자열이 아니라 `*_code_id`(FK)로만 참조 — PK 채번 규칙과 동일한 이유(추측/의미 유출 방지).

## 4차 라운드 설계 결정 (2026-08-06)
- **자료형 이식성**: `BOOLEAN`, `TIMESTAMPTZ`처럼 특정 DBMS 전용 자료형을 프로젝트 전반에서 제거. `BOOLEAN`은 `CHAR(1)` `'Y'/'N'` + `CHECK`로 바꾸고 컬럼명도 기존 `del_yn` 관례에 맞춰 `*_yn`으로 통일(`is_default`→`default_yn`, `is_active`→`active_yn`, `is_primary`→`primary_yn`). `TIMESTAMPTZ`는 전부 `TIMESTAMP`로. `UUID`는 [보안 규칙](#보안-규칙-프로젝트-표준)과 직결된 예외라 그대로 유지(다른 타입으로 바꾸면 "추측 불가능한 공개 식별자"라는 목적 자체가 무너짐).
- **`common_codes.description` 추가**: `code` 값이 비식별화되면서(`ACTP0001` 등) 의미를 남겨둘 곳이 `code_name`(짧은 라벨) 하나뿐이었음. 더 상세한 설명이 필요할 수 있어 `description`(nullable) 컬럼을 별도로 추가.
- **`code_group` vs `parent_id` 역할 재확인**: 겹치는 것처럼 보일 수 있으나 "어느 분류에 속하는가"(`code_group`, 모든 행)와 "같은 분류 안에서 어떤 코드의 하위인가"(`parent_id`, 계층 있는 소수 그룹만)로 답하는 질문이 다름을 확인. `code_group`을 없애고 `parent_id` 트리(그룹=루트 노드)만으로 표현하는 대안도 검토했으나, 제일 흔한 조회인 "그룹별 목록"이 재귀 쿼리가 되어버리는 단점이 있어 현재의 이중 구조를 유지하기로 결정. 대신 자식 코드의 `code_group`이 부모와 항상 같아야 한다는 비정규화 규칙을 문서화.

## 5차 라운드 설계 결정 (2026-08-06, 야간 자율 진행)
검토 필요 사항에 남아있던 항목을 모두 이번 라운드에서 판단해 구조에 반영. 승인 없이 진행했으므로 오전에 훑어보고 방향이 다르면 알려주세요 — 특히 상품 옵션·정산·권한 세 가지는 설계 폭이 넓어 되돌리기보다 조정이 필요할 수 있습니다.

- **상품 옵션**: `product_options`(옵션 축, 예: 사이즈) + `product_option_values`(옵션 값, 예: M) + `product_option_combinations`(실제 구매 단위=SKU, 조합별 재고/추가금액) + `product_option_combination_values`(조합-값 연결) 4테이블로 구성. 옵션이 없는 상품은 이 테이블들에 행이 없고 기존 `products.price`/`stock_quantity`를 그대로 씀 — 모든 상품에 옵션 체계를 강제하지 않음. `cart_items`/`order_items`에 `option_combination_id`(nullable)를 추가하고, `order_items.option_summary`로 주문 시점 옵션 표시를 스냅샷(가격 스냅샷과 같은 이유 — 이후 옵션이 바뀌어도 과거 주문엔 영향 없게). `cart_items`의 기존 `UNIQUE(cart_id, product_id)`는 옵션까지 포함해야 해서 `COALESCE(option_combination_id, 'NONE')`을 쓰는 부분 유니크 인덱스로 교체(옵션 없는 상품도 동일하게 중복 방지).
- **재고 이력**: 보류를 풀고 `stock_histories` 추가. `product_id` + (옵션 상품이면) `option_combination_id`, 변경 사유(`STOCK_CHANGE_TYPE` 공통코드), 변경량(`quantity_delta`), 변경 후 스냅샷(`quantity_after`), 주문으로 인한 변경이면 `reference_order_id`까지 남겨 실제 "추적"이 가능하도록.
- **판매자 정산**: `settlements`(기간 단위 1건, 매출/수수료/지급액) + `settlement_items`(정산에 포함된 주문 항목 상세, `order_item_id`가 `UNIQUE`라 이중 정산 방지) 2테이블. `payments`가 "고객→쇼핑몰" 결제라면 `settlements`는 "쇼핑몰→판매자" 정산이라 역할이 다름.
- **관리자 권한 세분화**: `admins.admin_level_code_id`(SUPER/GENERAL)는 큰 구분으로 남기고, `admin_permissions`(관리자-권한코드 다대다)로 상품관리/주문관리/회원관리/정산관리/게시판관리 같은 기능 단위 권한을 별도 부여 가능하게 함. 실제 화면/API 접근 제어 로직은 여전히 애플리케이션 몫.
- **좋아요/싫어요 중복 방지**: `reactions` 테이블 추가 — `comments`와 같은 배타적 FK 패턴(`post_id`/`comment_id`/`review_id` 중 정확히 하나)에 `account_id` + `reaction_type_code_id`(LIKE/DISLIKE). 대상별로 부분 유니크 인덱스(`WHERE post_id IS NOT NULL` 등)를 걸어 계정당 반응 1개만 허용. 기존 `like_count`/`dislike_count`는 조회 성능용 집계 컬럼으로 유지하고, 애플리케이션이 `reactions` 변경에 맞춰 증감시키는 구조(트리거는 이번 단계에서 도입하지 않음).
- **FAQ 등 게시판 하위 카테고리**: 이미 `common_codes`의 재귀 구조가 게시판 종류 전반에 적용되므로 스키마 변경 불필요. `BOARD_TYPE` 그룹 안에서 FAQ(`BDTP0002`)도 NOTICE와 같은 방식으로 하위 코드(`BDTP0004` 배송문의, `BDTP0005` 결제문의 등)를 둘 수 있음 — 시드 예시에 반영.
- **쿠폰 세부 정책**: `coupons`에 `min_order_amount`(최소 주문금액), `max_discount_amount`(정률 할인 시 최대 할인 캡, nullable) 컬럼 추가.
- **로그인 식별 방식**: 대표 이메일 여부와 무관하게 계정에 등록된 아무 이메일로나 로그인 가능하도록 결정(스키마 변경 없음, `account_emails.email` UNIQUE로 이미 지원됨). 위 [계정 구조](#계정-구조-관리자판매자구매자-통합) 절에 반영.
- **`common_codes` 시드 데이터 확정**: 새로 생긴 그룹(`STOCK_CHANGE_TYPE`, `SETTLEMENT_STATUS`, `ADMIN_PERMISSION`, `REACTION_TYPE`) 포함해 전체 그룹의 시드 값을 `schema.sql` 하단에 정리(여전히 주석 처리된 예시 — 실제 DB 적용 시점에 INSERT).

## 6차 라운드 설계 결정 (2026-08-07)
- **판매자 등급별 수수료율(초안)**: `seller_grade_policies` 테이블 신설(`grade_code_id` 1:1, `commission_rate`(%), `benefit_description`). `settlements.commission_amount = total_sales_amount × (해당 등급 commission_rate / 100)`을 기본 계산식으로 문서화. 시드값은 일반 10%/우수 7% 예시로 초안만 넣어둠 — 실제 비율은 운영 정책 확정 필요.
- **관리자 권한 목록 확정(1차)**: `ADMIN_PERMISSION` 코드를 5개 → 9개로 확장(쿠폰관리/판매자관리/통계조회/권한관리 추가). 화면-권한 매핑 자체는 라우팅 성격이라 DB 테이블이 아니라 애플리케이션 라우트 설정에서 관리하는 것으로 결정(각 화면 진입 시 필요한 `ADMIN_PERMISSION` 코드를 코드 레벨에 선언).
- **옵션 상태 세분화**: 원래 "조합 전체 품절 시 상품을 자동으로 SOLD_OUT 처리할지"였던 질문을, 더 근본적으로 "옵션 자체에 상태를 부여"하는 방향으로 확장. `product_options.selection_type_code_id`(`OPTION_SELECTION_TYPE`: 필수/선택 — 이 축을 반드시 골라야 하는지, 축 단위 속성)와 `product_option_values.status_code_id`(`OPTION_VALUE_STATUS`: 판매중/품절/단종 — 이 값 자체를 고를 수 있는지, 값 단위 속성)로 분리해서 추가했다. 두 개념(필수여부/가용상태)을 하나의 컬럼에 섞지 않은 이유: "이 축은 필수인데 그중 한 값이 품절"처럼 동시에 성립해야 하는 조합이 있어, 한 컬럼으로는 표현이 안 되기 때문. `product_option_combinations.status_code_id`(기존, PRODUCT_STATUS 재사용)는 "이 조합(SKU) 자체가 판매 가능한지"로 역할이 다르게 유지됨.
  - 남은 세부 정책: 조합의 모든 값이 품절/단종이 됐을 때 상품(`products.status_code_id`) 자체를 자동으로 SOLD_OUT 전환할지는 여전히 애플리케이션 로직 몫(스키마가 막지 않음, 강제하지도 않음).

## 7차 라운드 설계 결정 (2026-08-07)
- **알림 기능 추가**: `notifications`(인앱 알림 피드) + `notification_settings`(계정별 유형별 수신 on/off) 2테이블 신설. 요청받은 3종(관리자 공지, 이벤트 당첨, 배송완료) 외에 실제 쇼핑몰에서 흔히 필요한 유형을 판단해 총 14종으로 확장 — 주문접수/결제완료, 배송시작, 취소·환불완료, 쿠폰발급, 쿠폰만료임박, 재입고, 리뷰작성요청, 댓글·대댓글, 판매자승인결과, 정산완료, 문의답변등록. `notification_type_code_id`는 `common_codes`(`NOTIFICATION_TYPE`)로 관리해 유형이 늘어나도 스키마 변경이 필요 없다.
  - **의도적 예외 — 폴리모픽 참조**: 알림이 가리키는 원본(주문/배송/쿠폰/게시물/리뷰/댓글/정산/판매자/상품 등)은 `target_type_code_id`(공통코드 FK로 "종류"는 강제) + `target_id`(실제 FK 없음)로 느슨하게 참조한다. `files`/`comments`에서 지양했던 `parent_type/parent_id` 패턴을 여기서는 예외적으로 채택했는데, 이유는: (1) 대상 종류가 계속 늘어날 수 있는 도메인이라 매번 nullable FK 컬럼을 추가하는 게 비현실적이고, (2) 알림은 원본이 삭제돼도 알림 자체(로그)는 남아있어도 무방해 DB가 항상 참조 무결성을 지켜야 할 만큼 중요한 관계가 아니기 때문. `comments`/`reactions`처럼 대상이 2~3종으로 고정된 경우와는 성격이 달라 원칙을 깨는 게 아니라 원칙이 적용되는 전제 조건(대상 종류 적음 + 무결성 중요) 자체가 다른 경우로 판단.
  - `notification_settings`은 계정×유형 조합에 행이 없으면 "수신함"(기본값)으로 간주하고 `enabled_yn='N'`인 행만 명시적으로 끈 것으로 취급 — 모든 조합을 미리 채워둘 필요가 없다.
- **`common_codes` 예비 속성 컬럼(attr_1~5) 제안 — 채택하지 않음**: 코드마다 다른 부가 데이터(수수료율 등)를 위해 범용 예비 컬럼 5개를 두자는 제안을 검토했으나, 다음 이유로 권장하지 않기로 함(EAV 안티패턴):
  - 값이 전부 텍스트/범용 타입이 될 수밖에 없어 `commission_rate`처럼 실제로는 숫자인 값도 타입·범위 체크(`CHECK BETWEEN 0 AND 100` 등)를 잃는다.
  - 같은 컬럼(`attr_3` 등)이 `code_group`마다 다른 의미로 쓰이게 되어(어떤 그룹엔 수수료율, 어떤 그룹엔 아이콘 URL) 컬럼명만 봐서는 의미를 알 수 없다 — 우리가 `code` 값을 비식별화하면서 지키려던 "의미는 이름 있는 곳에 명확히 담는다" 원칙과 반대 방향.
  - 5개라는 개수가 임의적이라, 6번째 부가 데이터가 필요해지는 순간 다시 컬럼 추가(피하려던 마이그레이션)가 필요하거나 한 컬럼에 값 두 개를 억지로 욱여넣게 된다.
  - 이미 `seller_grade_policies`처럼 "정말 부가 데이터가 필요한 그룹에만 작고 타입이 명확한 확장 테이블을 둔다"는 패턴을 쓰고 있고, 이 방식이 일관성 있게 유지하기 더 낫다고 판단. 공통코드 관리 화면을 따로 만들 계획이라면 더더욱 "수수료율(%)" 같은 제대로 된 입력 필드가 있는 게 "속성3" 같은 범용 입력창보다 관리자 입장에서도 명확함.
- **애플리케이션 로직은 ERD 밖에서**: 관리자 권한-화면 매핑, 알림 발송(이메일/푸시 등 실제 전송), 수수료 계산 실행, 옵션 품절 시 상품 상태 자동전환 같은 "동작"은 프론트엔드/백엔드 코드에서 정의하는 게 맞다는 방향에 동의. ERD/스키마는 그 동작이 딛고 설 수 있는 데이터 구조와, DB가 스스로 지킬 수 있는 무결성 제약(UNIQUE, CHECK, FK)까지만 책임진다. 지금까지 "남은 사항"으로 분류해온 항목들이 대부분 이 경계에 걸쳐 있었던 것도 같은 맥락.
- **공통 코드 관리 화면 별도 제작 예정**: `common_codes`(및 향후 관리가 필요한 데이터)를 SQL 직접 수정이 아니라 전용 관리자 페이지에서 조정할 계획 — 위 attr_1~5 미채택 판단과도 맞물림(관리 화면이 있다면 더더욱 필드별로 타입이 명확한 편이 유리).

## 8차 라운드 설계 결정 (2026-08-07) — "빠진 것/필요한 것" 리뷰 반영
사용자가 제안한 우선순위 목록(높음 1~6, 보통 7~10, 낮음 11~13)을 검토한 결과를 반영. 5번(상품문의)은 게시판 재사용 방향에 맞춰 최소 확장만, 나머지 12개는 다른 쇼핑몰(쿠팡/11번가/네이버 스마트스토어 등)의 통상적인 구조를 참고해 새로 설계.

- **상품문의(5번)**: 별도 테이블 없이 `board_posts` 재사용 확정. 다만 상품과 연결되고(`product_id`), 개인정보가 섞일 수 있어 비밀글 처리가 필요하고(`secret_yn`), 답변 여부를 목록에서 빠르게 걸러야 하는(`answered_yn`) 세 가지는 게시판 공통 스키마만으론 부족해 `board_posts`에 3컬럼을 추가. `product_id`는 공지/FAQ에서는 NULL로 두면 되므로 기존 게시판도 영향 없음.
- **배송비(1번) + 다중 판매자 배송 분리(2번)**: 두 문제가 얽혀 있어 함께 해결. `deliveries`를 `orders`와 1:1에서 **1:N**으로 바꾸고 `seller_id`를 추가해 "주문 1건, 판매자별 배송 N건" 구조로 정정. `order_items.delivery_id`로 각 항목이 어느 배송 건에 속하는지 연결. 배송비는 `seller_shipping_policies`(판매자별 기본배송비/무료배송 조건/도서산간 추가비) 기준으로 계산해 `deliveries.delivery_fee`에 스냅샷으로 남긴다 — 정책이 나중에 바뀌어도 과거 배송비는 그대로 보이도록. `orders.total_amount`의 의미도 "상품금액 합 - 할인 + 배송비 합"으로 명확히 문서화.
- **위시리스트(3번)**: `wishlists`(계정×상품, UNIQUE) 단순 추가.
- **반품/교환/환불(4번)**: `order_claims`를 `order_items` 단위로 설계해 부분 클레임(한 주문에서 일부 상품만 반품)을 지원. 유형(취소/반품/교환/단순환불), 사유, 상태(접수→승인→수거중→수거완료→처리완료/거절)를 모두 공통코드로 관리.
- **적립금 이력(6번)**: `point_histories`를 `stock_histories`와 동일한 패턴(변경사유/변경량/변경후 스냅샷)으로 추가. `buyers.points`는 여전히 현재 잔액 캐시로 유지.
- **쿠폰 적용 범위 제한(7번)**: `coupons.scope_code_id`(전체/카테고리한정/상품한정/판매자한정) + `coupon_targets`(카테고리/상품/판매자 중 정확히 하나를 가리키는 배타적 FK, `comments`/`reactions`와 같은 패턴). 대상이 3종으로 고정돼 있어 `notifications`처럼 느슨한 참조 대신 실제 FK를 걸었다.
- **상품 대표이미지(8번)**: `product_files.thumbnail_yn` + 상품당 1개로 강제하는 부분 유니크 인덱스(`account_emails.primary_yn`과 동일 패턴).
- **로그인 이력(9번)**: `account_login_histories` — 성공/실패 결과, IP, User-Agent 기록.
- **약관 동의 이력(10번)**: `terms`(버전 관리 — 개정 시 새 행을 추가하고 과거 버전은 수정하지 않음) + `account_terms_agreements`(계정×약관 동의 기록). 재동의 필요 여부 판단은 애플리케이션이 최신 버전과 비교해서 처리.
- **상품 속성/스펙(11번)**: `product_attributes`(상품 1:N, key-value 형태의 소재/원산지/제조사 등). `product_options`와 달리 구매자가 "선택"하지 않고 그냥 "표시"만 되는 정보라 재고/가격에 영향이 없다 — 이건 `common_codes` attr_1~5를 거부했던 것과 모순처럼 보일 수 있어 짚어둔다: 여기 값들은 애초에 비즈니스 로직이 값을 보고 분기하지 않는 순수 표시용 데이터라 타입 안전성을 잃을 게 없고, EAV 문제(같은 컬럼이 그룹마다 다른 의미)도 발생하지 않는다.
- **배너/기획전(12번)**: `banners`(이미지, 링크, 노출 위치/기간, 활성 여부).
- **관리자 감사로그(13번)**: `admin_activity_logs` — `notifications`와 같은 이유로 `target_id`를 느슨하게 참조(로그 대상이 계정/상품/주문/쿠폰/공통코드 등으로 매우 다양하고, 로그는 원본이 바뀌어도 기록 자체가 남아야 하므로).
- 테이블 수 35 → **46개**(시퀀스 42개)로 증가.

## 9차 라운드 설계 결정 (2026-08-07) — 계정/회사 구조 개편 + 대량등록
사용자가 "판매자를 계정 종류가 아니라 일반계정의 자격으로, 회사를 여러 계정이 소속되는 실제 그룹으로 만들자"고 제안한 것을 계기로 계정 모델을 근본적으로 다시 짬. 여러 차례에 걸쳐 세부사항(직책/권한, 1인 다회사, 대표자 변경 절차)을 확정한 뒤 한 번에 반영.

- **계정 2분할**: `ACCOUNT_TYPE`을 ADMIN/SELLER/BUYER 3종에서 **ADMIN/GENERAL 2종**으로 축소. `buyers` 테이블은 `general_accounts`로 이름을 바꿔 "일반 계정의 기본(구매) 프로필"이라는 의미를 명확히 했다. "판매자"는 계정의 속성이 아니라 `company_members`를 통해 얻는 자격이 됐다.
- **회사(companies) 신설**: 기존 `sellers`(accounts와 1:1)를 폐기하고 `companies`를 신설 — 사업자 정보를 담되 특정 계정에 종속되지 않는다. `company_members`(계정-회사-직책 다대다)로 여러 계정이 한 회사에 소속되거나, 한 계정이 여러 회사에 소속될 수 있다 — 후자("1인 다회사")는 다대다 구조 자체에서 자연히 따라오는 결과라 별도 설계 요소가 필요 없었다.
- **회사별 직책/권한**: `company_roles`(회사가 자유롭게 정의하는 직책 이름) + `company_role_permissions`(직책-권한 연결). 권한의 "종류"(상품관리/정산조회 등)는 `COMPANY_PERMISSION` 공통코드로 시스템에 고정하고, 직책 "이름"과 "어떤 권한을 묶을지"만 회사 재량으로 둔 것이 핵심 — 이래야 코드가 권한을 검증할 근거(고정된 종류)를 유지하면서도 회사마다 다른 조직도를 표현할 수 있다.
- **대표자 컬럼 + 변경 절차**: `companies.owner_account_id`로 대표자를 직책 체계와 독립적으로 명시. 직접 `UPDATE`를 허용하지 않고 `company_owner_change_requests`(접수→검토중→승인/반려, 관리자가 처리) 절차를 거치도록 의도적으로 번거롭게 만들었다 — 사업자 명의 변경은 분쟁 소지가 있는 민감한 액션이라 사유·처리 이력을 남기는 게 낫다고 판단.
- **연쇄 리네임**: `seller_id`를 참조하던 모든 컬럼(`products`, `deliveries`, `settlements`, `coupon_targets`)이 `company_id` → `companies(id)`로 바뀜. `SELLER_GRADE`/`SELLER_APPROVAL_STATUS`/`BUYER_GRADE` 공통코드 그룹도 각각 `COMPANY_GRADE`/`COMPANY_APPROVAL_STATUS`/`GENERAL_GRADE`로 개명.
- **대량등록(엑셀) 스테이징**: 상품등록/송장번호등록/재고·가격변경 3종을 우선 구현(카테고리 일괄등록·직원 일괄초대는 제외). `temp_bulk_import_batches`(배치 헤더, 3종 공용) + 종류별 `temp_*_import_rows`(엑셀 원본, 검증 전이라 가격 등도 문자열로 보관) 구조. 배치 헤더를 공용으로 두고 상세 행만 종류별로 나눈 이유는, 종류마다 필요한 컬럼이 완전히 달라서(상품은 이름/가격, 송장은 주문번호/운송장번호) 한 테이블에 억지로 담으면 `attr_1~5`를 거부했을 때와 같은 EAV 문제가 재발하기 때문.
  - **테이블명 `temp_` 접두어**: 스테이징 테이블임을 이름으로 표시. 취소 시 상세 행은 실제 `DELETE`로 제거(소프트 삭제 관행의 예외)하고, 배치 헤더만 상태를 '취소됨'으로 바꿔 가볍게 남긴다. 하루 넘게 방치된 배치를 정리하는 것도 같은 방식 — 이 "정리 동작" 자체는 스케줄러/백엔드 코드가 담당하고, 스키마는 상태값과 `ON DELETE CASCADE`까지만 준비해둔다.
- 테이블 수 46 → **54개**(시퀀스 51개)로 증가.

## 10차 라운드 — 1차 완성 (남은 운영 정책 전부 임의 확정, 2026-08-07)
"남은 것들 옳다고 생각하는 대로 임의로 설정하고 1차 완성으로 보여달라"는 요청에 따라, 그동안 "남은 사항"으로 미뤄뒀던 항목을 전부 판단해서 채웠다. **전부 검토용 1차 추정치**이며 실제 서비스 오픈 전 재검토가 필요하다 — 스키마 구조 변경은 거의 없고 대부분 값/규칙 결정이라 `schema.sql` 하단 주석과 각 컬럼 코멘트에 "1차" 표시로 남겨뒀다.

- **회사 등급 수수료율**: 일반 10% / 우수 7% 그대로 확정(1차).
- **옵션 전량 품절 시 상품 자동전환**: **한다.** 옵션 조합이 전부 품절/단종이면 앱이 `products.status_code_id`를 자동으로 SOLD_OUT 전환, 하나라도 판매중이면 ON_SALE 유지.
- **회사 배송비 기본값**: `company_shipping_policies`의 컬럼 `DEFAULT`를 기본배송비 3,000원 / 무료배송 기준 30,000원 / 도서산간 추가 3,000원으로 설정 — 새 회사는 이 값으로 시작하고 개별 조정 가능.
- **클레임 처리 SLA/배송비 부담**: 귀책 원칙 적용 — 단순변심은 구매자 부담(접수 후 3일 내 수거), 불량·오배송·배송지연은 회사 부담(접수 후 2일 내 처리 시작). 전체 처리 완료 목표 7일. `CLAIM_REASON` 각 코드의 `description`에 부담 주체를 명시(기존 `description` 컬럼 활용 — 새 컬럼 불필요).
- **적립금 정책**: 적립률 구매확정액의 1%, 적립일로부터 365일 후 소멸. 상수 2개뿐이라 별도 테이블 없이 애플리케이션 설정값으로 관리(스키마에 새 테이블을 만들면 오히려 과함).
- **알림 발송 채널/재시도**: 인앱(`notifications`) 항상 생성 + 이메일 병행, 실패 시 지수 백오프 3회 재시도 후 종결. 인앱 알림 자체는 이미 저장돼 있어 발송 실패와 무관하게 유실 없음.
- **`COMPANY_PERMISSION` 목록**: 현재 6종(상품/주문/정산조회/직원관리/배송/회사정보관리) 그대로 확정.
- **대량등록 만료 기준**: 업로드됨/검증중 상태로 **24시간** 경과 시 일간 배치가 만료 처리.
- **대량등록 엑셀 템플릿**: 상품등록(상품명·카테고리명·가격·재고수량·상품설명, 앞 4개 필수) / 송장등록(주문번호·택배사·운송장번호, 전부 필수) / 재고·가격변경(상품식별자·옵션식별자(선택)·변경재고수량·변경가격(선택)) 컬럼 순서로 확정.
- **`common_codes` 시드 문구**: 지금까지의 초안 문구를 1차 최종으로 확정(전체 목록은 `schema.sql` 하단). 실제 DB 미적용 상태이므로 화면 설계 단계에서 세부 워딩은 언제든 조정 가능.

## 11차 라운드 — 배송지 별칭 (2026-08-07)
계정에 귀속된 저장 주소를 이메일처럼 "자주 쓰는 주소"로 불러다 쓸 수 있게 해달라는 요청. `addresses`가 이미 `account_id` FK + `default_yn`(기본 배송지 표시)로 사실상 계정별 주소록 구조였어서, 별도 테이블 신설 없이 컬럼 하나만 추가했다.

- **`addresses.address_name`** `VARCHAR(50)`, nullable — "우리집", "사무실"처럼 계정이 직접 붙이는 주소 별칭. 필수로 강제하지 않음(안 붙이면 그냥 목록에서 주소 텍스트로 구분).
- **`ux_addresses_default` 부분 유니크 인덱스 추가**: `account_id` 기준 `default_yn = 'Y'`는 최대 1개만 허용 — `account_emails.primary_yn`과 동일 패턴인데 이전 라운드에서 문서에는 있었지만 실제 인덱스가 빠져있던 걸 이번에 같이 채웠다.

## 12차 라운드 — 주문 배송지 스냅샷 버그 수정 (2026-08-07)
사용자가 `orders.address_id`가 `addresses`(계정 귀속, 언제든 수정/삭제 가능)를 살아있는 FK로 참조하고 있다는 걸 지적 — 주문 이후 계정이 그 저장 주소를 수정하면 이미 지나간 주문의 배송지까지 같이 바뀌어 보이는 버그였다. `order_items`가 이미 `price`/`option_summary`를 스냅샷으로 떼어 놓은 것과 같은 이유로, 주문의 배송지도 주문 시점 값을 그대로 복사해 고정해야 한다.

- **`orders`에 스냅샷 컬럼 추가**: `recipient_name`/`phone`/`zip_code`/`address1`/`address2` (전부 `addresses`와 동일한 형태) — 주문 생성 시점에 값을 그대로 복사해 저장하고, 이후 원본 `addresses` 행이 수정/삭제돼도 절대 바뀌지 않음. 실제 배송에 쓰이는 원본은 이 컬럼들.
- **`orders.address_id`를 `NOT NULL` → nullable로 변경**, `ON DELETE SET NULL` 추가 — 이제 이 컬럼은 "어떤 저장 주소에서 복사해왔는지"를 가리키는 참고용 역참조일 뿐, 배송지의 원본이 아니다. 계정이 주소록에 저장하지 않고 1회성으로 입력한 주소로 주문하면 `address_id`는 `NULL`, 스냅샷 컬럼만 채워진다.
- 새 테이블 없음, 기존 `order_items` 스냅샷 패턴을 `orders`에도 동일하게 적용한 것뿐.

## 13차 라운드 — 환불 테이블 신설 + 유사 스냅샷 누락 점검 (2026-08-07)
사용자가 "payment로 매출을 확인할 수 있을 것 같은데, refund 테이블을 따로 둬야 정확한 데이터를 가질 수 있지 않겠냐"고 제안 — 동의하고 반영. 이어서 "아까(12차) 말한 것(살아있는 FK로만 참조하는 것)과 비슷한 사례가 더 있는지 확인해서 같이 반영해달라"고 요청받아 스키마 전체를 훑어 2건을 추가로 발견/수정했다.

- **`refunds` 테이블 신설**: `payments`의 짝이 되는 원장(ledger) 테이블 — `point_histories`/`stock_histories`와 같은 패턴. `payment_id`(FK 필수, 매출 계산의 직접 경로) + `order_claim_id`(FK nullable — 클레임 없이 CS가 임의로 처리하는 환불도 지원) + `method_code_id`/`status_code_id`(공통코드) + `amount` + 요청·처리일시. `order_claims.refund_amount`는 "승인 시점 결정액"으로 역할을 그대로 두고, `refunds`가 "실제 처리 내역"을 담당 — 부분환불/재시도/실패를 표현하려면 승인 결정과 실제 처리가 분리돼 있어야 하기 때문. 순매출 계산 공식: `SUM(payments.amount) - SUM(refunds.amount WHERE 완료)`.
- **[유사 사례 1] `order_items.product_name` 스냅샷 추가**: 기존에 `price`/`option_summary`는 주문 시점 스냅샷인데 상품명은 `product_id` FK로 `products.name`을 살아있게 참조하고 있었다 — 회사가 이후 상품명을 바꾸면 지나간 주문 내역의 표시명도 같이 바뀌는 동일한 유형의 문제라 스냅샷 컬럼을 추가했다.
- **[유사 사례 2] `settlements`에 `bank_name`/`bank_account_no` 스냅샷 추가**: 정산 지급 계좌 정보를 `companies.bank_account_no`에서 매번 실시간으로 가져오고 있었다 — 정산 완료 후 회사가 계좌를 바꾸면 "그때 실제로 어느 계좌로 지급했는지" 기록이 사라지는 회계 감사 리스크라 정산 생성 시점 스냅샷 컬럼을 추가했다.
- 검토했지만 문제없다고 판단해 그대로 둔 것들: `orders.discount_amount`(이미 스칼라 스냅샷), `deliveries.delivery_fee`(이미 스냅샷), `notifications`/`admin_activity_logs`의 target_id 느슨한 참조(의도된 예외, 로그 성격이라 무결성보다 유연성이 중요), `carts`/`cart_items`/`wishlists`(현재 상태를 보여줘야 하는 게 맞는 라이브 데이터라 스냅샷 대상 아님).
- 테이블 수 54 → **55개**(시퀀스 52개)로 증가. 새 공통코드 그룹 `REFUND_METHOD`/`REFUND_STATUS` 시드 예시 추가.

## 14차 라운드 — 소프트 삭제와 UNIQUE 제약의 충돌 일괄 수정 (2026-08-10)
장바구니 기능을 만들다가 실제로 터진 버그에서 출발했다. 장바구니에서 상품을 뺀 뒤(`del_yn='Y'`) 같은 상품을 다시 담으면 `ux_cart_items_product_option` 위반으로 500이 났다.

**원인(구조적 문제)**: 이 프로젝트는 전 테이블에서 물리 삭제 대신 `del_yn` 소프트 삭제를 쓰는데, 지금까지 만든 UNIQUE 제약/인덱스는 `del_yn`을 전혀 고려하지 않았다. 그래서 **소프트 삭제된 행이 UNIQUE 슬롯을 영구히 점유**하고, "지웠다가 다시 추가"가 불가능해진다. 장바구니뿐 아니라 같은 유형의 제약 전부가 동일한 잠재 버그였다 — 12·13차 때의 "스냅샷 누락"과 같은 성격의, 한 곳에서 발견하면 전체를 훑어야 하는 문제.

- **부분 유니크 인덱스로 교체(17건)**: `WHERE del_yn = 'N'`을 붙여 "활성 행 중에서만 유일"이라는 원래 의도를 정확히 표현하도록 바꿨다. 대상 — 장바구니 항목/장바구니, 이메일(값·대표), 기본 배송지, 상품 이미지(연결·대표), 좋아요/싫어요 3종, 찜, 회사 직원, 회사 직책, 직책 권한, 관리자 권한, 회사 등급/배송 정책, 옵션조합-옵션값, 알림 설정.
- **일부러 그대로 둔 것(엄격 유지)**: `orders.order_number`, `products.uuid`, `board_posts.uuid`, `coupons.code`(재사용되면 안 되는 식별자), `payments.order_id`, `deliveries(order_id, company_id)`(지나간 거래·배송 기록), `settlements(회사,기간)`, `settlement_items.order_item_id`(이중 정산 방지), `account_coupons(coupon_id, account_id)`(**"계정당 1회"가 규칙 자체라, 소프트 삭제로 재발급이 뚫리면 악용됨**), `account_terms_agreements`(법적 동의 기록), `common_codes(code_group, code)`·`terms(type, version)`(영구 식별자), `companies.business_reg_no`(실제 사업자 식별값).
- **적용/검증**: Flyway `V3__soft_delete_aware_unique_indexes.sql`로 기존 DB에 적용하고, `schema.sql`(신규 설치용 원본)도 같은 내용으로 갱신했다. 두 경로가 어긋나지 않았는지 확인하려고 **빈 DB에 `schema.sql`을 통째로 적용해 실제 운영 DB와 UNIQUE 인덱스 목록을 비교** — Flyway 자체 테이블(`flyway_schema_history`)을 빼면 완전히 동일함을 확인했다.

## 참고
- DB 연결: `jdbc:postgresql://127.0.0.1:5432/shopping_mall` (VM Postgres, 포트포워딩 완료)
