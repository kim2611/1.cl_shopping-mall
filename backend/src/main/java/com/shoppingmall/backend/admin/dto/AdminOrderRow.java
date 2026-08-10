package com.shoppingmall.backend.admin.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import lombok.Builder;

@Builder
public record AdminOrderRow(
        String orderNumber,
        LocalDateTime orderedAt,
        String buyerName,
        String recipientName,
        Integer itemCount,
        BigDecimal totalAmount,
        String statusName,
        String statusCode) {
}
