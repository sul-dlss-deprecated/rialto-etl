# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::TransformDirectory do
  subject(:transformer) { described_class.new }

  describe '#call' do
    let(:transformer_name) { 'FooBar' }
    let(:mock_transformer_instance) { instance_double(Rialto::Etl::Transformer) }

    context 'with a valid transformer' do
      before do
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(mock_transformer_instance)
        allow(transformer).to receive(:configs).and_return('FooBar' => 'path/to/config.rb')
        allow(transformer).to receive(:options).and_return(input_directory: 'spec/fixtures/grants/grouped_by_sunetid',
                                                           output_directory: Dir.tmpdir)
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

    context 'with an invalid transformer' do
      it 'outputs a message' do
        expect { transformer.call('Unknown') }.to raise_error(SystemExit)
          .and output(/^No 'Unknown' transformer exists./).to_stderr
      end
    end
  end

  describe '#list' do
    it 'prints out callable configs' do
      allow(transformer).to receive(:say)
      transformer.list
      expect(transformer).to have_received(:say)
        .with('Transformers supported: StanfordGrants')
    end
  end
end
