import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// The admin panel is served under /admin/ (by nginx or by the API itself).
// In development, API calls are proxied to the local backend.
export default defineConfig({
  base: "/admin/",
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": "http://localhost:8000",
      "/uploads": "http://localhost:8000",
      "/privacy-policy": "http://localhost:8000",
    },
  },
  build: { outDir: "dist", sourcemap: false },
});
