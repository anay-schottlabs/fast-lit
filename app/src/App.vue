<script setup>
import { useRoute } from 'vue-router';
import { useTheme } from './composables/useTheme.js';
import Footer from './components/Footer.vue';

const route = useRoute();
const { themeMode } = useTheme();

function toggleTheme() {
    themeMode.value = themeMode.value === 'light' ? 'dark' : 'light';
}

// Shared by every sidebar nav item — a fixed-size icon tile with a tooltip
// for its label, since the sidebar is a permanent icon rail now (no
// expand/collapse). Active page gets a soft ink-tinted pill background;
// everything else is a muted ink-light that turns full ink on hover.
function navItemClass(path) {
    const isActive = route.path === path;
    return [
        "tooltip tooltip-right flex h-12 w-12 items-center justify-center rounded-2xl transition-colors duration-150 focus-ring",
        isActive
            ? "bg-ink/10 text-ink"
            : "text-ink-light hover:bg-ink/5 hover:text-ink",
    ];
}

// Same nav list, but for the mobile top bar's icon row — no tooltip
// (there's no hover on touch) and no visible label (an aria-label instead)
// since six labelled tabs don't fit one row at phone widths; icon-only is
// what keeps this a single compact row instead of needing a second one.
const mobileNavItems = [
    { path: "/", label: "Home" },
    { path: "/read", label: "Read" },
    { path: "/extension", label: "Extension" },
    { path: "/lab", label: "Lab" },
    { path: "/feedback", label: "Feedback" },
    { path: "/privacy", label: "Privacy" },
];

function mobileNavItemClass(path) {
    const isActive = route.path === path;
    return [
        "flex h-9 w-9 shrink-0 items-center justify-center rounded-xl transition-colors duration-150 focus-ring",
        isActive
            ? "bg-ink/10 text-ink"
            : "text-ink-light hover:bg-ink/5 hover:text-ink",
    ];
}
</script>

<template>
    <div class="flex min-h-screen flex-col md:flex-row">
        <!-- No overflow-y-auto here: daisyUI's tooltip pops out via
             tooltip-right, positioned outside this rail's own narrow
             width — an overflow-y value other than visible forces
             overflow-x to clip too (per the CSS spec, you can't have one
             axis auto/hidden and the other visible), which was cutting
             the tooltips off. Content fits within a normal viewport
             height without needing to scroll anyway.

             z-30 is the other half of that fix: this sticky aside and the
             main content div next to it are both un-z-indexed siblings, so
             which one paints on top of the other where they visually
             overlap (the tooltip bleeding past x=88px into the main
             content's own column) was left to default stacking order —
             inconsistent across pages depending on what stacking contexts
             their own content happens to create. An explicit z-index
             settles it outright: the sidebar (tooltips included) always
             paints above page content. -->
        <aside class="sticky top-0 z-30 box-border hidden h-screen w-[88px] shrink-0 flex-col items-center gap-1 border-r border-border bg-bg px-3 py-8 md:flex">
            <!-- logo mark -->
            <router-link
                to="/"
                class="tooltip tooltip-right mb-6 flex items-center justify-center rounded-xl p-2 focus-ring"
                data-tip="Orbit"
            >
                <div class="flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full border-[3px] border-ink/35">
                    <div class="h-[9px] w-[9px] rounded-full bg-ink"></div>
                </div>
            </router-link>

            <!-- theme toggle -->
            <button
                type="button"
                @click="toggleTheme"
                class="tooltip tooltip-right mb-2 flex h-12 w-12 items-center justify-center rounded-2xl text-ink-light transition-colors duration-150 hover:bg-ink/5 hover:text-ink focus-ring"
                data-tip="Swap theme"
            >
                <!-- sun: shown in light mode (click to go dark) -->
                <svg v-if="themeMode === 'light'" width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                    <circle cx="12" cy="12" r="5" />
                    <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" />
                </svg>
                <!-- moon: shown in dark mode (click to go light) -->
                <svg v-else width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                    <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z" />
                </svg>
            </button>
            <div class="mb-2 w-8 border-t border-border"></div>

            <nav class="flex w-full flex-col items-center gap-1">
                <router-link to="/" :class="navItemClass('/')" data-tip="Home">
                    <svg width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <path d="M3 11l9-7 9 7" /><path d="M5 10v9a1 1 0 001 1h4v-6h4v6h4a1 1 0 001-1v-9" />
                    </svg>
                </router-link>
                <router-link to="/read" :class="navItemClass('/read')" data-tip="Read">
                    <svg width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" class="shrink-0">
                        <path d="M2 6h20" /><path d="M2 12h20" /><path d="M2 18h14" />
                    </svg>
                </router-link>
                <router-link to="/extension" :class="navItemClass('/extension')" data-tip="Extension">
                    <svg width="19" height="21" viewBox="0 0 22 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <rect x="2" y="4" width="18" height="18" rx="3" /><path d="M8 2h6a1 1 0 011 1v2H7V3a1 1 0 011-1z" />
                    </svg>
                </router-link>
                <router-link to="/lab" :class="navItemClass('/lab')" data-tip="Lab">
                    <!-- The flask path itself is symmetric around x=12, not
                         x=10 — the old "0 0 20 24" viewBox framed it off-
                         center, shifting the whole icon right within its
                         button. Shifting the viewBox's own origin to
                         "2 0 20 24" (same width, just re-centered on the
                         shape) fixes it without touching the path. -->
                    <svg width="19" height="21" viewBox="2 0 20 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <path d="M9 3h6" /><path d="M10 3v6l-6 10a2 2 0 002 3h12a2 2 0 002-3l-6-10V3" /><path d="M7.5 14h9" />
                    </svg>
                </router-link>
                <router-link to="/feedback" :class="navItemClass('/feedback')" data-tip="Feedback">
                    <svg width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <path d="M14 9V5a3 3 0 00-3-3l-4 9v11h11.28a2 2 0 002-1.7l1.38-9a2 2 0 00-2-2.3H14z" /><path d="M7 22H4a2 2 0 01-2-2v-7a2 2 0 012-2h3" />
                    </svg>
                </router-link>
                <router-link to="/privacy" :class="navItemClass('/privacy')" data-tip="Privacy">
                    <svg width="21" height="21" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V7a4 4 0 018 0v4" />
                    </svg>
                </router-link>
            </nav>
        </aside>

        <!-- mobile top bar: logo, the full nav as a row of icon-only
             buttons (aria-labelled, no visible text — that's what keeps six
             items in one row instead of needing a second one), and the
             theme toggle. Replaces the desktop sidebar entirely — no
             separate bottom bar, so pages get their full height back and
             there's only ever one piece of nav chrome on screen. -->
        <header class="sticky top-0 z-30 flex items-center gap-1 border-b border-border bg-bg px-2 py-2 md:hidden">
            <router-link to="/" class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl focus-ring" aria-label="Orbit home">
                <div class="flex h-[20px] w-[20px] shrink-0 items-center justify-center rounded-full border-[3px] border-ink/35">
                    <div class="h-2 w-2 rounded-full bg-ink"></div>
                </div>
            </router-link>

            <nav class="nav-scroll flex min-w-0 flex-1 items-center gap-2 overflow-x-auto px-0.5">
                <router-link
                    v-for="item in mobileNavItems"
                    :key="item.path"
                    :to="item.path"
                    :class="mobileNavItemClass(item.path)"
                    :aria-label="item.label"
                >
                    <svg v-if="item.path === '/'" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <path d="M3 11l9-7 9 7" /><path d="M5 10v9a1 1 0 001 1h4v-6h4v6h4a1 1 0 001-1v-9" />
                    </svg>
                    <svg v-else-if="item.path === '/read'" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" class="shrink-0">
                        <path d="M2 6h20" /><path d="M2 12h20" /><path d="M2 18h14" />
                    </svg>
                    <svg v-else-if="item.path === '/extension'" width="16" height="18" viewBox="0 0 22 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <rect x="2" y="4" width="18" height="18" rx="3" /><path d="M8 2h6a1 1 0 011 1v2H7V3a1 1 0 011-1z" />
                    </svg>
                    <svg v-else-if="item.path === '/lab'" width="16" height="18" viewBox="2 0 20 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <path d="M9 3h6" /><path d="M10 3v6l-6 10a2 2 0 002 3h12a2 2 0 002-3l-6-10V3" /><path d="M7.5 14h9" />
                    </svg>
                    <svg v-else-if="item.path === '/feedback'" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <path d="M14 9V5a3 3 0 00-3-3l-4 9v11h11.28a2 2 0 002-1.7l1.38-9a2 2 0 00-2-2.3H14z" /><path d="M7 22H4a2 2 0 01-2-2v-7a2 2 0 012-2h3" />
                    </svg>
                    <svg v-else width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                        <rect x="5" y="11" width="14" height="9" rx="2" /><path d="M8 11V7a4 4 0 018 0v4" />
                    </svg>
                </router-link>
            </nav>

            <button
                type="button"
                @click="toggleTheme"
                class="flex h-9 w-9 shrink-0 items-center justify-center rounded-xl text-ink-light transition-colors duration-150 hover:bg-ink/5 hover:text-ink focus-ring"
                aria-label="Swap theme"
            >
                <svg v-if="themeMode === 'light'" width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                    <circle cx="12" cy="12" r="5" />
                    <path d="M12 1v2M12 21v2M4.22 4.22l1.42 1.42M18.36 18.36l1.42 1.42M1 12h2M21 12h2M4.22 19.78l1.42-1.42M18.36 5.64l1.42-1.42" />
                </svg>
                <svg v-else width="17" height="17" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="shrink-0">
                    <path d="M21 12.79A9 9 0 1111.21 3 7 7 0 0021 12.79z" />
                </svg>
            </button>
        </header>

        <!-- min-h-screen moved to the root wrapper above (not repeated here)
             — this div relies on that root's flex stretch for its height
             instead of separately forcing its own 100vh. Doubling it up
             here on mobile (header sits above this div, both under the same
             flex-col root) meant total page height was always at least
             100vh + the header's own height, guaranteeing a several-pixel
             vertical scrollbar on every mobile page regardless of content. -->
        <div class="flex min-w-0 flex-1 flex-col">
            <main class="flex-1">
                <router-view></router-view>
            </main>
            <!-- The read page is a focused, app-like reading screen — no
                 footer, so its controls always fit one viewport without
                 scrolling instead of competing with the footer for space. -->
            <Footer v-if="route.path !== '/read'" />
        </div>
    </div>
</template>

<style scoped>
/* The mobile header's icon row scrolls horizontally instead of squeezing
   items to fit — hide the scrollbar itself (still fully scrollable via
   touch/trackpad) so it reads as a clean icon row, not a visible scroll
   widget. */
.nav-scroll {
    scrollbar-width: none;
    -ms-overflow-style: none;
}

.nav-scroll::-webkit-scrollbar {
    display: none;
}
</style>
