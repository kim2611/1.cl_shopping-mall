package com.shoppingmall.backend.cart.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** CartItemRepository의 목록 조회 JPQL이 바로 채우는 로우 프로젝션 (thumbnailStoredPath는 URL 변환 전 원본 경로). */
public record CartItemRow(
        String cartItemId,
        UUID productUuid,
        String productName,
        BigDecimal price,
        Integer quantity,
        Integer stockQuantity,
        String thumbnailStoredPath) {
}
