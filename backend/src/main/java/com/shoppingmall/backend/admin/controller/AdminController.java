package com.shoppingmall.backend.admin.controller;

import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.PagedModel;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.shoppingmall.backend.admin.dto.AdminOrderRow;
import com.shoppingmall.backend.admin.dto.AdminProductRow;
import com.shoppingmall.backend.admin.dto.AdminStatsResponse;
import com.shoppingmall.backend.admin.dto.UpdateOrderStatusRequest;
import com.shoppingmall.backend.admin.dto.UpdateProductRequest;
import com.shoppingmall.backend.admin.service.AdminService;

import jakarta.validation.Valid;

/** /api/admin/** 는 SecurityConfig에서 ROLE_ADMIN만 통과하도록 막혀 있다. */
@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final AdminService adminService;

    public AdminController(AdminService adminService) {
        this.adminService = adminService;
    }

    @GetMapping("/stats")
    public AdminStatsResponse stats() {
        return adminService.stats();
    }

    @GetMapping("/orders")
    public PagedModel<AdminOrderRow> orders(@PageableDefault(size = 20) Pageable pageable) {
        return adminService.orders(pageable);
    }

    @PatchMapping("/orders/{orderNumber}/status")
    public AdminOrderRow updateOrderStatus(
            Authentication authentication,
            @PathVariable String orderNumber,
            @Valid @RequestBody UpdateOrderStatusRequest request) {
        return adminService.updateOrderStatus(authentication.getName(), orderNumber, request);
    }

    @GetMapping("/products")
    public PagedModel<AdminProductRow> products(@PageableDefault(size = 20) Pageable pageable) {
        return adminService.products(pageable);
    }

    @PatchMapping("/products/{uuid}")
    public AdminProductRow updateProduct(
            Authentication authentication,
            @PathVariable UUID uuid,
            @Valid @RequestBody UpdateProductRequest request) {
        return adminService.updateProduct(authentication.getName(), uuid, request);
    }
}
