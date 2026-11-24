# Frontend and Backend API Connection

## Scope

The React dashboard in `frontend/` uses the existing Spring Boot API for catalog reads and management. It does not introduce new backend routes or change the backend/database implementation.

No backend code, database schema, or backend configuration is changed by this integration.

## Local connection

- Spring Boot API base: `http://localhost:8080/api/v1`
- React dev server: usually `http://localhost:5173`
- Frontend pages: `/` (overview dashboard), `/products` (product management), and `/categories` (category management).
- Vite proxies requests beginning with `/api` to `http://localhost:8080` (`frontend/vite.config.ts`).
- The browser therefore requests same-origin paths such as `/api/v1/products`; it does not need a separate CORS configuration for local development.
- The left navigation collapses to an icon rail on desktop and can hide/show the top navigation on smaller screens.

Start MySQL and the backend using [the backend and database setup guide](backend-database-setup.md), then in a separate PowerShell window:

```powershell
cd C:\Users\Latitude\Downloads\pom\frontend
npm.cmd install
npm.cmd run dev
```

## Dashboard endpoints

| Request | Backend response | Dashboard use |
|---|---|---|
| `GET /api/v1/products` | JSON array of product records | Total and active product counts, category counts, and product table |
| `GET /api/v1/categories` | JSON array of category records | Category count, product category labels, and category filter options |
| `GET /api/v1/health` | JSON object with `status` and `message` | Manual connectivity check; dashboard does not poll this endpoint |

The dashboard loads products and categories together. A failed or non-2xx response from either catalog endpoint is shown as an API error with a retry action. An empty array is treated as a valid empty catalog.

## Frontend actions and route mapping

The React catalog management interface now maps actions to the backend routes as follows:

| UI action | Request | Behavior |
|---|---|---|
| Initial dashboard load / refresh | `GET /api/v1/products`, `GET /api/v1/categories`, `GET /api/v1/health` | Updates catalog totals and connection state |
| Product search | `GET /api/v1/products/search?keyword=...` | Searches name, SKU, and barcode; input is sent after a short typing pause |
| Category filter | `GET /api/v1/products/category/{categoryId}` | Retrieves products in the selected category |
| Status filter | `GET /api/v1/products/active?active=true|false` | Retrieves products for selected active status |
| Combined search and filters | Corresponding search/category/status GET routes | Intersects results by product ID; Uncategorized is filtered from the list response because no dedicated route exists |
| Open product edit | `GET /api/v1/products/{id}` | Reads current details before displaying the edit form |
| Add product | `POST /api/v1/products` | Submits product fields as JSON |
| Save product changes | `PUT /api/v1/products/{id}` | Submits the editable product fields as JSON |
| Activate / deactivate | `PUT /api/v1/products/{id}/activate` or `/deactivate` | Updates active status |
| Delete product | `DELETE /api/v1/products/{id}` | Requires browser confirmation; backend may reject referenced products with HTTP 409 |
| Open category edit | `GET /api/v1/categories/{id}` | Reads current details before displaying the edit form |
| Add category | `POST /api/v1/categories` | Submits `{ "name": string, "description": string|null }` |
| Save category changes | `PUT /api/v1/categories/{id}` | Submits `{ "name": string, "description": string|null }` |
| Delete category | `DELETE /api/v1/categories/{id}` | Requires browser confirmation; backend rejects categories that contain products |

Product create/update submits `sku`, `barcode`, `name`, `description`, `categoryId`, `brandId`, `unitId`, `costPrice`, `sellingPrice`, and `taxRate`. The UI requires a category, nonblank SKU/name, nonnegative prices/tax rate, and selling price greater than or equal to cost. Brand/unit IDs are optional because the API accepts IDs but provides no corresponding lookup or management routes in the current controllers.

All write actions refresh the dashboard and catalog after success. The client displays backend `message` and validation `errors` when provided; otherwise it falls back to the HTTP status. The product/category list and chart continue to represent the API data, and sales/stock panels remain unavailable.

## Notifications

Transient success, error, and warning feedback uses the shared toast viewport (`frontend/src/components/ToastProvider.tsx`). This includes validation feedback, API failures, and successful create/update/status/delete actions. Delete warnings are actionable toast notifications: choosing **Delete** submits the request; dismissing or allowing the warning to expire cancels it. Persistent connection state remains visible in the dashboard header/sidebar.

### Product response fields

`GET /api/v1/products` returns the `Product` entity as a JSON array. Its current fields are:

| Field | Type from backend model | Dashboard use |
|---|---|---|
| `id` | integer (`Long`) | Stable table row identifier |
| `sku` | string | Table and search |
| `barcode` | string or `null` | Search |
| `name` | string | Table and search |
| `description` | string or `null` | Available for future product detail UI |
| `categoryId` | integer (`Long`) or `null` | Category label, grouping, and filter |
| `brandId` | integer (`Long`) or `null` | Available from API; not currently displayed |
| `unitId` | integer (`Long`) or `null` | Available from API; not currently displayed |
| `costPrice` | decimal | Available from API; not currently displayed |
| `sellingPrice` | decimal | Product table, formatted as GHS |
| `taxRate` | decimal | Available from API; not currently displayed |
| `active` | boolean | Active count and status filter |
| `createdAt` | date-time string or `null` | Added date column |

The frontend accepts decimal values as either JSON numbers or strings for price formatting. Unknown or missing category references display as “Uncategorized”.

### Category response fields

`GET /api/v1/categories` returns a JSON array with `id` (integer), `name` (string), `description` (string or `null`), and `active` (boolean). The dashboard uses the ID and name for category labels, filters, and the category total.

## Other current catalog routes

These routes are declared by the existing Spring controllers. The React dashboard now calls the management routes as listed in the UI route mapping above.

### Products (`/api/v1/products`)

| Method | Route | Current behavior |
|---|---|---|
| `GET` | `/` | List all products |
| `POST` | `/` | Create a product; body is a validated product entity |
| `GET` | `/{id}` | Get one product |
| `PUT` | `/{id}` | Update a product; body is a validated product entity |
| `DELETE` | `/{id}` | Delete a product when no references prevent deletion |
| `GET` | `/search?keyword={text}` | Search name, SKU, and barcode |
| `GET` | `/category/{categoryId}` | List products for a category |
| `GET` | `/active?active=true` | List products by active state (`true` or `false`) |
| `PUT` | `/{id}/activate` | Activate a product |
| `PUT` | `/{id}/deactivate` | Deactivate a product |

Product creation and update validate required SKU/name/prices/tax rate, nonnegative prices/rate, category existence, selling price not below cost, and duplicate SKU. Creation sets the product active. Product deletion returns a conflict when the product has references; deactivation is the suggested alternative.

### Categories (`/api/v1/categories`)

| Method | Route | Current behavior |
|---|---|---|
| `GET` | `/` | List all categories |
| `POST` | `/` | Create a category |
| `GET` | `/{id}` | Get one category |
| `PUT` | `/{id}` | Update a category name and description |
| `DELETE` | `/{id}` | Delete a category when it has no products |

Category creation requires a nonblank, unique name and sets the category active. A category with products cannot be deleted.

## Errors and loading behavior

The frontend checks `response.ok`; non-2xx responses become a visible catalog error with the path and HTTP status. The backend's `GlobalExceptionHandler` returns:

- Validation errors: HTTP 400 with `{ "status": 400, "message": "Validation failed", "errors": { ... } }`.
- `ResponseStatusException`: its HTTP status with `{ "status": number, "message": string }`.

Other framework errors may use Spring's default error response. The dashboard currently presents a general retry message rather than interpreting endpoint-specific error bodies.

## Verification record

On 2026-11-24, read-only requests to the running local backend returned:

- `GET /api/v1/health`: HTTP 200, `status: UP`.
- `GET /api/v1/products`: HTTP 200, empty JSON array.
- `GET /api/v1/categories`: HTTP 200, empty JSON array.

This confirms those local routes were reachable at that time. It does not verify catalog behavior with populated records, any write route, or a deployed environment.

## Source mapping

- Frontend requests: `frontend/src/api/catalog.ts`
- Frontend response types: `frontend/src/api/types.ts`
- Vite proxy: `frontend/vite.config.ts`
- Product routes/model: `src/main/java/com/pos/ecommerce_pos/controller/ProductController.java`, `model/Product.java`
- Category routes/model: `src/main/java/com/pos/ecommerce_pos/controller/CategoryController.java`, `model/Category.java`
- Health route: `src/main/java/com/pos/ecommerce_pos/controller/HealthController.java`
- Error bodies: `src/main/java/com/pos/ecommerce_pos/exception/GlobalExceptionHandler.java`
