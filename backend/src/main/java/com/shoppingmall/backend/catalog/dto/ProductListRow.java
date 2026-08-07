package com.shoppingmall.backend.catalog.dto;

import java.math.BigDecimal;
import java.util.UUID;

/** ProductRepository의 목록 조회 JPQL이 바로 채워 넣는 로우 프로젝션 (thumbnailStoredPath는 URL 변환 전 원본 경로). */
public record ProductListRow(UUID uuid, String name, BigDecimal price, String thumbnailStoredPath) {
}
