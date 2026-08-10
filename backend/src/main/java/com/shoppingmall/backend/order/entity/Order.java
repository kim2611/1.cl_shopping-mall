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
 * 주문. 배송지는 address_id(참고용 역참조)가 아니라 recipient_name~address2 스냅샷 컬럼이 원본이다
 * (저장 주소를 나중에 수정해도 지나간 주문의 배송지는 바뀌면 안 되므로 - ERD 12차 라운드).
 */
@Entity
@Table(name = "orders")
@Getter
@NoArgsConstructor
@SuperBuilder
public class Order extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "account_id", nullable = false, length = 17)
    private String accountId;

    @Column(name = "address_id", length = 17)
    private String addressId;

    @Column(name = "recipient_name", nullable = false, length = 50)
    private String recipientName;

    @Column(nullable = false, length = 20)
    private String phone;

    @Column(name = "zip_code", nullable = false, length = 10)
    private String zipCode;

    @Column(nullable = false, length = 200)
    private String address1;

    @Column(length = 200)
    private String address2;

    @Column(name = "order_number", nullable = false, length = 50)
    private String orderNumber;

    @Setter
    @Column(name = "status_code_id", nullable = false, length = 17)
    private String statusCodeId;

    /** 상품금액 합 - discount_amount + 배송비 합. */
    @Setter
    @Column(name = "total_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal totalAmount;

    @Column(name = "discount_amount", nullable = false, precision = 12, scale = 2)
    private BigDecimal discountAmount;

    @Column(name = "ordered_at", nullable = false)
    private LocalDateTime orderedAt;
}
