package com.shoppingmall.backend.catalog.entity;

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

/**
 * files 테이블 매핑 - 클래스명은 java.io.File과 겹치지 않도록 FileAsset으로 둔다.
 * PK가 UUID인 유일한 예외 테이블(외부에 직접 서빙되는 공개 식별자라 코드+순번 규칙을 안 씀).
 */
@Entity
@Table(name = "files")
@Getter
@NoArgsConstructor
@SuperBuilder
public class FileAsset extends BaseEntity {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "original_name", nullable = false, length = 255)
    private String originalName;

    @Column(name = "stored_path", nullable = false, length = 500)
    private String storedPath;

    @Column(name = "mime_type", nullable = false, length = 100)
    private String mimeType;

    @Column(name = "size_bytes", nullable = false)
    private Long sizeBytes;

    @Column(name = "uploaded_by", length = 17)
    private String uploadedBy;
}
