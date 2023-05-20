# Acnihilator

This tool is focused on detecting GDPR violation on website to automate later
complaint sending to national DPA

## Requirement

Ruby 3 or later
Chrome headless (used by Selenium)

Software released under [AGPLv3+](https://www.gnu.org/licenses/agpl-3.0.html) license

## Setup

Get a GeoIP MaxMind free license [https://www.maxmind.com/en/account/login](here).

```bash
$ cat > ~/.config/GeoIP.conf <EOF
AccountID <MaxMind account ID>
LicenseKey <MaxMind license key>
EditionIDs GeoLite2-ASN GeoLite2-City GeoLite2-Country
EOF
$ bundle install
$ bundle exec rake
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
