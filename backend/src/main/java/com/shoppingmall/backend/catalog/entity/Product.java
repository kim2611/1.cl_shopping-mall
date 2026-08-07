package com.shoppingmall.backend.catalog.entity;

import java.math.BigDecimal;
import java.util.UUID;

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

@Entity
@Table(name = "products")
@Getter
@NoArgsConstructor
@SuperBuilder
public class Product extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    // 클라이언트에 노출하는 외부 공개 식별자 - 내부 id(코드+순번)는 절대 노출하지 않는다.
    @Column(nullable = false, unique = true)
    private UUID uuid;

    @Column(name = "company_id", nullable = false, length = 17)
    private String companyId;

    @Column(name = "category_id", nullable = false, length = 17)
    private String categoryId;

    @Column(nullable = false, length = 200)
    private String name;

    private String description;

    @Column(nullable = false, precision = 12, scale = 2)
    private BigDecimal price;

    @Column(name = "stock_quantity", nullable = false)
    private Integer stockQuantity;

    @Column(name = "status_code_id", nullable = false, length = 17)
    private String statusCodeId;
}
