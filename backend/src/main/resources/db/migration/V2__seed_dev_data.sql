-- 개발/테스트용 시드 데이터. 관리자 로그인 테스트 계정 1개 + 더미 회사/카테고리/상품 10개.
-- 비밀번호는 BCrypt 해시. 평문: admin@mall.test / Mall!2026 (관리자), seller@mall.test / Seller!2026 (더미 판매자, FK 충족용)

DO $$
DECLARE
  v_code_account_type_admin   VARCHAR(17);
  v_code_account_type_general VARCHAR(17);
  v_code_account_status_active VARCHAR(17);
  v_code_admin_level_super    VARCHAR(17);
  v_code_general_grade        VARCHAR(17);
  v_code_company_approval_ok  VARCHAR(17);
  v_code_company_grade        VARCHAR(17);
  v_code_product_status_onsale VARCHAR(17);

  v_admin_account_id VARCHAR(17);
  v_owner_account_id VARCHAR(17);
  v_company_id       VARCHAR(17);

  v_cat_top    VARCHAR(17);
  v_cat_bottom VARCHAR(17);
  v_cat_outer  VARCHAR(17);
  v_cat_acc    VARCHAR(17);

  v_product_id VARCHAR(17);
  v_file_id    UUID;
BEGIN
  -- 로그인/상품 시드에 필요한 최소 공통코드
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('ACCOUNT_TYPE','ACTP0001','관리자','seed') RETURNING id INTO v_code_account_type_admin;
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('ACCOUNT_TYPE','ACTP0002','일반회원','seed') RETURNING id INTO v_code_account_type_general;
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('ACCOUNT_STATUS','ACST0001','활성','seed') RETURNING id INTO v_code_account_status_active;
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('ACCOUNT_STATUS','ACST0002','정지','seed');
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('ACCOUNT_STATUS','ACST0003','탈퇴','seed');
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('ADMIN_LEVEL','ADLV0001','최고관리자','seed') RETURNING id INTO v_code_admin_level_super;
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('ADMIN_LEVEL','ADLV0002','일반관리자','seed');
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('GENERAL_GRADE','GGRD0001','일반','seed') RETURNING id INTO v_code_general_grade;
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('COMPANY_APPROVAL_STATUS','CAPR0001','승인대기','seed');
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('COMPANY_APPROVAL_STATUS','CAPR0002','승인완료','seed') RETURNING id INTO v_code_company_approval_ok;
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('COMPANY_GRADE','CGRD0001','일반','seed') RETURNING id INTO v_code_company_grade;
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('PRODUCT_STATUS','PRST0001','판매중','seed') RETURNING id INTO v_code_product_status_onsale;
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('PRODUCT_STATUS','PRST0002','품절','seed');
  INSERT INTO common_codes (code_group, code, code_name, created_by) VALUES ('PRODUCT_STATUS','PRST0003','숨김','seed');

  -- 관리자 테스트 계정 (admin@mall.test / Mall!2026)
  INSERT INTO accounts (password, name, account_type_code_id, status_code_id, created_by)
    VALUES ('$2b$10$YSIO6wiua0fRBzdGqbYS5.wsTbDHcsGs.59lMk4uSsP3zSbcWehwa', '관리자', v_code_account_type_admin, v_code_account_status_active, 'seed')
    RETURNING id INTO v_admin_account_id;
  INSERT INTO admins (account_id, admin_level_code_id, created_by) VALUES (v_admin_account_id, v_code_admin_level_super, 'seed');
  INSERT INTO account_emails (account_id, email, primary_yn, created_by) VALUES (v_admin_account_id, 'admin@mall.test', 'Y', 'seed');

  -- 더미 판매자 계정 - products.company_id FK를 만족시키기 위한 소유주일 뿐, 테스트 로그인 대상 아님
  INSERT INTO accounts (password, name, account_type_code_id, status_code_id, created_by)
    VALUES ('$2b$10$vsle7u1ZSsTFv0bTZE3K2.OY3MEcjTQRNCv5esOTP31huHdhD7be.', '테스트셀러', v_code_account_type_general, v_code_account_status_active, 'seed')
    RETURNING id INTO v_owner_account_id;
  INSERT INTO general_accounts (account_id, grade_code_id, created_by) VALUES (v_owner_account_id, v_code_general_grade, 'seed');
  INSERT INTO account_emails (account_id, email, primary_yn, created_by) VALUES (v_owner_account_id, 'seller@mall.test', 'Y', 'seed');

  -- 더미 회사
  INSERT INTO companies (business_name, business_reg_no, approval_status_code_id, grade_code_id, owner_account_id, created_by)
    VALUES ('MALL 테스트 스토어', '000-00-00000', v_code_company_approval_ok, v_code_company_grade, v_owner_account_id, 'seed')
    RETURNING id INTO v_company_id;

  -- 카테고리
  INSERT INTO categories (name, sort_order, created_by) VALUES ('상의', 1, 'seed') RETURNING id INTO v_cat_top;
  INSERT INTO categories (name, sort_order, created_by) VALUES ('하의', 2, 'seed') RETURNING id INTO v_cat_bottom;
  INSERT INTO categories (name, sort_order, created_by) VALUES ('아우터', 3, 'seed') RETURNING id INTO v_cat_outer;
  INSERT INTO categories (name, sort_order, created_by) VALUES ('잡화', 4, 'seed') RETURNING id INTO v_cat_acc;

  -- 상품 1: 오버사이즈 코튼 셔츠
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_top, '오버사이즈 코튼 셔츠', '오버사이즈 핏의 두꺼운 코튼 셔츠', 39000, 50, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('01-shirt.svg', 'products/01-shirt.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 2: 크루넥 스웨트셔츠
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_top, '크루넥 스웨트셔츠', '기모 안감의 기본 크루넥 스웨트셔츠', 42000, 40, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('02-sweatshirt.svg', 'products/02-sweatshirt.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 3: 스트라이프 니트
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_top, '스트라이프 니트', '얇은 스트라이프 패턴의 니트 상의', 46000, 35, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('03-knit.svg', 'products/03-knit.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 4: 와이드 팬츠
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_bottom, '와이드 팬츠', '통이 넉넉한 와이드 핏 팬츠', 52000, 45, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('04-wide-pants.svg', 'products/04-wide-pants.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 5: 스트레이트 데님 팬츠
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_bottom, '스트레이트 데님 팬츠', '기본 스트레이트 핏 데님', 58000, 60, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('05-denim.svg', 'products/05-denim.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 6: 니트 가디건
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_outer, '니트 가디건', '가볍게 걸치기 좋은 니트 가디건', 45000, 30, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('06-cardigan.svg', 'products/06-cardigan.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 7: 울 블렌드 코트
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_outer, '울 블렌드 코트', '가을·겨울용 울 혼방 롱코트', 189000, 15, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('07-coat.svg', 'products/07-coat.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 8: 레더 벨트
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_acc, '레더 벨트', '심플한 정장·캐주얼 겸용 가죽 벨트', 28000, 70, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('08-belt.svg', 'products/08-belt.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 9: 캔버스 토트백
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_acc, '캔버스 토트백', '데일리로 메기 좋은 캔버스 토트백', 35000, 55, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('09-tote.svg', 'products/09-tote.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

  -- 상품 10: 스니커즈
  INSERT INTO products (company_id, category_id, name, description, price, stock_quantity, status_code_id, created_by)
    VALUES (v_company_id, v_cat_acc, '스니커즈', '어디에나 무난하게 신을 수 있는 로우탑 스니커즈', 68000, 80, v_code_product_status_onsale, 'seed')
    RETURNING id INTO v_product_id;
  INSERT INTO files (original_name, stored_path, mime_type, size_bytes, uploaded_by, created_by)
    VALUES ('10-sneakers.svg', 'products/10-sneakers.svg', 'image/svg+xml', 2000, v_admin_account_id, 'seed') RETURNING id INTO v_file_id;
  INSERT INTO product_files (product_id, file_id, thumbnail_yn, created_by) VALUES (v_product_id, v_file_id, 'Y', 'seed');

END $$;
