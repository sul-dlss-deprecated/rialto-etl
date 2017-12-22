# frozen_string_literal: true

RSpec.describe Rialto::Etl::Extractors::StanfordResearchers do
  describe 'subclass' do
    it { is_expected.to be_a Rialto::Etl::Extractors::AbstractStanfordExtractor }
  end

  describe '#extract' do
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
      stub_request(:get, /api.stanford.edu/)
        .to_return(status: 200, body: 'whatever', headers: {})
    end

    it { is_expected.to respond_to(:extract) }

    it 'does not raise NotImplementedError' do
      expect { extractor.extract }.not_to raise_error
    end

    context 'when client raises an exception' do
      let(:error_message) { 'Uh oh!' }

      before do
        allow(extractor).to receive(:client).and_raise(error_message)
      end

      it 'prints out the exception' do
        allow(STDOUT).to receive(:puts)
        extractor.extract
        expect(STDOUT).to have_received(:puts).with("Error: #{error_message}")
      end
    end
  end
end
