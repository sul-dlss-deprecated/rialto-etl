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
  describe '#load' do
    let(:dir) do
      Dir.mktmpdir
    end

    let(:args) do
      ['--input-file', 'spec/fixtures/researchers.csv', '--force', '--input-directory', dir, '--output-directory', dir]
    end

    before do
      allow(Rialto::Etl::Loaders::Sparql).to receive(:new).and_return(double(load: true))
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
        .with(input: "#{dir}/wos-123.sparql")
    end
    # rubocop:enable RSpec/VerifiedDoubles
  end
end
