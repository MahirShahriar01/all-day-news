import { useCallback, useEffect, useState } from "react";
import { api, mediaSrc } from "../api/client";
import type { Media } from "../api/types";
import { MediaPreview, UploadZone } from "../components/Media";
import { useErrorToast, useToast } from "../components/toast";
import { Modal, Segmented, Spinner } from "../components/ui";
import { formatBytes } from "../lib/color";
import { ApiError } from "../api/client";

export function MediaLibraryPage() {
  const [kind, setKind] = useState<string>("");
  const [items, setItems] = useState<Media[] | null>(null);
  const [open, setOpen] = useState<Media | null>(null);
  const toast = useToast();
  const onError = useErrorToast();
  const load = useCallback(() => api.media(kind || undefined).then((p) => setItems(p.items)).catch(onError), [kind, onError]);
  useEffect(() => { load(); }, [load]);

  const remove = async (m: Media) => {
    if (!window.confirm("Delete this file?")) return;
    try {
      await api.deleteMedia(m.id);
    } catch (e) {
      if (e instanceof ApiError && e.status === 409) {
        if (!window.confirm(`${e.message}\n\nDelete anyway? Items using it will show no image.`)) return;
        try { await api.deleteMedia(m.id, true); } catch (e2) { onError(e2); return; }
      } else { onError(e); return; }
    }
    toast("File deleted");
    setOpen(null);
    load();
  };

  const copy = async (m: Media) => {
    try { await navigator.clipboard.writeText(m.absolute_url); toast("Link copied"); } catch { toast(m.absolute_url, "info"); }
  };

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Media library</h1>
          <p>Logos, icons, backgrounds, GIFs and short videos. Upload once, use anywhere.</p>
        </div>
      </div>
      <div className="card">
        <UploadZone onUploaded={() => load()} />
        <div className="flex mt between">
          <Segmented label="Show" value={kind} onChange={setKind} options={[
            { value: "", label: "All" }, { value: "image", label: "Images" }, { value: "animation", label: "GIFs" }, { value: "video", label: "Videos" },
          ]} />
          <span className="faint">{items?.length ?? 0} file(s)</span>
        </div>
        {!items ? <Spinner /> : (
          <div className="media-grid">
            {items.map((m) => (
              <button key={m.id} className="media-tile" onClick={() => setOpen(m)}>
                <div className="preview"><MediaPreview url={m.url} alt={m.original_name} /></div>
                <div className="info">{m.original_name || m.kind}</div>
              </button>
            ))}
          </div>
        )}
      </div>
      {open && (
        <Modal title={open.original_name || "File"} onClose={() => setOpen(null)}
          footer={<><button className="btn btn-danger" onClick={() => remove(open)}>Delete</button><button className="btn" onClick={() => copy(open)}>Copy link</button><a className="btn btn-primary" href={mediaSrc(open.url)} target="_blank" rel="noreferrer">Open</a></>}>
          <div className="media-tile" style={{ cursor: "default" }}><div className="preview" style={{ aspectRatio: "16/10" }}><MediaPreview url={open.url} alt={open.original_name} /></div></div>
          <p className="muted mt">
            {open.mime_type} · {formatBytes(open.size_bytes)}{open.width ? ` · ${open.width}×${open.height}px` : ""} · uploaded {new Date(open.created_at).toLocaleString()}
          </p>
        </Modal>
      )}
    </>
  );
}
