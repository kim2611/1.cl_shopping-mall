-- 소프트 삭제(del_yn)와 UNIQUE 제약이 충돌하는 문제 일괄 수정.
--
-- [배경] 이 프로젝트는 모든 테이블에서 물리 삭제 대신 del_yn='Y' 소프트 삭제를 쓴다. 그런데 기존
-- UNIQUE 제약/인덱스는 del_yn을 전혀 고려하지 않아서, 소프트 삭제된 행이 UNIQUE 슬롯을 계속
-- 점유한다. 그 결과 "지웠다가 다시 추가"가 영구히 불가능해진다.
--   실제로 겪은 사례: 장바구니에서 상품을 뺀 뒤(del_yn='Y') 같은 상품을 다시 담으면
--   ux_cart_items_product_option 위반으로 500이 났다.
--
-- [해결] "활성 행(del_yn='N') 중에서만 유일" 이라는 원래 의도대로, 해당 제약들을
-- WHERE del_yn = 'N' 부분 유니크 인덱스로 교체한다.
--
-- [일부러 그대로 둔 것] 아래는 "한 번 쓰인 값은 영구히 점유"가 맞는 제약이라 손대지 않는다:
--   orders.order_number, products.uuid, board_posts.uuid, coupons.code  - 재사용되면 안 되는 식별자
--   payments.order_id, deliveries(order_id,company_id)                  - 지나간 거래/배송 기록
--   settlements(company_id,기간), settlement_items.order_item_id        - 이중 정산 방지가 목적
--   account_coupons(coupon_id,account_id)                               - "계정당 1회"가 핵심 규칙.
--                                                                         소프트 삭제로 재발급이 뚫리면 악용됨
--   account_terms_agreements(account_id,terms_id)                       - 법적 동의 기록
--   common_codes(code_group,code), terms(type_code_id,version)          - 코드/버전은 영구 식별자
--   companies.business_reg_no                                           - 실제 사업자를 가리키는 값(분쟁/감사)

-- 1) 장바구니: 상품을 뺐다가 다시 담기 (이번에 실제로 터진 버그)
DROP INDEX IF EXISTS ux_cart_items_product_option;
CREATE UNIQUE INDEX ux_cart_items_product_option
    ON cart_items (cart_id, product_id, COALESCE(option_combination_id, 'NONE'))
    WHERE del_yn = 'N';

-- 2) 계정당 장바구니 1개: 장바구니를 지우고 새로 만들기
ALTER TABLE carts DROP CONSTRAINT IF EXISTS carts_account_id_key;
CREATE UNIQUE INDEX ux_carts_account ON carts (account_id) WHERE del_yn = 'N';

-- 3) 이메일: 지운 이메일을 다시 등록하기 / 대표 이메일 교체하기
ALTER TABLE account_emails DROP CONSTRAINT IF EXISTS account_emails_email_key;
CREATE UNIQUE INDEX ux_account_emails_email ON account_emails (email) WHERE del_yn = 'N';
DROP INDEX IF EXISTS ux_account_emails_primary;
CREATE UNIQUE INDEX ux_account_emails_primary
    ON account_emails (account_id) WHERE primary_yn = 'Y' AND del_yn = 'N';

-- 4) 기본 배송지 교체 (지우고 다른 주소를 기본으로)
DROP INDEX IF EXISTS ux_addresses_default;
CREATE UNIQUE INDEX ux_addresses_default
    ON addresses (account_id) WHERE default_yn = 'Y' AND del_yn = 'N';

-- 5) 상품 이미지: 이미지를 뺐다가 다시 넣기 / 대표이미지 교체
ALTER TABLE product_files DROP CONSTRAINT IF EXISTS product_files_product_id_file_id_key;
CREATE UNIQUE INDEX ux_product_files_product_file
    ON product_files (product_id, file_id) WHERE del_yn = 'N';
DROP INDEX IF EXISTS ux_product_files_thumbnail;
CREATE UNIQUE INDEX ux_product_files_thumbnail
    ON product_files (product_id) WHERE thumbnail_yn = 'Y' AND del_yn = 'N';

-- 6) 좋아요/싫어요: 취소했다가 다시 누르기
DROP INDEX IF EXISTS ux_reactions_post;
DROP INDEX IF EXISTS ux_reactions_comment;
DROP INDEX IF EXISTS ux_reactions_review;
CREATE UNIQUE INDEX ux_reactions_post
    ON reactions (post_id, account_id) WHERE post_id IS NOT NULL AND del_yn = 'N';
CREATE UNIQUE INDEX ux_reactions_comment
    ON reactions (comment_id, account_id) WHERE comment_id IS NOT NULL AND del_yn = 'N';
CREATE UNIQUE INDEX ux_reactions_review
    ON reactions (review_id, account_id) WHERE review_id IS NOT NULL AND del_yn = 'N';

-- 7) 찜: 해제했다가 다시 찜하기
ALTER TABLE wishlists DROP CONSTRAINT IF EXISTS wishlists_account_id_product_id_key;
CREATE UNIQUE INDEX ux_wishlists_account_product
    ON wishlists (account_id, product_id) WHERE del_yn = 'N';

-- 8) 회사 직원: 탈퇴했다가 재합류
ALTER TABLE company_members DROP CONSTRAINT IF EXISTS company_members_company_id_account_id_key;
CREATE UNIQUE INDEX ux_company_members_company_account
    ON company_members (company_id, account_id) WHERE del_yn = 'N';

-- 9) 회사 직책: 같은 이름의 직책을 지웠다가 다시 만들기
ALTER TABLE company_roles DROP CONSTRAINT IF EXISTS company_roles_company_id_role_name_key;
CREATE UNIQUE INDEX ux_company_roles_company_name
    ON company_roles (company_id, role_name) WHERE del_yn = 'N';

-- 10) 직책 권한: 회수했다가 다시 부여
ALTER TABLE company_role_permissions DROP CONSTRAINT IF EXISTS company_role_permissions_role_id_permission_code_id_key;
CREATE UNIQUE INDEX ux_company_role_permissions_role_permission
    ON company_role_permissions (role_id, permission_code_id) WHERE del_yn = 'N';

-- 11) 관리자 권한: 회수했다가 다시 부여
ALTER TABLE admin_permissions DROP CONSTRAINT IF EXISTS admin_permissions_admin_id_permission_code_id_key;
CREATE UNIQUE INDEX ux_admin_permissions_admin_permission
    ON admin_permissions (admin_id, permission_code_id) WHERE del_yn = 'N';

-- 12) 회사 정책(등급별 수수료/배송비): 정책 행을 갈아끼우기
ALTER TABLE company_grade_policies DROP CONSTRAINT IF EXISTS company_grade_policies_grade_code_id_key;
CREATE UNIQUE INDEX ux_company_grade_policies_grade
    ON company_grade_policies (grade_code_id) WHERE del_yn = 'N';
ALTER TABLE company_shipping_policies DROP CONSTRAINT IF EXISTS company_shipping_policies_company_id_key;
CREATE UNIQUE INDEX ux_company_shipping_policies_company
    ON company_shipping_policies (company_id) WHERE del_yn = 'N';

-- 13) 옵션 조합-옵션값 연결: 조합 구성을 수정하기
ALTER TABLE product_option_combination_values
    DROP CONSTRAINT IF EXISTS product_option_combination_va_combination_id_product_option_key;
CREATE UNIQUE INDEX ux_poc_values_combination_value
    ON product_option_combination_values (combination_id, product_option_value_id) WHERE del_yn = 'N';

-- 14) 알림 설정: 설정 행을 지웠다가 다시 만들기
ALTER TABLE notification_settings
    DROP CONSTRAINT IF EXISTS notification_settings_account_id_notification_type_code_id_key;
CREATE UNIQUE INDEX ux_notification_settings_account_type
    ON notification_settings (account_id, notification_type_code_id) WHERE del_yn = 'N';
