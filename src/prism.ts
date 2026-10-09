// Prism highlights the ~45 languages on demand: the bundle ships no grammar at all,
// and the autoloader fetches one from the same CDN copy the page links (`data-manual`
// stops it from scanning the document on load).
//
// The markup is produced as a *string* and rendered with v-html rather than letting
// Prism rewrite an element in place: Vue owns the DOM here, and an element Prism had
// re-rendered behind Vue's back would be overwritten by the next patch.
interface PrismAutoloader {
    languages_path: string;
    loadLanguages(languages: string[], success?: () => void, error?: () => void): void;
}

interface PrismGlobal {
    languages: Record<string, unknown>;
    highlight(code: string, grammar: unknown, language: string): string;
    plugins?: { autoloader?: PrismAutoloader };
}

declare global {
    interface Window {
        /** The CDN copy index.html loads, if it loaded. */
        Prism?: PrismGlobal;
    }
}

export function configurePrism(): void {
    const autoloader = window.Prism?.plugins?.autoloader;
    if (autoloader) {
        autoloader.languages_path = "https://cdnjs.cloudflare.com/ajax/libs/prism/1.29.0/components/";
    }
}

// Resolve to highlighted markup for `code`.  A grammar that Prism does not know
// (the `language-none` used for the console capture, or a language whose component
// the CDN lacks) leaves the code as escaped plain text, exactly as before.
export async function highlightCode(code: string, prismClass: string): Promise<string> {
    const prism = window.Prism;
    if (!prism) {
        return escapeHtml(code);
    }
    const language = prismClass.replace(/^language-/, "");
    let grammar = prism.languages[language];
    if (!grammar && prism.plugins?.autoloader) {
        grammar = await new Promise<unknown>((resolve) => {
            prism.plugins!.autoloader!.loadLanguages(
                [language],
                () => resolve(prism.languages[language]),
                () => resolve(undefined),
            );
        });
    }
    return grammar ? prism.highlight(code, grammar, language) : escapeHtml(code);
}

function escapeHtml(text: string): string {
    return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
}
