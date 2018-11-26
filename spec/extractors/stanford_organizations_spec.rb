# frozen_string_literal: true

RSpec.describe Rialto::Etl::Extractors::StanfordOrganizations do
  describe '#extract' do
    subject(:extractor) { described_class.new }

    let(:authz_json) do
      {
        expires_in: Time.local(*Time.now).to_i,
        access_token: 'foobar'
      }.to_json
    end

    let(:logger) { instance_double('Yell::Logger') }

    before do
      stub_request(:get, /authz.stanford.edu/)
        .to_return(status: 200, body: authz_json, headers: {})
      stub_request(:get, /api.stanford.edu/)
        .to_return(status: 200, body: 'whatever', headers: {})
    end

    it { is_expected.to respond_to(:each) }

    it 'does not raise NotImplementedError' do
      expect { extractor.each }.not_to raise_error
    end

    context 'when client raises an exception' do
      let(:error_message) { 'Uh oh!' }

      before do
        allow(extractor).to receive(:client).and_raise(error_message)
        allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
        allow(logger).to receive(:error)
      end

      it 'prints out the exception' do
        extractor.each {}
        expect(logger).to have_received(:error)
      end
    end
  end
end
