# QPOS Catalog Management Design

## Intent

Extend the existing React dashboard so staff can use the current Spring product and category endpoints from the UI. Keep all Spring, database, and backend configuration files unchanged. Document the frontend-to-backend route mapping and operational constraints.

## Goals

- List and search products, filter by category and active status using the existing GET endpoints.
- Create, view, edit, activate/deactivate, and delete products using current routes.
- List, view, create, edit, and delete categories using current routes.
- Display backend validation/conflict/not-found messages and refresh dashboard data after successful changes.
- Keep forms aligned with existing entity fields and validation rules.
- Document endpoint use and how to run the integrated UI.

## Non-goals

- Any backend or database edits, new routes, authentication, sales, inventory, POS checkout, or stock adjustment.
- Invented data, client-side persistence, or writes executed during implementation.
- Editing brand/unit reference data because no corresponding endpoints exist in the reviewed backend.

## Approaches

1. **Build catalog management into the current dashboard (selected).** Add focused product and category forms/actions to existing catalog panels, with shared typed API functions. This keeps the first frontend release in one place and directly exercises the endpoints already present.
2. **Create separate management routes and a larger router shell.** This offers more room as the app grows, but introduces navigation and routing infrastructure before there are enough screens to justify it.
3. **Build list-only API calls and postpone mutations.** This is smaller but does not fulfill the request to build the frontend features for the existing backend endpoints.

## Data and behavior

- Products use `GET/POST /api/v1/products`, `GET/PUT/DELETE /api/v1/products/{id}`, `GET /search?keyword=...`, `GET /category/{categoryId}`, `GET /active?active=...`, and `PUT /{id}/activate|deactivate`.
- Categories use `GET/POST /api/v1/categories`, `GET/PUT/DELETE /api/v1/categories/{id}`.
- Health status uses `GET /api/v1/health` as a standalone connection check; catalog data remains loaded from its own endpoints.
- Product forms include SKU, barcode, name, description, category, brand ID, unit ID, cost price, selling price, and tax rate. Category is required by the current service for product creation/update; cost/selling/tax are nonnegative and selling price cannot be lower than cost.
- Category forms include name and description. Deleting a category with associated products is expected to return a conflict and will be shown to the user.
- Product deletion requires an explicit confirmation and displays server conflicts; deactivation is presented as the safer option when references prevent deletion.
- Successful writes refresh the product/category data and derived dashboard totals. Failed writes keep form values available for correction.
- Search and individual category/status filters use their existing server routes. When filters are combined, the frontend intersects the returned records by product ID.
- Sales and inventory remain unavailable because the backend has no such endpoints.

## Constraints and risks

- Existing routes return JPA entities directly, and error response shapes vary by error source. The client must safely present both structured backend messages and generic HTTP errors.
- There is no authentication or authorization layer visible in the current controllers; these screens assume the same trust boundary as the current local API.
- Local Vite proxies `/api` to port 8080. Production still needs a same-origin proxy or appropriate CORS configuration, which is outside this change.
- The local API may have an empty database, so reads can be verified while mutation flows still need user-driven data checks.

## Acceptance criteria

- Dashboard product/category list, search, and filters use existing API routes.
- Product and category CRUD/status actions use the existing routes and display API errors.
- Successful mutations refresh all visible derived data.
- `docs/frontend-backend-api.md` documents every UI action, request, and known backend validation behavior.
- Frontend build succeeds; no backend files are modified.
