package com.shoppingmall.backend.order.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import lombok.Builder;

/** 주문 목록용 요약 - 대표 상품명 + 나머지 개수로 "오버사이즈 코튼 셔츠 외 2건" 형태를 만든다. */
@Builder
public record OrderSummaryResponse(
        String orderNumber,
        String statusName,
        LocalDateTime orderedAt,
        String representativeProductName,
        Integer itemCount,
        BigDecimal totalAmount,
        String thumbnailUrl) {
}
