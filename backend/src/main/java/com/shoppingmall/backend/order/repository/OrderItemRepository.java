package com.shoppingmall.backend.order.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.order.entity.OrderItem;

public interface OrderItemRepository extends JpaRepository<OrderItem, String> {

    List<OrderItem> findByOrderIdAndDelYnOrderByCreatedAtAsc(String orderId, String delYn);
}
