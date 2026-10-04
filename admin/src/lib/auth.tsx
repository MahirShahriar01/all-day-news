import { createContext, useCallback, useContext, useEffect, useState, type ReactNode } from "react";
import { api, session, setUnauthorizedHandler } from "../api/client";
import type { Admin } from "../api/types";

interface AuthState {
  admin: Admin | null;
  loading: boolean;
  login: (email: string, password: string) => Promise<void>;
  logout: () => void;
}

const AuthCtx = createContext<AuthState>(null as unknown as AuthState);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [admin, setAdmin] = useState<Admin | null>(null);
  const [loading, setLoading] = useState(true);

  const logout = useCallback(() => {
    session.clear();
    setAdmin(null);
  }, []);

  useEffect(() => {
    setUnauthorizedHandler(() => setAdmin(null));
    if (!session.token) {
      setLoading(false);
      return;
    }
    api.me().then(setAdmin).catch(() => session.clear()).finally(() => setLoading(false));
  }, []);

  const login = useCallback(async (email: string, password: string) => {
    const res = await api.login(email, password);
    session.save(res.access_token, res.expires_at);
    setAdmin(res.admin);
  }, []);

  return <AuthCtx.Provider value={{ admin, loading, login, logout }}>{children}</AuthCtx.Provider>;
}

export const useAuth = () => useContext(AuthCtx);
