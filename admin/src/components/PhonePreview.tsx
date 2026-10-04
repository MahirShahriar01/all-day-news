import { useEffect, useState } from "react";
import { api, mediaSrc } from "../api/client";
import type { AppSettings } from "../api/types";
import { initials, toCss } from "../lib/color";

interface PreviewSite { id: number; title: string; logo_url: string; accent_color: string; background_url: string; animation_url: string; category_id: number | null; description: string; badge: string }
interface PreviewCategory { id: number; name: string; color: string }
interface PreviewData { categories: PreviewCategory[]; sites: PreviewSite[]; featured: number[] }

let cache: PreviewData | null = null;

async function loadPreview(): Promise<PreviewData> {
  if (cache) return cache;
  const [cats, sites] = await Promise.all([api.categories(), api.sites({})]);
  const enabledCats = cats.filter((c) => c.is_enabled);
  const visible = sites.items.filter((s) => s.is_enabled && (s.category_id === null || enabledCats.some((c) => c.id === s.category_id)));
  cache = {
    categories: enabledCats,
    sites: visible,
    featured: visible.filter((s) => s.is_featured).sort((a, b) => a.featured_order - b.featured_order).map((s) => s.id),
  };
  return cache;
}

/** Approximation of the mobile home screen that updates live while editing settings. */
export function PhonePreview({ settings }: { settings: AppSettings }) {
  const [data, setData] = useState<PreviewData | null>(cache);
  useEffect(() => { loadPreview().then(setData).catch(() => setData({ categories: [], sites: [], featured: [] })); }, []);

  const t = settings.theme;
  const l = settings.layout;
  const light = t.mode === "light";
  const bg = light ? "#F4F6FC" : toCss(t.background_color);
  const surface = light ? "#FFFFFF" : toCss(t.surface_color);
  const text = light ? "#141A33" : toCss(t.text_color);
  const radius = Math.max(6, t.corner_radius * 0.7);
  const gradient = `linear-gradient(135deg, ${toCss(t.gradient_start)}, ${toCss(t.gradient_end)})`;
  const glass = t.card_style === "glass";
  const cardBg = glass ? (light ? "rgba(255,255,255,.7)" : "rgba(255,255,255,.06)") : surface;

  const featured = (data?.featured ?? []).map((id) => data!.sites.find((s) => s.id === id)).filter(Boolean) as PreviewSite[];
  const firstCat = data?.categories[0];
  const gridSites = (data?.sites ?? []).filter((s) => !firstCat || s.category_id === firstCat.id).slice(0, l.grid_columns * 3);

  return (
    <div className="phone" aria-label="App preview">
      <div className="phone-screen" style={{ background: bg, color: text }}>
        {l.home_background_url && (
          <div className="phone-bg" style={{ backgroundImage: `url(${mediaSrc(l.home_background_url)})`, opacity: l.home_background_opacity }} />
        )}
        <div className="phone-scroll">
          <div className="flex" style={{ gap: 8, marginBottom: 2 }}>
            {settings.branding.logo_url ? (
              <img src={mediaSrc(settings.branding.logo_url)} alt="" style={{ width: 28, height: 28, borderRadius: 8, objectFit: "cover" }} />
            ) : (
              <div style={{ width: 28, height: 28, borderRadius: 8, background: gradient }} />
            )}
            <div className="p-title">{settings.branding.app_name}</div>
          </div>
          <div className="p-tag">{settings.branding.tagline}</div>
          {l.announcement.enabled && l.announcement.text && (
            <div style={{ background: gradient, color: "white", borderRadius: radius, padding: "7px 10px", fontSize: 10.5, marginBottom: 10 }}>
              📣 {l.announcement.text}
            </div>
          )}
          {l.show_search && <div className="p-search" style={{ background: cardBg, border: `1px solid ${light ? "#0001" : "#fff1"}` }}>🔍 Search websites…</div>}
          {l.show_featured && featured.length > 0 && (
            <>
              <div className="p-section">{l.featured_title}</div>
              {l.featured_style === "carousel" ? (
                <div className="p-feature" style={{
                  borderRadius: radius + 4,
                  background: featured[0].background_url || featured[0].animation_url
                    ? `linear-gradient(transparent, #000a), url(${mediaSrc(featured[0].animation_url || featured[0].background_url)}) center/cover`
                    : `linear-gradient(135deg, ${toCss(featured[0].accent_color, toCss(t.gradient_start))}, ${toCss(t.gradient_end)})`,
                }}>
                  {featured[0].badge && <span style={{ position: "absolute", top: 10, left: 10, background: toCss(t.accent_color), padding: "2px 7px", borderRadius: 6, fontSize: 9 }}>{featured[0].badge}</span>}
                  {featured[0].title}
                  <span style={{ fontSize: 9.5, fontWeight: 500, opacity: 0.85 }}>{featured[0].description}</span>
                </div>
              ) : (
                <div className="p-grid" style={{ gridTemplateColumns: "1fr 1fr" }}>
                  {featured.slice(0, 4).map((s) => (
                    <div key={s.id} className="p-feature" style={{ height: 70, borderRadius: radius, background: `linear-gradient(135deg, ${toCss(s.accent_color, toCss(t.gradient_start))}, ${toCss(t.gradient_end)})`, fontSize: 10.5 }}>{s.title}</div>
                  ))}
                </div>
              )}
            </>
          )}
          {l.show_category_tabs && (
            <div className="p-tabs">
              {(data?.categories ?? []).slice(0, 5).map((c, i) => (
                <span key={c.id} className="p-tab" style={i === 0 ? { background: gradient, color: "white" } : { background: cardBg }}>{c.name}</span>
              ))}
            </div>
          )}
          <div className="p-grid" style={{ gridTemplateColumns: `repeat(${l.grid_columns}, 1fr)` }}>
            {gridSites.map((s) => (
              <div key={s.id} className="p-card" style={{ background: cardBg, borderRadius: radius, border: glass ? `1px solid ${light ? "#0001" : "#ffffff14"}` : "none" }}>
                <div className="p-logo" style={{ background: toCss(s.accent_color, toCss(t.primary_color)), borderRadius: radius * 0.6 }}>
                  {s.logo_url ? <img src={mediaSrc(s.logo_url)} alt="" /> : initials(s.title)}
                </div>
                <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", maxWidth: "100%" }}>{s.title}</span>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}

export function invalidatePreview() {
  cache = null;
}
