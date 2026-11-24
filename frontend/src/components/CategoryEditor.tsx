import { useEffect, useState, type FormEvent } from "react";
import type { Category } from "../api/types";
import type { CategoryInput } from "../api/catalog";
import { useToast } from "./ToastProvider";

type Props = {
  category: Category | null;
  busy: boolean;
  onCancel: () => void;
  onSubmit: (input: CategoryInput) => void;
};

function CategoryEditor({ category, busy, onCancel, onSubmit }: Props) {
  const toast = useToast();
  const [name, setName] = useState(category?.name ?? "");
  const [description, setDescription] = useState(category?.description ?? "");
  useEffect(() => {
    setName(category?.name ?? "");
    setDescription(category?.description ?? "");
  }, [category]);

  function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!name.trim()) {
      toast({ kind: "warning", message: "Category name is required." });
      return;
    }
    onSubmit({ name: name.trim(), description: description.trim() || null });
  }

  return (
    <div className="management-backdrop" role="presentation" onMouseDown={(event) => event.target === event.currentTarget && onCancel()}>
      <section className="management-dialog category-dialog" role="dialog" aria-modal="true" aria-labelledby="category-editor-title">
        <div className="management-dialog-heading"><div><p className="eyebrow">PRODUCT CATALOG</p><h2 id="category-editor-title">{category ? "Edit category" : "Add category"}</h2><p>Category names must be unique.</p></div><button className="icon-button" type="button" onClick={onCancel} aria-label="Close category form">×</button></div>
        <form noValidate onSubmit={submit} className="management-form">
          <label>Category name<input autoFocus value={name} onChange={(event) => setName(event.target.value)} /></label>
          <label>Description<textarea rows={3} value={description} onChange={(event) => setDescription(event.target.value)} /></label>
          <div className="management-actions"><button type="button" className="quiet-button" onClick={onCancel} disabled={busy}>Cancel</button><button type="submit" className="primary-button" disabled={busy}>{busy ? "Saving…" : category ? "Save changes" : "Create category"}</button></div>
        </form>
      </section>
    </div>
  );
}

export default CategoryEditor;
