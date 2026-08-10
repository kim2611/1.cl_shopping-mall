package com.shoppingmall.backend.order.repository;

import java.math.BigDecimal;
import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.shoppingmall.backend.order.entity.Payment;

public interface PaymentRepository extends JpaRepository<Payment, String> {

    Optional<Payment> findByOrderIdAndDelYn(String orderId, String delYn);

    /** 결제 '완료' 상태만 합산. 환불분은 refunds에서 따로 빼야 순매출이 된다. */
    @Query("""
            select coalesce(sum(p.amount), 0) from Payment p
            where p.delYn = 'N' and p.statusCodeId = :completedStatusCodeId
            """)
    BigDecimal sumCompletedAmount(@Param("completedStatusCodeId") String completedStatusCodeId);
}
