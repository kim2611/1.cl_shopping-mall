package com.shoppingmall.backend.code.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.code.entity.CommonCode;

public interface CommonCodeRepository extends JpaRepository<CommonCode, String> {

    Optional<CommonCode> findByCodeGroupAndCode(String codeGroup, String code);
}
