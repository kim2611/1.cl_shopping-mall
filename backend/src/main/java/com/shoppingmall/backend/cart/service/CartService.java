package com.shoppingmall.backend.cart.service;

import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.shoppingmall.backend.account.repository.GeneralAccountRepository;
import com.shoppingmall.backend.cart.dto.AddCartItemRequest;
import com.shoppingmall.backend.cart.dto.CartItemResponse;
import com.shoppingmall.backend.cart.dto.CartItemRow;
import com.shoppingmall.backend.cart.dto.CartResponse;
import com.shoppingmall.backend.cart.dto.UpdateCartItemRequest;
import com.shoppingmall.backend.cart.entity.Cart;
import com.shoppingmall.backend.cart.entity.CartItem;
import com.shoppingmall.backend.cart.repository.CartItemRepository;
import com.shoppingmall.backend.cart.repository.CartRepository;
import com.shoppingmall.backend.catalog.entity.Product;
import com.shoppingmall.backend.catalog.repository.ProductRepository;
import com.shoppingmall.backend.common.exception.ApiException;
import com.shoppingmall.backend.common.exception.ErrorCode;
import com.shoppingmall.backend.common.storage.StorageService;

@Service
@Transactional(readOnly = true)
public class CartService {

    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final GeneralAccountRepository generalAccountRepository;
    private final StorageService storageService;

    public CartService(
            CartRepository cartRepository,
            CartItemRepository cartItemRepository,
            ProductRepository productRepository,
            GeneralAccountRepository generalAccountRepository,
            StorageService storageService) {
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
        this.generalAccountRepository = generalAccountRepository;
        this.storageService = storageService;
    }

    public CartResponse getCart(String accountId) {
        return cartRepository.findByAccountIdAndDelYn(accountId, "N")
                .map(this::toResponse)
                .orElseGet(() -> emptyCart(null));
    }

    @Transactional
    public CartResponse addItem(String accountId, AddCartItemRequest request) {
        Cart cart = findOrCreateCart(accountId);
        Product product = findProduct(request.productUuid());

        // 옵션 없는 상품만 다루므로 optionCombinationId는 항상 null - 같은 상품을 다시 담으면 수량을 합친다
        // (cart_items의 UNIQUE 인덱스가 같은 상품+옵션 조합의 중복 행 자체를 막는다).
        CartItem existing = cartItemRepository
                .findByCartIdAndProductIdWithoutOption(cart.getId(), product.getId())
                .orElse(null);

        int newQuantity = (existing == null ? 0 : existing.getQuantity()) + request.quantity();
        requireStock(product, newQuantity);

        if (existing == null) {
            cartItemRepository.save(CartItem.builder()
                    .cartId(cart.getId())
                    .productId(product.getId())
                    .quantity(request.quantity())
                    .createdBy(accountId)
                    .build());
        } else {
            existing.setQuantity(newQuantity);
            existing.setUpdatedBy(accountId);
            cartItemRepository.save(existing);
        }

        return toResponse(cart);
    }

    @Transactional
    public CartResponse updateItem(String accountId, String cartItemId, UpdateCartItemRequest request) {
        Cart cart = requireCart(accountId);
        CartItem item = cartItemRepository.findByIdAndCartIdAndDelYn(cartItemId, cart.getId(), "N")
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "장바구니 항목을 찾을 수 없습니다."));

        Product product = productRepository.findById(item.getProductId())
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "상품을 찾을 수 없습니다."));
        requireStock(product, request.quantity());

        item.setQuantity(request.quantity());
        item.setUpdatedBy(accountId);
        cartItemRepository.save(item);

        return toResponse(cart);
    }

    @Transactional
    public CartResponse removeItem(String accountId, String cartItemId) {
        Cart cart = requireCart(accountId);
        CartItem item = cartItemRepository.findByIdAndCartIdAndDelYn(cartItemId, cart.getId(), "N")
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "장바구니 항목을 찾을 수 없습니다."));

        // 프로젝트 공통 규칙에 따라 실제 DELETE가 아니라 소프트 삭제.
        item.setDelYn("Y");
        item.setUpdatedBy(accountId);
        cartItemRepository.save(item);

        return toResponse(cart);
    }

    private Cart findOrCreateCart(String accountId) {
        return cartRepository.findByAccountIdAndDelYn(accountId, "N")
                .orElseGet(() -> {
                    // carts.account_id가 general_accounts를 참조하므로 관리자 계정은 장바구니를 만들 수 없다.
                    // FK 위반으로 500이 나기 전에 여기서 403으로 명확히 막는다.
                    if (!generalAccountRepository.existsById(accountId)) {
                        throw new ApiException(ErrorCode.NOT_A_SHOPPER);
                    }
                    return cartRepository.save(Cart.builder()
                            .accountId(accountId)
                            .createdBy(accountId)
                            .build());
                });
    }

    private Cart requireCart(String accountId) {
        return cartRepository.findByAccountIdAndDelYn(accountId, "N")
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "장바구니가 비어 있습니다."));
    }

    private Product findProduct(UUID productUuid) {
        return productRepository.findByUuidAndDelYn(productUuid, "N")
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "상품을 찾을 수 없습니다."));
    }

    private void requireStock(Product product, int wantedQuantity) {
        if (product.getStockQuantity() < wantedQuantity) {
            throw new ApiException(ErrorCode.OUT_OF_STOCK,
                    "재고가 부족합니다. (남은 수량: %d개)".formatted(product.getStockQuantity()));
        }
    }

    private CartResponse toResponse(Cart cart) {
        List<CartItemResponse> items = cartItemRepository.findRowsByCartId(cart.getId()).stream()
                .map(this::toItemResponse)
                .toList();

        int totalQuantity = items.stream().mapToInt(CartItemResponse::quantity).sum();
        BigDecimal totalAmount = items.stream()
                .map(CartItemResponse::lineAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);

        return CartResponse.builder()
                .cartId(cart.getId())
                .items(items)
                .totalQuantity(totalQuantity)
                .totalAmount(totalAmount)
                .build();
    }

    private CartItemResponse toItemResponse(CartItemRow row) {
        return CartItemResponse.builder()
                .cartItemId(row.cartItemId())
                .productUuid(row.productUuid())
                .productName(row.productName())
                .price(row.price())
                .quantity(row.quantity())
                .lineAmount(row.price().multiply(BigDecimal.valueOf(row.quantity())))
                .stockQuantity(row.stockQuantity())
                .thumbnailUrl(row.thumbnailStoredPath() == null
                        ? null
                        : storageService.publicUrl(row.thumbnailStoredPath()))
                .build();
    }

    private CartResponse emptyCart(String cartId) {
        return CartResponse.builder()
                .cartId(cartId)
                .items(List.of())
                .totalQuantity(0)
                .totalAmount(BigDecimal.ZERO)
                .build();
    }
}
