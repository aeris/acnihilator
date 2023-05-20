# Acnihilator

This tool is focused on detecting GDPR violation on website to automate later
complaint sending to national DPA

## Requirement

This tool requires:
- [Ruby 3 or later](https://www.ruby-lang.org/)
- [Bundler](https://bundler.io/)
- [Chrome headless](https://github.com/ungoogled-software/ungoogled-chromium#downloads)
- [geoipupdate](https://github.com/maxmind/geoipupdate)

Software released under [AGPLv3+](https://www.gnu.org/licenses/agpl-3.0.html) license

## Setup

To work this tool need GeoIP informations. You can get them from [maxmind](https://www.maxmind.com/). Create a free account, go to "My Account", "Manage License Keys" and create a new one.

Store this key in the file `~/.config/GeoIP.conf`:

```bash
$ cat > ~/.config/GeoIP.conf <EOF
AccountID <MaxMind account ID>
LicenseKey <MaxMind license key>
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
EOF
```

Now you can install all dependencies and download required files (geoip and easyprivacy list):

```bash
bundle install   # Install dependencies
bundle exec rake # Download geoip and easyprivacy list
```

## Usage

```bash
$ bundle exec ./acnihilator <url of the website to test>
```

## Under the hood

This script uses [Selenium](https://www.selenium.dev/) with a headless browser
to intercept all HTTP requests done on a given website.

From this collection, it tries to detect GDPR violation:

  - Usage of US services, violating [Schrems II CJEU decision](https://curia.europa.eu/juris/liste.jsf?num=C-311/18)
    - GeoIP database for IP country location
    - Whois service for organization identification
  
  - Deposit of identifying cookies without consent

  - Usage of prohibited services like reCaptcha, hCaptcha, Cloudflare, Stripe, Mailchimp…
