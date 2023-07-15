require 'whois'

class Acnihilator
  class Whois
    CLIENT        = ::Whois::Client.new
    ORGANIZATIONS = /(?:role|Organization|contact|OrgName|org-name):\s*(.*)$/.freeze

    def self.organizations(entry)
      CLIENT.lookup(entry).to_s
            .scan(ORGANIZATIONS)
            .collect { _1.first.chomp }
    rescue
      []
    end
  end
end
