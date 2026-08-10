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

/** 결제. amount는 최초 결제 금액 그대로 유지하고, 환불이 생겨도 수정하지 않는다(환불은 refunds 원장에 별도 기록). */
@Entity
@Table(name = "payments")
@Getter
@NoArgsConstructor
@SuperBuilder
public class Payment extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "order_id", nullable = false, length = 17)
    private String orderId;

    @Column(name = "method_code_id", nullable = false, length = 17)
    private String methodCodeId;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal amount;

    @Setter
    @Column(name = "status_code_id", nullable = false, length = 17)
    private String statusCodeId;

    @Setter
    @Column(name = "paid_at")
    private LocalDateTime paidAt;
}
