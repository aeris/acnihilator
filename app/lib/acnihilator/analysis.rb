require_relative './adblock'
require_relative './cookies'
require_relative './selenium'
require_relative './whois'
require_relative './geoip'

class Acnihilator
  class Analysis
    CONFIG            = YAML.load_file 'config.yaml'
    ADBLOCK           = AdBlock.from 'easyprivacy.list'
    COOKIES           = Cookies.new 'cookiedatabase.csv'
    BAD_URLS          = TagAdblock.new CONFIG.fetch :adblock
    BAD_ORGANIZATIONS = TagAdblock.new CONFIG.fetch :organizations
    BAD_COUNTRIES     = CONFIG.fetch :countries
    RESOLVER          = Resolv::DNS.new nameserver: Acnihilator::DNS

    def self.from_web(url, wait = 10)
      selenium = Selenium.new url, wait
      data     = selenium.to_h
      self.new url, data
    end

    def self.from_db(id)
    end

    def self.from_json(id)
    end

    def to_h
      {
        url:        @url,
        date:       DateTime.now,
        urls:       @urls,
        domains:    @domains,
        cookies:    @cookies,
        violations: {
          tags:          @violations.tags.to_a,
          urls:          @violations.urls.to_h,
          organizations: @violations.organizations.to_h,
          cookies:       @violations.cookies
        },
        screenshot: @screenshot
      }
    end

    private

    def initialize(url, data)
      @violations = OpenStruct.new tags:          Set.new, urls: [],
                                   organizations: [], cookies: []
      @url        = url
      url         = URI url
      @report     = File.join 'reports', url.host + "@" + url.path.gsub('/', '_')
      @urls       = data.fetch :urls
      @cookies    = data.fetch :cookies
      self.analyze
    end

    def analyze
      LOGGER.process 'Analyzing URLs' do
        @urls.each do |url|
          match = ADBLOCK.match? url
          if match
            LOGGER.error "  #{url.colorize :red}:"
            match = match.collect &:to_s
            match.each { LOGGER.error "    #{_1}" }
            @violations.urls << [url, match.collect { [_1, :tracking] }.to_h]
            @violations.tags << :tracking
          end

          match = BAD_URLS.match? url
          if match
            LOGGER.error "  #{url.colorize background: :red}:"
            match.each { LOGGER.error "    #{_1.first.to_s}: #{_1.last.join ', '}" }
            @violations.urls << [url, match.collect { [_1.first.to_s, _1.last] }.to_h]
            @violations.tags += match.collect(&:last).flatten
          end
        end
      end

      LOGGER.process 'Analyzing domains' do
        @domains = @urls.collect { URI(_1).host }.uniq.sort
        @domains.each { LOGGER.debug '  ' + _1 } if LOGGER.debug?
        LOGGER.info "  #{@domains.size.to_s.colorize :blue} domains detected"
        @resources = @domains.collect { self.resolve _1 }
      end

      LOGGER.process 'Analyzing cookies' do
        @cookies.each do |cookie|
          name = cookie[:name]
          LOGGER.info "  #{name.colorize :blue}: #{cookie[:value]}"
          entry     = COOKIES[name]
          category  = entry.fetch :category
          violation = category == 'Functional' ? :green : :red
          LOGGER.info "    #{category.colorize violation} #{entry.fetch(:entity).colorize :yellow} #{entry.fetch :description}"
        end
      end
    end

    def bad_organization?(organization)
      match = BAD_ORGANIZATIONS.match? organization.downcase
      return organization unless match
      [organization.colorize(background: :red), match]
    end

    def bad_organizations?(organizations)
      texts, matches = [], {}
      organizations.uniq.sort.each do |organization|
        text, match = self.bad_organization? organization
        texts << text
        matches[organization] = match if match
      end
      matches = nil if matches.empty?
      [texts.join(', '), matches]
    end

    def bad_organizations!(chain, organizations)
      level       = chain.size
      domain      = chain.last
      text, match = bad_organizations? organizations
      LOGGER.info '  ' * level + "#{domain.colorize :blue}: #{text}"
      if match
        match = match.collect do |organisation, match|
          @violations.tags += match.collect(&:last).flatten
          match            = match.collect { [_1.first.to_s, _1.last] }.to_h
          [organisation, match]
        end.to_h
        @violations.organizations << [chain.join(' > '), match]
      end
    end

    def resolve(*chain)
      domain        = chain.last
      organizations = Whois.organizations PublicSuffix.domain domain
      self.bad_organizations! chain, organizations
      RESOLVER.getresources(domain, Resolv::DNS::Resource::IN::ANY)
              .collect do |resource|
        case resource
        when Resolv::DNS::Resource::IN::A, Resolv::DNS::Resource::IN::AAAA
          ip            = resource.address.to_s
          country       = Geoip.country ip
          organizations = Whois.organizations ip
          self.bad_organizations! [*chain, ip], organizations
        when Resolv::DNS::Resource::IN::CNAME
          domain = resource.name.to_s
          self.resolve *chain, domain
        end
      end
    end
  end
end
