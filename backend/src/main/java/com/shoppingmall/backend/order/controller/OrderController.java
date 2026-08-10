package com.shoppingmall.backend.order.controller;

import java.util.List;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.shoppingmall.backend.order.dto.CreateOrderRequest;
import com.shoppingmall.backend.order.dto.OrderResponse;
import com.shoppingmall.backend.order.dto.OrderSummaryResponse;
import com.shoppingmall.backend.order.service.OrderService;

import jakarta.validation.Valid;

/** 전부 인증 필수. 주문은 외부에 내부 PK 대신 order_number로 노출한다. */
@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderService orderService;

    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }

    @PostMapping
    public ResponseEntity<OrderResponse> create(
            Authentication authentication, @Valid @RequestBody CreateOrderRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(orderService.createOrder(authentication.getName(), request));
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
