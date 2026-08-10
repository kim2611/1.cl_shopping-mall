package com.shoppingmall.backend.order.entity;

import java.math.BigDecimal;

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

/** 주문 항목. product_name/price/option_summary는 전부 주문 시점 스냅샷 (이후 상품이 바뀌어도 불변). */
@Entity
@Table(name = "order_items")
@Getter
@NoArgsConstructor
@SuperBuilder
public class OrderItem extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "order_id", nullable = false, length = 17)
    private String orderId;

    @Column(name = "product_id", nullable = false, length = 17)
    private String productId;

    @Column(name = "product_name", nullable = false, length = 200)
    private String productName;

    @Column(name = "option_combination_id", length = 17)
    private String optionCombinationId;

    @Column(name = "option_summary", length = 300)
    private String optionSummary;

    /** 어느 배송 건에 속하는지. deliveries를 먼저 만들 수 없어 주문 생성 중에 나중에 채운다. */
    @Setter
    @Column(name = "delivery_id", length = 17)
    private String deliveryId;

    @Column(nullable = false)
    private Integer quantity;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;
}
