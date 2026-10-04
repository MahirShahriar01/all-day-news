import { useState } from "react";
import { BrowserRouter, NavLink, Navigate, Route, Routes, useLocation } from "react-router-dom";
import { ToastProvider } from "./components/toast";
import { Spinner } from "./components/ui";
import { AuthProvider, useAuth } from "./lib/auth";
import { AccountPage } from "./pages/Account";
import { AdminsPage } from "./pages/Admins";
import { CategoriesPage } from "./pages/Categories";
import { DashboardPage } from "./pages/Dashboard";
import { FeaturedPage } from "./pages/Featured";
import { LoginPage } from "./pages/Login";
import { MediaLibraryPage } from "./pages/MediaLibrary";
import { SettingsPage } from "./pages/Settings";
import { SitesPage } from "./pages/Sites";

const NAV = [
  { group: "Content", items: [
    { to: "/", icon: "◈", label: "Dashboard", end: true },
    { to: "/categories", icon: "🗂", label: "Categories" },
    { to: "/sites", icon: "🌐", label: "Websites" },
    { to: "/featured", icon: "★", label: "Featured" },
    { to: "/media", icon: "🖼", label: "Media library" },
  ] },
  { group: "Appearance", items: [
    { to: "/branding", icon: "✦", label: "Branding" },
    { to: "/theme", icon: "🎨", label: "Colours & style" },
    { to: "/layout", icon: "▦", label: "Home screen" },
    { to: "/browser", icon: "🧭", label: "Browser" },
  ] },
  { group: "Settings", items: [
    { to: "/legal", icon: "🛡", label: "Privacy & legal" },
    { to: "/admins", icon: "👥", label: "Administrators", owner: true },
    { to: "/account", icon: "👤", label: "My account" },
  ] },
];

function Shell() {
  const { admin, logout } = useAuth();
  const [open, setOpen] = useState(false);
  const location = useLocation();
  const isOwner = admin?.role === "owner";
  return (
    <div className="shell">
      <aside className={`sidebar ${open ? "open" : ""}`} aria-label="Main navigation">
        <div className="brand"><div className="brand-mark">A</div><div><b>All in One News</b><small>Admin panel</small></div></div>
        {NAV.map((g) => (
          <nav key={g.group} aria-label={g.group}>
            <div className="nav-label">{g.group}</div>
            {g.items.filter((i) => !("owner" in i) || isOwner).map((i) => (
              <NavLink key={i.to} to={i.to} end={"end" in i} className="nav-link" onClick={() => setOpen(false)}>
                <span className="ico" aria-hidden>{i.icon}</span>{i.label}
              </NavLink>
            ))}
          </nav>
        ))}
        <div className="sidebar-footer">
          <div className="muted" style={{ fontSize: 12, padding: "0 12px 8px" }}>{admin?.email}</div>
          <button className="btn btn-ghost" style={{ width: "100%", justifyContent: "flex-start" }} onClick={logout}>⎋ Sign out</button>
        </div>
      </aside>
      <div className="main">
        <header className="topbar">
          <button className="btn btn-icon menu-btn" onClick={() => setOpen(!open)} aria-label="Open menu">☰</button>
          <span className="faint" style={{ fontSize: 13 }}>{location.pathname === "/" ? "Overview" : location.pathname.slice(1)}</span>
          <div className="spacer" />
          <a className="btn btn-sm" href="/api/v1/config" target="_blank" rel="noreferrer" title="The data the mobile app downloads">API feed ↗</a>
        </header>
        <main className="content" onClick={() => open && setOpen(false)}>
          <Routes>
            <Route path="/" element={<DashboardPage />} />
            <Route path="/categories" element={<CategoriesPage />} />
            <Route path="/sites" element={<SitesPage />} />
            <Route path="/featured" element={<FeaturedPage />} />
            <Route path="/media" element={<MediaLibraryPage />} />
            <Route path="/branding" element={<SettingsPage key="branding" section="branding" />} />
            <Route path="/theme" element={<SettingsPage key="theme" section="theme" />} />
            <Route path="/layout" element={<SettingsPage key="layout" section="layout" />} />
            <Route path="/browser" element={<SettingsPage key="browser" section="browser" />} />
            <Route path="/legal" element={<SettingsPage key="legal" section="legal" />} />
            {isOwner && <Route path="/admins" element={<AdminsPage />} />}
            <Route path="/account" element={<AccountPage />} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </main>
      </div>
    </div>
  );
}

function Gate() {
  const { admin, loading } = useAuth();
  if (loading) return <Spinner />;
  return admin ? <Shell /> : <LoginPage />;
}

export default function App() {
  return (
    <BrowserRouter basename="/admin">
      <ToastProvider>
        <AuthProvider>
          <Gate />
        </AuthProvider>
      </ToastProvider>
    </BrowserRouter>
  );
}
