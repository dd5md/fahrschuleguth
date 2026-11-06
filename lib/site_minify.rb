# frozen_string_literal: true

require "json"

# Verkleinert die fertig gebauten Seiten (nur beim Build):
#  * HTML: Kommentare und überflüssige Leerzeichen/Zeilenumbrüche entfernen, sodass der Quelltext sehr kompakt ist,
#  * JSON-LD: kompakt schreiben,
#  * JavaScript: mit esbuild verkleinern (falls installiert, sonst bleibt die Datei unverändert).
# Das spart Übertragungsvolumen. Ein Schutz vor dem Kopieren der Seite ist das nicht: Jeder Browser kann den Quelltext
# weiterhin lesen und formatieren.
module SiteMinify
  KEEP = /<(pre|textarea|script|style)\b[^>]*>.*?<\/\1>/mi
  # Block-Elemente: Leerraum davor und danach ändert die Darstellung nicht.
  BLOCK = %w[html head body meta link title header footer nav main section article aside div p ul ol li h1 h2 h3 h4 h5 h6
             form figure figcaption dl dt dd table thead tbody tr td th hr br noscript].freeze
  BLOCK_TAG = /\s*(<\/?(?:#{BLOCK.join("|")})\b[^>]*>)\s*/i

  module_function

  def html(source)
    keep = []
    out = source.gsub(KEEP) do
      keep << Regexp.last_match(0)
      "\u0001#{keep.size - 1}\u0001"
    end
    out = out.gsub(/<!--(?!\[if).*?-->/m, "")
    out = out.gsub(/\s+/, " ")
    out = out.gsub(BLOCK_TAG, '\1')
    out = out.strip
    out.gsub(/\u0001(\d+)\u0001/) { json_ld(keep[Regexp.last_match(1).to_i]) }
  end

  def json_ld(block)
    return block unless block =~ /\A<script type="application\/ld\+json">(.*)<\/script>\z/m

    %(<script type="application/ld+json">#{JSON.generate(JSON.parse(Regexp.last_match(1)))}</script>)
  rescue JSON::ParserError
    block
  end

  def build_dir(dir)
    Dir.glob(File.join(dir, "**", "*.html")).each do |file|
      File.write(file, html(File.read(file, encoding: "UTF-8")))
    end
    Dir.glob(File.join(dir, "assets", "javascripts", "*.js")).each do |file|
      system("npx", "--no-install", "esbuild", file, "--minify", "--outfile=#{file}", "--allow-overwrite",
             out: File::NULL, err: File::NULL)
    end
  end
end
