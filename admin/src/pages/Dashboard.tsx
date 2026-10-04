import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "../api/client";
import type { Dashboard } from "../api/types";
import { useErrorToast } from "../components/toast";
import { Spinner } from "../components/ui";
import { formatBytes, timeAgo } from "../lib/color";

const ACTION_ICON: Record<string, string> = { create: "➕", update: "✏️", delete: "🗑️", reorder: "↕️", login: "🔑" };

export function DashboardPage() {
  const [data, setData] = useState<Dashboard | null>(null);
  const onError = useErrorToast();
  useEffect(() => { api.dashboard().then(setData).catch(onError); }, [onError]);
  if (!data) return <Spinner />;

  const stats = [
    { lbl: "Websites", num: data.sites, sub: `${data.sites_enabled} visible in the app`, to: "/sites" },
    { lbl: "Categories", num: data.categories, sub: `${data.categories_enabled} enabled`, to: "/categories" },
    { lbl: "Featured", num: data.sites_featured, sub: "shown at the top of the app", to: "/featured" },
    { lbl: "Media files", num: data.media_files, sub: formatBytes(data.media_bytes), to: "/media" },
  ];

  return (
    <>
      <div className="page-head">
        <div>
          <h1>Dashboard</h1>
          <p>Everything you change here appears in the app within a minute, with no app update needed.</p>
        </div>
        <div className="flex">
          <Link className="btn" to="/categories?new=1">New category</Link>
          <Link className="btn btn-primary" to="/sites?new=1">＋ Add website</Link>
        </div>
      </div>
      <div className="grid grid-4">
        {stats.map((s) => (
          <Link key={s.lbl} to={s.to} className="card stat" style={{ textDecoration: "none", color: "inherit" }}>
            <div className="lbl">{s.lbl}</div>
            <div className="num">{s.num}</div>
            <div className="sub">{s.sub}</div>
          </Link>
        ))}
      </div>
      {data.sites_uncategorised > 0 && (
        <div className="card mt">
          ⚠️ {data.sites_uncategorised} website(s) have no category. They appear in search and Featured only.{" "}
          <Link to="/sites?uncategorised=1">Review them</Link>
        </div>
      )}
      <div className="grid grid-2 mt">
        <div className="card">
          <div className="card-head"><h2>Quick start</h2></div>
          <ol className="muted" style={{ margin: 0, paddingLeft: 18, lineHeight: 2 }}>
            <li><Link to="/branding">Set your app name and logo</Link></li>
            <li><Link to="/theme">Choose colours and style</Link></li>
            <li><Link to="/categories">Create categories</Link> (News, Sports, …)</li>
            <li><Link to="/sites">Add websites</Link> with logos and descriptions</li>
            <li><Link to="/featured">Pick featured websites</Link> for the top of the home screen</li>
            <li><Link to="/legal">Fill in privacy &amp; contact details</Link> (required by app stores)</li>
          </ol>
        </div>
        <div className="card">
          <div className="card-head"><h2>Recent activity</h2></div>
          {data.recent_activity.length === 0 && <p className="muted">Nothing yet.</p>}
          <div className="list">
            {data.recent_activity.map((a) => (
              <div key={a.id} className="flex" style={{ gap: 10 }}>
                <span aria-hidden>{ACTION_ICON[a.action] ?? "•"}</span>
                <div className="grow" style={{ flex: 1, minWidth: 0 }}>
                  <div>{a.summary}</div>
                  <div className="faint" style={{ fontSize: 12 }}>{a.admin_email} · {timeAgo(a.created_at)}</div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </>
  );
}
