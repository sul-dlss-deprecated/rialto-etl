# frozen_string_literal: true

RSpec.describe Rialto::Etl::Logging do
  include described_class

  describe 'info_log' do
    it 'provides a default path to the info log file' do
      expect(info_log).to eq('./log/rialto_etl.log')
    end
  end

  describe 'error_log' do
    it 'provides a default path to the info log file' do
      expect(error_log).to eq('./log/rialto_etl_error.log')
    end
  end
end
