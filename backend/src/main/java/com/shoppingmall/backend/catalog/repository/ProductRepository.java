package com.shoppingmall.backend.catalog.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.shoppingmall.backend.catalog.dto.ProductListRow;
import com.shoppingmall.backend.catalog.entity.Product;

public interface ProductRepository extends JpaRepository<Product, String> {

    Optional<Product> findByUuidAndDelYn(UUID uuid, String delYn);

    @Query("""
            select new com.shoppingmall.backend.catalog.dto.ProductListRow(p.uuid, p.name, p.price, f.storedPath)
            from Product p
            left join ProductFile pf on pf.productId = p.id and pf.thumbnailYn = 'Y' and pf.delYn = 'N'
            left join FileAsset f on f.id = pf.fileId
            where p.delYn = 'N' and (:categoryId is null or p.categoryId = :categoryId)
            order by p.createdAt desc
            """)
    Page<ProductListRow> findSummariesLatest(@Param("categoryId") String categoryId, Pageable pageable);

    @Query("""
            select new com.shoppingmall.backend.catalog.dto.ProductListRow(p.uuid, p.name, p.price, f.storedPath)
            from Product p
            left join ProductFile pf on pf.productId = p.id and pf.thumbnailYn = 'Y' and pf.delYn = 'N'
            left join FileAsset f on f.id = pf.fileId
            where p.delYn = 'N' and (:categoryId is null or p.categoryId = :categoryId)
            order by p.price asc
            """)
    Page<ProductListRow> findSummariesPriceAsc(@Param("categoryId") String categoryId, Pageable pageable);

    @Query("""
            select new com.shoppingmall.backend.catalog.dto.ProductListRow(p.uuid, p.name, p.price, f.storedPath)
            from Product p
            left join ProductFile pf on pf.productId = p.id and pf.thumbnailYn = 'Y' and pf.delYn = 'N'
            left join FileAsset f on f.id = pf.fileId
            where p.delYn = 'N' and (:categoryId is null or p.categoryId = :categoryId)
            order by p.price desc
            """)
    Page<ProductListRow> findSummariesPriceDesc(@Param("categoryId") String categoryId, Pageable pageable);
}
