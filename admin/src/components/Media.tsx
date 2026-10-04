import { useCallback, useEffect, useRef, useState } from "react";
import { api, mediaSrc } from "../api/client";
import type { Media } from "../api/types";
import { formatBytes, initials, toCss } from "../lib/color";
import { useErrorToast, useToast } from "./toast";
import { Modal } from "./ui";

const ACCEPT = "image/png,image/jpeg,image/webp,image/gif,video/mp4,video/webm";
const isVideo = (url: string) => /\.(mp4|webm)(\?|$)/i.test(url);

export function MediaPreview({ url, alt }: { url: string; alt: string }) {
  if (!url) return null;
  return isVideo(url) ? (
    <video src={mediaSrc(url)} muted autoPlay loop playsInline aria-label={alt} />
  ) : (
    <img src={mediaSrc(url)} alt={alt} loading="lazy" />
  );
}

export function Thumb({ url, title, color }: { url?: string; title: string; color?: string }) {
  return (
    <div className="thumb" style={color ? { background: toCss(color) } : undefined}>
      {url ? <MediaPreview url={url} alt="" /> : <span aria-hidden>{initials(title)}</span>}
    </div>
  );
}

/** Drag & drop or click to upload one or more files. */
export function UploadZone({ onUploaded, multiple = true }: { onUploaded: (m: Media[]) => void; multiple?: boolean }) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [over, setOver] = useState(false);
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const onError = useErrorToast();

  const upload = async (files: FileList | null) => {
    if (!files?.length) return;
    setBusy(true);
    const done: Media[] = [];
    for (const file of Array.from(files)) {
      try {
        done.push(await api.upload(file));
      } catch (e) {
        onError(new Error(`${file.name}: ${(e as Error).message}`));
      }
    }
    setBusy(false);
    if (done.length) {
      toast(`Uploaded ${done.length} file${done.length > 1 ? "s" : ""}`);
      onUploaded(done);
    }
  };

  return (
    <div
      className={`dropzone ${over ? "over" : ""}`}
      role="button"
      tabIndex={0}
      onClick={() => inputRef.current?.click()}
      onKeyDown={(e) => (e.key === "Enter" || e.key === " ") && inputRef.current?.click()}
      onDragOver={(e) => { e.preventDefault(); setOver(true); }}
      onDragLeave={() => setOver(false)}
      onDrop={(e) => { e.preventDefault(); setOver(false); upload(e.dataTransfer.files); }}
    >
      <input ref={inputRef} type="file" hidden accept={ACCEPT} multiple={multiple} onChange={(e) => upload(e.target.files)} />
      {busy ? <div className="spinner" style={{ margin: "0 auto" }} /> : (
        <>
          <div style={{ fontSize: 28 }} aria-hidden>⬆️</div>
          <b>Drop files here or click to upload</b>
          <div className="faint">PNG, JPG, WebP, GIF, MP4, WebM</div>
        </>
      )}
    </div>
  );
}

export function MediaLibraryModal({ onPick, onClose, kind }: { onPick: (m: Media) => void; onClose: () => void; kind?: string }) {
  const [items, setItems] = useState<Media[] | null>(null);
  const onError = useErrorToast();
  const load = useCallback(() => api.media(kind).then((p) => setItems(p.items)).catch(onError), [kind, onError]);
  useEffect(() => { load(); }, [load]);
  return (
    <Modal title="Choose from media library" onClose={onClose} wide>
      <UploadZone multiple={false} onUploaded={(m) => onPick(m[0])} />
      <div className="media-grid mt">
        {items?.map((m) => (
          <button key={m.id} className="media-tile" onClick={() => onPick(m)} title={m.original_name}>
            <div className="preview"><MediaPreview url={m.url} alt={m.original_name} /></div>
            <div className="info">{m.original_name || m.kind} · {formatBytes(m.size_bytes)}</div>
          </button>
        ))}
      </div>
      {items && !items.length && <p className="muted mt">No files yet. Upload one above.</p>}
    </Modal>
  );
}

/** A form field holding a media URL with preview, library picker and manual URL entry. */
export function MediaInput({ label, value, onChange, hint, kind }: {
  label: string; value: string; onChange: (url: string) => void; hint?: string; kind?: string;
}) {
  const [open, setOpen] = useState(false);
  return (
    <div className="field">
      <span className="label">{label}</span>
      <div className="input-row">
        <div className="thumb" style={{ background: "var(--bg-2)", border: "1px solid var(--border)" }}>
          {value ? <MediaPreview url={value} alt={label} /> : <span className="faint" aria-hidden>—</span>}
        </div>
        <input className="input" aria-label={`${label} URL`} value={value} placeholder="Upload or paste an image URL" onChange={(e) => onChange(e.target.value.trim())} />
        <button type="button" className="btn btn-sm" onClick={() => setOpen(true)}>Choose…</button>
        {value && <button type="button" className="btn btn-ghost btn-sm" onClick={() => onChange("")} aria-label={`Remove ${label}`}>✕</button>}
      </div>
      {hint && <span className="hint">{hint}</span>}
      {open && <MediaLibraryModal kind={kind} onClose={() => setOpen(false)} onPick={(m) => { onChange(m.url); setOpen(false); }} />}
    </div>
  );
}
