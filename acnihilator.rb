require 'selenium-webdriver'
require 'resolv'
require 'uri'
require 'public_suffix'
require 'colorize'
require 'logger'
require 'yaml'
require 'json'
require 'ostruct'

require './acnihilator/adblock'
require './acnihilator/whois'
require './acnihilator/geoip'

class Acnihilator
  DNS      = 'ns0.fdn.fr'
  RESOLVER = Resolv::DNS.new nameserver: DNS

  USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/113.0.0.0 Safari/537.36'
  OPTIONS    = Selenium::WebDriver::Chrome::Options.new local_state: {
    "dns_over_https.mode":      'secure',
    "dns_over_https.templates": "https://#{DNS}/dns-query",
  }, args:                                                           %W[--headless --user-agent=#{USER_AGENT}]

  ADBLOCK           = AdBlock.from 'easyprivacy.list'
  CONFIG            = YAML.load_file 'config.yaml'
  BAD_URLS          = TagAdblock.new CONFIG.fetch :adblock
  BAD_ORGANIZATIONS = TagAdblock.new CONFIG.fetch :organizations
  BAD_COUNTRIES     = CONFIG.fetch :countries

  LOGGER = Logger.new STDOUT, level: Logger::INFO,
                      formatter:     (proc do |severity, datetime, progname, msg|
                        msg + "\n"
                      end)

  def initialize(url, wait = 10)
    @violations = OpenStruct.new tags:          Set.new, urls: [],
                                 organizations: [], cookies: []
    @url        = url
    url         = URI url
    @report     = File.join 'reports', url.host + "@" + url.path.gsub('/', '_')

    self.do_in_browser do |driver|
      self.process 'Collecting urls' do
        @urls = []
        driver.intercept do |request, &continue|
          @urls << url = request.url
          LOGGER.debug '  ' + url if LOGGER.debug?
          continue.call request
        end
        driver.get @url
        if wait
          LOGGER.info "  Waiting #{wait}s, because trackers are evils…"
          sleep wait
        end
        LOGGER.info "  #{@urls.size.to_s.colorize :blue} URLs collected"
      end
      self.process 'Collecting cookies' do
        @cookies = driver.manage.all_cookies
        LOGGER.info "  #{@cookies.size.to_s.colorize :blue} cookies collected"
      end
      self.process 'Take screenshot' do
        @screenshot = driver.screenshot_as :png, full_page: false
      end
    end

    self.process 'Analyzing URLs' do
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

    self.process 'Analyzing domains' do
      @domains = @urls.collect { URI(_1).host }.uniq.sort
      @domains.each { LOGGER.debug '  ' + _1 } if LOGGER.debug?
      LOGGER.info "  #{@domains.size.to_s.colorize :blue} domains detected"
      @resources = @domains.collect { self.resolve _1 }
    end

    self.process 'Analyzing cookies' do
      @cookies.each do |cookie|
        name = cookie[:name]
        LOGGER.info "  #{name.colorize :blue}: #{cookie[:value]}"
      end
    end
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

  def process(text)
    LOGGER.info (text + '…').colorize :yellow
    yield
    LOGGER.info 'Done'.colorize :green
  end

  def do_in_browser
    driver = Selenium::WebDriver.for :chrome, options: OPTIONS
    begin
      driver.manage.window.resize_to 1920, 1080
      driver.manage.delete_all_cookies
      yield driver
    ensure
      driver.quit
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
