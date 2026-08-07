package com.shoppingmall.backend.common.entity;

import java.time.LocalDateTime;

import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import jakarta.persistence.Column;
import jakarta.persistence.MappedSuperclass;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import lombok.experimental.SuperBuilder;

/**
 * 모든 테이블 공통 5종 컬럼(del_yn/created_by/created_at/updated_by/updated_at) 매핑.
 * created_at/del_yn은 여기서 자동 기본값을 채우고, created_by는 호출부(서비스 계층)에서
 * 인증 주체를 알고 있을 때 명시적으로 설정한다.
 * 서브클래스가 상속 필드까지 빌더에 포함하려면 @Builder 대신 @SuperBuilder를 써야 해서
 * (Lombok 제약) 이 계층 전체는 @SuperBuilder로 통일한다.
 */
@Getter
@Setter
@SuperBuilder
@NoArgsConstructor
@MappedSuperclass
public abstract class BaseEntity {

    @lombok.Builder.Default
    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "del_yn", nullable = false, length = 1)
    private String delYn = "N";

    @Column(name = "created_by", nullable = false, length = 50)
    private String createdBy;

    @Column(name = "created_at", nullable = false)
    private LocalDateTime createdAt;

    @Column(name = "updated_by")
    private String updatedBy;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now();
        }
        if (delYn == null) {
            delYn = "N";
        }
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
