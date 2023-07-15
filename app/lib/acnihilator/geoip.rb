require 'maxmind/geoip2'

class Acnihilator
  class Geoip
    DATABASE = MaxMind::GeoIP2::Reader.new database: 'GeoLite2-Country.mmdb'

    def self.country(ip)
      country = DATABASE.country(ip)&.country.iso_code
      return '??' if country.nil?
      country
    rescue
      '??'
    end
  end
end
