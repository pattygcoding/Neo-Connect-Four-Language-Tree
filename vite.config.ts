import { cpSync, existsSync } from "node:fs";
import { defineConfig, type Plugin } from "vite";
import vue from "@vitejs/plugin-vue";

// The Play tab runs a page that belongs to the repository rather than to this app:
// `languages/htmlcss/connect_four.html` *is* the HTML/CSS implementation, and the
// generated data points the iframe straight at that path.  The dev server already
// serves it (it sits inside the project root), so only the build has to copy it to
// the same place in `dist/`.
function copyInteractivePreviews(): Plugin {
    return {
        name: "connect-four:copy-interactive-previews",
        apply: "build",
        closeBundle() {
            const from = new URL("languages/htmlcss", import.meta.url);
            const to = new URL("dist/languages/htmlcss", import.meta.url);
            if (existsSync(from)) {
                cpSync(from, to, { recursive: true });
            }
        },
    };
}

export default defineConfig({
    // Relative asset URLs, so one build works both at the custom domain's root and
    // under a `<user>.github.io/<repo>/` path - the dashboard derives its own
    // deployment prefix (`APP_DIR`) from wherever the page happens to be served.
    base: "./",
    plugins: [vue(), copyInteractivePreviews()],
    build: {
        outDir: "dist",
        emptyOutDir: true,
    },
});
