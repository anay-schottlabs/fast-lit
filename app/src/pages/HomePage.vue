<script setup>
import Header from '../components/Header.vue';
import { useRouter } from 'vue-router';
import { HomeScripts } from '@/assets/textScripts.js';
import { ref, onMounted } from 'vue';
import { db } from '@/firebase/index.js';
import { collection, getDocs } from "firebase/firestore";

const totalWordsRead = ref(0);

// get stats from firestore
onMounted(async () => {
    const querySnapshot = await getDocs(collection(db, "stats"));
    querySnapshot.forEach((doc) => {
        totalWordsRead.value = doc.data().totalWordsRead;
    });
});

const router = useRouter();

function navigateTo(path) {
    router.push(path);
}
</script>

<template>
    <div>
        <!-- page header -->
        <Header pageName="" />

        <!-- page hero -->
        <div class="hero my-20">
            <div class="hero-content text-center">
                <div class="max-w-3xl mx-auto px-4">
                    <h1 class="text-7xl font-bold text-red whitespace-normal">
                        {{ HomeScripts.heroTitle }}
                    </h1>
                    <p class="py-6">
                        {{ HomeScripts.heroContent }}
                    </p>
                    <button
                        class="btn btn-wide bg-red hover:opacity-80 relative"
                        @click="navigateTo('/read')"
                    >
                        <span class="w-full text-center">
                            {{ HomeScripts.heroButton }}
                        </span>
                        <svg
                            xmlns="http://www.w3.org/2000/svg"
                            fill="white"
                            viewBox="0 0 24 24"
                            width="28"
                            height="28"
                            class="absolute right-4 top-1/2 -translate-y-1/2"
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
                    </button>
                </div>
            </div>
        </div>

        <!-- stats display -->
        <div class="stats flex justify-center px-20">
            <!-- first stat -->
            <div class="stat">
                <div class="stat-figure text-secondary">
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        class="inline-block h-8 w-8 stroke-current text-red"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z"
                        ></path>
                    </svg>
                </div>
                <div class="stat-title">Words Read</div>
                <div class="stat-value">
                    <!-- collective words read by all users -->
                    <!-- calculated in thousands with the tenths place (e.g. 1.2K) -->
                    {{ (totalWordsRead / 1000).toFixed(1) }}k
                </div>
            </div>

            <!-- second stat -->
            <div class="stat">
                <div class="stat-figure text-secondary">
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        class="inline-block h-8 w-8 stroke-current text-red"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4"
                        ></path>
                    </svg>
                </div>
                <div class="stat-title">Books Finished</div>
                <div class="stat-value">
                    <!-- the number of books read based on total words read -->
                    <!-- an average book is around 100,000 words -->
                    <!-- this is rounded down to the nearest book -->
                    {{ Math.floor(totalWordsRead / 100000) }}
                </div>
            </div>

            <!-- third stat -->
            <div class="stat">
                <div class="stat-figure text-secondary">
                    <svg
                        xmlns="http://www.w3.org/2000/svg"
                        fill="none"
                        viewBox="0 0 24 24"
                        class="inline-block h-8 w-8 stroke-current text-red"
                    >
                        <path
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            stroke-width="2"
                            d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4"
                        ></path>
                    </svg>
                </div>
                <div class="stat-title">Hours saved</div>
                <div class="stat-value">
                    <!-- 
                    - the number of hours saved by users across the site
                    - average speed for this site is around 500 wpm, average reading speed in general is roughly 250 wpm
                    - therefore, by using this site, users read 2x faster on average
                    - we divide words by wpm to get time, then divide by 2 to get time saved
                    - finally divide by 60 to convert minutes saved to hours saved
                    -->
                    {{ Math.floor(totalWordsRead / 500 / 2 / 60) }}
                </div>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
