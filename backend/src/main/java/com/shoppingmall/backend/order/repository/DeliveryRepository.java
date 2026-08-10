package com.shoppingmall.backend.order.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.order.entity.Delivery;

public interface DeliveryRepository extends JpaRepository<Delivery, String> {

    List<Delivery> findByOrderIdAndDelYn(String orderId, String delYn);
}
