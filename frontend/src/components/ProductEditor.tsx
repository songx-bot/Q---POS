import { useEffect, useState, type FormEvent } from "react";
import type { Product } from "../api/types";
import type { ProductInput } from "../api/catalog";
import { useToast } from "./ToastProvider";

type Props = {
  product: Product | null;
  categories: { id: number | string; name: string }[];
  busy: boolean;
  onCancel: () => void;
  onSubmit: (input: ProductInput) => void;
};

const empty = {
  sku: "", barcode: "", name: "", description: "", categoryId: "",
  brandId: "", unitId: "", costPrice: "0", sellingPrice: "0", taxRate: "0",
};

function ProductEditor({ product, categories, busy, onCancel, onSubmit }: Props) {
  const toast = useToast();
  const [form, setForm] = useState(empty);

  useEffect(() => {
    setForm(product ? {
      sku: product.sku ?? "",
      barcode: product.barcode ?? "",
      name: product.name ?? "",
      description: product.description ?? "",
      categoryId: product.categoryId == null ? "" : String(product.categoryId),
      brandId: product.brandId == null ? "" : String(product.brandId),
      unitId: product.unitId == null ? "" : String(product.unitId),
      costPrice: String(product.costPrice ?? 0),
      sellingPrice: String(product.sellingPrice ?? 0),
      taxRate: String(product.taxRate ?? 0),
    } : empty);
  }, [product]);

  const change = (key: keyof typeof empty) => (event: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
    setForm((current) => ({ ...current, [key]: event.target.value }));

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    const costPrice = Number(form.costPrice);
    const sellingPrice = Number(form.sellingPrice);
    const taxRate = Number(form.taxRate);
    if (!form.name.trim() || !form.sku.trim() || !form.categoryId) {
      toast({ kind: "warning", message: "Product name, SKU, and category are required." });
      return;
    }
    if ([form.costPrice, form.sellingPrice, form.taxRate].some((value) => !value.trim()) || ![costPrice, sellingPrice, taxRate].every(Number.isFinite) || costPrice < 0 || sellingPrice < 0 || taxRate < 0) {
      toast({ kind: "warning", message: "Enter valid nonnegative cost, selling, and tax values." });
      return;
    }
    if (sellingPrice < costPrice) {
      toast({ kind: "warning", message: "Selling price cannot be lower than cost price." });
      return;
    }
    if ([form.brandId, form.unitId].some((value) => value && (!Number.isInteger(Number(value)) || Number(value) < 1))) {
      toast({ kind: "warning", message: "Brand ID and unit ID must be positive whole numbers." });
      return;
    }
    onSubmit({
      sku: form.sku.trim(),
      barcode: form.barcode.trim() || null,
      name: form.name.trim(),
      description: form.description.trim() || null,
      categoryId: Number(form.categoryId),
      brandId: form.brandId ? Number(form.brandId) : null,
      unitId: form.unitId ? Number(form.unitId) : null,
      costPrice,
      sellingPrice,
      taxRate,
    });
  }

  return (
    <div className="management-backdrop" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onCancel()}>
      <section className="management-dialog" role="dialog" aria-modal="true" aria-labelledby="product-editor-title">
        <div className="management-dialog-heading">
          <div><p className="eyebrow">PRODUCT CATALOG</p><h2 id="product-editor-title">{product ? "Edit product" : "Add product"}</h2><p>Fields and checks follow the current product API.</p></div>
          <button className="icon-button" type="button" onClick={onCancel} aria-label="Close product form">×</button>
        </div>
        <form noValidate onSubmit={submit} className="management-form">
          <label>Product name<input autoFocus value={form.name} onChange={change("name")} maxLength={180} /></label>
          <div className="form-row">
            <label>SKU<input value={form.sku} onChange={change("sku")} /></label>
            <label>Barcode<input value={form.barcode} onChange={change("barcode")} /></label>
          </div>
          <label>Category<select value={form.categoryId} onChange={change("categoryId")}><option value="">Choose a category</option>{categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}</select></label>
          <label>Description<textarea rows={2} value={form.description} onChange={change("description")} /></label>
          <div className="form-row form-row-three">
            <label>Cost price<input type="number" min="0" step="0.0001" value={form.costPrice} onChange={change("costPrice")} /></label>
            <label>Selling price<input type="number" min="0" step="0.0001" value={form.sellingPrice} onChange={change("sellingPrice")} /></label>
            <label>Tax rate<input type="number" min="0" step="0.0001" value={form.taxRate} onChange={change("taxRate")} /></label>
          </div>
          <div className="form-row">
            <label>Brand ID <span className="field-optional">Optional</span><input type="number" min="1" step="1" value={form.brandId} onChange={change("brandId")} /></label>
            <label>Unit ID <span className="field-optional">Optional</span><input type="number" min="1" step="1" value={form.unitId} onChange={change("unitId")} /></label>
          </div>
          <div className="management-actions"><button type="button" className="quiet-button" onClick={onCancel} disabled={busy}>Cancel</button><button type="submit" className="primary-button" disabled={busy}>{busy ? "Saving…" : product ? "Save changes" : "Create product"}</button></div>
        </form>
      </section>
    </div>
  );
}

export default ProductEditor;
