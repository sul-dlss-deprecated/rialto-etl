# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::Grants do
  subject(:loader) { described_class.new([], ['--input-file', 'sunetids.json'], conf) }

  let(:command) { described_class.all_commands['load'] }
  let(:conf) do
    {
      current_command: command,
      command_options: command.options
    }
  end
  let(:extractor) { double }
  let(:results) do
    [
      '{"spoNumber": "12345","piSunetId":"mjgiarlo"}',
      '{"spoNumber": "67890","piSunetId":"mjgiarlo"}'
    ]
  end

  describe '#load' do
    let(:json) { '{"sunetid":"mjgiarlo"}' }

    before do
      allow(File).to receive(:open).and_yield(json)
      allow(Parallel).to receive(:map).and_yield(results)
      allow(loader).to receive(:extract_and_write).and_return(results)
    end

    it 'uses Parallel to return results' do
      loader.invoke_command(command)
      expect(File).to have_received(:open).with('sunetids.json', 'r')
      expect(Parallel).to have_received(:map).once
      expect(loader).to have_received(:extract_and_write).once
    end
  end

  describe '#extract_and_write' do
    let(:client) { double }
    let(:output_file) { 'data/mjgiarlo.json' }
    let(:id) { 'mjgiarlo' }
    let(:writer) { double }

    before do
      allow(client).to receive(:each).and_yield(results)
      allow(Rialto::Etl::Extractors::Sera).to receive(:new).and_return(client)
      allow(writer).to receive(:write)
      allow(File).to receive(:open).and_yield(writer)
    end

    context 'with results' do
      it 'writes to a file' do
        loader.send(:extract_and_write, id, output_file)
        expect(File).to have_received(:open).with(output_file, 'w')
        expect(writer).to have_received(:write).with(results.join("\n"))
      end
    end

    context 'with no results' do
      let(:results) { [] }

      before do
        allow(client).to receive(:each)
      end

      it 'no-ops' do
        loader.send(:extract_and_write, id, output_file)
        expect(File).not_to have_received(:open)
        expect(writer).not_to have_received(:write)
      end
    end
  end
end
