import { createInertiaApp } from "@inertiajs/vue3";
import "./app.css";

createInertiaApp({
  pages: {
    path: "./pages",
    lazy: true,
  },
});
