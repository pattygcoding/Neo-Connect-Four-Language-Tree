<script setup lang="ts">
import { computed } from "vue";
import { state, toggleMenu } from "../store/session";

// A custom dropdown rather than a native <select>: the OS draws a select's popup, so
// its height cannot be capped and the 90-odd frameworks would run off the screen.
// This is a button with a height-capped, scrollable menu instead (.menu-scroll).
// `id` doubles as the state key, so the panel knows which value it is showing.
const props = defineProps<{
    id: "category" | "stack" | "language";
    options: { value: string; label: string }[];
}>();

const emit = defineEmits<{ pick: [value: string] }>();

const open = computed<boolean>(() => state.openMenu === props.id);

// The value stays the stable key `activeItems` compares on; the label is what the
// button echoes back.
const current = computed<string>(() => state[props.id]);

const currentLabel = computed<string>(() =>
    props.options.find((option) => option.value === current.value)?.label ?? props.options[0]?.label ?? "",
);

function pick(value: string): void {
    state.openMenu = null;
    emit("pick", value);
}
</script>

<template>
    <div class="relative flex-1 min-w-0">
        <button type="button" aria-haspopup="listbox" :aria-expanded="open" @click.stop="toggleMenu(id)"
                class="w-full flex items-center justify-between gap-2 micro bg-ink-950 border border-line/10 rounded-md px-2 py-1.5 text-fg-soft hover:border-line/20 focus:outline-none focus:border-accent/60 transition">
            <span class="truncate">{{ currentLabel }}</span>
            <svg class="shrink-0 opacity-60" xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="m6 9 6 6 6-6" /></svg>
        </button>
        <div role="listbox" @click.stop
             :class="['absolute left-0 right-0 z-50 mt-1 py-1 max-h-56 overflow-y-auto menu-scroll rounded-md bg-ink-900 border border-line/10 shadow-xl',
                      open ? '' : 'hidden']">
            <button v-for="option in options" :key="option.value" type="button" role="option"
                    :aria-selected="option.value === current"
                    :class="['w-full flex items-center gap-2 text-left px-2.5 py-1.5 micro transition',
                             option.value === current ? 'text-accent bg-accent/10' : 'text-fg-soft hover:bg-line/5']"
                    @click="pick(option.value)">{{ option.label }}</button>
        </div>
    </div>
</template>
