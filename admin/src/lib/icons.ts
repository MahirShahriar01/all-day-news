/**
 * Built-in category icons. Names match Material Icons and the map in
 * app/lib/core/utils/icon_registry.dart (keep both lists in sync).
 */
export const CATEGORY_ICONS: { name: string; emoji: string; label: string }[] = [
  { name: "newspaper", emoji: "📰", label: "News" },
  { name: "live_tv", emoji: "📺", label: "Live TV" },
  { name: "sports_soccer", emoji: "⚽", label: "Football" },
  { name: "sports_cricket", emoji: "🏏", label: "Cricket" },
  { name: "sports", emoji: "🏅", label: "Sports" },
  { name: "memory", emoji: "💻", label: "Technology" },
  { name: "science", emoji: "🔬", label: "Science" },
  { name: "movie", emoji: "🎬", label: "Movies" },
  { name: "music_note", emoji: "🎵", label: "Music" },
  { name: "radio", emoji: "📻", label: "Radio" },
  { name: "podcasts", emoji: "🎙️", label: "Podcasts" },
  { name: "videogame_asset", emoji: "🎮", label: "Games" },
  { name: "school", emoji: "🎓", label: "Education" },
  { name: "info", emoji: "ℹ️", label: "Information" },
  { name: "public", emoji: "🌍", label: "World" },
  { name: "business", emoji: "🏢", label: "Business" },
  { name: "attach_money", emoji: "💰", label: "Finance" },
  { name: "health_and_safety", emoji: "🩺", label: "Health" },
  { name: "cloud", emoji: "⛅", label: "Weather" },
  { name: "flight", emoji: "✈️", label: "Travel" },
  { name: "restaurant", emoji: "🍽️", label: "Food" },
  { name: "shopping_bag", emoji: "🛍️", label: "Shopping" },
  { name: "gavel", emoji: "⚖️", label: "Government" },
  { name: "star", emoji: "⭐", label: "Favourites" },
  { name: "apps", emoji: "🔗", label: "Other" },
];

export const iconEmoji = (name: string) => CATEGORY_ICONS.find((i) => i.name === name)?.emoji ?? "🔗";
