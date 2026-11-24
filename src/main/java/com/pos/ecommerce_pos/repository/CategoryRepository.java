package com.pos.ecommerce_pos.repository;

import com.pos.ecommerce_pos.model.Category;
import org.springframework.data.jpa.repository.JpaRepository;

 import java.util.Optional;

public interface CategoryRepository extends JpaRepository<Category, Long> {

    Optional<Category> findByNameIgnoreCase(String name);

}