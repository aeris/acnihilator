require 'selenium-webdriver'
require 'resolv'
require 'uri'
require 'public_suffix'
require 'colorize'
require 'logger'
require 'yaml'
require 'json'
require 'ostruct'

class Acnihilator
  LOGGER = Logger.new STDOUT, level: Logger::INFO,
                      formatter:     proc { |*_, msg| msg + "\n" }

  DNS      = 'ns0.fdn.fr'

  def LOGGER.process(text)
    self.info (text + '…').colorize :yellow
    yield
    self.info 'Done'.colorize :green
  end

  def self.selenium(...)
    Analysis.from_web(...)
  end
end

require './acnihilator/analysis'
