# frozen_string_literal: true

require 'rialto/etl/namespaces'

# rubocop:disable RSpec/DescribeClass
RSpec.describe 'geocodes_to_country_names' do
  subject(:translation_map) { Traject::TranslationMap.new('geocodes_to_country_names') }

  describe 'lookup' do
    it 'returns a preferred name before a short name' do
      expect(translation_map[Rialto::Etl::Vocabs::SWS_GEONAMES['6252001/'].to_s]).to eq('United States of America')
    end
    it 'returns a short name when no preferred name' do
      expect(translation_map[Rialto::Etl::Vocabs::SWS_GEONAMES['3932488/'].to_s]).to eq('Peru')
    end
  end
end
# rubocop:enable RSpec/DescribeClass
