# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::ErrorReporter do
  describe '.log_exception' do
    before do
      allow(Honeybadger).to receive(:notify)
      allow($stderr).to receive(:puts)
    end

    it 'logs the message' do
      described_class.log_exception('There was a problem')
      expect(Honeybadger).to have_received(:notify)
      expect($stderr).to have_received(:puts)
    end
  end
end
