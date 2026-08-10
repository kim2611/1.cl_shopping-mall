package com.shoppingmall.backend.auth.dto;

import lombok.Builder;

@Builder
public record MeResponse(
        String accountId,
        String name,
        String email) {
}
