package com.shoppingmall.backend.auth.controller;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.shoppingmall.backend.auth.dto.LoginRequest;
import com.shoppingmall.backend.auth.dto.LoginResponse;
import com.shoppingmall.backend.auth.dto.MeResponse;
import com.shoppingmall.backend.auth.dto.SignupRequest;
import com.shoppingmall.backend.auth.service.AuthService;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService authService;

    public AuthController(AuthService authService) {
        this.authService = authService;
    }

    @PostMapping("/login")
    public LoginResponse login(@Valid @RequestBody LoginRequest request) {
        return authService.login(request);
    }

    @PostMapping("/signup")
    public ResponseEntity<LoginResponse> signup(@Valid @RequestBody SignupRequest request) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.signup(request));
    }

    /** 보호된 엔드포인트 - Authorization: Bearer 필요. JwtAuthenticationFilter가 principal=accountId로 채워둔다. */
    @GetMapping("/me")
    public MeResponse me(Authentication authentication) {
        return authService.me(authentication.getName());
    }
}
