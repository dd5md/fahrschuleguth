// Minimale Lightbox (ohne Abhängigkeiten) für Links mit data-lightbox="<Gruppe>"
(function () {
  var links = Array.prototype.slice.call(document.querySelectorAll("a[data-lightbox]"));
  if (!links.length) return;
  var dlg = document.createElement("dialog");
  dlg.className = "lightbox";
  dlg.setAttribute("aria-label", "Bildansicht");
  dlg.innerHTML =
    '<div class="flex h-full w-full flex-col items-center justify-center p-4">' +
    '<img alt="" class="max-h-[80dvh] max-w-full rounded-xl object-contain">' +
    '<p class="mt-3 text-center text-sm text-white/80" data-cap></p>' +
    '<div class="mt-4 flex gap-3">' +
    '<button type="button" class="btn btn-circle" data-prev aria-label="Vorheriges Bild">‹</button>' +
    '<button type="button" class="btn btn-circle" data-close aria-label="Schließen">✕</button>' +
    '<button type="button" class="btn btn-circle" data-next aria-label="Nächstes Bild">›</button>' +
    "</div></div>";
  document.body.appendChild(dlg);
  var img = dlg.querySelector("img"), cap = dlg.querySelector("[data-cap]");
  var group = [], idx = 0;
  function show(i) {
    idx = (i + group.length) % group.length;
    img.src = group[idx].href;
    img.alt = group[idx].getAttribute("data-alt") || "";
    cap.textContent = img.alt;
  }
  links.forEach(function (a) {
    a.addEventListener("click", function (e) {
      e.preventDefault();
      var g = a.getAttribute("data-lightbox");
      group = links.filter(function (l) { return l.getAttribute("data-lightbox") === g; });
      dlg.showModal();
      show(group.indexOf(a));
    });
  });
  dlg.addEventListener("click", function (e) {
    if (e.target.closest("[data-close]") || e.target === dlg || e.target === dlg.firstChild) dlg.close();
    else if (e.target.closest("[data-prev]")) show(idx - 1);
    else if (e.target.closest("[data-next]")) show(idx + 1);
  });
  dlg.addEventListener("keydown", function (e) {
    if (e.key === "ArrowLeft") show(idx - 1);
    if (e.key === "ArrowRight") show(idx + 1);
  });
})();
