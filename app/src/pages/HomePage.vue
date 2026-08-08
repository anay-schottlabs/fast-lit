<script setup>
import { ref, computed, onMounted } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, getDocs } from "firebase/firestore";
import { useTextScripts } from '@/composables/useRemoteContent.js';
import textScriptsFallback from '@/assets/textScripts.json';

const HomeScripts = useTextScripts('HomeScripts', textScriptsFallback.HomeScripts);

const totalWordsRead = ref(0);
// distinguishes "still loading" from "genuinely zero" so the stat cards
// don't flash a real-looking 0 while the Firestore read is in flight
const statsLoading = ref(true);

// get stats from firestore
onMounted(async () => {
    const querySnapshot = await getDocs(collection(db, "stats"));
    querySnapshot.forEach((doc) => {
        totalWordsRead.value = doc.data().totalWordsRead;
    });
    statsLoading.value = false;
});

// stat cards shown below the hero, backed by the same totalWordsRead math as before
const statCards = computed(() => [
    {
        label: "Words Read",
        value: `${(totalWordsRead.value / 1000).toFixed(1)}k`,
        // same three-bar "text" mark as the sidebar's Read icon, so this
        // card visually ties back to the Read nav item
        icon: "M4 6h16M4 12h16M4 18h10"
    },
    {
        label: "Books Finished",
        // an average book is around 100,000 words; rounded down to the nearest book
        value: Math.floor(totalWordsRead.value / 100000),
        icon: "M4 4.5A2.5 2.5 0 016.5 2H20v17H6.5A2.5 2.5 0 004 21.5v-17zM4 19.5A2.5 2.5 0 016.5 17H20"
    },
    {
        label: "Hours Saved",
        // average speed on this site is ~500 wpm vs. ~250 wpm average reading speed,
        // so users read 2x faster; divide words by wpm to get minutes, then by 2 for
        // time saved, then by 60 to convert minutes saved to hours saved
        value: Math.floor(totalWordsRead.value / 500 / 2 / 60),
        // circle drawn as two semicircle arcs (standard technique for a
        // single-path icon), plus the clock hands — same visual result as
        // the handoff's separate <circle r="9"/> + hands path.
        icon: "M3 12A9 9 0 1 0 21 12A9 9 0 1 0 3 12M12 7v5l4 2"
    }
]);
</script>

<template>
    <div>
        <!-- hero -->
        <section class="mx-auto flex max-w-[1040px] flex-col items-center gap-7 px-8 pb-16 pt-[140px] text-center">
            <!-- mascot: a ring around a dot, with an ambient glow and two small sparkles -->
            <div class="relative flex h-[140px] w-[140px] flex-none items-center justify-center">
                <div class="absolute h-[196px] w-[196px] rounded-full bg-ink opacity-[.06] blur-[26px]"></div>
                <div class="absolute right-[4px] top-[2px] h-[9px] w-[9px] rounded-full bg-ink opacity-45"></div>
                <div class="absolute bottom-[8px] left-[-4px] h-[7px] w-[7px] rounded-full bg-ink opacity-30"></div>
                <div class="flex h-24 w-24 items-center justify-center rounded-full border-[7px] border-ink/35">
                    <div class="h-[46px] w-[46px] rounded-full bg-ink"></div>
                </div>
            </div>

            <h1 class="max-w-[820px] font-display text-[56px] font-bold leading-[1.1] text-ink">
                {{ HomeScripts.heroTitle }}
            </h1>
            <p class="max-w-[640px] text-[20px] leading-[1.6] text-ink-light">
                {{ HomeScripts.heroContent }}
            </p>

            <!-- Same btn-primary/btn-secondary classes as every other page's
                 CTAs (Extension, Feedback, ...) — the mockup's own literal
                 padding/font-size for these was noticeably larger than
                 those, which read as oversized and inconsistent with the
                 rest of the site. min-w keeps them a bit more prominent
                 than a typical inline button without needing custom sizing. -->
            <div class="mt-2 flex flex-wrap justify-center gap-4">
                <router-link to="/read" class="btn-primary min-w-[220px]">{{ HomeScripts.heroButton }}</router-link>
                <router-link to="/lab" class="btn-secondary min-w-[180px]">{{ HomeScripts.heroSecondaryButton }}</router-link>
            </div>
        </section>

        <!-- stats -->
        <section class="mx-auto max-w-[1180px] px-8 pb-24">
            <div class="grid gap-6" style="grid-template-columns:repeat(auto-fit,minmax(220px,1fr))">
                <div
                    class="flex flex-col items-center gap-3.5 rounded-[20px] bg-card p-8 text-center"
                    v-for="stat in statCards"
                    :key="stat.label"
                >
                    <div class="flex h-[52px] w-[52px] items-center justify-center rounded-full bg-bg">
                        <svg width="19" height="19" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round" class="text-ink">
                            <path :d="stat.icon"></path>
                        </svg>
                    </div>
                    <span class="font-display text-[40px] font-bold text-ink">
                        <span v-if="statsLoading" class="inline-block h-9 w-16 animate-pulse rounded-lg bg-bg" aria-hidden="true"></span>
                        <span v-else>{{ stat.value }}</span>
                    </span>
                    <span class="text-[15px] font-semibold text-ink-light">{{ stat.label }}</span>
                </div>
            </div>
        </section>

        <!-- how it works -->
        <section class="mx-auto max-w-[1180px] px-8 pb-24">
            <h2 class="mb-12 text-center font-display text-[34px] font-bold text-ink">How It Works</h2>
            <div class="grid gap-6" style="grid-template-columns:repeat(auto-fit,minmax(240px,1fr))">
                <div
                    class="flex flex-col gap-3.5 rounded-[20px] bg-card p-7"
                    v-for="(step, idx) in HomeScripts.steps"
                    :key="step.title"
                >
                    <div class="flex h-8 w-8 flex-none items-center justify-center rounded-full bg-ink font-display text-[15px] font-bold text-invert">
                        {{ idx + 1 }}
                    </div>
                    <h3 class="text-lg font-bold text-ink">{{ step.title }}</h3>
                    <p class="text-[15px] leading-[1.5] text-ink-light">{{ step.description }}</p>
                </div>
            </div>
        </section>

        <!-- closing call to action -->
        <section class="mx-auto max-w-[1180px] px-8 pb-24">
            <div class="flex flex-col items-center gap-4 rounded-[28px] bg-card px-8 py-14 text-center">
                <h2 class="font-display text-[30px] font-bold text-ink">{{ HomeScripts.ctaTitle }}</h2>
                <p class="text-base text-ink-light">{{ HomeScripts.ctaContent }}</p>
                <router-link to="/read" class="btn-primary mt-2 min-w-[220px]">{{ HomeScripts.heroButton }}</router-link>
            </div>
        </section>

    </div>
</template>

<style scoped></style>
