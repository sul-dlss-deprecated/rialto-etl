# frozen_string_literal: true

# This requires countries.tsv. To create:
# curl http://download.geonames.org/export/dump/allCountries.zip > allCountries.zip
# unzip -p allCountries.zip | grep "\tPCLI\t" > lib/translation_maps/countries.tsv

require 'csv'

countries = {}
CSV.foreach(File.join(File.dirname(__FILE__), 'countries.tsv'), col_sep: "\t") do |row|
  geocode_id = row[0]
  # Name
  countries[row[1].downcase] = geocode_id
  # Ascii name
  countries[row[2].downcase] = geocode_id
  # Alternate names
  row[3].split(/,/).each { |name| countries[name.downcase] = geocode_id }
end
countries
