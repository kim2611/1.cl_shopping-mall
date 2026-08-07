package com.shoppingmall.backend.catalog.service;

import java.util.List;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PagedModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.shoppingmall.backend.catalog.dto.ProductDetailResponse;
import com.shoppingmall.backend.catalog.dto.ProductListRow;
import com.shoppingmall.backend.catalog.dto.ProductSummaryResponse;
import com.shoppingmall.backend.catalog.entity.Category;
import com.shoppingmall.backend.catalog.entity.Product;
import com.shoppingmall.backend.catalog.repository.CategoryRepository;
import com.shoppingmall.backend.catalog.repository.ProductFileRepository;
import com.shoppingmall.backend.catalog.repository.ProductRepository;
import com.shoppingmall.backend.code.entity.CommonCode;
import com.shoppingmall.backend.code.repository.CommonCodeRepository;
import com.shoppingmall.backend.common.exception.ApiException;
import com.shoppingmall.backend.common.exception.ErrorCode;
import com.shoppingmall.backend.common.storage.StorageService;

@Service
@Transactional(readOnly = true)
public class ProductService {

    private final ProductRepository productRepository;
    private final ProductFileRepository productFileRepository;
    private final CategoryRepository categoryRepository;
    private final CommonCodeRepository commonCodeRepository;
    private final StorageService storageService;

    public ProductService(
            ProductRepository productRepository,
            ProductFileRepository productFileRepository,
            CategoryRepository categoryRepository,
            CommonCodeRepository commonCodeRepository,
            StorageService storageService) {
        this.productRepository = productRepository;
        this.productFileRepository = productFileRepository;
        this.categoryRepository = categoryRepository;
        this.commonCodeRepository = commonCodeRepository;
        this.storageService = storageService;
    }

    public PagedModel<ProductSummaryResponse> list(String categoryId, String sort, Pageable pageable) {
        // 정렬은 sortBy로만 결정한다 - Pageable에 우연히 Sort가 실려 있어도(예: 클라이언트가 실수로
        // ?sort= 를 같이 보낸 경우) 무시하고 페이지 번호/크기만 사용한다.
        Pageable unsortedPage = PageRequest.of(pageable.getPageNumber(), pageable.getPageSize());
        Page<ProductListRow> rows = switch (sort) {
            case "priceAsc" -> productRepository.findSummariesPriceAsc(categoryId, unsortedPage);
            case "priceDesc" -> productRepository.findSummariesPriceDesc(categoryId, unsortedPage);
            default -> productRepository.findSummariesLatest(categoryId, unsortedPage);
        };

        Page<ProductSummaryResponse> mapped = rows.map(row -> ProductSummaryResponse.builder()
                .uuid(row.uuid())
                .name(row.name())
                .price(row.price())
                .thumbnailUrl(row.thumbnailStoredPath() == null ? null : storageService.publicUrl(row.thumbnailStoredPath()))
                .build());

        return new PagedModel<>(mapped);
    }

    public ProductDetailResponse detail(UUID uuid) {
        Product product = productRepository.findByUuidAndDelYn(uuid, "N")
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "상품을 찾을 수 없습니다."));

        String categoryName = categoryRepository.findById(product.getCategoryId())
                .map(Category::getName)
                .orElse(null);
        String statusName = commonCodeRepository.findById(product.getStatusCodeId())
                .map(CommonCode::getCodeName)
                .orElse(null);
        List<String> imageUrls = productFileRepository.findImagePaths(product.getId()).stream()
                .map(storageService::publicUrl)
                .toList();

        return ProductDetailResponse.builder()
                .uuid(product.getUuid())
                .name(product.getName())
                .description(product.getDescription())
                .price(product.getPrice())
                .stockQuantity(product.getStockQuantity())
                .categoryName(categoryName)
                .statusName(statusName)
                .imageUrls(imageUrls)
                .build();
    }
}
