/** @type {import('tailwindcss').Config} */
// Wird in assets/css/site.css per `@config` eingebunden (Tailwind v4).
// daisyUI 5 ist ein CSS-natives Plugin und wird daher in assets/css/site.css
// per `@plugin "daisyui"` samt Theme-Liste registriert (JS-`require` wird von v5 nicht unterstützt).
module.exports = {
  content: [
    "./source/**/*.{erb,html,md}",
    "./config.rb",
    "./helpers/**/*.rb",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
      },
    },
  },
};
