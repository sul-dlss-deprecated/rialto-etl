# frozen_string_literal: true

RSpec.describe Rialto::Etl::ServiceClient::StanfordClient do
  before do
    stub_request(:get, /authz.stanford.edu/)
      .to_return(status: authz_status, body: authz_json, headers: {})
    stub_request(:get, /api.stanford.edu/)
      .to_return(status: 200, body: 'whatever', headers: {})
  end

  let(:access_token) { 'foobar' }
  let(:authz_json) do
    {
      expires_in: current_time,
      access_token: access_token
    }.to_json
  end
  let(:authz_status) { 200 }
  let(:current_time) { Time.local(*Time.now).to_i }

  it { is_expected.to respond_to(:access_token_expiry_time) }

  describe '#client' do
    subject(:client) { described_class.new.send(:client) }

    it 'returns an http connection' do
      expect(client).to be_a Faraday::Connection
    end

    it 'connects to api.stanford.edu' do
      expect(client.host).to eq 'api.stanford.edu'
    end

    describe 'headers' do
      subject { client.headers }

      it { is_expected.to include('Authorization' => "Bearer #{access_token}") }
      it { is_expected.to include('Accept' => 'application/json', 'Content-Type' => 'application/json') }
    end
  end

  describe '#access_token' do
    let(:extractor) { described_class.new }
    let(:expired) { true }

    before do
      allow(extractor).to receive(:token_expired?).and_return(expired)
      allow(extractor).to receive(:reset_access_token!)
    end

    context 'when expired' do
      it 'resets the access token if expired' do
        extractor.send(:access_token)
        expect(extractor).to have_received(:reset_access_token!).once
      end
    end

    context 'when not expired' do
      let(:expired) { false }

      it 'creates a new access token' do
        expect(extractor.send(:access_token)).to eq "Bearer #{access_token}"
      end

      context 'when client returns something other than 200' do
        let(:authz_status) { 401 }

        it 'raises an exception' do
          expect { extractor.send(:access_token) }.to raise_error('Failed to authenticate')
        end
      end

      context 'when already set' do
        let(:token_value) { 'foo' }

        before do
          extractor.instance_variable_set(:@access_token, token_value)
        end

        it 'uses existing access token if not expired' do
          expect(extractor.send(:access_token)).to eq token_value
        end
      end
    end
  end

  describe '#auth_code' do
    subject(:code) { described_class.new.send(:auth_code) }

    it { is_expected.to eq Settings.cap.api_key }
  end

  describe '#get' do
    subject(:extractor) { described_class.new }

    it 'does not raise NotImplementedError' do
      expect(extractor.get('/path')).to eq 'whatever'
    end
  end
end
