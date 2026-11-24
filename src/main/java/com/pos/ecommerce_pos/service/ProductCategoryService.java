package com.pos.ecommerce_pos.service;

import com.pos.ecommerce_pos.model.Product;
import org.springframework.stereotype.Service;

@Service
public class ProductCategoryService {

    private final ProductService productService;
    private final CategoryService categoryService;

    public ProductCategoryService(
            ProductService productService,
            CategoryService categoryService) {

        this.productService = productService;
        this.categoryService = categoryService;
    }

    // Check whether a category can be deleted
    public void validateCategoryDeletion(Long categoryId) {

        categoryService.getCategoryById(categoryId);

        if (productService.hasProductsInCategory(categoryId)) {

            throw new org.springframework.web.server.ResponseStatusException(
                    org.springframework.http.HttpStatus.CONFLICT,
                    "Cannot delete category because it contains products."
            );
        }
    }
}