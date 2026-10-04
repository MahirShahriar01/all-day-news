import { useState, type FormEvent } from "react";
import { api } from "../api/client";
import { useErrorToast, useToast } from "../components/toast";
import { TextField } from "../components/ui";
import { useAuth } from "../lib/auth";

export function AccountPage() {
  const { admin, logout } = useAuth();
  const [current, setCurrent] = useState("");
  const [next, setNext] = useState("");
  const [repeat, setRepeat] = useState("");
  const toast = useToast();
  const onError = useErrorToast();

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    if (next !== repeat) return onError(new Error("The new passwords do not match"));
    try {
      await api.changePassword(current, next);
      toast("Password changed. Please sign in again.");
      logout();
    } catch (err) { onError(err); }
  };

  const logoutAll = async () => {
    try { await api.logoutAll(); logout(); } catch (e) { onError(e); }
  };

  return (
    <>
      <div className="page-head"><div><h1>My account</h1><p>{admin?.email} · {admin?.role}</p></div></div>
      <div className="grid grid-2">
        <form className="card" onSubmit={submit}>
          <div className="card-head"><h2>Change password</h2></div>
          <TextField label="Current password" type="password" value={current} onChange={setCurrent} required />
          <TextField label="New password" type="password" value={next} onChange={setNext} required hint="At least 10 characters. A short sentence is easy to remember and hard to guess." />
          <TextField label="Repeat new password" type="password" value={repeat} onChange={setRepeat} required />
          <button className="btn btn-primary" disabled={next.length < 10}>Change password</button>
        </form>
        <div className="card">
          <div className="card-head"><h2>Sessions</h2></div>
          <p className="muted mb">Signed in on a shared or lost computer? Sign out everywhere, including this browser.</p>
          <button className="btn btn-danger" onClick={logoutAll}>Sign out on all devices</button>
        </div>
      </div>
    </>
  );
}
