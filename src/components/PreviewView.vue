<script setup lang="ts">
import { previewSrc } from "../store/session";
</script>

<template>
    <section class="flex-1 flex flex-col min-h-0">
        <div class="flex items-center justify-between mb-2">
            <span class="micro text-fg-dim">Live preview</span>
            <span class="micro text-accent/70">Runs in the browser - red vs. yellow</span>
        </div>
        <!-- The page itself (languages/htmlcss/connect_four.html) is not part of this
             app, so it runs in an iframe from the path the data names. -->
        <div class="flex-1 min-h-0 rounded-lg overflow-hidden bg-ink-850 border border-line/5">
            <iframe title="Connect Four live preview" class="w-full h-full bg-white" loading="lazy"
                    :src="previewSrc || undefined"></iframe>
        </div>
    </section>
</template>
