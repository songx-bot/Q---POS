package com.pos.ecommerce_pos.service;

import com.pos.ecommerce_pos.model.Product;
import com.pos.ecommerce_pos.repository.ProductRepository;

import org.springframework.stereotype.Service;
import org.springframework.http.HttpStatus;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Optional;

@Service
public class ProductService {

    private final ProductRepository productRepository;
    private final CategoryService categoryService;

    public ProductService(
            ProductRepository productRepository,
            CategoryService categoryService) {

        this.productRepository = productRepository;
        this.categoryService = categoryService;
    }

    private void validatePrices(Product product) {

        if (product.getCostPrice() != null
                && product.getSellingPrice() != null
                && product.getSellingPrice().compareTo(product.getCostPrice()) < 0) {

            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Selling price cannot be lower than cost price."
            );
        }
    }

    private void validateCategory(Long categoryId) {

        if (categoryId == null) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Category ID is required."
            );
        }

        categoryService.getCategoryById(categoryId);
    }

    private void checkDuplicateSku(String sku, Long excludedProductId) {

        if (sku == null || sku.isBlank()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Product SKU is required."
            );
        }

        Optional<Product> existingProduct =
                productRepository.findBySkuIgnoreCase(sku.trim());

        if (existingProduct.isPresent()
                && (excludedProductId == null
                || !existingProduct.get().getId().equals(excludedProductId))) {

            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Product with SKU '" + sku + "' already exists."
            );
        }
    }

    public Product addProduct(Product product) {

        validatePrices(product);
        validateCategory(product.getCategoryId());
        checkDuplicateSku(product.getSku(), null);

        product.setSku(product.getSku().trim());
        product.setActive(true);

        return productRepository.save(product);
    }

    public List<Product> getAllProducts() {
        return productRepository.findAll();
    }

    public List<Product> searchProducts(String keyword) {

        if (keyword == null || keyword.isBlank()) {
            return getAllProducts();
        }

        String searchTerm = keyword.trim();

        return productRepository
                .findByNameContainingIgnoreCaseOrSkuContainingIgnoreCaseOrBarcodeContainingIgnoreCase(
                        searchTerm,
                        searchTerm,
                        searchTerm
                );
    }

    public boolean hasProductsInCategory(Long categoryId) {
        return productRepository.existsByCategoryId(categoryId);
    }

    public Product getProductById(Long id) {

        return productRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Product not found"
                ));
    }

    public Product updateProduct(Long id, Product updatedProduct) {

        Product existingProduct = getProductById(id);

        validatePrices(updatedProduct);
        validateCategory(updatedProduct.getCategoryId());
        checkDuplicateSku(updatedProduct.getSku(), id);

        existingProduct.setName(updatedProduct.getName());
        existingProduct.setSku(updatedProduct.getSku().trim());
        existingProduct.setDescription(updatedProduct.getDescription());
        existingProduct.setCostPrice(updatedProduct.getCostPrice());
        existingProduct.setSellingPrice(updatedProduct.getSellingPrice());
        existingProduct.setBarcode(updatedProduct.getBarcode());
        existingProduct.setCategoryId(updatedProduct.getCategoryId());
        existingProduct.setBrandId(updatedProduct.getBrandId());
        existingProduct.setUnitId(updatedProduct.getUnitId());
        existingProduct.setTaxRate(updatedProduct.getTaxRate());

        return productRepository.save(existingProduct);
    }

    public Product deactivateProduct(Long id) {

        Product product = getProductById(id);
        product.setActive(false);

        return productRepository.save(product);
    }

    public Product activateProduct(Long id) {

        Product product = getProductById(id);
        product.setActive(true);

        return productRepository.save(product);
    }

    public void deleteProduct(Long id) {

        Product product = getProductById(id);

        Long referenceCount = productRepository.countProductReferences(id);

        if (referenceCount > 0) {
            throw new ResponseStatusException(
                HttpStatus.CONFLICT,
                "Cannot delete this product because it has references. DEACTIVATE the product instead of deleting it."
            );
        }

        productRepository.delete(product);
    }

    public List<Product> getProductsByCategory(Long categoryId) {
        return productRepository.findByCategoryId(categoryId);
    }

    public List<Product> getProductsByActiveStatus(boolean active) {
        return productRepository.findByActive(active);
    }
}