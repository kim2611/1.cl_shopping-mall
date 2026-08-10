package com.shoppingmall.backend.auth.dto;

import lombok.Builder;

@Builder
public record LoginResponse(
        String accountId,
        String name,
        /** ADMIN | GENERAL - 클라이언트가 관리자 화면 진입 여부를 판단할 때 쓴다(실제 인가는 서버가 함). */
        String role,
        String accessToken,
        String refreshToken) {
}
