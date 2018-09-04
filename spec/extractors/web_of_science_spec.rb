# frozen_string_literal: true

RSpec.describe Rialto::Etl::Extractors::WebOfScience do
  describe '#each' do
    subject(:extractor) { described_class.new(options) }

    let(:options) { { firstname: 'Tom', lastname: 'Abel' } }

    context 'when client raises an exception' do
      let(:error_message) { 'Uh oh!' }

      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos?count=100&databaseId=WOS&firstRecord=1&usrQuery=AU=,%20AND%20OG=Stanford%20University')
          .to_return(status: 200, body: '{"Data":{"Records": { "records": {"REC": ["one", "two"]}}},'\
            '"QueryResult": {"RecordsFound": 3}}')

        allow(extractor).to receive(:client).and_raise(error_message)
      end

      it 'prints out the exception' do
        expect { extractor.each {} }.to output("Error: #{error_message}\n").to_stderr
      end
    end

    context 'when there is more than one page of results' do
      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos?count=2&databaseId=WOS&firstRecord=1&usrQuery=AU=,%20AND%20OG=Stanford%20University')
          .to_return(status: 200, body: '{"Data":{"Records": { "records": {"REC": ["one", "two"]}}},'\
            '"QueryResult": {"RecordsFound": 3}}')

        stub_request(:get, 'https://api.clarivate.com/api/wos?count=2&databaseId=WOS&firstRecord=3&usrQuery=AU=,%20AND%20OG=Stanford%20University')
          .to_return(status: 200, body: '{"Data":{"Records": { "records": {"REC": ["three"]}}},'\
            '"QueryResult": {"RecordsFound": 3}}')

        allow(extractor.send(:client)).to receive(:page_size).and_return(2)
      end
      it 'calls the block on each result' do
        results = []
        extractor.each do |records|
          results << records
        end
        # rubocop:disable Lint/PercentStringArray
        expect(results).to eq %w["one" "two" "three"]
        # rubocop:enable Lint/PercentStringArray
      end
    end
  end
end
