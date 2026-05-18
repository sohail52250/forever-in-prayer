self.addEventListener("install", e=>{
  e.waitUntil(
    caches.open("memorial").then(cache=>{
      return cache.addAll([
        "./",
        "./index.html",
        "./brother1.jpeg",
        "./brother2.jpeg",
        "./AlFatihah.mp3",
        "./dua.mp3",
        "./icon.png"
      ]);
    })
  );
});

self.addEventListener("fetch", e=>{
  e.respondWith(
    caches.match(e.request).then(r=>r || fetch(e.request))
  );
});