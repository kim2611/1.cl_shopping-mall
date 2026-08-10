package com.shoppingmall.backend.admin.dto;

import java.math.BigDecimal;

import lombok.Builder;

@Builder
public record AdminStatsResponse(
        long orderCount,
        /** 결제 완료 합계 - 환불 완료 합계 (ERD 13차 라운드에서 정한 순매출 공식). */
        BigDecimal netRevenue,
        long productCount,
        long memberCount,
        long lowStockCount) {
}
