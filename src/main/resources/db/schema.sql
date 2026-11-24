-- QPOS++ local database schema for MySQL 8.0+.
SET NAMES utf8mb4;

CREATE DATABASE IF NOT EXISTS qpos_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE qpos_db;

CREATE TABLE IF NOT EXISTS stores (
  store_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, store_code VARCHAR(255) NOT NULL UNIQUE, name VARCHAR(255) NOT NULL,
  phone VARCHAR(255), email VARCHAR(255), address TEXT, is_active BIGINT NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS store_settings (
  store_id BIGINT NOT NULL,
  setting_key VARCHAR(255) NOT NULL, setting_value VARCHAR(255) NOT NULL, PRIMARY KEY(store_id,setting_key)
);
CREATE TABLE IF NOT EXISTS store_targets (
  target_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, store_id BIGINT NOT NULL,
  target_month DATE NOT NULL, sales_target DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(sales_target >= 0),
  UNIQUE(store_id,target_month)
);
CREATE TABLE IF NOT EXISTS users (
  user_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, username VARCHAR(255) NOT NULL UNIQUE, email VARCHAR(255) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NOT NULL, status VARCHAR(255) NOT NULL DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE','LOCKED','DISABLED')),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_profiles (
  user_id BIGINT NOT NULL PRIMARY KEY,
  first_name VARCHAR(255), last_name VARCHAR(255), phone VARCHAR(255), avatar_path VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS roles (
  role_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, role_name VARCHAR(255) NOT NULL UNIQUE, description TEXT
);
CREATE TABLE IF NOT EXISTS permissions (
  permission_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, permission_key VARCHAR(255) NOT NULL UNIQUE, description TEXT
);
CREATE TABLE IF NOT EXISTS role_permissions (
  role_id BIGINT NOT NULL,
  permission_id BIGINT NOT NULL,
  PRIMARY KEY(role_id, permission_id)
);
CREATE TABLE IF NOT EXISTS employees (
  employee_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id BIGINT UNIQUE,
  store_id BIGINT, employee_code VARCHAR(255) NOT NULL UNIQUE,
  first_name VARCHAR(255) NOT NULL, last_name VARCHAR(255) NOT NULL, email VARCHAR(255), phone VARCHAR(255),
  hire_date DATE, employment_status VARCHAR(255) NOT NULL DEFAULT 'ACTIVE'
);
CREATE TABLE IF NOT EXISTS employee_roles (
  employee_id BIGINT NOT NULL,
  role_id BIGINT NOT NULL, PRIMARY KEY(employee_id, role_id)
);
CREATE TABLE IF NOT EXISTS sessions (
  session_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
  token_hash VARCHAR(255) NOT NULL UNIQUE, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  expires_at DATETIME NOT NULL, revoked_at DATETIME
);
CREATE TABLE IF NOT EXISTS password_reset_tokens (
  token_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
  token_hash VARCHAR(255) NOT NULL UNIQUE, expires_at DATETIME NOT NULL, used_at DATETIME
);
CREATE TABLE IF NOT EXISTS two_factor_codes (
  code_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
  code_hash VARCHAR(255) NOT NULL, expires_at DATETIME NOT NULL, used_at DATETIME
);
CREATE TABLE IF NOT EXISTS audit_logs (
  audit_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id BIGINT,
  action VARCHAR(255) NOT NULL, entity_type VARCHAR(255), entity_id BIGINT, details TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS user_settings (
  user_id BIGINT NOT NULL PRIMARY KEY,
  settings_json JSON NOT NULL
);

CREATE TABLE IF NOT EXISTS categories (
  category_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL UNIQUE, description TEXT,
  parent_category_id BIGINT
);
CREATE TABLE IF NOT EXISTS brands (
  brand_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL UNIQUE, description TEXT
);
CREATE TABLE IF NOT EXISTS units_of_measure (
  unit_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL UNIQUE, abbreviation VARCHAR(255) NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS products (
  product_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, sku VARCHAR(255) NOT NULL UNIQUE, barcode VARCHAR(255) UNIQUE,
  name VARCHAR(255) NOT NULL, description TEXT, category_id BIGINT,
  brand_id BIGINT, unit_id BIGINT,
  cost_price DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(cost_price >= 0),
  selling_price DECIMAL(15,4) NOT NULL CHECK(selling_price >= 0),
  tax_rate DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(tax_rate >= 0),
  is_active BIGINT NOT NULL DEFAULT 1 CHECK(is_active IN (0,1)),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS product_variants (
  variant_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  sku VARCHAR(255) NOT NULL UNIQUE, variant_name VARCHAR(255) NOT NULL, attributes_json JSON NOT NULL,
  price_adjustment DECIMAL(15,4) NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS product_images (
  image_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  file_path TEXT NOT NULL, is_primary BIGINT NOT NULL DEFAULT 0 CHECK(is_primary IN (0,1))
);
CREATE TABLE IF NOT EXISTS product_barcodes (
  barcode_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  barcode VARCHAR(255) NOT NULL UNIQUE, symbology VARCHAR(255) NOT NULL DEFAULT 'CODE128'
);
CREATE TABLE IF NOT EXISTS reviews (
  review_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  customer_id BIGINT, rating BIGINT NOT NULL CHECK(rating BETWEEN 1 AND 5), comment TEXT,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS warranties (
  warranty_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  customer_id BIGINT, order_id BIGINT,
  start_date DATE NOT NULL, end_date DATE NOT NULL, terms TEXT
);
CREATE TABLE IF NOT EXISTS import_batches (
  import_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id BIGINT, file_name VARCHAR(255) NOT NULL,
  status VARCHAR(255) NOT NULL DEFAULT 'PENDING', imported_count BIGINT NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS customers (
  customer_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, customer_code VARCHAR(255) UNIQUE, first_name VARCHAR(255) NOT NULL,
  last_name VARCHAR(255), email VARCHAR(255) UNIQUE, phone VARCHAR(255), customer_type VARCHAR(255) NOT NULL DEFAULT 'RETAIL',
  status VARCHAR(255) NOT NULL DEFAULT 'ACTIVE', created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS customer_addresses (
  address_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, customer_id BIGINT NOT NULL,
  label VARCHAR(255), address_line TEXT NOT NULL, city VARCHAR(255), region VARCHAR(255), country VARCHAR(255), is_default BIGINT NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS membership_plans (
  plan_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL UNIQUE, points_per_currency DECIMAL(15,4) NOT NULL DEFAULT 1,
  description TEXT
);
CREATE TABLE IF NOT EXISTS customer_memberships (
  membership_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, customer_id BIGINT NOT NULL,
  plan_id BIGINT NOT NULL, joined_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(customer_id, plan_id)
);
CREATE TABLE IF NOT EXISTS customer_notes (
  note_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, customer_id BIGINT NOT NULL,
  user_id BIGINT, note TEXT NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS customer_tags (
  tag_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, customer_id BIGINT NOT NULL,
  tag VARCHAR(255) NOT NULL, UNIQUE(customer_id,tag)
);
CREATE TABLE IF NOT EXISTS customer_wallet_transactions (
  wallet_txn_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, customer_id BIGINT NOT NULL,
  amount DECIMAL(15,4) NOT NULL CHECK(amount <> 0), txn_type VARCHAR(255) NOT NULL CHECK(txn_type IN ('CREDIT','DEBIT')),
  reference VARCHAR(255), created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS loyalty_points (
  loyalty_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, customer_id BIGINT NOT NULL,
  points BIGINT NOT NULL CHECK(points <> 0), reason VARCHAR(255) NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS suppliers (
  supplier_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, supplier_code VARCHAR(255) NOT NULL UNIQUE, name VARCHAR(255) NOT NULL,
  email VARCHAR(255), phone VARCHAR(255), address TEXT, status VARCHAR(255) NOT NULL DEFAULT 'ACTIVE'
);
CREATE TABLE IF NOT EXISTS supplier_companies (
  supplier_company_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, supplier_id BIGINT NOT NULL,
  company_name VARCHAR(255) NOT NULL, tax_identifier VARCHAR(255), contact_name VARCHAR(255)
);
CREATE TABLE IF NOT EXISTS supplier_bank_accounts (
  bank_account_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, supplier_id BIGINT NOT NULL,
  bank_name VARCHAR(255) NOT NULL, account_name VARCHAR(255) NOT NULL, account_number VARCHAR(255) NOT NULL
);
CREATE TABLE IF NOT EXISTS supplier_payments (
  supplier_payment_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, supplier_id BIGINT NOT NULL,
  purchase_id BIGINT, amount DECIMAL(15,4) NOT NULL CHECK(amount > 0),
  method VARCHAR(255) NOT NULL, paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS warehouses (
  warehouse_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, store_id BIGINT NOT NULL,
  name VARCHAR(255) NOT NULL, address TEXT, UNIQUE(store_id,name)
);
CREATE TABLE IF NOT EXISTS stock_levels (
  stock_level_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(quantity >= 0),
  reorder_level DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(reorder_level >= 0), UNIQUE(product_id,warehouse_id)
);
CREATE TABLE IF NOT EXISTS inventory_valuation (
  valuation_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL,
  unit_cost DECIMAL(15,4) NOT NULL CHECK(unit_cost >= 0), valued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS stock_movements (
  movement_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL, user_id BIGINT,
  quantity_delta DECIMAL(15,4) NOT NULL CHECK(quantity_delta <> 0), movement_type VARCHAR(255) NOT NULL,
  reference_type VARCHAR(255), reference_id BIGINT, note TEXT, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS batches (
  batch_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL, supplier_id BIGINT,
  batch_code VARCHAR(255) NOT NULL, expiry_date DATE, quantity DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(quantity >= 0),
  UNIQUE(product_id,warehouse_id,batch_code)
);
CREATE TABLE IF NOT EXISTS stock_adjustments (
  adjustment_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, warehouse_id BIGINT NOT NULL,
  user_id BIGINT, reason VARCHAR(255) NOT NULL, status VARCHAR(255) NOT NULL DEFAULT 'POSTED',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS stock_ins (
  stock_in_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, warehouse_id BIGINT NOT NULL,
  supplier_id BIGINT, user_id BIGINT,
  received_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS stock_in_items (
  stock_in_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, stock_in_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0), unit_cost DECIMAL(15,4) NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS stock_outs (
  stock_out_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, warehouse_id BIGINT NOT NULL,
  user_id BIGINT, reason VARCHAR(255) NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS stock_out_items (
  stock_out_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, stock_out_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0)
);
CREATE TABLE IF NOT EXISTS stock_transfers (
  transfer_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, source_warehouse_id BIGINT NOT NULL,
  destination_warehouse_id BIGINT NOT NULL, user_id BIGINT,
  status VARCHAR(255) NOT NULL DEFAULT 'COMPLETED', created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CHECK(source_warehouse_id <> destination_warehouse_id)
);
CREATE TABLE IF NOT EXISTS stock_transfer_items (
  transfer_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, transfer_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0)
);
CREATE TABLE IF NOT EXISTS lost_items (
  lost_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0),
  reason VARCHAR(255) NOT NULL, reported_by BIGINT, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS inventory_alerts (
  alert_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, product_id BIGINT NOT NULL,
  warehouse_id BIGINT NOT NULL, alert_type VARCHAR(255) NOT NULL,
  status VARCHAR(255) NOT NULL DEFAULT 'OPEN', created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS orders (
  order_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, order_number VARCHAR(255) NOT NULL UNIQUE,
  store_id BIGINT NOT NULL, warehouse_id BIGINT NOT NULL,
  customer_id BIGINT, cashier_user_id BIGINT,
  status VARCHAR(255) NOT NULL DEFAULT 'COMPLETED' CHECK(status IN ('HELD','COMPLETED','CANCELLED','REFUNDED')),
  subtotal DECIMAL(15,4) NOT NULL CHECK(subtotal >= 0), discount_total DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(discount_total >= 0),
  tax_total DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(tax_total >= 0), total DECIMAL(15,4) NOT NULL CHECK(total >= 0),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS order_items (
  order_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, order_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL, variant_id BIGINT,
  quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0), unit_price DECIMAL(15,4) NOT NULL CHECK(unit_price >= 0),
  discount DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(discount >= 0), tax DECIMAL(15,4) NOT NULL DEFAULT 0 CHECK(tax >= 0),
  line_total DECIMAL(15,4) NOT NULL CHECK(line_total >= 0)
);
CREATE TABLE IF NOT EXISTS payments (
  payment_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, order_id BIGINT NOT NULL,
  method VARCHAR(255) NOT NULL, amount DECIMAL(15,4) NOT NULL CHECK(amount > 0), reference VARCHAR(255),
  status VARCHAR(255) NOT NULL DEFAULT 'PAID', paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS invoices (
  invoice_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, order_id BIGINT NOT NULL UNIQUE,
  invoice_number VARCHAR(255) NOT NULL UNIQUE, issued_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS invoice_items (
  invoice_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, invoice_id BIGINT NOT NULL,
  product_description VARCHAR(255) NOT NULL, quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0),
  unit_price DECIMAL(15,4) NOT NULL CHECK(unit_price >= 0), line_total DECIMAL(15,4) NOT NULL CHECK(line_total >= 0)
);
CREATE TABLE IF NOT EXISTS held_bills (
  held_bill_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, store_id BIGINT NOT NULL,
  cashier_user_id BIGINT, bill_json JSON NOT NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS refunds (
  refund_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, order_id BIGINT NOT NULL,
  payment_id BIGINT, user_id BIGINT,
  amount DECIMAL(15,4) NOT NULL CHECK(amount > 0), reason VARCHAR(255) NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS refund_items (
  refund_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, refund_id BIGINT NOT NULL,
  order_item_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0)
);
CREATE TABLE IF NOT EXISTS purchases (
  purchase_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, purchase_number VARCHAR(255) NOT NULL UNIQUE,
  supplier_id BIGINT NOT NULL, warehouse_id BIGINT NOT NULL,
  status VARCHAR(255) NOT NULL DEFAULT 'RECEIVED', total DECIMAL(15,4) NOT NULL CHECK(total >= 0),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS purchase_items (
  purchase_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, purchase_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0),
  unit_cost DECIMAL(15,4) NOT NULL CHECK(unit_cost >= 0)
);
CREATE TABLE IF NOT EXISTS purchase_payments (
  purchase_payment_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, purchase_id BIGINT NOT NULL,
  amount DECIMAL(15,4) NOT NULL CHECK(amount > 0), method VARCHAR(255) NOT NULL, paid_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS purchase_returns (
  purchase_return_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, purchase_id BIGINT NOT NULL,
  reason VARCHAR(255) NOT NULL, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS purchase_return_items (
  return_item_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, purchase_return_id BIGINT NOT NULL,
  product_id BIGINT NOT NULL, quantity DECIMAL(15,4) NOT NULL CHECK(quantity > 0)
);

CREATE TABLE IF NOT EXISTS bank_accounts (
  bank_account_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, store_id BIGINT, name VARCHAR(255) NOT NULL,
  currency_code VARCHAR(255) NOT NULL DEFAULT 'GHS', account_number VARCHAR(255), opening_balance DECIMAL(15,4) NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS expense_categories (
  expense_category_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL UNIQUE
);
CREATE TABLE IF NOT EXISTS expenses (
  expense_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, expense_category_id BIGINT,
  bank_account_id BIGINT, user_id BIGINT,
  amount DECIMAL(15,4) NOT NULL CHECK(amount > 0), description TEXT NOT NULL, spent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS income_entries (
  income_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, bank_account_id BIGINT,
  amount DECIMAL(15,4) NOT NULL CHECK(amount > 0), description TEXT NOT NULL, received_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS transfers (
  transfer_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, from_account_id BIGINT NOT NULL,
  to_account_id BIGINT NOT NULL, amount DECIMAL(15,4) NOT NULL CHECK(amount > 0),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, CHECK(from_account_id <> to_account_id)
);
CREATE TABLE IF NOT EXISTS currencies (
  currency_code VARCHAR(3) PRIMARY KEY, name VARCHAR(255) NOT NULL, symbol VARCHAR(255) NOT NULL, is_base BIGINT NOT NULL DEFAULT 0
);
CREATE TABLE IF NOT EXISTS tax_rates (
  tax_rate_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL UNIQUE, rate DECIMAL(15,4) NOT NULL CHECK(rate >= 0), is_active BIGINT NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS coupons (
  coupon_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, code VARCHAR(255) NOT NULL UNIQUE, discount_type VARCHAR(255) NOT NULL CHECK(discount_type IN ('PERCENT','FIXED')),
  discount_value DECIMAL(15,4) NOT NULL CHECK(discount_value > 0), starts_at DATETIME, ends_at DATETIME, is_active BIGINT NOT NULL DEFAULT 1
);
CREATE TABLE IF NOT EXISTS company_settings (
  setting_key VARCHAR(100) PRIMARY KEY, setting_value VARCHAR(255) NOT NULL, updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS calendar_events (
  event_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, title VARCHAR(255) NOT NULL, starts_at DATETIME NOT NULL, ends_at DATETIME NOT NULL,
  created_by BIGINT, category VARCHAR(255), CHECK(ends_at >= starts_at)
);
CREATE TABLE IF NOT EXISTS calendar_event_guests (
  event_id BIGINT NOT NULL,
  employee_id BIGINT NOT NULL, PRIMARY KEY(event_id,employee_id)
);
CREATE TABLE IF NOT EXISTS chat_conversations (
  conversation_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS chat_messages (
  message_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, conversation_id BIGINT,
  sender_user_id BIGINT NOT NULL, body TEXT NOT NULL,
  sent_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS emails (
  email_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, sender_user_id BIGINT, recipient VARCHAR(255) NOT NULL,
  subject VARCHAR(255) NOT NULL, body TEXT NOT NULL, sent_at DATETIME
);
CREATE TABLE IF NOT EXISTS email_queue (
  queue_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, recipient VARCHAR(255) NOT NULL, subject VARCHAR(255) NOT NULL, body TEXT NOT NULL,
  status VARCHAR(255) NOT NULL DEFAULT 'PENDING', created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
);
CREATE TABLE IF NOT EXISTS notification_settings (
  user_id BIGINT NOT NULL, notification_key VARCHAR(255) NOT NULL,
  enabled BIGINT NOT NULL DEFAULT 1 CHECK(enabled IN (0,1)), PRIMARY KEY(user_id,notification_key)
);
CREATE TABLE IF NOT EXISTS plans (
  plan_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, name VARCHAR(255) NOT NULL UNIQUE, price DECIMAL(15,4) NOT NULL CHECK(price >= 0),
  billing_period VARCHAR(255) NOT NULL DEFAULT 'MONTHLY'
);
CREATE TABLE IF NOT EXISTS subscriptions (
  subscription_id BIGINT NOT NULL AUTO_INCREMENT PRIMARY KEY, user_id BIGINT NOT NULL,
  plan_id BIGINT NOT NULL, status VARCHAR(255) NOT NULL DEFAULT 'ACTIVE',
  starts_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP, ends_at DATETIME
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_stock_warehouse_product ON stock_levels(warehouse_id,product_id);
CREATE INDEX idx_movements_product_date ON stock_movements(product_id,created_at);
CREATE INDEX idx_orders_store_date ON orders(store_id,created_at);
CREATE INDEX idx_orders_customer ON orders(customer_id,created_at);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_audit_user_date ON audit_logs(user_id,created_at);


-- Foreign keys are added after table creation so forward references are valid.
ALTER TABLE store_settings ADD CONSTRAINT fk_store_settings_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE CASCADE;
ALTER TABLE store_targets ADD CONSTRAINT fk_store_targets_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id) ON DELETE CASCADE;
ALTER TABLE user_profiles ADD CONSTRAINT fk_user_profiles_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE role_permissions ADD CONSTRAINT fk_role_permissions_permission_id FOREIGN KEY (permission_id) REFERENCES permissions(permission_id) ON DELETE CASCADE;
ALTER TABLE role_permissions ADD CONSTRAINT fk_role_permissions_role_id FOREIGN KEY (role_id) REFERENCES roles(role_id) ON DELETE CASCADE;
ALTER TABLE employees ADD CONSTRAINT fk_employees_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id);
ALTER TABLE employees ADD CONSTRAINT fk_employees_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE employee_roles ADD CONSTRAINT fk_employee_roles_role_id FOREIGN KEY (role_id) REFERENCES roles(role_id);
ALTER TABLE employee_roles ADD CONSTRAINT fk_employee_roles_employee_id FOREIGN KEY (employee_id) REFERENCES employees(employee_id) ON DELETE CASCADE;
ALTER TABLE sessions ADD CONSTRAINT fk_sessions_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE password_reset_tokens ADD CONSTRAINT fk_password_reset_tokens_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE two_factor_codes ADD CONSTRAINT fk_two_factor_codes_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE audit_logs ADD CONSTRAINT fk_audit_logs_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;
ALTER TABLE user_settings ADD CONSTRAINT fk_user_settings_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE categories ADD CONSTRAINT fk_categories_parent_category_id FOREIGN KEY (parent_category_id) REFERENCES categories(category_id);
ALTER TABLE products ADD CONSTRAINT fk_products_unit_id FOREIGN KEY (unit_id) REFERENCES units_of_measure(unit_id);
ALTER TABLE products ADD CONSTRAINT fk_products_brand_id FOREIGN KEY (brand_id) REFERENCES brands(brand_id);
ALTER TABLE products ADD CONSTRAINT fk_products_category_id FOREIGN KEY (category_id) REFERENCES categories(category_id);
ALTER TABLE product_variants ADD CONSTRAINT fk_product_variants_product_id FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE;
ALTER TABLE product_images ADD CONSTRAINT fk_product_images_product_id FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE;
ALTER TABLE product_barcodes ADD CONSTRAINT fk_product_barcodes_product_id FOREIGN KEY (product_id) REFERENCES products(product_id) ON DELETE CASCADE;
ALTER TABLE reviews ADD CONSTRAINT fk_reviews_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE reviews ADD CONSTRAINT fk_reviews_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE warranties ADD CONSTRAINT fk_warranties_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE warranties ADD CONSTRAINT fk_warranties_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE warranties ADD CONSTRAINT fk_warranties_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE import_batches ADD CONSTRAINT fk_import_batches_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE customer_addresses ADD CONSTRAINT fk_customer_addresses_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE;
ALTER TABLE customer_memberships ADD CONSTRAINT fk_customer_memberships_plan_id FOREIGN KEY (plan_id) REFERENCES membership_plans(plan_id);
ALTER TABLE customer_memberships ADD CONSTRAINT fk_customer_memberships_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE customer_notes ADD CONSTRAINT fk_customer_notes_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE customer_notes ADD CONSTRAINT fk_customer_notes_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE;
ALTER TABLE customer_tags ADD CONSTRAINT fk_customer_tags_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id) ON DELETE CASCADE;
ALTER TABLE customer_wallet_transactions ADD CONSTRAINT fk_customer_wallet_transactions_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE loyalty_points ADD CONSTRAINT fk_loyalty_points_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE supplier_companies ADD CONSTRAINT fk_supplier_companies_supplier_id FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE CASCADE;
ALTER TABLE supplier_bank_accounts ADD CONSTRAINT fk_supplier_bank_accounts_supplier_id FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON DELETE CASCADE;
ALTER TABLE supplier_payments ADD CONSTRAINT fk_supplier_payments_purchase_id FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id);
ALTER TABLE supplier_payments ADD CONSTRAINT fk_supplier_payments_supplier_id FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id);
ALTER TABLE warehouses ADD CONSTRAINT fk_warehouses_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id);
ALTER TABLE stock_levels ADD CONSTRAINT fk_stock_levels_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE stock_levels ADD CONSTRAINT fk_stock_levels_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE inventory_valuation ADD CONSTRAINT fk_inventory_valuation_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE inventory_valuation ADD CONSTRAINT fk_inventory_valuation_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE stock_movements ADD CONSTRAINT fk_stock_movements_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE stock_movements ADD CONSTRAINT fk_stock_movements_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE stock_movements ADD CONSTRAINT fk_stock_movements_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE batches ADD CONSTRAINT fk_batches_supplier_id FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id);
ALTER TABLE batches ADD CONSTRAINT fk_batches_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE batches ADD CONSTRAINT fk_batches_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE stock_adjustments ADD CONSTRAINT fk_stock_adjustments_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE stock_adjustments ADD CONSTRAINT fk_stock_adjustments_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE stock_ins ADD CONSTRAINT fk_stock_ins_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE stock_ins ADD CONSTRAINT fk_stock_ins_supplier_id FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id);
ALTER TABLE stock_ins ADD CONSTRAINT fk_stock_ins_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE stock_in_items ADD CONSTRAINT fk_stock_in_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE stock_in_items ADD CONSTRAINT fk_stock_in_items_stock_in_id FOREIGN KEY (stock_in_id) REFERENCES stock_ins(stock_in_id) ON DELETE CASCADE;
ALTER TABLE stock_outs ADD CONSTRAINT fk_stock_outs_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE stock_outs ADD CONSTRAINT fk_stock_outs_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE stock_out_items ADD CONSTRAINT fk_stock_out_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE stock_out_items ADD CONSTRAINT fk_stock_out_items_stock_out_id FOREIGN KEY (stock_out_id) REFERENCES stock_outs(stock_out_id) ON DELETE CASCADE;
ALTER TABLE stock_transfers ADD CONSTRAINT fk_stock_transfers_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE stock_transfers ADD CONSTRAINT fk_stock_transfers_destination_warehouse_id FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE stock_transfers ADD CONSTRAINT fk_stock_transfers_source_warehouse_id FOREIGN KEY (source_warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE stock_transfer_items ADD CONSTRAINT fk_stock_transfer_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE stock_transfer_items ADD CONSTRAINT fk_stock_transfer_items_transfer_id FOREIGN KEY (transfer_id) REFERENCES stock_transfers(transfer_id) ON DELETE CASCADE;
ALTER TABLE lost_items ADD CONSTRAINT fk_lost_items_reported_by FOREIGN KEY (reported_by) REFERENCES users(user_id);
ALTER TABLE lost_items ADD CONSTRAINT fk_lost_items_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE lost_items ADD CONSTRAINT fk_lost_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE inventory_alerts ADD CONSTRAINT fk_inventory_alerts_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE inventory_alerts ADD CONSTRAINT fk_inventory_alerts_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE orders ADD CONSTRAINT fk_orders_cashier_user_id FOREIGN KEY (cashier_user_id) REFERENCES users(user_id);
ALTER TABLE orders ADD CONSTRAINT fk_orders_customer_id FOREIGN KEY (customer_id) REFERENCES customers(customer_id);
ALTER TABLE orders ADD CONSTRAINT fk_orders_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE orders ADD CONSTRAINT fk_orders_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id);
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_variant_id FOREIGN KEY (variant_id) REFERENCES product_variants(variant_id);
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE order_items ADD CONSTRAINT fk_order_items_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE payments ADD CONSTRAINT fk_payments_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE invoices ADD CONSTRAINT fk_invoices_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE invoice_items ADD CONSTRAINT fk_invoice_items_invoice_id FOREIGN KEY (invoice_id) REFERENCES invoices(invoice_id) ON DELETE CASCADE;
ALTER TABLE held_bills ADD CONSTRAINT fk_held_bills_cashier_user_id FOREIGN KEY (cashier_user_id) REFERENCES users(user_id);
ALTER TABLE held_bills ADD CONSTRAINT fk_held_bills_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id);
ALTER TABLE refunds ADD CONSTRAINT fk_refunds_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE refunds ADD CONSTRAINT fk_refunds_payment_id FOREIGN KEY (payment_id) REFERENCES payments(payment_id);
ALTER TABLE refunds ADD CONSTRAINT fk_refunds_order_id FOREIGN KEY (order_id) REFERENCES orders(order_id);
ALTER TABLE refund_items ADD CONSTRAINT fk_refund_items_order_item_id FOREIGN KEY (order_item_id) REFERENCES order_items(order_item_id);
ALTER TABLE refund_items ADD CONSTRAINT fk_refund_items_refund_id FOREIGN KEY (refund_id) REFERENCES refunds(refund_id) ON DELETE CASCADE;
ALTER TABLE purchases ADD CONSTRAINT fk_purchases_warehouse_id FOREIGN KEY (warehouse_id) REFERENCES warehouses(warehouse_id);
ALTER TABLE purchases ADD CONSTRAINT fk_purchases_supplier_id FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id);
ALTER TABLE purchase_items ADD CONSTRAINT fk_purchase_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE purchase_items ADD CONSTRAINT fk_purchase_items_purchase_id FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id);
ALTER TABLE purchase_payments ADD CONSTRAINT fk_purchase_payments_purchase_id FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id);
ALTER TABLE purchase_returns ADD CONSTRAINT fk_purchase_returns_purchase_id FOREIGN KEY (purchase_id) REFERENCES purchases(purchase_id);
ALTER TABLE purchase_return_items ADD CONSTRAINT fk_purchase_return_items_product_id FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE purchase_return_items ADD CONSTRAINT fk_purchase_return_items_purchase_return_id FOREIGN KEY (purchase_return_id) REFERENCES purchase_returns(purchase_return_id);
ALTER TABLE bank_accounts ADD CONSTRAINT fk_bank_accounts_store_id FOREIGN KEY (store_id) REFERENCES stores(store_id);
ALTER TABLE expenses ADD CONSTRAINT fk_expenses_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
ALTER TABLE expenses ADD CONSTRAINT fk_expenses_bank_account_id FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(bank_account_id);
ALTER TABLE expenses ADD CONSTRAINT fk_expenses_expense_category_id FOREIGN KEY (expense_category_id) REFERENCES expense_categories(expense_category_id);
ALTER TABLE income_entries ADD CONSTRAINT fk_income_entries_bank_account_id FOREIGN KEY (bank_account_id) REFERENCES bank_accounts(bank_account_id);
ALTER TABLE transfers ADD CONSTRAINT fk_transfers_to_account_id FOREIGN KEY (to_account_id) REFERENCES bank_accounts(bank_account_id);
ALTER TABLE transfers ADD CONSTRAINT fk_transfers_from_account_id FOREIGN KEY (from_account_id) REFERENCES bank_accounts(bank_account_id);
ALTER TABLE calendar_events ADD CONSTRAINT fk_calendar_events_created_by FOREIGN KEY (created_by) REFERENCES users(user_id);
ALTER TABLE calendar_event_guests ADD CONSTRAINT fk_calendar_event_guests_employee_id FOREIGN KEY (employee_id) REFERENCES employees(employee_id);
ALTER TABLE calendar_event_guests ADD CONSTRAINT fk_calendar_event_guests_event_id FOREIGN KEY (event_id) REFERENCES calendar_events(event_id) ON DELETE CASCADE;
ALTER TABLE chat_messages ADD CONSTRAINT fk_chat_messages_sender_user_id FOREIGN KEY (sender_user_id) REFERENCES users(user_id);
ALTER TABLE chat_messages ADD CONSTRAINT fk_chat_messages_conversation_id FOREIGN KEY (conversation_id) REFERENCES chat_conversations(conversation_id);
ALTER TABLE emails ADD CONSTRAINT fk_emails_sender_user_id FOREIGN KEY (sender_user_id) REFERENCES users(user_id);
ALTER TABLE notification_settings ADD CONSTRAINT fk_notification_settings_user_id FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE;
ALTER TABLE subscriptions ADD CONSTRAINT fk_subscriptions_plan_id FOREIGN KEY (plan_id) REFERENCES plans(plan_id);
ALTER TABLE subscriptions ADD CONSTRAINT fk_subscriptions_user_id FOREIGN KEY (user_id) REFERENCES users(user_id);
