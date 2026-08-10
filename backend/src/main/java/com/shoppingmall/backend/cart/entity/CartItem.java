package com.shoppingmall.backend.cart.entity;

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

@Entity
@Table(name = "cart_items")
@Getter
@NoArgsConstructor
@SuperBuilder
public class CartItem extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "cart_id", nullable = false, length = 17)
    private String cartId;

    @Column(name = "product_id", nullable = false, length = 17)
    private String productId;

    /** 옵션이 없는 상품이면 NULL. 현재 시드 상품은 전부 옵션이 없어 NULL로만 쓰인다. */
    @Column(name = "option_combination_id", length = 17)
    private String optionCombinationId;

    @Setter
    @Column(nullable = false)
    private Integer quantity;
}
