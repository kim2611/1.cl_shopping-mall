package com.shoppingmall.backend.order.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import com.shoppingmall.backend.order.entity.Order;

public interface OrderRepository extends JpaRepository<Order, String> {

    List<Order> findByAccountIdAndDelYnOrderByOrderedAtDesc(String accountId, String delYn);

    Optional<Order> findByOrderNumberAndDelYn(String orderNumber, String delYn);

    Page<Order> findByDelYnOrderByOrderedAtDesc(String delYn, Pageable pageable);

    /** 주문번호 채번용 시퀀스. PK와 달리 형식이 'ORD+날짜+일련번호'라 DB DEFAULT로 만들 수 없어 앱에서 조립한다. */
    @Query(value = "select nextval('SEQ_ORDER_NUMBER_01')", nativeQuery = true)
    Long nextOrderNumberSequence();
}
