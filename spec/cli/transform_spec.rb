# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::Transform do
  subject(:transformer) { described_class.new }

  describe '#call' do
    let(:transformer_name) { 'FooBar' }
    let(:mock_transformer_class) { double }
    let(:mock_transformer_instance) { double }

    before do
      allow(Rialto::Etl::Transformers).to receive(:const_get).with(transformer_name).and_return(mock_transformer_class)
      allow(mock_transformer_class).to receive(:new).and_return(mock_transformer_instance)
    end

    context 'with missing name argument' do
      it 'raises ArgumentError when called without args' do
        expect { transformer.call }.to raise_error(ArgumentError)
      end
    end

    it 'calls a transformer' do
      allow(mock_transformer_instance).to receive(:transform)
      transformer.call(transformer_name)
      expect(mock_transformer_instance).to have_received(:transform).once
    end
  end

  describe '#list' do
    it 'prints out callable transformers' do
      allow(transformer).to receive(:say)
      transformer.list
      expect(transformer).to have_received(:say).with(/StanfordOrganizationsToVivo, StanfordOrganizationsToJsonList/)
    end
  end
end
