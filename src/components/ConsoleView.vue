<script setup lang="ts">
import { consoleCaption, outputText } from "../store/session";
</script>

<template>
    <section class="flex-1 flex flex-col min-h-0">
        <div class="flex items-center justify-between mb-2">
            <span class="micro text-fg-dim">{{ consoleCaption }}</span>
            <span class="micro text-accent/70">Byte-for-byte identical across every implementation</span>
        </div>
        <!-- The verified capture from tests/expected/, shown verbatim: no highlighting,
             so what the suite diffs is what the panel prints. -->
        <pre class="bg-console text-accent font-mono p-5 rounded-lg flex-1 min-h-0 overflow-auto text-sm border border-line/5 leading-relaxed"><code class="language-none">{{ outputText }}</code></pre>
    </section>
</template>
