package com.shoppingmall.backend.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.account.entity.AccountEmail;

public interface AccountEmailRepository extends JpaRepository<AccountEmail, String> {

    boolean existsByEmailAndDelYn(String email, String delYn);
}
