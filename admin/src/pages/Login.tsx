import { useState, type FormEvent } from "react";
import { useAuth } from "../lib/auth";

export function LoginPage() {
  const { login } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent) => {
    e.preventDefault();
    setBusy(true);
    setError("");
    try {
      await login(email, password);
    } catch (err) {
      setError((err as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="login-wrap">
      <form className="card login-card" onSubmit={submit}>
        <div className="brand-mark" style={{ width: 48, height: 48, fontSize: 20 }}>A</div>
        <h1>Welcome back</h1>
        <p className="muted mb">Sign in to manage All in One News.</p>
        {error && <div className="error-box" role="alert">{error}</div>}
        <div className="field">
          <label htmlFor="email">E-mail</label>
          <input id="email" className="input" type="email" autoComplete="username" required autoFocus value={email} onChange={(e) => setEmail(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="password">Password</label>
          <input id="password" className="input" type="password" autoComplete="current-password" required value={password} onChange={(e) => setPassword(e.target.value)} />
        </div>
        <button className="btn btn-primary" style={{ width: "100%", marginTop: 6 }} disabled={busy}>
          {busy ? "Signing in…" : "Sign in"}
        </button>
        <p className="faint mt" style={{ fontSize: 12 }}>Forgot your password? Ask an owner to reset it, or see the Admin Guide.</p>
      </form>
    </div>
  );
}
