package com.shoppingmall.backend.cart.controller;

import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.shoppingmall.backend.cart.dto.AddCartItemRequest;
import com.shoppingmall.backend.cart.dto.CartResponse;
import com.shoppingmall.backend.cart.dto.UpdateCartItemRequest;
import com.shoppingmall.backend.cart.service.CartService;

import jakarta.validation.Valid;

/** 전부 보호된 엔드포인트 - SecurityConfig의 공개 경로에 포함시키지 않아 Authorization 헤더가 필수다. */
@RestController
@RequestMapping("/api/cart")
public class CartController {

    private final CartService cartService;

    public CartController(CartService cartService) {
        this.cartService = cartService;
    }

    @GetMapping
    public CartResponse getCart(Authentication authentication) {
        return cartService.getCart(authentication.getName());
    }

    @PostMapping("/items")
    public CartResponse addItem(Authentication authentication, @Valid @RequestBody AddCartItemRequest request) {
        return cartService.addItem(authentication.getName(), request);
    }

    @PatchMapping("/items/{cartItemId}")
    public CartResponse updateItem(
            Authentication authentication,
            @PathVariable String cartItemId,
            @Valid @RequestBody UpdateCartItemRequest request) {
        return cartService.updateItem(authentication.getName(), cartItemId, request);
    }

    @DeleteMapping("/items/{cartItemId}")
    public CartResponse removeItem(Authentication authentication, @PathVariable String cartItemId) {
        return cartService.removeItem(authentication.getName(), cartItemId);
    }
}
