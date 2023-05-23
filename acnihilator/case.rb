require 'json'

class Acnihilator
  class Case
    def initialize(file, locale = :fr)
      @report        = JSON.load_file file
      @violations    = @report.fetch 'violations'
      @tags          = @violations.fetch 'tags'
      @urls          = @violations.fetch 'urls'
      @organizations = @violations.fetch 'organizations'
    end

    def urls(*tags)
      @urls.reject { |_, f| f.select { |f, t| tags.any? { t.include? _1 } }.empty? }
           .collect { |u, _| u = URI(u); u.fragment = u.query = nil; "  - #{u}" }.sort
    end

    def organizations(*tags)
      @organizations.reject { |_, f| f.select { |f, t| t.values.any? { |v| tags.any? { |t| v.include? t } } }.empty? }
                    .collect { |o, f| "  - #{o}: #{f.first.first}" }.sort
    end

    def tags(*tags)
      urls          = self.urls *tags
      organizations = self.organizations *tags
      return if urls.empty? && organizations.empty?
      [*urls, '', *organizations]
    end

    CNIL_TAGS    = %w[google-analytics recaptcha hcaptcha]
    US_PROVIDERS = %w[google microsoft amazon fastly edgecast akamai]

    def to_s
      text = [
        'Bonjour,', '',
        "Suite à la visite du site #{@report.fetch 'url'}, j’ai a priori relevé plusieurs non conformités RGPD."
      ]

      if us = self.tags('us')
        text      += ['', "Ce site semble mettre en œuvre des services état-uniens, en violation de l’arrêt Schrems II de juillet 2020 de la CJUE ou recourt à des sous-traitants qui en font de même."]
        providers = @tags & US_PROVIDERS
        text      += ['Les sous-traitants identifiés sont : ' + providers.collect(&:capitalize).join(', '), ''] unless providers.empty?
        text      += us
      end

      if tracking = self.tags('tracking')
        text += ['', 'Ce site aurait aussi mis en place du contenu considéré comme traçant :', '']
        text += tracking
      end

      if cnil = self.tags(*CNIL_TAGS)
        tags = CNIL_TAGS.select { self.tags _1 }.collect(&:capitalize).join ', '
        text += ['', "Il semble aussi que ce service utilise des services déjà sanctionnés par votre Commission, à savoir : #{tags}"]
        text += cnil
      end

      text += ['', 'Je tenais donc à vous signaler les manquements constatés à l’utilisation de ce service.']
      text.join "\n"
    end
  end
end
