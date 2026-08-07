import { ref, watch } from 'vue';

// Module-level (not created per-call) so every component sharing this
// composable reads/writes the exact same ref — the standard "global
// composable" pattern for app-wide state like a theme.
//
// No UI control reads or writes this anywhere yet — per the design handoff,
// only the internal switch needs to exist for now. Flipping it (e.g. from
// devtools: useTheme().themeMode.value = 'dark') re-themes the whole site
// immediately, since the watcher below keeps <html>'s data-theme attribute
// in sync, and style.css's :root[data-theme="dark"] block reassigns every
// color token from there.
const themeMode = ref('light');

watch(
    themeMode,
    (mode) => {
        document.documentElement.setAttribute('data-theme', mode);
    },
    { immediate: true }
);

export function useTheme() {
    return { themeMode };
}
