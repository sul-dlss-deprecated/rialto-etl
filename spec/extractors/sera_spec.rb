# frozen_string_literal: true

RSpec.describe Rialto::Etl::Extractors::Sera do
  before do
    Settings.sera.token_url = 'https://aswsuat.stanford.edu/api/oauth/token'
    Settings.sera.service_url = 'https://aswsuat.stanford.edu'
  end

  let(:token_response) do
    '{"access_token":"ABCD123","token_type":"Bearer","expires_in":3599,"scope":"sera.public sera.stanford-only"}'
  end

  describe '#each' do
    subject(:extractor) { described_class.new(options) }

    let(:options) { { sunetid: 'altman' } }

    context 'when client raises an exception' do
      before do
        stub_request(:post, 'https://aswsuat.stanford.edu/api/oauth/token')
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: token_response)
        stub_request(:get, 'https://aswsuat.stanford.edu/mais/sera/v1/api?scope=sera.stanford-only&sunetId=altman')
          .to_return(status: 401, body: '', headers: {})
        # allow(extractor).to receive(:client).and_raise(error_message)
      end

      it 'raises the exception' do
        expect { extractor.each {} }.to raise_error(Rialto::Etl::Extractors::Sera::ConnectionError,
                                                    /There was a problem with the request/)
      end
    end

    context 'when it returns results' do
      let(:body) do
        '{"SeRARecord": [{"spoNumber":"118753", "projectTitle":"Cookies are delicious",' \
        '"piSunetId": "jcoyne85", "piFullName":"Coyne, Justin", "projectStatus":"Awarded",' \
        '"projectStartDate":"2015-05-01T00:00:00.000-07:00", ' \
        '"projectEndDate":"2016-04-30T00:00:00.000-07:00", ' \
        '"edwCreateDateTime":"2015-08-18T04:18:01.000-07:00", ' \
        '"edwUpdateDateTime":"2015-08-18T04:18:01.000-07:00"}]}'
      end

      before do
        stub_request(:post, 'https://aswsuat.stanford.edu/api/oauth/token')
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                     body: token_response)

        stub_request(:get, 'https://aswsuat.stanford.edu/mais/sera/v1/api?scope=sera.stanford-only&sunetId=altman')
          .with(headers: { 'Authorization' => 'Bearer ABCD123' })
          .to_return(status: 200, body: body, headers: {})
        allow(extractor.send(:client)).to receive(:page_size).and_return(2)
      end
      it 'calls the block on each result' do
        results = []
        extractor.each do |records|
          results << records
        end
        expect(JSON.parse(results[0])['spoNumber']).to eq '118753'
      end
    end

    context 'when it returns a 404' do
      before do
        stub_request(:post, 'https://aswsuat.stanford.edu/api/oauth/token')
          .to_return(status: 200, headers: { 'Content-Type' => 'application/json' },
                     body: token_response)

        stub_request(:get, 'https://aswsuat.stanford.edu/mais/sera/v1/api?scope=sera.stanford-only&sunetId=altman')
          .with(headers: { 'Authorization' => 'Bearer ABCD123' })
          .to_return(status: 404, body: '', headers: {})
        allow(extractor.send(:client)).to receive(:page_size).and_return(2)
      end
      it 'calls the block on each result' do
        results = []
        extractor.each do |records|
          results << records
        end
        expect(results.size).to eq 0
      end
    end
  end
end
