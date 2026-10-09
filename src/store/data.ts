import type { DashboardData, Item, Scenario, TabId } from "../types";

// Everything the dashboard displays, read straight from the generated payload.
// These helpers are pure lookups over `DATA` - the reactive selection on top of
// them lives in `session.ts`.
export const DATA: DashboardData | undefined = window.CONNECT_FOUR_DATA;

// A checkout that has not run the generator yet still boots and shows the empty
// state (which says how to generate the data) instead of throwing.
export const hasData: boolean = !!DATA && Array.isArray(DATA.languages) && DATA.languages.length > 0;

// The implementation the showcase falls back to when the address names none (`/`
// and `index.html` both land here).  C# is the reference walkthrough, so it opens
// first; a fork without it falls back to the first language present.
export const DEFAULT_LANG_ID = "csharp";

export function languages(): Item[] {
    return DATA?.languages ?? [];
}

export function frameworks(): Item[] {
    return DATA?.frameworks ?? [];
}

// Both browse modes feed the same detail panel, so anything that decides whether
// an id is real (or which item to render) reads this union.
export function allItems(): Item[] {
    return languages().concat(frameworks());
}

export function itemById(id: string | null): Item | undefined {
    if (!id) {
        return undefined;
    }
    return allItems().find((item) => item.id === id);
}

export function knownLang(id: string | null | undefined): boolean {
    return !!id && allItems().some((item) => item.id === id);
}

export function isFramework(id: string | null): boolean {
    return !!id && frameworks().some((item) => item.id === id);
}

export function defaultLangId(): string | null {
    const all = languages();
    return (all.find((lang) => lang.id === DEFAULT_LANG_ID) ?? all[0])?.id ?? null;
}

export function scenarios(): Scenario[] {
    return DATA?.scenarios ?? [];
}

export function knownScenario(id: string | null | undefined): boolean {
    return !!id && scenarios().some((item) => item.id === id);
}

export function scenarioLabel(id: string | null): string {
    return scenarios().find((item) => item.id === id)?.label ?? "Console output";
}

export function outputFor(id: string | null): string {
    const text = id ? DATA?.outputs?.[id] : "";
    return text || "(no capture)";
}

// Whether an item can show a given tab: only a previewable item (HTML/CSS) has a
// Play tab, and only a console language has a Console Output tab - a framework or
// HTML/CSS has no golden capture.
export function tabAvailableFor(item: Item | undefined, tab: TabId): boolean {
    if (!item) {
        return tab === "code";
    }
    if (tab === "preview") {
        return !!item.preview;
    }
    if (tab === "output") {
        return !isFramework(item.id) && !item.preview;
    }
    return true;
}

// The tab an item opens on when the address names none: a previewable item
// (HTML/CSS) opens on its live board, everything else on its code.
export function defaultTabFor(id: string | null): TabId {
    return itemById(id)?.preview ? "preview" : "code";
}

// The folder an implementation lives in, used for its GitHub link.  A framework
// sets `folder` explicitly, because its one shown file sits deep in the app while
// the link should point at the app root.
export function repoFolder(item: Item): string {
    if (item.folder) {
        return item.folder;
    }
    return (item.file || "languages/" + item.id).replace(/\/[^/]*$/, "");
}

// `<repository>/tree/<branch>/<folder>`, from the repository and branch the
// generator recorded (the git remote, else GITHUB_REPOSITORY, else its default),
// so a clone or a fork links to the right project.
export function repoUrlFor(item: Item): string {
    const repository = DATA?.meta?.repository;
    if (!repository) {
        return "";
    }
    return repository + "/tree/" + (DATA?.meta?.branch || "main") + "/" + repoFolder(item);
}

// A language's short file-extension tag (".ts", ".cs") - how the language tags and
// the Language dropdown identify it.
export function languageTag(name: string): string {
    return DATA?.languageExtensions?.[name] ?? name;
}

// The line-number column beside the code: one number per line, trimmed of the
// trailing blank lines a file ends with.
export function lineNumbersFor(text: string): string {
    const normalized = text.replace(/\n+$/, "");
    const count = normalized.length ? normalized.split("\n").length : 1;
    const numbers: number[] = [];
    for (let line = 1; line <= count; line += 1) {
        numbers.push(line);
    }
    return numbers.join("\n");
}

// Fixed reading order for the Stack facet, with the short badge (FE/BE/FS) used in
// the sidebar and the fuller label used in the dropdown.
export const STACK_ORDER = ["Frontend", "Backend", "Full stack"];

export const STACK_TAG: Record<string, string> = {
    Frontend: "FE",
    Backend: "BE",
    "Full stack": "FS",
};

export const STACK_LABEL: Record<string, string> = {
    Frontend: "Frontend (FE)",
    Backend: "Backend (BE)",
    "Full stack": "Full Stack (FS)",
};
