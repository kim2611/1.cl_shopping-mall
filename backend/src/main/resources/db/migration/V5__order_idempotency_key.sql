-- 주문 중복 생성 방지(Idempotency).
--
-- [배경] 버튼 더블탭이나 네트워크 재시도로 POST /api/orders가 두 번 도달하면 주문이 두 건 생기고
-- 재고도 두 번 깎였다. 클라이언트가 보낸 Idempotency-Key를 주문에 함께 저장하고, 같은 계정 + 같은 키는
-- DB 유니크 인덱스로 한 건만 존재하도록 강제한다(경합 시 늦은 쪽이 제약에 걸리고, 앱은 먼저 만들어진
-- 주문을 그대로 돌려준다).
--
-- 키를 별도 테이블로 빼지 않고 orders 컬럼으로 둔 이유: 키의 수명이 곧 주문의 수명이고,
-- "이 주문이 어떤 요청으로 만들어졌는지"를 주문 레코드 옆에 두는 편이 추적에 낫다.
ALTER TABLE orders ADD COLUMN IF NOT EXISTS idempotency_key VARCHAR(64);

COMMENT ON COLUMN orders.idempotency_key IS '주문 생성 요청의 멱등 키(클라이언트 생성). 미전달 시 NULL.';

-- V3에서 정리한 원칙대로 소프트 삭제된 행은 슬롯을 점유하지 않게 부분 인덱스로 만든다.
CREATE UNIQUE INDEX IF NOT EXISTS ux_orders_account_idempotency
    ON orders (account_id, idempotency_key)
    WHERE idempotency_key IS NOT NULL AND del_yn = 'N';
