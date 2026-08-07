package com.shoppingmall.backend.catalog.entity;

import java.util.UUID;

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
@Table(name = "product_files")
@Getter
@NoArgsConstructor
@SuperBuilder
public class ProductFile extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(length = 17)
    private String id;

    @Column(name = "product_id", nullable = false, length = 17)
    private String productId;

    @Column(name = "file_id", nullable = false)
    private UUID fileId;

    @JdbcTypeCode(SqlTypes.CHAR)
    @Column(name = "thumbnail_yn", nullable = false, length = 1)
    private String thumbnailYn;

    @Column(name = "sort_order", nullable = false)
    private Integer sortOrder;
}
