package com.shoppingmall.backend.admin.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.PositiveOrZero;

/** 부분 수정 - null인 필드는 건드리지 않는다. */
public record UpdateProductRequest(
        @PositiveOrZero BigDecimal price,
        @Min(0) Integer stockQuantity,
        /** PRODUCT_STATUS 그룹의 code 값 (PRST0001 판매중 / PRST0002 품절 / PRST0003 숨김). */
        String statusCode) {
}
