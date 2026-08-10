package com.shoppingmall.backend.order.service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.shoppingmall.backend.cart.entity.Cart;
import com.shoppingmall.backend.cart.entity.CartItem;
import com.shoppingmall.backend.cart.repository.CartItemRepository;
import com.shoppingmall.backend.cart.repository.CartRepository;
import com.shoppingmall.backend.catalog.entity.Product;
import com.shoppingmall.backend.catalog.entity.StockHistory;
import com.shoppingmall.backend.catalog.repository.ProductFileRepository;
import com.shoppingmall.backend.catalog.repository.ProductRepository;
import com.shoppingmall.backend.catalog.repository.StockHistoryRepository;
import com.shoppingmall.backend.code.repository.CommonCodeRepository;
import com.shoppingmall.backend.code.service.CommonCodeLookup;
import com.shoppingmall.backend.common.exception.ApiException;
import com.shoppingmall.backend.common.exception.ErrorCode;
import com.shoppingmall.backend.common.storage.StorageService;
import com.shoppingmall.backend.company.repository.CompanyShippingPolicyRepository;
import com.shoppingmall.backend.order.dto.CreateOrderRequest;
import com.shoppingmall.backend.order.dto.OrderItemResponse;
import com.shoppingmall.backend.order.dto.OrderResponse;
import com.shoppingmall.backend.order.dto.OrderSummaryResponse;
import com.shoppingmall.backend.order.entity.Delivery;
import com.shoppingmall.backend.order.entity.Order;
import com.shoppingmall.backend.order.entity.OrderItem;
import com.shoppingmall.backend.order.entity.Payment;
import com.shoppingmall.backend.order.repository.DeliveryRepository;
import com.shoppingmall.backend.order.repository.OrderItemRepository;
import com.shoppingmall.backend.order.repository.OrderRepository;
import com.shoppingmall.backend.order.repository.PaymentRepository;

@Service
@Transactional(readOnly = true)
public class OrderService {

    private static final DateTimeFormatter ORDER_NO_DATE = DateTimeFormatter.ofPattern("yyyyMMdd");

    // 배송비 정책 행이 없는 회사에 대한 폴백 (ERD 10차 라운드에서 확정한 1차 기본값과 동일)
    private static final BigDecimal DEFAULT_BASE_FEE = new BigDecimal("3000");
    private static final BigDecimal DEFAULT_FREE_THRESHOLD = new BigDecimal("30000");

    private final OrderRepository orderRepository;
    private final OrderItemRepository orderItemRepository;
    private final PaymentRepository paymentRepository;
    private final DeliveryRepository deliveryRepository;
    private final CartRepository cartRepository;
    private final CartItemRepository cartItemRepository;
    private final ProductRepository productRepository;
    private final ProductFileRepository productFileRepository;
    private final StockHistoryRepository stockHistoryRepository;
    private final CompanyShippingPolicyRepository shippingPolicyRepository;
    private final CommonCodeRepository commonCodeRepository;
    private final CommonCodeLookup codes;
    private final StorageService storageService;

    public OrderService(
            OrderRepository orderRepository,
            OrderItemRepository orderItemRepository,
            PaymentRepository paymentRepository,
            DeliveryRepository deliveryRepository,
            CartRepository cartRepository,
            CartItemRepository cartItemRepository,
            ProductRepository productRepository,
            ProductFileRepository productFileRepository,
            StockHistoryRepository stockHistoryRepository,
            CompanyShippingPolicyRepository shippingPolicyRepository,
            CommonCodeRepository commonCodeRepository,
            CommonCodeLookup codes,
            StorageService storageService) {
        this.orderRepository = orderRepository;
        this.orderItemRepository = orderItemRepository;
        this.paymentRepository = paymentRepository;
        this.deliveryRepository = deliveryRepository;
        this.cartRepository = cartRepository;
        this.cartItemRepository = cartItemRepository;
        this.productRepository = productRepository;
        this.productFileRepository = productFileRepository;
        this.stockHistoryRepository = stockHistoryRepository;
        this.shippingPolicyRepository = shippingPolicyRepository;
        this.commonCodeRepository = commonCodeRepository;
        this.codes = codes;
        this.storageService = storageService;
    }

    /**
     * 장바구니 전체를 주문으로 확정한다. 한 트랜잭션 안에서:
     * 주문/주문항목(스냅샷) 생성 → 재고 차감 + 재고이력 기록 → 회사별 배송 건 생성 → 결제 생성 → 장바구니 비우기.
     * 중간에 하나라도 실패하면 전부 롤백된다(재고만 깎이고 주문은 없는 상태가 생기지 않도록).
     */
    @Transactional
    public OrderResponse createOrder(String accountId, String idempotencyKey, CreateOrderRequest request) {
        Cart cart = cartRepository.findByAccountIdAndDelYn(accountId, "N")
                .orElseThrow(() -> new ApiException(ErrorCode.EMPTY_CART));
        List<CartItem> cartItems = cartItemRepository.findByCartIdAndDelYnOrderByCreatedAtAsc(cart.getId(), "N");
        if (cartItems.isEmpty()) {
            throw new ApiException(ErrorCode.EMPTY_CART);
        }

        Order order = orderRepository.save(Order.builder()
                .accountId(accountId)
                .addressId(request.addressId())
                .recipientName(request.recipientName())
                .phone(request.phone())
                .zipCode(request.zipCode())
                .address1(request.address1())
                .address2(request.address2())
                .orderNumber(generateOrderNumber())
                .idempotencyKey(idempotencyKey)
                .statusCodeId(codes.requireId("ORDER_STATUS", "ORST0002")) // 결제완료
                .totalAmount(BigDecimal.ZERO) // 배송비까지 계산한 뒤 아래에서 확정
                .discountAmount(BigDecimal.ZERO)
                .orderedAt(LocalDateTime.now())
                .createdBy(accountId)
                .build());
        // 멱등 키 중복은 이 시점에 DB 유니크 인덱스가 잡아야 하므로, 뒤 작업을 하기 전에 먼저 반영한다.
        orderRepository.flush();

        String stockDecreaseCodeId = codes.requireId("STOCK_CHANGE_TYPE", "STCT0003"); // 주문차감

        BigDecimal itemsAmount = BigDecimal.ZERO;
        // 회사별로 배송이 나뉘므로(1주문 : N배송) 회사 단위로 항목과 금액을 모은다.
        Map<String, List<OrderItem>> itemsByCompany = new LinkedHashMap<>();
        Map<String, BigDecimal> amountByCompany = new LinkedHashMap<>();

        // 상품 ID 순으로 정렬해서 잠근다 - 두 주문이 같은 상품 두 개를 서로 반대 순서로 잠그면
        // 데드락이 나므로, 모든 트랜잭션이 항상 같은 순서로 락을 잡게 한다.
        List<CartItem> lockOrderedItems = cartItems.stream()
                .sorted(Comparator.comparing(CartItem::getProductId))
                .toList();

        for (CartItem cartItem : lockOrderedItems) {
            // 행 잠금 조회 - 재고 검사와 차감 사이에 다른 주문이 끼어들지 못하게 한다.
            Product product = productRepository.findForStockUpdate(cartItem.getProductId())
                    .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "상품을 찾을 수 없습니다."));

            if (product.getStockQuantity() < cartItem.getQuantity()) {
                throw new ApiException(ErrorCode.OUT_OF_STOCK,
                        "'%s' 재고가 부족합니다. (남은 수량: %d개)".formatted(product.getName(), product.getStockQuantity()));
            }

            BigDecimal lineAmount = product.getPrice().multiply(BigDecimal.valueOf(cartItem.getQuantity()));
            itemsAmount = itemsAmount.add(lineAmount);

            OrderItem orderItem = orderItemRepository.save(OrderItem.builder()
                    .orderId(order.getId())
                    .productId(product.getId())
                    .productName(product.getName())          // 스냅샷
                    .optionCombinationId(cartItem.getOptionCombinationId())
                    .quantity(cartItem.getQuantity())
                    .price(product.getPrice())               // 스냅샷
                    .createdBy(accountId)
                    .build());

            itemsByCompany.computeIfAbsent(product.getCompanyId(), k -> new java.util.ArrayList<>()).add(orderItem);
            amountByCompany.merge(product.getCompanyId(), lineAmount, BigDecimal::add);

            // 재고 차감 + 감사 이력
            int after = product.getStockQuantity() - cartItem.getQuantity();
            product.setStockQuantity(after);
            productRepository.save(product);
            stockHistoryRepository.save(StockHistory.builder()
                    .productId(product.getId())
                    .optionCombinationId(cartItem.getOptionCombinationId())
                    .changeTypeCodeId(stockDecreaseCodeId)
                    .quantityDelta(-cartItem.getQuantity())
                    .quantityAfter(after)
                    .referenceOrderId(order.getId())
                    .memo("주문 " + order.getOrderNumber())
                    .createdBy(accountId)
                    .build());
        }

        // 회사별 배송 건 생성 + 각 주문항목에 소속 배송 연결
        String preparingCodeId = codes.requireId("DELIVERY_STATUS", "DLST0001"); // 상품준비중
        BigDecimal totalDeliveryFee = BigDecimal.ZERO;

        for (Map.Entry<String, List<OrderItem>> entry : itemsByCompany.entrySet()) {
            String companyId = entry.getKey();
            BigDecimal companyAmount = amountByCompany.get(companyId);
            BigDecimal fee = calculateDeliveryFee(companyId, companyAmount);
            totalDeliveryFee = totalDeliveryFee.add(fee);

            Delivery delivery = deliveryRepository.save(Delivery.builder()
                    .orderId(order.getId())
                    .companyId(companyId)
                    .statusCodeId(preparingCodeId)
                    .deliveryFee(fee) // 주문 시점 정책 스냅샷
                    .createdBy(accountId)
                    .build());

            for (OrderItem item : entry.getValue()) {
                item.setDeliveryId(delivery.getId());
                item.setUpdatedBy(accountId);
                orderItemRepository.save(item);
            }
        }

        BigDecimal totalAmount = itemsAmount.add(totalDeliveryFee); // 할인은 아직 없음(쿠폰 미구현)
        order.setTotalAmount(totalAmount);
        order.setUpdatedBy(accountId);
        orderRepository.save(order);

        // 실제 PG 연동은 아직 없어 결제는 즉시 '완료'로 기록한다 (개발 단계 한정).
        paymentRepository.save(Payment.builder()
                .orderId(order.getId())
                .methodCodeId(codes.requireId("PAYMENT_METHOD",
                        request.paymentMethodCode() == null ? "PYMT0001" : request.paymentMethodCode()))
                .amount(totalAmount)
                .statusCodeId(codes.requireId("PAYMENT_STATUS", "PYST0002")) // 완료
                .paidAt(LocalDateTime.now())
                .createdBy(accountId)
                .build());

        // 주문된 장바구니 항목은 소프트 삭제로 비운다
        for (CartItem cartItem : cartItems) {
            cartItem.setDelYn("Y");
            cartItem.setUpdatedBy(accountId);
            cartItemRepository.save(cartItem);
        }

        return toDetailResponse(order);
    }

    public List<OrderSummaryResponse> listMyOrders(String accountId) {
        return orderRepository.findByAccountIdAndDelYnOrderByOrderedAtDesc(accountId, "N").stream()
                .map(this::toSummaryResponse)
                .toList();
    }

    public OrderResponse getMyOrder(String accountId, String orderNumber) {
        Order order = orderRepository.findByOrderNumberAndDelYn(orderNumber, "N")
                .orElseThrow(() -> new ApiException(ErrorCode.NOT_FOUND, "주문을 찾을 수 없습니다."));
        // 남의 주문을 주문번호만 알면 볼 수 있으면 안 되므로 소유자 확인 (없으면 존재 자체를 숨김)
        if (!order.getAccountId().equals(accountId)) {
            throw new ApiException(ErrorCode.NOT_FOUND, "주문을 찾을 수 없습니다.");
        }
        return toDetailResponse(order);
    }

    private BigDecimal calculateDeliveryFee(String companyId, BigDecimal companyItemsAmount) {
        Optional<com.shoppingmall.backend.company.entity.CompanyShippingPolicy> policy =
                shippingPolicyRepository.findByCompanyIdAndDelYn(companyId, "N");

        BigDecimal baseFee = policy.map(p -> p.getBaseFee()).orElse(DEFAULT_BASE_FEE);
        BigDecimal threshold = policy.map(p -> p.getFreeShippingThreshold()).orElse(DEFAULT_FREE_THRESHOLD);

        if (threshold != null && companyItemsAmount.compareTo(threshold) >= 0) {
            return BigDecimal.ZERO;
        }
        return baseFee;
    }

    private String generateOrderNumber() {
        long seq = orderRepository.nextOrderNumberSequence();
        return "ORD%s%06d".formatted(LocalDate.now().format(ORDER_NO_DATE), seq);
    }

    private OrderSummaryResponse toSummaryResponse(Order order) {
        List<OrderItem> items = orderItemRepository.findByOrderIdAndDelYnOrderByCreatedAtAsc(order.getId(), "N");
        OrderItem first = items.isEmpty() ? null : items.get(0);

        return OrderSummaryResponse.builder()
                .orderNumber(order.getOrderNumber())
                .statusName(codeName(order.getStatusCodeId()))
                .orderedAt(order.getOrderedAt())
                .representativeProductName(first == null ? null : first.getProductName())
                .itemCount(items.size())
                .totalAmount(order.getTotalAmount())
                .thumbnailUrl(first == null ? null : thumbnailUrlOf(first.getProductId()))
                .build();
    }

    private OrderResponse toDetailResponse(Order order) {
        List<OrderItem> items = orderItemRepository.findByOrderIdAndDelYnOrderByCreatedAtAsc(order.getId(), "N");

        List<OrderItemResponse> itemResponses = items.stream()
                .map(item -> OrderItemResponse.builder()
                        .orderItemId(item.getId())
                        .productUuid(productRepository.findById(item.getProductId())
                                .map(Product::getUuid).orElse(null))
                        .productName(item.getProductName())
                        .optionSummary(item.getOptionSummary())
                        .quantity(item.getQuantity())
                        .price(item.getPrice())
                        .lineAmount(item.getPrice().multiply(BigDecimal.valueOf(item.getQuantity())))
                        .thumbnailUrl(thumbnailUrlOf(item.getProductId()))
                        .build())
                .toList();

        BigDecimal itemsAmount = itemResponses.stream()
                .map(OrderItemResponse::lineAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        BigDecimal deliveryFee = deliveryRepository.findByOrderIdAndDelYn(order.getId(), "N").stream()
                .map(Delivery::getDeliveryFee)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        Optional<Payment> payment = paymentRepository.findByOrderIdAndDelYn(order.getId(), "N");

        return OrderResponse.builder()
                .orderNumber(order.getOrderNumber())
                .statusName(codeName(order.getStatusCodeId()))
                .orderedAt(order.getOrderedAt())
                .recipientName(order.getRecipientName())
                .phone(order.getPhone())
                .zipCode(order.getZipCode())
                .address1(order.getAddress1())
                .address2(order.getAddress2())
                .items(itemResponses)
                .itemsAmount(itemsAmount)
                .deliveryFee(deliveryFee)
                .discountAmount(order.getDiscountAmount())
                .totalAmount(order.getTotalAmount())
                .paymentMethodName(payment.map(p -> codeName(p.getMethodCodeId())).orElse(null))
                .paymentStatusName(payment.map(p -> codeName(p.getStatusCodeId())).orElse(null))
                .build();
    }

    private String codeName(String codeId) {
        return commonCodeRepository.findById(codeId)
                .map(com.shoppingmall.backend.code.entity.CommonCode::getCodeName)
                .orElse(null);
    }

    private String thumbnailUrlOf(String productId) {
        return productFileRepository.findImagePaths(productId).stream()
                .findFirst()
                .map(storageService::publicUrl)
                .orElse(null);
    }
}
