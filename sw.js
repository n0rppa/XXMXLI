// Minimal service worker for basic caching
const CACHE_NAME = 'xxmxli-static-v1';
const PRECACHE_URLS = [
  '/', '/index.html', '/styles.css', '/photography.html', '/security.html', '/donate.html'
];

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(CACHE_NAME).then(cache => cache.addAll(PRECACHE_URLS))
  );
});

self.addEventListener('activate', event => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('fetch', event => {
  event.respondWith(
    caches.match(event.request).then(response => response || fetch(event.request))
  );
});
