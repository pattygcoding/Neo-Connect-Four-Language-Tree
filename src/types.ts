// The shape of `public/dashboard-data.js`, which tools/generate_dashboard.py writes
// from the real repository.  A language and a framework share one shape - a
// framework only adds the extra fields the Frameworks facets and its banner need -
// so every renderer can stay unaware of which list an item came from.

export type TabId = "code" | "preview" | "output";

export type ModeId = "languages" | "frameworks";

export interface Scenario {
    id: string;
    label: string;
}

// A named placeholder in an item's `note` (the `{name}` form other than `{link}`).
export interface NoteLink {
    text: string;
    href: string;
}

export interface Item {
    id: string;
    name: string;
    category: string;
    /** The Prism grammar class, e.g. `language-ada`. */
    prism: string;
    /** The source path shown above the code and linked on GitHub. */
    file: string;
    code: string;
    /** Frameworks: the folder to link on GitHub, since only one file is shown. */
    folder?: string;
    /** The sentence above the code; `{link}` becomes the whole-project anchor. */
    note?: string;
    linkText?: string;
    noteLinks?: Record<string, NoteLink>;
    /** Browser-only implementations: the page the Play tab runs in an iframe. */
    preview?: string;
    interactive?: boolean;
    /** Frameworks: Frontend / Backend / Full stack. */
    stack?: string;
    /** Frameworks: the languages the app is written in. */
    languages?: string[];
}

export interface DataMeta {
    updated: string;
    languageCount: number;
    frameworkCount: number;
    scenarioCount: number;
    repository: string;
    branch: string;
}

export interface DashboardData {
    meta: DataMeta;
    scenarios: Scenario[];
    /** scenario id -> the verified capture in tests/expected/. */
    outputs: Record<string, string>;
    languages: Item[];
    frameworks: Item[];
    /** language name -> its file-extension tag (".ts", ".cs", ...). */
    languageExtensions: Record<string, string>;
}

declare global {
    interface Window {
        /** Installed by public/dashboard-data.js, before the app module runs. */
        CONNECT_FOUR_DATA?: DashboardData;
    }
}
