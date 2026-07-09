<script setup>
import Header from '../components/Header.vue';
import { useRouter } from 'vue-router';
import { ExtensionScripts } from '@/assets/textScripts.js';

const router = useRouter();

function navigateTo(path) {
    router.push(path);
}

function openStore() {
    window.open(ExtensionScripts.storeUrl, "_blank");
}
</script>

<template>
    <!--
        header + hero share this wrapper, same full-bleed-through-padding technique
        as HomePage.vue: -mt-4 cancels App.vue's p-4 top padding, pt-4 adds it back
        so the header's on-screen position is unchanged.
    -->
    <div class="relative -mt-4 overflow-hidden pt-4">
        <!-- decorative glow -->
        <div
            class="pointer-events-none absolute -top-10 left-1/2 -z-10 h-[34rem] w-[34rem] -translate-x-1/2 rounded-full bg-red/25 blur-3xl"
            aria-hidden="true"
        ></div>

        <Header pageName="Extension" />

        <!-- hero -->
        <div class="mx-auto max-w-3xl px-4 pb-16 pt-16 text-center">
            <span class="inline-block rounded-full border border-red/40 bg-red/10 px-4 py-1 text-xs font-semibold uppercase tracking-widest text-red-light">
                {{ ExtensionScripts.heroBadge }}
            </span>

            <h1 class="mt-5 text-5xl font-bold !text-red sm:text-6xl">{{ ExtensionScripts.heroTitle }}</h1>
            <p class="mx-auto mt-6 max-w-xl text-lg text-white/80">{{ ExtensionScripts.heroContent }}</p>

            <button
                class="btn-red !w-full max-w-80 mt-8"
                @click="openStore"
            >
                <span class="w-full flex items-center justify-center gap-2 ms-2">
                    {{ ExtensionScripts.installButton }}
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="white"
                        viewBox="0 0 24 24"
                        width="24"
                        height="24"
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
    </div>

    <div class="mx-auto max-w-5xl px-4 pb-24">
        <!-- feature highlights -->
        <div class="grid gap-6 sm:grid-cols-3">
            <div
                class="rounded-2xl border border-white/10 bg-white/5 p-6 shadow-2xl shadow-black/40"
                v-for="feature in ExtensionScripts.features"
                :key="feature.title"
            >
                <h3 class="mb-2 text-lg font-semibold !text-red">{{ feature.title }}</h3>
                <p class="text-sm text-white/70">{{ feature.description }}</p>
            </div>
        </div>

        <!-- how it works -->
        <div class="mt-16">
            <h2 class="mb-10 text-center text-3xl font-bold">{{ ExtensionScripts.stepsTitle }}</h2>
            <div class="grid gap-6 sm:grid-cols-2 lg:grid-cols-4">
                <div
                    class="rounded-2xl border border-white/10 bg-white/5 p-6 shadow-2xl shadow-black/40"
                    v-for="(step, idx) in ExtensionScripts.steps"
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

        <!-- privacy callout -->
        <div class="mt-16 rounded-3xl border border-white/10 bg-white/5 p-8 shadow-2xl shadow-black/40 sm:p-10">
            <div class="flex flex-col items-start gap-4 sm:flex-row sm:items-center">
                <div class="flex h-12 w-12 shrink-0 items-center justify-center rounded-full bg-red/15">
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        stroke="currentColor"
                        stroke-width="2.5"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        class="h-6 w-6 text-red"
                    >
                        <rect x="5" y="11" width="14" height="9" rx="2" />
                        <path d="M8 11V8a4 4 0 0 1 8 0v3" />
                    </svg>
                </div>
                <div>
                    <h3 class="text-xl font-semibold">{{ ExtensionScripts.privacyTitle }}</h3>
                    <p class="mt-2 text-white/70">{{ ExtensionScripts.privacyContent }}</p>
                    <button
                        class="mt-4 inline-flex items-center gap-1 text-sm font-semibold text-red-light transition-colors hover:text-red-light/80 focus-ring rounded cursor-pointer"
                        @click="navigateTo('/privacy')"
                    >
                        {{ ExtensionScripts.privacyLinkText }}
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2.5"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="h-4 w-4"
                        >
                            <path d="M5 12h14M13 6l6 6-6 6" />
                        </svg>
                    </button>
                </div>
            </div>
        </div>

        <!-- faq -->
        <div class="mt-16">
            <h2 class="mb-10 text-center text-3xl font-bold">Frequently Asked Questions</h2>
            <div class="mx-auto flex max-w-3xl flex-col gap-4">
                <div
                    class="rounded-2xl border border-white/10 bg-white/5 p-6 shadow-2xl shadow-black/40"
                    v-for="item in ExtensionScripts.faq"
                    :key="item.question"
                >
                    <h3 class="mb-2 font-semibold !text-red">{{ item.question }}</h3>
                    <p class="text-sm text-white/70">{{ item.answer }}</p>
                </div>
            </div>
        </div>

        <!-- closing call to action -->
        <div class="mx-auto mt-16 max-w-3xl text-center">
            <div class="rounded-3xl border border-white/10 bg-white/5 px-6 py-12 shadow-2xl shadow-black/40">
                <h2 class="mb-3 text-3xl font-bold">Ready to read the whole web faster?</h2>
                <p class="mb-6 text-white/70">Install Fast Lit Grabber and turn any article into a speed-read in one click.</p>
                <button
                    class="btn-red !w-full max-w-80"
                    @click="openStore"
                >
                    {{ ExtensionScripts.installButton }}
                </button>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
