/** API colours are #AARRGGBB or #RRGGBB (Flutter style). Browsers want #RRGGBB / rgba(). */
export function toCss(color: string | undefined, fallback = "#7C4DFF"): string {
  if (!color) return fallback;
  const hex = color.replace("#", "");
  if (hex.length === 6) return `#${hex}`;
  if (hex.length === 8) {
    const a = parseInt(hex.slice(0, 2), 16) / 255;
    const r = parseInt(hex.slice(2, 4), 16);
    const g = parseInt(hex.slice(4, 6), 16);
    const b = parseInt(hex.slice(6, 8), 16);
    return `rgba(${r}, ${g}, ${b}, ${a.toFixed(3)})`;
  }
  return fallback;
}

/** #AARRGGBB -> #RRGGBB for <input type="color">. */
export function toRgbHex(color: string | undefined): string {
  if (!color) return "#7c4dff";
  const hex = color.replace("#", "");
  return `#${(hex.length === 8 ? hex.slice(2) : hex).toLowerCase()}`;
}

/** Keep the existing alpha when the picker returns #RRGGBB. */
export function fromRgbHex(rgb: string, previous?: string): string {
  const prev = (previous ?? "").replace("#", "");
  const alpha = prev.length === 8 ? prev.slice(0, 2) : "FF";
  return `#${alpha}${rgb.replace("#", "")}`.toUpperCase();
}

export function initials(text: string): string {
  const words = text.trim().split(/\s+/).filter(Boolean);
  return (words.length > 1 ? words[0][0] + words[1][0] : (words[0] ?? "?").slice(0, 2)).toUpperCase();
}

export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1024 / 1024).toFixed(1)} MB`;
}

export function timeAgo(iso: string): string {
  const s = (Date.now() - new Date(iso).getTime()) / 1000;
  if (s < 60) return "just now";
  if (s < 3600) return `${Math.floor(s / 60)} min ago`;
  if (s < 86400) return `${Math.floor(s / 3600)} h ago`;
  return new Date(iso).toLocaleDateString();
}
