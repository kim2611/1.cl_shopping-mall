-- ============================================================
-- 1.shopping-mall ERD 1차 완성판 (DDL Data Source 용)
-- 실제 DB에는 아직 적용하지 않은 draft 입니다. 남아있던 운영 정책 항목은 10차 라운드에서
-- 전부 임의로 확정해 채워넣었다 - 실제 서비스 오픈 전 재검토 필요(각 항목에 "1차" 표시).
-- IntelliJ Ultimate: Database 툴 > + > Data Source > DDL Data Source 로
-- 이 파일을 지정해서 시각화(Show Visualization)해보세요.
--
-- [공통 규칙] 모든 테이블 공통:
--   - PK 필수
--   - 공통 컬럼 5종 필수: del_yn(삭제여부), created_by(최초작성자),
--     created_at(최초작성일), updated_by(최종수정자), updated_at(최종수정일)
--   - 예외: 테이블명이 "temp_"로 시작하는 임시(스테이징) 테이블은 컬럼 구성은 동일하게 갖추되,
--     del_yn을 통한 소프트 삭제 대신 실제 DELETE로 정리한다 (취소 시 상세행 삭제, 일간 배치로 방치된
--     행 정리). 업로드 자체를 나타내는 배치 헤더 테이블(temp_bulk_import_batches)만은 가벼운 이력
--     차원에서 행을 남기고 상태만 취소/만료로 바꾼다.
--
-- [PK 규칙] 모든 PK는 "4자리 대문자 테이블 코드 + 13자리 숫자" (총 17자, VARCHAR(17))를 사용한다.
-- 숫자 부분은 'SEQ_' + 테이블명(대문자) + '_01' 이름의 시퀀스를 NEXTVAL로 1씩 증가시켜 채번하고
-- LPAD로 13자리 0-padding한다. 한 테이블에 시퀀스가 여러 개 필요해지면 01, 02, 03...으로 확장한다.
-- 예) accounts.id 기본값 = 'ACCT' || LPAD(NEXTVAL('SEQ_ACCOUNTS_01')::TEXT, 13, '0')
-- 서브타입 테이블(admins/general_accounts)의 PK는 accounts.id 값을 그대로 복사해 쓰는 FK 겸 PK이므로
-- 별도 시퀀스를 두지 않는다.
-- 주의: 이 PK는 내부 조인/식별용이며 URL 등 클라이언트에 직접 노출하지 않는다 — 접두 테이블코드 +
-- 순증가 숫자 조합이라 오히려 순차 정수 PK보다도 값을 추측/유추하기 쉽다. 외부 노출용 식별자는
-- 기존과 동일하게 products.uuid / board_posts.uuid / files.id(자체가 UUID)를 사용한다.
--
-- [공통 코드 규칙] 값의 종류가 적고 의미를 이름으로 표시해야 하는 분류/상태성 컬럼
-- (계정유형, 각종 상태, 등급, 부서, 결제수단, 게시판종류 등)은 CHECK로 하드코딩된 varchar 대신
-- common_codes를 참조하는 "*_code_id" 컬럼으로 관리한다.
-- 예) admins.department(X) -> admins.department_code_id -> common_codes(code_group='DEPARTMENT')
-- common_codes 자체는 재귀(parent_id) 방식으로 계층을 표현한다 — 고정 개수의 그룹핑 컬럼
-- (group1/group2..)보다 깊이 제한이 없고, 이미 categories에서 쓰던 self-ref 패턴과 일관된다.
--
-- [코드 값(common_codes.code) 규칙] code 컬럼 값 자체도 'ADMIN', 'ACTIVE'처럼 의미가 읽히는
-- 문자열을 쓰지 않는다. code_group을 나타내는 "4~5자리 대문자 접두어 + 4자리 숫자"(예: DEPR0001)
-- 형태로, 값만 봐서는 무엇인지 알 수 없게 채번한다. 접두어는 code_group별로 하나씩 정하고,
-- 숫자는 그 접두어 안에서 0001부터 순서대로 부여한다(그룹마다 별도 카운트, 전역 시퀀스 아님).
-- 화면에 보여줄 실제 의미는 항상 code_name에만 담는다 — code는 순수 식별자, code_name이 라벨.
-- 예) ACCOUNT_TYPE 그룹: code_name='관리자'인 행의 code='ACTP0001' (ADMIN이라고 쓰지 않음)
-- 애플리케이션에서도 code 문자열을 파싱/비교해 분기하지 않고, FK인 *_code_id(=common_codes.id)
-- 로만 참조한다 — 위 [PK 규칙]과 같은 이유로, 값 자체에서 의미가 드러나지 않게 하기 위함이다.
--
-- [계정 구조] 계정은 딱 두 종류(ACCOUNT_TYPE: ADMIN/GENERAL)로만 나눈다. '판매자'는 더 이상
-- 계정의 종류가 아니라 일반 계정(general_accounts)이 추가로 가질 수 있는 "자격"이다 - 아래
-- [회사 구조]를 통해 표현한다. 관리자 상세는 admins에, 일반 계정 상세(구매 관련 기본 프로필:
-- 등급/적립금)는 general_accounts에 분리 보관한다.
-- (account_id가 각 서브타입 테이블의 PK이자 accounts.id를 참조하는 FK)
--
-- [회사 구조] "회사(companies)"는 사업자 단위이며, accounts와 1:1이 아니다. 한 회사에 여러 일반
-- 계정이 소속(company_members)될 수 있고, 한 계정이 여러 회사에 동시에 소속될 수도 있다(다대다) -
-- "1명이 여러 회사를 운영"하는 경우가 이 구조에서 자연히 성립한다.
--   - companies: 사업자 정보 (상호명/사업자번호/정산계좌/승인상태/등급/대표자)
--   - company_roles: 회사가 자유롭게 정의하는 직책 이름 (예: '대표', 'MD', '배송담당') - 회사마다 다름
--   - company_role_permissions: 직책이 가지는 권한 (권한 "종류" 자체는 COMPANY_PERMISSION
--     공통코드로 시스템에 고정 - 회사가 마음대로 새 권한 종류를 만들 수는 없음, 직책 이름만 자유)
--   - company_members: 계정-회사-직책 연결 (다대다 핵심)
--   - companies.owner_account_id: 대표자를 별도 컬럼으로 명시 - 직책 체계가 잘못 구성돼도(예: 특정
--     권한 가진 사람이 아무도 없어짐) 회사의 최종 책임자를 시스템이 항상 확실히 알 수 있도록 함.
--     변경은 가능하지만 직접 UPDATE를 허용하지 않고 company_owner_change_requests 승인 절차를
--     거치도록 애플리케이션에서 강제한다(의도적으로 번거롭게).
--
-- [계정 연락처] 전화번호는 별도 테이블로 정규화하지 않고 accounts.phone_1/phone_2/phone_3로
-- 최대 3개까지 보관한다(대표/부기 구분 없이 단순 다건). 이메일은 계정당 여러 개일 수 있어
-- account_emails로 정규화하고, primary_yn 컬럼 + 부분 유니크 인덱스로 계정당 대표 이메일이
-- 정확히 1개(또는 0개)로 유지되도록 강제한다.
--
-- [보안 규칙] 클라이언트(URL/API 응답)에 직접 노출되는 리소스는 내부 PK 대신 UUID를 공개
-- 식별자로 사용 (IDOR/BOLA 대비, OWASP 권고 - 단, 이는 defense-in-depth일 뿐 매 요청의
-- 소유권/인가 검증을 대체하지 않음).
-- 파일은 files 공통 테이블에서 관리하고, 각 엔티티는 전용 연결 테이블
-- (product_files 등)로 참조 - parent_type/parent_id 폴리모픽 방식은
-- FK 무결성이 약해지므로 지양 (단, notifications/admin_activity_logs는 대상 종류가 계속 늘어나고
-- 무결성이 덜 중요한 로그 성격이라 예외적으로 이 방식을 쓴다 - 각 테이블 주석 참고).
-- 파일은 files 공통 테이블에서 관리하고, 각 엔티티는 전용 연결 테이블
-- (product_files 등)로 참조.
--
-- [자료형 규칙] 특정 DBMS 전용 자료형은 가급적 자제한다 (Oracle/MySQL/MSSQL 등으로 옮길 때
-- 그대로 못 쓰는 것들).
--   - BOOLEAN(X) -> CHAR(1) 'Y'/'N' + CHECK, 컬럼명도 del_yn과 동일하게 "*_yn" 접미사로 통일.
--     (예: is_default -> default_yn, is_active -> active_yn, is_primary -> primary_yn)
--   - TIMESTAMPTZ(X) -> TIMESTAMP (타임존 정보 없이 저장, 필요하면 애플리케이션에서 UTC로 통일)
--   - UUID는 예외로 유지한다 — products.uuid/board_posts.uuid/files.id는 [보안 규칙]상
--     추측 불가능한 외부 공개 식별자여야 해서 자료형을 바꾸면 그 목적 자체가 흔들린다.
--     다른 DBMS로 옮길 때는 CHAR(36) 문자열 저장 + 애플리케이션/다른 확장에서 채번하는 방식으로
--     대체 가능 (지금 단계에서는 미적용, 필요해지면 별도 논의).
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto; -- gen_random_uuid() 사용

-- ------------------------------------------------------------
-- PK 채번용 시퀀스 (files는 UUID PK 유지 - 시퀀스 불필요)
-- admins/general_accounts는 accounts.id를 그대로 쓰므로 시퀀스 불필요
-- ------------------------------------------------------------
CREATE SEQUENCE IF NOT EXISTS SEQ_COMMON_CODES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_TERMS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ACCOUNTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ACCOUNT_EMAILS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ACCOUNT_LOGIN_HISTORIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ACCOUNT_TERMS_AGREEMENTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COMPANIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COMPANY_GRADE_POLICIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COMPANY_SHIPPING_POLICIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COMPANY_ROLES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COMPANY_ROLE_PERMISSIONS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COMPANY_MEMBERS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COMPANY_OWNER_CHANGE_REQUESTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ADDRESSES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_CATEGORIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_PRODUCTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_PRODUCT_FILES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_PRODUCT_OPTIONS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_PRODUCT_OPTION_VALUES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_PRODUCT_OPTION_COMBINATIONS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_PRODUCT_OPTION_COMBINATION_VALUES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_PRODUCT_ATTRIBUTES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_WISHLISTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_CARTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_CART_ITEMS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ORDERS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ORDER_ITEMS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ORDER_CLAIMS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_POINT_HISTORIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_PAYMENTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_REFUNDS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_REVIEWS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_BOARD_POSTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COMMENTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COUPONS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_COUPON_TARGETS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ACCOUNT_COUPONS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_DELIVERIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_DELIVERY_STATUS_HISTORIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_STOCK_HISTORIES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_SETTLEMENTS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_SETTLEMENT_ITEMS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ADMIN_PERMISSIONS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_REACTIONS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_NOTIFICATIONS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_NOTIFICATION_SETTINGS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_BANNERS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_ADMIN_ACTIVITY_LOGS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_TEMP_BULK_IMPORT_BATCHES_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_TEMP_PRODUCT_IMPORT_ROWS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_TEMP_TRACKING_IMPORT_ROWS_01;
CREATE SEQUENCE IF NOT EXISTS SEQ_TEMP_STOCK_IMPORT_ROWS_01;

-- 공통 코드 - 계정유형/상태/등급/부서/결제수단/게시판종류 등 분류성 값을 한 곳에서 관리.
-- parent_id 재귀로 "같은 그룹 안에서의 상하위 관계"를 표현 (예: BOARD_TYPE 그룹의 EVENT 코드가
-- NOTICE 코드의 하위로 등록). code_group과 parent_id는 서로 다른 질문에 답하므로 역할이 겹치지
-- 않는다:
--   - code_group: "이 코드가 어느 분류에 속하는가" (모든 행에 필수, 평평한 태그, 단순 WHERE 조회용)
--   - parent_id : "이 코드가 같은 분류 안에서 어떤 코드의 하위인가" (대부분 NULL, 계층이 실제로
--                 존재하는 극소수 그룹에서만 사용)
-- 주의(비정규화): 자식 코드의 code_group은 parent 행의 code_group과 항상 같아야 한다 — DB가
-- 자동으로 강제하지는 않으므로 시드/입력 시점에 지켜야 하는 애플리케이션 규칙이다.
CREATE TABLE common_codes (
    id          VARCHAR(17)  PRIMARY KEY DEFAULT ('CCOD' || LPAD(NEXTVAL('SEQ_COMMON_CODES_01')::TEXT, 13, '0')),
    parent_id   VARCHAR(17)  REFERENCES common_codes(id) ON DELETE CASCADE, -- 같은 code_group 내 상위 코드 (계층이 없으면 NULL)
    code_group  VARCHAR(50)  NOT NULL, -- 같은 분류를 묶는 키 (예: BOARD_TYPE, ACCOUNT_STATUS)
    code        VARCHAR(50)  NOT NULL, -- 코드 값. "접두어(4~5자리 대문자)+4자리 숫자"로 채번 (예: BDTP0001) — ADMIN/ACTIVE처럼 의미가 읽히는 문자열 금지
    code_name   VARCHAR(100) NOT NULL, -- 화면 표시명 (짧은 라벨, 예: '공지사항')
    description VARCHAR(500), -- code_name보다 상세한 설명. code 자체가 무의미한 값이라 의미를 남겨둘 곳이 필요해서 추가
    sort_order  INTEGER      NOT NULL DEFAULT 0,
    active_yn   CHAR(1)      NOT NULL DEFAULT 'Y' CHECK (active_yn IN ('Y','N')),

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP,
    UNIQUE (code_group, code)
);

-- 약관 (버전 관리). 약관이 개정되면 새 버전을 새 행으로 추가 - 기존 행은 과거 버전 기록으로 남긴다(수정하지 않음).
CREATE TABLE terms (
    id             VARCHAR(17)  PRIMARY KEY DEFAULT ('TERM' || LPAD(NEXTVAL('SEQ_TERMS_01')::TEXT, 13, '0')),
    type_code_id   VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='TERMS_TYPE' (이용약관/개인정보처리방침/마케팅수신동의 등)
    version        VARCHAR(20)  NOT NULL, -- 예: '2026.08.07'
    title          VARCHAR(200) NOT NULL,
    content        TEXT         NOT NULL,
    required_yn    CHAR(1)      NOT NULL DEFAULT 'Y' CHECK (required_yn IN ('Y','N')), -- 필수/선택 동의
    effective_at   TIMESTAMP    NOT NULL,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP,
    UNIQUE (type_code_id, version)
);

-- 계정 (공통) - 관리자/일반회원 두 종류만 존재. 이메일은 account_emails로 정규화되어 이 테이블에는 없음.
CREATE TABLE accounts (
    id                    VARCHAR(17) PRIMARY KEY DEFAULT ('ACCT' || LPAD(NEXTVAL('SEQ_ACCOUNTS_01')::TEXT, 13, '0')),
    password              VARCHAR(255) NOT NULL,
    name                  VARCHAR(50)  NOT NULL,
    phone_1               VARCHAR(20),
    phone_2               VARCHAR(20),
    phone_3               VARCHAR(20),
    account_type_code_id  VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='ACCOUNT_TYPE' (ADMIN/GENERAL)
    status_code_id        VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='ACCOUNT_STATUS' (ACTIVE/SUSPENDED/WITHDRAWN)

    del_yn        CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by    VARCHAR(50)  NOT NULL,
    created_at    TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by    VARCHAR(50),
    updated_at    TIMESTAMP
);

-- 계정 이메일 (정규화) - 계정당 여러 개 가능, primary_yn으로 대표 이메일 표시
CREATE TABLE account_emails (
    id          VARCHAR(17)  PRIMARY KEY DEFAULT ('EMAL' || LPAD(NEXTVAL('SEQ_ACCOUNT_EMAILS_01')::TEXT, 13, '0')),
    account_id  VARCHAR(17)  NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    email       VARCHAR(100) NOT NULL, -- 유일성은 아래 ux_account_emails_email 부분 인덱스로 (소프트 삭제 고려)
    primary_yn  CHAR(1)      NOT NULL DEFAULT 'N' CHECK (primary_yn IN ('Y','N')),

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);
CREATE UNIQUE INDEX ux_account_emails_email ON account_emails (email) WHERE del_yn = 'N';
-- 계정당 대표 이메일은 최대 1개로 강제 (부분 유니크 인덱스)
CREATE UNIQUE INDEX ux_account_emails_primary ON account_emails(account_id) WHERE primary_yn = 'Y' AND del_yn = 'N';

-- 로그인 시도 이력 (보안 로그) - 성공/실패 모두 기록
CREATE TABLE account_login_histories (
    id                    VARCHAR(17)  PRIMARY KEY DEFAULT ('LGHS' || LPAD(NEXTVAL('SEQ_ACCOUNT_LOGIN_HISTORIES_01')::TEXT, 13, '0')),
    account_id            VARCHAR(17)  NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    login_result_code_id  VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='LOGIN_RESULT' (성공/실패-비밀번호오류/실패-잠김 등)
    ip_address            VARCHAR(45), -- IPv6 대응
    user_agent            VARCHAR(300),
    logged_in_at           TIMESTAMP   NOT NULL DEFAULT now(),

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 계정별 약관 동의 이력. 약관이 개정(새 버전)되면 재동의 필요 여부는 애플리케이션이 version 비교로 판단.
CREATE TABLE account_terms_agreements (
    id          VARCHAR(17) PRIMARY KEY DEFAULT ('TAGR' || LPAD(NEXTVAL('SEQ_ACCOUNT_TERMS_AGREEMENTS_01')::TEXT, 13, '0')),
    account_id  VARCHAR(17) NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    terms_id    VARCHAR(17) NOT NULL REFERENCES terms(id),
    agreed_yn   CHAR(1)     NOT NULL DEFAULT 'Y' CHECK (agreed_yn IN ('Y','N')), -- 선택 약관을 거부한 경우도 기록으로 남기기 위해 'N' 허용
    agreed_at   TIMESTAMP   NOT NULL DEFAULT now(),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP,
    UNIQUE (account_id, terms_id)
);

-- 관리자 상세 (accounts.account_type_code_id = 'ADMIN')
CREATE TABLE admins (
    account_id            VARCHAR(17) PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    department_code_id    VARCHAR(17) REFERENCES common_codes(id), -- code_group='DEPARTMENT'
    admin_level_code_id   VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='ADMIN_LEVEL' (SUPER/GENERAL)

    del_yn       CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by   VARCHAR(50) NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT now(),
    updated_by   VARCHAR(50),
    updated_at   TIMESTAMP
);

-- 일반 계정 상세 (accounts.account_type_code_id = 'GENERAL'). 구매 관련 기본 프로필(등급/적립금)이며,
-- 회사 소속(company_members)을 통해 판매자 역할도 추가로 가질 수 있다 - "판매자"는 계정 종류가 아니라
-- 이 프로필 위에 얹히는 자격이라는 게 이번 개편의 핵심.
CREATE TABLE general_accounts (
    account_id     VARCHAR(17) PRIMARY KEY REFERENCES accounts(id) ON DELETE CASCADE,
    grade_code_id  VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='GENERAL_GRADE' (일반/실버/골드/VIP 등)
    points         INTEGER     NOT NULL DEFAULT 0 CHECK (points >= 0),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 회사 (사업자 단위). accounts와 1:1이 아니며, company_members를 통해 여러 계정이 소속될 수 있다.
CREATE TABLE companies (
    id                       VARCHAR(17)   PRIMARY KEY DEFAULT ('COMP' || LPAD(NEXTVAL('SEQ_COMPANIES_01')::TEXT, 13, '0')),
    business_name            VARCHAR(100)  NOT NULL,
    business_reg_no          VARCHAR(20)   NOT NULL UNIQUE,
    bank_name                VARCHAR(50),
    bank_account_no          VARCHAR(50),
    settlement_email         VARCHAR(100),
    approval_status_code_id  VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='COMPANY_APPROVAL_STATUS'
    grade_code_id            VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='COMPANY_GRADE'. 등급별 실제 혜택/수수료율은 company_grade_policies 참고
    owner_account_id         VARCHAR(17)   NOT NULL REFERENCES general_accounts(account_id), -- 대표자. 변경은 company_owner_change_requests 승인을 통해서만(앱 규칙, 직접 UPDATE 금지)

    del_yn      CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMP     NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 회사 등급별 정책 (초안) - 등급 코드 하나당 정책 1행. 수수료율/혜택 실제 수치는 운영 정책에 맞게 조정 필요.
-- settlements.commission_amount = total_sales_amount * (해당 회사 grade_code_id의 commission_rate / 100) 로 계산하는 것을 기본 공식으로 함.
CREATE TABLE company_grade_policies (
    id                    VARCHAR(17)  PRIMARY KEY DEFAULT ('CGPL' || LPAD(NEXTVAL('SEQ_COMPANY_GRADE_POLICIES_01')::TEXT, 13, '0')),
    grade_code_id         VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='COMPANY_GRADE'. 유일성은 아래 ux_company_grade_policies_grade로
    commission_rate       NUMERIC(5,2) NOT NULL CHECK (commission_rate BETWEEN 0 AND 100), -- %
    benefit_description   VARCHAR(300),

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);
CREATE UNIQUE INDEX ux_company_grade_policies_grade ON company_grade_policies (grade_code_id) WHERE del_yn = 'N';

-- 회사 배송비 정책 (회사당 1건 - 기본 배송비/무료배송 조건/도서산간 추가배송비).
-- 실제 주문에 청구된 배송비는 deliveries.delivery_fee에 스냅샷으로 남는다(정책이 바뀌어도 과거 배송엔 영향 없음).
CREATE TABLE company_shipping_policies (
    id                        VARCHAR(17)   PRIMARY KEY DEFAULT ('CSHP' || LPAD(NEXTVAL('SEQ_COMPANY_SHIPPING_POLICIES_01')::TEXT, 13, '0')),
    company_id                VARCHAR(17)   NOT NULL REFERENCES companies(id) ON DELETE CASCADE, -- 유일성은 아래 ux_company_shipping_policies_company로
    base_fee                  NUMERIC(10,2) NOT NULL DEFAULT 3000 CHECK (base_fee >= 0), -- 기본 배송비 (1차 기본값 3,000원 - 회사가 개별 조정 가능)
    free_shipping_threshold   NUMERIC(12,2) DEFAULT 30000 CHECK (free_shipping_threshold IS NULL OR free_shipping_threshold >= 0), -- 이 금액 이상 무료배송 (1차 기본값 30,000원). 무료배송 미제공 회사는 NULL로 명시적 변경
    remote_area_extra_fee     NUMERIC(10,2) NOT NULL DEFAULT 3000 CHECK (remote_area_extra_fee >= 0), -- 제주/도서산간 등 추가배송비 (1차 기본값 3,000원)

    del_yn      CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMP     NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);
CREATE UNIQUE INDEX ux_company_shipping_policies_company ON company_shipping_policies (company_id) WHERE del_yn = 'N';

-- 회사 직책. 이름은 회사가 자유롭게 정의(예: '대표', 'MD', '배송담당') - 같은 이름이라도 회사가
-- 다르면 완전히 다른 행. 실제 시스템 권한 종류(company_role_permissions가 참조하는 공통코드)는
-- 고정돼 있고, 직책은 그 권한들을 회사 마음대로 묶는 "이름표"에 가깝다.
CREATE TABLE company_roles (
    id          VARCHAR(17)  PRIMARY KEY DEFAULT ('CROL' || LPAD(NEXTVAL('SEQ_COMPANY_ROLES_01')::TEXT, 13, '0')),
    company_id  VARCHAR(17)  NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    role_name   VARCHAR(50)  NOT NULL,
    sort_order  INTEGER      NOT NULL DEFAULT 0,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
    -- UNIQUE(company_id, role_name)는 아래 부분 유니크 인덱스로 대체 (소프트 삭제된 행이 슬롯을 점유하지 않도록)
);
CREATE UNIQUE INDEX ux_company_roles_company_name ON company_roles (company_id, role_name) WHERE del_yn = 'N';

-- 직책-권한 연결 (다대다). 권한 "종류" 자체는 COMPANY_PERMISSION 공통코드로 시스템에 고정된 목록.
CREATE TABLE company_role_permissions (
    id                  VARCHAR(17) PRIMARY KEY DEFAULT ('CRPM' || LPAD(NEXTVAL('SEQ_COMPANY_ROLE_PERMISSIONS_01')::TEXT, 13, '0')),
    role_id             VARCHAR(17) NOT NULL REFERENCES company_roles(id) ON DELETE CASCADE,
    permission_code_id  VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='COMPANY_PERMISSION' (상품관리/주문관리/정산조회/직원관리/배송관리/회사정보관리 등)

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
    -- UNIQUE(role_id, permission_code_id)는 아래 부분 유니크 인덱스로 대체
);
CREATE UNIQUE INDEX ux_company_role_permissions_role_permission ON company_role_permissions (role_id, permission_code_id) WHERE del_yn = 'N';

-- 계정-회사-직책 연결 (다대다 핵심). account_id가 general_accounts를 참조하므로 관리자는 회사에
-- 소속될 수 없다(DB가 강제). company_id가 다르면 같은 account_id가 여러 행에 나타날 수 있어
-- "1명이 여러 회사 운영"이 이 구조에서 자연히 지원된다 - 별도 설계 요소가 필요 없다.
CREATE TABLE company_members (
    id          VARCHAR(17) PRIMARY KEY DEFAULT ('CMEM' || LPAD(NEXTVAL('SEQ_COMPANY_MEMBERS_01')::TEXT, 13, '0')),
    company_id  VARCHAR(17) NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    account_id  VARCHAR(17) NOT NULL REFERENCES general_accounts(account_id) ON DELETE CASCADE,
    role_id     VARCHAR(17) NOT NULL REFERENCES company_roles(id),
    joined_at   TIMESTAMP   NOT NULL DEFAULT now(),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
    -- UNIQUE(company_id, account_id)는 아래 부분 유니크 인덱스로 대체 (탈퇴 후 재합류 가능하도록)
);
CREATE UNIQUE INDEX ux_company_members_company_account ON company_members (company_id, account_id) WHERE del_yn = 'N';

-- 회사 대표자 변경 신청. companies.owner_account_id를 직접 UPDATE하지 않고 이 절차(접수->검토중
-- ->승인/반려)를 거치도록 애플리케이션에서 강제한다 - 의도적으로 번거롭게 만들어 오남용/분쟁을 줄임.
CREATE TABLE company_owner_change_requests (
    id                          VARCHAR(17)  PRIMARY KEY DEFAULT ('OWCR' || LPAD(NEXTVAL('SEQ_COMPANY_OWNER_CHANGE_REQUESTS_01')::TEXT, 13, '0')),
    company_id                  VARCHAR(17)  NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    current_owner_account_id    VARCHAR(17)  NOT NULL REFERENCES general_accounts(account_id), -- 신청 시점 대표자 스냅샷
    requested_owner_account_id  VARCHAR(17)  NOT NULL REFERENCES general_accounts(account_id), -- 새 대표자 희망 계정(company_members 소속이어야 함 - 앱 규칙)
    requested_by_account_id     VARCHAR(17)  NOT NULL REFERENCES general_accounts(account_id),
    reason                      VARCHAR(500),
    status_code_id              VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='OWNER_CHANGE_STATUS' (접수/검토중/승인/반려)
    processed_by_admin_id       VARCHAR(17)  REFERENCES admins(account_id),
    processed_at                TIMESTAMP,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 배송지 (계정 소속)
CREATE TABLE addresses (
    id              VARCHAR(17)  PRIMARY KEY DEFAULT ('ADDR' || LPAD(NEXTVAL('SEQ_ADDRESSES_01')::TEXT, 13, '0')),
    account_id      VARCHAR(17)  NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    address_name    VARCHAR(50), -- 계정이 붙이는 주소 별칭 (예: 우리집, 사무실) - 선택 입력
    recipient_name  VARCHAR(50)  NOT NULL,
    phone           VARCHAR(20)  NOT NULL,
    zip_code        VARCHAR(10)  NOT NULL,
    address1        VARCHAR(200) NOT NULL,
    address2        VARCHAR(200),
    default_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (default_yn IN ('Y','N')),

    del_yn          CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by      VARCHAR(50)  NOT NULL,
    created_at      TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by      VARCHAR(50),
    updated_at      TIMESTAMP
);
-- 계정당 기본 배송지는 최대 1개로 강제 (부분 유니크 인덱스, account_emails.primary_yn과 동일 패턴)
CREATE UNIQUE INDEX ux_addresses_default ON addresses(account_id) WHERE default_yn = 'Y' AND del_yn = 'N';

-- 카테고리 (self-reference로 대/중/소 분류 지원)
CREATE TABLE categories (
    id          VARCHAR(17)  PRIMARY KEY DEFAULT ('CATG' || LPAD(NEXTVAL('SEQ_CATEGORIES_01')::TEXT, 13, '0')),
    parent_id   VARCHAR(17)  REFERENCES categories(id) ON DELETE SET NULL,
    name        VARCHAR(50)  NOT NULL,
    sort_order  INTEGER      NOT NULL DEFAULT 0,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 상품 (회사 소속)
-- id: 내부 조인/성능용 PK(신규 코드+시퀀스 규칙), uuid: API/URL 등 외부 노출용 공개 식별자 (IDOR 대비)
CREATE TABLE products (
    id              VARCHAR(17)   PRIMARY KEY DEFAULT ('PROD' || LPAD(NEXTVAL('SEQ_PRODUCTS_01')::TEXT, 13, '0')),
    uuid            UUID          NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    company_id      VARCHAR(17)   NOT NULL REFERENCES companies(id),
    category_id     VARCHAR(17)   NOT NULL REFERENCES categories(id),
    name            VARCHAR(200)  NOT NULL,
    description     TEXT,
    price           NUMERIC(12,2) NOT NULL CHECK (price >= 0),
    stock_quantity  INTEGER       NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0), -- 옵션이 있는 상품은 product_option_combinations.stock_quantity가 실제 재고이며 이 컬럼은 참고용
    status_code_id  VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='PRODUCT_STATUS' (ON_SALE/SOLD_OUT/HIDDEN). 1차 정책: 옵션 조합 전량 품절/단종 시 앱이 자동으로 SOLD_OUT 전환(파일 하단 참고)

    del_yn          CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by      VARCHAR(50)   NOT NULL,
    created_at      TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by      VARCHAR(50),
    updated_at      TIMESTAMP
);

-- 파일 (공통) - 모든 첨부/이미지 파일을 여기서 통합 관리
-- 예외: PK 자체가 URL로 직접 서빙되는 공개 식별자이므로, 위 [PK 규칙](코드+순번)을 적용하지 않고
-- 기존과 동일하게 UUID를 PK로 유지한다 — 코드+순번 조합은 오히려 추측이 쉬워 보안 규칙과 충돌하기 때문.
CREATE TABLE files (
    id               UUID         PRIMARY KEY DEFAULT gen_random_uuid(),
    original_name    VARCHAR(255) NOT NULL,
    stored_path      VARCHAR(500) NOT NULL, -- 실제 저장 경로/키 (S3 key 등) - 클라이언트에 직접 노출 금지
    mime_type        VARCHAR(100) NOT NULL,
    size_bytes       BIGINT       NOT NULL CHECK (size_bytes >= 0),
    uploaded_by      VARCHAR(17)  REFERENCES accounts(id),

    del_yn           CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by       VARCHAR(50)  NOT NULL,
    created_at       TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by       VARCHAR(50),
    updated_at       TIMESTAMP
);

-- 상품-파일 연결 (product_id는 내부 FK, file_id는 UUID로 files를 참조)
CREATE TABLE product_files (
    id             VARCHAR(17)  PRIMARY KEY DEFAULT ('PDFL' || LPAD(NEXTVAL('SEQ_PRODUCT_FILES_01')::TEXT, 13, '0')),
    product_id     VARCHAR(17)  NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    file_id        UUID         NOT NULL REFERENCES files(id) ON DELETE CASCADE,
    thumbnail_yn   CHAR(1)      NOT NULL DEFAULT 'N' CHECK (thumbnail_yn IN ('Y','N')), -- 대표이미지 여부
    sort_order     INTEGER      NOT NULL DEFAULT 0,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
    -- UNIQUE(product_id, file_id)는 아래 부분 유니크 인덱스로 대체
);
CREATE UNIQUE INDEX ux_product_files_product_file ON product_files (product_id, file_id) WHERE del_yn = 'N';
-- 상품당 대표이미지는 최대 1개
CREATE UNIQUE INDEX ux_product_files_thumbnail ON product_files(product_id) WHERE thumbnail_yn = 'Y' AND del_yn = 'N';

-- 상품 옵션 축 (예: '사이즈', '색상' - 상품마다 0개 이상)
-- selection_type_code_id: 이 축을 반드시 골라야 하는지(필수) 아닌지(선택) - 축 단위 속성
CREATE TABLE product_options (
    id                     VARCHAR(17)  PRIMARY KEY DEFAULT ('POPT' || LPAD(NEXTVAL('SEQ_PRODUCT_OPTIONS_01')::TEXT, 13, '0')),
    product_id             VARCHAR(17)  NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name                   VARCHAR(50)  NOT NULL, -- 예: '사이즈', '색상'
    selection_type_code_id VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='OPTION_SELECTION_TYPE' (필수/선택)
    sort_order             INTEGER      NOT NULL DEFAULT 0,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 옵션 축의 선택 가능한 값 (예: 'S'/'M'/'L', '빨강'/'파랑')
-- status_code_id: 이 값 자체가 판매중/품절/단종인지 - 조합(product_option_combinations)의 재고와는 별개로
-- "이 값을 아예 고를 수 있는 상태인지"를 값 단위로 관리 (예: '빨강'이 단종되면 모든 조합에서 자동으로 배제)
CREATE TABLE product_option_values (
    id                 VARCHAR(17)  PRIMARY KEY DEFAULT ('POVL' || LPAD(NEXTVAL('SEQ_PRODUCT_OPTION_VALUES_01')::TEXT, 13, '0')),
    product_option_id  VARCHAR(17)  NOT NULL REFERENCES product_options(id) ON DELETE CASCADE,
    value              VARCHAR(50)  NOT NULL,
    status_code_id     VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='OPTION_VALUE_STATUS' (판매중/품절/단종)
    sort_order         INTEGER      NOT NULL DEFAULT 0,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 실제 구매 가능한 옵션 조합 (SKU 역할) - 조합마다 재고/추가금액을 따로 관리.
-- 옵션이 없는 상품은 이 테이블에 행이 없고, products.price/stock_quantity를 그대로 사용한다.
CREATE TABLE product_option_combinations (
    id                VARCHAR(17)   PRIMARY KEY DEFAULT ('POCB' || LPAD(NEXTVAL('SEQ_PRODUCT_OPTION_COMBINATIONS_01')::TEXT, 13, '0')),
    product_id        VARCHAR(17)   NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    additional_price  NUMERIC(12,2) NOT NULL DEFAULT 0, -- 상품 기본가 대비 추가금액(음수면 할인 조합도 가능)
    stock_quantity    INTEGER       NOT NULL DEFAULT 0 CHECK (stock_quantity >= 0),
    status_code_id    VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='PRODUCT_STATUS' 재사용 (조합 단위 판매중/품절)

    del_yn            CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by        VARCHAR(50)   NOT NULL,
    created_at        TIMESTAMP     NOT NULL DEFAULT now(),
    updated_by        VARCHAR(50),
    updated_at        TIMESTAMP
);

-- 조합-옵션값 연결 (한 조합은 옵션 축 개수만큼 값을 가짐, 예: 사이즈=M + 색상=빨강)
CREATE TABLE product_option_combination_values (
    id                        VARCHAR(17) PRIMARY KEY DEFAULT ('POCV' || LPAD(NEXTVAL('SEQ_PRODUCT_OPTION_COMBINATION_VALUES_01')::TEXT, 13, '0')),
    combination_id            VARCHAR(17) NOT NULL REFERENCES product_option_combinations(id) ON DELETE CASCADE,
    product_option_value_id   VARCHAR(17) NOT NULL REFERENCES product_option_values(id),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
    -- UNIQUE(combination_id, product_option_value_id)는 아래 부분 유니크 인덱스로 대체
);
CREATE UNIQUE INDEX ux_poc_values_combination_value ON product_option_combination_values (combination_id, product_option_value_id) WHERE del_yn = 'N';

-- 상품 스펙/속성 (구매 옵션이 아닌 단순 표시용 정보 - 예: 소재, 원산지, 제조사).
-- product_options와의 차이: 이건 고객이 "선택"하지 않고 그냥 "보여지기만" 하는 정보라 재고/가격에 영향 없음.
CREATE TABLE product_attributes (
    id               VARCHAR(17)  PRIMARY KEY DEFAULT ('PATR' || LPAD(NEXTVAL('SEQ_PRODUCT_ATTRIBUTES_01')::TEXT, 13, '0')),
    product_id       VARCHAR(17)  NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    attribute_name   VARCHAR(50)  NOT NULL, -- 예: '소재', '원산지', '제조사'
    attribute_value  VARCHAR(200) NOT NULL,
    sort_order       INTEGER      NOT NULL DEFAULT 0,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 찜/위시리스트
CREATE TABLE wishlists (
    id          VARCHAR(17) PRIMARY KEY DEFAULT ('WISH' || LPAD(NEXTVAL('SEQ_WISHLISTS_01')::TEXT, 13, '0')),
    account_id  VARCHAR(17) NOT NULL REFERENCES general_accounts(account_id) ON DELETE CASCADE,
    product_id  VARCHAR(17) NOT NULL REFERENCES products(id) ON DELETE CASCADE,

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
    -- UNIQUE(account_id, product_id)는 아래 부분 유니크 인덱스로 대체 (찜 해제 후 재찜 가능하도록)
);
CREATE UNIQUE INDEX ux_wishlists_account_product ON wishlists (account_id, product_id) WHERE del_yn = 'N';

-- 장바구니 (계정당 1개)
CREATE TABLE carts (
    id          VARCHAR(17) PRIMARY KEY DEFAULT ('CART' || LPAD(NEXTVAL('SEQ_CARTS_01')::TEXT, 13, '0')),
    account_id  VARCHAR(17) NOT NULL REFERENCES general_accounts(account_id) ON DELETE CASCADE, -- 유일성은 아래 ux_carts_account로

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);
CREATE UNIQUE INDEX ux_carts_account ON carts (account_id) WHERE del_yn = 'N';

-- 장바구니 항목
CREATE TABLE cart_items (
    id                     VARCHAR(17) PRIMARY KEY DEFAULT ('CRIT' || LPAD(NEXTVAL('SEQ_CART_ITEMS_01')::TEXT, 13, '0')),
    cart_id                VARCHAR(17) NOT NULL REFERENCES carts(id) ON DELETE CASCADE,
    product_id             VARCHAR(17) NOT NULL REFERENCES products(id),
    option_combination_id  VARCHAR(17) REFERENCES product_option_combinations(id), -- 옵션 없는 상품이면 NULL
    quantity               INTEGER     NOT NULL CHECK (quantity > 0),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);
-- 같은 상품+옵션조합은 장바구니에 한 줄만 존재 (옵션 없는 상품도 COALESCE로 동일하게 강제)
CREATE UNIQUE INDEX ux_cart_items_product_option ON cart_items (cart_id, product_id, COALESCE(option_combination_id, 'NONE')) WHERE del_yn = 'N';

-- 주문 (계정이 생성)
CREATE TABLE orders (
    id               VARCHAR(17)   PRIMARY KEY DEFAULT ('ORDR' || LPAD(NEXTVAL('SEQ_ORDERS_01')::TEXT, 13, '0')),
    account_id       VARCHAR(17)   NOT NULL REFERENCES general_accounts(account_id),
    address_id       VARCHAR(17)   REFERENCES addresses(id) ON DELETE SET NULL, -- 참고용 역참조일 뿐(어떤 저장 주소에서 복사했는지). 저장 안 하고 1회성으로 입력한 주소면 NULL. 실제 배송지는 아래 스냅샷 컬럼이 원본
    recipient_name   VARCHAR(50)   NOT NULL, -- 주문 시점 배송지 스냅샷 (이후 addresses가 수정/삭제돼도 주문 내역엔 영향 없도록)
    phone            VARCHAR(20)   NOT NULL,
    zip_code         VARCHAR(10)   NOT NULL,
    address1         VARCHAR(200)  NOT NULL,
    address2         VARCHAR(200),
    order_number     VARCHAR(50)   NOT NULL UNIQUE,
    status_code_id   VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='ORDER_STATUS' (배송 자체의 상세 상태/이력은 deliveries/delivery_status_histories 참고)
    total_amount     NUMERIC(12,2) NOT NULL CHECK (total_amount >= 0), -- 상품금액 합 - discount_amount + 배송비 합(deliveries.delivery_fee 전체 합) = 결제 총액
    discount_amount  NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (discount_amount >= 0), -- 적용된 쿠폰 할인액 스냅샷 (어떤 쿠폰인지는 account_coupons.used_order_id로 역참조)
    ordered_at       TIMESTAMP   NOT NULL DEFAULT now(),

    del_yn        CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by    VARCHAR(50)   NOT NULL,
    created_at    TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by    VARCHAR(50),
    updated_at    TIMESTAMP
);

-- 주문 항목 (주문 시점 가격 스냅샷)
CREATE TABLE order_items (
    id                     VARCHAR(17)   PRIMARY KEY DEFAULT ('ORIT' || LPAD(NEXTVAL('SEQ_ORDER_ITEMS_01')::TEXT, 13, '0')),
    order_id               VARCHAR(17)   NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id             VARCHAR(17)   NOT NULL REFERENCES products(id),
    product_name           VARCHAR(200)  NOT NULL, -- 주문 시점 상품명 스냅샷 - 이후 회사가 상품명을 바꾸거나 상품을 삭제해도 주문 내역 표시엔 영향 없도록 (order_items.price/option_summary와 같은 이유)
    option_combination_id  VARCHAR(17)   REFERENCES product_option_combinations(id),
    option_summary         VARCHAR(300), -- 주문 시점 옵션 표시 스냅샷 (예: '사이즈: M, 색상: 빨강') - 이후 옵션 구성이 바뀌어도 주문 내역엔 영향 없도록
    delivery_id            VARCHAR(17), -- 이 항목이 속한 배송(회사별 분리 배송). FK는 deliveries 정의 이후 ALTER TABLE로 추가(테이블 선언 순서상)
    quantity               INTEGER       NOT NULL CHECK (quantity > 0),
    price                  NUMERIC(12,2) NOT NULL CHECK (price >= 0), -- 옵션 추가금액까지 반영된 단가 스냅샷

    del_yn      CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 취소/반품/교환/환불 신청 (클레임). order_items 단위라 부분 취소/반품이 가능.
CREATE TABLE order_claims (
    id                  VARCHAR(17)   PRIMARY KEY DEFAULT ('CLAM' || LPAD(NEXTVAL('SEQ_ORDER_CLAIMS_01')::TEXT, 13, '0')),
    order_item_id       VARCHAR(17)   NOT NULL REFERENCES order_items(id),
    claim_type_code_id  VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='CLAIM_TYPE' (취소/반품/교환/단순환불)
    reason_code_id      VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='CLAIM_REASON' (단순변심/상품불량/오배송/기타 등)
    reason_detail       VARCHAR(500),
    status_code_id      VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='CLAIM_STATUS' (접수/승인/수거중/수거완료/처리완료/거절)
    quantity            INTEGER       NOT NULL CHECK (quantity > 0), -- 부분 클레임 지원
    refund_amount       NUMERIC(12,2) CHECK (refund_amount IS NULL OR refund_amount >= 0), -- 승인된 환불 예정액(결정값). 실제 처리 이력은 refunds.order_claim_id로 역참조
    requested_at        TIMESTAMP     NOT NULL DEFAULT now(),
    processed_at        TIMESTAMP,

    del_yn      CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMP     NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 적립금 변동 이력. general_accounts.points는 현재 잔액 스냅샷이고, 이 테이블이 stock_histories와 같은 방식의 감사 근거.
CREATE TABLE point_histories (
    id                    VARCHAR(17) PRIMARY KEY DEFAULT ('PTHS' || LPAD(NEXTVAL('SEQ_POINT_HISTORIES_01')::TEXT, 13, '0')),
    account_id            VARCHAR(17) NOT NULL REFERENCES general_accounts(account_id) ON DELETE CASCADE,
    change_type_code_id   VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='POINT_CHANGE_TYPE' (구매적립/사용/소멸/관리자지급/취소환수)
    points_delta          INTEGER     NOT NULL, -- 증감량 (적립 양수, 사용/소멸 음수)
    points_after          INTEGER     NOT NULL CHECK (points_after >= 0), -- 변경 후 잔액 스냅샷
    reference_order_id    VARCHAR(17) REFERENCES orders(id),
    expires_at            TIMESTAMP, -- 이 적립 건의 소멸 예정일 (적립 이력에만 의미). 1차 정책: 적립률 1%, 적립일+365일 소멸(파일 하단 참고)
    memo                  VARCHAR(200),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 결제 (주문당 1건). amount는 최초 결제된 금액 그대로 유지(환불이 발생해도 수정하지 않음) -
-- 실제 매출 계산은 SUM(payments.amount) - SUM(refunds.amount WHERE 완료) 로 한다.
-- status_code_id의 REFUNDED는 "전액 환불 완료"를 나타내는 요약 상태일 뿐, 부분환불 등 상세 내역은 refunds 테이블 참고.
CREATE TABLE payments (
    id              VARCHAR(17)   PRIMARY KEY DEFAULT ('PAYM' || LPAD(NEXTVAL('SEQ_PAYMENTS_01')::TEXT, 13, '0')),
    order_id        VARCHAR(17)   NOT NULL UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    method_code_id  VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='PAYMENT_METHOD' (CARD/BANK_TRANSFER/VIRTUAL_ACCOUNT)
    amount          NUMERIC(12,2) NOT NULL CHECK (amount >= 0),
    status_code_id  VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='PAYMENT_STATUS' (PENDING/COMPLETED/FAILED/REFUNDED)
    paid_at         TIMESTAMP,

    del_yn      CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 환불 처리 내역 (payments의 짝, point_histories/stock_histories와 같은 원장 패턴).
-- order_claims.refund_amount는 "클레임 승인 시점에 얼마를 환불해주기로 결정했나"(승인액)이고,
-- 이 테이블은 "실제로 언제·얼마나·어떤 방식으로 돈이 처리됐나"(실제 처리 이력) - 부분환불/재시도/실패를
-- 표현하려면 승인 결정과 실제 처리를 분리해야 해서 별도 테이블로 둔다.
CREATE TABLE refunds (
    id               VARCHAR(17)   PRIMARY KEY DEFAULT ('RFND' || LPAD(NEXTVAL('SEQ_REFUNDS_01')::TEXT, 13, '0')),
    payment_id       VARCHAR(17)   NOT NULL REFERENCES payments(id),
    order_claim_id   VARCHAR(17)   REFERENCES order_claims(id), -- nullable: 클레임 없이 관리자가 임의로 처리하는 환불도 지원
    method_code_id   VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='REFUND_METHOD' (원결제수단/계좌이체/적립금전환)
    amount           NUMERIC(12,2) NOT NULL CHECK (amount > 0),
    status_code_id   VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='REFUND_STATUS' (요청/처리중/완료/실패)
    requested_at     TIMESTAMP     NOT NULL DEFAULT now(),
    processed_at     TIMESTAMP,

    del_yn      CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 리뷰 (계정이 작성)
CREATE TABLE reviews (
    id             VARCHAR(17) PRIMARY KEY DEFAULT ('RVEW' || LPAD(NEXTVAL('SEQ_REVIEWS_01')::TEXT, 13, '0')),
    product_id     VARCHAR(17) NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    account_id     VARCHAR(17) NOT NULL REFERENCES general_accounts(account_id) ON DELETE CASCADE,
    order_item_id  VARCHAR(17) REFERENCES order_items(id),
    rating         SMALLINT    NOT NULL CHECK (rating BETWEEN 1 AND 5),
    content        TEXT,
    view_count     INTEGER     NOT NULL DEFAULT 0 CHECK (view_count >= 0),
    like_count     INTEGER     NOT NULL DEFAULT 0 CHECK (like_count >= 0),
    dislike_count  INTEGER     NOT NULL DEFAULT 0 CHECK (dislike_count >= 0),

    del_yn         CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by     VARCHAR(50) NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    updated_by     VARCHAR(50),
    updated_at     TIMESTAMP
);

-- ============================================================
-- 게시판 / 댓글 / 쿠폰 / 배송추적
-- ============================================================

-- 게시물 (공지/FAQ/상품문의 통합 관리). board_code_id로 게시판 종류를 구분하며,
-- 이벤트는 common_codes에 NOTICE의 하위(parent_id) 코드로 등록해 "공지의 하위 카테고리"를 표현.
-- 상품문의(PRODUCT_INQUIRY)는 같은 board_posts를 재사용하되 product_id/secret_yn/answered_yn으로
-- 상품 연결·비밀글·답변여부를 추가 지원 - 프론트/백엔드에서 board_code_id로 노출 방식만 다르게 그리면 됨.
-- 리뷰(reviews)는 주문/평점에 강하게 묶여 있고 조회 패턴도 달라 통합하지 않고 별도 유지,
-- 대신 view_count/like_count/dislike_count 컬럼 구조와 댓글 연결(comments)은 동일하게 공유.
-- id: 내부 PK, uuid: 게시물 상세 URL 등 외부 노출용 공개 식별자 (products와 동일한 보안 규칙 적용)
CREATE TABLE board_posts (
    id             VARCHAR(17)  PRIMARY KEY DEFAULT ('BPST' || LPAD(NEXTVAL('SEQ_BOARD_POSTS_01')::TEXT, 13, '0')),
    uuid           UUID         NOT NULL UNIQUE DEFAULT gen_random_uuid(),
    board_code_id  VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='BOARD_TYPE'
    account_id     VARCHAR(17)  NOT NULL REFERENCES accounts(id), -- 작성자
    product_id     VARCHAR(17)  REFERENCES products(id), -- 상품문의 등 특정 상품에 딸린 게시물일 때만 사용, 공지/FAQ는 NULL
    title          VARCHAR(200) NOT NULL,
    content        TEXT         NOT NULL,
    secret_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (secret_yn IN ('Y','N')), -- 비밀글(작성자+판매자+관리자만 열람) - 상품문의에서 주로 사용
    answered_yn    CHAR(1)      NOT NULL DEFAULT 'N' CHECK (answered_yn IN ('Y','N')), -- 답변(댓글) 등록 여부 - 앱이 댓글 생성 시 갱신하는 집계 플래그
    view_count     INTEGER      NOT NULL DEFAULT 0 CHECK (view_count >= 0),
    like_count     INTEGER      NOT NULL DEFAULT 0 CHECK (like_count >= 0),
    dislike_count  INTEGER      NOT NULL DEFAULT 0 CHECK (dislike_count >= 0),

    del_yn         CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by     VARCHAR(50)  NOT NULL,
    created_at     TIMESTAMP  NOT NULL DEFAULT now(),
    updated_by     VARCHAR(50),
    updated_at     TIMESTAMP
);

-- 댓글 (게시물/리뷰 통합 관리, 대댓글 지원)
-- post_id/review_id 중 정확히 하나만 채워지는 배타적 FK 구조로 설계.
-- files에서 지양한 parent_type/parent_id 문자열 폴리모픽 대신, 대상별 실제 FK를 그대로 두어
-- 무결성은 유지하면서도 댓글 테이블 자체는 하나로 통합 (요구사항의 "통합 관리"를 만족).
CREATE TABLE comments (
    id            VARCHAR(17) PRIMARY KEY DEFAULT ('CMNT' || LPAD(NEXTVAL('SEQ_COMMENTS_01')::TEXT, 13, '0')),
    post_id       VARCHAR(17) REFERENCES board_posts(id) ON DELETE CASCADE,
    review_id     VARCHAR(17) REFERENCES reviews(id) ON DELETE CASCADE,
    parent_id     VARCHAR(17) REFERENCES comments(id) ON DELETE CASCADE, -- 대댓글 (자기 자신 참조)
    account_id    VARCHAR(17) NOT NULL REFERENCES accounts(id), -- 작성자
    content       TEXT        NOT NULL,
    like_count    INTEGER     NOT NULL DEFAULT 0 CHECK (like_count >= 0),
    dislike_count INTEGER     NOT NULL DEFAULT 0 CHECK (dislike_count >= 0),

    del_yn        CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by    VARCHAR(50) NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT now(),
    updated_by    VARCHAR(50),
    updated_at    TIMESTAMP,
    CHECK (num_nonnulls(post_id, review_id) = 1)
);

-- 쿠폰 정의. issue_type_code_id로 두 방식을 한 테이블에서 표현:
--   SHARED_CODE - 계정이 code를 직접 입력해 사용 (전체 공용 코드)
--   TARGETED    - 관리자가 특정 계정에 미리 발급 (code는 보통 NULL)
CREATE TABLE coupons (
    id                      VARCHAR(17)   PRIMARY KEY DEFAULT ('CPON' || LPAD(NEXTVAL('SEQ_COUPONS_01')::TEXT, 13, '0')),
    code                    VARCHAR(50)   UNIQUE, -- SHARED_CODE만 사용, TARGETED는 보통 NULL
    issue_type_code_id      VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='COUPON_ISSUE_TYPE'
    discount_type_code_id   VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='COUPON_DISCOUNT_TYPE'
    discount_value          NUMERIC(12,2) NOT NULL CHECK (discount_value > 0),
    min_order_amount        NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (min_order_amount >= 0), -- 쿠폰 적용 가능한 최소 주문금액
    max_discount_amount     NUMERIC(12,2) CHECK (max_discount_amount IS NULL OR max_discount_amount >= 0), -- 정률(RATE) 할인의 최대 할인 캡. AMOUNT 타입은 보통 NULL
    valid_from              TIMESTAMP,
    valid_until             TIMESTAMP,
    status_code_id          VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='COUPON_STATUS'
    scope_code_id           VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='COUPON_SCOPE' (전체상품/카테고리한정/상품한정/회사한정). 한정이면 coupon_targets에 대상 등록

    del_yn          CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by      VARCHAR(50)   NOT NULL,
    created_at      TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by      VARCHAR(50),
    updated_at      TIMESTAMP
);

-- 쿠폰 적용 대상 (scope_code_id가 전체상품이 아닐 때만 사용). category_id/product_id/company_id 중 정확히 하나만
-- 채워지는 배타적 FK로, comments/reactions와 같은 패턴 - 대상 종류가 3개로 고정돼 있어 실제 FK로 무결성을 지킨다
-- (notifications처럼 대상 종류가 계속 늘어나는 경우와 달리, 여기선 폴리모픽 예외를 쓰지 않음).
CREATE TABLE coupon_targets (
    id           VARCHAR(17) PRIMARY KEY DEFAULT ('CPTG' || LPAD(NEXTVAL('SEQ_COUPON_TARGETS_01')::TEXT, 13, '0')),
    coupon_id    VARCHAR(17) NOT NULL REFERENCES coupons(id) ON DELETE CASCADE,
    category_id  VARCHAR(17) REFERENCES categories(id),
    product_id   VARCHAR(17) REFERENCES products(id),
    company_id   VARCHAR(17) REFERENCES companies(id),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP,
    CHECK (num_nonnulls(category_id, product_id, company_id) = 1)
);

-- 계정별 쿠폰 보유/사용 현황.
-- SHARED_CODE는 계정이 코드를 사용(redeem)하는 시점에 행이 생성되고,
-- TARGETED는 발급 시점에 행이 생성됨 - 두 경우 모두 이 테이블 하나로 처리.
-- UNIQUE(coupon_id, account_id)가 "계정당 1회"를 자동으로 보장 (공용 코드 중복 사용도, 개별 중복 발급도 함께 방지).
CREATE TABLE account_coupons (
    id              VARCHAR(17) PRIMARY KEY DEFAULT ('ACPN' || LPAD(NEXTVAL('SEQ_ACCOUNT_COUPONS_01')::TEXT, 13, '0')),
    coupon_id       VARCHAR(17) NOT NULL REFERENCES coupons(id),
    account_id      VARCHAR(17) NOT NULL REFERENCES accounts(id),
    status_code_id  VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='ACCOUNT_COUPON_STATUS' (ISSUED/USED/EXPIRED)
    used_order_id   VARCHAR(17) REFERENCES orders(id), -- 사용된 주문 (사용 전에는 NULL)
    issued_at       TIMESTAMP NOT NULL DEFAULT now(),
    used_at         TIMESTAMP,

    del_yn         CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by     VARCHAR(50) NOT NULL,
    created_at     TIMESTAMP NOT NULL DEFAULT now(),
    updated_by     VARCHAR(50),
    updated_at     TIMESTAMP,
    UNIQUE (coupon_id, account_id)
);

-- 배송 (회사별 1건 - 한 주문에 여러 회사 상품이 섞이면 회사마다 따로 배송됨. 주문 자체는 orders 1건이라도
-- 배송은 orders : deliveries = 1:N). orders.status_code_id(주문 생애주기)와 분리해 배송 자체의 현재 상태를 관리.
CREATE TABLE deliveries (
    id               VARCHAR(17)   PRIMARY KEY DEFAULT ('DELV' || LPAD(NEXTVAL('SEQ_DELIVERIES_01')::TEXT, 13, '0')),
    order_id         VARCHAR(17)   NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    company_id       VARCHAR(17)   NOT NULL REFERENCES companies(id), -- 이 배송 건을 발송하는 회사
    carrier          VARCHAR(50),
    tracking_number  VARCHAR(100),
    status_code_id   VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='DELIVERY_STATUS' (PREPARING/SHIPPED/IN_TRANSIT/DELIVERED/FAILED)
    delivery_fee     NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (delivery_fee >= 0), -- 이 배송 건의 배송비 스냅샷(회사 정책 기준, company_shipping_policies 참고)
    shipped_at       TIMESTAMP,
    delivered_at     TIMESTAMP,

    del_yn           CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by       VARCHAR(50)   NOT NULL,
    created_at       TIMESTAMP     NOT NULL DEFAULT now(),
    updated_by       VARCHAR(50),
    updated_at       TIMESTAMP,
    UNIQUE (order_id, company_id) -- 같은 주문 안에서 회사당 배송 건은 1개
);
-- order_items 선언 시점엔 deliveries가 없어 FK를 못 걸었으므로 여기서 추가
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_delivery FOREIGN KEY (delivery_id) REFERENCES deliveries(id);

-- 배송 상태 이력 - 상태가 바뀔 때마다 한 행씩 적재해 "추적"이 실제로 가능하도록 함
-- (deliveries.status_code_id는 현재 상태만 담으므로, 변경 이력 자체는 이 테이블이 근거가 됨)
CREATE TABLE delivery_status_histories (
    id              VARCHAR(17) PRIMARY KEY DEFAULT ('DLVH' || LPAD(NEXTVAL('SEQ_DELIVERY_STATUS_HISTORIES_01')::TEXT, 13, '0')),
    delivery_id     VARCHAR(17) NOT NULL REFERENCES deliveries(id) ON DELETE CASCADE,
    status_code_id  VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='DELIVERY_STATUS' (deliveries.status_code_id와 동일 그룹)
    memo            VARCHAR(200),
    changed_at      TIMESTAMP NOT NULL DEFAULT now(),

    del_yn       CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by   VARCHAR(50) NOT NULL,
    created_at   TIMESTAMP NOT NULL DEFAULT now(),
    updated_by   VARCHAR(50),
    updated_at   TIMESTAMP
);

-- ============================================================
-- 재고 이력 / 정산 / 관리자 권한 / 반응(좋아요·싫어요)
-- ============================================================

-- 재고 변동 이력. 옵션이 있는 상품은 option_combination_id까지 남기고, 없으면 NULL.
-- reference_order_id는 주문으로 인한 변동일 때만 채움(입고/조정 등은 NULL).
CREATE TABLE stock_histories (
    id                     VARCHAR(17) PRIMARY KEY DEFAULT ('STHS' || LPAD(NEXTVAL('SEQ_STOCK_HISTORIES_01')::TEXT, 13, '0')),
    product_id             VARCHAR(17) NOT NULL REFERENCES products(id),
    option_combination_id  VARCHAR(17) REFERENCES product_option_combinations(id),
    change_type_code_id    VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='STOCK_CHANGE_TYPE' (입고/출고/주문차감/취소복원/조정)
    quantity_delta         INTEGER     NOT NULL, -- 변경량 (증가 양수, 감소 음수)
    quantity_after          INTEGER    NOT NULL CHECK (quantity_after >= 0), -- 변경 후 재고 스냅샷
    reference_order_id     VARCHAR(17) REFERENCES orders(id),
    memo                   VARCHAR(200),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 정산 (기간 단위 1건). 실제 지급액 = total_sales_amount - commission_amount.
CREATE TABLE settlements (
    id                   VARCHAR(17)   PRIMARY KEY DEFAULT ('STLM' || LPAD(NEXTVAL('SEQ_SETTLEMENTS_01')::TEXT, 13, '0')),
    company_id           VARCHAR(17)   NOT NULL REFERENCES companies(id),
    period_start         DATE          NOT NULL,
    period_end           DATE          NOT NULL,
    total_sales_amount   NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (total_sales_amount >= 0),
    commission_amount    NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (commission_amount >= 0),
    payout_amount        NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (payout_amount >= 0),
    bank_name             VARCHAR(50),  -- 정산 생성 시점 companies.bank_name 스냅샷 - 이후 회사가 계좌를 바꿔도 "그때 어디로 지급했는지" 기록은 안 바뀌도록
    bank_account_no       VARCHAR(50),  -- 정산 생성 시점 companies.bank_account_no 스냅샷
    status_code_id       VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='SETTLEMENT_STATUS' (정산대기/정산확정/지급완료)
    paid_at              TIMESTAMP,

    del_yn          CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by      VARCHAR(50)   NOT NULL,
    created_at      TIMESTAMP     NOT NULL DEFAULT now(),
    updated_by      VARCHAR(50),
    updated_at      TIMESTAMP,
    UNIQUE (company_id, period_start, period_end)
);

-- 정산에 포함된 주문 항목 상세 - 주문 항목 하나는 정산 한 건에만 포함(UNIQUE)되어 이중 정산을 방지.
CREATE TABLE settlement_items (
    id             VARCHAR(17)   PRIMARY KEY DEFAULT ('STIT' || LPAD(NEXTVAL('SEQ_SETTLEMENT_ITEMS_01')::TEXT, 13, '0')),
    settlement_id  VARCHAR(17)   NOT NULL REFERENCES settlements(id) ON DELETE CASCADE,
    order_item_id  VARCHAR(17)   NOT NULL UNIQUE REFERENCES order_items(id),
    amount         NUMERIC(12,2) NOT NULL CHECK (amount >= 0),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 관리자 권한 세분화. admins.admin_level_code_id(SUPER/GENERAL)는 큰 구분으로 남기고,
-- 실제 기능 단위 권한은 이 다대다 테이블로 관리 (한 관리자가 여러 권한을 가질 수 있음).
-- (참고: 회사 소속 계정의 권한은 company_role_permissions가 별도로 관리 - 서로 다른 체계)
CREATE TABLE admin_permissions (
    id                  VARCHAR(17) PRIMARY KEY DEFAULT ('ADPM' || LPAD(NEXTVAL('SEQ_ADMIN_PERMISSIONS_01')::TEXT, 13, '0')),
    admin_id            VARCHAR(17) NOT NULL REFERENCES admins(account_id) ON DELETE CASCADE,
    permission_code_id  VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='ADMIN_PERMISSION' (상품/주문/회원/정산/게시판/쿠폰/회사/통계/권한관리 등 - 시드 예시 참고)

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
    -- UNIQUE(admin_id, permission_code_id)는 아래 부분 유니크 인덱스로 대체
);
CREATE UNIQUE INDEX ux_admin_permissions_admin_permission ON admin_permissions (admin_id, permission_code_id) WHERE del_yn = 'N';

-- 좋아요/싫어요 개별 투표 기록 - board_posts/comments/reviews.like_count·dislike_count는
-- 조회 성능을 위한 집계 컬럼이고(애플리케이션이 이 테이블 변경에 맞춰 증감), 실제 "누가 눌렀는지"와
-- 중복 투표 방지는 이 테이블이 근거. comments와 동일한 배타적 FK 패턴(대상 중 정확히 하나만 채움).
CREATE TABLE reactions (
    id                     VARCHAR(17) PRIMARY KEY DEFAULT ('RCTN' || LPAD(NEXTVAL('SEQ_REACTIONS_01')::TEXT, 13, '0')),
    post_id                VARCHAR(17) REFERENCES board_posts(id) ON DELETE CASCADE,
    comment_id             VARCHAR(17) REFERENCES comments(id) ON DELETE CASCADE,
    review_id              VARCHAR(17) REFERENCES reviews(id) ON DELETE CASCADE,
    account_id             VARCHAR(17) NOT NULL REFERENCES accounts(id),
    reaction_type_code_id  VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='REACTION_TYPE' (LIKE/DISLIKE)

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP,
    CHECK (num_nonnulls(post_id, comment_id, review_id) = 1)
);
-- 대상별로 계정당 반응 1개만 (좋아요<->싫어요 전환은 UPDATE, 취소는 DELETE)
CREATE UNIQUE INDEX ux_reactions_post ON reactions (post_id, account_id) WHERE post_id IS NOT NULL AND del_yn = 'N';
CREATE UNIQUE INDEX ux_reactions_comment ON reactions (comment_id, account_id) WHERE comment_id IS NOT NULL AND del_yn = 'N';
CREATE UNIQUE INDEX ux_reactions_review ON reactions (review_id, account_id) WHERE review_id IS NOT NULL AND del_yn = 'N';

-- ============================================================
-- 알림 / 배너 / 감사로그
-- ============================================================

-- 알림 (수신자별 인앱 알림 피드).
-- target_type_code_id/target_id로 원본 데이터(주문/배송/쿠폰/게시물/리뷰/댓글/정산/회사승인/상품 등)를
-- 느슨하게 가리킨다. 대상 종류가 계속 늘어나고, 알림은 원본이 지워져도 알림 자체는 남아 있어도 무방해
-- (DB가 항상 무결성을 지킬 만큼 중요한 관계가 아님) 이 테이블에 한해 parent_type/parent_id류 폴리모픽을
-- 예외적으로 허용한다. target_type_code_id는 공통코드 FK로 "종류"는 강제하되, target_id는 실제 FK를
-- 걸지 않는다 - 어떤 테이블의 PK인지는 target_type_code_id를 보고 애플리케이션이 해석한다.
CREATE TABLE notifications (
    id                          VARCHAR(17)  PRIMARY KEY DEFAULT ('NTFY' || LPAD(NEXTVAL('SEQ_NOTIFICATIONS_01')::TEXT, 13, '0')),
    account_id                  VARCHAR(17)  NOT NULL REFERENCES accounts(id) ON DELETE CASCADE, -- 수신자
    notification_type_code_id   VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='NOTIFICATION_TYPE'
    title                       VARCHAR(200) NOT NULL,
    content                     VARCHAR(500),
    target_type_code_id         VARCHAR(17)  REFERENCES common_codes(id), -- code_group='NOTIFICATION_TARGET_TYPE'. 단순 안내성 알림이면 NULL
    target_id                   VARCHAR(17), -- target_type_code_id가 가리키는 테이블의 PK 값 (실제 FK 아님, 위 설명 참고)
    read_yn                     CHAR(1)      NOT NULL DEFAULT 'N' CHECK (read_yn IN ('Y','N')),
    read_at                     TIMESTAMP,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 계정별 알림 유형 수신 설정. 행이 없으면 "수신함"(기본값)으로 간주하고, enabled_yn='N' 행이 있을 때만 꺼진 것으로 취급
-- (모든 계정×모든 유형 조합을 미리 채워둘 필요 없이, 끈 것만 기록하는 방식).
CREATE TABLE notification_settings (
    id                          VARCHAR(17) PRIMARY KEY DEFAULT ('NTST' || LPAD(NEXTVAL('SEQ_NOTIFICATION_SETTINGS_01')::TEXT, 13, '0')),
    account_id                  VARCHAR(17) NOT NULL REFERENCES accounts(id) ON DELETE CASCADE,
    notification_type_code_id   VARCHAR(17) NOT NULL REFERENCES common_codes(id), -- code_group='NOTIFICATION_TYPE'
    enabled_yn                  CHAR(1)     NOT NULL DEFAULT 'Y' CHECK (enabled_yn IN ('Y','N')),

    del_yn      CHAR(1)     NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50) NOT NULL,
    created_at  TIMESTAMP   NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
    -- UNIQUE(account_id, notification_type_code_id)는 아래 부분 유니크 인덱스로 대체
);
CREATE UNIQUE INDEX ux_notification_settings_account_type ON notification_settings (account_id, notification_type_code_id) WHERE del_yn = 'N';

-- 메인 배너 / 기획전 노출 관리
CREATE TABLE banners (
    id                        VARCHAR(17)  PRIMARY KEY DEFAULT ('BNNR' || LPAD(NEXTVAL('SEQ_BANNERS_01')::TEXT, 13, '0')),
    title                     VARCHAR(200) NOT NULL,
    image_file_id             UUID         NOT NULL REFERENCES files(id),
    link_url                  VARCHAR(500), -- 클릭 시 이동 경로. 내부/외부 링크 다 담을 수 있어야 해서 문자열로 유지(특정 테이블 FK로 강제하지 않음)
    display_position_code_id  VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='BANNER_POSITION' (메인상단/메인중단 등)
    sort_order                INTEGER      NOT NULL DEFAULT 0,
    start_at                  TIMESTAMP,
    end_at                    TIMESTAMP,
    active_yn                 CHAR(1)      NOT NULL DEFAULT 'Y' CHECK (active_yn IN ('Y','N')),

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 관리자 활동 감사로그. target_id는 notifications와 같은 이유로 실제 FK를 걸지 않는 느슨한 참조
-- (관리자가 건드릴 수 있는 대상이 계정/상품/주문/쿠폰/공통코드/회사 자체 등으로 매우 다양하고, 로그의
-- 목적상 원본이 삭제/변경돼도 "누가 언제 무엇을 했는지" 기록 자체는 그대로 남아야 하므로).
CREATE TABLE admin_activity_logs (
    id                    VARCHAR(17)  PRIMARY KEY DEFAULT ('AALG' || LPAD(NEXTVAL('SEQ_ADMIN_ACTIVITY_LOGS_01')::TEXT, 13, '0')),
    admin_id              VARCHAR(17)  NOT NULL REFERENCES admins(account_id),
    action_type_code_id   VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='ADMIN_ACTION_TYPE' (생성/수정/삭제/승인/거절 등)
    target_type_code_id   VARCHAR(17)  REFERENCES common_codes(id), -- code_group='ADMIN_LOG_TARGET_TYPE'
    target_id             VARCHAR(17), -- 실제 FK 아님, target_type_code_id로 애플리케이션이 해석
    detail                VARCHAR(1000), -- 변경 내용 요약
    ip_address            VARCHAR(45),

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- ============================================================
-- 대량 등록(엑셀) 임시 테이블 - "temp_" 접두어로 스테이징 테이블임을 표시.
-- 취소 시 상세 행(temp_*_import_rows)은 실제 DELETE로 제거하고, 배치 헤더(temp_bulk_import_batches)만
-- 상태를 '취소됨'으로 바꿔 가볍게 남긴다. 하루 넘게 방치된(업로드됨/검증중 상태 그대로인) 배치도 같은
-- 방식으로 일간 배치 작업이 정리한다 - 이 "동작"은 스케줄러/백엔드 코드 몫이라 스키마는 상태값과
-- ON DELETE CASCADE 관계까지만 준비해두면 된다.
-- ============================================================

-- 업로드 배치 헤더 (상품등록/송장등록/재고변경 공용) - 종류는 import_type_code_id로 구분.
-- 각 종류의 실제 행 데이터는 아래 종류별 temp_*_import_rows 테이블에 별도로 담는다(타입별 컬럼이
-- 서로 달라서 - 공통코드 attr_1~5를 거부했던 것과 같은 이유로 여기서도 범용 컬럼에 억지로 담지 않음).
CREATE TABLE temp_bulk_import_batches (
    id                    VARCHAR(17)  PRIMARY KEY DEFAULT ('TIMB' || LPAD(NEXTVAL('SEQ_TEMP_BULK_IMPORT_BATCHES_01')::TEXT, 13, '0')),
    company_id            VARCHAR(17)  NOT NULL REFERENCES companies(id) ON DELETE CASCADE,
    uploaded_by           VARCHAR(17)  NOT NULL REFERENCES accounts(id),
    import_type_code_id   VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='BULK_IMPORT_TYPE' (상품등록/송장등록/재고변경)
    file_name             VARCHAR(255),
    status_code_id        VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='BULK_IMPORT_STATUS' (업로드됨/검증중/일부실패/반영완료/취소됨/만료됨)
    total_rows             INTEGER     NOT NULL DEFAULT 0,
    success_rows           INTEGER     NOT NULL DEFAULT 0,
    fail_rows               INTEGER    NOT NULL DEFAULT 0,
    processed_at           TIMESTAMP,

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 상품 일괄등록 - 엑셀 원본은 검증 전이라 가격/재고도 우선 문자열로 받고, 검증 통과 시 products로 변환.
CREATE TABLE temp_product_import_rows (
    id                  VARCHAR(17)   PRIMARY KEY DEFAULT ('TIPR' || LPAD(NEXTVAL('SEQ_TEMP_PRODUCT_IMPORT_ROWS_01')::TEXT, 13, '0')),
    batch_id            VARCHAR(17)   NOT NULL REFERENCES temp_bulk_import_batches(id) ON DELETE CASCADE,
    row_number          INTEGER       NOT NULL, -- 엑셀 몇 번째 줄인지 (오류 확인용)
    product_name        VARCHAR(200),
    category_name       VARCHAR(100), -- 검증 시 categories.name과 매칭
    price                VARCHAR(50), -- 검증 전 원본 텍스트 (콤마 등 포함 가능)
    stock_quantity       VARCHAR(50),
    description          TEXT,
    raw_row_text         TEXT, -- 엑셀 원본 한 줄 백업 (템플릿에 없는 컬럼 대비)
    status_code_id       VARCHAR(17)   NOT NULL REFERENCES common_codes(id), -- code_group='IMPORT_ROW_STATUS' (대기/성공/실패)
    error_message        VARCHAR(500),
    created_product_id   VARCHAR(17)   REFERENCES products(id), -- 성공 시 생성된 상품 연결(추적용)

    del_yn      CHAR(1)       NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)   NOT NULL,
    created_at  TIMESTAMP     NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 송장번호 일괄등록 - order_number로 주문을 찾아 deliveries.carrier/tracking_number를 갱신.
CREATE TABLE temp_tracking_import_rows (
    id                    VARCHAR(17)  PRIMARY KEY DEFAULT ('TITR' || LPAD(NEXTVAL('SEQ_TEMP_TRACKING_IMPORT_ROWS_01')::TEXT, 13, '0')),
    batch_id              VARCHAR(17)  NOT NULL REFERENCES temp_bulk_import_batches(id) ON DELETE CASCADE,
    row_number            INTEGER      NOT NULL,
    order_number          VARCHAR(50), -- orders.order_number와 매칭
    carrier               VARCHAR(50),
    tracking_number       VARCHAR(100),
    raw_row_text          TEXT,
    status_code_id        VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='IMPORT_ROW_STATUS'
    error_message         VARCHAR(500),
    updated_delivery_id   VARCHAR(17)  REFERENCES deliveries(id), -- 성공 시 갱신된 배송 건 연결(추적용)

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- 재고/가격 일괄 변경 - product_identifier(상품명 등)로 상품(옵션 조합 포함 가능)을 찾아 재고/가격을 갱신.
CREATE TABLE temp_stock_import_rows (
    id                          VARCHAR(17)  PRIMARY KEY DEFAULT ('TISR' || LPAD(NEXTVAL('SEQ_TEMP_STOCK_IMPORT_ROWS_01')::TEXT, 13, '0')),
    batch_id                    VARCHAR(17)  NOT NULL REFERENCES temp_bulk_import_batches(id) ON DELETE CASCADE,
    row_number                  INTEGER      NOT NULL,
    product_identifier          VARCHAR(200), -- 상품 매칭용 식별자 (상품명 또는 상품 uuid 등, 원본 그대로)
    option_identifier           VARCHAR(200), -- 옵션 조합 매칭용 (있는 경우), 예: '사이즈:M,색상:빨강'
    quantity                    VARCHAR(50), -- 변경할 재고 수량 (원본 텍스트)
    price                       VARCHAR(50), -- 같이 바꿀 가격 (선택)
    raw_row_text                TEXT,
    status_code_id              VARCHAR(17)  NOT NULL REFERENCES common_codes(id), -- code_group='IMPORT_ROW_STATUS'
    error_message                VARCHAR(500),
    applied_stock_history_id     VARCHAR(17)  REFERENCES stock_histories(id), -- 성공 시 생성된 재고이력 연결(추적용)

    del_yn      CHAR(1)      NOT NULL DEFAULT 'N' CHECK (del_yn IN ('Y','N')),
    created_by  VARCHAR(50)  NOT NULL,
    created_at  TIMESTAMP    NOT NULL DEFAULT now(),
    updated_by  VARCHAR(50),
    updated_at  TIMESTAMP
);

-- ============================================================
-- common_codes 시드 예시 (전체) - 실제 값/명칭은 서비스 정책에 맞게 확정 필요.
-- id는 DEFAULT가 자동 채번하므로 INSERT 시 지정하지 않는다.
-- code는 위 [코드 값 규칙]에 따라 "code_group별 4~5자리 접두어 + 4자리 숫자"로 채번한다
-- (ADMIN, ACTIVE 같은 의미가 읽히는 문자열 대신 opaque한 값을 사용) — 실제 의미는 code_name에만 표시.
-- EVENT(BDTP0003)는 NOTICE(BDTP0001)의 parent_id를 물고 들어가 "공지의 하위 카테고리"를 표현.
-- FAQ 서브카테고리(BDTP0004 배송문의/BDTP0005 결제문의)는 FAQ(BDTP0002)의 parent_id를 물고 들어가는
-- 동일한 방식 — 이 구조가 이미 "게시판마다 하위 카테고리"를 스키마 변경 없이 지원함을 보여주는 예시.
-- ============================================================
-- INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES
--   ('ACCOUNT_TYPE', 'ACTP0001', '관리자', 'system'),
--   ('ACCOUNT_TYPE', 'ACTP0002', '일반회원', 'system'),
--   ('ACCOUNT_STATUS', 'ACST0001', '활성', 'system'),
--   ('ACCOUNT_STATUS', 'ACST0002', '정지', 'system'),
--   ('ACCOUNT_STATUS', 'ACST0003', '탈퇴', 'system'),
--   ('ADMIN_LEVEL', 'ADLV0001', '최고관리자', 'system'),
--   ('ADMIN_LEVEL', 'ADLV0002', '일반관리자', 'system'),
--   ('DEPARTMENT', 'DEPR0001', '운영팀', 'system'),
--   ('DEPARTMENT', 'DEPR0002', '고객지원팀', 'system'),
--   ('COMPANY_APPROVAL_STATUS', 'CAPR0001', '승인대기', 'system'),
--   ('COMPANY_APPROVAL_STATUS', 'CAPR0002', '승인완료', 'system'),
--   ('COMPANY_APPROVAL_STATUS', 'CAPR0003', '승인거절', 'system'),
--   ('COMPANY_GRADE', 'CGRD0001', '일반', 'system'),
--   ('COMPANY_GRADE', 'CGRD0002', '우수', 'system'),
--   ('COMPANY_PERMISSION', 'CPRM0001', '상품관리', 'system'),
--   ('COMPANY_PERMISSION', 'CPRM0002', '주문관리', 'system'),
--   ('COMPANY_PERMISSION', 'CPRM0003', '정산조회', 'system'),
--   ('COMPANY_PERMISSION', 'CPRM0004', '직원관리(직책/권한)', 'system'),
--   ('COMPANY_PERMISSION', 'CPRM0005', '배송관리', 'system'),
--   ('COMPANY_PERMISSION', 'CPRM0006', '회사정보관리', 'system'),
--   ('OWNER_CHANGE_STATUS', 'OWST0001', '접수', 'system'),
--   ('OWNER_CHANGE_STATUS', 'OWST0002', '검토중', 'system'),
--   ('OWNER_CHANGE_STATUS', 'OWST0003', '승인', 'system'),
--   ('OWNER_CHANGE_STATUS', 'OWST0004', '반려', 'system'),
--   ('GENERAL_GRADE', 'GGRD0001', '일반', 'system'),
--   ('GENERAL_GRADE', 'GGRD0002', '실버', 'system'),
--   ('GENERAL_GRADE', 'GGRD0003', '골드', 'system'),
--   ('GENERAL_GRADE', 'GGRD0004', 'VIP', 'system'),
--   ('PRODUCT_STATUS', 'PRST0001', '판매중', 'system'),
--   ('PRODUCT_STATUS', 'PRST0002', '품절', 'system'),
--   ('PRODUCT_STATUS', 'PRST0003', '숨김', 'system'),
--   ('ORDER_STATUS', 'ORST0001', '주문대기', 'system'),
--   ('ORDER_STATUS', 'ORST0002', '결제완료', 'system'),
--   ('ORDER_STATUS', 'ORST0003', '배송중', 'system'),
--   ('ORDER_STATUS', 'ORST0004', '배송완료', 'system'),
--   ('ORDER_STATUS', 'ORST0005', '취소', 'system'),
--   ('PAYMENT_METHOD', 'PYMT0001', '카드', 'system'),
--   ('PAYMENT_METHOD', 'PYMT0002', '계좌이체', 'system'),
--   ('PAYMENT_METHOD', 'PYMT0003', '가상계좌', 'system'),
--   ('PAYMENT_STATUS', 'PYST0001', '대기', 'system'),
--   ('PAYMENT_STATUS', 'PYST0002', '완료', 'system'),
--   ('PAYMENT_STATUS', 'PYST0003', '실패', 'system'),
--   ('PAYMENT_STATUS', 'PYST0004', '환불', 'system'),
--   ('COUPON_ISSUE_TYPE', 'CPIT0001', '공용 코드', 'system'),
--   ('COUPON_ISSUE_TYPE', 'CPIT0002', '개별 발급', 'system'),
--   ('COUPON_DISCOUNT_TYPE', 'CPDT0001', '정률', 'system'),
--   ('COUPON_DISCOUNT_TYPE', 'CPDT0002', '정액', 'system'),
--   ('COUPON_STATUS', 'CPST0001', '사용가능', 'system'),
--   ('COUPON_STATUS', 'CPST0002', '만료', 'system'),
--   ('COUPON_STATUS', 'CPST0003', '중지', 'system'),
--   ('COUPON_SCOPE', 'CPSC0001', '전체상품', 'system'),
--   ('COUPON_SCOPE', 'CPSC0002', '카테고리 한정', 'system'),
--   ('COUPON_SCOPE', 'CPSC0003', '상품 한정', 'system'),
--   ('COUPON_SCOPE', 'CPSC0004', '회사 한정', 'system'),
--   ('ACCOUNT_COUPON_STATUS', 'ACPS0001', '발급됨', 'system'),
--   ('ACCOUNT_COUPON_STATUS', 'ACPS0002', '사용됨', 'system'),
--   ('ACCOUNT_COUPON_STATUS', 'ACPS0003', '만료', 'system'),
--   ('DELIVERY_STATUS', 'DLST0001', '상품준비중', 'system'),
--   ('DELIVERY_STATUS', 'DLST0002', '발송', 'system'),
--   ('DELIVERY_STATUS', 'DLST0003', '배송중', 'system'),
--   ('DELIVERY_STATUS', 'DLST0004', '배송완료', 'system'),
--   ('DELIVERY_STATUS', 'DLST0005', '배송실패', 'system'),
--   ('STOCK_CHANGE_TYPE', 'STCT0001', '입고', 'system'),
--   ('STOCK_CHANGE_TYPE', 'STCT0002', '출고', 'system'),
--   ('STOCK_CHANGE_TYPE', 'STCT0003', '주문차감', 'system'),
--   ('STOCK_CHANGE_TYPE', 'STCT0004', '취소복원', 'system'),
--   ('STOCK_CHANGE_TYPE', 'STCT0005', '재고조정', 'system'),
--   ('SETTLEMENT_STATUS', 'STST0001', '정산대기', 'system'),
--   ('SETTLEMENT_STATUS', 'STST0002', '정산확정', 'system'),
--   ('SETTLEMENT_STATUS', 'STST0003', '지급완료', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0001', '상품관리', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0002', '주문관리', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0003', '회원관리', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0004', '정산관리', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0005', '게시판관리', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0006', '쿠폰관리', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0007', '회사관리(승인/등급)', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0008', '통계/리포트 조회', 'system'),
--   ('ADMIN_PERMISSION', 'APRM0009', '관리자/권한관리', 'system'),
--   ('REACTION_TYPE', 'RCTP0001', '좋아요', 'system'),
--   ('REACTION_TYPE', 'RCTP0002', '싫어요', 'system'),
--   ('OPTION_SELECTION_TYPE', 'OSTP0001', '필수', 'system'),
--   ('OPTION_SELECTION_TYPE', 'OSTP0002', '선택', 'system'),
--   ('OPTION_VALUE_STATUS', 'OVST0001', '판매중', 'system'),
--   ('OPTION_VALUE_STATUS', 'OVST0002', '품절', 'system'),
--   ('OPTION_VALUE_STATUS', 'OVST0003', '단종', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0001', '공지사항 등록', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0002', '이벤트 당첨', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0003', '주문 접수/결제완료', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0004', '배송 시작', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0005', '배송 완료', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0006', '취소/환불 완료', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0007', '쿠폰 발급', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0008', '쿠폰 만료 임박', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0009', '재입고 알림', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0010', '리뷰 작성 요청', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0011', '댓글/대댓글 알림', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0012', '회사 승인 결과', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0013', '정산 완료', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0014', '문의 답변 등록', 'system'),
--   ('NOTIFICATION_TYPE', 'NTTP0015', '대량 등록 처리 결과', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0001', '주문(orders)', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0002', '배송(deliveries)', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0003', '쿠폰(account_coupons)', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0004', '게시물(board_posts)', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0005', '리뷰(reviews)', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0006', '댓글(comments)', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0007', '정산(settlements)', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0008', '회사(companies)', 'system'),
--   ('NOTIFICATION_TARGET_TYPE', 'NTGT0009', '상품(products)', 'system'),
--   ('TERMS_TYPE', 'TRTP0001', '이용약관', 'system'),
--   ('TERMS_TYPE', 'TRTP0002', '개인정보처리방침', 'system'),
--   ('TERMS_TYPE', 'TRTP0003', '마케팅 정보 수신동의', 'system'),
--   ('LOGIN_RESULT', 'LGRS0001', '성공', 'system'),
--   ('LOGIN_RESULT', 'LGRS0002', '실패-비밀번호오류', 'system'),
--   ('LOGIN_RESULT', 'LGRS0003', '실패-계정잠김', 'system'),
--   ('LOGIN_RESULT', 'LGRS0004', '실패-존재하지않는계정', 'system'),
--   ('CLAIM_TYPE', 'CLTP0001', '취소', 'system'),
--   ('CLAIM_TYPE', 'CLTP0002', '반품', 'system'),
--   ('CLAIM_TYPE', 'CLTP0003', '교환', 'system'),
--   ('CLAIM_TYPE', 'CLTP0004', '단순환불', 'system'),
--   ('CLAIM_REASON', 'CLRS0001', '단순변심', 'system'),
--   ('CLAIM_REASON', 'CLRS0002', '상품불량', 'system'),
--   ('CLAIM_REASON', 'CLRS0003', '오배송', 'system'),
--   ('CLAIM_REASON', 'CLRS0004', '배송지연', 'system'),
--   ('CLAIM_REASON', 'CLRS0005', '기타', 'system'),
--   ('CLAIM_STATUS', 'CLST0001', '접수', 'system'),
--   ('CLAIM_STATUS', 'CLST0002', '승인', 'system'),
--   ('CLAIM_STATUS', 'CLST0003', '수거중', 'system'),
--   ('CLAIM_STATUS', 'CLST0004', '수거완료', 'system'),
--   ('CLAIM_STATUS', 'CLST0005', '처리완료', 'system'),
--   ('CLAIM_STATUS', 'CLST0006', '거절', 'system'),
--   ('REFUND_METHOD', 'RFMT0001', '원결제수단', 'system'),
--   ('REFUND_METHOD', 'RFMT0002', '계좌이체', 'system'),
--   ('REFUND_METHOD', 'RFMT0003', '적립금전환', 'system'),
--   ('REFUND_STATUS', 'RFST0001', '요청', 'system'),
--   ('REFUND_STATUS', 'RFST0002', '처리중', 'system'),
--   ('REFUND_STATUS', 'RFST0003', '완료', 'system'),
--   ('REFUND_STATUS', 'RFST0004', '실패', 'system'),
--   ('POINT_CHANGE_TYPE', 'PTCT0001', '구매적립', 'system'),
--   ('POINT_CHANGE_TYPE', 'PTCT0002', '사용', 'system'),
--   ('POINT_CHANGE_TYPE', 'PTCT0003', '소멸', 'system'),
--   ('POINT_CHANGE_TYPE', 'PTCT0004', '관리자지급', 'system'),
--   ('POINT_CHANGE_TYPE', 'PTCT0005', '취소환수', 'system'),
--   ('BANNER_POSITION', 'BNPS0001', '메인 상단', 'system'),
--   ('BANNER_POSITION', 'BNPS0002', '메인 중단', 'system'),
--   ('ADMIN_ACTION_TYPE', 'AATP0001', '생성', 'system'),
--   ('ADMIN_ACTION_TYPE', 'AATP0002', '수정', 'system'),
--   ('ADMIN_ACTION_TYPE', 'AATP0003', '삭제', 'system'),
--   ('ADMIN_ACTION_TYPE', 'AATP0004', '승인', 'system'),
--   ('ADMIN_ACTION_TYPE', 'AATP0005', '거절', 'system'),
--   ('ADMIN_LOG_TARGET_TYPE', 'ALTG0001', '계정(accounts)', 'system'),
--   ('ADMIN_LOG_TARGET_TYPE', 'ALTG0002', '상품(products)', 'system'),
--   ('ADMIN_LOG_TARGET_TYPE', 'ALTG0003', '주문(orders)', 'system'),
--   ('ADMIN_LOG_TARGET_TYPE', 'ALTG0004', '쿠폰(coupons)', 'system'),
--   ('ADMIN_LOG_TARGET_TYPE', 'ALTG0005', '공통코드(common_codes)', 'system'),
--   ('ADMIN_LOG_TARGET_TYPE', 'ALTG0006', '회사(companies)', 'system'),
--   ('BULK_IMPORT_TYPE', 'BITP0001', '상품등록', 'system'),
--   ('BULK_IMPORT_TYPE', 'BITP0002', '송장등록', 'system'),
--   ('BULK_IMPORT_TYPE', 'BITP0003', '재고변경', 'system'),
--   ('BULK_IMPORT_STATUS', 'BIST0001', '업로드됨', 'system'),
--   ('BULK_IMPORT_STATUS', 'BIST0002', '검증중', 'system'),
--   ('BULK_IMPORT_STATUS', 'BIST0003', '일부실패', 'system'),
--   ('BULK_IMPORT_STATUS', 'BIST0004', '반영완료', 'system'),
--   ('BULK_IMPORT_STATUS', 'BIST0005', '취소됨', 'system'),
--   ('BULK_IMPORT_STATUS', 'BIST0006', '만료됨', 'system'),
--   ('IMPORT_ROW_STATUS', 'IRST0001', '대기', 'system'),
--   ('IMPORT_ROW_STATUS', 'IRST0002', '성공', 'system'),
--   ('IMPORT_ROW_STATUS', 'IRST0003', '실패', 'system'),
--   ('BOARD_TYPE', 'BDTP0001', '공지사항', 'system'),
--   ('BOARD_TYPE', 'BDTP0002', 'FAQ', 'system'),
--   ('BOARD_TYPE', 'BDTP0006', '상품문의', 'system');
-- INSERT INTO common_codes (parent_id, code_group, code, code_name, created_by)
--   SELECT id, 'BOARD_TYPE', 'BDTP0003', '이벤트', 'system' FROM common_codes WHERE code = 'BDTP0001';
-- INSERT INTO common_codes (parent_id, code_group, code, code_name, created_by)
--   SELECT id, 'BOARD_TYPE', 'BDTP0004', '배송문의', 'system' FROM common_codes WHERE code = 'BDTP0002';
-- INSERT INTO common_codes (parent_id, code_group, code, code_name, created_by)
--   SELECT id, 'BOARD_TYPE', 'BDTP0005', '결제문의', 'system' FROM common_codes WHERE code = 'BDTP0002';

-- 회사 등급별 정책 시드 예시 (1차 확정 수치 - 실제 오픈 전 재검토)
-- INSERT INTO company_grade_policies (grade_code_id, commission_rate, benefit_description, created_by)
--   SELECT id, 10.00, '기본 수수료율', 'system' FROM common_codes WHERE code = 'CGRD0001'; -- 일반
-- INSERT INTO company_grade_policies (grade_code_id, commission_rate, benefit_description, created_by)
--   SELECT id, 7.00, '수수료 3%p 우대 + 노출 우선순위', 'system' FROM common_codes WHERE code = 'CGRD0002'; -- 우수

-- ============================================================
-- 10차 라운드: 남아있던 운영 정책 항목을 전부 1차로 임의 확정 (사용자 검토용).
-- 대부분 DB 구조 변경이 필요 없는 "값/규칙" 결정이라 코멘트/시드로만 남긴다.
-- ============================================================

-- [반품/교환 배송비 부담 주체 - 1차] CLAIM_REASON.description에 부담 주체를 명시.
-- 원칙: 판매자(회사) 귀책(불량/오배송)은 회사 부담, 그 외(단순변심 등)는 구매자 부담.
-- INSERT INTO common_codes (code_group, code, code_name, description, created_by) VALUES
--   ('CLAIM_REASON', 'CLRS0001', '단순변심', '반품 배송비 구매자 부담', 'system'),
--   ('CLAIM_REASON', 'CLRS0002', '상품불량', '반품 배송비 회사 부담', 'system'),
--   ('CLAIM_REASON', 'CLRS0003', '오배송', '반품 배송비 회사 부담', 'system'),
--   ('CLAIM_REASON', 'CLRS0004', '배송지연', '반품 배송비 회사 부담', 'system'),
--   ('CLAIM_REASON', 'CLRS0005', '기타', '건별 관리자 판단', 'system');
-- (위 5개 코드값은 앞서 이미 시드했으므로 실제 적용 시엔 INSERT가 아니라 description만 채우는
--  UPDATE로 반영 - 여기서는 최종 의도를 보여주기 위해 값까지 함께 표기)

-- [클레임 처리 SLA - 1차] 애플리케이션 정책 (스키마 변경 없음, order_claims.requested_at/processed_at으로 측정 가능)
--   - 단순변심: 접수 후 3일 이내 수거 시작
--   - 불량/오배송: 접수 후 2일 이내 처리 시작 (회사 귀책이라 더 빠르게)
--   - 전체 처리 완료 목표: 접수 후 7일 이내

-- [옵션 전량 품절 시 상품 상태 자동전환 - 1차] 결정: 자동 전환한다.
-- product_option_combinations 전체가 품절/단종이 되면 애플리케이션이 products.status_code_id를
-- PRST0002(품절)로 자동 전환. 옵션이 하나라도 판매중이면 상품은 ON_SALE 유지. (앱 로직, 스키마 변경 없음)

-- [적립금 정책 - 1차] 애플리케이션 설정값 (스키마 변경 없음 - 상수 몇 개만을 위한 테이블은 만들지 않음)
--   - 적립률: 구매 확정 금액의 1% (POINT_CHANGE_TYPE='구매적립' 발생 시 point_histories.points_delta 계산 기준)
--   - 소멸 주기: 적립일로부터 365일 (point_histories.expires_at에 적립 시점 + 365일을 기록)

-- [알림 발송 채널/재시도 - 1차] 애플리케이션/인프라 정책 (스키마 변경 없음)
--   - 기본 채널: 인앱(notifications 테이블) 항상 생성 + 이메일 병행. SMS/카카오톡은 추후 검토
--   - 실패 시 지수 백오프로 최대 3회 재시도, 이후 실패로 종결(인앱 알림 자체는 이미 생성돼 있어 유실 없음)

-- [대량등록 배치 만료 기준 - 1차] BULK_IMPORT_STATUS='업로드됨' 또는 '검증중' 상태로
-- 24시간 경과한 temp_bulk_import_batches는 일간 배치가 '만료됨'으로 전환하고 상세 행을 삭제.

-- [대량등록 엑셀 템플릿 컬럼 순서 - 1차]
--   상품등록(temp_product_import_rows): 상품명 | 카테고리명 | 가격 | 재고수량 | 상품설명 (앞 4개 필수)
--   송장등록(temp_tracking_import_rows): 주문번호 | 택배사 | 운송장번호 (전부 필수)
--   재고/가격변경(temp_stock_import_rows): 상품식별자 | 옵션식별자(선택) | 변경재고수량 | 변경가격(선택)
