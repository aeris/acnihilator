require 'csv'

class Acnihilator
  class Cookies
    def initialize(csv)
      @cookies = CSV.open(csv, headers: true)
                    .collect do |row|
        name, entity, category, description = row.values_at 'Cookie / Data Key name', 'Platform', 'Category', 'Description'
        { name: name.downcase, entity: entity, category: category, description: description }
      end
    end

    def [](cookie)
      cookie = cookie.downcase
      @cookies.select { cookie.start_with? _1.fetch :name }
              .sort { _1.fetch(:name).size <=> _2.fetch(:name).size }
              .last
    end
  end
end
