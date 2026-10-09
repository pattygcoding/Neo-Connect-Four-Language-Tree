<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { highlightCode } from "../prism";
import { lineNumbersFor } from "../store/data";
import { currentItem, noteSegments } from "../store/session";

// The highlighted markup of the selected file (rendered with v-html) and the state
// of the copy button.
const highlighted = ref("");
const copied = ref(false);
let copyTimer: number | undefined;

// Prism loads a grammar on demand, so highlighting is async: a fast selection change
// must not let an older highlight land on the newer file.
let highlightRun = 0;

watch(
    () => currentItem.value,
    async (item) => {
        highlightRun += 1;
        const run = highlightRun;
        const html = await highlightCode(item?.code ?? "", item?.prism ?? "language-clike");
        if (run === highlightRun) {
            highlighted.value = html;
        }
    },
    { immediate: true },
);

// The gutter must line up with Prism's output, so it is derived from the same code
// the panel is showing.
const lineNumbers = computed<string>(() => lineNumbersFor(currentItem.value?.code ?? ""));

async function copyCode(): Promise<void> {
    const text = currentItem.value?.code ?? "";
    if (!navigator.clipboard?.writeText) {
        return;
    }
    try {
        await navigator.clipboard.writeText(text);
    } catch {
        return;   // refused (insecure context or permissions): leave the icon alone
    }
    copied.value = true;
    window.clearTimeout(copyTimer);
    copyTimer = window.setTimeout(() => { copied.value = false; }, 1200);
}
</script>

<template>
    <section class="flex-1 flex flex-col min-h-0">
        <div class="flex items-center justify-between mb-2">
            <span class="micro text-fg-dim">{{ currentItem?.file ?? "Source code" }}</span>
        </div>
        <!-- A framework is many files: this says the panel shows one of them and links
             the whole project.  Absent for a language. -->
        <p v-if="noteSegments.length" class="mb-3 text-xs leading-relaxed text-fg-muted">
            <template v-for="(segment, index) in noteSegments" :key="index">
                <a v-if="segment.href" :href="segment.href" target="_blank" rel="noopener"
                   class="text-accent hover:underline">{{ segment.text }}</a>
                <template v-else>{{ segment.text }}</template>
            </template>
        </p>
        <div class="relative flex-1 min-h-0">
            <button type="button" @click="copyCode()" title="Copy source code" aria-label="Copy source code"
                    :class="['absolute top-3 right-5 z-10 flex items-center justify-center w-8 h-8 rounded-md bg-ink-900/80 border border-line/10 backdrop-blur transition',
                             copied ? 'text-accent' : 'text-fg-muted hover:text-accent hover:border-accent/40']">
                <svg v-if="copied" xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6 9 17l-5-5" /></svg>
                <svg v-else xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><rect width="14" height="14" x="8" y="8" rx="2" ry="2" /><path d="M4 16c-1.1 0-2-.9-2-2V4c0-1.1.9-2 2-2h10c1.1 0 2 .9 2 2" /></svg>
            </button>
            <div class="h-full rounded-lg overflow-auto bg-ink-850 border border-line/5 font-mono text-[13px] leading-relaxed">
                <div class="flex min-w-full min-h-full">
                    <pre class="m-0 pt-2 pb-5 pl-4 pr-3 text-right text-[13px] leading-relaxed text-gutter select-none whitespace-pre shrink-0 sticky left-0 bg-ink-850 border-r border-line/5">{{ lineNumbers }}</pre>
                    <pre class="cf-code m-0 flex-1 text-[13px] leading-relaxed outline-none"><code v-html="highlighted" :class="[currentItem?.prism ?? 'language-clike', 'whitespace-pre']"></code></pre>
                </div>
            </div>
        </div>
    </section>
</template>
