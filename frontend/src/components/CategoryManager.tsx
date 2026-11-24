import { useState } from "react";
import type { Category } from "../api/types";
import { createCategory, deleteCategory, getCategory, updateCategory, type CategoryInput } from "../api/catalog";
import CategoryEditor from "./CategoryEditor";
import { useToast } from "./ToastProvider";

type Props = { categories: Category[]; onChanged: () => void };

function CategoryManager({ categories, onChanged }: Props) {
  const toast = useToast();
  const [editing, setEditing] = useState<Category | null>(null);
  const [open, setOpen] = useState(false);
  const [busy, setBusy] = useState(false);
  const [busyId, setBusyId] = useState<string | null>(null);

  async function openEdit(category: Category) {
    setBusyId(String(category.id));
    try { setEditing(await getCategory(category.id)); setOpen(true); }
    catch (reason) { toast({ kind: "error", message: reason instanceof Error ? reason.message : "Could not load category." }); }
    finally { setBusyId(null); }
  }

  async function submit(input: CategoryInput) {
    setBusy(true);
    try {
      if (editing) await updateCategory(editing.id, input);
      else await createCategory(input);
      setOpen(false); toast({ kind: "success", message: editing ? "Category updated." : "Category created." }); setEditing(null); onChanged();
    } catch (reason) { toast({ kind: "error", message: reason instanceof Error ? reason.message : "Could not save category." }); }
    finally { setBusy(false); }
  }

  async function performDelete(category: Category) {
    setBusyId(String(category.id));
    try { await deleteCategory(category.id); toast({ kind: "success", message: `Category “${category.name}” deleted.` }); onChanged(); }
    catch (reason) { toast({ kind: "error", message: reason instanceof Error ? reason.message : "Could not delete category." }); }
    finally { setBusyId(null); }
  }

  function remove(category: Category) {
    toast({
      kind: "warning",
      message: `Delete category “${category.name}”? Categories with products cannot be deleted.`,
      action: { label: "Delete", onClick: () => void performDelete(category) },
    });
  }

  return (
    <section className="panel category-management" id="category-management" aria-label="Category management">
      <div className="products-heading"><div><h2>Categories</h2><p>Manage category names used by the product catalog.</p></div><button type="button" className="primary-button" onClick={() => { setEditing(null); setOpen(true); }}>＋ Add category</button></div>
      {categories.length === 0 ? <div className="table-empty filtered-empty"><strong>No categories yet</strong><span>Create a category before adding a product.</span></div> : (
        <div className="products-table-scroll"><table className="manager-table" aria-label="Categories"><thead><tr><th>Name</th><th>Description</th><th>Status</th><th>Actions</th></tr></thead><tbody>
          {categories.map((category) => <tr key={category.id}><td><strong>{category.name}</strong></td><td>{category.description || "—"}</td><td><span className={`status-badge${category.active ? " is-active" : " is-inactive"}`}>{category.active ? "Active" : "Inactive"}</span></td><td><div className="row-actions"><button type="button" onClick={() => void openEdit(category)} disabled={busyId === String(category.id)}>Edit</button><button type="button" className="danger-action" onClick={() => remove(category)} disabled={busyId === String(category.id)}>Delete</button></div></td></tr>)}
        </tbody></table></div>
      )}
      {open && <CategoryEditor category={editing} busy={busy} onCancel={() => { if (!busy) { setOpen(false); setEditing(null); } }} onSubmit={(input) => void submit(input)} />}
    </section>
  );
}

export default CategoryManager;
