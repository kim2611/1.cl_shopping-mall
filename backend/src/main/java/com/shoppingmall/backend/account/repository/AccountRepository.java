package com.shoppingmall.backend.account.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.shoppingmall.backend.account.entity.Account;

public interface AccountRepository extends JpaRepository<Account, String> {

    @Query("""
            select a from Account a
            join AccountEmail e on e.accountId = a.id
            where e.email = :email and e.delYn = 'N' and a.delYn = 'N'
            """)
    Optional<Account> findByLoginEmail(@Param("email") String email);
}
