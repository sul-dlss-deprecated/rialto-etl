# frozen_string_literal: true

RSpec.describe Rialto::Etl::Transformers::StanfordOrganizationsToVivo do
  subject(:transformer) { described_class.new(input: input) }

  let(:input) { '' }

  describe '#input' do
    it { is_expected.to respond_to(:input) }

    it 'returns the value of the passed-in attr' do
      expect(transformer.input).to eq input
    end
  end

  describe '#transform' do
    before do
      allow(transformer).to receive(:transformer).and_return(indexer)
      allow(File).to receive(:open).and_yield(input)
    end

    let(:indexer) { instance_double(Traject::Indexer) }

    it 'passes input to the indexer' do
      allow(indexer).to receive(:process)
      transformer.transform
      expect(indexer).to have_received(:process).with(input).once
    end
  end
end