package com.shoppingmall.backend.security;

import java.io.IOException;
import java.util.List;

import org.jspecify.annotations.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * Authorization: Bearer 헤더의 access 토큰을 검증해 SecurityContext에 인증 정보를 채운다.
 * 지금은 보호된 엔드포인트가 없지만(로그인만 구현), 앞으로 추가될 API를 위한 공통 인프라.
 */
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    public JwtAuthenticationFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(
            @NonNull HttpServletRequest request,
            @NonNull HttpServletResponse response,
            @NonNull FilterChain filterChain) throws ServletException, IOException {

        String header = request.getHeader("Authorization");
        if (header != null && header.startsWith("Bearer ")) {
            try {
                Claims claims = jwtService.parse(header.substring(7));
                if ("access".equals(claims.get("tokenType", String.class))) {
                    String accountId = claims.getSubject();
                    String role = claims.get("role", String.class);

                    // role 클레임이 없는 옛 토큰은 일반 회원으로 간주 (관리자 권한은 주지 않음)
                    var authorities = List.of(new SimpleGrantedAuthority("ROLE_" + (role == null ? "GENERAL" : role)));
                    var authentication = new UsernamePasswordAuthenticationToken(accountId, null, authorities);
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                }
            } catch (JwtException | IllegalArgumentException ignored) {
                // 유효하지 않은 토큰이면 그냥 미인증 상태로 흘려보내고, 이후 authorizeHttpRequests가 막는다.
            }
        }

        filterChain.doFilter(request, response);
    }
}
