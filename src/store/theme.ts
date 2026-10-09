import { ref } from "vue";

export type Theme = "dark" | "light";

// The head script in index.html has already chosen the theme before first paint;
// this mirrors that decision into Vue state so the toggle knows which way to flip,
// and owns every change after it.
export const theme = ref<Theme>(readTheme());

function readTheme(): Theme {
    return document.documentElement.getAttribute("data-theme") === "light" ? "light" : "dark";
}

export function applyTheme(next: Theme): void {
    theme.value = next;
    document.documentElement.setAttribute("data-theme", next);
    try {
        localStorage.setItem("cf-theme", next);
    } catch {
        // private mode: the theme still applies to this visit
    }
    parkUnusedPrismTheme(next);
}

export function initTheme(): void {
    applyTheme(theme.value);
}

// The toggle offers the mode it switches to: sun while dark, moon while light.
// Which icon is drawn is CSS (`.theme-icon-sun` / `.theme-icon-moon`).
export function toggleTheme(): void {
    applyTheme(theme.value === "light" ? "dark" : "light");
}

// Both Prism themes are linked, so the unused one is parked behind `media="not all"`
// to keep the token colours in step with the palette.
function parkUnusedPrismTheme(next: Theme): void {
    const isLight = next === "light";
    const dark = document.querySelector<HTMLLinkElement>("#prism-dark");
    const light = document.querySelector<HTMLLinkElement>("#prism-light");
    if (dark) {
        dark.media = isLight ? "not all" : "all";
    }
    if (light) {
        light.media = isLight ? "all" : "not all";
    }
}
