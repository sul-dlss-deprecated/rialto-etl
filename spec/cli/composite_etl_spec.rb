# frozen_string_literal: true

require 'tmpdir'

module Rialto
  module Etl
    module CLI
      # Publications iterates over the people in the input file CSV and for each
      # calls extract, transform, and load.
      class DummyEtl < CompositeEtl
        protected

        def file_prefix
          'dummy'
        end

        def perform_extract(row)
          results = []
          Rialto::Etl::Extractors::WebOfScience.new(firstname: row[:first_name], lastname: row[:last_name]).each do |result|
            results << result
          end
          results
        end

        def transformer_config
          'lib/rialto/etl/configs/wos_to_sparql_statements.rb'
        end
      end
    end
  end
end

RSpec.describe Rialto::Etl::CLI::DummyEtl do
  subject(:loader) { described_class.new([], args, conf) }

  let(:command) { described_class.all_commands['load'] }
  let(:conf) do
    {
      current_command: command,
      command_options: command.options
    }
  end
  let(:row) do
    {
      sunetid: 'vjarrett',
      first_name: 'Valerie',
      last_name: 'Jarrett',
      uri: 'http://example.com/record1',
      profileid: '123'
    }
  end

  describe '#load' do
    context 'with a valid transformer' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--force']
      end

      before do
        allow(CSV).to receive(:foreach).and_return([row])
        allow(Parallel).to receive(:each_with_index)
      end

      it 'calls parallel' do
        loader.invoke_command(command)
        expect(Parallel).to have_received(:each_with_index).with([row], in_processes: 1)
      end
    end
  end

  # rubocop:disable RSpec/VerifiedDoubles
  describe '#handle_row' do
    let(:dir) do
      Dir.mktmpdir
    end

    context 'with a valid transformer' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--force', '--input-directory', dir, '--output-directory', dir]
      end

      before do
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double(load: true))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract, transform, and load' do
        loader.handle_row(row, 1)
        expect(Rialto::Etl::Extractors::WebOfScience).to have_received(:new)
          .with(firstname: 'Valerie', lastname: 'Jarrett')
        expect(Rialto::Etl::Transformer).to have_received(:new).once
        expect(Rialto::Etl::Loaders::Sparql).to have_received(:new)
          .with(input: "#{dir}/dummy-123.sparql")
      end
    end
    context 'when json and sparql files already exist' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--input-directory', dir, '--output-directory', dir]
      end

      before do
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double(load: true))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls load' do
        loader.handle_row(row, 1)
        expect(Rialto::Etl::Extractors::WebOfScience).not_to have_received(:new)
          .with(firstname: 'Valerie', lastname: 'Jarrett')
        expect(Rialto::Etl::Transformer).not_to have_received(:new)
        expect(Rialto::Etl::Loaders::Sparql).to have_received(:new)
          .with(input: "#{dir}/dummy-123.sparql")
      end
    end
    context 'when load is skipped' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--skip-load', '--input-directory', dir, '--output-directory', dir]
      end

      before do
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new)
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(false, true, false, true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract and transform' do
        loader.handle_row(row, 1)
        expect(Rialto::Etl::Extractors::WebOfScience).to have_received(:new)
          .with(firstname: 'Valerie', lastname: 'Jarrett')
        expect(Rialto::Etl::Transformer).to have_received(:new).once
        expect(Rialto::Etl::Loaders::Sparql).not_to have_received(:new)
      end
    end
  end
  describe '#extract' do
    let(:dir) do
      Dir.mktmpdir
    end

    context 'when extract error occurs' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--output-directory', dir, '--input-directory', dir]
      end

      before do
        # allow(Rialto::Etl::Transformer).to receive(:new).and_raise(StandardError)
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_raise(StandardError)
      end

      it 'handles error and does not write an ndj file' do
        ndj_file = File.join(dir, 'dummy-1234.ndj')
        File.open(ndj_file, 'w') { |file| file.write('test') }
        expect(File).to be_exist(ndj_file)
        expect(loader.send(:extract, row, '1234', true)).to eq(ndj_file)
        expect(File).not_to be_exist(ndj_file)
        expect(Rialto::Etl::Extractors::WebOfScience).to have_received(:new)
          .with(firstname: 'Valerie', lastname: 'Jarrett')
      end
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles
end
