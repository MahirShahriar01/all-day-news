/**
 * Thin, typed wrapper around fetch for the admin API.
 * All endpoints live under /api/v1/admin and require a bearer token.
 */
import type {
  Admin, AppSettings, Category, Dashboard, Media, Page, SettingsSection, Site, TokenResponse,
} from "./types";

const BASE = (import.meta.env.VITE_API_BASE_URL as string | undefined)?.replace(/\/$/, "") ?? "";
const TOKEN_KEY = "aion.admin.token";

export class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
  }
}

export const session = {
  get token(): string | null {
    try {
      const raw = localStorage.getItem(TOKEN_KEY);
      if (!raw) return null;
      const { token, expires } = JSON.parse(raw) as { token: string; expires: string };
      if (new Date(expires).getTime() < Date.now()) return null;
      return token;
    } catch {
      return null;
    }
  },
  save(token: string, expires: string) {
    try {
      localStorage.setItem(TOKEN_KEY, JSON.stringify({ token, expires }));
    } catch {
      /* storage unavailable: session lasts until reload */
    }
  },
  clear() {
    try {
      localStorage.removeItem(TOKEN_KEY);
    } catch {
      /* ignore */
    }
  },
};

let onUnauthorized: () => void = () => {};
export function setUnauthorizedHandler(fn: () => void) {
  onUnauthorized = fn;
}

function describe(detail: unknown): string {
  if (typeof detail === "string") return detail;
  if (Array.isArray(detail)) {
    return detail
      .map((d: { loc?: (string | number)[]; msg?: string }) => {
        const field = d.loc?.filter((p) => p !== "body").join(" → ");
        const msg = (d.msg ?? "Invalid value").replace(/^Value error, /, "");
        return field ? `${field}: ${msg}` : msg;
      })
      .join("\n");
  }
  return "Something went wrong";
}

async function request<T>(method: string, path: string, body?: unknown): Promise<T> {
  const headers: Record<string, string> = {};
  const token = session.token;
  if (token) headers.Authorization = `Bearer ${token}`;
  let payload: BodyInit | undefined;
  if (body instanceof FormData) payload = body;
  else if (body !== undefined) {
    headers["Content-Type"] = "application/json";
    payload = JSON.stringify(body);
  }
  let res: Response;
  try {
    res = await fetch(`${BASE}/api/v1${path}`, { method, headers, body: payload });
  } catch {
    throw new ApiError(0, "Cannot reach the server. Check your internet connection.");
  }
  if (res.status === 401 && !path.startsWith("/admin/auth/login")) {
    session.clear();
    onUnauthorized();
  }
  if (!res.ok) {
    let detail: unknown = res.statusText;
    try {
      detail = (await res.json()).detail;
    } catch {
      /* not json */
    }
    throw new ApiError(res.status, describe(detail));
  }
  if (res.status === 204) return undefined as T;
  return (await res.json()) as T;
}

const get = <T,>(p: string) => request<T>("GET", p);
const post = <T,>(p: string, b?: unknown) => request<T>("POST", p, b);
const put = <T,>(p: string, b?: unknown) => request<T>("PUT", p, b);
const patch = <T,>(p: string, b?: unknown) => request<T>("PATCH", p, b);
const del = (p: string) => request<void>("DELETE", p);

const qs = (params: Record<string, string | number | boolean | undefined | null>) => {
  const s = new URLSearchParams();
  Object.entries(params).forEach(([k, v]) => v !== undefined && v !== null && v !== "" && s.set(k, String(v)));
  const out = s.toString();
  return out ? `?${out}` : "";
};

export const api = {
  login: (email: string, password: string) => post<TokenResponse>("/admin/auth/login", { email, password }),
  me: () => get<Admin>("/admin/auth/me"),
  changePassword: (current_password: string, new_password: string) =>
    post<void>("/admin/auth/change-password", { current_password, new_password }),
  logoutAll: () => post<void>("/admin/auth/logout-all"),

  dashboard: () => get<Dashboard>("/admin/dashboard"),

  categories: () => get<Category[]>("/admin/categories"),
  createCategory: (data: Partial<Category>) => post<Category>("/admin/categories", data),
  updateCategory: (id: number, data: Partial<Category>) => patch<Category>(`/admin/categories/${id}`, data),
  deleteCategory: (id: number, opts: { move_sites_to?: number; delete_sites?: boolean }) =>
    del(`/admin/categories/${id}${qs(opts)}`),
  reorderCategories: (ids: number[]) => post<void>("/admin/categories/reorder", { ids }),

  sites: (params: { category_id?: number; uncategorised?: boolean; featured?: boolean; q?: string } = {}) =>
    get<Page<Site>>(`/admin/sites${qs({ ...params, limit: 1000 })}`),
  createSite: (data: Partial<Site>) => post<Site>("/admin/sites", data),
  updateSite: (id: number, data: Partial<Site>) => patch<Site>(`/admin/sites/${id}`, data),
  deleteSite: (id: number) => del(`/admin/sites/${id}`),
  reorderSites: (ids: number[]) => post<void>("/admin/sites/reorder", { ids }),
  reorderFeatured: (ids: number[]) => post<void>("/admin/sites/featured/reorder", { ids }),
  bulkSites: (ids: number[], action: string, category_id?: number | null) =>
    post<void>("/admin/sites/bulk", { ids, action, category_id }),

  media: (kind?: string) => get<Page<Media>>(`/admin/media${qs({ kind, limit: 500 })}`),
  upload: (file: File) => {
    const fd = new FormData();
    fd.append("file", file);
    return post<Media>("/admin/media", fd);
  },
  deleteMedia: (id: number, force = false) => del(`/admin/media/${id}${qs({ force: force || undefined })}`),

  settings: () => get<AppSettings>("/admin/settings"),
  saveSection: <K extends SettingsSection>(section: K, value: AppSettings[K]) =>
    put<AppSettings[K]>(`/admin/settings/${section}`, value),

  admins: () => get<Admin[]>("/admin/admins"),
  createAdmin: (data: { email: string; full_name: string; password: string; role: string }) =>
    post<Admin>("/admin/admins", data),
  updateAdmin: (id: number, data: Partial<Admin> & { password?: string }) => patch<Admin>(`/admin/admins/${id}`, data),
  deleteAdmin: (id: number) => del(`/admin/admins/${id}`),
};

/** Resolve a stored media path (/uploads/x.png) for display in the browser. */
export const mediaSrc = (url: string) => (url && url.startsWith("/") ? `${BASE}${url}` : url);
