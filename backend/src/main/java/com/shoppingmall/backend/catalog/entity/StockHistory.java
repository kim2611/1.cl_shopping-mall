package com.shoppingmall.backend.catalog.entity;

import com.shoppingmall.backend.common.entity.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

/** 재고 변동 이력 - products.stock_quantity는 현재값 스냅샷이고, 이 테이블이 감사 근거. */
@Entity
@Table(name = "stock_histories")
@Getter
@NoArgsConstructor
@SuperBuilder
public class StockHistory extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "product_id", nullable = false, length = 17)
    private String productId;

    @Column(name = "option_combination_id", length = 17)
    private String optionCombinationId;

    @Column(name = "change_type_code_id", nullable = false, length = 17)
    private String changeTypeCodeId;

    /** 증가 양수 / 감소 음수. */
    @Column(name = "quantity_delta", nullable = false)
    private Integer quantityDelta;

    @Column(name = "quantity_after", nullable = false)
    private Integer quantityAfter;

    @Column(name = "reference_order_id", length = 17)
    private String referenceOrderId;

    @Column(length = 200)
    private String memo;
}
