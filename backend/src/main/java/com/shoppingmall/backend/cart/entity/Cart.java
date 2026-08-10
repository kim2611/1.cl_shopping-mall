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
import lombok.experimental.SuperBuilder;

/** 장바구니 - 계정당 1개(account_id UNIQUE). account_id는 general_accounts를 참조하므로 관리자 계정은 가질 수 없다. */
@Entity
@Table(name = "carts")
@Getter
@NoArgsConstructor
@SuperBuilder
public class Cart extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "account_id", nullable = false, length = 17)
    private String accountId;
}
