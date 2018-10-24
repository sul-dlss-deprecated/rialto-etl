# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::Grants do
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

  # rubocop:disable RSpec/VerifiedDoubles
  describe '#handle_row' do
    let(:dir) do
      Dir.mktmpdir
    end

    context 'with a valid transformer' do
      let(:args) do
        ['--input-file', 'data/researchers.csv', '--force', '--dir', dir]
      end

      before do
        allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double(load: true))
        allow(Rialto::Etl::Transformer).to receive(:new).and_return(double('t', transform: nil))
        allow(Rialto::Etl::Extractors::Sera).to receive(:new).and_return(['foo'])
        allow(File).to receive(:exist?).and_return(true)
        allow(File).to receive(:empty?).and_return(false)
      end

      it 'calls extract, transform, and load' do
        loader.handle_row(row, 1)
        expect(Rialto::Etl::Extractors::Sera).to have_received(:new)
          .with(sunetid: 'vjarrett')
        expect(Rialto::Etl::Transformer).to have_received(:new).once
        expect(Rialto::Etl::Loaders::Sparql).to have_received(:new)
          .with(input: "#{dir}/sera-123.sparql")
      end
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end
end
