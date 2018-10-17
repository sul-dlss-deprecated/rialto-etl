# frozen_string_literal: true

RSpec.describe Rialto::Etl::Extractors::WebOfScience do
  describe '#each' do
    subject(:extractor) { described_class.new(options) }

    let(:options) { { firstname: 'Tom', lastname: 'Abel' } }

    context 'when client raises an exception' do
      let(:error_message) { 'Uh oh!' }
      let(:path) { 'organization?whatever+university' }
      let(:client) { instance_double(Rialto::Etl::ServiceClient::WebOfScienceClient, path: path) }

      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos?count=100&databaseId=WOS&firstRecord=1&usrQuery=AU=Abel,Tom%20AND%20OG=Stanford%20University')
          .to_return(status: 200, body: '{"Data":{"Records": { "records": {"REC": ["one", "two"]}}},'\
            '"QueryResult": {"RecordsFound": 3}}')

        allow(extractor).to receive(:client).and_return(client)
        allow(client).to receive(:request).and_raise(error_message)
      end

      it 'prints out the exception' do
        expect { extractor.each {} }.to output("Error fetching #{path}: #{error_message}\n").to_stderr
      end
    end

    # rubocop:disable RSpec/VerifiedDoubles
    context 'when connection is throttled' do
      let(:client) { double('client', request: request, path: 'foo') }
      let(:request) { double('request', success?: false, status: 429) }

      before do
        allow(extractor).to receive(:client).and_return(client)
        allow(extractor).to receive(:sleep)
        allow(extractor).to receive(:more).and_return(true, false)
      end

      it 'retries three times' do
        expect { extractor.each {} }.to output(
          "retrying connection to WebOfScience because connection is throttled. Sleeping for 1 second(s)...\n" \
            "retrying connection to WebOfScience because connection is throttled. Sleeping for 2 second(s)...\n" \
            "retrying connection to WebOfScience because connection is throttled. Sleeping for 3 second(s)...\n"
        ).to_stdout
        expect(extractor).to have_received(:sleep).exactly(3).times
      end
    end
    # rubocop:enable RSpec/VerifiedDoubles

    context 'when there is more than one page of results' do
      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos?count=2&databaseId=WOS&firstRecord=1&usrQuery=AU=Abel,Tom%20AND%20OG=Stanford%20University')
          .to_return(status: 200, body: '{"Data":{"Records": { "records": {"REC": ["one", "two"]}}},'\
            '"QueryResult": {"RecordsFound": 3}}')

        stub_request(:get, 'https://api.clarivate.com/api/wos?count=2&databaseId=WOS&firstRecord=3&usrQuery=AU=Abel,Tom%20AND%20OG=Stanford%20University')
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

    context 'when there is only one result' do
      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos?count=2&databaseId=WOS&firstRecord=1&usrQuery=AU=Abel,Tom%20AND%20OG=Stanford%20University')
          .to_return(status: 200, body: '{"Data":{"Records": { "records": {"REC": "one"}}},'\
            '"QueryResult": {"RecordsFound": 1}}')

        allow(extractor.send(:client)).to receive(:page_size).and_return(2)
      end
      it 'calls the block on single result' do
        results = []
        extractor.each do |records|
          results << records
        end
        expect(results).to eq ['"one"']
      end
    end
  end
end
