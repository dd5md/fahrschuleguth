# frozen_string_literal: true

require "json"

module SiteHelpers
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

  # <picture> mit WebP-Quelle und PNG- oder JPG-Fallback. `name` ohne Endung,
  # z. B. "hero/a-klasse-front". `class:` sitzt auf dem <picture>, das <img> füllt es aus.
  def picture_tag(name, alt:, class: nil, loading: "lazy", **attrs)
    css = binding.local_variable_get(:class)
    dir = File.join(app.root, config[:source], config[:images_dir])
    ext = File.exist?(File.join(dir, "#{name}.png")) ? "png" : "jpg"
    width, height = image_size(File.join(dir, "#{name}.#{ext}"))
    attributes = { alt: alt, width: width, height: height, loading: loading, decoding: "async",
                   class: "h-auto w-full" }.merge(attrs)
                                           .map { |key, value| %(#{key}="#{ERB::Util.html_escape(value)}") }.join(" ")
    webp = image?("#{name}.webp") ? %(<source srcset="#{asset_path(:images, "#{name}.webp")}" type="image/webp">) : ""
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
    "close" => "M6 18 18 6M6 6l12 12"
  }.freeze

  SOCIAL_ICONS = {
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
      %(<li><a href="#{asset_path(:images, "#{it.file}.webp")}" data-lightbox="#{group}" data-alt="#{ERB::Util.html_escape(it.alt)}" class="group block overflow-hidden rounded-box border border-base-content/10 bg-base-200">) +
        picture_tag(it.file, alt: it.alt, loading: eager, class: "aspect-[4/3] overflow-hidden",
                             style: "object-fit:cover;aspect-ratio:4/3") +
        %(</a></li>)
    end
    %(<ul class="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-4">#{lis.join}</ul>)
  end
end
