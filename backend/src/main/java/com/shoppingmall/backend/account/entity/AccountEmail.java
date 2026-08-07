package com.shoppingmall.backend.account.entity;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

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
@Table(name = "account_emails")
@Getter
@NoArgsConstructor
@SuperBuilder
public class AccountEmail extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "account_id", nullable = false, length = 17)
    private String accountId;

    @Column(nullable = false, length = 100)
    private String email;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "primary_yn", nullable = false, length = 1)
    private String primaryYn;
}
