// Design tokens mirrored from patrickgoodwin.dev: a navy canvas, a mint accent,
// Inter for text and JetBrains Mono for technical labels.  This is the config the
// page shipped inline for the Tailwind Play CDN, moved here so the stylesheet is
// built instead of compiled in the browser - the palette, the class names and the
// rendered result are unchanged.  Every colour resolves to a CSS variable declared
// in `src/styles/app.css`, so one `data-theme` attribute flips the whole theme.
export default {
    content: ["./index.html", "./src/**/*.{vue,ts}"],
    theme: {
        extend: {
            colors: {
                ink: {
                    950: "rgb(var(--ink-950) / <alpha-value>)",
                    900: "rgb(var(--ink-900) / <alpha-value>)",
                    850: "rgb(var(--ink-850) / <alpha-value>)",
                    800: "rgb(var(--ink-800) / <alpha-value>)",
                    700: "rgb(var(--ink-700) / <alpha-value>)",
                    600: "rgb(var(--ink-600) / <alpha-value>)",
                },
                // Filled accents keep the pale mint; text/borders use `accent`,
                // which darkens in light mode so it stays legible on white.
                mint: {
                    300: "#b9f4da",
                    400: "#8debc4",
                    500: "#6fd9af",
                    600: "#4fb894",
                },
                accent: "rgb(var(--accent) / <alpha-value>)",
                "on-accent": "#05070c",
                fg: "rgb(var(--fg) / <alpha-value>)",
                "fg-strong": "rgb(var(--fg-strong) / <alpha-value>)",
                "fg-soft": "rgb(var(--fg-soft) / <alpha-value>)",
                "fg-muted": "rgb(var(--fg-muted) / <alpha-value>)",
                "fg-dim": "rgb(var(--fg-dim) / <alpha-value>)",
                gutter: "rgb(var(--gutter) / <alpha-value>)",
                hint: "rgb(var(--hint) / <alpha-value>)",
                console: "rgb(var(--console) / <alpha-value>)",
                line: "rgb(var(--line) / <alpha-value>)",
            },
            fontFamily: {
                sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
                mono: ['"JetBrains Mono"', "ui-monospace", "SFMono-Regular", "monospace"],
            },
        },
    },
};
