package com.shoppingmall.backend.admin.dto;

import java.math.BigDecimal;
import java.util.UUID;

import lombok.Builder;

@Builder
public record AdminProductRow(
        UUID uuid,
        String name,
        String categoryName,
        BigDecimal price,
        Integer stockQuantity,
        String statusName,
        String statusCode,
        String thumbnailUrl) {
}
