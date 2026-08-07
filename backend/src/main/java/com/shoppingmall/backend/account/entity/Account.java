package com.shoppingmall.backend.account.entity;

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
@Table(name = "accounts")
@Getter
@NoArgsConstructor
@SuperBuilder
public class Account extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(nullable = false, length = 255)
    private String password;

    @Column(nullable = false, length = 50)
    private String name;

    @Column(name = "phone_1", length = 20)
    private String phone1;

    @Column(name = "phone_2", length = 20)
    private String phone2;

    @Column(name = "phone_3", length = 20)
    private String phone3;

    @Column(name = "account_type_code_id", nullable = false, length = 17)
    private String accountTypeCodeId;

    @Column(name = "status_code_id", nullable = false, length = 17)
    private String statusCodeId;
}
