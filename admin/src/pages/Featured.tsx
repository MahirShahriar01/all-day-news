import { useCallback, useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Site } from "../api/types";
import { Thumb } from "../components/Media";
import { invalidatePreview } from "../components/PhonePreview";
import { SortableList } from "../components/Sortable";
import { useErrorToast, useToast } from "../components/toast";
import { Empty, Modal, Spinner } from "../components/ui";

export function FeaturedPage() {
  const [items, setItems] = useState<Site[] | null>(null);
  const [adding, setAdding] = useState(false);
  const toast = useToast();
  const onError = useErrorToast();
  const load = useCallback(() => api.sites({ featured: true }).then((p) => setItems(p.items)).catch(onError), [onError]);
  useEffect(() => { load(); }, [load]);

  const reorder = async (next: Site[]) => {
    setItems(next);
    try { await api.reorderFeatured(next.map((s) => s.id)); invalidatePreview(); toast("Order saved"); } catch (e) { onError(e); load(); }
  };
  const unfeature = async (s: Site) => {
    try { await api.updateSite(s.id, { is_featured: false }); invalidatePreview(); load(); } catch (e) { onError(e); }
  };

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Featured &amp; bookmarks</h1>
          <p>Highlighted websites at the top of the home screen. The first one is the most prominent.</p>
        </div>
        <button className="btn btn-primary" onClick={() => setAdding(true)}>＋ Add to featured</button>
      </div>
      <div className="card">
        {!items ? <Spinner /> : items.length === 0 ? (
          <Empty icon="⭐" title="Nothing featured yet"><button className="btn btn-primary" onClick={() => setAdding(true)}>Choose websites</button></Empty>
        ) : (
          <SortableList items={items} onReorder={reorder} render={(s, handle) => (
            <div className={`row ${s.is_enabled ? "" : "disabled"}`}>
              {handle}
              <Thumb url={s.logo_url} title={s.title} color={s.accent_color} />
              <div className="grow">
                <div className="title">{s.title} {!s.is_enabled && <span className="chip red">Hidden</span>}</div>
                <div className="meta">{s.animation_url ? "🎞️ Animated" : s.background_url ? "🖼️ Background image" : "🎨 Colour gradient"} · {s.url}</div>
              </div>
              <div className="actions">
                <Link className="btn btn-sm" to={`/sites?category=${s.category_id ?? ""}`}>Open list</Link>
                <button className="btn btn-sm" onClick={() => unfeature(s)}>Remove</button>
              </div>
            </div>
          )} />
        )}
      </div>
      {adding && <AddFeatured onClose={() => setAdding(false)} onDone={() => { setAdding(false); invalidatePreview(); load(); }} />}
    </>
  );
}

function AddFeatured({ onClose, onDone }: { onClose: () => void; onDone: () => void }) {
  const [sites, setSites] = useState<Site[] | null>(null);
  const [picked, setPicked] = useState<Set<number>>(new Set());
  const [q, setQ] = useState("");
  const onError = useErrorToast();
  useEffect(() => { api.sites({ featured: false }).then((p) => setSites(p.items)).catch(onError); }, [onError]);
  const save = async () => {
    try { await api.bulkSites([...picked], "feature"); onDone(); } catch (e) { onError(e); }
  };
  const visible = sites?.filter((s) => s.title.toLowerCase().includes(q.toLowerCase())) ?? [];
  return (
    <Modal title="Add websites to Featured" onClose={onClose}
      footer={<><button className="btn" onClick={onClose}>Cancel</button><button className="btn btn-primary" disabled={!picked.size} onClick={save}>Add {picked.size || ""}</button></>}>
      <input className="input mb" type="search" placeholder="Search…" value={q} onChange={(e) => setQ(e.target.value)} aria-label="Search websites" />
      {!sites ? <Spinner /> : (
        <div className="list">
          {visible.map((s) => (
            <label key={s.id} className="row" style={{ cursor: "pointer" }}>
              <input type="checkbox" checked={picked.has(s.id)} onChange={() => setPicked((p) => { const n = new Set(p); if (n.has(s.id)) n.delete(s.id); else n.add(s.id); return n; })} />
              <Thumb url={s.logo_url} title={s.title} color={s.accent_color} />
              <div className="grow"><div className="title">{s.title}</div><div className="meta">{s.url}</div></div>
            </label>
          ))}
        </div>
      )}
    </Modal>
  );
}
