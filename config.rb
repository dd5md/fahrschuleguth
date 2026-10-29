# frozen_string_literal: true

require_relative "lib/site_helpers"

# ---------------------------------------------------------------------------
# Site-Konfiguration
# ---------------------------------------------------------------------------
set :site_url, ENV.fetch("SITE_URL", "https://fahrschuleguth.de")
set :default_og_image, "/assets/images/og-image.jpg"
set :default_locale, "de_DE"

set :relative_links, true

# Markup
set :erb_engine, :erb

# Asset-Verzeichnisse (relativ zu source/)
config[:css_dir]     = "assets/stylesheets"
config[:js_dir]      = "assets/javascripts"
config[:images_dir]  = "assets/images"
config[:fonts_dir]   = "assets/fonts"

# URLs wie auf der Altseite: /ueberuns/preise/ (Verzeichnis + Slash)
activate :directory_indexes
page "/404.html", directory_index: false, layout: "layout"

# Tailwind-Quelldatei ist nur Input für die Tailwind CLI und wird nicht ausgeliefert
ignore "assets/stylesheets/site.src.css"
ignore "**/.gitkeep"

page "/*.xml", layout: false
page "/*.json", layout: false
page "/*.txt", layout: false

# ---------------------------------------------------------------------------
# External Pipeline: Tailwind CLI (kein Sprockets)
# ---------------------------------------------------------------------------
tailwind_input  = "source/assets/stylesheets/site.src.css"
tailwind_output = ".tmp/dist/assets/stylesheets/site.css"

activate :external_pipeline,
         name: :tailwind,
         command: if build?
                    "NODE_ENV=production npx tailwindcss -i #{tailwind_input} -o #{tailwind_output} --minify"
                  else
                    "npx tailwindcss -i #{tailwind_input} -o #{tailwind_output} --watch"
                  end,
         source: ".tmp/dist",
         latency: 1

# ---------------------------------------------------------------------------
# Helpers (lib/site_helpers.rb)
# ---------------------------------------------------------------------------
helpers SiteHelpers

configure :build do
  activate :minify_html, remove_quotes: false if defined?(Middleman::MinifyHtml)
end
