package com.shoppingmall.backend.auth.dto;

import lombok.Builder;

@Builder
public record LoginResponse(
        String accountId,
        String name,
        String accessToken,
        String refreshToken) {
}
