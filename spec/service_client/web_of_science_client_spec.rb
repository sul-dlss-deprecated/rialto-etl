# frozen_string_literal: true

RSpec.describe Rialto::Etl::ServiceClient::WebOfScienceClient do
  subject(:client) { described_class.new(institution: 'Stanford University') }

  let(:api_response) { '{}' }
  let(:publication_ranges) { ['1700-01-01+1700-12-31'] }
  let(:records_found) { 1 }

  # rubocop:disable RSpec/AnyInstance
  before do
    stub_request(:get, 'https://api.clarivate.com/api/wos?count=1&databaseId=WOS&firstRecord=1' \
      '&usrQuery=OG=Stanford%20University&publishTimeSpan=1700-01-01%2B1700-12-31')
      .to_return(status: 200, body: api_response, headers: {})

    allow(client).to receive(:query_id).and_return(123)
    allow(client).to receive(:records_found).and_return(records_found)
    allow(client).to receive(:publication_ranges).and_return(publication_ranges)
    allow_any_instance_of(Faraday::Request::Retry).to receive(:sleep)
  end
  # rubocop:enable RSpec/AnyInstance

  describe '#each' do
    context 'when connection raises an exception' do
      let(:error_message) { 'Uh oh!' }
      let(:path) { '/api/wos/query/123?firstRecord=1&count=100' }

      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos/query/123?count=100&firstRecord=1')
          .to_return(status: 500, body: error_message, headers: {})
      end

      it 'raises an exception' do
        expect { client.each {} }.to raise_error(RuntimeError)
      end
    end

    context 'when connection is throttled' do
      let(:expected_output_regex) do
        /
        retrying\ connection\ \(5\ remaining\).+
        retrying\ connection\ \(4\ remaining\).+
        retrying\ connection\ \(3\ remaining\).+
        retrying\ connection\ \(2\ remaining\).+
        retrying\ connection\ \(1\ remaining\).+
        retrying\ connection\ \(0\ remaining\)
        /mx
      end

      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos/query/123?count=100&firstRecord=1')
          .to_return(status: 429, body: '', headers: {})
      end

      it 'retries and writes to stderr multiple times' do
        expect { client.each {} }.to output(expected_output_regex).to_stderr.and raise_error(RuntimeError)
      end
    end

    context 'when there is only one result' do
      let(:api_response) { '{"Records": { "records": {"REC": "one"}},"QueryResult": {"RecordsFound": 1}}' }

      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos/query/123?count=100&firstRecord=1')
          .to_return(status: 200, body: api_response, headers: {})
      end

      it 'calls the block on single result' do
        results = client.each.to_a
        expect(results).to eq [['one']]
      end
    end

    context 'when there is more than one page of results' do
      let(:api_response) { '{"Records": { "records": {"REC": ["one", "two"]}},"QueryResult": {"RecordsFound": 3}}' }
      let(:api_response2) { '{"Records": { "records": {"REC": ["three"]}},"QueryResult": {"RecordsFound": 3}}' }
      let(:records_found) { 3 }

      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos/query/123?count=2&firstRecord=1')
          .to_return(status: 200, body: api_response, headers: {})

        stub_request(:get, 'https://api.clarivate.com/api/wos/query/123?count=2&firstRecord=3')
          .to_return(status: 200, body: api_response2, headers: {})

        allow(client).to receive(:page_size).and_return(2)
      end

      it 'calls the block on each result' do
        results = client.each.to_a

        expect(results).to eq [%w[one two], ['three']]
      end
    end
  end
end
