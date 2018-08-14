# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::Extract do
  subject(:extractor) { described_class.new }

  # rubocop:disable RSpec/VerifiedDoubles
  describe '#call' do
    let(:extractor_name) { 'FooBar' }
    let(:mock_extractor_class) { double(new: mock_extractor_instance) }
    let(:mock_extractor_instance) { double }

    before do
      allow(Rialto::Etl::Extractors).to receive(:const_get).with(extractor_name).and_return(mock_extractor_class)
    end

    it 'raises ArgumentError when called without args' do
      expect { extractor.call }.to raise_error(ArgumentError)
    end
    it 'calls an extractor' do
      allow(mock_extractor_instance).to receive(:each)
      extractor.call(extractor_name)
      expect(mock_extractor_instance).to have_received(:each).once
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles

  describe '#list' do
    it 'prints out callable extractors' do
      allow(extractor).to receive(:say)
      extractor.list
      expect(extractor).to have_received(:say).with(/StanfordOrganizations, StanfordResearchers/)
    end
    it 'omits non-callable extractors' do
      allow(extractor).to receive(:say)
      extractor.list
      expect(extractor).not_to have_received(:say).with(/Abstract/)
    end
  end
end
