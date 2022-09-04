import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "path";

// https://vitejs.dev/config/
export default defineConfig({
  root: resolve(__dirname, "client2"),
  assetsInclude: ["**/*.glb"],
  build: {
    outDir: resolve(__dirname, "build2"),
    emptyOutDir: true,
  },
  plugins: [
    react({
      jsxImportSource: "@emotion/react",
      babel: {
        plugins: ["@emotion"],
      },
    }),
  ],
  esbuild: {
    jsxFactory: "jsx",
    jsxInject: "import {jsx} from '@emotion/react'",
    logOverride: {
      "this-is-undefined-in-esm": "silent",
    },
  },
});
