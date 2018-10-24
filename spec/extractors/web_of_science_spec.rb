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
      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos' \
          '?count=1&databaseId=WOS&firstRecord=1&usrQuery=AU=%22,%22%20AND%20OG=Stanford%20University')
          .to_return(status: 200, body: '{}', headers: {})
      end

      it 'builds a client' do
        expect(extractor.client).to be_an_instance_of(Rialto::Etl::ServiceClient::WebOfScienceClient)
      end
    end

    context 'when given an institution' do
      let(:institution) { 'Foo University' }
      let(:options) { { institution: institution } }

      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos' \
          '?count=1&databaseId=WOS&firstRecord=1&usrQuery=AU=%22,%22%20AND%20OG=Foo%20University')
          .to_return(status: 200, body: '{}', headers: {})
      end

      it 'passes the value to the client' do
        expect(extractor.client.institution).to eq institution
      end
    end

    context 'when not given an institution' do
      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos' \
          '?count=1&databaseId=WOS&firstRecord=1&usrQuery=AU=%22,%22%20AND%20OG=Stanford%20University')
          .to_return(status: 200, body: '{}', headers: {})
      end

      it 'defaults to "Stanford University"' do
        expect(extractor.client.institution).to eq described_class::DEFAULT_INSTITUTION
      end
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
