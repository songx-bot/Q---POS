package com.pos.ecommerce_pos.controller;

import com.pos.ecommerce_pos.model.Category;
import com.pos.ecommerce_pos.service.CategoryService;
import com.pos.ecommerce_pos.service.ProductCategoryService;

import jakarta.validation.Valid;

import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/v1/categories")
public class CategoryController {

    private final CategoryService categoryService;
    private final ProductCategoryService productCategoryService;

    public CategoryController(
            CategoryService categoryService,
            ProductCategoryService productCategoryService) {

        this.categoryService = categoryService;
        this.productCategoryService = productCategoryService;
    }

    // Create category
    @PostMapping
    public Category addCategory(@Valid @RequestBody Category category) {
        return categoryService.addCategory(category);
    }

    // Get all categories
    @GetMapping
    public List<Category> getAllCategories() {
        return categoryService.getAllCategories();
    }

    // Get category by ID
    @GetMapping("/{id}")
    public Category getCategoryById(@PathVariable Long id) {
        return categoryService.getCategoryById(id);
    }

    // Update category
    @PutMapping("/{id}")
    public Category updateCategory(
            @PathVariable Long id,
            @Valid @RequestBody Category category) {

        return categoryService.updateCategory(id, category);
    }

    // Delete category
    @DeleteMapping("/{id}")
    public void deleteCategory(@PathVariable Long id) {

        productCategoryService.validateCategoryDeletion(id);

        categoryService.deleteCategory(id);
    }
}