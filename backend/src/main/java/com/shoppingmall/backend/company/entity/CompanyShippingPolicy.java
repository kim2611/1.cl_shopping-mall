package com.shoppingmall.backend.company.entity;

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
import lombok.experimental.SuperBuilder;

@Entity
@Table(name = "company_shipping_policies")
@Getter
@NoArgsConstructor
@SuperBuilder
public class CompanyShippingPolicy extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "company_id", nullable = false, length = 17)
    private String companyId;

    @Column(name = "base_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal baseFee;

    /** 이 금액 이상이면 무료배송. NULL이면 무료배송 미제공. */
    @Column(name = "free_shipping_threshold", precision = 12, scale = 2)
    private BigDecimal freeShippingThreshold;

    @Column(name = "remote_area_extra_fee", nullable = false, precision = 10, scale = 2)
    private BigDecimal remoteAreaExtraFee;
}
