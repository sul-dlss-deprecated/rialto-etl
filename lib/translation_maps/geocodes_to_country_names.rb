# frozen_string_literal: true

# This requires countries.csv.
# To create:
# curl http://download.geonames.org/export/dump/allCountries.zip > allCountries.zip
# unzip allCountries.zip
# cat allCountries.txt | csvgrep -d $'\t' -u 3 -H -c 8 -m "PCLI" | csvcut -c 1-4 | \
# tail -n +2 > lib/translation_maps/countries.csv

# This requires englishAlternateNamesV2.csv.
# To create:
# curl http://download.geonames.org/export/dump/alternateNamesV2.zip > alternateNamesV2.zip
# unzip alternateNamesV2.zip
# cat alternateNamesV2.txt | csvgrep -d $'\t' -H -u 3 -c 3 -m "en" | csvgrep -c 8 -m "1" -i | csvgrep -c 5,6 -a -m "1" | \
# tail -n +2 > englishAlternateNamesV2.csv
# csvjoin -c 1,2 -H --snifflimit 0 lib/translation_maps/countries.csv englishAlternateNamesV2.csv | \
# csvcut -c 1,7,8,9 | tail -n +2 > lib/translation_maps/country_names.csv

require 'csv'

def to_geoname(geocode_id)
  Rialto::Etl::Vocabs::SWS_GEONAMES["#{geocode_id}/"].to_s
end

countries = {}
CSV.foreach(File.join(File.dirname(__FILE__), 'country_names.csv')) do |row|
  geocode_id = row[0]
  country = row[1]
  is_preferred = row[2]
  is_short = row[3]
  # If (nothing yet and is_short) or is_preferred then set
  countries[to_geoname(geocode_id)] = country if (!countries.key?(to_geoname(geocode_id)) && is_short) || is_preferred
end
CSV.foreach(File.join(File.dirname(__FILE__), 'countries.csv')) do |row|
  geocode_id = row[0]
  country = row[1]
  # If nothing yet then set
  countries[to_geoname(geocode_id)] = country unless countries.key?(to_geoname(geocode_id))
end
countries
