package com.shoppingmall.backend.account.entity;

import com.shoppingmall.backend.common.entity.BaseEntity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.experimental.SuperBuilder;

/**
 * accounts.id를 그대로 PK로 쓰는 서브타입 테이블 (자체 시퀀스 없음) - accountId는
 * 서비스 계층에서 이미 저장된 Account.id 값을 그대로 채워 넣는다.
 */
@Entity
@Table(name = "general_accounts")
@Getter
@NoArgsConstructor
@SuperBuilder
public class GeneralAccount extends BaseEntity {

    @Id
    @Column(name = "account_id", length = 17)
    private String accountId;

    @Column(name = "grade_code_id", nullable = false, length = 17)
    private String gradeCodeId;

    @Column(nullable = false)
    private Integer points;
}
