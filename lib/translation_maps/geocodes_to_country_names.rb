# frozen_string_literal: true

# This requires countries.tsv. To create:
# curl http://download.geonames.org/export/dump/allCountries.zip > allCountries.zip
# unzip -p allCountries.zip | grep "\tPCLI\t" > lib/translation_maps/countries.tsv

require 'csv'

countries = {}
CSV.foreach(File.join(File.dirname(__FILE__), 'countries.tsv'), col_sep: "\t") do |row|
  geocode_id = row[0]
  country = row[1]
  countries[Rialto::Etl::Vocabs::SWS_GEONAMES["#{geocode_id}/"].to_s] = country
end
countries
