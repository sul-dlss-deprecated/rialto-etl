# frozen_string_literal: true

RSpec.describe Rialto::Etl::Extractors::StanfordResearchers do
  describe '#each' do
    subject(:extractor) { described_class.new }

    let(:authz_json) do
      {
        expires_in: Time.local(*Time.now).to_i,
        access_token: 'foobar'
      }.to_json
    end

    before do
      stub_request(:get, /authz.stanford.edu/)
        .to_return(status: 200, body: authz_json, headers: {})
      stub_request(:get, 'https://api.stanford.edu/profiles/v1?p=1&ps=100')
        .to_return(status: 200, body: '{"lastPage": false, "totalPages": 2, "values":["one"]}', headers: {})
      stub_request(:get, 'https://api.stanford.edu/profiles/v1?p=2&ps=100')
        .to_return(status: 200, body: '{"lastPage": true, "totalPages": 2, "values":["two", "three"]}', headers: {})
    end

    context 'when client raises an exception' do
      let(:error_message) { 'Uh oh!' }

      before do
        allow(extractor).to receive(:client).and_raise(error_message)
      end

      it 'prints out the exception' do
        expect { extractor.each { true } }.to output("Error: #{error_message}\n").to_stderr
      end
    end

    context 'when there is more than one page of results' do
      it 'calls the block on each result' do
        results = []
        extractor.each do |records|
          results << records
        end
        expect(results).to eq %w[one two three]
      end
    end
  end
end
