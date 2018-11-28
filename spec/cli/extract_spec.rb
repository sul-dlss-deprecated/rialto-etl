# frozen_string_literal: true

RSpec.describe Rialto::Etl::CLI::Extract do
  subject(:extractor) { described_class.new([], args, conf) }

  let(:args) do
    []
  end

  let(:command) { described_class.all_commands['call'] }

  let(:conf) do
    {
      current_command: command,
      command_options: command.options
    }
  end

  describe 'integration test' do
    let(:args) do
      ['--since', '1D']
    end

    before do
      stub_request(:get, 'https://api.clarivate.com/api/wos?count=1&databaseId=WOS&firstRecord=1&loadTimeSpan=1D&usrQuery=OG=Stanford%20University')
        .to_return(status: 200, body: '{}', headers: {})
    end

    it 'passes options that do not cause the extractor to raise' do
      extractor.invoke_command(command, 'WebOfScience')
      expect { extractor.invoke_command(command, 'WebOfScience') }.not_to raise_error
    end
  end

  # rubocop:disable RSpec/VerifiedDoubles
  describe '#call' do
    let(:extractor_name) { 'FooBar' }
    let(:mock_extractor_class) { double(new: mock_extractor_instance) }
    let(:mock_extractor_instance) { double }
    let(:result) { double }

    before do
      allow(Rialto::Etl::Extractors).to receive(:const_get).with(extractor_name).and_return(mock_extractor_class)
    end

    context 'when called without args' do
      let(:args) do
        []
      end

      it 'raises an exception' do
        expect { extractor.invoke_command(command) }.to raise_error(Thor::InvocationError)
      end
    end

    context 'when called with an extractor name arg' do
      it 'calls the named extractor' do
        allow(extractor).to receive(:say).with(result)
        allow(mock_extractor_instance).to receive(:each).and_yield(result)
        extractor.invoke_command(command, extractor_name)
        expect(mock_extractor_instance).to have_received(:each).once
        expect(extractor).to have_received(:say).once
      end
    end
  end
  # rubocop:enable RSpec/VerifiedDoubles

  describe '#list' do
    let(:command) { described_class.all_commands['list'] }

    it 'prints out callable extractors' do
      allow(extractor).to receive(:say)
      extractor.invoke_command(command)
      expect(extractor).to have_received(:say).with(/StanfordOrganizations, StanfordResearchers/)
    end

    it 'omits non-callable extractors' do
      allow(extractor).to receive(:say)
      extractor.invoke_command(command)
      expect(extractor).not_to have_received(:say).with(/Abstract/)
    end
  end
end
