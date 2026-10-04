import { useEffect, useId, type ReactNode } from "react";
import { fromRgbHex, toRgbHex } from "../lib/color";

export function Spinner() {
  return <div className="center"><div className="spinner" role="status" aria-label="Loading" /></div>;
}

export function Empty({ icon = "✨", title, children }: { icon?: string; title: string; children?: ReactNode }) {
  return (
    <div className="empty">
      <div className="big" aria-hidden>{icon}</div>
      <h3>{title}</h3>
      {children && <div className="mt">{children}</div>}
    </div>
  );
}

export function Field({ label, hint, children }: { label: string; hint?: ReactNode; children: (id: string) => ReactNode }) {
  const id = useId();
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      {children(id)}
      {hint && <span className="hint">{hint}</span>}
    </div>
  );
}

export function TextField(props: {
  label: string; value: string; onChange: (v: string) => void; hint?: ReactNode; placeholder?: string;
  type?: string; multiline?: boolean; maxLength?: number; required?: boolean; autoFocus?: boolean;
}) {
  const { label, value, onChange, hint, multiline, ...rest } = props;
  return (
    <Field label={label} hint={hint}>
      {(id) =>
        multiline ? (
          <textarea id={id} className="input" value={value} onChange={(e) => onChange(e.target.value)} {...rest} />
        ) : (
          <input id={id} className="input" value={value} onChange={(e) => onChange(e.target.value)} {...rest} />
        )
      }
    </Field>
  );
}

export function Toggle({ checked, onChange, label, hint }: { checked: boolean; onChange: (v: boolean) => void; label: string; hint?: string }) {
  return (
    <div className="field">
      <label className="switch">
        <input type="checkbox" checked={checked} onChange={(e) => onChange(e.target.checked)} />
        <span className="track" aria-hidden />
        <span>{label}</span>
      </label>
      {hint && <span className="hint">{hint}</span>}
    </div>
  );
}

export function Segmented<T extends string | number>({ value, options, onChange, label }: {
  value: T; options: { value: T; label: string }[]; onChange: (v: T) => void; label: string;
}) {
  return (
    <div className="field">
      <span className="label">{label}</span>
      <div className="segmented" role="radiogroup" aria-label={label}>
        {options.map((o) => (
          <button type="button" role="radio" aria-checked={o.value === value} key={String(o.value)}
            className={o.value === value ? "on" : ""} onClick={() => onChange(o.value)}>
            {o.label}
          </button>
        ))}
      </div>
    </div>
  );
}

export function ColorField({ label, value, onChange, allowEmpty, hint }: {
  label: string; value: string; onChange: (v: string) => void; allowEmpty?: boolean; hint?: string;
}) {
  return (
    <Field label={label} hint={hint}>
      {(id) => (
        <div className="color-field">
          <input type="color" aria-label={`${label} picker`} value={toRgbHex(value)} onChange={(e) => onChange(fromRgbHex(e.target.value, value))} />
          <input id={id} className="input" value={value} placeholder={allowEmpty ? "Automatic" : "#FF7C4DFF"}
            onChange={(e) => onChange(e.target.value.toUpperCase())} />
          {allowEmpty && value && <button type="button" className="btn btn-ghost btn-sm" onClick={() => onChange("")}>Clear</button>}
        </div>
      )}
    </Field>
  );
}

export function Modal({ title, onClose, children, footer, wide }: {
  title: string; onClose: () => void; children: ReactNode; footer?: ReactNode; wide?: boolean;
}) {
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === "Escape" && onClose();
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose]);
  return (
    <div className="backdrop" onMouseDown={(e) => e.target === e.currentTarget && onClose()}>
      <div className={`modal ${wide ? "wide" : ""}`} role="dialog" aria-modal="true" aria-label={title}>
        <div className="modal-head">
          <h2>{title}</h2>
          <button className="btn btn-ghost btn-icon" onClick={onClose} aria-label="Close">✕</button>
        </div>
        <div className="modal-body">{children}</div>
        {footer && <div className="modal-foot">{footer}</div>}
      </div>
    </div>
  );
}
