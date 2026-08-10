package com.shoppingmall.backend.order.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.shoppingmall.backend.order.dto.CreateOrderRequest;
import com.shoppingmall.backend.order.dto.OrderResponse;
import com.shoppingmall.backend.order.dto.OrderSummaryResponse;
import com.shoppingmall.backend.order.service.OrderCheckoutService;
import com.shoppingmall.backend.order.service.OrderService;

import jakarta.validation.Valid;

/** 전부 인증 필수. 주문은 외부에 내부 PK 대신 order_number로 노출한다. */
@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService orderService;
    private final OrderCheckoutService orderCheckoutService;

    public OrderController(OrderService orderService, OrderCheckoutService orderCheckoutService) {
        this.orderService = orderService;
        this.orderCheckoutService = orderCheckoutService;
    }

    /**
     * Idempotency-Key 헤더를 보내면 같은 키의 재요청은 주문을 새로 만들지 않고 처음 만든 주문을 그대로 돌려준다
     * (버튼 더블탭/네트워크 재시도 대비). 헤더가 없으면 기존처럼 매번 새 주문이 생긴다.
     */
    @PostMapping
    public ResponseEntity<OrderResponse> create(
            Authentication authentication,
            @RequestHeader(value = "Idempotency-Key", required = false) String idempotencyKey,
            @Valid @RequestBody CreateOrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(orderCheckoutService.checkout(authentication.getName(), idempotencyKey, request));
    }

    @GetMapping
    public List<OrderSummaryResponse> myOrders(Authentication authentication) {
        return orderService.listMyOrders(authentication.getName());
    }

    @GetMapping("/{orderNumber}")
    public OrderResponse detail(Authentication authentication, @PathVariable String orderNumber) {
        return orderService.getMyOrder(authentication.getName(), orderNumber);
    }
}
