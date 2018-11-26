# frozen_string_literal: true

# To create:
# curl http://download.geonames.org/export/dump/allCountries.zip > allCountries.zip
# unzip allCountries.zip
# cat allCountries.txt | csvgrep -d $'\t' -u 3 -H -c 8 -m "PCLI" | csvcut -c 1-4 | tail -n +2 > lib/translation_maps/countries.csv

require 'csv'

countries = {}
CSV.foreach(File.join(File.dirname(__FILE__), 'countries.csv')) do |row|
  geocode_id = row[0]
  # Name
  countries[row[1].downcase] = geocode_id
  # Ascii name
  countries[row[2].downcase] = geocode_id
  # Alternate names
  row[3].split(/,/).each { |name| countries[name.downcase] = geocode_id }
end
countries
