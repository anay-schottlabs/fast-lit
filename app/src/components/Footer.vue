<script setup>
// minimal drops the nav-links row, matching the design handoff's Read
// page footer (just logo + copyright) — used on pages meant to stay
// distraction-free rather than surfacing a full site nav at the bottom.
defineProps({
    minimal: {
        type: Boolean,
        default: false
    }
});
</script>

<template>
    <footer class="border-t border-border px-8 py-10">
        <div class="mx-auto flex max-w-[1180px] flex-wrap items-center justify-between gap-5">
            <div class="flex items-center gap-2.5">
                <div class="flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full border-[3px] border-ink/35">
                    <div class="h-[9px] w-[9px] rounded-full bg-ink"></div>
                </div>
                <span class="font-display text-[17px] font-bold text-ink">Orbit</span>
            </div>

            <div v-if="!minimal" class="flex flex-wrap gap-7">
                <router-link to="/" class="text-sm font-semibold text-ink-light hover:text-ink">Home</router-link>
                <router-link to="/read" class="text-sm font-semibold text-ink-light hover:text-ink">Read</router-link>
                <router-link to="/lab" class="text-sm font-semibold text-ink-light hover:text-ink">Lab</router-link>
                <router-link to="/privacy" class="text-sm font-semibold text-ink-light hover:text-ink">Privacy</router-link>
                <router-link to="/feedback" class="text-sm font-semibold text-ink-light hover:text-ink">Feedback</router-link>
            </div>

            <span class="text-[13px] font-medium text-ink-light">&copy; 2026 Orbit</span>
        </div>
    </footer>
</template>

<style scoped></style>
