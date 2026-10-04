import { useCallback, useEffect, useState } from "react";
import { api } from "../api/client";
import type { Admin, Role } from "../api/types";
import { useErrorToast, useToast } from "../components/toast";
import { Field, Modal, Spinner, TextField, Toggle } from "../components/ui";
import { useAuth } from "../lib/auth";
import { timeAgo } from "../lib/color";

export function AdminsPage() {
  const { admin: me } = useAuth();
  const [items, setItems] = useState<Admin[] | null>(null);
  const [editing, setEditing] = useState<Partial<Admin> | null>(null);
  const toast = useToast();
  const onError = useErrorToast();
  const load = useCallback(() => api.admins().then(setItems).catch(onError), [onError]);
  useEffect(() => { load(); }, [load]);

  const remove = async (a: Admin) => {
    if (!window.confirm(`Remove ${a.email}? They will no longer be able to sign in.`)) return;
    try { await api.deleteAdmin(a.id); toast("Administrator removed"); load(); } catch (e) { onError(e); }
  };

  return (
    <>
      <div className="page-head">
        <div><h1>Administrators</h1><p>People who can sign in to this panel. <b>Owners</b> can also manage administrators; <b>editors</b> manage content only.</p></div>
        <button className="btn btn-primary" onClick={() => setEditing({ role: "editor", is_active: true })}>＋ Add administrator</button>
      </div>
      <div className="card">
        {!items ? <Spinner /> : (
          <div className="list">
            {items.map((a) => (
              <div key={a.id} className={`row ${a.is_active ? "" : "disabled"}`}>
                <div className="thumb" aria-hidden>{(a.full_name || a.email)[0].toUpperCase()}</div>
                <div className="grow">
                  <div className="title">{a.full_name || a.email} {a.id === me?.id && <span className="chip">You</span>}</div>
                  <div className="meta">{a.email} · last sign-in {a.last_login_at ? timeAgo(a.last_login_at) : "never"}</div>
                </div>
                <span className={`chip ${a.role === "owner" ? "gold" : ""}`}>{a.role}</span>
                {!a.is_active && <span className="chip red">Disabled</span>}
                <div className="actions">
                  <button className="btn btn-sm" onClick={() => setEditing(a)}>Edit</button>
                  {a.id !== me?.id && <button className="btn btn-sm btn-danger" onClick={() => remove(a)} aria-label={`Remove ${a.email}`}>🗑</button>}
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
      {editing && <AdminEditor value={editing} onClose={() => setEditing(null)} onSaved={() => { setEditing(null); load(); }} />}
    </>
  );
}

function AdminEditor({ value, onClose, onSaved }: { value: Partial<Admin>; onClose: () => void; onSaved: () => void }) {
  const [form, setForm] = useState({ email: value.email ?? "", full_name: value.full_name ?? "", role: (value.role ?? "editor") as Role, is_active: value.is_active ?? true, password: "" });
  const toast = useToast();
  const onError = useErrorToast();
  const save = async () => {
    try {
      if (value.id) {
        await api.updateAdmin(value.id, { full_name: form.full_name, role: form.role, is_active: form.is_active, ...(form.password ? { password: form.password } : {}) });
      } else {
        await api.createAdmin({ email: form.email, full_name: form.full_name, role: form.role, password: form.password });
      }
      toast("Saved");
      onSaved();
    } catch (e) { onError(e); }
  };
  return (
    <Modal title={value.id ? `Edit ${value.email}` : "Add administrator"} onClose={onClose}
      footer={<><button className="btn" onClick={onClose}>Cancel</button><button className="btn btn-primary" onClick={save}>Save</button></>}>
      {!value.id && <TextField label="E-mail" type="email" value={form.email} onChange={(v) => setForm({ ...form, email: v })} required autoFocus />}
      <TextField label="Name" value={form.full_name} onChange={(v) => setForm({ ...form, full_name: v })} />
      <Field label="Role">
        {(id) => (
          <select id={id} className="input" value={form.role} onChange={(e) => setForm({ ...form, role: e.target.value as Role })}>
            <option value="editor">Editor: manages content, media and branding</option>
            <option value="owner">Owner: everything, including administrators</option>
          </select>
        )}
      </Field>
      <TextField label={value.id ? "New password (leave empty to keep)" : "Password"} type="password" value={form.password} onChange={(v) => setForm({ ...form, password: v })} hint="At least 10 characters." />
      {value.id && <Toggle label="Account active" checked={form.is_active} onChange={(v) => setForm({ ...form, is_active: v })} />}
    </Modal>
  );
}
