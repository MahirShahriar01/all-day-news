import { useCallback, useEffect, useState } from "react";
import { Link, useSearchParams } from "react-router-dom";
import { api } from "../api/client";
import type { Category } from "../api/types";
import { MediaInput, MediaPreview } from "../components/Media";
import { invalidatePreview } from "../components/PhonePreview";
import { SortableList } from "../components/Sortable";
import { useErrorToast, useToast } from "../components/toast";
import { ColorField, Empty, Field, Modal, Spinner, TextField, Toggle } from "../components/ui";
import { toCss } from "../lib/color";
import { CATEGORY_ICONS, iconEmoji } from "../lib/icons";

const blank: Partial<Category> = { name: "", description: "", icon_name: "newspaper", icon_url: "", background_url: "", color: "", is_enabled: true };

export function CategoriesPage() {
  const [items, setItems] = useState<Category[] | null>(null);
  const [editing, setEditing] = useState<Partial<Category> | null>(null);
  const [deleting, setDeleting] = useState<Category | null>(null);
  const [params, setParams] = useSearchParams();
  const toast = useToast();
  const onError = useErrorToast();

  const load = useCallback(() => api.categories().then(setItems).catch(onError), [onError]);
  useEffect(() => { load(); }, [load]);
  useEffect(() => {
    if (params.get("new")) { setEditing({ ...blank }); setParams({}, { replace: true }); }
  }, [params, setParams]);

  const reorder = async (next: Category[]) => {
    setItems(next);
    try { await api.reorderCategories(next.map((c) => c.id)); invalidatePreview(); toast("Order saved"); } catch (e) { onError(e); load(); }
  };

  const toggle = async (c: Category) => {
    try { await api.updateCategory(c.id, { is_enabled: !c.is_enabled }); invalidatePreview(); load(); } catch (e) { onError(e); }
  };

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Categories</h1>
          <p>Groups of websites shown as tabs in the app. Drag ⠿ to change the order.</p>
        </div>
        <button className="btn btn-primary" onClick={() => setEditing({ ...blank })}>＋ New category</button>
      </div>
      <div className="card">
        {!items ? <Spinner /> : items.length === 0 ? (
          <Empty icon="🗂️" title="No categories yet">
            <button className="btn btn-primary" onClick={() => setEditing({ ...blank })}>Create your first category</button>
          </Empty>
        ) : (
          <SortableList items={items} onReorder={reorder} render={(c, handle) => (
            <div className={`row ${c.is_enabled ? "" : "disabled"}`}>
              {handle}
              <div className="thumb" style={{ background: toCss(c.color, "var(--primary)") }}>
                {c.icon_url ? <MediaPreview url={c.icon_url} alt="" /> : <span aria-hidden>{iconEmoji(c.icon_name)}</span>}
              </div>
              <div className="grow">
                <div className="title">{c.name} {!c.is_enabled && <span className="chip red">Hidden</span>}</div>
                <div className="meta">{c.description || <span className="faint">No description</span>}</div>
              </div>
              <Link className="chip" to={`/sites?category=${c.id}`}>{c.site_count} website{c.site_count === 1 ? "" : "s"}</Link>
              <div className="actions">
                <label className="switch" title={c.is_enabled ? "Visible in app" : "Hidden from app"}>
                  <input type="checkbox" checked={c.is_enabled} onChange={() => toggle(c)} aria-label={`Show ${c.name} in app`} />
                  <span className="track" />
                </label>
                <button className="btn btn-sm" onClick={() => setEditing(c)}>Edit</button>
                <button className="btn btn-sm btn-danger" onClick={() => setDeleting(c)} aria-label={`Delete ${c.name}`}>🗑</button>
              </div>
            </div>
          )} />
        )}
      </div>
      {editing && <CategoryEditor value={editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); invalidatePreview(); load(); }} />}
      {deleting && items && (
        <DeleteCategory category={deleting} others={items.filter((c) => c.id !== deleting.id)} onClose={() => setDeleting(null)}
          onDone={() => { setDeleting(null); invalidatePreview(); load(); }} />
      )}
    </>
  );
}

function CategoryEditor({ value, onClose, onSaved }: { value: Partial<Category>; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState(value);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const onError = useErrorToast();
  const set = <K extends keyof Category>(k: K, v: Category[K]) => setForm((f) => ({ ...f, [k]: v }));

  const save = async () => {
    setBusy(true);
    const payload = {
      name: form.name, description: form.description, icon_name: form.icon_name, icon_url: form.icon_url,
      background_url: form.background_url, color: form.color, is_enabled: form.is_enabled,
      ...(form.id && form.slug ? { slug: form.slug } : {}),
    };
    try {
      if (form.id) await api.updateCategory(form.id, payload);
      else await api.createCategory(payload);
      toast(form.id ? "Category updated" : "Category created");
      onSaved();
    } catch (e) { onError(e); } finally { setBusy(false); }
  };

  return (
    <Modal title={form.id ? `Edit “${value.name}”` : "New category"} onClose={onClose}
      footer={<><button className="btn" onClick={onClose}>Cancel</button><button className="btn btn-primary" disabled={busy || !form.name?.trim()} onClick={save}>{busy ? "Saving…" : "Save"}</button></>}>
      <TextField label="Name" value={form.name ?? ""} onChange={(v) => set("name", v)} required autoFocus maxLength={80} placeholder="e.g. Live Streaming" />
      <TextField label="Description" value={form.description ?? ""} onChange={(v) => set("description", v)} multiline maxLength={2000} hint="Optional. Shown under the category title." />
      <Field label="Icon" hint="Used when no icon image is uploaded.">
        {(id) => (
          <select id={id} className="input" value={form.icon_name} onChange={(e) => set("icon_name", e.target.value)}>
            {CATEGORY_ICONS.map((i) => <option key={i.name} value={i.name}>{i.emoji}  {i.label}</option>)}
          </select>
        )}
      </Field>
      <div className="grid grid-2">
        <MediaInput label="Icon image (optional)" value={form.icon_url ?? ""} onChange={(v) => set("icon_url", v)} hint="Square PNG/WebP, 256×256 or larger." />
        <MediaInput label="Background image (optional)" value={form.background_url ?? ""} onChange={(v) => set("background_url", v)} hint="Wide image, e.g. 1200×600." />
      </div>
      <ColorField label="Colour" value={form.color ?? ""} onChange={(v) => set("color", v)} allowEmpty hint="Accent colour of the tab and header." />
      {form.id && <TextField label="Web address name (slug)" value={form.slug ?? ""} onChange={(v) => set("slug", v)} hint="Lower-case letters, numbers and dashes. Used for deep links." />}
      <Toggle label="Visible in the app" checked={!!form.is_enabled} onChange={(v) => set("is_enabled", v)} />
    </Modal>
  );
}

function DeleteCategory({ category, others, onClose, onDone }: { category: Category; others: Category[]; onClose: () => void; onDone: () => void }) {
  const [mode, setMode] = useState<"keep" | "move" | "delete">(others.length ? "move" : "keep");
  const [target, setTarget] = useState<number | undefined>(others[0]?.id);
  const toast = useToast();
  const onError = useErrorToast();
  const confirm = async () => {
    try {
      await api.deleteCategory(category.id, mode === "move" ? { move_sites_to: target } : mode === "delete" ? { delete_sites: true } : {});
      toast("Category deleted");
      onDone();
    } catch (e) { onError(e); }
  };
  return (
    <Modal title={`Delete “${category.name}”?`} onClose={onClose}
      footer={<><button className="btn" onClick={onClose}>Cancel</button><button className="btn btn-danger" onClick={confirm}>Delete category</button></>}>
      {category.site_count === 0 ? <p>This category is empty and will be removed.</p> : (
        <>
          <p className="mb">This category contains <b>{category.site_count}</b> website(s). What should happen to them?</p>
          {others.length > 0 && (
            <label className="flex mb"><input type="radio" checked={mode === "move"} onChange={() => setMode("move")} /> Move them to
              <select className="input" style={{ width: "auto" }} value={target} onChange={(e) => { setTarget(Number(e.target.value)); setMode("move"); }}>
                {others.map((o) => <option key={o.id} value={o.id}>{o.name}</option>)}
              </select>
            </label>
          )}
          <label className="flex mb"><input type="radio" checked={mode === "keep"} onChange={() => setMode("keep")} /> Keep them without a category</label>
          <label className="flex"><input type="radio" checked={mode === "delete"} onChange={() => setMode("delete")} /> <span style={{ color: "var(--danger)" }}>Delete the websites too</span></label>
        </>
      )}
    </Modal>
  );
}
