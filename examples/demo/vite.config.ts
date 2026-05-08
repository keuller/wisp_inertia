import { defineConfig } from "vite";
import laravel from "laravel-vite-plugin";
import vue from "@vitejs/plugin-vue";
import inertia from "@inertiajs/vite";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  resolve: {
    tsconfigPaths: true,
  },
  plugins: [
    laravel({
      input: "priv/app/app.ts",
      buildDirectory: "priv/static",
      publicDirectory: "priv/public",
      refresh: true,
    }),
    inertia({ ssr: false }),
    tailwindcss(),
    vue(),
  ],
  build: {
    manifest: true,
    outDir: "priv/static",
    rollupOptions: {
      input: ["priv/app/app.ts"],
      output: {
        entryFileNames: "assets/[name].js",
        chunkFileNames: "assets/[name].js",
        assetFileNames: "assets/[name].[ext]",
      },
    },
  },
  server: {
    hmr: {
      host: "localhost",
    },
  },
});
