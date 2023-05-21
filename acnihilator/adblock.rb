require 'uri'

class Acnihilator
  class AdBlock
    class Rule
      def initialize(rule)
        @raw = rule

        @exception     = rule.delete_prefix! '@@'
        @domain        = rule.delete_prefix! '||'
        rule, @options = rule.split '$', 2

        rule.gsub! '.', '\.'
        rule.gsub! '*', '.*'
        rule.gsub! '[', '\['
        rule.gsub! ']', '\]'
        rule.gsub! '?', '\?'

        rule.gsub! '(?:!^)|(?:!$)', '\|' # Need to avoid replacing | at start or end
        rule.gsub! '^', '(?:[^\w\d_\-.%]|$)'
        rule.sub! /^\|/, '^'
        rule.sub! /\|$/, '$'

        @rule = Regexp.new rule
      end

      def to_s
        @raw
      end

      def match?(url)
        return false if @options
        url   = URI(url).host if @domain
        match = @rule.match url
        return match ? :exception : false if @exception
        !!match
      end
    end

    def initialize
      @rules = []
    end

    def match?(url)
      matches = []
      @rules.each do |rule|
        match = rule.match? url
        return if match == :exception
        matches << rule if match
      end
      return if matches.empty?
      matches
    end

    def <<(rule)
      return if rule.start_with? '! '
      rule = Rule.new rule.chomp
      @rules << rule
      rule
    end

    def import(file)
      IO.foreach(file) { self << _1 }
    end

    def self.from(file)
      list = self.new
      list.import file
      list
    end
  end

  class TagAdblock
    def initialize(config)
      @rules = config.collect do |entry|
        rule, *tags = entry
        rule        = AdBlock::Rule.new rule
        [rule, tags.collect(&:to_sym)]
      end.to_h
    end

    def match?(url)
      matches = []
      @rules.each do |rule, tags|
        match = rule.match? url
        return if match == :exception
        matches << [rule, tags] if match
      end
      return if matches.empty?
      matches
    end
  end
end
