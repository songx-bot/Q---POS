package com.pos.ecommerce_pos.service;

import com.pos.ecommerce_pos.model.Category;
import com.pos.ecommerce_pos.repository.CategoryRepository;

import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@Service
public class CategoryService {

    private final CategoryRepository categoryRepository;

    // Constructor injection
    public CategoryService(CategoryRepository categoryRepository) {
        this.categoryRepository = categoryRepository;
    }

    // Validate category name
    private void validateCategoryName(String name) {

        if (name == null || name.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Category name is required."
            );
        }
    }

    // Check for duplicate category names
    private void checkDuplicateCategoryName(String name, Long excludedCategoryId) {

        Optional<Category> existingCategory =
                categoryRepository.findByNameIgnoreCase(name.trim());

        if (existingCategory.isPresent()
                && (excludedCategoryId == null
                || !existingCategory.get().getId().equals(excludedCategoryId))) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "A category with this name already exists."
            );
        }
    }

    // Create a category
    public Category addCategory(Category category) {

        validateCategoryName(category.getName());

        checkDuplicateCategoryName(category.getName(), null);

        category.setName(category.getName().trim());
        category.setActive(true);

        return categoryRepository.save(category);
    }

    // Get all categories
    public List<Category> getAllCategories() {

        return categoryRepository.findAll();
    }

    // Get category by ID
    public Category getCategoryById(Long id) {

        return categoryRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Category not found"
                ));
    }

    // Update category
    public Category updateCategory(Long id, Category updatedCategory) {

        validateCategoryName(updatedCategory.getName());

        Category existingCategory = getCategoryById(id);

        checkDuplicateCategoryName(updatedCategory.getName(), id);

        existingCategory.setName(updatedCategory.getName().trim());
        existingCategory.setDescription(updatedCategory.getDescription());

        return categoryRepository.save(existingCategory);
    }

    // Delete category
    public void deleteCategory(Long id) {

        Category existingCategory = getCategoryById(id);

        categoryRepository.delete(existingCategory);
    }
}