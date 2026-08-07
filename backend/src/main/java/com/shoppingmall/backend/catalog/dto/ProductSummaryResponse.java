package com.shoppingmall.backend.catalog.dto;

import java.math.BigDecimal;
import java.util.UUID;

import lombok.Builder;

@Builder
public record ProductSummaryResponse(
        UUID uuid,
        String name,
        BigDecimal price,
        String thumbnailUrl) {
}
