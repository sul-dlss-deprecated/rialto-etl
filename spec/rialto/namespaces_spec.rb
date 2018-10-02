# frozen_string_literal: true

require 'rdf'
require 'rialto/etl/namespaces'

RSpec.describe Rialto::Etl::Vocabs do
  include described_class

  describe 'remove_vocab_from_uri' do
    let(:person_uri) { described_class::RIALTO_PEOPLE['123'] }

    let(:vocab) { described_class::RIALTO_PEOPLE }

    it 'removes vocab prefix' do
      expect(remove_vocab_from_uri(vocab, person_uri)).to eq('123')
    end
  end
end
