package edu.posgroup4.qposplusplus;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.List;
import java.util.UUID;

/**
 * QPOS++ Point of Sale Checkout Service.
 * Transactional checkout: order header, line items, stock movement, inventory deduction,
 * invoice, and payment commit atomically.
 */
public final class PosSaleService {
    public record SaleLine(long productId, BigDecimal quantity, BigDecimal unitPrice) {}

    private final Database database;

    public PosSaleService(Database database) {
        this.database = database;
    }

    public long checkout(long storeId, long warehouseId, Long customerId, Long cashierId,
                         List<SaleLine> lines, String paymentMethod, BigDecimal paymentAmount)
            throws SQLException {
        if (lines == null || lines.isEmpty()) {
            throw new IllegalArgumentException("A QPOS++ sale requires at least one line item");
        }
        if (paymentAmount == null || paymentAmount.signum() <= 0) {
            throw new IllegalArgumentException("Payment amount must be positive");
        }

        try (Connection connection = database.connect()) {
            connection.setAutoCommit(false);
            try {
                BigDecimal total = BigDecimal.ZERO;
                for (SaleLine line : lines) {
                    if (line.quantity().signum() <= 0 || line.unitPrice().signum() < 0) {
                        throw new IllegalArgumentException("Quantity must be positive and unit price cannot be negative");
                    }
                    total = total.add(line.quantity().multiply(line.unitPrice()));
                }
                if (paymentAmount.compareTo(total) != 0) {
                    throw new IllegalArgumentException("Payment amount (" + paymentAmount + ") must equal order total (" + total + ")");
                }

                long orderId;
                String orderNumber = "QPOSPP-" + UUID.randomUUID();
                try (PreparedStatement insert = connection.prepareStatement(
                        "INSERT INTO orders(order_number,store_id,warehouse_id,customer_id,cashier_user_id,status,subtotal,total) " +
                                "VALUES(?,?,?,?,?,'COMPLETED',?,?)", PreparedStatement.RETURN_GENERATED_KEYS)) {
                    insert.setString(1, orderNumber);
                    insert.setLong(2, storeId);
                    insert.setLong(3, warehouseId);
                    if (customerId == null) insert.setNull(4, Types.BIGINT); else insert.setLong(4, customerId);
                    if (cashierId == null) insert.setNull(5, Types.BIGINT); else insert.setLong(5, cashierId);
                    insert.setBigDecimal(6, total);
                    insert.setBigDecimal(7, total);
                    insert.executeUpdate();
                    try (ResultSet keys = insert.getGeneratedKeys()) {
                        if (!keys.next()) throw new SQLException("QPOS++: MySQL did not return generated order ID");
                        orderId = keys.getLong(1);
                    }
                }

                for (SaleLine line : lines) {
                    BigDecimal lineTotal = line.quantity().multiply(line.unitPrice());
                    try (PreparedStatement insertLine = connection.prepareStatement(
                            "INSERT INTO order_items(order_id,product_id,quantity,unit_price,line_total) VALUES(?,?,?,?,?)")) {
                        insertLine.setLong(1, orderId);
                        insertLine.setLong(2, line.productId());
                        insertLine.setBigDecimal(3, line.quantity());
                        insertLine.setBigDecimal(4, line.unitPrice());
                        insertLine.setBigDecimal(5, lineTotal);
                        insertLine.executeUpdate();
                    }

                    try (PreparedStatement decrement = connection.prepareStatement(
                            "UPDATE stock_levels SET quantity=quantity-? WHERE product_id=? AND warehouse_id=? AND quantity>=?")) {
                        decrement.setBigDecimal(1, line.quantity());
                        decrement.setLong(2, line.productId());
                        decrement.setLong(3, warehouseId);
                        decrement.setBigDecimal(4, line.quantity());
                        if (decrement.executeUpdate() != 1) {
                            throw new SQLException("Insufficient stock or stock record missing for product ID " + line.productId());
                        }
                    }

                    // Decrement quantity via negated delta using standard '?' parameter placeholder
                    try (PreparedStatement movement = connection.prepareStatement(
                            "INSERT INTO stock_movements(product_id,warehouse_id,user_id,quantity_delta,movement_type,reference_type,reference_id) " +
                                    "VALUES(?,?,?,?,'SALE','ORDER',?)")) {
                        movement.setLong(1, line.productId());
                        movement.setLong(2, warehouseId);
                        if (cashierId == null) movement.setNull(3, Types.BIGINT); else movement.setLong(3, cashierId);
                        movement.setBigDecimal(4, line.quantity().negate());
                        movement.setLong(5, orderId);
                        movement.executeUpdate();
                    }
                }

                try (PreparedStatement payment = connection.prepareStatement(
                        "INSERT INTO payments(order_id,method,amount,status) VALUES(?,?,?,'PAID')")) {
                    payment.setLong(1, orderId);
                    payment.setString(2, paymentMethod);
                    payment.setBigDecimal(3, paymentAmount);
                    payment.executeUpdate();
                }

                try (PreparedStatement invoice = connection.prepareStatement(
                        "INSERT INTO invoices(order_id,invoice_number) VALUES(?,?)")) {
                    invoice.setLong(1, orderId);
                    invoice.setString(2, "INV-" + orderNumber);
                    invoice.executeUpdate();
                }

                connection.commit();
                return orderId;
            } catch (Exception failure) {
                connection.rollback();
                if (failure instanceof SQLException sqlFailure) throw sqlFailure;
                if (failure instanceof RuntimeException runtimeFailure) throw runtimeFailure;
                throw new SQLException("QPOS++ Sale checkout failed", failure);
            }
        }
    }
}
