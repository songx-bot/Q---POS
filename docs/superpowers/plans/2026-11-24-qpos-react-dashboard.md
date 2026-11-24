# QPOS React Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a responsive React dashboard frontend connected to the existing product and category GET APIs.

**Architecture:** Keep the Spring Boot project at the repository root. Create a standalone Vite app under `frontend/`; use a Vite `/api` proxy to the backend at port 8080. Fetch only existing catalog endpoints and derive counts/category distribution in the browser.

**Tech Stack:** React 19, TypeScript, Vite 7, Tailwind CSS 4, BoardUI free dashboard components, EasyUI bar chart.

**Spec:** `docs/superpowers/specs/2026-11-24-qpos-react-dashboard-design.md`

## Global Constraints

- Do not edit Spring, Java, `pom.xml`, database, schema, or `application.properties` files.
- Use existing product and category endpoints for reads and management actions; no new routes or sample business data.
- Never present sales/revenue/order or stock numbers as available; current API does not return these summaries.
- Do not install BoardUI Pro components.
- Keep the app in `frontend/` and preserve the existing backend project root.

## Review Focus

- API offline or non-2xx response: show a useful error and working retry action.
- Zero products/categories: show a first-use/empty state instead of misleading zero charts.
- Unknown `categoryId`: place product in an Uncategorized bucket.
- Long product names/SKUs and narrow screens: preserve readable table/card layout without page-level horizontal overflow.
- Sales and stock values unavailable: visibly communicate the missing data source without sample metrics.

---

### Task 1: Scaffold isolated React app and install free UI primitives

**Files:** Create `frontend/package.json`, Vite and TypeScript config, Tailwind setup, `frontend/index.html`, and BoardUI/EasyUI component source under `frontend/src`.

**Interfaces:** Dev server serves the React app; `/api/*` forwards to `http://localhost:8080`.

**Ruling:** Use a QPOS-specific sidebar shell instead of BoardUI's complete sidebar block. The block includes template navigation and demo account details that do not match this product; the dashboard still uses BoardUI's stat cards, input, select, and table components.

**Ruling:** Pin Vite 7 because the Vite 8 Rolldown native binding failed to load on this Windows environment; Vite 7 builds successfully here. This avoids asking for host security changes, at the cost of staying on the prior Vite major until the host issue is resolved.

- [x] Create Vite React TypeScript app in `frontend/` without touching root Java files.
- [x] Configure Tailwind CSS 4 and Vite proxy.
- [x] Add BoardUI free stat cards, input, select, and table components; add EasyUI bar chart component.
- [x] Add `frontend/README.md` with backend and frontend startup steps.

### Task 2: Implement dashboard data loading and view

**Files:** Create `frontend/src/App.tsx`, API client/types, dashboard sections, and responsive styles.

**Interfaces:** Fetch `Product[]` and `Category[]` from `/api/v1/products` and `/api/v1/categories`; expose retry/loading/error/empty state to the view.

- [x] Render QPOS sidebar/header, catalog KPIs, category counts, and product list using live API data.
- [x] Add product search and category/active filters.
- [x] Render explicit unavailable panels for sales and inventory summaries.
- [x] Make the layout responsive and provide labeled controls/keyboard access.

### Task 3: Build and scope review

**Files:** No backend files may be modified.

- [x] Review dependency install/build output; no automated tests were added or run.
- [x] Inspect created files and confirm backend source/config/schema were not edited.
- [x] Provide precise run instructions and any limitations.

Review follow-up: lazy-load the category chart, describe that its counts include inactive products, and show keyboard navigation guidance. Update the small-screen layout description to match the implemented horizontally scrollable top navigation row.

Build result: `npm.cmd run build` completed successfully on Vite 7.3.8 after review follow-up. The main JavaScript chunk is 575.18 kB minified (179.15 kB gzip); the lazy chart is 152.68 kB (52.63 kB gzip). Vite still reports the main chunk above its 500 kB warning threshold. No browser preview tool was available for visual review.
