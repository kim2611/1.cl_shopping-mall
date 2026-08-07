package com.shoppingmall.backend.catalog.dto;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import lombok.Builder;

@Builder
public record ProductDetailResponse(
        UUID uuid,
        String name,
        String description,
        BigDecimal price,
        Integer stockQuantity,
        String categoryName,
        String statusName,
        List<String> imageUrls) {
}
