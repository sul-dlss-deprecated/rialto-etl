# frozen_string_literal: true

describe Rialto::Etl do
  it 'has a version number' do
    expect(Rialto::Etl::VERSION).not_to be nil
  end

  describe 'configuration' do
    it 'provides a configuration value for CAP token' do
      expect(Settings.tokens.cap).not_to be_empty
    end

    describe 'overriding values via environment variables' do
      let(:overridden_value) { 'dropthebeat' }

      before do
        ENV['SETTINGS__TOKENS__CAP'] = overridden_value
        Settings.reload!
      end

      it 'works as configured' do
        expect(Settings.tokens.cap).to eq overridden_value
      end
    end
  end
end
