import { useEffect, useState } from "react";
import type { Catalog, Product } from "../api/types";
import { deleteProduct, getProduct, getProductsByQuery, setProductActive, updateProduct, createProduct, type ProductInput } from "../api/catalog";
import ProductEditor from "./ProductEditor";
import { useToast } from "./ToastProvider";

type Props = { catalog: Catalog; onChanged: () => void };

function ProductManager({ catalog, onChanged }: Props) {
  const toast = useToast();
  const [products, setProducts] = useState<Product[]>(catalog.products);
  const [query, setQuery] = useState("");
  const [categoryId, setCategoryId] = useState("all");
  const [active, setActive] = useState("all");
  const [editProduct, setEditProduct] = useState<Product | null>(null);
  const [editorOpen, setEditorOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let current = true;
    setLoading(true);
    const timer = window.setTimeout(() => {
      void getProductsByQuery({ keyword: query, categoryId, active }).then((result) => {
        if (current) { setProducts(result); setLoading(false); }
      }).catch((reason: unknown) => {
        if (current) { toast({ kind: "error", message: reason instanceof Error ? reason.message : "Could not load products." }); setLoading(false); }
      });
    }, query.trim() ? 250 : 0);
    return () => { current = false; window.clearTimeout(timer); };
  }, [query, categoryId, active, catalog.products, toast]);

  async function openEdit(product: Product) {
    setBusyId(String(product.id));
    try {
      setEditProduct(await getProduct(product.id));
      setEditorOpen(true);
    } catch (reason) {
      toast({ kind: "error", message: reason instanceof Error ? reason.message : "Could not load product details." });
    } finally { setBusyId(null); }
  }

  async function submit(input: ProductInput) {
    setBusy(true);
    try {
      if (editProduct) await updateProduct(editProduct.id, input);
      else await createProduct(input);
      setEditorOpen(false); setEditProduct(null); toast({ kind: "success", message: editProduct ? "Product updated." : "Product created." });
      onChanged();
    } catch (reason) {
      toast({ kind: "error", message: reason instanceof Error ? reason.message : "Could not save product." });
    } finally { setBusy(false); }
  }

  async function toggleActive(product: Product) {
    setBusyId(String(product.id));
    try {
      await setProductActive(product.id, !product.active);
      toast({ kind: "success", message: product.active ? "Product deactivated." : "Product activated." });
      onChanged();
    } catch (reason) {
      toast({ kind: "error", message: reason instanceof Error ? reason.message : "Could not update product status." });
    } finally { setBusyId(null); }
  }

  async function performDelete(product: Product) {
    setBusyId(String(product.id));
    try {
      await deleteProduct(product.id);
      toast({ kind: "success", message: `Product “${product.name}” deleted.` }); onChanged();
    } catch (reason) {
      toast({ kind: "error", message: reason instanceof Error ? reason.message : "Could not delete product." });
    } finally { setBusyId(null); }
  }

  function remove(product: Product) {
    toast({
      kind: "warning",
      message: `Delete “${product.name}” (${product.sku})? This cannot be undone.`,
      action: { label: "Delete", onClick: () => void performDelete(product) },
    });
  }

  const categoryName = (product: Product) => catalog.categories.find((category) => String(category.id) === String(product.categoryId))?.name ?? "Uncategorized";

  return (
    <section className="panel products-panel" id="products" aria-label="Product catalog">
      <div className="products-heading">
        <div><h2>Product catalog</h2><p>Search, filter, and manage products using the live catalog API.</p></div>
        <button type="button" className="primary-button" onClick={() => { setEditProduct(null); setEditorOpen(true); }}>＋ Add product</button>
      </div>
      <div className="catalog-toolbar">
        <input className="manager-input catalog-search" aria-label="Search products" placeholder="Search name, SKU or barcode" value={query} onChange={(event) => setQuery(event.target.value)} />
        <select className="manager-select catalog-filter" aria-label="Filter products by category" value={categoryId} onChange={(event) => setCategoryId(event.target.value)}>
          <option value="all">All categories</option>
          {catalog.categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
          <option value="uncategorized">Uncategorized</option>
        </select>
        <select className="manager-select catalog-filter status-filter" aria-label="Filter products by status" value={active} onChange={(event) => setActive(event.target.value)}>
          <option value="all">Any status</option><option value="active">Active</option><option value="inactive">Inactive</option>
        </select>
        <span className="product-total">{products.length} shown</span>
      </div>
      {loading ? <div className="table-loading" role="status">Loading products…</div> : products.length === 0 ? (
        <div className="table-empty filtered-empty"><strong>{query || categoryId !== "all" || active !== "all" ? "No matching products" : "Your catalog is empty"}</strong><span>{query || categoryId !== "all" || active !== "all" ? "Try another search or filter." : "Add your first product to populate the catalog."}</span></div>
      ) : (
        <div className="products-table-scroll"><table className="manager-table" aria-label="Product catalog"><thead><tr><th>Product</th><th>SKU</th><th>Category</th><th>Selling price</th><th>Status</th><th>Actions</th></tr></thead><tbody>
          {products.map((product) => <tr key={product.id}>
            <td><strong>{product.name}</strong>{product.barcode && <small>Barcode {product.barcode}</small>}</td>
            <td><span className="sku-value">{product.sku}</span></td><td>{categoryName(product)}</td>
            <td>{new Intl.NumberFormat("en-GH", { style: "currency", currency: "GHS", maximumFractionDigits: 2 }).format(Number(product.sellingPrice))}</td>
            <td><span className={`status-badge${product.active ? " is-active" : " is-inactive"}`}>{product.active ? "Active" : "Inactive"}</span></td>
            <td><div className="row-actions"><button type="button" onClick={() => void openEdit(product)} disabled={busyId === String(product.id)}>Edit</button><button type="button" onClick={() => void toggleActive(product)} disabled={busyId === String(product.id)}>{product.active ? "Deactivate" : "Activate"}</button><button type="button" className="danger-action" onClick={() => void remove(product)} disabled={busyId === String(product.id)}>Delete</button></div></td>
          </tr>)}
        </tbody></table></div>
      )}
      {products.length > 0 && <p className="table-footnote">Search uses the backend name/SKU/barcode endpoint. Category and status filters use the matching backend list routes.</p>}
      {editorOpen && <ProductEditor product={editProduct} categories={catalog.categories} busy={busy} onCancel={() => { if (!busy) { setEditorOpen(false); setEditProduct(null); } }} onSubmit={(input) => void submit(input)} />}
    </section>
  );
}

export default ProductManager;
