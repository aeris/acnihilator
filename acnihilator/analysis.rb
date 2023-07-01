class Analysis
  include Mongoid::Document
  field :url, type: String
  field :urls, type: Array
  field :domains, type: Array
  field :cookies, type: Array
  field :violations, type: Hash
  field :screenshot, type: BSON::Binary
  field :date, type: DateTime, default: Time.now
end
