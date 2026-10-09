<script setup lang="ts">
import { computed } from "vue";
import { categoryOptions, facetsApply, metaLine, searchPlaceholder, setFacet, setMode, setQuery, stackOptions, state } from "../store/session";
import { languageOptions } from "../store/session";
import FacetDropdown from "./FacetDropdown.vue";
import ItemList from "./ItemList.vue";

// The two browse modes the header's pill switches between.
const MODES = ["languages", "frameworks"] as const;

// The sidebar is a slide-in drawer below `lg` (toggled by the header's menu button)
// and a plain static column above it.  The `-translate-x-full` class is the closed
// state; `lg:translate-x-0` keeps it on screen there.
const drawerClass = computed<string>(() =>
    state.sidebarOpen ? "translate-x-0" : "-translate-x-full",
);
</script>

<template>
    <aside id="sidebar"
           :class="['fixed inset-y-0 left-0 z-40 w-80 max-w-[85vw] bg-ink-900 border-r border-line/5 flex flex-col shrink-0 transition-transform duration-200 ease-out lg:static lg:z-auto lg:translate-x-0 lg:bg-ink-900/70',
                    drawerClass]">
        <div class="p-5 border-b border-line/5">
            <div class="flex items-center gap-2.5">
                <a href="https://pattygcoding.com" target="_blank" rel="noopener" title="pattygcoding.com"
                   aria-label="Back to pattygcoding.com"
                   class="flex items-center justify-center w-8 h-8 rounded-md bg-ink-950 border border-line/10 text-fg-muted hover:text-accent hover:border-accent/40 transition">
                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m3 9 9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z" /><polyline points="9 22 9 12 15 12 15 22" /></svg>
                </a>
                <p class="micro text-fg-dim">CF / Language Tree</p>
            </div>
            <h1 class="mt-3 text-2xl font-semibold tracking-tight text-fg-strong">Connect <span class="text-accent">Four</span></h1>
            <p class="mt-1 text-xs text-fg-muted">Multi-language implementation library</p>
            <p class="micro mt-3 text-accent/80 whitespace-pre-line">{{ metaLine }}</p>
            <!-- Browse mode: languages are the shipped implementations, frameworks are
                 the multi-file apps beside them.  The list swaps between the two
                 without touching the address, which only ever names an item. -->
            <div role="tablist" aria-label="Browse languages or frameworks"
                 class="flex gap-1 mt-4 p-1 rounded-full bg-ink-950 border border-line/10">
                <button v-for="mode in MODES" :key="mode" type="button" role="tab"
                        :aria-selected="state.mode === mode" @click="setMode(mode)"
                        :class="['flex-1 micro px-3 py-1.5 rounded-full transition',
                                 state.mode === mode ? 'bg-mint-400 text-on-accent' : 'text-fg-muted hover:text-fg']">
                    {{ mode === "languages" ? "Languages" : "Frameworks" }}
                </button>
            </div>
        </div>
        <div class="p-3 border-b border-line/5 space-y-2">
            <input type="search" :placeholder="searchPlaceholder" :value="state.query"
                   @input="setQuery(($event.target as HTMLInputElement).value)"
                   class="w-full bg-ink-950 border border-line/10 rounded-md px-3 py-2 text-sm text-fg
                          placeholder-hint focus:outline-none focus:border-accent/60 focus:ring-1 focus:ring-accent/20 transition" />
            <div class="flex items-center gap-2">
                <p class="micro text-fg-dim shrink-0 w-[4.75rem]">Category</p>
                <FacetDropdown id="category" :options="categoryOptions" @pick="setFacet('category', $event)" />
            </div>
            <!-- Stack and Language only describe a framework tree, so they appear only
                 in Frameworks mode (a language has no stack of its own). -->
            <div v-if="facetsApply" class="flex items-center gap-2">
                <p class="micro text-fg-dim shrink-0 w-[4.75rem]">Stack</p>
                <FacetDropdown id="stack" :options="stackOptions" @pick="setFacet('stack', $event)" />
            </div>
            <div v-if="facetsApply" class="flex items-center gap-2">
                <p class="micro text-fg-dim shrink-0 w-[4.75rem]">Language</p>
                <FacetDropdown id="language" :options="languageOptions" @pick="setFacet('language', $event)" />
            </div>
        </div>
        <ItemList />
    </aside>
</template>
