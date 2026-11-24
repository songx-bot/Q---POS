package com.pos.ecommerce_pos.controller;

import com.pos.ecommerce_pos.model.Product;
import com.pos.ecommerce_pos.service.ProductService;

import org.springframework.web.bind.annotation.*;

import jakarta.validation.Valid;

import java.util.List;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    private final ProductService productService;

    // Constructor injection
    public ProductController(ProductService productService) {
        this.productService = productService;
    }

    // Add a product
    @PostMapping
    public Product addProduct(@Valid @RequestBody Product product) {
        return productService.addProduct(product);
    }

    // Get all products
    @GetMapping
    public List<Product> getAllProducts() {
        return productService.getAllProducts();
    }

    // Get one product
    @GetMapping("/{id}")
    public Product getProductById(@PathVariable Long id) {
        return productService.getProductById(id);
    }

    // Search products by name, SKU or barcode
    @GetMapping("/search")
    public List<Product> searchProducts(@RequestParam String keyword) {
        return productService.searchProducts(keyword);
    }

    // Update a product
    @PutMapping("/{id}")
    public Product updateProduct(
            @PathVariable Long id,
            @Valid @RequestBody Product product) {

        return productService.updateProduct(id, product);
    }

    // Delete a product
    @DeleteMapping("/{id}")
    public void deleteProduct(@PathVariable Long id) {
        productService.deleteProduct(id);
    }

    @GetMapping("/category/{categoryId}")
    public List<Product> getProductsByCategoryId(@PathVariable Long categoryId) {
        return productService.getProductsByCategory(categoryId);
    }

    // Deactivate a product
    @PutMapping("/{id}/deactivate")
    public Product deactivateProduct(@PathVariable Long id) {
        return productService.deactivateProduct(id);
    }

    // Activate a product
    @PutMapping("/{id}/activate")
    public Product activateProduct(@PathVariable Long id) {
        return productService.activateProduct(id);
    }

    // Get products by active status
    @GetMapping("/active")
    public List<Product> getProductsActiveByStatus(@RequestParam("active") boolean active) {
        return productService.getProductsByActiveStatus(active);
    }
}