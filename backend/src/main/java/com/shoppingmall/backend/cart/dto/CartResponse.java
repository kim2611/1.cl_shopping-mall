package com.shoppingmall.backend.cart.dto;

import java.math.BigDecimal;
import java.util.List;

import lombok.Builder;

@Builder
public record CartResponse(
        String cartId,
        List<CartItemResponse> items,
        Integer totalQuantity,
        BigDecimal totalAmount) {
}
