# frozen_string_literal: true

RSpec.describe Rialto::Etl::ServiceClient::EntityResolver do
  describe '.resolve' do
    subject(:resolve) do
      described_class.resolve('person', 'orcid_id' => '0000-0002-2328-2018', 'full_name' => 'Wilson, Jennifer L.')
    end

    context 'when the record is found' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?full_name=Wilson,%20Jennifer%20L.&orcid_id=0000-0002-2328-2018')
          .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/123')
      end
      it 'gets the URI' do
        expect(resolve).to eq 'http://sul.stanford.edu/rialto/agents/people/123'
      end
    end

    context 'when the record is not found' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?full_name=Wilson,%20Jennifer%20L.&orcid_id=0000-0002-2328-2018')
          .to_return(status: 404, body: '')
      end
      it 'returns nil' do
        expect(resolve).to be_nil
      end
    end

    # rubocop:disable Metrics/LineLength
    context 'when resolver behaves unexpectedly' do
      before do
        stub_request(:get, 'http://127.0.0.1:3001/person?full_name=Wilson,%20Jennifer%20L.&orcid_id=0000-0002-2328-2018')
          .to_return(status: 500, body: '')
      end
      it 'prints a warning' do
        expect { resolve }.to output('Error resolving with path person?orcid_id=0000-0002-2328-2018&full_name=Wilson%2C+Jennifer+L.: Entity resolver returned 500 for person type and {"orcid_id"=>"0000-0002-2328-2018", "full_name"=>"Wilson, Jennifer L."} params.' + "\n").to_stderr
      end
    end
    # rubocop:enable Metrics/LineLength
  end
end
