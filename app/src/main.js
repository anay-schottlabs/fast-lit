import { createApp } from 'vue'
import App from './App.vue'
import { createRouter, createWebHistory } from 'vue-router'
import HomePage from './pages/HomePage.vue';
import ReadPage from './pages/ReadPage.vue';
import WritePage from './pages/WritePage.vue';
import ExtensionPage from './pages/ExtensionPage.vue';
import ChangelogPage from './pages/ChangelogPage.vue';
import FeedbackPage from './pages/FeedbackPage.vue';
import PrivacyPolicyPage from './pages/PrivacyPolicyPage.vue';

const router = createRouter({
    history: createWebHistory(),
    routes: [
        { path: '/', component: HomePage },
        { path: '/read', component: ReadPage },
        { path: '/write', component: WritePage },
        { path: '/extension', component: ExtensionPage },
        { path: '/changelog', component: ChangelogPage },
        { path: '/feedback', component: FeedbackPage },
        { path: '/privacy', component: PrivacyPolicyPage }
    ],
});

createApp(App).use(router).mount('#app');
