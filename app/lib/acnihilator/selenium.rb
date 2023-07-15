require 'shellwords'

class Acnihilator
  class Selenium
    USER_AGENT = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/114.0.0.0 Safari/537.36'

    def initialize(url, wait = 10)
      self.do_in_browser do |driver|
        LOGGER.process 'Collecting urls' do
          @urls = []
          driver.intercept do |request, &continue|
            @urls << (url = request.url)
            LOGGER.debug '  ' + url if LOGGER.debug?
            continue.call request
          end
          driver.get url
          if wait
            LOGGER.info "  Waiting #{wait}s, because trackers are evils…"
            sleep wait
          end
          LOGGER.info "  #{@urls.size.to_s.colorize :blue} URLs collected"
        end
        LOGGER.process 'Collecting cookies' do
          @cookies = driver.manage.all_cookies
          LOGGER.info "  #{@cookies.size.to_s.colorize :blue} cookies collected"
        end
        LOGGER.process 'Take screenshot' do
          @screenshot = driver.screenshot_as :png, full_page: false
        end
      end
    end

    def to_h
      {
        urls: @urls,
        cookies: @cookies,
        screenshot: @screenshot
      }
    end

    private

    def do_in_browser
      args = %W[
        --headless
        --user-agent=#{USER_AGENT}
      ]
      if (env_args = ENV['SELENIUM_ARGS'])
        args += env_args.shellsplit
      end
      options = {
        local_state: {
          "dns_over_https.mode": 'secure',
          "dns_over_https.templates": "https://#{Acnihilator::DNS}/dns-query",
        }, args: args
      }
      options = ::Selenium::WebDriver::Chrome::Options.new **options
      driver = ::Selenium::WebDriver.for :chrome, options: options
      begin
        driver.manage.window.resize_to 1920, 1080
        driver.manage.delete_all_cookies
        yield driver
      ensure
        driver.quit
      end
    end
  end
end
