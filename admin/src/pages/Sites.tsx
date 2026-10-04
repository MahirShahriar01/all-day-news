import { useCallback, useEffect, useMemo, useState } from "react";
import { useSearchParams } from "react-router-dom";
import { api, mediaSrc } from "../api/client";
import type { Category, OpenMode, Site } from "../api/types";
import { MediaInput, Thumb } from "../components/Media";
import { invalidatePreview } from "../components/PhonePreview";
import { SortableList } from "../components/Sortable";
import { useErrorToast, useToast } from "../components/toast";
import { ColorField, Empty, Field, Modal, Spinner, TextField, Toggle } from "../components/ui";
import { toCss } from "../lib/color";

const OPEN_MODES: { value: OpenMode; label: string; hint: string }[] = [
  { value: "default", label: "App default", hint: "Use the setting from Browser settings." },
  { value: "custom_tab", label: "In-app browser tab", hint: "Chrome Custom Tab / Safari View. Fast, secure and store-friendly. Recommended." },
  { value: "in_app", label: "Embedded browser", hint: "Opens inside the app’s own browser screen. Only use for sites you own or have permission to embed." },
  { value: "external", label: "External browser / app", hint: "Leaves the app and opens the phone’s browser or the site’s own app." },
];

const blank: Partial<Site> = {
  title: "", url: "https://", description: "", category_id: null, logo_url: "", background_url: "", animation_url: "",
  accent_color: "", badge: "", tags: "", open_mode: "default", is_featured: false, is_enabled: true,
};

export function SitesPage() {
  const [params, setParams] = useSearchParams();
  const [categories, setCategories] = useState<Category[]>([]);
  const [sites, setSites] = useState<Site[] | null>(null);
  const [q, setQ] = useState("");
  const [selected, setSelected] = useState<Set<number>>(new Set());
  const [editing, setEditing] = useState<Partial<Site> | null>(null);
  const toast = useToast();
  const onError = useErrorToast();

  const categoryParam = params.get("category");
  const uncategorised = params.get("uncategorised") === "1";
  const categoryId = categoryParam ? Number(categoryParam) : undefined;

  const load = useCallback(() => {
    api.sites({ category_id: categoryId, uncategorised: uncategorised || undefined, q: q || undefined })
      .then((p) => setSites(p.items)).catch(onError);
  }, [categoryId, uncategorised, q, onError]);

  useEffect(() => { api.categories().then(setCategories).catch(onError); }, [onError]);
  useEffect(() => { const t = setTimeout(load, q ? 250 : 0); return () => clearTimeout(t); }, [load, q]);
  useEffect(() => {
    if (params.get("new")) {
      setEditing({ ...blank, category_id: categoryId ?? null });
      params.delete("new");
      setParams(params, { replace: true });
    }
  }, [params, setParams, categoryId]);

  const catName = useMemo(() => Object.fromEntries(categories.map((c) => [c.id, c.name])), [categories]);
  const canReorder = categoryId !== undefined && !q;
  const refresh = () => { invalidatePreview(); setSelected(new Set()); load(); };

  const setFilter = (value: string) => {
    if (value === "all") setParams({});
    else if (value === "none") setParams({ uncategorised: "1" });
    else setParams({ category: value });
  };

  const reorder = async (next: Site[]) => {
    setSites(next);
    try { await api.reorderSites(next.map((s) => s.id)); invalidatePreview(); toast("Order saved"); } catch (e) { onError(e); load(); }
  };

  const quick = async (s: Site, data: Partial<Site>) => {
    try { await api.updateSite(s.id, data); refresh(); } catch (e) { onError(e); }
  };

  const bulk = async (action: string, category_id?: number | null) => {
    if (action === "delete" && !window.confirm(`Delete ${selected.size} website(s)? This cannot be undone.`)) return;
    try { await api.bulkSites([...selected], action, category_id); toast("Done"); refresh(); } catch (e) { onError(e); }
  };

  const remove = async (s: Site) => {
    if (!window.confirm(`Delete “${s.title}”? This cannot be undone.`)) return;
    try { await api.deleteSite(s.id); toast("Website deleted"); refresh(); } catch (e) { onError(e); }
  };

  const toggleSel = (id: number) => setSelected((s) => { const n = new Set(s); if (n.has(id)) n.delete(id); else n.add(id); return n; });

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Websites</h1>
          <p>The cards users tap to open a website, channel or service.</p>
        </div>
        <button className="btn btn-primary" onClick={() => setEditing({ ...blank, category_id: categoryId ?? null })}>＋ Add website</button>
      </div>

      <div className="card">
        <div className="toolbar">
          <select className="input" style={{ maxWidth: 240 }} aria-label="Filter by category"
            value={uncategorised ? "none" : categoryParam ?? "all"} onChange={(e) => setFilter(e.target.value)}>
            <option value="all">All categories</option>
            {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            <option value="none">Without category</option>
          </select>
          <input className="input" type="search" placeholder="Search title, URL or tag…" value={q} onChange={(e) => setQ(e.target.value)} aria-label="Search websites" />
          <span className="faint" style={{ fontSize: 12 }}>
            {canReorder ? "Drag ⠿ to change the order inside this category." : "Choose a category to change the order."}
          </span>
        </div>

        {selected.size > 0 && (
          <div className="toolbar" style={{ background: "var(--primary-soft)", padding: 10, borderRadius: 12 }}>
            <b>{selected.size} selected</b>
            <button className="btn btn-sm" onClick={() => bulk("enable")}>Show</button>
            <button className="btn btn-sm" onClick={() => bulk("disable")}>Hide</button>
            <button className="btn btn-sm" onClick={() => bulk("feature")}>★ Feature</button>
            <button className="btn btn-sm" onClick={() => bulk("unfeature")}>Unfeature</button>
            <select className="input" style={{ maxWidth: 200 }} aria-label="Move selected to category" value=""
              onChange={(e) => bulk("move", e.target.value === "none" ? null : Number(e.target.value))}>
              <option value="" disabled>Move to…</option>
              {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
              <option value="none">No category</option>
            </select>
            <button className="btn btn-sm btn-danger" onClick={() => bulk("delete")}>Delete</button>
            <button className="btn btn-sm btn-ghost" onClick={() => setSelected(new Set())}>Clear</button>
          </div>
        )}

        {!sites ? <Spinner /> : sites.length === 0 ? (
          <Empty icon="🌐" title={q ? "No websites match your search" : "No websites here yet"}>
            <button className="btn btn-primary" onClick={() => setEditing({ ...blank, category_id: categoryId ?? null })}>Add a website</button>
          </Empty>
        ) : (
          <SortableList items={sites} onReorder={reorder} disabled={!canReorder} render={(s, handle) => (
            <div className={`row ${s.is_enabled ? "" : "disabled"}`}>
              <input type="checkbox" checked={selected.has(s.id)} onChange={() => toggleSel(s.id)} aria-label={`Select ${s.title}`} />
              {handle}
              <Thumb url={s.logo_url} title={s.title} color={s.accent_color} />
              <div className="grow">
                <div className="title">
                  {s.title}{" "}
                  {s.badge && <span className="chip gold">{s.badge}</span>}{" "}
                  {!s.is_enabled && <span className="chip red">Hidden</span>}
                </div>
                <div className="meta">
                  {s.category_id ? catName[s.category_id] : <i>No category</i>} · <a href={s.url} target="_blank" rel="noreferrer noopener">{s.url}</a>
                </div>
              </div>
              <div className="actions">
                <button className={`btn btn-sm ${s.is_featured ? "btn-primary" : ""}`} onClick={() => quick(s, { is_featured: !s.is_featured })}
                  title={s.is_featured ? "Remove from Featured" : "Add to Featured"} aria-pressed={s.is_featured}>★</button>
                <label className="switch" title={s.is_enabled ? "Visible in app" : "Hidden from app"}>
                  <input type="checkbox" checked={s.is_enabled} onChange={() => quick(s, { is_enabled: !s.is_enabled })} aria-label={`Show ${s.title} in app`} />
                  <span className="track" />
                </label>
                <button className="btn btn-sm" onClick={() => setEditing(s)}>Edit</button>
                <button className="btn btn-sm btn-danger" onClick={() => remove(s)} aria-label={`Delete ${s.title}`}>🗑</button>
              </div>
            </div>
          )} />
        )}
      </div>
      {editing && <SiteEditor value={editing} categories={categories} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); refresh(); }} />}
    </>
  );
}

export function SiteEditor({ value, categories, onClose, onSaved }: {
  value: Partial<Site>; categories: Category[]; onClose: () => void; onSaved: () => void;
}) {
  const [form, setForm] = useState(value);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const onError = useErrorToast();
  const set = <K extends keyof Site>(k: K, v: Site[K]) => setForm((f) => ({ ...f, [k]: v }));

  const save = async () => {
    setBusy(true);
    const payload: Partial<Site> = {
      title: form.title?.trim(), url: form.url?.trim(), description: form.description, category_id: form.category_id ?? null,
      logo_url: form.logo_url, background_url: form.background_url, animation_url: form.animation_url,
      accent_color: form.accent_color, badge: form.badge, tags: form.tags, open_mode: form.open_mode,
      is_featured: form.is_featured, is_enabled: form.is_enabled,
    };
    try {
      if (form.id) await api.updateSite(form.id, payload);
      else await api.createSite(payload);
      toast(form.id ? "Website updated" : "Website added");
      onSaved();
    } catch (e) { onError(e); } finally { setBusy(false); }
  };

  const accent = toCss(form.accent_color, "var(--primary)");
  const bg = form.animation_url || form.background_url;

  return (
    <Modal wide title={form.id ? `Edit “${value.title}”` : "Add website"} onClose={onClose}
      footer={<><button className="btn" onClick={onClose}>Cancel</button><button className="btn btn-primary" disabled={busy || !form.title?.trim() || !form.url?.trim()} onClick={save}>{busy ? "Saving…" : "Save website"}</button></>}>
      <div className="split">
        <div>
          <div className="grid grid-2">
            <TextField label="Title" value={form.title ?? ""} onChange={(v) => set("title", v)} required autoFocus maxLength={120} placeholder="e.g. BBC News" />
            <Field label="Category">
              {(id) => (
                <select id={id} className="input" value={form.category_id ?? ""} onChange={(e) => set("category_id", e.target.value ? Number(e.target.value) : null)}>
                  <option value="">No category</option>
                  {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
                </select>
              )}
            </Field>
          </div>
          <TextField label="Website address (URL)" type="url" value={form.url ?? ""} onChange={(v) => set("url", v)} required placeholder="https://www.example.com" hint="Must start with https:// (recommended) or http://" />
          <TextField label="Short description" value={form.description ?? ""} onChange={(v) => set("description", v)} multiline maxLength={2000} hint="One or two sentences shown on the card." />
          <div className="grid grid-2">
            <MediaInput label="Logo / icon" value={form.logo_url ?? ""} onChange={(v) => set("logo_url", v)} hint="Square, 256×256+ PNG or WebP." />
            <MediaInput label="Background image" value={form.background_url ?? ""} onChange={(v) => set("background_url", v)} hint="Optional. Wide 1200×600 JPG/WebP." />
          </div>
          <MediaInput label="Animation (GIF / video)" value={form.animation_url ?? ""} onChange={(v) => set("animation_url", v)}
            hint="Optional. Shown on featured cards instead of the background. Keep it short and under 5 MB." />
          <div className="grid grid-2">
            <ColorField label="Accent colour" value={form.accent_color ?? ""} onChange={(v) => set("accent_color", v)} allowEmpty />
            <TextField label="Badge" value={form.badge ?? ""} onChange={(v) => set("badge", v.toUpperCase())} maxLength={20} placeholder="LIVE, NEW, 24/7…" />
          </div>
          <TextField label="Search keywords" value={form.tags ?? ""} onChange={(v) => set("tags", v)} maxLength={300} hint="Comma separated, e.g. cricket, scores, live" />
          <Field label="How it opens" hint={OPEN_MODES.find((m) => m.value === form.open_mode)?.hint}>
            {(id) => (
              <select id={id} className="input" value={form.open_mode} onChange={(e) => set("open_mode", e.target.value as OpenMode)}>
                {OPEN_MODES.map((m) => <option key={m.value} value={m.value}>{m.label}</option>)}
              </select>
            )}
          </Field>
          <div className="grid grid-2">
            <Toggle label="★ Featured" checked={!!form.is_featured} onChange={(v) => set("is_featured", v)} hint="Shown prominently at the top of the home screen." />
            <Toggle label="Visible in the app" checked={!!form.is_enabled} onChange={(v) => set("is_enabled", v)} />
          </div>
        </div>
        <div className="sticky">
          <span className="label">Preview</span>
          <div className="card mt" style={{ padding: 0, overflow: "hidden" }}>
            <div style={{
              height: 150, position: "relative", display: "flex", alignItems: "flex-end", padding: 14, color: "white",
              background: bg ? `linear-gradient(transparent 30%, #000c), url(${mediaSrc(bg)}) center/cover` : `linear-gradient(135deg, ${accent}, var(--primary-2))`,
            }}>
              {form.badge && <span className="chip" style={{ position: "absolute", top: 12, left: 12, background: "var(--danger)", color: "white" }}>{form.badge}</span>}
              <div className="flex" style={{ gap: 10 }}>
                <Thumb url={form.logo_url} title={form.title || "?"} color={form.accent_color} />
                <div><b>{form.title || "Website title"}</b><div style={{ fontSize: 12, opacity: 0.85 }}>{form.description?.slice(0, 80)}</div></div>
              </div>
            </div>
          </div>
          <p className="faint mt" style={{ fontSize: 12 }}>Featured cards use the animation or background image. Grid cards show the logo and title.</p>
        </div>
      </div>
    </Modal>
  );
}
