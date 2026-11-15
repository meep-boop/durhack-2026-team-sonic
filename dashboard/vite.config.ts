import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

export default defineConfig({
  plugins: [react()],
  // The guide models live in ../assets/models, outside this app, and are shared with the phone.
  server: { fs: { allow: [".."] } },
});
