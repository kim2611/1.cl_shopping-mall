package com.shoppingmall.backend.catalog.repository;

import java.util.Optional;
import java.util.UUID;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Lock;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.shoppingmall.backend.catalog.dto.ProductListRow;
import com.shoppingmall.backend.catalog.entity.Product;

import jakarta.persistence.LockModeType;

public interface ProductRepository extends JpaRepository<Product, String> {

    /**
     * 재고 차감용 조회 - 행 잠금(SELECT ... FOR UPDATE)을 걸어 "읽고-검사하고-쓰는" 사이에
     * 다른 트랜잭션이 끼어들지 못하게 한다. 이게 없으면 재고 1개를 여러 주문이 동시에
     * 통과시켜 초과판매가 난다(실제로 재고 1개짜리 상품에 동시 주문 4건이 전부 성공했다).
     */
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select p from Product p where p.id = :id and p.delYn = 'N'")
    Optional<Product> findForStockUpdate(@Param("id") String id);

    Optional<Product> findByUuidAndDelYn(UUID uuid, String delYn);

    Page<Product> findByDelYnOrderByCreatedAtDesc(String delYn, Pageable pageable);

    long countByDelYn(String delYn);

    long countByDelYnAndStockQuantityLessThan(String delYn, Integer threshold);

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
