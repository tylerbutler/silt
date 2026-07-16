// @ts-check
import { defineConfig } from "astro/config";

// Static, content-led brand site. No integrations needed — hand-authored CSS.
export default defineConfig({
  site: "https://silt.tylerbutler.com",
  devToolbar: { enabled: false },
});
