# frozen_string_literal: true

RSpec.describe Rialto::Etl::ServiceClient::WebOfScienceClient do
  subject(:client) { described_class.new(institution: 'Stanford University') }

  let(:api_response) { '{}' }
  let(:publication_ranges) { ['1700-01-01+1700-12-31'] }
  let(:records_found) { 1 }

  before do
    Settings.wos.publication_ranges = publication_ranges
  end

  describe '#initialize' do
    context 'when since value is supplied' do
      subject(:client) { described_class.new(institution: 'Stanford University', since: since_value) }

      let(:since_value) { '4D' }

      before do
        client.send(:pub_range=, since_value)
      end

      it 'sets the since value' do
        expect(client.since).to eq since_value
      end

      it 'short-circuits the publication ranges' do
        expect(client.send(:publication_ranges)).to eq Array(since_value)
      end

      it 'uses the loadTimeSpan param instead of the publishTimeSpan param' do
        expect(client.send(:user_query_path)).to eq '/api/wos?databaseId=WOS&firstRecord=1&count=1' \
          '&usrQuery=OG%3DStanford+University&loadTimeSpan=4D'
      end
    end
    context 'when publication_range value is supplied' do
      subject(:client) { described_class.new(institution: 'Stanford University', publication_range: publication_range) }

      let(:publication_range) { '1800-01-01+1800-12-31' }

      it 'sets the publication_range value' do
        expect(client.publication_range).to eq publication_range
      end

      it 'short-circuits the publication ranges' do
        expect(client.send(:publication_ranges)).to eq Array(publication_range)
      end
    end
  end

  describe '#each' do
    # rubocop:disable RSpec/AnyInstance
    before do
      stub_request(:get, 'https://api.clarivate.com/api/wos?count=1&databaseId=WOS&firstRecord=1' \
        '&usrQuery=OG=Stanford%20University&publishTimeSpan=1700-01-01%2B1700-12-31')
        .to_return(status: 200, body: api_response, headers: {})

      allow(client).to receive(:query_id).and_return(123)
      allow(client).to receive(:records_found).and_return(records_found)
      allow_any_instance_of(Faraday::Request::Retry).to receive(:sleep)
    end
    # rubocop:enable RSpec/AnyInstance

    RSpec::Matchers.define_negated_matcher :not_output, :output

    context 'when connection raises an exception' do
      let(:error_message) { 'Uh oh!' }
      let(:path) { '/api/wos/query/123?firstRecord=1&count=100' }
      let(:unexpected_output_regex) { /retrying connection/ }

      before do
        stub_request(:get, 'https://api.clarivate.com/api/wos/query/123?count=100&firstRecord=1')
          .to_return(status: 501, body: error_message, headers: {})
      end

      it 'raises an exception and does not retry' do
        expect { client.each.to_a }.to raise_error(RuntimeError).and not_output(unexpected_output_regex).to_stderr
      end
    end

    context 'when connection is throttled' do
      let(:expected_output_regex) do
        /
        retrying\ connection\ \(1\ remaining\).+
        retrying\ connection\ \(0\ remaining\)
        /mx
      end

      before do
        Settings.wos.max_retries = 2
        stub_request(:get, 'https://api.clarivate.com/api/wos/query/123?count=100&firstRecord=1')
          .to_return(status: 429, body: '', headers: {})
      end

      it 'retries and writes to stderr multiple times' do
        expect { client.each.to_a }.to output(expected_output_regex).to_stderr.and raise_error(RuntimeError)
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
        expect(results).to eq ['one']
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

        expect(results).to eq %w[one two three]
      end
    end
  end
end
