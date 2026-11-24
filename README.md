# QPOS++ Point of Sale

QPOS++ is a point of sale project with a React dashboard and a Spring Boot REST API. The current working slice focuses on the product catalog: viewing and managing products and categories, and seeing catalog totals in the dashboard.

## What is built

### Frontend

The React + TypeScript application is in [`frontend/`](frontend/). It uses Vite, Tailwind CSS, shared BoardUI-style components, and EasyUI-inspired chart components. The interface follows the QPOS++ orange and white brand palette.

- **Overview (`/`)** shows total products, active products, and categories, plus a products-by-category chart.
- **Products (`/products`)** has its own page for searching, filtering by category and active status, creating, editing, activating/deactivating, and deleting products.
- **Categories (`/categories`)** has its own page for creating, editing, and deleting categories.
- The sidebar can collapse, and the header and sidebar show API connection status.
- Success, warning, and error feedback uses toast notifications.
- Sales and inventory dashboard areas are marked unavailable because the current REST API does not provide those data endpoints.

The frontend API calls and endpoint mapping are described in [`docs/frontend-backend-api.md`](docs/frontend-backend-api.md).

### Backend

The Spring Boot application is at the repository root. It uses Java 17, Spring Web MVC, Spring Data JPA, Bean Validation, and the MySQL Connector/J driver. The current REST API provides:

- `GET /api/v1/health` for a basic service status response.
- Product list, detail, search, category and active-status filters, create, update, activate/deactivate, and delete under `/api/v1/products`.
- Category list, detail, create, update, and delete under `/api/v1/categories`.
- Validation and API error handling through the global exception handler.

The backend setup and MySQL connection steps are in [`docs/backend-database-setup.md`](docs/backend-database-setup.md). Database notes and API behavior are documented in [`docs/backend-database-findings.md`](docs/backend-database-findings.md).

### Database

The local database is MySQL (`qpos_db`). Spring Boot reads its JDBC URL, username, and password from `QPOS_DB_URL`, `QPOS_DB_USER`, and `QPOS_DB_PASSWORD`; defaults are configured in `src/main/resources/application.properties`. Hibernate is configured with `ddl-auto=update` for the JPA entities currently used by the API (products and categories).

[`db/schema.sql`](db/schema.sql) contains a broader POS schema, including stores, users and roles, products, inventory, suppliers, customers, sales, and related records. Those schema tables do not mean corresponding REST endpoints or frontend features are already implemented. The current connected frontend/backend feature set is the catalog described above.

The repository also contains standalone Java POS classes under `src/main/java/edu/posgroup4/qposplusplus`; these are separate from the Spring controllers and are not the routes used by the React dashboard.

## Run locally on Windows

### Prerequisites

- Java 17 or newer (the Maven project compiler target is Java 17)
- MySQL Server 8
- Node.js and npm

### 1. Start MySQL and initialize the database

Start the MySQL Windows service from an Administrator Command Prompt:

```cmd
net start MySQL80
```

For a fresh database, load `db/schema.sql` with the MySQL client. The detailed commands and troubleshooting steps are in [`docs/backend-database-setup.md`](docs/backend-database-setup.md). Avoid rerunning schema SQL against data you need to preserve without first backing it up and reviewing the script.

### 2. Start the backend

From PowerShell in the repository root, set `QPOS_DB_PASSWORD` for the process and run the Maven wrapper. The setup guide provides a secure hidden-password prompt example. The API listens on `http://localhost:8080` by default.

Check the health endpoint at:

```text
http://localhost:8080/api/v1/health
```

### 3. Start the frontend

In a separate PowerShell window:

```powershell
cd C:\Users\Latitude\Downloads\pom\frontend
npm.cmd install
npm.cmd run dev
```

Open the Vite URL printed in the terminal (normally `http://localhost:5173`). During local development, Vite proxies `/api` requests to `http://localhost:8080`, so the browser uses the same origin for the dashboard and API calls.

## Project layout

```text
pom/
|-- db/                 MySQL POS schema
|-- docs/               Backend, database, API, and design notes
|-- frontend/           React + TypeScript dashboard
|-- src/main/java/      Spring Boot API and standalone Java POS classes
|-- src/main/resources/ Spring and database configuration
|-- src/test/           Backend test source
|-- mvnw, mvnw.cmd      Maven wrapper scripts
`-- pom.xml             Maven project configuration
```

## Current scope

The current connected workflow covers product and category catalog management. Authentication, sales transactions, inventory operations, and analytics backed by sales data are not currently available through the Spring REST API, even though the broader SQL schema includes tables for parts of the POS domain. See the API and database documents for route details and the known boundary between schema and implemented application behavior.
