import { createApp } from 'vue'
import App from './App.vue'
import { createRouter, createWebHistory } from 'vue-router'
import Vue3Toastify from 'vue3-toastify';
import 'vue3-toastify/dist/index.css';
import HomePage from './components/HomePage.vue';
import ReadPage from './components/ReadPage.vue';
import ChangelogPage from './components/ChangelogPage.vue';
import FeedbackPage from './components/FeedbackPage.vue';

const router = createRouter({
    history: createWebHistory(),
    routes: [
        { path: '/', component: HomePage },
        { path: '/read', component: ReadPage },
        { path: '/changelog', component: ChangelogPage },
        { path: '/feedback', component: FeedbackPage }
    ],
});

createApp(App).use(
    Vue3Toastify,
    {
        autoClose: 3000,
    },
).use(router).mount('#app');
