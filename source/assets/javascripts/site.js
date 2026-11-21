// Fahrschule Guth: kleine, abhängigkeitsfreie Skripte
(function () {
  var root = document.documentElement;

  // Animationen erst nach dem ersten Laden starten (schont LCP/TBT)
  window.addEventListener("load", function () { root.classList.add("is-loaded"); });

  // Handy-Menü: Tastatur (Enter/Leertaste), Esc zum Schließen, aria-expanded
  var navToggle = document.getElementById("nav-toggle");
  if (navToggle) {
    var burger = document.getElementById("nav-burger");
    var sync = function () {
      if (burger) burger.setAttribute("aria-expanded", navToggle.checked ? "true" : "false");
    };
    navToggle.addEventListener("change", sync);
    // Echte Knöpfe (Enter und Leertaste funktionieren von selbst) schalten das Menü um
    [].forEach.call(document.querySelectorAll("[data-nav-toggle]"), function (btn) {
      btn.addEventListener("click", function () { navToggle.checked = !navToggle.checked; sync(); if (!navToggle.checked && burger) burger.focus(); });
    });
    document.addEventListener("keydown", function (e) {
      if (e.key === "Escape" && navToggle.checked) { navToggle.checked = false; sync(); if (burger) burger.focus(); }
    });
    [].forEach.call(document.querySelectorAll("#nav-drawer a"), function (a) {
      a.addEventListener("click", function () { navToggle.checked = false; sync(); });
    });
  }

  // Schnellauswahl: filtert die Themenliste und springt direkt zum Ziel
  var form = document.querySelector("[data-quicksearch]");
  if (form) {
    var input = form.querySelector("input");
    var list = form.querySelector("[data-results]");
    var items = [].slice.call(list.querySelectorAll("li"));
    var norm = function (s) { return s.toLowerCase().normalize("NFD").replace(/[̀-ͯ]/g, ""); };
    var update = function () {
      var q = norm(input.value.trim()), shown = 0;
      items.forEach(function (li) {
        var hit = q === "" || norm(li.getAttribute("data-text")).indexOf(q) !== -1;
        li.hidden = !hit;
        if (hit) shown++;
      });
      list.hidden = q === "" || shown === 0;
    };
    input.addEventListener("input", update);
    input.addEventListener("focus", function () { if (input.value) update(); });
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      var first = items.filter(function (li) { return !li.hidden; })[0];
      if (first) window.location.href = first.querySelector("a").getAttribute("href");
    });
    document.addEventListener("click", function (e) { if (!form.contains(e.target)) list.hidden = true; });
    document.addEventListener("keydown", function (e) {
      if (e.key === "/" && !/input|textarea|select/i.test(document.activeElement.tagName)) { e.preventDefault(); input.focus(); }
      if (e.key === "Escape") { list.hidden = true; input.blur(); }
    });
  }

  // Tabs (Preise): ohne JavaScript bleiben alle Panels sichtbar
  [].forEach.call(document.querySelectorAll("[data-tabs]"), function (box) {
    var tabs = [].slice.call(box.querySelectorAll("[role=tab]"));
    var show = function (tab) {
      tabs.forEach(function (t) {
        var on = t === tab;
        t.setAttribute("aria-selected", on);
        document.getElementById(t.getAttribute("aria-controls")).hidden = !on;
      });
    };
    tabs.forEach(function (t, i) {
      t.addEventListener("click", function () { show(t); });
      t.addEventListener("keydown", function (e) {
        var n = e.key === "ArrowRight" ? i + 1 : e.key === "ArrowLeft" ? i - 1 : null;
        if (n === null) return;
        var next = tabs[(n + tabs.length) % tabs.length]; next.focus(); show(next);
      });
    });
    show(tabs[0]);
  });

  // Eingebettete Fremdinhalte (YouTube, Karte) erst nach Klick laden
  [].forEach.call(document.querySelectorAll("[data-embed]"), function (box) {
    var btn = box.querySelector("button");
    if (!btn) return;
    btn.addEventListener("click", function () {
      var f = document.createElement("iframe");
      f.src = box.getAttribute("data-embed");
      f.title = box.getAttribute("data-title") || "Eingebetteter Inhalt";
      f.className = "size-full";
      if (box.getAttribute("data-height")) { box.style.minHeight = box.getAttribute("data-height") + "px"; f.style.minHeight = box.getAttribute("data-height") + "px"; }
      f.setAttribute("allow", "encrypted-media; picture-in-picture");
      f.setAttribute("allowfullscreen", "");
      box.innerHTML = "";
      box.appendChild(f);
    });
  });
})();

// Zähleffekt: Zahlen mit data-count laufen beim Einblenden von 0 hoch (ohne JavaScript oder bei reduzierter Bewegung steht der Endwert im Text)
(function () {
  var els = document.querySelectorAll("[data-count]");
  if (!els.length) return;
  if ((window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches) || !("IntersectionObserver" in window)) return;
  function fmt(el, v) {
    var d = parseInt(el.getAttribute("data-decimals"), 10) || 0;
    return (el.getAttribute("data-prefix") || "") + v.toLocaleString("de-DE", { minimumFractionDigits: d, maximumFractionDigits: d }) + (el.getAttribute("data-suffix") || "");
  }
  function run(el) {
    var to = parseFloat(el.getAttribute("data-count")), t0 = null, dur = 1600;
    function step(t) {
      if (t0 === null) t0 = t;
      var p = Math.min((t - t0) / dur, 1), e = 1 - Math.pow(1 - p, 3);
      el.textContent = fmt(el, to * e);
      if (p < 1) requestAnimationFrame(step);
    }
    requestAnimationFrame(step);
  }
  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (x) {
      if (x.isIntersecting) { io.unobserve(x.target); run(x.target); }
    });
  }, { threshold: 0.6 });
  els.forEach(function (el) { el.textContent = fmt(el, 0); io.observe(el); });
})();

// Effekte: Kacheln der Startseite blenden einzeln ein; Lichtstreifen (.beam) läuft nur, solange die Kachel sichtbar ist
(function () {
  if (!("IntersectionObserver" in window)) return;
  var still = window.matchMedia && matchMedia("(prefers-reduced-motion: reduce)").matches;
  if (still) return;
  var beams = document.querySelectorAll(".beam");
  if (beams.length) {
    var bo = new IntersectionObserver(function (entries) {
      entries.forEach(function (x) { x.target.classList.toggle("is-view", x.isIntersecting); });
    });
    beams.forEach(function (el) { bo.observe(el); });
  }
  var vh = window.innerHeight || document.documentElement.clientHeight;
  // Bilder (Galerien, Startseite „bestanden“, News, große Fotos im Text) fliegen schräg von unten ein, links von links, rechts von rechts, Mitte von unten
  var main = document.querySelector("main");
  var pics = [];
  Array.prototype.forEach.call(document.querySelectorAll("main li > a[data-lightbox]"), function (a) { pics.push(a.parentElement); });
  Array.prototype.forEach.call(document.querySelectorAll("main picture"), function (p) {
    if (p.closest(".tile") || p.closest("li > a[data-lightbox]") || p.closest("[data-embed]")) return;
    if (p.getBoundingClientRect().width >= 200) pics.push(p);
  });
  pics = pics.filter(function (el) { return el.getBoundingClientRect().top > vh * 0.9; });
  if (pics.length) {
    pics.forEach(function (el) {
      var box = el.tagName === "LI" ? el.parentElement : main;
      var r = box.getBoundingClientRect(), e = el.getBoundingClientRect();
      var f = r.width ? (e.left + e.width / 2 - r.left) / r.width : 0.5;
      el.style.setProperty("--fx", f < 0.34 ? "-50px" : f > 0.66 ? "50px" : "0px");
      el.classList.add("fly-wait");
    });
    var po = new IntersectionObserver(function (entries) {
      var n = 0;
      entries.forEach(function (x) {
        if (!x.isIntersecting) return;
        var el = x.target;
        po.unobserve(el);
        el.style.animationDelay = Math.min(n * 140, 700) + "ms";
        n++;
        el.classList.remove("fly-wait");
        el.classList.add("fly-in");
        el.addEventListener("animationend", function () {
          el.classList.remove("fly-in");
          el.style.animationDelay = "";
          el.style.removeProperty("--fx");
        }, { once: true });
      });
    }, { threshold: 0.12, rootMargin: "0px 0px -6% 0px" });
    pics.forEach(function (el) { po.observe(el); });
  }
  if (!document.querySelector("[data-reveal-scope]")) return;
  var tiles = Array.prototype.filter.call(document.querySelectorAll("[data-reveal-scope] main .tile"), function (el) {
    // nur Kacheln unterhalb des ersten Bildschirms und keine verschachtelten Kacheln
    return !(el.parentElement && el.parentElement.closest(".tile")) && el.getBoundingClientRect().top > vh * 0.9;
  });
  if (!tiles.length) return;
  tiles.forEach(function (el) { el.classList.add("reveal-wait"); });
  var ro = new IntersectionObserver(function (entries) {
    var n = 0;
    entries.forEach(function (x) {
      if (!x.isIntersecting) return;
      var el = x.target;
      ro.unobserve(el);
      el.style.animationDelay = Math.min(n * 90, 360) + "ms";
      n++;
      el.classList.remove("reveal-wait");
      el.classList.add("reveal-in");
      el.addEventListener("animationend", function () {
        el.classList.remove("reveal-in");
        el.style.animationDelay = "";
      }, { once: true });
    });
  }, { threshold: 0.12, rootMargin: "0px 0px -6% 0px" });
  tiles.forEach(function (el) { ro.observe(el); });
})();
