// 불 끄기 대작전 서비스워커: 한 번 받은 모델·지도·인식 파일은 저장해 두고 빠르게, 화면(HTML)은 항상 새 버전 먼저
const V = 'gnfire-v1';
const SHELL = ['./', 'index.html', 'train.html', 'teacher.html', 'manifest.json', 'lib/qrcode.js', 'lobby.webp', 'comic_intro.webp', 'comic_ending.webp'];
self.addEventListener('install', e => { e.waitUntil(caches.open(V).then(c => c.addAll(SHELL).catch(() => { }))); self.skipWaiting(); });
self.addEventListener('activate', e => { e.waitUntil(caches.keys().then(ks => Promise.all(ks.filter(k => k !== V).map(k => caches.delete(k))))); self.clients.claim(); });
self.addEventListener('fetch', e => {
  const r = e.request; if (r.method !== 'GET') return;
  const u = new URL(r.url), same = u.origin === location.origin;
  if (!same && !/cdn\.jsdelivr\.net|fonts\.(googleapis|gstatic)\.com/.test(u.host)) return;
  if (r.mode === 'navigate' || /\.html?$/.test(u.pathname) || u.pathname.endsWith('/')) {
    e.respondWith(fetch(r).then(res => { const c = res.clone(); caches.open(V).then(x => x.put(r, c)); return res; }).catch(() => caches.match(r).then(m => m || caches.match('index.html'))));
    return;
  }
  e.respondWith(caches.match(r).then(m => m || fetch(r).then(res => { if (res.ok || res.type === 'opaque') { const c = res.clone(); caches.open(V).then(x => x.put(r, c)); } return res; })));
});
