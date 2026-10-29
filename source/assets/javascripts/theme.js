// Dark/Light-Umschalter (Auswahl wird in localStorage gespeichert)
(function () {
  var toggle = document.getElementById("theme-toggle");
  if (!toggle) return;
  var root = document.documentElement;
  toggle.checked = root.getAttribute("data-theme") === "guth-light";
  toggle.addEventListener("change", function () {
    var theme = toggle.checked ? "guth-light" : "guth-dark";
    root.setAttribute("data-theme", theme);
    try { localStorage.setItem("theme", theme); } catch (e) {}
  });
})();
