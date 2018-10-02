# frozen_string_literal: true

require 'rdf'
require 'rialto/etl/namespaces'

RSpec.describe Rialto::Etl::Vocabs do
  describe '.remove_from_uri' do
    let(:person_uri) { Rialto::Etl::Vocabs::RIALTO_PEOPLE['123'] }

    it 'removes vocab prefix' do
      expect(Rialto::Etl::Vocabs::RIALTO_PEOPLE.remove_from_uri(person_uri)).to eq('123')
    end
  end
end
