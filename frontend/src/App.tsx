import { lazy, Suspense, useCallback, useEffect, useMemo, useState } from "react";
import {
  RiArchiveLine,
  RiArrowRightUpLine,
  RiBox3Line,
  RiBuildingLine,
  RiDashboardLine,
  RiDatabase2Line,
  RiRefreshLine,
  RiShoppingBag3Line,
  RiStackLine,
} from "@remixicon/react";
import { Button } from "@/components/base/buttons/button";
import { StatCards, type Stat } from "@/components/application/dashboard/stat-cards";
import { DirectionProvider } from "@/components/foundations/direction/direction";
import { fetchCatalog, fetchHealth } from "./api/catalog";
import type { Category, Product } from "./api/types";
import ProductManager from "./components/ProductManager";
import CategoryManager from "./components/CategoryManager";
import { useToast } from "./components/ToastProvider";
import "./dashboard.css";

const BarChart = lazy(() =>
  import("@/src/components/ui/bar-chart").then((module) => ({ default: module.BarChart })),
);

type CatalogState = {
  products: Product[];
  categories: Category[];
  loading: boolean;
  error: string | null;
};

const initialState: CatalogState = {
  products: [],
  categories: [],
  loading: true,
  error: null,
};

const countFormatter = new Intl.NumberFormat();
type Page = "overview" | "products" | "categories";
const pagePaths: Record<Page, string> = { overview: "/", products: "/products", categories: "/categories" };

function pageFromPath(pathname: string): Page {
  if (pathname === "/products") return "products";
  if (pathname === "/categories") return "categories";
  return "overview";
}

function getCategoryName(product: Product, categoryNames: Map<number, string>) {
  return product.categoryId == null
    ? "Uncategorized"
    : categoryNames.get(Number(product.categoryId)) ?? "Uncategorized";
}

function App() {
  const toast = useToast();
  const [page, setPage] = useState<Page>(() => pageFromPath(window.location.pathname));
  const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
  const [catalog, setCatalog] = useState<CatalogState>(initialState);
  const [refreshToken, setRefreshToken] = useState(0);
  const [health, setHealth] = useState<"checking" | "up" | "down">("checking");

  const refreshData = useCallback(() => setRefreshToken((value) => value + 1), []);

  useEffect(() => {
    const syncPage = () => setPage(pageFromPath(window.location.pathname));
    window.addEventListener("popstate", syncPage);
    return () => window.removeEventListener("popstate", syncPage);
  }, []);

  const navigate = (nextPage: Page, event?: React.MouseEvent<HTMLAnchorElement>) => {
    if (event && (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey || event.button !== 0)) return;
    event?.preventDefault();
    if (page !== nextPage) window.history.pushState({}, "", pagePaths[nextPage]);
    setPage(nextPage);
    setSidebarCollapsed(false);
    window.scrollTo({ top: 0, behavior: "smooth" });
  };

  const loadCatalog = useCallback(async (signal: AbortSignal) => {
    setCatalog((current) => ({ ...current, loading: true, error: null }));
    try {
      const result = await fetchCatalog(signal);
      setCatalog({ ...result, loading: false, error: null });
    } catch (error) {
      if (signal.aborted) return;
      setCatalog((current) => ({
        ...current,
        loading: false,
        error: error instanceof Error ? error.message : "The catalog could not be loaded.",
      }));
    }
  }, []);

  useEffect(() => {
    const controller = new AbortController();
    void loadCatalog(controller.signal);
    setHealth("checking");
    void fetchHealth(controller.signal).then((result) => {
      if (!controller.signal.aborted) setHealth(result.status === "UP" ? "up" : "down");
    }).catch(() => {
      if (!controller.signal.aborted) setHealth("down");
    });
    return () => controller.abort();
  }, [loadCatalog, refreshToken]);

  useEffect(() => {
    if (catalog.error) toast({ kind: "error", message: catalog.error });
  }, [catalog.error, toast]);

  const categoryNames = useMemo(
    () => new Map(catalog.categories.map((category) => [Number(category.id), category.name])),
    [catalog.categories],
  );

  const activeProducts = useMemo(
    () => catalog.products.filter((product) => product.active),
    [catalog.products],
  );

  const chartData = useMemo(() => {
    const counts = new Map<string, number>();
    for (const product of catalog.products) {
      const name = getCategoryName(product, categoryNames);
      counts.set(name, (counts.get(name) ?? 0) + 1);
    }
    const ordered = [...counts.entries()].sort((a, b) => b[1] - a[1]);
    const visible = ordered.slice(0, 7).map(([label, products]) => ({ label, products }));
    const remaining = ordered.slice(7).reduce((sum, [, products]) => sum + products, 0);
    if (remaining > 0) visible.push({ label: "Other categories", products: remaining });
    return visible;
  }, [catalog.products, categoryNames]);

  const stats: Stat[] = [
    {
      icon: RiBox3Line,
      label: "Total products",
      value: catalog.loading && catalog.products.length === 0 ? "…" : countFormatter.format(catalog.products.length),
      delta: catalog.error ? "Offline" : "Live",
      deltaColor: catalog.error ? "rose" : "neutral",
    },
    {
      icon: RiShoppingBag3Line,
      label: "Active products",
      value: catalog.loading && catalog.products.length === 0 ? "…" : countFormatter.format(activeProducts.length),
      delta: catalog.error ? "Offline" : "Live",
      deltaColor: catalog.error ? "rose" : "neutral",
    },
    {
      icon: RiStackLine,
      label: "Categories",
      value: catalog.loading && catalog.categories.length === 0 ? "…" : countFormatter.format(catalog.categories.length),
      delta: catalog.error ? "Offline" : "Live",
      deltaColor: catalog.error ? "rose" : "neutral",
    },
  ];

  const pageTitles: Record<Page, string> = { overview: "Overview", products: "Products", categories: "Categories" };
  const pageDescriptions: Record<Page, string> = {
    overview: "A live view of your product catalog and what needs attention.",
    products: "Manage product details, status, and catalog visibility.",
    categories: "Organize the products in your catalog.",
  };

  return (
    <DirectionProvider locale="en-GH">
      <div className={`qpos-shell${sidebarCollapsed ? " is-collapsed" : ""}`}>
        <aside className={`qpos-sidebar${sidebarCollapsed ? " is-collapsed" : ""}`} aria-label="Main navigation">
          <div className="qpos-sidebar-brand-row">
          <a href="/" onClick={(event) => navigate("overview", event)} className="qpos-brand" aria-label="QPOS overview">
            <span className="qpos-brand-mark" aria-hidden="true">Q</span>
            <span className="qpos-brand-word">QPOS<span>++</span></span>
          </a>
          <button type="button" className="sidebar-toggle" onClick={() => setSidebarCollapsed((value) => !value)} aria-label={sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar"} aria-expanded={!sidebarCollapsed} title={sidebarCollapsed ? "Expand sidebar" : "Collapse sidebar"}>{sidebarCollapsed ? "›" : "‹"}</button>
          </div>
          <div className="qpos-workspace-label">RETAIL WORKSPACE</div>
          <nav className="qpos-nav">
            <a className={`qpos-nav-link${page === "overview" ? " is-active" : ""}`} href="/" onClick={(event) => navigate("overview", event)} aria-current={page === "overview" ? "page" : undefined} title="Overview">
              <RiDashboardLine aria-hidden="true" /> <span>Overview</span>
            </a>
            <a className={`qpos-nav-link${page === "products" ? " is-active" : ""}`} href="/products" onClick={(event) => navigate("products", event)} aria-current={page === "products" ? "page" : undefined} title="Products">
              <RiBox3Line aria-hidden="true" /> <span>Products</span>
            </a>
            <a className={`qpos-nav-link${page === "categories" ? " is-active" : ""}`} href="/categories" onClick={(event) => navigate("categories", event)} aria-current={page === "categories" ? "page" : undefined} title="Categories">
              <RiStackLine aria-hidden="true" /> <span>Categories</span>
            </a>
          </nav>
          <div className="qpos-sidebar-note">
            <RiDatabase2Line aria-hidden="true" />
            <div>
              <strong>Catalog connection</strong>
              <span>{health === "down" ? "Needs attention" : health === "checking" ? "Connecting…" : "Connected to API"}</span>
            </div>
            <span className={`connection-dot${catalog.error ? " is-error" : ""}`} aria-hidden="true" />
          </div>
          <div className="qpos-sidebar-footer">
            <div className="qpos-avatar" aria-hidden="true">Q</div>
            <div><strong>QPOS</strong><span>Point of sale</span></div>
          </div>
        </aside>

        <main className="qpos-main">
          <header className="qpos-topbar">
            <div className="qpos-breadcrumb"><span>Workspace</span><RiArrowRightUpLine aria-hidden="true" /><strong>{pageTitles[page]}</strong></div>
            <div className="qpos-topbar-actions">
              <span className={`api-status${health === "down" ? " is-error" : ""}`}>
                <span className="connection-dot" aria-hidden="true" />
                {health === "checking" ? "Checking API" : health === "down" ? "API unavailable" : "API connected"}
              </span>
                <Button
                variant="secondary"
                size="small"
                leadingIcon={RiRefreshLine}
                onClick={() => setRefreshToken((value) => value + 1)}
                disabled={catalog.loading}
                >
                Refresh data
              </Button>
            </div>
          </header>

          <div className="qpos-content">
            <section className="page-heading">
              <div>
                <p className="eyebrow">{page === "overview" ? "YOUR BUSINESS, AT A GLANCE" : "RETAIL WORKSPACE"}</p>
                <h1>{pageTitles[page]}</h1>
                <p className="heading-copy">{pageDescriptions[page]}</p>
              </div>
              {page === "overview" && <div className="heading-date"><RiBuildingLine aria-hidden="true" /><span>Store dashboard</span></div>}
            </section>

            {page === "overview" && <>
            <section aria-label="Catalog summary" className="summary-section">
              <div className="section-heading">
                <div><h2>Catalog summary</h2><p>Current totals from your product database</p></div>
                <span className="live-label"><span className="connection-dot" aria-hidden="true" /> Live data</span>
              </div>
              <StatCards stats={stats} variant="plain" columns={2} className="qpos-kpis" />
            </section>

            <section className="overview-grid" aria-label="Catalog and data connections">
              <article className="panel category-panel" id="category-chart">
                <div className="panel-heading">
                  <div><h2>Products by category</h2><p>All products, including inactive listings. Focus the chart and use arrow keys to inspect counts.</p></div>
                  <span className="panel-icon"><RiStackLine aria-hidden="true" /></span>
                </div>
                {catalog.loading && catalog.products.length === 0 ? (
                  <div className="chart-placeholder" aria-label="Loading category chart"><span /><span /><span /><span /><span /></div>
                ) : chartData.length > 0 ? (
                  <Suspense fallback={<div className="chart-loading" role="status">Loading category chart…</div>}>
                    <BarChart
                      data={chartData}
                      series={[{ key: "products", label: "Products", color: "var(--color-accent-600)" }]}
                      height={220}
                      showLegend={false}
                      animated={false}
                      formatTick={(value) => countFormatter.format(value)}
                      formatValue={(value) => `${countFormatter.format(value)} products`}
                      ariaLabel="Product count by category. The data table follows the chart."
                      className="qpos-category-chart"
                    />
                  </Suspense>
                ) : (
                  <div className="chart-empty"><span className="empty-icon"><RiStackLine aria-hidden="true" /></span><strong>No catalog data yet</strong><span>Add products to see a category breakdown.</span></div>
                )}
                <div className="chart-footer"><span>{countFormatter.format(catalog.products.length)} products</span><span>{countFormatter.format(catalog.categories.length)} categories</span></div>
              </article>

              <div className="data-panels">
                <article className="panel unavailable-panel">
                  <div className="unavailable-icon"><RiShoppingBag3Line aria-hidden="true" /></div>
                  <div className="unavailable-copy"><span className="unavailable-label">SALES OVERVIEW</span><strong>Not connected yet</strong><p>The current API doesn’t provide sales totals or order summaries.</p></div>
                  <span className="coming-tag">Unavailable</span>
                </article>
                <article className="panel unavailable-panel">
                  <div className="unavailable-icon stock-icon"><RiArchiveLine aria-hidden="true" /></div>
                  <div className="unavailable-copy"><span className="unavailable-label">INVENTORY STATUS</span><strong>Not connected yet</strong><p>Stock quantities aren’t returned by the product API.</p></div>
                  <span className="coming-tag">Unavailable</span>
                </article>
                <div className="connection-callout"><span className="callout-mark"><RiDatabase2Line aria-hidden="true" /></span><p>Sales and stock figures will appear here when their API data is available.</p></div>
              </div>
            </section>

            </>}

            {page === "products" && <ProductManager catalog={catalog} onChanged={refreshData} />}
            {page === "categories" && <CategoryManager categories={catalog.categories} onChanged={refreshData} />}

            <footer className="page-footer"><span>QPOS++</span><span>Retail operations dashboard</span></footer>
          </div>
        </main>
      </div>
    </DirectionProvider>
  );
}

export default App;
