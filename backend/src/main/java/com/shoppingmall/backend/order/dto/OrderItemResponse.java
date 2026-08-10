package com.shoppingmall.backend.order.dto;

import java.math.BigDecimal;
import java.util.UUID;

import lombok.Builder;

@Builder
public record OrderItemResponse(
        String orderItemId,
        UUID productUuid,
        String productName,
        String optionSummary,
        Integer quantity,
        BigDecimal price,
        BigDecimal lineAmount,
        String thumbnailUrl) {
}
