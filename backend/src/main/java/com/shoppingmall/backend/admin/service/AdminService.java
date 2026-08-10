package com.shoppingmall.backend.admin.service;

import java.math.BigDecimal;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.web.PagedModel;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.shoppingmall.backend.account.repository.AccountRepository;
import com.shoppingmall.backend.account.repository.GeneralAccountRepository;
import com.shoppingmall.backend.admin.dto.AdminOrderRow;
import com.shoppingmall.backend.admin.dto.AdminProductRow;
import com.shoppingmall.backend.admin.dto.AdminStatsResponse;
import com.shoppingmall.backend.admin.dto.UpdateOrderStatusRequest;
import com.shoppingmall.backend.admin.dto.UpdateProductRequest;
import com.shoppingmall.backend.catalog.entity.Product;
import com.shoppingmall.backend.catalog.entity.StockHistory;
import com.shoppingmall.backend.catalog.repository.CategoryRepository;
import com.shoppingmall.backend.catalog.repository.ProductFileRepository;
import com.shoppingmall.backend.catalog.repository.ProductRepository;
import com.shoppingmall.backend.catalog.repository.StockHistoryRepository;
import com.shoppingmall.backend.code.entity.CommonCode;
import com.shoppingmall.backend.code.repository.CommonCodeRepository;
import com.shoppingmall.backend.code.service.CommonCodeLookup;
import com.shoppingmall.backend.common.exception.ApiException;
import com.shoppingmall.backend.common.exception.ErrorCode;
import com.shoppingmall.backend.common.storage.StorageService;
import com.shoppingmall.backend.order.entity.Order;
import com.shoppingmall.backend.order.repository.OrderItemRepository;
import com.shoppingmall.backend.order.repository.OrderRepository;
import com.shoppingmall.backend.order.repository.PaymentRepository;

@Service
@Transactional(readOnly = true)
public class AdminService {

    /** 재고 부족 경고 기준 (대시보드 표시용). */
    private static final int LOW_STOCK_THRESHOLD = 20;

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final PaymentRepository paymentRepository;
    private final ProductRepository productRepository;
    private final ProductFileRepository productFileRepository;
    private final CategoryRepository categoryRepository;
    private final StockHistoryRepository stockHistoryRepository;
    private final GeneralAccountRepository generalAccountRepository;
    private final AccountRepository accountRepository;
    private final CommonCodeRepository commonCodeRepository;
    private final CommonCodeLookup codes;
    private final StorageService storageService;

    public AdminService(
            OrderRepository orderRepository,
            OrderItemRepository orderItemRepository,
            PaymentRepository paymentRepository,
            ProductRepository productRepository,
            ProductFileRepository productFileRepository,
            CategoryRepository categoryRepository,
            StockHistoryRepository stockHistoryRepository,
            GeneralAccountRepository generalAccountRepository,
            AccountRepository accountRepository,
            CommonCodeRepository commonCodeRepository,
            CommonCodeLookup codes,
            StorageService storageService) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.paymentRepository = paymentRepository;
        this.productRepository = productRepository;
        this.productFileRepository = productFileRepository;
        this.categoryRepository = categoryRepository;
        this.stockHistoryRepository = stockHistoryRepository;
        this.generalAccountRepository = generalAccountRepository;
        this.accountRepository = accountRepository;
        this.commonCodeRepository = commonCodeRepository;
        this.codes = codes;
        this.storageService = storageService;
    }

    public AdminStatsResponse stats() {
        BigDecimal paid = paymentRepository.sumCompletedAmount(codes.requireId("PAYMENT_STATUS", "PYST0002"));
        // 환불(refunds)은 아직 기능이 없어 항상 0이지만, 순매출 공식을 여기서부터 지켜둔다.
        BigDecimal refunded = BigDecimal.ZERO;

        return AdminStatsResponse.builder()
                .orderCount(orderRepository.countByDelYn("N"))
                .netRevenue(paid.subtract(refunded))
                .productCount(productRepository.countByDelYn("N"))
                .memberCount(generalAccountRepository.countByDelYn("N"))
                .lowStockCount(productRepository.countByDelYnAndStockQuantityLessThan("N", LOW_STOCK_THRESHOLD))
                .build();
    }

    public PagedModel<AdminOrderRow> orders(Pageable pageable) {
        Page<AdminOrderRow> page = orderRepository.findByDelYnOrderByOrderedAtDesc("N", pageable)
                .map(order -> {
                    CommonCode status = commonCodeRepository.findById(order.getStatusCodeId()).orElse(null);
                    return AdminOrderRow.builder()
                            .orderNumber(order.getOrderNumber())
                            .orderedAt(order.getOrderedAt())
                            .buyerName(accountRepository.findById(order.getAccountId())
                                    .map(a -> a.getName()).orElse(null))
                            .recipientName(order.getRecipientName())
                            .itemCount(orderItemRepository
                                    .findByOrderIdAndDelYnOrderByCreatedAtAsc(order.getId(), "N").size())
                            .totalAmount(order.getTotalAmount())
                            .statusName(status == null ? null : status.getCodeName())
                            .statusCode(status == null ? null : status.getCode())
                            .build();
                });
        return new PagedModel<>(page);
    }

    @Transactional
    public AdminOrderRow updateOrderStatus(String adminId, String orderNumber, UpdateOrderStatusRequest request) {
        Order order = orderRepository.findByOrderNumberAndDelYn(orderNumber, "N")
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "주문을 찾을 수 없습니다."));

        CommonCode status = codes.require("ORDER_STATUS", request.statusCode());
        order.setStatusCodeId(status.getId());
        order.setUpdatedBy(adminId);
        orderRepository.save(order);

        return AdminOrderRow.builder()
                .orderNumber(order.getOrderNumber())
                .orderedAt(order.getOrderedAt())
                .buyerName(accountRepository.findById(order.getAccountId()).map(a -> a.getName()).orElse(null))
                .recipientName(order.getRecipientName())
                .itemCount(orderItemRepository.findByOrderIdAndDelYnOrderByCreatedAtAsc(order.getId(), "N").size())
                .totalAmount(order.getTotalAmount())
                .statusName(status.getCodeName())
                .statusCode(status.getCode())
                .build();
    }

    public PagedModel<AdminProductRow> products(Pageable pageable) {
        Page<AdminProductRow> page = productRepository.findByDelYnOrderByCreatedAtDesc("N", pageable)
                .map(this::toProductRow);
        return new PagedModel<>(page);
    }

    @Transactional
    public AdminProductRow updateProduct(String adminId, UUID uuid, UpdateProductRequest request) {
        Product product = productRepository.findByUuidAndDelYn(uuid, "N")
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "상품을 찾을 수 없습니다."));

        if (request.price() != null) {
            product.setPrice(request.price());
        }
        if (request.statusCode() != null) {
            product.setStatusCodeId(codes.requireId("PRODUCT_STATUS", request.statusCode()));
        }
        if (request.stockQuantity() != null && !request.stockQuantity().equals(product.getStockQuantity())) {
            // 재고를 직접 고칠 때도 감사 이력을 남긴다(주문 차감과 동일하게 stock_histories가 근거).
            int delta = request.stockQuantity() - product.getStockQuantity();
            product.setStockQuantity(request.stockQuantity());
            stockHistoryRepository.save(StockHistory.builder()
                    .productId(product.getId())
                    .changeTypeCodeId(codes.requireId("STOCK_CHANGE_TYPE", "STCT0005")) // 재고조정
                    .quantityDelta(delta)
                    .quantityAfter(request.stockQuantity())
                    .memo("관리자 재고 조정")
                    .createdBy(adminId)
                    .build());
        }

        product.setUpdatedBy(adminId);
        productRepository.save(product);
        return toProductRow(product);
    }

    private AdminProductRow toProductRow(Product product) {
        CommonCode status = commonCodeRepository.findById(product.getStatusCodeId()).orElse(null);
        return AdminProductRow.builder()
                .uuid(product.getUuid())
                .name(product.getName())
                .categoryName(categoryRepository.findById(product.getCategoryId())
                        .map(c -> c.getName()).orElse(null))
                .price(product.getPrice())
                .stockQuantity(product.getStockQuantity())
                .statusName(status == null ? null : status.getCodeName())
                .statusCode(status == null ? null : status.getCode())
                .thumbnailUrl(productFileRepository.findImagePaths(product.getId()).stream()
                        .findFirst().map(storageService::publicUrl).orElse(null))
                .build();
    }
}
