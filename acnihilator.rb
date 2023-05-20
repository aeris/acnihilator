#!/usr/bin/env ruby
require 'bundler'
Bundler.require
require 'selenium-webdriver'
require 'amazing_print'
require 'resolv'
require 'uri'
require 'maxmind/geoip2'
require 'whois'
require 'public_suffix'
require 'colorize'
require 'ruby_jard'

require './adblock'

ADBLOCK = AdBlock.new
ADBLOCK.import 'easyprivacy.list'

options = Selenium::WebDriver::Chrome::Options.new args: %w[--headless], local_state: {
  "dns_over_https.mode":      "secure",
  "dns_over_https.templates": "https://ns0.fdn.fr/dns-query",
}
driver  = Selenium::WebDriver.for :chrome, options: options

puts 'Collecting urls...'.colorize :yellow
begin
  urls = []
  driver.intercept do |request, &continue|
    url = request.url
    urls << url
    continue.call request
  end
  driver.get ARGV.first
  cookies = driver.manage.all_cookies
ensure
  driver.quit
end
puts 'Done'.colorize :green

puts 'Analyzing urls...'.colorize :yellow
urls.each do |url|
  if match = ADBLOCK.match?(url)
    puts "  #{url.colorize(:red)}"
    match.each { puts "    #{_1.to_s.colorize :yellow}" }
  else
    puts "  #{url}"
  end
end
puts 'Done'.colorize :green

puts 'Collecting domains...'.colorize :yellow
hosts = urls.collect { URI(_1).host }.uniq.sort
hosts.each { puts '  ' + _1 }
puts 'Done'.colorize :green

puts 'Analyzing...'.colorize :yellow

RESOLVER = Resolv::DNS.new nameserver: 'ns0.fdn.fr'
GEOIP    = MaxMind::GeoIP2::Reader.new database: 'GeoLite2-Country.mmdb'
WHOIS    = Whois::Client.new

ORGANIZATIONS     = /(?:role|Organization|contact|OrgName):\s*(.*)$/.freeze
BAD_ORGANIZATIONS = %w[
  google amazon cloudflare cloudfront fastly
]

def organizations(entry)
  WHOIS.lookup(entry).to_s
       .scan(ORGANIZATIONS)
       .collect do |organization|
    organization = organization.first.chomp
    organization = organization.colorize :red if BAD_ORGANIZATIONS.any? { organization.downcase.include? _1 }
    organization
  end
rescue Timeout::Error
  []
end

def country(ip)
  country = GEOIP.country(ip)&.country.iso_code
  country.colorize country == 'US' ? :red : :yellow
end

def emoji_flag(country_code)
  cc = country_code.to_s.upcase
  return unless cc =~ /\A[A-Z]{2}\z/
  cc.codepoints.map { |c| (c + 127397).chr(Encoding::UTF_8) }.join
end

def resolve(domain, level = 1)
  org = organizations PublicSuffix.domain domain
  puts '  ' * level + "#{domain.colorize :blue}: #{org.join ', '}"
  RESOLVER.getresources(domain, Resolv::DNS::Resource::IN::ANY)
          .collect do |resource|
    case resource
    when Resolv::DNS::Resource::IN::A, Resolv::DNS::Resource::IN::AAAA
      ip      = resource.address.to_s
      country = country ip
      org     = organizations ip
      puts '  ' * (level + 1) + "#{ip.colorize :blue}: [#{country}] #{org.join ', '}"
    when Resolv::DNS::Resource::IN::CNAME
      domain = resource.name.to_s
      resolve domain, level + 1
    end
  end
end

hosts.each { resolve _1 }
puts 'Done'.colorize :green

puts 'Analyzing cookies...'.colorize :yellow
cookies.each do |cookie|
  puts "  #{cookie[:name].colorize :blue}: #{cookie[:value]}"
end
puts 'Done'.colorize :green
