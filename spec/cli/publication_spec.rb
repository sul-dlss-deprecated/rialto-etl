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
        ['--input-file', 'data/researchers.csv']
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
        allow(loader).to receive(:system)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract, transform, and load' do
        loader.invoke_command(command)
        expect(loader).to have_received(:system)
          .with('exe/extract call WebOfScience --firstname Valerie --lastname Jarrett > data/123.ndj')
        expect(loader).to have_received(:system)
          .with('exe/transform call WebOfScience -i data/123.ndj > data/123.sparql')
        expect(loader).to have_received(:system)
          .with('exe/load call Sparql -i data/123.sparql')
      end
    end
    context 'when json and sparql files already exist' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--skip-existing']
      end

      before do
        allow(CSV).to receive(:foreach).and_yield(row)
        allow(loader).to receive(:system)
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls load' do
        loader.invoke_command(command)
        expect(loader).not_to have_received(:system)
          .with('exe/extract call WebOfScience --firstname Valerie --lastname Jarrett > data/123.ndj')
        expect(loader).not_to have_received(:system)
          .with('exe/transform call WebOfScience -i data/123.ndj > data/123.sparql')
        expect(loader).to have_received(:system)
          .with('exe/load call Sparql -i data/123.sparql')
      end
    end
    context 'when load is skipped' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--skip-load']
      end

      before do
        allow(CSV).to receive(:foreach).and_yield(row)
        allow(loader).to receive(:system)
        allow(File).to receive(:exist?).and_return(false)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract and transform' do
        loader.invoke_command(command)
        expect(loader).to have_received(:system)
          .with('exe/extract call WebOfScience --firstname Valerie --lastname Jarrett > data/123.ndj')
        expect(loader).to have_received(:system)
          .with('exe/transform call WebOfScience -i data/123.ndj > data/123.sparql')
        expect(loader).not_to have_received(:system)
          .with('exe/load call Sparql -i data/123.sparql')
      end
    end
  end
end
