# frozen_string_literal: true

RSpec.describe Rialto::Etl::Extractors::WebOfScience do
  subject(:extractor) { described_class.new(options) }

  let(:options) { {} }

  describe '#initialize' do
    context 'when given a client' do
      let(:client) { double }
      let(:options) { { client: client } }

      it 'uses the supplied client' do
        expect(extractor.client).to eq client
      end
    end

    context 'when not given a client' do
      it 'builds a client' do
        expect(extractor.client).to be_an_instance_of(Rialto::Etl::ServiceClient::WebOfScienceClient)
      end
    end

    context 'when given an institution' do
      let(:institution) { 'Foo University' }
      let(:options) { { institution: institution } }

      it 'passes the value to the client' do
        expect(extractor.client.institution).to eq institution
      end
    end

    context 'when not given an institution' do
      it 'defaults to "Stanford University"' do
        expect(extractor.client.institution).to eq described_class::DEFAULT_INSTITUTION
      end
    end
  end

  context 'when given a since value' do
    let(:since) { '2M' }
    let(:options) { { since: since } }

    it 'passes the value to the client' do
      expect(extractor.client.since).to eq since
    end
  end

  context 'when not given an since' do
    it 'passes nil to the client ' do
      expect(extractor.client.since).to be nil
    end
  end

  describe '#each' do
    let(:client) do
      [
        { key1: 'value1' },
        { key2: 'value2' }
      ]
    end
    let(:options) { { client: client } }

    it 'iterates over client results and coerces to JSON' do
      expect { |b| extractor.each(&b) }.to yield_successive_args('{"key1":"value1"}',
                                                                 '{"key2":"value2"}')
    end
  end
end
