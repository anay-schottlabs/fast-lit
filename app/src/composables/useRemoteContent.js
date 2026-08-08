import { ref, computed } from 'vue';

// Serves text content (site copy, lab study passages) from GitHub's raw
// content CDN instead of the bundled JS, so editing content.json + pushing
// updates the live site on next load — no Netlify rebuild needed. Falls
// back to a bundled copy (imported normally from the .json files, so it's
// always available synchronously) if the network fetch fails or hasn't
// resolved yet, so the site never shows blank/broken content and never
// blocks on the network. Note GitHub's raw CDN caches for ~5 minutes, so a
// push can take a few minutes to show up here — still far faster than a
// full rebuild+deploy cycle.
const GITHUB_RAW_BASE = 'https://raw.githubusercontent.com/anay-schottlabs/speed-reader/main/app/src/assets';

// Module-level cache: every component asking for the same file shares one
// fetch and one ref, instead of each triggering its own request. Starts as
// null (not yet fetched) rather than a fallback, since the fallback is
// per-caller (each page only wants its own section — see useTextScripts).
const cache = new Map();

function fetchJsonOnce(filename) {
    if (cache.has(filename)) {
        return cache.get(filename);
    }

    const contentRef = ref(null);
    fetch(`${GITHUB_RAW_BASE}/${filename}`, { cache: 'no-store' })
        .then((res) => (res.ok ? res.json() : Promise.reject(new Error(`HTTP ${res.status}`))))
        .then((data) => {
            contentRef.value = data;
        })
        .catch((err) => {
            console.warn(`Falling back to bundled ${filename} — fetch from GitHub failed:`, err);
        });

    cache.set(filename, contentRef);
    return contentRef;
}

// Returns a computed that reads `section` (e.g. "HomeScripts") out of the
// live-fetched textScripts.json once it's in, falling back to `fallback`
// (that page's own slice of the bundled textScripts.json) until then.
export function useTextScripts(section, fallback) {
    const whole = fetchJsonOnce('textScripts.json');
    return computed(() => whole.value?.[section] ?? fallback);
}

// labData.json is just the passages array itself, no sectioning needed.
export function useLabData(fallback) {
    const whole = fetchJsonOnce('labData.json');
    return computed(() => whole.value ?? fallback);
}
