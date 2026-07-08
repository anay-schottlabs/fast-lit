<script setup>
import Header from '../components/Header.vue';
import { useRouter } from 'vue-router';
import { HomeScripts } from '@/assets/textScripts.js';
import { ref, computed, onMounted, onUnmounted, watch } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, getDocs } from "firebase/firestore";

const totalWordsRead = ref(0);
// distinguishes "still loading" from "genuinely zero" so the stat cards
// don't flash a real-looking 0 while the Firestore read is in flight
const statsLoading = ref(true);
// docId is only set once the Firestore stats doc has loaded below; guards
// saveDemoWordsRead against running before it's available.
let docId;

// get stats from firestore
onMounted(async () => {
    const querySnapshot = await getDocs(collection(db, "stats"));
    querySnapshot.forEach((doc) => {
        docId = doc.id;
        totalWordsRead.value = doc.data().totalWordsRead;
    });
    statsLoading.value = false;
});

// counts every word the live preview cycles through during this page visit,
// added to the firestore total when the page is closed, reloaded, or
// navigated away from within the app.
let demoWordsRead = 0;

const FIRESTORE_COMMIT_URL = `https://firestore.googleapis.com/v1/projects/${db.app.options.projectId}/databases/(default)/documents:commit`;

// beforeunload/pagehide handlers can't reliably wait on async work — the
// browser doesn't keep the page alive for a pending fetch/XHR to finish, so
// the Firestore SDK's write (a long-lived WebChannel request) can get cut
// off mid-flight before it ever reaches the server. Confirmed this in
// testing: an SDK updateDoc() call fired from beforeunload silently never
// landed. navigator.sendBeacon() is built specifically for this "flush data
// as the page goes away" case — the browser guarantees the request is sent
// even after the page unloads — so this hits Firestore's REST commit
// endpoint directly with an atomic increment transform, bypassing the SDK.
function saveDemoWordsRead() {
    if (demoWordsRead > 0 && docId) {
        const body = {
            writes: [
                {
                    transform: {
                        document: `projects/${db.app.options.projectId}/databases/(default)/documents/stats/${docId}`,
                        fieldTransforms: [
                            { fieldPath: "totalWordsRead", increment: { integerValue: String(demoWordsRead) } }
                        ]
                    }
                }
            ]
        };
        navigator.sendBeacon(FIRESTORE_COMMIT_URL, new Blob([JSON.stringify(body)], { type: "application/json" }));
        demoWordsRead = 0;
    }
}

window.addEventListener('beforeunload', saveDemoWordsRead);

const router = useRouter();

function navigateTo(path) {
    router.push(path);
}

// live preview widget: cycles through HomeScripts.demoWords to show the
// RSVP focal-point effect right in the hero, the same way Reader.vue does
// for real reading sessions.
const demoIndex = ref(0);

// every index change is one more word the live preview has cycled through
watch(demoIndex, () => {
    demoWordsRead++;
});

const demoWord = computed(() => HomeScripts.demoWords[demoIndex.value]);
const demoBefore = computed(() => demoWord.value.slice(0, Math.floor(demoWord.value.length / 2)));
const demoRedLetter = computed(() => demoWord.value[Math.floor(demoWord.value.length / 2)]);
const demoAfter = computed(() => demoWord.value.slice(Math.floor(demoWord.value.length / 2) + 1));

// same punctuation-pause technique as Reader.vue, restricted to the two marks
// that actually appear in HomeScripts.demoText: commas get one extra tick,
// periods get three, before the demo advances to the next word.
const DemoDelayState = Object.freeze({
    NONE: "none",
    SHORT_PAUSE: "shortPause",
    MEDIUM_PAUSE: "mediumPause",
    LONG_PAUSE: "longPause"
});

const demoDelayState = ref(DemoDelayState.NONE);

let demoInterval;

onMounted(() => {
    const intervalMs = Math.floor(60000 / HomeScripts.demoWpm);
    demoInterval = setInterval(() => {
        if (demoDelayState.value == DemoDelayState.LONG_PAUSE) {
            demoDelayState.value = DemoDelayState.MEDIUM_PAUSE;
            return;
        }
        else if (demoDelayState.value == DemoDelayState.MEDIUM_PAUSE) {
            demoDelayState.value = DemoDelayState.SHORT_PAUSE;
            return;
        }
        else if (demoDelayState.value == DemoDelayState.SHORT_PAUSE) {
            demoDelayState.value = DemoDelayState.NONE;
            demoIndex.value = (demoIndex.value + 1) % HomeScripts.demoWords.length;
            return;
        }

        const lastChar = demoWord.value[demoWord.value.length - 1];
        if (lastChar == ".") {
            demoDelayState.value = DemoDelayState.LONG_PAUSE;
        }
        else if (lastChar == ",") {
            demoDelayState.value = DemoDelayState.SHORT_PAUSE;
        }
        else {
            demoIndex.value = (demoIndex.value + 1) % HomeScripts.demoWords.length;
        }
    }, intervalMs);
});

onUnmounted(() => {
    clearInterval(demoInterval);
    // beforeunload only fires on an actual tab close/reload — navigating to
    // another page within the app just unmounts this component, so flush
    // the count here too, and drop the listener since it'd otherwise stack
    // up (and misfire with a stale docId) if the user revisits the home page.
    window.removeEventListener('beforeunload', saveDemoWordsRead);
    saveDemoWordsRead();
});

// stat cards shown below the hero, backed by the same totalWordsRead math as before
const statCards = computed(() => [
    {
        label: "Words Read",
        value: `${(totalWordsRead.value / 1000).toFixed(1)}k`,
        icon: "M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
    },
    {
        label: "Books Finished",
        // an average book is around 100,000 words; rounded down to the nearest book
        value: Math.floor(totalWordsRead.value / 100000),
        icon: "M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"
    },
    {
        label: "Hours Saved",
        // average speed on this site is ~500 wpm vs. ~250 wpm average reading speed,
        // so users read 2x faster; divide words by wpm to get minutes, then by 2 for
        // time saved, then by 60 to convert minutes saved to hours saved
        value: Math.floor(totalWordsRead.value / 500 / 2 / 60),
        icon: "M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"
    }
]);
</script>

<template>
    <div>
        <!--
            header + hero share this wrapper so the decorative glow bleeds behind both.
            App.vue wraps <router-view> in a p-4 box, which reserves 16px above this
            page that this wrapper can't paint into on its own — so -mt-4 cancels that
            reserved space (a standard negative-margin "full bleed inside a padded
            layout" trick) and pt-4 adds the same amount back as internal padding,
            keeping the header's on-screen position unchanged while letting the glow's
            background extend all the way up behind it.
        -->
        <div class="relative -mt-4 overflow-hidden pt-4">
            <!-- decorative glow -->
            <div
                class="pointer-events-none absolute -top-10 left-1/2 -z-10 h-[34rem] w-[34rem] -translate-x-1/2 rounded-full bg-red/25 blur-3xl"
                aria-hidden="true"
            ></div>

            <!-- page header -->
            <Header pageName="" />

            <!-- hero -->
            <div class="mx-auto grid max-w-6xl gap-16 px-4 pb-20 pt-16 lg:grid-cols-2 lg:items-center">
                <!-- copy + CTA -->
                <div class="text-center lg:text-left">
                    <span class="inline-block rounded-full border border-red/40 bg-red/10 px-4 py-1 text-xs font-semibold uppercase tracking-widest text-red-light">
                        {{ HomeScripts.heroBadge }}
                    </span>

                    <h1 class="mt-5 text-6xl font-bold !text-red whitespace-normal lg:text-7xl">
                        {{ HomeScripts.heroTitle }}
                    </h1>
                    <p class="py-6 text-lg text-white/80">
                        {{ HomeScripts.heroContent }}
                    </p>
                    <button
                        class="btn-red !w-full max-w-64"
                        @click="navigateTo('/read')"
                    >
                        <span class="w-full flex items-center justify-center gap-2 ms-2">
                            {{ HomeScripts.heroButton }}
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                fill="white"
                                viewBox="0 0 24 24"
                                width="28"
                                height="28"
                            >
                                <path
                                    d="M5 12h14M13 6l6 6-6 6"
                                    stroke="white"
                                    stroke-width="2.2"
                                    stroke-linecap="round"
                                    stroke-linejoin="round"
                                    fill="none"
                                />
                            </svg>
                        </span>
                    </button>
                </div>

                <!-- live RSVP preview -->
                <div class="rounded-3xl border border-white/10 bg-white/5 p-10 shadow-2xl shadow-black/40">
                    <p class="text-center text-xs font-semibold uppercase tracking-widest text-white/50">
                        Live Preview
                    </p>
                    <div class="my-8 flex h-16 items-center justify-center text-5xl font-bold">
                        <span class="flex-1 text-right">{{ demoBefore }}</span>
                        <span class="text-red">{{ demoRedLetter }}</span>
                        <span class="flex-1 text-left">{{ demoAfter }}</span>
                    </div>
                    <p class="text-center text-sm text-white/50">
                        ~{{ HomeScripts.demoWpm }} words per minute
                    </p>
                </div>
            </div>
        </div>

        <!-- stats -->
        <div class="mx-auto mb-24 grid max-w-5xl gap-6 px-4 sm:grid-cols-3">
            <div
                class="rounded-2xl border border-white/10 bg-white/5 p-6 text-center shadow-2xl shadow-black/40"
                v-for="stat in statCards"
                :key="stat.label"
            >
                <div class="mx-auto mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-red/15">
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        class="h-6 w-6 stroke-current text-red"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            :d="stat.icon"
                        ></path>
                    </svg>
                </div>
                <div class="text-4xl font-bold">
                    <span v-if="statsLoading" class="inline-block h-9 w-16 animate-pulse rounded-lg bg-white/10" aria-hidden="true"></span>
                    <span v-else>{{ stat.value }}</span>
                </div>
                <div class="mt-1 text-sm text-white/55">{{ stat.label }}</div>
            </div>
        </div>

        <!-- how it works -->
        <div class="mx-auto mb-24 max-w-5xl px-4">
            <h2 class="mb-10 text-center text-3xl font-bold">How It Works</h2>
            <div class="grid gap-6 sm:grid-cols-3">
                <div
                    class="rounded-2xl border border-white/10 bg-white/5 p-6 shadow-2xl shadow-black/40"
                    v-for="(step, idx) in HomeScripts.steps"
                    :key="step.title"
                >
                    <span class="mb-4 flex h-8 w-8 items-center justify-center rounded-full bg-red text-sm font-bold">
                        {{ idx + 1 }}
                    </span>
                    <h3 class="mb-2 text-lg font-semibold">{{ step.title }}</h3>
                    <p class="text-sm text-white/70">{{ step.description }}</p>
                </div>
            </div>
        </div>

        <!-- closing call to action -->
        <div class="mx-auto mb-24 max-w-3xl px-4 text-center">
            <div class="rounded-3xl border border-white/10 bg-white/5 px-6 py-12 shadow-2xl shadow-black/40">
                <h2 class="mb-3 text-3xl font-bold">{{ HomeScripts.ctaTitle }}</h2>
                <p class="mb-6 text-white/70">{{ HomeScripts.ctaContent }}</p>
                <button
                    class="btn-red !w-full max-w-64"
                    @click="navigateTo('/read')"
                >
                    {{ HomeScripts.heroButton }}
                </button>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
