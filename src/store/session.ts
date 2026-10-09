import { computed, reactive } from "vue";
import type { Item, ModeId, TabId } from "../types";
import * as data from "./data";

export type MenuId = "category" | "stack" | "language";

export interface FacetOption {
    value: string;
    label: string;
}

export interface NoteSegment {
    text: string;
    href?: string;
}

// ---- The address ----------------------------------------------------------------
// Every implementation is addressable on its own path: /ada, /c, /objectivec.  The
// dashboard is a static bundle, so the path is resolved client-side with the
// History API.  A document with a null origin (file://) refuses path writes, so the
// query-string shape (?lang=ada) is used there instead - and that query shape is
// also what the deployed site's 404.html shim forwards, so `?lang=`, `?tab=` and
// `?scenario=` stay readable in both forms and older links keep working.
const APP_DIR = window.location.pathname.replace(/[^/]*$/, "");
let applyingHistory = false;

// Can this document write a path?  Probing once here, rather than discovering it
// when the first write fails, keeps the sidebar's hrefs in the right shape from the
// very first render; the temporary URL is restored in the same tick, before
// anything can observe it.
let canWritePath = (function probePathWrites(): boolean {
    const original = window.location.href;
    try {
        window.history.replaceState(window.history.state, "", APP_DIR + "__path-probe__");
    } catch {
        return false;
    }
    try {
        window.history.replaceState(window.history.state, "", original);
    } catch {
        // keep going: the probe already told us path writes are allowed
    }
    return true;
})();

interface LocationState {
    langId: string | null;
    tab: TabId;
    scenarioId: string | null;
    explicit: boolean;
}

// What the current address asks for, in either shape.
function locationState(): LocationState {
    const tail = window.location.pathname.slice(APP_DIR.length).replace(/\/+$/, "");
    const parts = tail ? tail.split("/") : [];
    const pathTab = parts.length === 2 && /^(code|output|preview)$/.test(parts[1]) ? parts[1] : "";
    const params = new URLSearchParams(window.location.search || "");
    const langId = data.knownLang(parts[0]) ? parts[0] : params.get("lang");
    const rawTab = pathTab || params.get("tab");
    return {
        langId: data.knownLang(langId) ? langId : null,
        tab: rawTab === "output" || rawTab === "preview" ? rawTab : "code",
        scenarioId: params.get("scenario"),
        explicit: !!(pathTab || params.get("tab")),
    };
}

// The address for what is on screen, in whichever shape the browser accepts.  Used
// for the sidebar's real links too, so a copied or middle-clicked link carries the
// current tab (and scenario) along with the implementation.
export function stateUrl(langId: string, tab: TabId, scenarioId: string | null): string {
    const params = new URLSearchParams();
    if (!canWritePath) {
        params.set("lang", langId);
    }
    // Addresses stay clean: name a tab only when the item can show it and it is not
    // the tab the item opens on anyway, so a plain /htmlcss opens the live board and
    // a plain /csharp opens the code.
    if (!data.tabAvailableFor(data.itemById(langId), tab)) {
        tab = "code";
    }
    if (tab !== data.defaultTabFor(langId)) {
        params.set("tab", tab);
        if (tab === "output" && scenarioId) {
            params.set("scenario", scenarioId);
        }
    }
    const search = params.toString();
    const path = canWritePath ? APP_DIR + langId : window.location.pathname;
    return path + (search ? "?" + search : "");
}

function syncUrl(mode: "push" | "replace"): void {
    if (applyingHistory || !state.langId) {
        return;
    }
    const url = stateUrl(state.langId, state.tab, state.scenarioId);
    try {
        window.history[mode === "push" ? "pushState" : "replaceState"](null, "", url);
    } catch {
        // Belt and braces: keep the query shape such a document allows.
        canWritePath = false;
        syncUrl(mode);
    }
}

// Back/forward: rebuild the view from the address without writing it again.
function applyLocation(): void {
    const target = locationState();
    applyingHistory = true;
    if (target.langId && target.langId !== state.langId) {
        state.langId = target.langId;
        syncMode();
    }
    applyScenario(target.scenarioId);
    switchTab(target.explicit ? target.tab : data.defaultTabFor(state.langId));
    applyingHistory = false;
}

// ---- Selection ------------------------------------------------------------------
export const state = reactive({
    langId: null as string | null,
    tab: "code" as TabId,
    scenarioId: null as string | null,
    query: "",
    category: "All",
    stack: "All",
    language: "All",
    mode: "languages" as ModeId,
    /** The mobile drawer: a slide-in sidebar below `lg`. */
    sidebarOpen: false,
    /** The one filter dropdown allowed open at a time. */
    openMenu: null as MenuId | null,
});

export const currentItem = computed<Item | undefined>(() => data.itemById(state.langId));

export const frameworkSelected = computed<boolean>(() => data.isFramework(state.langId));

export const previewable = computed<boolean>(() => !!currentItem.value?.preview);

// The extra facets (Stack, Language) only make sense for the framework tree, so in
// Languages mode they are ignored and their rows hidden.
export const facetsApply = computed<boolean>(() => state.mode === "frameworks");

// Items for the currently selected browse mode.  Both lists share one shape
// (id/name/category/prism/file/code; a framework adds folder/note/linkText,
// stack/languages), so every renderer stays unaware of the mode.
export const modeItems = computed<Item[]>(() => (facetsApply.value ? data.frameworks() : data.languages()));

export const visibleItems = computed<Item[]>(() => {
    const query = state.query.trim().toLowerCase();
    return modeItems.value.filter((item) => {
        const matchesCategory = state.category === "All" || item.category === state.category;
        const matchesStack = !facetsApply.value || state.stack === "All" || item.stack === state.stack;
        const names = item.languages ?? [];
        const matchesLanguage = !facetsApply.value || state.language === "All" || names.includes(state.language);
        const haystack = (
            item.name + " " + item.id + " " + (item.category || "") + " " +
            (item.stack || "") + " " + names.join(" ")
        ).toLowerCase();
        return matchesCategory && matchesStack && matchesLanguage && (query === "" || haystack.includes(query));
    });
});

export const listMessage = computed<string>(() => {
    if (modeItems.value.length === 0) {
        return facetsApply.value ? "No frameworks yet." : "No languages yet.";
    }
    return "No " + state.mode + " match your search.";
});

export const searchPlaceholder = computed<string>(() =>
    facetsApply.value ? "Search frameworks..." : "Search languages...",
);

export const metaLine = computed<string>(() => {
    const meta = data.DATA?.meta;
    let counts = (meta?.languageCount || data.languages().length) + " languages";
    const frameworkCount = meta?.frameworkCount || data.frameworks().length;
    if (frameworkCount) {
        counts += " \u00b7 " + frameworkCount + " framework" + (frameworkCount === 1 ? "" : "s");
    }
    return counts + " \u00b7 " + (meta?.scenarioCount || 0) + " captures\nupdated " + (meta?.updated || "n/a");
});

export const repoUrl = computed<string>(() => (currentItem.value ? data.repoUrlFor(currentItem.value) : ""));

export const repoFolderName = computed<string>(() => (currentItem.value ? data.repoFolder(currentItem.value) : ""));

// Language tags for a framework: the blue file-extension of each language it is
// written in, so opening Blazor visibly ties back to the C# language entry.
export const writtenIn = computed<string[]>(() =>
    frameworkSelected.value ? currentItem.value?.languages ?? [] : [],
);

export const showOutputTab = computed<boolean>(() => !frameworkSelected.value && !previewable.value);

export const showPreviewTab = computed<boolean>(() => previewable.value);

// The preview page lives in the repository (languages/htmlcss/), not in this app,
// so its URL is built from the directory the dashboard is served from.
export const previewSrc = computed<string>(() =>
    previewable.value && currentItem.value?.preview ? APP_DIR + currentItem.value.preview : "",
);

export const outputText = computed<string>(() => data.outputFor(state.scenarioId));

export const consoleCaption = computed<string>(() => data.scenarioLabel(state.scenarioId));

// The banner above the code: a sentence whose `{link}` placeholder becomes an
// anchor to the whole project on GitHub, and whose other `{name}` placeholders
// become anchors from `noteLinks[name]`.  An item without a `note` shows nothing.
export const noteSegments = computed<NoteSegment[]>(() => {
    const item = currentItem.value;
    const note = item?.note;
    if (!item || !note) {
        return [];
    }
    const extra = item.noteLinks ?? {};
    const url = repoUrl.value;
    const pattern = /\{(\w+)\}/g;
    const segments: NoteSegment[] = [];
    let last = 0;
    let match: RegExpExecArray | null;
    while ((match = pattern.exec(note)) !== null) {
        const target = match[1] === "link"
            ? { text: item.linkText || "the full project on GitHub", href: url || "#" }
            : extra[match[1]];
        if (!target) {
            continue;
        }
        segments.push({ text: note.slice(last, match.index) });
        segments.push({ text: target.text, href: target.href });
        last = pattern.lastIndex;
    }
    segments.push({ text: note.slice(last) });
    return segments;
});

// ---- Facets ---------------------------------------------------------------------
export const categoryOptions = computed<FacetOption[]>(() => {
    const seen: string[] = [];
    for (const item of modeItems.value) {
        if (item.category && !seen.includes(item.category)) {
            seen.push(item.category);
        }
    }
    return [{ value: "All", label: "All categories" }].concat(
        seen.map((name) => ({ value: name, label: name })),
    );
});

export const stackOptions = computed<FacetOption[]>(() => {
    const present = modeItems.value.map((item) => item.stack);
    return [{ value: "All", label: "All stacks" }].concat(
        data.STACK_ORDER
            .filter((name) => present.includes(name))
            .map((name) => ({ value: name, label: data.STACK_LABEL[name] ?? name })),
    );
});

// Languages read most-used first (so C#, JavaScript, Python, ... lead) and then
// alphabetically, with how many frameworks use each.
export const languageOptions = computed<FacetOption[]>(() => {
    const counts: Record<string, number> = {};
    for (const item of modeItems.value) {
        for (const name of item.languages ?? []) {
            counts[name] = (counts[name] ?? 0) + 1;
        }
    }
    const names = Object.keys(counts).sort((a, b) => counts[b] - counts[a] || a.localeCompare(b));
    return [{ value: "All", label: "All languages" }].concat(
        names.map((name) => ({ value: name, label: name + " (" + counts[name] + ")" })),
    );
});

// ---- Actions --------------------------------------------------------------------
export function setQuery(value: string): void {
    state.query = value;
}

export function setFacet(facet: MenuId, value: string): void {
    state[facet] = value;
}

export function setMode(mode: ModeId): void {
    if (mode === state.mode) {
        return;
    }
    state.mode = mode;
    // Switching lists resets the search and every facet, to keep the two lists
    // independent; the search box empties with `state.query`.
    state.category = "All";
    state.stack = "All";
    state.language = "All";
    state.query = "";
    // Select something from the new list so the detail panel matches it, keeping
    // the current selection only if it lives in both lists.
    const items = modeItems.value;
    if (items.some((item) => item.id === state.langId)) {
        syncUrl("push");
    } else if (items.length) {
        selectLanguage(items[0].id);
    } else {
        state.langId = null;
    }
}

// Keep the browse mode in step with the selection: opening /rubyonrails (or
// navigating back to it) must reveal the Frameworks list it belongs to.
function syncMode(): void {
    const mode: ModeId = data.isFramework(state.langId) ? "frameworks" : "languages";
    if (mode === state.mode) {
        return;
    }
    state.mode = mode;
    state.category = "All";
    state.stack = "All";
    state.language = "All";
}

export function selectLanguage(id: string): void {
    state.langId = id;
    // A tab the new item cannot show would leave an empty panel, so fall back to
    // its code before the push below writes the address.
    if (!data.tabAvailableFor(currentItem.value, state.tab)) {
        state.tab = "code";
    }
    syncUrl("push");
    state.sidebarOpen = false;
}

export function switchTab(tab: TabId): void {
    if (!data.tabAvailableFor(currentItem.value, tab)) {
        tab = "code";
    }
    const changed = state.tab !== tab;
    state.tab = tab;
    if (changed) {
        syncUrl("push");
    }
}

export function selectScenario(id: string): void {
    state.scenarioId = id;
    syncUrl("replace");
}

// The scenario belongs to the console-output address; an unknown or absent id falls
// back to the preferred capture so a bare URL still shows something.
function applyScenario(id: string | null): void {
    const all = data.scenarios();
    const preferred = all.find((item) => item.id === "horizontal_win");
    state.scenarioId = data.knownScenario(id) ? id : (preferred ?? all[0])?.id ?? null;
}

export function toggleSidebar(): void {
    state.sidebarOpen = !state.sidebarOpen;
}

export function closeSidebar(): void {
    state.sidebarOpen = false;
}

export function toggleMenu(id: MenuId): void {
    state.openMenu = state.openMenu === id ? null : id;
}

export function closeMenus(): void {
    state.openMenu = null;
}

// Mirror the address into the view; the address is only written at the end (a tab
// taken from the URL must not add a history entry).
export function initSession(): void {
    if (!data.hasData) {
        return;
    }
    const target = locationState();
    state.langId = target.langId ?? data.defaultLangId();
    syncMode();
    applyingHistory = true;
    applyScenario(target.scenarioId);
    switchTab(target.explicit ? target.tab : data.defaultTabFor(state.langId));
    applyingHistory = false;
    syncUrl("replace");   // canonical address for what is on screen

    window.addEventListener("popstate", applyLocation);
}


