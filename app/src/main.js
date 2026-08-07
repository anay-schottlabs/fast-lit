import { createApp } from 'vue'
import App from './App.vue'
import { createRouter, createWebHistory } from 'vue-router'
import HomePage from './pages/HomePage.vue';
import ReadPage from './pages/ReadPage.vue';
import ExtensionPage from './pages/ExtensionPage.vue';
import ChangelogPage from './pages/ChangelogPage.vue';
import FeedbackPage from './pages/FeedbackPage.vue';
import PrivacyPolicyPage from './pages/PrivacyPolicyPage.vue';
import LabPage from './pages/LabPage.vue';
import LabResultsPage from './pages/LabResultsPage.vue';

const router = createRouter({
    history: createWebHistory(),
    routes: [
        { path: '/', component: HomePage },
        { path: '/read', component: ReadPage },
        { path: '/extension', component: ExtensionPage },
        { path: '/changelog', component: ChangelogPage },
        { path: '/feedback', component: FeedbackPage },
        { path: '/privacy', component: PrivacyPolicyPage },
        { path: '/lab', component: LabPage },
        // Admin-only results view — deliberately not in the sidebar nav,
        // reachable by direct URL only.
        { path: '/lab/results', component: LabResultsPage }
    ],
});

createApp(App).use(router).mount('#app');
