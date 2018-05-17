# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI do
  describe '.start' do
    it 'delegates to the Base class' do
      allow(Rialto::Etl::CLI::Base).to receive(:start)
      described_class.start
      expect(Rialto::Etl::CLI::Base).to have_received(:start).once
    end
  end
end
