# QPOS React Dashboard Design

## Intent

Create the first QPOS frontend as a daily operator dashboard with product and category management. Use the supplied QPOS++ logo image as the orange and white brand reference, React, EasyUI components, and free BoardUI dashboard components. Keep all backend and database files unchanged.

## Goals

- Provide a responsive dashboard shell with separate overview, products, and categories pages and collapsible navigation.
- Read products and categories from the existing Spring API and show catalog counts, current products, and category distribution from returned data.
- Use existing product/category endpoints for search, filtering, detail reads, create/update, product activation, and deletion.
- Include loading, empty, API error, retry, and filtered-empty states.
- Show sales and inventory summaries as unavailable because the current API does not expose those aggregates or stock levels.
- Make the frontend straightforward to run independently while the backend is available on port 8080.

## Non-goals

- Any Spring, database, schema, or backend configuration edits.
- Checkout, authentication, sales reporting, or stock management.
- Invented sales, revenue, order, or inventory metrics.
- BoardUI Pro templates or chart components.

## Approaches considered

1. **Frontend-only dashboard using the current API (selected).** Add a standalone React app; show live product/category data and explicit unavailable states for sales and stock. This meets the requested frontend-first scope and keeps figures truthful.
2. **Dashboard with sample sales and stock data.** This would make the screen look fuller, but could be mistaken for live business data, so it is not appropriate for the operational dashboard.
3. **Add backend aggregates before the dashboard.** This would enable live sales and inventory cards, but crosses the explicit backend boundary for this task.

## Data and endpoints

- `GET /api/v1/products`: product `id`, `sku`, `name`, `description`, `categoryId`, prices, `active`, and `createdAt`.
- `GET /api/v1/categories`: category `id`, `name`, `description`, and `active`.
- `GET /api/v1/health` is not required by the dashboard; fetch failures are handled at the product/category request layer.
- Vite development proxy forwards `/api` to `http://localhost:8080` so browser requests stay same-origin.
- Product category distribution is computed from the fetched product records and category IDs. Missing categories remain visible as “Uncategorized.”
- Sales and stock panels explain that the backend does not currently provide this data.

## Layout and interaction

- Overview page: QPOS++ shell, dashboard heading and refresh action, three catalog KPI cards, catalog category visualization, and two unavailable-data panels.
- Products page: searchable/filterable product management table and product create/edit/status/delete actions.
- Categories page: category management table and category create/edit/delete actions.
- Desktop navigation collapses to an icon rail; on small screens it moves to a collapsible horizontal navigation row.
- Small screens: navigation moves above the content and can be collapsed; KPI cards stack, chart and status panels stack, and management tables scroll horizontally within their own containers.
- Search matches product name, SKU, and barcode where present. Category and active-status filters apply to the visible product list.
- Refresh reloads products and categories. A retry action appears when loading fails.
- Orange is the primary action/accent; white surfaces and warm neutral background preserve contrast. Use the image for brand direction; do not assume screenshot viewer chrome is part of the logo.

## Component and platform decisions

- New isolated app at `frontend/` using React 19, TypeScript, Vite, and Tailwind CSS v4.
- BoardUI free `sidebar`, `stat-cards`, and `table` components provide dashboard primitives; EasyUI `bar-chart` visualizes fetched category counts.
- Do not install or use BoardUI Pro components.
- Use local component source so styling can follow the QPOS palette.

## Constraints and risks

- Backend endpoints return catalog data only; sales and stock must stay clearly unavailable.
- Existing create/update APIs require product category, SKU, name, cost/selling prices, and tax rate. The UI follows these constraints; brand and unit IDs remain optional because lookup endpoints do not exist.
- The backend has no CORS configuration, so local Vite uses a dev proxy. Any future production hosting arrangement may require a same-origin reverse proxy or backend CORS work, which is outside this task.
- Existing Java files, `pom.xml`, database schema, and backend properties are outside the allowed edit scope.

## Acceptance criteria

- `frontend/` contains a runnable React dashboard and its own startup instructions.
- Dashboard requests only existing backend endpoints and clearly reports loading, error, empty, and not-connected states.
- No backend/database files are changed.
- Interface is responsive and uses orange/white QPOS branding with EasyUI and free BoardUI components.
