# frozen_string_literal: true

def extract_orgs(org)
  orgs = {}
  org['orgCodes'].each { |org_code| orgs[org_code] = org['alias'] }
  org['children'].each { |child_org| orgs.merge!(extract_orgs(child_org)) } if org.key?('children')
  orgs
end

organizations_filepath = nil
# Look in $LOAD_PATH/translation_maps. This is primarily useful to testing.
$LOAD_PATH.each do |base_filepath|
  possible_filepath = File.join(base_filepath, %w[translation_maps organizations.json])
  if File.exist?(possible_filepath)
    organizations_filepath = possible_filepath
    break
  end
end

# Requires that organizations.json exists.
extract_orgs(JSON.parse(File.read(organizations_filepath || 'organizations.json')))
