# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::Publications do
  subject(:loader) { described_class.new([], args, conf) }

  let(:command) { described_class.all_commands['load'] }
  let(:conf) do
    {
      current_command: command,
      command_options: command.options
    }
  end

  # rubocop:disable RSpec/VerifiedDoubles
  describe '#load' do
    let(:row) do
      {
        sunetid: 'vjarrett',
        first_name: 'Valerie',
        last_name: 'Jarrett',
        uri: 'http://example.com/record1',
        profileid: '123'
      }
    end

    context 'with a valid transformer' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--force']
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

      before do
        allow(CSV).to receive(:foreach).and_yield(row)
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double(load: true))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract, transform, and load' do
        loader.invoke_command(command)
        expect(Rialto::Etl::Extractors::WebOfScience).to have_received(:new)
          .with(firstname: 'Valerie', lastname: 'Jarrett')
        expect(Rialto::Etl::Transformer).to have_received(:new).once
        expect(Rialto::Etl::Loaders::Sparql).to have_received(:new)
          .with(input: 'data/123.sparql')
      end
    end
    context 'when json and sparql files already exist' do
      let(:args) do
        ['--input-file', 'data/researchers.csv']
      end

      before do
        allow(CSV).to receive(:foreach).and_yield(row)
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double(load: true))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls load' do
        loader.invoke_command(command)
        expect(Rialto::Etl::Extractors::WebOfScience).not_to have_received(:new)
          .with(firstname: 'Valerie', lastname: 'Jarrett')
        expect(Rialto::Etl::Transformer).not_to have_received(:new)
        expect(Rialto::Etl::Loaders::Sparql).to have_received(:new)
          .with(input: 'data/123.sparql')
      end
    end
    context 'when load is skipped' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--skip-load']
      end

      before do
        allow(CSV).to receive(:foreach).and_yield(row)
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new)
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::WebOfScience).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(false, true, false, true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract and transform' do
        loader.invoke_command(command)
        expect(Rialto::Etl::Extractors::WebOfScience).to have_received(:new)
          .with(firstname: 'Valerie', lastname: 'Jarrett')
        expect(Rialto::Etl::Transformer).to have_received(:new).once
        expect(Rialto::Etl::Loaders::Sparql).not_to have_received(:new)
      end
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end
end
