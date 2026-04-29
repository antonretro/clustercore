const CACHE_NAME = 'clustercore-v2';
const CORE_ASSETS = [
    './',
    './index.html',
    './css/style.css',
    './js/ad-manager.js',
    './js/music-manager.js',
    './js/render-utils.js',
    './js/match-engine.js',
    './js/game.js',
    './audio/music/game-intro.ogg',
    './audio/music/game-loop.ogg',
    './audio/music/game-outro.ogg'
];

self.addEventListener('install', (event) => {
    event.waitUntil(
        caches.open(CACHE_NAME).then((cache) => cache.addAll(CORE_ASSETS))
    );
    self.skipWaiting();
});

self.addEventListener('activate', (event) => {
    event.waitUntil(
        caches.keys().then((keys) =>
            Promise.all(
                keys
                    .filter((key) => key !== CACHE_NAME)
                    .map((key) => caches.delete(key))
            )
        )
    );
    self.clients.claim();
});

function isClusterCoreRequest(url) {
    return url.origin === self.location.origin && url.pathname.startsWith('/games/clustercore/');
}

async function networkFirst(request) {
    const cache = await caches.open(CACHE_NAME);
    try {
        const fresh = await fetch(request);
        if (fresh && fresh.ok) {
            cache.put(request, fresh.clone());
        }
        return fresh;
    } catch (error) {
        const cached = await cache.match(request);
        if (cached) return cached;
        throw error;
    }
}

async function staleWhileRevalidate(request) {
    const cache = await caches.open(CACHE_NAME);
    const cached = await cache.match(request);

    const networkPromise = fetch(request)
        .then((response) => {
            if (response && response.ok) {
                cache.put(request, response.clone());
            }
            return response;
        })
        .catch(() => null);

    return cached || networkPromise || fetch(request);
}

self.addEventListener('fetch', (event) => {
    const { request } = event;
    if (request.method !== 'GET') return;

    const url = new URL(request.url);
    if (!isClusterCoreRequest(url)) return;

    // Keep gameplay routes resilient: prefer fresh HTML, fallback to cache.
    const isNavigation = request.mode === 'navigate' || request.destination === 'document';
    if (isNavigation) {
        event.respondWith(networkFirst(request));
        return;
    }

    // Static assets: instant cache response with background refresh.
    event.respondWith(staleWhileRevalidate(request));
});
