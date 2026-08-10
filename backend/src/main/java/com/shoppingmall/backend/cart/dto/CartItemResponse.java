package com.shoppingmall.backend.cart.dto;

import java.math.BigDecimal;
import java.util.UUID;

import lombok.Builder;

@Builder
public record CartItemResponse(
        String cartItemId,
        UUID productUuid,
        String productName,
        BigDecimal price,
        Integer quantity,
        BigDecimal lineAmount,
        Integer stockQuantity,
        String thumbnailUrl) {
}
