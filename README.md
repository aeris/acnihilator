# Acnihilator

This tool is focused on detecting GDPR violation on website to automate later
complaint sending to national DPA

## Requirement

Ruby 3 or later
Chrome headless (used by Selenium)

Software released under [AGPLv3+](https://www.gnu.org/licenses/agpl-3.0.html)
license

## Setup

Get a GeoIP MaxMind free
license [https://www.maxmind.com/en/account/login](here).

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
$ bundle exec ./bin/acnihilator inspect <url of the website to test>
```

## Dockerized version

In a blank folder, put the GeoIP.conf file as described above with your MaxMind credentials.

Then within this folder, run the following command, replacing the last part with the full URL of the website you want to test :
```bash
$ docker run -v ./GeoIP.conf:/Rails-Docker/.config/GeoIP.conf -v ./reports/:/Rails-Docker/reports ghcr.io/sharkoz/acnihilator:master /bin/sh -c "bundle exec rake ; bundle exec ./bin/acnihilator inspect <url of the website to test>"
```
Results are visible in the "results" folder created by the script.

Or clone only the "run.sh" file of this repository, make it executable and run it like that :
```bash
$ chmod +x run.sh
$ ./run.sh https://www.ssi.gouv.fr
```

## Under the hood

This script uses [Selenium](https://www.selenium.dev/) with a headless browser
to intercept all HTTP requests done on a given website.

From this collection, it tries to detect GDPR violation:

- Usage of US services, violating
  [Schrems II CJEU decision](https://curia.europa.eu/juris/liste.jsf?num=C-311/18)
    - GeoIP database for IP country location
    - Whois service for organization identification

- Deposit of identifying cookies without consent

- Usage of prohibited services like reCaptcha, hCaptcha, Cloudflare, Stripe,
  Mailchimp…
