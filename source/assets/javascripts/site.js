// Fahrschule Guth: kleine, abhängigkeitsfreie Skripte
(function () {
  var root = document.documentElement;

  // Animationen erst nach dem ersten Laden starten (schont LCP/TBT)
  window.addEventListener("load", function () { root.classList.add("is-loaded"); });

  // Dark/Light-Umschalter (Auswahl wird in localStorage gespeichert)
  var toggle = document.getElementById("theme-toggle");
  if (toggle) {
    toggle.checked = root.getAttribute("data-theme") === "guth-light";
    toggle.addEventListener("change", function () {
      var theme = toggle.checked ? "guth-light" : "guth-dark";
      root.setAttribute("data-theme", theme);
      try { localStorage.setItem("theme", theme); } catch (e) {}
    });
  }

  // Handy-Menü: Tastatur (Enter/Leertaste), Esc zum Schließen, aria-expanded
  var navToggle = document.getElementById("nav-toggle");
  if (navToggle) {
    var burger = document.getElementById("nav-burger");
    var sync = function () {
      if (burger) burger.setAttribute("aria-expanded", navToggle.checked ? "true" : "false");
    };
    navToggle.addEventListener("change", sync);
    [].forEach.call(document.querySelectorAll('label[for="nav-toggle"][role="button"]'), function (lb) {
      lb.addEventListener("keydown", function (e) {
        if (e.key === "Enter" || e.key === " ") { e.preventDefault(); navToggle.checked = !navToggle.checked; sync(); }
      });
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
