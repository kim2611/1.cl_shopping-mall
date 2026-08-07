package com.shoppingmall.backend.catalog.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.shoppingmall.backend.catalog.entity.Category;

public interface CategoryRepository extends JpaRepository<Category, String> {
}
