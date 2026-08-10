-- 주문/결제/배송에 필요한 공통코드 시드 + 주문번호 채번용 시퀀스 + 테스트 회사 배송비 정책.
-- V2에서는 로그인/상품 조회에 필요한 코드만 넣었어서, 주문 기능에 필요한 그룹을 여기서 채운다.

INSERT INTO common_codes (code_group, code, code_name, sort_order, created_by) VALUES
  ('ORDER_STATUS', 'ORST0001', '주문대기',   1, 'seed'),
  ('ORDER_STATUS', 'ORST0002', '결제완료',   2, 'seed'),
  ('ORDER_STATUS', 'ORST0003', '배송중',     3, 'seed'),
  ('ORDER_STATUS', 'ORST0004', '배송완료',   4, 'seed'),
  ('ORDER_STATUS', 'ORST0005', '취소',       5, 'seed'),

  ('PAYMENT_METHOD', 'PYMT0001', '카드',      1, 'seed'),
  ('PAYMENT_METHOD', 'PYMT0002', '계좌이체',  2, 'seed'),
  ('PAYMENT_METHOD', 'PYMT0003', '가상계좌',  3, 'seed'),

  ('PAYMENT_STATUS', 'PYST0001', '대기',      1, 'seed'),
  ('PAYMENT_STATUS', 'PYST0002', '완료',      2, 'seed'),
  ('PAYMENT_STATUS', 'PYST0003', '실패',      3, 'seed'),
  ('PAYMENT_STATUS', 'PYST0004', '환불',      4, 'seed'),

  ('DELIVERY_STATUS', 'DLST0001', '상품준비중', 1, 'seed'),
  ('DELIVERY_STATUS', 'DLST0002', '발송',       2, 'seed'),
  ('DELIVERY_STATUS', 'DLST0003', '배송중',     3, 'seed'),
  ('DELIVERY_STATUS', 'DLST0004', '배송완료',   4, 'seed'),
  ('DELIVERY_STATUS', 'DLST0005', '배송실패',   5, 'seed'),

  ('STOCK_CHANGE_TYPE', 'STCT0001', '입고',      1, 'seed'),
  ('STOCK_CHANGE_TYPE', 'STCT0002', '출고',      2, 'seed'),
  ('STOCK_CHANGE_TYPE', 'STCT0003', '주문차감',  3, 'seed'),
  ('STOCK_CHANGE_TYPE', 'STCT0004', '취소복원',  4, 'seed'),
  ('STOCK_CHANGE_TYPE', 'STCT0005', '재고조정',  5, 'seed');

-- 주문번호(order_number)는 사용자에게 보여주는 값이라 내부 PK와 별개로 채번한다.
-- PK와 달리 DEFAULT로 만들 수 없어(형식이 'ORD+날짜+일련번호') 애플리케이션이 이 시퀀스를 읽어 조립한다.
CREATE SEQUENCE IF NOT EXISTS SEQ_ORDER_NUMBER_01;

-- 테스트 회사의 배송비 정책 (기본값 그대로 - 3,000원 / 30,000원 이상 무료).
-- 정책 행이 없으면 애플리케이션이 코드 기본값으로 폴백하지만, 실제 흐름을 그대로 태우려고 시드해둔다.
INSERT INTO company_shipping_policies (company_id, created_by)
SELECT id, 'seed' FROM companies WHERE business_reg_no = '000-00-00000';
