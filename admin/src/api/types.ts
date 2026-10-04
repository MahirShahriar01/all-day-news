export type Role = "owner" | "editor";

export interface Admin {
  id: number;
  email: string;
  full_name: string;
  role: Role;
  is_active: boolean;
  last_login_at: string | null;
  created_at: string;
}

export interface TokenResponse {
  access_token: string;
  expires_at: string;
  admin: Admin;
}

export interface Category {
  id: number;
  name: string;
  slug: string;
  description: string;
  icon_name: string;
  icon_url: string;
  background_url: string;
  color: string;
  sort_order: number;
  is_enabled: boolean;
  site_count: number;
}

export type OpenMode = "default" | "in_app" | "custom_tab" | "external";

export interface Site {
  id: number;
  title: string;
  url: string;
  category_id: number | null;
  description: string;
  logo_url: string;
  background_url: string;
  animation_url: string;
  accent_color: string;
  badge: string;
  tags: string;
  open_mode: OpenMode;
  is_featured: boolean;
  featured_order: number;
  sort_order: number;
  is_enabled: boolean;
  updated_at: string;
}

export interface Page<T> {
  items: T[];
  total: number;
}

export interface Media {
  id: number;
  kind: "image" | "animation" | "video";
  url: string;
  absolute_url: string;
  mime_type: string;
  size_bytes: number;
  width: number | null;
  height: number | null;
  original_name: string;
  created_at: string;
}

export interface Activity {
  id: number;
  admin_email: string;
  action: string;
  entity: string;
  summary: string;
  created_at: string;
}

export interface Dashboard {
  categories: number;
  categories_enabled: number;
  sites: number;
  sites_enabled: number;
  sites_featured: number;
  sites_uncategorised: number;
  media_files: number;
  media_bytes: number;
  recent_activity: Activity[];
}

export interface BrandingSettings {
  app_name: string;
  tagline: string;
  logo_url: string;
  splash_image_url: string;
}

export interface ThemeSettings {
  mode: "dark" | "light" | "system";
  primary_color: string;
  secondary_color: string;
  accent_color: string;
  background_color: string;
  surface_color: string;
  text_color: string;
  gradient_start: string;
  gradient_end: string;
  corner_radius: number;
  card_style: "glass" | "solid" | "image";
  enable_animations: boolean;
}

export interface LayoutSettings {
  home_background_url: string;
  home_background_opacity: number;
  show_featured: boolean;
  featured_title: string;
  featured_style: "carousel" | "grid";
  show_search: boolean;
  show_category_tabs: boolean;
  grid_columns: number;
  show_descriptions: boolean;
  announcement: { enabled: boolean; text: string; url: string };
}

export interface BrowserSettings {
  default_open_mode: "in_app" | "custom_tab" | "external";
  show_toolbar: boolean;
  allow_open_in_external_browser: boolean;
  allow_share: boolean;
}

export interface LegalSettings {
  privacy_policy_url: string;
  terms_url: string;
  contact_email: string;
  publisher_name: string;
  about_text: string;
  privacy_policy_text: string;
}

export interface AppSettings {
  branding: BrandingSettings;
  theme: ThemeSettings;
  layout: LayoutSettings;
  browser: BrowserSettings;
  legal: LegalSettings;
}

export type SettingsSection = keyof AppSettings;
