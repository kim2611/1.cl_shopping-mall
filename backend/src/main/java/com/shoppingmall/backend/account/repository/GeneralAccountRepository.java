package com.shoppingmall.backend.account.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.account.entity.GeneralAccount;

public interface GeneralAccountRepository extends JpaRepository<GeneralAccount, String> {

    long countByDelYn(String delYn);
}
