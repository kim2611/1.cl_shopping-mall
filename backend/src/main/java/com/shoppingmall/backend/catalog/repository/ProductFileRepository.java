package com.shoppingmall.backend.catalog.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.shoppingmall.backend.catalog.entity.ProductFile;

public interface ProductFileRepository extends JpaRepository<ProductFile, String> {

    @Query("""
            select f.storedPath from ProductFile pf join FileAsset f on f.id = pf.fileId
            where pf.productId = :productId and pf.delYn = 'N'
            order by pf.sortOrder asc
            """)
    List<String> findImagePaths(@Param("productId") String productId);
}
