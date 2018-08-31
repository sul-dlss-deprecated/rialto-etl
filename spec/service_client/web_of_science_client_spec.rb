# frozen_string_literal: true

RSpec.describe Rialto::Etl::ServiceClient::WebOfScienceClient do
  let(:instance) do
    described_class.new(firstname: 'Russ', lastname: 'Altman', institution: 'Stanford University')
  end

  describe '#uri' do
    subject { instance.path(page: page) }

    context 'when page is 1' do
      let(:page) { 1 }

      it do
        is_expected.to eq '/api/wos?databaseId=WOK&' \
        'firstRecord=1&count=100&usrQuery=AU%3DAltman%2CRuss+AND+OG%3DStanford+University'
      end
    end
    context 'when page is 2' do
      let(:page) { 2 }

      it do
        is_expected.to eq '/api/wos?databaseId=WOK&' \
        'firstRecord=101&count=100&usrQuery=AU%3DAltman%2CRuss+AND+OG%3DStanford+University'
      end
    end
  end

  describe '#request' do
    subject { instance.request(page: 1).body }

    before do
      stub_request(:get, 'https://api.clarivate.com/api/wos?count=100&databaseId=WOK&firstRecord=1&usrQuery=AU=Altman,Russ%20AND%20OG=Stanford%20University')
        .with(
          headers: {
            'X-Apikey' => 'evendumbervalue'
          }
        )
        .to_return(status: 200, body: 'Dood', headers: {})
    end
    it { is_expected.to eq 'Dood' }
  end
end
