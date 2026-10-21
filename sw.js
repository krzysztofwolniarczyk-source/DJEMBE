/* Service worker PWA. Rejestrowany tylko pod https (GitHub Pages) —
   w natywnej powłoce iOS strona idzie z http://127.0.0.1 i SW nie jest potrzebny. */
var CACHE = 'bartek-jones-v1';
var CORE = [
  './',
  './index.html',
  './manifest.webmanifest',
  './icons/icon-192.png',
  './icons/icon-512.png',
  './icons/maskable-512.png',
  './icons/apple-touch-icon.png'
];

self.addEventListener('install', function (e) {
  e.waitUntil(
    caches.open(CACHE).then(function (c) { return c.addAll(CORE); }).then(function () { return self.skipWaiting(); })
  );
});

self.addEventListener('activate', function (e) {
  e.waitUntil(
    caches.keys()
      .then(function (ks) { return Promise.all(ks.filter(function (k) { return k !== CACHE; }).map(function (k) { return caches.delete(k); })); })
      .then(function () { return self.clients.claim(); })
  );
});

self.addEventListener('fetch', function (e) {
  var req = e.request;
  if (req.method !== 'GET') return;

  /* Otwarcie aplikacji: najpierw sieć (świeża wersja), offline — kopia z cache. */
  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(function (res) {
          var cp = res.clone();
          caches.open(CACHE).then(function (c) { c.put('./index.html', cp); });
          return res;
        })
        .catch(function () { return caches.match('./index.html'); })
    );
    return;
  }

  /* Ikony, manifest: najpierw cache, brakujące dociągnij i zapamiętaj. */
  e.respondWith(
    caches.match(req).then(function (hit) {
      return hit || fetch(req).then(function (res) {
        if (res && res.ok) {
          var cp = res.clone();
          caches.open(CACHE).then(function (c) { c.put(req, cp); });
        }
        return res;
      });
    })
  );
});
