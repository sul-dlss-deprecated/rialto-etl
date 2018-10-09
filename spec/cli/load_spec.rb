# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::Load do
  subject(:loader) { described_class.new }

  describe '#call' do
    let(:loader_name) { 'FooBar' }
    let(:mock_loader_class) { double }
    let(:mock_loader_instance) { double }

    before do
      allow(Rialto::Etl::Loaders).to receive(:const_get).with(loader_name).and_return(mock_loader_class)
      allow(mock_loader_class).to receive(:new).and_return(mock_loader_instance)
    end

    context 'with missing name argument' do
      it 'raises ArgumentError when called without args' do
        expect { loader.call }.to raise_error(ArgumentError)
      end
    end

    it 'calls a loader' do
      allow(mock_loader_instance).to receive(:load)
      loader.call(loader_name)
      expect(mock_loader_instance).to have_received(:load).once
    end
  end

  describe '#list' do
    it 'prints out callable loaders' do
      allow(loader).to receive(:say)
      loader.list
      expect(loader).to have_received(:say).with('Loaders supported: Sns, Sparql')
    end
  end
end
