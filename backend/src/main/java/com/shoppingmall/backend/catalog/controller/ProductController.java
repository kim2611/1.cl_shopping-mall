package com.shoppingmall.backend.catalog.controller;

import java.util.UUID;

import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PageableDefault;
import org.springframework.data.web.PagedModel;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.shoppingmall.backend.catalog.dto.ProductDetailResponse;
import com.shoppingmall.backend.catalog.dto.ProductSummaryResponse;
import com.shoppingmall.backend.catalog.service.ProductService;

@RestController
@RequestMapping("/api/products")
public class ProductController {

    private final ProductService productService;

    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    /**
     * sortBy: new(최신순, 기본값) | priceAsc(낮은가격순) | priceDesc(높은가격순).
     * "인기순"은 아직 뒷받침할 지표(판매량/조회수 등)가 없어 제외 - 나중에 추가.
     * 파라미터명을 "sort"가 아니라 "sortBy"로 둔 이유: "sort"는 Spring Data의 Pageable
     * 리졸버가 페이지네이션 정렬용으로 이미 예약해 쓰는 이름이라 겹치면 우리 의도와 다른
     * order by가 같이 붙어버린다 (실제로 겪은 버그).
     */
    @GetMapping
    public PagedModel<ProductSummaryResponse> list(
            @RequestParam(required = false) String categoryId,
            @RequestParam(defaultValue = "new") String sortBy,
            @PageableDefault(size = 20) Pageable pageable) {
        return productService.list(categoryId, sortBy, pageable);
    }

    @GetMapping("/{uuid}")
    public ProductDetailResponse detail(@PathVariable UUID uuid) {
        return productService.detail(uuid);
    }
}
