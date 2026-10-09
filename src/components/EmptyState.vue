<script setup lang="ts">
// Shown when public/dashboard-data.js is missing (a fresh clone whose generator has
// not run yet, or a build that skipped it): the app is still usable, and this says
// which command produces the data.
</script>

<template>
    <div class="flex-1 flex items-center justify-center text-center">
        <div>
            <p class="text-lg mb-2 text-fg-soft">No dashboard data found.</p>
            <p class="text-sm text-fg-muted">Run <code class="text-accent">npm run data</code> to build
                <code class="text-accent">public/dashboard-data.js</code>.</p>
        </div>
    </div>
</template>
