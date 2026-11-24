# Backend and Database Findings

## Scope

This document records a read-only source review of the current workspace. The application code was not changed. The backend was not started, no MySQL connection was attempted, no API requests were made, and tests were not run. Findings about runtime behavior are therefore source-based and should be confirmed against the actual local database.

## Backend overview

The project is a Spring Boot REST API for product and category management. The entry point is `src/main/java/com/pos/ecommerce_pos/EcommercePosApplication.java`.

The request flow is:

```text
HTTP request -> controller -> service -> repository -> MySQL
```

- Controllers define HTTP routes.
- Services apply business checks and call repositories.
- Spring Data JPA repositories perform persistence operations.
- JPA entity classes map the product and category data.
- `GlobalExceptionHandler` returns structured validation and application errors.

The project uses Java 25 and Spring Boot 4.0.9, with Spring MVC, Spring Data JPA, validation, and the MySQL JDBC driver. These versions and dependencies are declared in `pom.xml`.

## API endpoints

The API base URL is `http://localhost:8080/api/v1` (Spring Boot's default port; no alternate port is configured in the reviewed properties).

### Health

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/health` | Returns an application health status and message. |

### Products

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/products` | List products. |
| `POST` | `/products` | Create a product. |
| `GET` | `/products/{id}` | Retrieve one product. |
| `PUT` | `/products/{id}` | Update a product. |
| `DELETE` | `/products/{id}` | Delete a product if the reference check permits it. |
| `GET` | `/products/search?keyword=...` | Search by product name, SKU, or barcode. |
| `GET` | `/products/category/{categoryId}` | List products with the specified category ID. |
| `GET` | `/products/active?active=true` | Filter products by active status. |
| `PUT` | `/products/{id}/activate` | Activate a product. |
| `PUT` | `/products/{id}/deactivate` | Deactivate a product. |

### Categories

| Method | Path | Purpose |
|---|---|---|
| `GET` | `/categories` | List categories. |
| `POST` | `/categories` | Create a category. |
| `GET` | `/categories/{id}` | Retrieve one category. |
| `PUT` | `/categories/{id}` | Update a category. |
| `DELETE` | `/categories/{id}` | Delete a category if it has no products. |

The route definitions are in `controller/ProductController.java`, `controller/CategoryController.java`, and `controller/HealthController.java`.

## Database connection configuration

`src/main/resources/application.properties` configures:

| Setting | Current configuration |
|---|---|
| Database engine | MySQL |
| Host and port | `localhost:3306` |
| Database name | `qpos_db` |
| Username | `root` |
| Password | `${QPOS_DB_PASSWORD}` environment variable |
| Hibernate schema behavior | `spring.jpa.hibernate.ddl-auto=update` |
| SQL logging | Enabled, with formatted SQL |

The database must be available before the application starts because Spring Boot initializes the configured datasource as part of startup.

### Local setup and start

1. Install and start MySQL.
2. Create the database if it does not exist:

   ```sql
   CREATE DATABASE qpos_db
     CHARACTER SET utf8mb4
     COLLATE utf8mb4_unicode_ci;
   ```

3. Ensure the configured MySQL account can connect to `qpos_db` and create or alter tables. The current username is `root`.
4. From the project root in PowerShell, set the password in the current terminal session and run the application:

   ```powershell
   $env:QPOS_DB_PASSWORD = '<your MySQL password>'
   .\mvnw.cmd spring-boot:run
   ```

5. Check the health route at `http://localhost:8080/api/v1/health`.

The health route reports application status; it does not prove every database query or mutation succeeds.

## Mapped database tables

There are two JPA entities in the reviewed source. Hibernate is configured to create or update their tables at application startup. No migration files, schema scripts, or seed data are present in the source tree.

### `categories`

Mapped by `model/Category.java`.

| Column | Definition/meaning |
|---|---|
| `category_id` | Auto-generated primary key. |
| `name` | Required and unique. |
| `description` | Optional. |
| `is_active` | Boolean active flag. New categories are set active in the service. |

### `products`

Mapped by `model/Product.java`.

| Column | Definition/meaning |
|---|---|
| `product_id` | Auto-generated primary key. |
| `sku` | Required and unique. |
| `barcode` | Optional and unique. |
| `name` | Required. |
| `description` | Optional. |
| `category_id` | Category identifier stored as a numeric field. |
| `brand_id` | Optional numeric identifier; no corresponding entity is present here. |
| `unit_id` | Optional numeric identifier; no corresponding entity is present here. |
| `cost_price` | Required decimal, precision 15 and scale 4. |
| `selling_price` | Required decimal, precision 15 and scale 4. |
| `tax_rate` | Required decimal, precision 15 and scale 4; initialized to zero in Java. |
| `is_active` | Boolean active flag; initialized to true for products. |
| `created_at` | Read-only from the entity (`insertable=false`, `updatable=false`). |

The entity does not declare a default or timestamp generator for `created_at`. Its value depends on the actual database column definition; it may remain null if the column has no database default.

## Data validation and business rules

The service and entity validation code currently enforces these rules through the API:

- Product SKU and category name are required.
- Product SKU and category name are checked for case-insensitive duplicates.
- A product must have a category ID that resolves to an existing category when created or updated.
- Cost price, selling price, and tax rate must be present and nonnegative.
- Selling price cannot be lower than cost price.
- New products and categories are set active.
- A category cannot be deleted through the API while any product uses its ID.
- Product deletion is blocked when the repository's reference-count query finds references; the error recommends deactivation instead.

Validation annotations are on the entities. Service rules are in `service/ProductService.java`, `service/CategoryService.java`, and `service/ProductCategoryService.java`. Error formatting is in `exception/GlobalExceptionHandler.java`.

## Database integrity and implementation gaps

### Category relationship is not mapped as a foreign key

`Product.categoryId` is a plain `Long`; it is not a JPA `@ManyToOne` relationship. The API checks category existence in the service, but the entity does not declare a database foreign key. Direct SQL or another application could therefore create a product with an invalid category ID unless the actual database has a constraint created separately.

### Product deletion assumes additional tables

`repository/ProductRepository.java` contains a native reference-count query against all of these tables:

- `product_variants`
- `product_images`
- `product_barcodes`
- `reviews`
- `warranties`
- `stock_levels`
- `inventory_valuation`
- `stock_movements`
- `batches`
- `stock_in_items`
- `stock_out_items`
- `stock_transfer_items`
- `lost_items`
- `inventory_alerts`
- `order_items`
- `purchase_items`
- `purchase_return_items`

None of these tables has a mapped entity or migration in this workspace. If a referenced table is absent in the connected database, invoking product deletion may fail with a SQL error. Whether this is currently a problem depends on the live schema, which was not inspected.

### JDBC URL appears split across lines

The current properties contain:

```properties
spring.datasource.url=jdbc:mysql://localhost:3306/qpos_db?
useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC
```

Java `.properties` files do not normally concatenate adjacent lines. The second line may be parsed as a separate key rather than as URL parameters. Thus the SSL, public-key retrieval, and timezone options may not be applied as intended. This conclusion is based on source inspection; the effective runtime value was not checked.

### Automatic schema update and credentials

`ddl-auto=update` is useful for local development but is not a versioned migration strategy. The application account needs schema modification permissions. The configured `root` account also has broader privileges than a dedicated application account typically needs. Neither the current schema nor production deployment practices were assessed.

## Current backend scope

Implemented backend areas in this workspace:

- Product CRUD, search, category filtering, active filtering, activation/deactivation.
- Category CRUD, with a check that prevents category deletion while products refer to it.
- Health route and structured validation/application errors.

Not implemented as API/entity areas in the reviewed source:

- Checkout, sales, receipts, and payment processing.
- Inventory balances and stock movement operations.
- Purchasing, suppliers, returns, or transfers.
- Customers, authentication, roles, or user administration.
- Reporting.

Some related table names appear in the product deletion query, but their table definitions and APIs are absent from this workspace.

## React frontend status

There is no React frontend in the current workspace: no `package.json`, Vite configuration, or frontend source files were found. The existing backend could serve as the API for a future frontend, but a browser-based React app on another local port will need a CORS configuration or a development-server proxy before cross-origin API requests work.

## Verification status

This document reflects source inspection only. The backend was not run, MySQL was not connected, the database schema was not queried, endpoints were not exercised, and automated tests were not run. Runtime claims, including the JDBC URL parsing implications and availability of deletion-reference tables, remain to be confirmed in the target environment.
