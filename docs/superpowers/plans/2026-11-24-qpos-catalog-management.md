# QPOS Catalog Management Implementation Plan

## Scope guard

Only `frontend/` and the frontend API documentation in `docs/` may be changed. Do not modify Spring, Java, `pom.xml`, database, migrations, or backend configuration.

## Tasks

### 1. Extend the typed API client

- [x] Add reusable GET/POST/PUT/DELETE functions and structured backend error extraction.
- [x] Add product search/category/status/detail/create/update/delete/activate/deactivate functions.
- [x] Add category detail/create/update/delete functions and health check.
- [x] Confirm payload types reflect existing entity fields.

### 2. Add product management UI

- [x] Add create/edit forms with current backend validation constraints and required category.
- [x] Add detail read, activation controls, and confirmed deletion.
- [x] Drive product search and category/status filtering through existing API routes; intersect results for combined filters.
- [x] Refresh catalog data after successful mutations and preserve form data on error.

### 3. Add category management UI

- [x] Add list/detail/create/edit/delete interactions.
- [x] Show backend conflict messages when categories cannot be deleted.
- [x] Refresh category/product-derived data after changes.

### 4. Document and verify

- [x] Update `docs/frontend-backend-api.md` with UI actions, exact calls, payloads, validation, and errors.
- [x] Update frontend startup documentation.
- [x] Run the frontend production build and inspect changed file scope to confirm backend files are untouched.

Build result: `npm.cmd run build` succeeded. Main JavaScript is 344.94 kB minified (107.33 kB gzip); the lazy chart is 152.68 kB (52.64 kB gzip). No browser-driven CRUD flows were run. Changes in this task were limited to `frontend/` and `docs/`; backend files were not edited.

## Acceptance

- Product and category management features call only the existing routes.
- Errors and successful refreshes are visible in the UI.
- Frontend build succeeds; backend source/config/schema remain unchanged.
