package com.shoppingmall.backend.cart.dto;

import java.util.UUID;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;

/** 상품은 내부 PK가 아니라 외부 공개 식별자(uuid)로 지정한다 - 보안 규칙(IDOR 대비). */
public record AddCartItemRequest(
        @NotNull UUID productUuid,
        @NotNull @Min(1) @Max(99) Integer quantity) {
}
