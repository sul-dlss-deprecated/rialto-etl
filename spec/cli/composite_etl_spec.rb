# frozen_string_literal: true

require 'tmpdir'

module Rialto
  module Etl
    module CLI
      # Dummies iterates over the people in the input file CSV and for each
      # calls extract, transform, and load.
      class Dummies < CompositeEtl
        private

        def file_prefix
          'dummy'
        end

        def extractor_class
          'Rialto::Etl::Extractors::WebOfScience'
        end

        def extractor_args
          %w[first_name last_name]
        end

        def transformer_config
          'lib/rialto/etl/configs/wos_to_sparql_statements.rb'
        end
      end
    end
  end
end

RSpec.describe Rialto::Etl::CLI::Dummies do
  subject(:loader) { described_class.new([], args, conf) }

  let(:command) { described_class.all_commands['load'] }
  let(:conf) do
    {
      current_command: command,
      command_options: command.options
    }
  end
  let(:rows) do
    [
      {
        sunetid: 'vjarrett',
        first_name: 'Valerie',
        last_name: 'Jarrett',
        uri: 'http://example.com/record1',
        profileid: '123'
      }
    ]
  end

  # rubocop:disable RSpec/VerifiedDoubles
  describe '#load' do
    let(:dir) do
      Dir.mktmpdir
    end

    describe 'invocation of handler' do
      let(:args) do
        ['--input-file', 'spec/fixtures/researchers.csv', '--force']
      end

      before do
        allow(CSV).to receive(:foreach).and_return(rows)
        allow(Rialto::Etl::Workers::CompositeEtlHandler).to receive(:perform_async)
      end

      it 'hands off the hard work to the worker class' do
        loader.invoke_command(command)
        expect(Rialto::Etl::Workers::CompositeEtlHandler).to have_received(:perform_async).exactly(rows.size).times
      end
    end

    context 'with no steps skipped' do
      let(:args) do
        ['--input-file', 'spec/fixtures/researchers.csv', '--force', '--input-directory', dir, '--output-directory', dir]
      end

      before do
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double('l', load: nil))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract, transform, and load' do
        loader.invoke_command(command)
        expect(Rialto::Etl::Extractors::WebOfScience).to have_received(:new)
          .with(first_name: 'Valerie', last_name: 'Jarrett')
        expect(Rialto::Etl::Transformer).to have_received(:new).once
        expect(Rialto::Etl::Loaders::Sparql).to have_received(:new)
          .with(input: "#{dir}/dummy-123.sparql")
      end
    end

    context 'when json and sparql files already exist' do
      let(:args) do
        ['--input-file', 'spec/fixtures/researchers.csv', '--input-directory', dir, '--output-directory', dir]
      end

      before do
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double('l', load: nil))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls load' do
        loader.invoke_command(command)
        expect(Rialto::Etl::Extractors::WebOfScience).not_to have_received(:new)
          .with(first_name: 'Valerie', last_name: 'Jarrett')
        expect(Rialto::Etl::Transformer).not_to have_received(:new)
        expect(Rialto::Etl::Loaders::Sparql).to have_received(:new)
          .with(input: "#{dir}/dummy-123.sparql")
      end
    end

    context 'when load is skipped' do
      let(:args) do
        ['--input-file', 'spec/fixtures/researchers.csv', '--skip-load', '--input-directory', dir, '--output-directory', dir]
      end

      before do
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double('l', load: nil))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(false, true, false, true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract and transform' do
        loader.invoke_command(command)
        expect(Rialto::Etl::Extractors::WebOfScience).to have_received(:new)
          .with(first_name: 'Valerie', last_name: 'Jarrett')
        expect(Rialto::Etl::Transformer).to have_received(:new).once
        expect(Rialto::Etl::Loaders::Sparql).not_to have_received(:new)
      end
    end

    context 'when extract is skipped' do
      let(:args) do
        ['--input-file', 'spec/fixtures/researchers.csv', '--skip-extract', '--force',
         '--input-directory', dir, '--output-directory', dir]
      end

      before do
        allow(CSV).to receive(:foreach).and_return(rows)
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double('l', load: nil))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
        allow(File).to receive(:open).and_return(StringIO.new)
      end

      it 'calls transform and load' do
        loader.invoke_command(command)
        expect(Rialto::Etl::Extractors::WebOfScience).not_to have_received(:new)
        expect(Rialto::Etl::Transformer).to have_received(:new).once
        expect(Rialto::Etl::Loaders::Sparql).to have_received(:new).once
      end
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end
end
