/* Au juste mot — service worker
   Strategie :
   - app shell (HTML/icones/manifeste) precachee a l'installation -> ouverture hors-ligne immediate
   - meme origine : cache-first puis reseau (et on garde la copie)
   - Google Fonts : stale-while-revalidate -> hors-ligne apres la 1re visite en ligne
   Bump CACHE a chaque nouvelle version de l'app pour forcer la mise a jour. */
const CACHE = "ajm-dev";
const FONTS = "ajm-fonts-v1";
const SHELL = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-maskable-512.png",
  "./icons/apple-touch-icon.png"
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(CACHE).then((c) => c.addAll(SHELL)));
  // pas de skipWaiting automatique : la page proposera la mise a jour
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((keys) => Promise.all(keys.filter((k) => k !== CACHE && k !== FONTS).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("message", (e) => {
  if (e.data === "skip-waiting") self.skipWaiting();
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);

  // Google Fonts : stale-while-revalidate
  if (url.hostname === "fonts.googleapis.com" || url.hostname === "fonts.gstatic.com") {
    e.respondWith(caches.open(FONTS).then(async (c) => {
      const cached = await c.match(req);
      const network = fetch(req).then((r) => { c.put(req, r.clone()); return r; }).catch(() => cached);
      return cached || network;
    }));
    return;
  }

  // meme origine : cache-first, repli index.html pour la navigation
  if (url.origin === self.location.origin) {
    e.respondWith(caches.match(req).then((cached) => cached || fetch(req).then((r) => {
      const copy = r.clone();
      caches.open(CACHE).then((c) => c.put(req, copy));
      return r;
    }).catch(() => req.mode === "navigate" ? caches.match("./index.html") : undefined)));
    return;
  }

  // autres origines : reseau puis repli cache
  e.respondWith(fetch(req).catch(() => caches.match(req)));
});
