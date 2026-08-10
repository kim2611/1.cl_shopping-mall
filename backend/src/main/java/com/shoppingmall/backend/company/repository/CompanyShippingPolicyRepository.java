package com.shoppingmall.backend.company.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.company.entity.CompanyShippingPolicy;

public interface CompanyShippingPolicyRepository extends JpaRepository<CompanyShippingPolicy, String> {

    Optional<CompanyShippingPolicy> findByCompanyIdAndDelYn(String companyId, String delYn);
}
