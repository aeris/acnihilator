require 'net/http'

task default: %i[geoip easyprivacy]

task :geoip do
  system 'geoipupdate', '-f', File.expand_path('~/.config/GeoIP.conf'), '-d', '.', '--verbose'
end

task :easyprivacy do
  File.write 'easyprivacy.list', Net::HTTP.get(URI 'https://easylist.to/easylist/easyprivacy.txt')
end
