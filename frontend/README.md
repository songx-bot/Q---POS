# QPOS dashboard frontend

This folder contains the React dashboard. It reads products and categories from the Spring Boot API and does not modify backend or database files.

## Start the application

1. Start MySQL and the Spring Boot backend using [the backend and database setup guide](../docs/backend-database-setup.md). The backend should be available at `http://localhost:8080`.
2. In a separate PowerShell terminal, run:

   ```powershell
   cd C:\Users\Latitude\Downloads\pom\frontend
   npm.cmd install
   npm.cmd run dev
   ```

3. Open the Vite address shown in the terminal, usually `http://localhost:5173`.

Vite forwards requests under `/api` to the backend at port 8080. The dashboard reads `GET /api/v1/products` and `GET /api/v1/categories`.

The dashboard supports product and category search, filtering, create, edit, activate/deactivate, and delete flows through the existing API. See [Frontend and Backend API Connection](../docs/frontend-backend-api.md) for route mappings, payload fields, backend validation rules, proxy behavior, and the local verification record.

The app has separate pages at `/` (overview with cards and charts), `/products`, and `/categories`. Use the sidebar toggle to collapse or expand navigation.

Sales and stock summary panels are visibly unavailable because the current API does not expose those summaries. The dashboard does not use sample business metrics.
