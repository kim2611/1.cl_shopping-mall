package com.shoppingmall.backend.cart.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.cart.entity.Cart;

public interface CartRepository extends JpaRepository<Cart, String> {

    Optional<Cart> findByAccountIdAndDelYn(String accountId, String delYn);
}
