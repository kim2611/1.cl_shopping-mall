package com.shoppingmall.backend.cart.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.shoppingmall.backend.cart.dto.CartItemRow;
import com.shoppingmall.backend.cart.entity.CartItem;

public interface CartItemRepository extends JpaRepository<CartItem, String> {

    /**
     * 장바구니는 "지금 시점의 상품 정보"를 보여줘야 하는 라이브 데이터라, 담을 때 가격을 스냅샷하지 않고
     * 조회 시점에 products를 조인해 현재 가격/재고를 가져온다 (주문 확정 시점에야 order_items로 스냅샷된다).
     */
    @Query("""
            select new com.shoppingmall.backend.cart.dto.CartItemRow(
                ci.id, p.uuid, p.name, p.price, ci.quantity, p.stockQuantity, f.storedPath)
            from CartItem ci
            join Product p on p.id = ci.productId
            left join ProductFile pf on pf.productId = p.id and pf.thumbnailYn = 'Y' and pf.delYn = 'N'
            left join FileAsset f on f.id = pf.fileId
            where ci.cartId = :cartId and ci.delYn = 'N'
            order by ci.createdAt asc
            """)
    List<CartItemRow> findRowsByCartId(@Param("cartId") String cartId);

    Optional<CartItem> findByIdAndCartIdAndDelYn(String id, String cartId, String delYn);

    List<CartItem> findByCartIdAndDelYnOrderByCreatedAtAsc(String cartId, String delYn);

    Optional<CartItem> findByCartIdAndProductIdAndOptionCombinationIdAndDelYn(
            String cartId, String productId, String optionCombinationId, String delYn);

    /** 옵션 없는 상품(option_combination_id IS NULL)은 위 파생 쿼리로 매칭이 안 돼 별도 JPQL이 필요하다. */
    @Query("""
            select ci from CartItem ci
            where ci.cartId = :cartId and ci.productId = :productId
              and ci.optionCombinationId is null and ci.delYn = 'N'
            """)
    Optional<CartItem> findByCartIdAndProductIdWithoutOption(
            @Param("cartId") String cartId, @Param("productId") String productId);
}
