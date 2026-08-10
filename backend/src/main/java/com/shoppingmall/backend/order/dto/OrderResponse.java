package com.shoppingmall.backend.order.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import lombok.Builder;

@Builder
public record OrderResponse(
        String orderNumber,
        String statusName,
        LocalDateTime orderedAt,
        String recipientName,
        String phone,
        String zipCode,
        String address1,
        String address2,
        List<OrderItemResponse> items,
        BigDecimal itemsAmount,
        BigDecimal deliveryFee,
        BigDecimal discountAmount,
        BigDecimal totalAmount,
        String paymentMethodName,
        String paymentStatusName) {
}
