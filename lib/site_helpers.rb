# frozen_string_literal: true

require "json"

module SiteHelpers
  # Versionsnummer pro Build: hängt als ?v=… an CSS/JS, damit Browser nach einem Update die neue Datei laden
  # (die .htaccess erlaubt ein Jahr Cache). Überschreibbar: ASSET_VERSION=2 bundle exec middleman build
  BUILD_VERSION = (ENV["ASSET_VERSION"] || Time.now.strftime("%Y%m%d%H%M")).freeze

  def versioned(path)
    "#{path}?v=#{BUILD_VERSION}"
  end

  def site_url
    config[:site_url]
  end

  # Titel wie auf der Altseite: "<Seite> • <Site-Titel>"
  def page_title
    title = current_page.data.title
    site = data.site
    title ? "#{title} #{site.title_separator} #{site.title}" : site.title
  end

  def page_description
    current_page.data.description || data.site.description
  end

  def canonical_url
    "#{site_url}#{current_page.url}"
  end

  def og_image_url
    image = current_page.data.og_image || config[:default_og_image]
    image.start_with?("http") ? image : "#{site_url}#{image}"
  end

  # Telefonnummer mit farbigem Trenner (| zwischen Vorwahl und Nummer). `sep:` = CSS-Klassen für den Trenner.
  def phone(text, sep: "text-primary")
    ERB::Util.html_escape(text.to_s).gsub("|", %(<span class="#{sep}">|</span>))
  end

  # Typografie: verhindert Einzelwörter in der letzten Zeile ("ab 17", "35 kW") durch geschützte Leerzeichen.
  # Zahl + Einheit bleiben zusammen, die letzten zwei Wörter ebenfalls (wenn das letzte kurz ist).
  def tidy(text)
    t = ERB::Util.html_escape(text.to_s)
    t = t.gsub(/(\d)\s+(kW|kg|ccm|km|€|Jahre[n]?|Uhr|Minuten|Tage[n]?)/, '\1&nbsp;\2')
    t.sub(/\s+(\S{1,4})\z/, '&nbsp;\1')
  end

  # WhatsApp-Link (wa.me) mit vorbereiteter Nachricht
  def whatsapp_link(contact = data.site.contacts.first, text = "Hallo Uli, ich habe eine Frage zur Fahrschule.")
    "https://wa.me/#{contact.whatsapp}?text=#{ERB::Util.url_encode(text)}"
  end

  def tel_link(number)
    %(tel:#{number})
  end

  def home?
    current_page.url == "/"
  end

  # Breadcrumb-Einträge [[Name, URL], ...] aus Frontmatter `breadcrumbs:` oder Titel.
  def breadcrumbs
    return [] if home?
    crumbs = [["Home", "/"]]
    Array(current_page.data.breadcrumb_parents).each { |p| crumbs << [p["label"], p["href"]] }
    crumbs << [current_page.data.crumb || current_page.data.title, current_page.url]
    crumbs
  end

  def opening_hours_schema
    data.site.hours.map do |h|
      { "@type" => "OpeningHoursSpecification", "dayOfWeek" => h.schema_day,
        "opens" => "16:00", "closes" => "17:00" }
    end.concat(data.site.hours.map do |h|
      { "@type" => "OpeningHoursSpecification", "dayOfWeek" => h.schema_day,
        "opens" => "18:00", "closes" => "20:30" }
    end)
  end

  def business_schema
    s = data.site
    {
      "@type" => %w[DrivingSchool LocalBusiness],
      "@id" => "#{site_url}/#business",
      "name" => s.legal_name,
      "alternateName" => s.name,
      "url" => "#{site_url}/",
      "slogan" => s.slogan,
      "description" => s.description,
      "image" => "#{site_url}#{config[:default_og_image]}",
      "logo" => "#{site_url}/assets/images/logo.svg",
      "telephone" => s.contacts.first.tel,
      "email" => s.contacts.first.email,
      "founder" => { "@type" => "Person", "name" => s.owner },
      "address" => {
        "@type" => "PostalAddress", "streetAddress" => s.address.street,
        "postalCode" => s.address.plz, "addressLocality" => s.address.city,
        "addressRegion" => s.address.region, "addressCountry" => s.address.country
      },
      "geo" => { "@type" => "GeoCoordinates", "latitude" => s.geo.lat, "longitude" => s.geo.lon },
      "areaServed" => s.address.district,
      "openingHoursSpecification" => opening_hours_schema,
      "contactPoint" => s.contacts.map do |c|
        { "@type" => "ContactPoint", "name" => c.name, "contactType" => c.role,
          "telephone" => c.tel, "email" => c.email, "availableLanguage" => "de" }
      end,
      "sameAs" => [s.facebook]
    }
  end

  # JSON-LD @graph: LocalBusiness/DrivingSchool, WebSite, WebPage, BreadcrumbList (+ Frontmatter `schema:`)
  def json_ld_graph
    graph = [
      business_schema,
      { "@type" => "WebSite", "@id" => "#{site_url}/#website", "url" => "#{site_url}/",
        "name" => data.site.name, "inLanguage" => "de-DE",
        "publisher" => { "@id" => "#{site_url}/#business" } },
      { "@type" => "WebPage", "@id" => "#{canonical_url}#webpage", "url" => canonical_url,
        "name" => page_title, "description" => page_description, "inLanguage" => "de-DE",
        "isPartOf" => { "@id" => "#{site_url}/#website" },
        "about" => { "@id" => "#{site_url}/#business" } }
    ]
    crumbs = breadcrumbs
    unless crumbs.empty?
      graph << { "@type" => "BreadcrumbList",
                 "itemListElement" => crumbs.each_with_index.map do |(name, url), i|
                   { "@type" => "ListItem", "position" => i + 1, "name" => name, "item" => "#{site_url}#{url}" }
                 end }
    end
    if current_page.data.faq_schema
      graph << { "@type" => "FAQPage", "@id" => "#{canonical_url}#faq",
                 "mainEntity" => data.faq.map do |f|
                   { "@type" => "Question", "name" => f.frage,
                     "acceptedAnswer" => { "@type" => "Answer", "text" => f.antwort } }
                 end }
    end
    graph.concat(Array(current_page.data.schema).map(&:to_h))
    { "@context" => "https://schema.org", "@graph" => graph }
  end

  def image?(path)
    !sitemap.find_resource_by_path("#{config[:images_dir]}/#{path}").nil?
  end

  # Breite/Höhe aus PNG- oder JPEG-Header (verhindert Layout-Shift).
  def image_size(path)
    data = File.binread(path)
    if data[0, 8] == "\x89PNG\r\n\x1a\n".b
      data[16, 8].unpack("N2")
    else
      i = 2
      while i < data.bytesize
        marker = data.getbyte(i + 1)
        len = data[i + 2, 2].unpack1("n")
        return data[i + 5, 4].unpack("n2").reverse if (0xC0..0xCF).cover?(marker) && ![0xC4, 0xC8, 0xCC].include?(marker)
        i += 2 + len
      end
    end
  end

  # <picture> mit WebP-Quelle (optional mit kleinerer Variante "<name>-640.webp" als srcset)
  # und PNG-/JPG-Fallback. `name` ohne Endung, z. B. "hero/a-klasse-seite".
  # `class:` sitzt auf dem <picture>, das <img> füllt es aus. `sizes:` beschreibt die Anzeigebreite.
  def picture_tag(name, alt:, class: nil, loading: "lazy", sizes: nil, **attrs)
    css = binding.local_variable_get(:class)
    dir = File.join(app.root, config[:source], config[:images_dir])
    ext = File.exist?(File.join(dir, "#{name}.png")) ? "png" : "jpg"
    width, height = image_size(File.join(dir, "#{name}.#{ext}"))
    attributes = { alt: alt, width: width, height: height, loading: loading, decoding: "async",
                   class: "h-auto w-full" }.merge(attrs)
                                           .map { |key, value| %(#{key}="#{ERB::Util.html_escape(value)}") }.join(" ")
    srcset = asset_path(:images, "#{name}.webp")
    if image?("#{name}-640.webp") && width > 640
      srcset = "#{asset_path(:images, "#{name}-640.webp")} 640w, #{srcset} #{width}w"
    end
    webp = image?("#{name}.webp") ? %(<source srcset="#{srcset}"#{%( sizes="#{sizes}") if sizes} type="image/webp">) : ""
    %(<picture class="block #{css}">#{webp}<img src="#{asset_path(:images, "#{name}.#{ext}")}" #{attributes}></picture>)
  end

  ICONS = {
    "check" => "m4.5 12.75 6 6 9-13.5",
    "arrow" => "M13.5 4.5 21 12m0 0-7.5 7.5M21 12H3",
    "moon" => "M21.752 15.002A9.72 9.72 0 0 1 18 15.75c-5.385 0-9.75-4.365-9.75-9.75 0-1.33.266-2.597.748-3.752A9.753 9.753 0 0 0 3 11.25C3 16.635 7.365 21 12.75 21a9.753 9.753 0 0 0 9.002-5.998Z",
    "sun" => "M12 3v2.25m6.364.386-1.591 1.591M21 12h-2.25m-.386 6.364-1.591-1.591M12 18.75V21m-4.773-4.227-1.591 1.591M5.25 12H3m4.227-4.773L5.636 5.636M15.75 12a3.75 3.75 0 1 1-7.5 0 3.75 3.75 0 0 1 7.5 0Z",
    "menu" => "M3.75 6.75h16.5M3.75 12h16.5m-16.5 5.25h16.5",
    "phone" => "M2.25 6.75c0 8.284 6.716 15 15 15h2.25a2.25 2.25 0 0 0 2.25-2.25v-1.372c0-.516-.351-.966-.852-1.091l-4.423-1.106c-.44-.11-.902.055-1.173.417l-.97 1.293c-.282.376-.769.542-1.21.38a12.035 12.035 0 0 1-7.143-7.143c-.162-.441.004-.928.38-1.21l1.293-.97c.363-.271.527-.734.417-1.173L6.963 3.102a1.125 1.125 0 0 0-1.091-.852H4.5A2.25 2.25 0 0 0 2.25 4.5v2.25Z",
    "mail" => "M21.75 6.75v10.5a2.25 2.25 0 0 1-2.25 2.25h-15a2.25 2.25 0 0 1-2.25-2.25V6.75m19.5 0A2.25 2.25 0 0 0 19.5 4.5h-15a2.25 2.25 0 0 0-2.25 2.25m19.5 0v.243a2.25 2.25 0 0 1-1.07 1.916l-7.5 4.615a2.25 2.25 0 0 1-2.36 0L3.32 8.91a2.25 2.25 0 0 1-1.07-1.916V6.75",
    "pin" => "M15 10.5a3 3 0 1 1-6 0 3 3 0 0 1 6 0ZM19.5 10.5c0 7.142-7.5 11.25-7.5 11.25S4.5 17.642 4.5 10.5a7.5 7.5 0 1 1 15 0Z",
    "clock" => "M12 6v6h4.5m4.5 0a9 9 0 1 1-18 0 9 9 0 0 1 18 0Z",
    "download" => "M3 16.5v2.25A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75V16.5M16.5 12 12 16.5m0 0L7.5 12m4.5 4.5V3",
    "external" => "M13.5 6H5.25A2.25 2.25 0 0 0 3 8.25v10.5A2.25 2.25 0 0 0 5.25 21h10.5A2.25 2.25 0 0 0 18 18.75V10.5m-10.5 6L21 3m0 0h-5.25M21 3v5.25",
    "left" => "M15.75 19.5 8.25 12l7.5-7.5",
    "right" => "m8.25 4.5 7.5 7.5-7.5 7.5",
    "laptop" => "M9 17.25v1.007a3 3 0 0 1-.879 2.122L7.5 21h9l-.621-.621A3 3 0 0 1 15 18.257V17.25m6-12V15a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 15V5.25m18 0A2.25 2.25 0 0 0 18.75 3H5.25A2.25 2.25 0 0 0 3 5.25m18 0V12a2.25 2.25 0 0 1-2.25 2.25H5.25A2.25 2.25 0 0 1 3 12V5.25",
    "car" => "M8.25 18.75a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h6m-9 0H3.375a1.125 1.125 0 0 1-1.125-1.125V14.25m17.25 4.5a1.5 1.5 0 0 1-3 0m3 0a1.5 1.5 0 0 0-3 0m3 0h1.125c.621 0 1.129-.504 1.09-1.124a17.902 17.902 0 0 0-3.213-9.193 2.056 2.056 0 0 0-1.58-.86H14.25M16.5 18.75h-2.25m0-11.177v-.958c0-.568-.422-1.048-.987-1.106a48.554 48.554 0 0 0-10.026 0 1.106 1.106 0 0 0-.987 1.106v7.635m12-6.677v6.677m0 4.5v-4.5m0 0h-12",
    "star" => "M11.48 3.499a.562.562 0 0 1 1.04 0l2.125 5.111a.563.563 0 0 0 .475.345l5.518.442c.499.04.701.663.321.988l-4.204 3.602a.563.563 0 0 0-.182.557l1.285 5.385a.562.562 0 0 1-.84.61l-4.725-2.885a.562.562 0 0 0-.586 0L6.982 20.54a.562.562 0 0 1-.84-.61l1.285-5.386a.562.562 0 0 0-.182-.557l-4.204-3.602a.562.562 0 0 1 .321-.988l5.518-.442a.563.563 0 0 0 .475-.345L11.48 3.5Z",
    "search" => "m21 21-5.197-5.197m0 0A7.5 7.5 0 1 0 5.196 5.196a7.5 7.5 0 0 0 10.607 10.607Z",
    "bolt" => "m3.75 13.5 10.5-11.25L12 10.5h8.25L9.75 21.75 12 13.5H3.75Z",
    "shield" => "M9 12.75 11.25 15 15 9.75m-3-7.036A11.959 11.959 0 0 1 3.598 6 11.99 11.99 0 0 0 3 9.749c0 5.592 3.824 10.29 9 11.623 5.176-1.332 9-6.03 9-11.622 0-1.31-.21-2.571-.598-3.751h-.152c-3.196 0-6.1-1.248-8.25-3.285Z",
    "calendar" => "M6.75 3v2.25M17.25 3v2.25M3 18.75V7.5a2.25 2.25 0 0 1 2.25-2.25h13.5A2.25 2.25 0 0 1 21 7.5v11.25m-18 0A2.25 2.25 0 0 0 5.25 21h13.5A2.25 2.25 0 0 0 21 18.75m-18 0v-7.5A2.25 2.25 0 0 1 5.25 9h13.5A2.25 2.25 0 0 1 21 11.25v7.5",
    "heart" => "M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z",
    "bus" => "M8 6v6M15 6v6M2 12h19.6M18 18h3s.5-1.7.8-2.8c.1-.4.2-.8.2-1.2 0-.4-.1-.8-.2-1.2l-1.4-5C20.1 6.8 19.1 6 18 6H4a2 2 0 0 0-2 2v10h3M9 18h5M19 18a2 2 0 1 1-4 0M9 18a2 2 0 1 1-4 0",
    "close" => "M6 18 18 6M6 6l12 12"
  }.freeze

  SOCIAL_ICONS = {
    "whatsapp" => "M17.472 14.382c-.297-.149-1.758-.867-2.03-.967-.273-.099-.471-.148-.67.15-.197.297-.767.966-.94 1.164-.173.199-.347.223-.644.075-.3-.15-1.263-.465-2.403-1.485-.888-.795-1.484-1.77-1.66-2.07-.174-.3-.019-.465.13-.615.136-.135.301-.345.451-.523.146-.181.194-.301.297-.496.1-.21.049-.375-.025-.524-.075-.15-.672-1.62-.922-2.206-.24-.584-.487-.51-.672-.51-.172-.015-.371-.015-.571-.015-.2 0-.523.074-.797.359-.273.3-1.045 1.02-1.045 2.475s1.07 2.865 1.219 3.075c.149.195 2.105 3.195 5.1 4.485.714.3 1.27.48 1.704.629.714.227 1.365.195 1.88.121.574-.091 1.767-.721 2.016-1.426.255-.705.255-1.29.18-1.425-.074-.135-.27-.21-.57-.345m-5.446 7.443h-.016c-1.77 0-3.524-.48-5.055-1.38l-.36-.214-3.75.975 1.005-3.645-.239-.375c-.99-1.576-1.516-3.391-1.516-5.26 0-5.445 4.455-9.885 9.942-9.885 2.654 0 5.145 1.035 7.021 2.91 1.875 1.859 2.909 4.35 2.909 6.99-.004 5.444-4.46 9.885-9.935 9.885M20.52 3.449C18.24 1.245 15.24 0 12.045 0 5.463 0 .104 5.334.101 11.893c0 2.096.549 4.14 1.595 5.945L0 24l6.335-1.652c1.746.943 3.71 1.444 5.71 1.447h.006c6.585 0 11.946-5.336 11.949-11.896 0-3.176-1.24-6.165-3.495-8.411",
    "facebook" => "M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z"
  }.freeze

  def social_icon(name, css: "size-4")
    %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" class="#{css}" aria-hidden="true"><path d="#{SOCIAL_ICONS.fetch(name.to_s)}"/></svg>)
  end

  def icon(name, css: "size-6", stroke: 1.5)
    path = ICONS.fetch(name.to_s)
    %(<svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="#{stroke}" stroke="currentColor" class="#{css}" aria-hidden="true"><path stroke-linecap="round" stroke-linejoin="round" d="#{path}"/></svg>)
  end

  # Galerie-Raster mit Lightbox. items: Liste von {file, alt}
  def gallery_grid(items, group: "gallery")
    lis = items.each_with_index.map do |it, i|
      eager = i < 4 ? "eager" : "lazy"
      %(<li><a href="#{asset_path(:images, "#{it.file}.webp")}" data-lightbox="#{group}" data-alt="#{ERB::Util.html_escape(it.alt)}" class="group block overflow-hidden rounded-box bg-base-100 shadow-sm transition hover:-translate-y-1 hover:shadow-lg">) +
        picture_tag(it.file, alt: it.alt, loading: eager, class: "aspect-[4/3] overflow-hidden",
                             style: "object-fit:cover;aspect-ratio:4/3") +
        %(</a></li>)
    end
    %(<ul class="grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-4">#{lis.join}</ul>)
  end
end
