import { useEffect, useState } from "react";
import { api } from "../api/client";
import type { AppSettings, SettingsSection } from "../api/types";
import { MediaInput } from "../components/Media";
import { PhonePreview } from "../components/PhonePreview";
import { useErrorToast, useToast } from "../components/toast";
import { ColorField, Field, Segmented, Spinner, TextField, Toggle } from "../components/ui";

const META: Record<SettingsSection, { title: string; intro: string }> = {
  branding: { title: "Branding", intro: "Your app’s name, tagline and logo as users see them inside the app." },
  theme: { title: "Colours & style", intro: "Colours, card style and corner roundness. The preview updates as you type." },
  layout: { title: "Home screen", intro: "What appears on the home screen and how it is arranged." },
  browser: { title: "Browser", intro: "How websites open when a user taps a card." },
  legal: { title: "Privacy & legal", intro: "Required by Google Play and the App Store. Shown on the app’s About screen." },
};

const THEME_PRESETS: { name: string; theme: Partial<AppSettings["theme"]> }[] = [
  { name: "Neon Night", theme: { mode: "dark", primary_color: "#FF7C4DFF", secondary_color: "#FF00E5FF", accent_color: "#FFFF4081", background_color: "#FF0A0E1A", surface_color: "#FF141A2E", text_color: "#FFF5F7FF", gradient_start: "#FF7C4DFF", gradient_end: "#FF00E5FF" } },
  { name: "Crimson News", theme: { mode: "dark", primary_color: "#FFFF3D57", secondary_color: "#FFFFB74D", accent_color: "#FFFFD54F", background_color: "#FF0F0B10", surface_color: "#FF1C1418", text_color: "#FFFFF4F4", gradient_start: "#FFFF3D57", gradient_end: "#FFFF8A00" } },
  { name: "Ocean", theme: { mode: "dark", primary_color: "#FF2979FF", secondary_color: "#FF1DE9B6", accent_color: "#FF00B0FF", background_color: "#FF06121F", surface_color: "#FF0D2033", text_color: "#FFEAF6FF", gradient_start: "#FF2979FF", gradient_end: "#FF1DE9B6" } },
  { name: "Clean Light", theme: { mode: "light", primary_color: "#FF5B3DF5", secondary_color: "#FF00B8D4", accent_color: "#FFFF4081", background_color: "#FFF4F6FC", surface_color: "#FFFFFFFF", text_color: "#FF141A33", gradient_start: "#FF5B3DF5", gradient_end: "#FF00B8D4" } },
];

export function SettingsPage({ section }: { section: SettingsSection }) {
  const [settings, setSettings] = useState<AppSettings | null>(null);
  const [saved, setSaved] = useState<string>("");
  const [busy, setBusy] = useState(false);
  const toast = useToast();
  const onError = useErrorToast();

  useEffect(() => {
    api.settings().then((s) => { setSettings(s); setSaved(JSON.stringify(s[section])); }).catch(onError);
  }, [section, onError]);

  if (!settings) return <Spinner />;
  const dirty = JSON.stringify(settings[section]) !== saved;

  function update<K extends SettingsSection>(sec: K, patch: Partial<AppSettings[K]>) {
    setSettings((s) => (s ? { ...s, [sec]: { ...s[sec], ...patch } } : s));
  }

  const save = async () => {
    setBusy(true);
    try {
      const value = await api.saveSection(section, settings[section]);
      setSettings({ ...settings, [section]: value });
      setSaved(JSON.stringify(value));
      toast("Saved. The app picks this up on next launch or refresh.");
    } catch (e) { onError(e); } finally { setBusy(false); }
  };

  const b = settings.branding, t = settings.theme, l = settings.layout, br = settings.browser, lg = settings.legal;

  return (
    <>
      <div className="page-head">
        <div><h1>{META[section].title}</h1><p>{META[section].intro}</p></div>
        <div className="flex">
          {dirty && <span className="chip gold">Unsaved changes</span>}
          <button className="btn btn-primary" onClick={save} disabled={busy || !dirty}>{busy ? "Saving…" : "Save changes"}</button>
        </div>
      </div>
      <div className="split">
        <div className="card">
          {section === "branding" && (
            <>
              <TextField label="App name" value={b.app_name} onChange={(v) => update("branding", { app_name: v })} maxLength={60}
                hint="Shown at the top of the home screen. The name under the phone icon is set in the store build (see Build guide)." />
              <TextField label="Tagline" value={b.tagline} onChange={(v) => update("branding", { tagline: v })} maxLength={120} />
              <MediaInput label="App logo" value={b.logo_url} onChange={(v) => update("branding", { logo_url: v })} hint="Square PNG/WebP with transparent background, 512×512 recommended." />
              <MediaInput label="Splash image (optional)" value={b.splash_image_url} onChange={(v) => update("branding", { splash_image_url: v })} hint="Shown briefly while the app loads its content." />
            </>
          )}

          {section === "theme" && (
            <>
              <div className="field">
                <span className="label">Quick presets</span>
                <div className="flex">
                  {THEME_PRESETS.map((p) => (
                    <button key={p.name} className="btn btn-sm" onClick={() => update("theme", p.theme)}>
                      <span style={{ width: 14, height: 14, borderRadius: 4, background: `linear-gradient(135deg, #${p.theme.gradient_start!.slice(3)}, #${p.theme.gradient_end!.slice(3)})` }} />
                      {p.name}
                    </button>
                  ))}
                </div>
              </div>
              <Segmented label="Appearance" value={t.mode} onChange={(v) => update("theme", { mode: v })}
                options={[{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }, { value: "system", label: "Follow phone" }]} />
              <div className="grid grid-2">
                <ColorField label="Primary" value={t.primary_color} onChange={(v) => update("theme", { primary_color: v })} />
                <ColorField label="Secondary" value={t.secondary_color} onChange={(v) => update("theme", { secondary_color: v })} />
                <ColorField label="Accent (badges)" value={t.accent_color} onChange={(v) => update("theme", { accent_color: v })} />
                <ColorField label="Text" value={t.text_color} onChange={(v) => update("theme", { text_color: v })} hint="Dark mode text colour." />
                <ColorField label="Background" value={t.background_color} onChange={(v) => update("theme", { background_color: v })} hint="Dark mode background." />
                <ColorField label="Surface (cards)" value={t.surface_color} onChange={(v) => update("theme", { surface_color: v })} />
                <ColorField label="Gradient start" value={t.gradient_start} onChange={(v) => update("theme", { gradient_start: v })} />
                <ColorField label="Gradient end" value={t.gradient_end} onChange={(v) => update("theme", { gradient_end: v })} />
              </div>
              <Segmented label="Card style" value={t.card_style} onChange={(v) => update("theme", { card_style: v })}
                options={[{ value: "glass", label: "Glass" }, { value: "solid", label: "Solid" }, { value: "image", label: "Image" }]} />
              <Field label={`Corner roundness: ${t.corner_radius}px`}>
                {(id) => <input id={id} type="range" min={0} max={40} value={t.corner_radius} onChange={(e) => update("theme", { corner_radius: Number(e.target.value) })} />}
              </Field>
              <Toggle label="Animations" checked={t.enable_animations} onChange={(v) => update("theme", { enable_animations: v })} hint="Card entrance and press animations. The app also respects the phone’s “reduce motion” setting." />
            </>
          )}

          {section === "layout" && (
            <>
              <MediaInput label="Home background image" value={l.home_background_url} onChange={(v) => update("layout", { home_background_url: v })} hint="PNG, JPG, WebP or GIF. Tall images (1080×1920) look best." />
              <Field label={`Background visibility: ${Math.round(l.home_background_opacity * 100)}%`}>
                {(id) => <input id={id} type="range" min={0} max={1} step={0.05} value={l.home_background_opacity} onChange={(e) => update("layout", { home_background_opacity: Number(e.target.value) })} />}
              </Field>
              <Toggle label="Show Featured section" checked={l.show_featured} onChange={(v) => update("layout", { show_featured: v })} />
              {l.show_featured && (
                <div className="grid grid-2">
                  <TextField label="Featured title" value={l.featured_title} onChange={(v) => update("layout", { featured_title: v })} maxLength={40} />
                  <Segmented label="Featured style" value={l.featured_style} onChange={(v) => update("layout", { featured_style: v })}
                    options={[{ value: "carousel", label: "Carousel" }, { value: "grid", label: "Grid" }]} />
                </div>
              )}
              <Segmented label="Cards per row" value={l.grid_columns} onChange={(v) => update("layout", { grid_columns: v })}
                options={[{ value: 2, label: "2" }, { value: 3, label: "3" }, { value: 4, label: "4" }]} />
              <Toggle label="Show search bar" checked={l.show_search} onChange={(v) => update("layout", { show_search: v })} />
              <Toggle label="Show category tabs" checked={l.show_category_tabs} onChange={(v) => update("layout", { show_category_tabs: v })} />
              <Toggle label="Show descriptions on cards" checked={l.show_descriptions} onChange={(v) => update("layout", { show_descriptions: v })} />
              <div className="card" style={{ marginTop: 8 }}>
                <Toggle label="📣 Announcement banner" checked={l.announcement.enabled} onChange={(v) => update("layout", { announcement: { ...l.announcement, enabled: v } })} />
                {l.announcement.enabled && (
                  <>
                    <TextField label="Message" value={l.announcement.text} onChange={(v) => update("layout", { announcement: { ...l.announcement, text: v } })} maxLength={240} />
                    <TextField label="Link (optional)" value={l.announcement.url} onChange={(v) => update("layout", { announcement: { ...l.announcement, url: v } })} placeholder="https://" />
                  </>
                )}
              </div>
            </>
          )}

          {section === "browser" && (
            <>
              <Field label="Default way to open websites" hint="Individual websites can override this in their settings.">
                {(id) => (
                  <select id={id} className="input" value={br.default_open_mode} onChange={(e) => update("browser", { default_open_mode: e.target.value as AppSettings["browser"]["default_open_mode"] })}>
                    <option value="custom_tab">In-app browser tab (recommended)</option>
                    <option value="in_app">Embedded browser screen</option>
                    <option value="external">External browser</option>
                  </select>
                )}
              </Field>
              <div className="card mb" style={{ fontSize: 13 }}>
                <b>Which should I choose?</b>
                <ul className="muted" style={{ paddingLeft: 18, marginBottom: 0 }}>
                  <li><b>In-app browser tab</b>: opens a Chrome Custom Tab (Android) or Safari View (iOS) on top of the app. Users stay signed in to sites and get the browser’s security features. Safest choice for app store review.</li>
                  <li><b>Embedded browser</b>: the app’s own browser screen with back, forward, reload and share. Google Play and Apple may reject apps that embed other people’s websites without permission, so use it only for sites you own or are allowed to embed.</li>
                  <li><b>External browser</b>: leaves the app.</li>
                </ul>
              </div>
              <Toggle label="Show browser toolbar" checked={br.show_toolbar} onChange={(v) => update("browser", { show_toolbar: v })} hint="Back / forward / reload buttons in the embedded browser." />
              <Toggle label="Allow “Open in browser”" checked={br.allow_open_in_external_browser} onChange={(v) => update("browser", { allow_open_in_external_browser: v })} />
              <Toggle label="Allow sharing links" checked={br.allow_share} onChange={(v) => update("browser", { allow_share: v })} />
            </>
          )}

          {section === "legal" && (
            <>
              <TextField label="Publisher / company name" value={lg.publisher_name} onChange={(v) => update("legal", { publisher_name: v })} maxLength={120} />
              <TextField label="Support e-mail" type="email" value={lg.contact_email} onChange={(v) => update("legal", { contact_email: v })} hint="Shown in the app and required on the store listing." />
              <TextField label="Privacy policy URL" value={lg.privacy_policy_url} onChange={(v) => update("legal", { privacy_policy_url: v })} placeholder="Leave empty to use the built-in page"
                hint={<>Leave empty to use the hosted page at <a href="/privacy-policy" target="_blank" rel="noreferrer">/privacy-policy</a> (generated from the text below).</>} />
              <TextField label="Terms of use URL (optional)" value={lg.terms_url} onChange={(v) => update("legal", { terms_url: v })} placeholder="https://" />
              <TextField label="About text" value={lg.about_text} onChange={(v) => update("legal", { about_text: v })} multiline maxLength={4000} />
              <TextField label="Privacy policy text" value={lg.privacy_policy_text} onChange={(v) => update("legal", { privacy_policy_text: v })} multiline maxLength={50000}
                hint="Leave empty to use the default policy (written for this app's data practices). Use # Heading, ## Subheading and blank lines between paragraphs." />
            </>
          )}
        </div>
        <div className="sticky"><PhonePreview settings={settings} /></div>
      </div>
    </>
  );
}
