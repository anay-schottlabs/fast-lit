<script setup>
import { useRouter } from 'vue-router';

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

        <div class="drawer-side is-drawer-close:overflow-visible">
            <!-- Make the sidebar white by using bg-white instead of bg-base-200 -->
            <div class="flex min-h-full flex-col items-start bg-white is-drawer-close:w-14 is-drawer-open:w-64">
                <!-- Sidebar content here -->
                <ul class="menu w-full grow">
                    <!-- button to toggle the sidebar -->
                    <li>
                        <label for="sidebar-drawer-toggle" aria-label="open sidebar" class="btn btn-square btn-ghost">
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="2"
                                fill="none"
                                stroke="currentColor"
                                class="my-1.5 inline-block size-4 text-deepblue"
                            >
                                <path
                                    d="M4 4m0 2a2 2 0 0 1 2 -2h12a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2-2z"
                                />
                                <path d="M9 4v16" />
                                <path d="M14 10l2 2l-2 2" />
                            </svg>
             
                        </label>
                    </li>

                    <!-- button to navigate to the home page -->
                    <li>
                        <button
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right" data-tip="Home"
                            @click="navigateTo('/')"
                        >
                            <!-- Home icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="2"
                                fill="none"
                                stroke="currentColor"
                                class="my-1.5 inline-block size-4 text-deepblue"
                            >
                                <path
                                    d="M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8"
                                />
                                <path
                                    d="M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"
                                />
                            </svg>
                   
                            <span class="is-drawer-close:hidden text-deepblue">Home</span>
                        </button>
                    </li>

                    <!-- button to navigate to the read page -->
                    <li>
                        <button
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right" data-tip="Read"
                            @click="navigateTo('/read')"
                        >
                            <!-- Settings icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="2"
                                fill="none"
                                stroke="currentColor"
                                class="my-1.5 inline-block size-4 text-deepblue"
                            >
                                <path d="M20 7h-9" />
                                <path d="M14 17H5" />
                                <circle cx="17" cy="17" r="3" />
                                <circle cx="7" cy="7" r="3" />
                            </svg>    
                            <span class="is-drawer-close:hidden text-deepblue">Read</span>             
                        </button>
                    </li>

                    <!-- button to navigate to the feedback page -->
                    <li>
                        <button
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right" data-tip="Feedback"
                            @click="navigateTo('/feedback')"
                        >
                            <!-- Settings icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="2"
                                fill="none"
                                stroke="currentColor"
                                class="my-1.5 inline-block size-4 text-deepblue"
                            >
                                <path d="M20 7h-9" />
                                <path d="M14 17H5" />
                                <circle cx="17" cy="17" r="3" />
                                <circle cx="7" cy="7" r="3" />
                            </svg>    
                            <span class="is-drawer-close:hidden text-deepblue">Feedback</span>             
                        </button>
                    </li>

                    <!-- button to navigate to the changelog page -->
                    <li>
                        <button
                            class="is-drawer-close:tooltip is-drawer-close:tooltip-right" data-tip="Changelog"
                            @click="navigateTo('/changelog')"
                        >
                            <!-- Settings icon -->
                            <svg
                                xmlns="http://www.w3.org/2000/svg"
                                viewBox="0 0 24 24"
                                stroke-linejoin="round"
                                stroke-linecap="round"
                                stroke-width="2"
                                fill="none"
                                stroke="currentColor"
                                class="my-1.5 inline-block size-4 text-deepblue"
                            >
                                <path d="M20 7h-9" />
                                <path d="M14 17H5" />
                                <circle cx="17" cy="17" r="3" />
                                <circle cx="7" cy="7" r="3" />
                            </svg>    
                            <span class="is-drawer-close:hidden text-deepblue">Changelog</span>             
                        </button>
                    </li>
                </ul>
            </div>
        </div>
    </div>
</template>

<style scoped></style>
