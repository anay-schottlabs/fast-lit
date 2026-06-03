<script setup>
import { useRouter } from 'vue-router';

// Use one consistent SVG size for all icons
const svgSize = '2rem';

const router = useRouter();

function navigateTo(path) {
    router.push(path);
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
                class="flex min-h-full flex-col items-start bg-white is-drawer-close:w-18 is-drawer-open:w-64"
            >
                <!-- Sidebar content here -->
                <ul
                    class="menu w-full grow flex flex-col is-drawer-open:items-start is-drawer-close:items-start"
                >
                    <!-- button to toggle the sidebar -->
                    <li>
                        <label
                            for="sidebar-drawer-toggle"
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
                            style="background: none; box-shadow: none; border: none; transition: none; color: inherit;"
                        >
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                :style="{ width: svgSize, height: svgSize }"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                class="my-1.5 inline-block text-deepblue"
                            >
                                <rect x="3" y="3" width="18" height="18" rx="2" />
                                <line x1="9" y1="4" x2="9" y2="20" />
                                <polyline points="14 10 16 12 14 14" />
                            </svg>
                        </label>
                    </li>
     

                    <!-- button to navigate to the home page -->
                    <li>
                        <button
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
                            @click="navigateTo('/')"
                            style="background: none; box-shadow: none; border: none; transition: none; color: inherit;"
                        >
                            <!-- Home icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="2.5"
                                fill="none"
                                stroke="currentColor"
                                class="my-1.5 inline-block text-deepblue"
                                :style="{ width: svgSize, height: svgSize }"
                            >
                                <path
                                    d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"
                                />
                                <path
                                    d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"
                                />
                            </svg>
                            <span class="is-drawer-close:hidden text-deepblue text-xl ms-3">Home</span>
                        </button>
                    </li>

                    <!-- button to navigate to the read page -->
                    <li>
                        <button
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
                            @click="navigateTo('/read')"
                            style="background: none; box-shadow: none; border: none; transition: none; color: inherit;"
                        >
                            <!-- Read icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                class="my-1.5 inline-block text-deepblue"
                                :style="{ width: svgSize, height: svgSize }"
                            >
                                <path d="M9 4L10 4C11.1046 4 12 4.89543 12 6L12 18C12 19.1046 11.1046 20 10 20L9 20"/>
                                <path d="M15 4L14 4C12.8954 4 12 4.89543 12 6L12 18C12 19.1046 12.8954 20 14 20L15 20"/>
                                <path d="M10 12H14"/>
                            </svg>
                            <span class="is-drawer-close:hidden text-deepblue text-xl ms-3">Read</span>             
                        </button>
                    </li>

                    <!-- button to navigate to the feedback page -->
                    <li>
                        <button
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
                            @click="navigateTo('/feedback')"
                            style="background: none; box-shadow: none; border: none; transition: none; color: inherit;"
                        >
                            <!-- Feedback icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 128 128"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                class="my-1.5 inline-block text-deepblue"
                                :style="{ width: svgSize, height: svgSize }"
                            >
                                <path
                                    d="M86.5,114.1c-0.5,2.9-3,4.9-5.9,4.9H34v8h46.6c6.8,0,12.6-4.9,13.8-11.5l6.4-36
                                    c0.7-4.1-0.4-8.3-3-11.4c-2.7-3.2-6.6-5-10.7-5H71.2
                                    c1.2-3.7,2.8-9.1,4.1-16.2l0.6-4.2c0.9-6.6-3.7-12.6-10.2-13.5
                                    c-3.2-0.4-6.3,0.4-8.9,2.3c-2.6,1.9-4.2,4.8-4.7,7.9l-0.6,4
                                    c-0.1,0.5-0.2,1-0.2,1.5c-0.1,0.5-0.2,1-0.3,1.5
                                    C47.9,61,36.3,72.8,21.3,76.6L16,77.9V127h8V84.1
                                    c17.5-4.7,31.2-18.7,34.9-36c0.1-0.6,0.2-1.2,0.4-1.8
                                    c0.1-0.6,0.2-1.2,0.3-1.8l0.6-4c0.1-1.1,0.7-2,1.6-2.6
                                    c0.9-0.6,1.9-0.9,3-0.8c2.2,0.3,3.7,2.3,3.4,4.5l-0.5,3.9
                                    c-2.1,11.6-5,18.3-5.5,19.6l-0.3,0.8l0,5.2h25.5
                                    c1.8,0,3.5,0.8,4.6,2.1c1.1,1.4,1.6,3.2,1.3,4.9L86.5,114.1z"
                                    fill="currentColor"
                                />
                            </svg>
                            <span class="is-drawer-close:hidden text-deepblue text-xl ms-3">Feedback</span>             
                        </button>
                    </li>

                    <!-- button to navigate to the changelog page -->
                    <li>
                        <button
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right"
                            @click="navigateTo('/changelog')"
                            style="background: none; box-shadow: none; border: none; transition: none; color: inherit;"
                        >
                            <!-- Changelog icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="2"
                                fill="none"
                                stroke="currentColor"
                                :style="{ width: svgSize, height: svgSize }"
                                class="my-1.5 inline-block text-deepblue"
                            >
                                <path d="M20 7h-9" />
                                <path d="M14 17H5" />
                                <circle cx="17" cy="17" r="3" />
                                <circle cx="7" cy="7" r="3" />
                            </svg>
                            <span class="is-drawer-close:hidden text-deepblue text-xl ms-3">Changelog</span>             
                        </button>
                    </li>
                </ul>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
