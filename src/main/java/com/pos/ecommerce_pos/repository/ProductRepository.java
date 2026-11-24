package com.pos.ecommerce_pos.repository;

import com.pos.ecommerce_pos.model.Product;
import org.springframework.data.jpa.repository.JpaRepository;

import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface ProductRepository extends JpaRepository<Product, Long> {

    Optional<Product> findBySkuIgnoreCase(String sku);

    List<Product> findByNameContainingIgnoreCaseOrSkuContainingIgnoreCaseOrBarcodeContainingIgnoreCase(
            String name, String sku, String barcode

    );

    List<Product> findByCategoryId(Long categoryId);

    List<Product> findByActive(boolean active);

    boolean existsByCategoryId(Long categoryId);

    @Query(value =
        "SELECT " +
        "(SELECT COUNT(*) FROM product_variants WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM product_images WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM product_barcodes WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM reviews WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM warranties WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM stock_levels WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM inventory_valuation WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM stock_movements WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM batches WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM stock_in_items WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM stock_out_items WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM stock_transfer_items WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM lost_items WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM inventory_alerts WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM order_items WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM purchase_items WHERE product_id = :productId) + " +
        "(SELECT COUNT(*) FROM purchase_return_items WHERE product_id = :productId)",
        nativeQuery = true)
    Long countProductReferences(@Param("productId") Long productId);

}