package com.shoppingmall.backend.catalog.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.catalog.entity.StockHistory;

public interface StockHistoryRepository extends JpaRepository<StockHistory, String> {
}
