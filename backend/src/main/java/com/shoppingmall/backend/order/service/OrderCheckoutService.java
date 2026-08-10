package com.shoppingmall.backend.order.service;

import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.stereotype.Service;

import com.shoppingmall.backend.common.exception.ApiException;
import com.shoppingmall.backend.common.exception.ErrorCode;
import com.shoppingmall.backend.order.dto.CreateOrderRequest;
import com.shoppingmall.backend.order.dto.OrderResponse;
import com.shoppingmall.backend.order.repository.OrderRepository;

/**
 * 주문 생성의 멱등 처리 담당.
 *
 * <p>일부러 트랜잭션 밖에 둔다 - 멱등 키 충돌은 DB 유니크 제약 위반으로 나타나는데, 그 순간
 * 진행 중이던 트랜잭션은 롤백 대상이 되어 같은 트랜잭션 안에서는 "이미 만들어진 주문"을 다시
 * 조회할 수 없다. 그래서 실제 주문 생성(OrderService.createOrder)은 자기 트랜잭션에서 끝내고,
 * 충돌 복구(재조회)는 그 트랜잭션이 끝난 뒤 여기서 한다.
 */
@Service
public class OrderCheckoutService {

    private final OrderService orderService;
    private final OrderRepository orderRepository;

    public OrderCheckoutService(OrderService orderService, OrderRepository orderRepository) {
        this.orderService = orderService;
        this.orderRepository = orderRepository;
    }

    public OrderResponse checkout(String accountId, String idempotencyKey, CreateOrderRequest request) {
        // 키가 없으면 멱등 보장 없이 그대로 진행 (구버전 클라이언트 호환).
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            return orderService.createOrder(accountId, null, request);
        }

        // 1) 이미 같은 키로 만든 주문이 있으면 그대로 돌려준다 (재시도/뒤늦은 중복 요청).
        OrderResponse existing = findExisting(accountId, idempotencyKey);
        if (existing != null) {
            return existing;
        }

        try {
            return orderService.createOrder(accountId, idempotencyKey, request);
        } catch (DataIntegrityViolationException e) {
            // 2) 거의 동시에 들어온 중복 요청이라 1)에서는 못 찾고 INSERT에서 부딪힌 경우.
            //    먼저 성공한 쪽의 주문을 찾아 같은 결과를 돌려준다.
            OrderResponse created = findExisting(accountId, idempotencyKey);
            if (created != null) {
                return created;
            }
            throw e; // 멱등 키와 무관한 제약 위반이면 그대로 올린다
        }
    }

    private OrderResponse findExisting(String accountId, String idempotencyKey) {
        return orderRepository.findByAccountIdAndIdempotencyKeyAndDelYn(accountId, idempotencyKey, "N")
                .map(order -> {
                    try {
                        return orderService.getMyOrder(accountId, order.getOrderNumber());
                    } catch (ApiException e) {
                        if (e.getErrorCode() == ErrorCode.NOT_FOUND) {
                            return null;
                        }
                        throw e;
                    }
                })
                .orElse(null);
    }
}
