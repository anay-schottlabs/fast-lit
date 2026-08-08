<script setup>
import { useTextScripts } from '@/composables/useRemoteContent.js';
import textScriptsFallback from '@/assets/textScripts.json';

const PrivacyScripts = useTextScripts('PrivacyScripts', textScriptsFallback.PrivacyScripts);
</script>

<template>
    <div>
        <div class="mx-auto max-w-3xl px-4 pb-16 pt-16">
            <div class="rounded-3xl border border-border bg-card p-10">
                <span class="inline-block rounded-full border border-ink/30 bg-ink/10 px-4 py-1 text-xs font-semibold uppercase tracking-widest !text-ink">
                    {{ PrivacyScripts.lastUpdated }}
                </span>
                <h1 class="mt-4 text-3xl font-bold !text-ink sm:text-4xl">{{ PrivacyScripts.title }}</h1>
                <p class="mt-6 text-lg !text-ink-light">{{ PrivacyScripts.intro }}</p>

                <div
                    v-for="(section, idx) in PrivacyScripts.sections"
                    :key="section.heading"
                    class="mt-8 border-t border-border pt-8"
                >
                    <div class="mb-4 flex items-center gap-3">
                        <span class="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-ink text-sm font-bold !text-invert">
                            {{ idx + 1 }}
                        </span>
                        <h2 class="text-xl font-semibold !text-ink">{{ section.heading }}</h2>
                    </div>

                    <p
                        v-for="paragraph in section.paragraphs"
                        :key="paragraph"
                        class="mb-3 !text-ink-light"
                    >
                        {{ paragraph }}
                    </p>

                    <ul v-if="section.list" class="mb-3 flex flex-col gap-2">
                        <li
                            v-for="item in section.list"
                            :key="item"
                            class="flex items-start gap-3 !text-ink-light"
                        >
                            <span class="mt-2.5 h-1.5 w-1.5 shrink-0 rounded-full bg-ink"></span>
                            <span>{{ item }}</span>
                        </li>
                    </ul>

                    <p
                        v-for="paragraph in section.after"
                        :key="paragraph"
                        class="!text-ink-light"
                    >
                        {{ paragraph }}
                    </p>
                </div>
            </div>

        </div>

    </div>
</template>

<style scoped></style>
