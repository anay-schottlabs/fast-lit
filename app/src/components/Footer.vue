<script setup>
// No props — rendered identically on every page (see App.vue), so the
// same nav links show up everywhere instead of varying page to page.
</script>

<template>
    <footer class="border-t border-border px-8 py-10">
        <!-- Stacked and centered on mobile (logo, then links, then
             copyright) — the standard small-site footer layout, since the
             previous single flex-wrap row (logo/links/copyright as three
             items justify-between) let the links block wrap on its own
             mid-row instead of the whole footer reflowing as a unit. Reverts
             to the original wide row on md+. -->
        <div class="mx-auto flex max-w-[1180px] flex-col items-center gap-6 text-center md:flex-row md:flex-wrap md:items-center md:justify-between md:gap-5 md:text-left">
            <div class="flex items-center gap-2.5">
                <div class="flex h-[22px] w-[22px] shrink-0 items-center justify-center rounded-full border-[3px] border-ink/35">
                    <div class="h-[9px] w-[9px] rounded-full bg-ink"></div>
                </div>
                <span class="font-display text-[17px] font-bold text-ink">Orbit</span>
            </div>

            <div class="flex flex-wrap justify-center gap-x-6 gap-y-2 md:justify-start md:gap-7">
                <router-link to="/" class="text-sm font-semibold text-ink-light hover:text-ink">Home</router-link>
                <router-link to="/read" class="text-sm font-semibold text-ink-light hover:text-ink">Read</router-link>
                <router-link to="/extension" class="text-sm font-semibold text-ink-light hover:text-ink">Extension</router-link>
                <router-link to="/lab" class="text-sm font-semibold text-ink-light hover:text-ink">Lab</router-link>
                <router-link to="/feedback" class="text-sm font-semibold text-ink-light hover:text-ink">Feedback</router-link>
                <router-link to="/privacy" class="text-sm font-semibold text-ink-light hover:text-ink">Privacy</router-link>
            </div>

            <span class="text-[13px] font-medium text-ink-light">&copy; 2026 Orbit</span>
        </div>
    </footer>
</template>

<style scoped></style>
