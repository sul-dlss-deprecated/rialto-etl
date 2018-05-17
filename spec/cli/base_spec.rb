# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::Base do
  it 'declares a custom package name' do
    expect(described_class.instance_variable_get('@package_name')).to eq 'etl'
  end
  it 'exits on failure' do
    expect(described_class.exit_on_failure?).to be true
  end
  describe 'subcommands' do
    it 'exist' do
      expect(described_class.subcommands).to include('extract', 'transform')
    end
    describe '#extract' do
      it { is_expected.to respond_to(:extract) }
    end
    describe '#transform' do
      it { is_expected.to respond_to(:transform) }
    end
  end
end
