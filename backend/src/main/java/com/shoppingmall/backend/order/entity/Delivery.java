package com.shoppingmall.backend.order.entity;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import com.shoppingmall.backend.common.entity.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;

/**
 * 배송. 한 주문에 여러 회사 상품이 섞이면 회사별로 따로 배송되므로 orders : deliveries = 1:N.
 * delivery_fee는 주문 시점 회사 배송비 정책의 스냅샷(정책이 바뀌어도 과거 배송엔 영향 없음).
 */
@Entity
@Table(name = "deliveries")
@Getter
@NoArgsConstructor
@SuperBuilder
public class Delivery extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "order_id", nullable = false, length = 17)
    private String orderId;

    @Column(name = "company_id", nullable = false, length = 17)
    private String companyId;

    @Setter
    @Column(length = 50)
    private String carrier;

    @Setter
    @Column(name = "tracking_number", length = 100)
    private String trackingNumber;

    @Setter
    @Column(name = "status_code_id", nullable = false, length = 17)
    private String statusCodeId;

    @Column(name = "delivery_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal deliveryFee;

    @Setter
    @Column(name = "shipped_at")
    private LocalDateTime shippedAt;

    @Setter
    @Column(name = "delivered_at")
    private LocalDateTime deliveredAt;
}
