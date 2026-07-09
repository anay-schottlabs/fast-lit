<script setup>
import { useRoute, useRouter } from 'vue-router';
import { ChangelogScripts } from './assets/textScripts';

const changelog = ChangelogScripts.changelog;
const newestEntry = changelog[changelog.length - 1];
const currentVersion = newestEntry.version;

// Use one consistent SVG size for all main nav icons. The collapse toggle
// intentionally uses a smaller size — it's a secondary control, not a nav
// destination, and shouldn't compete with Home/Read/Feedback/Changelog.
const svgSize = '2rem';
const toggleSvgSize = '1.375rem';

const route = useRoute();
const router = useRouter();

function navigateTo(path) {
    router.push(path);
}

// Shared by every sidebar nav item (and the collapse toggle) so button
// height/padding/spacing is identical whether the sidebar is expanded or
// collapsed to an icon rail — only the container width changes, never the
// button's own box model. is-drawer-close:tooltip wires the button into
// daisyUI's tooltip off the sidebar checkbox's state; it only renders once
// paired with a data-tip attribute below.
const navBaseClass = "is-drawer-close:tooltip is-drawer-close:tooltip-right is-drawer-close:justify-center flex w-full items-center gap-3 rounded-xl px-3 py-3 transition-colors duration-150 focus-ring cursor-pointer";

// Active page gets a soft red pill background; everything else is a muted
// white that brightens on hover. Icons carry no color classes of their own
// — they inherit through currentColor from whichever of these wins, so the
// icon and label always recolor together. Forced !important because
// style.css's unlayered "button { color: white }" rule otherwise beats
// these (layered) utility classes regardless of specificity.
function navItemClass(path) {
    const isActive = route.path === path;
    return [
        navBaseClass,
        isActive
            ? "bg-red/10 !text-red"
            : "!text-white/70 hover:bg-white/10 hover:!text-white",
    ];
}
</script>

<template>
    <div class="drawer lg:drawer-open">
        <input id="sidebar-drawer-toggle" type="checkbox" class="drawer-toggle" />
        <div class="drawer-content">
            <!-- Page content here -->
            <div class="p-4">
                <router-view></router-view>
            </div>
        </div>

        <div
            class="min-h-screen drawer-side is-drawer-close:w-18 is-drawer-open:w-64"
        ></div>

        <div class="drawer-side is-drawer-close:overflow-visible fixed">
            <div
                class="flex min-h-full flex-col border-r border-white/10 bg-white/5 is-drawer-close:w-18 is-drawer-open:w-64 transition-[width] duration-200 ease-out"
            >
                <!-- Sidebar content here -->
                <!-- Collapse/expand control — deliberately kept OUTSIDE the
                     nav <ul> below (its own row, plus a divider) so it reads
                     as menu chrome rather than another destination in the
                     list, even though it shares the nav items' hover/focus
                     language. -->
                <div class="w-full px-2 pt-3 pb-2">
                    <label
                        for="sidebar-drawer-toggle"
                        class="is-drawer-close:tooltip is-drawer-close:tooltip-right is-drawer-close:justify-center flex w-full cursor-pointer items-center gap-3 rounded-xl px-3 py-2 !text-white/40 transition-colors duration-150 hover:bg-white/5 hover:!text-white/70 focus-ring"
                        data-tip="Toggle sidebar"
                    >
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            :style="{ width: toggleSvgSize, height: toggleSvgSize }"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="shrink-0 is-drawer-open:rotate-180 transition-transform duration-200"
                        >
                            <polyline points="9 6 15 12 9 18" />
                        </svg>
                        <span class="is-drawer-close:hidden whitespace-nowrap text-sm">Collapse</span>
                    </label>
                </div>
                <div class="mx-4 border-t border-white/10"></div>

                <ul class="flex w-full grow flex-col gap-1 px-2 pt-2 pb-3">
                    <!-- button to navigate to the home page -->
                    <li>
                        <button
                            :class="navItemClass('/')"
                            @click="navigateTo('/')"
                            data-tip="Home"
                        >
                            <!-- Home icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="1.75"
                                fill="none"
                                stroke="currentColor"
                                class="shrink-0"
                                :style="{ width: svgSize, height: svgSize }"
                            >
                                <path d="M4 11.5 12 4l8 7.5" />
                                <path d="M6 10.5V19a1 1 0 0 0 1 1h10a1 1 0 0 0 1-1v-8.5" />
                                <path d="M10 20v-5a1 1 0 0 1 1-1h2a1 1 0 0 1 1 1v5" />
                            </svg>
                            <span class="is-drawer-close:hidden whitespace-nowrap text-xl">Home</span>
                        </button>
                    </li>

                    <!-- button to navigate to the read page -->
                    <li>
                        <button
                            :class="navItemClass('/read')"
                            @click="navigateTo('/read')"
                            data-tip="Read"
                        >
                            <!-- Read icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.75"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                class="shrink-0"
                                :style="{ width: svgSize, height: svgSize }"
                            >
                                <path d="M12 7c-1.6-1.3-3.7-2-6-2v13c2.3 0 4.4.7 6 2" />
                                <path d="M12 7c1.6-1.3 3.7-2 6-2v13c-2.3 0-4.4.7-6 2" />
                                <path d="M12 7v13" />
                            </svg>
                            <span class="is-drawer-close:hidden whitespace-nowrap text-xl">Read</span>
                        </button>
                    </li>

                    <!-- button to navigate to the write page -->
                    <li>
                        <button
                            :class="navItemClass('/write')"
                            @click="navigateTo('/write')"
                            data-tip="Write"
                        >
                            <!-- Write icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.75"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                class="shrink-0"
                                :style="{ width: svgSize, height: svgSize }"
                            >
                                <path d="M4 20l.8-3.6L15.5 5.7a1.5 1.5 0 0 1 2.1 0l.7.7a1.5 1.5 0 0 1 0 2.1L7.6 19.2 4 20Z" />
                                <path d="M14 7.5l2.5 2.5" />
                            </svg>
                            <span class="is-drawer-close:hidden whitespace-nowrap text-xl">Write</span>
                        </button>
                    </li>

                    <!-- button to navigate to the feedback page -->
                    <li>
                        <button
                            :class="navItemClass('/feedback')"
                            @click="navigateTo('/feedback')"
                            data-tip="Feedback"
                        >
                            <!-- Feedback icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="1.75"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                class="shrink-0"
                                :style="{ width: svgSize, height: svgSize }"
                            >
                                <path d="M14 9V5a3 3 0 0 0-3-3l-4 9v11h11.28a2 2 0 0 0 2-1.7l1.38-9a2 2 0 0 0-2-2.3z" />
                                <path d="M7 22H4a2 2 0 0 1-2-2v-7a2 2 0 0 1 2-2h3" />
                            </svg>
                            <span class="is-drawer-close:hidden whitespace-nowrap text-xl">Feedback</span>
                        </button>
                    </li>

                    <!-- button to navigate to the changelog page -->
                    <li>
                        <button
                            :class="navItemClass('/changelog')"
                            @click="navigateTo('/changelog')"
                            data-tip="Changelog"
                        >
                            <!-- Changelog icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="1.75"
                                fill="none"
                                stroke="currentColor"
                                :style="{ width: svgSize, height: svgSize }"
                                class="shrink-0"
                            >
                                <path d="M20 7h-9" />
                                <path d="M14 17H5" />
                                <circle cx="17" cy="17" r="3" />
                                <circle cx="7" cy="7" r="3" />
                            </svg>
                            <span class="is-drawer-close:hidden whitespace-nowrap text-xl">Changelog</span>
                        </button>
                    </li>
                </ul>

                <!-- current version, linked to changelog page — pinned to
                     the bottom of the sidebar via mt-auto rather than
                     position:fixed, so it stays part of normal flex flow
                     and can never overlap nav items on short viewports.
                     Hidden (not just its text) while collapsed, since the
                     button alone had no icon and rendered as a tiny blank
                     hit target. -->
                <div class="is-drawer-close:hidden mt-auto w-full px-2 pb-3">
                    <button
                        :class="[navBaseClass, 'justify-center border border-red/30 bg-red/10 hover:bg-red/20 !text-red-light']"
                        @click="navigateTo('/changelog')"
                    >
                        <span class="font-mono text-lg font-bold">v{{ currentVersion }}</span>
                    </button>
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
