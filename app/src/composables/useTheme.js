import { ref, watch } from 'vue';

const THEME_STORAGE_KEY = 'orbit:themeMode';

function loadStoredTheme() {
    try {
        const stored = localStorage.getItem(THEME_STORAGE_KEY);
        return stored === 'light' || stored === 'dark' ? stored : 'light';
    } catch {
        return 'light';
    }
}

// Module-level (not created per-call) so every component sharing this
// composable reads/writes the exact same ref — the standard "global
// composable" pattern for app-wide state like a theme.
const themeMode = ref(loadStoredTheme());

watch(
    themeMode,
    (mode) => {
        document.documentElement.setAttribute('data-theme', mode);
        try {
            localStorage.setItem(THEME_STORAGE_KEY, mode);
        } catch {
            // localStorage unavailable (private browsing, etc.) — theme just
            // won't persist across reloads, no need to surface an error
        }
    },
    { immediate: true }
);

export function useTheme() {
    return { themeMode };
}
