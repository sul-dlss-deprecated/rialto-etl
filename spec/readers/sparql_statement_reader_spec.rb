# frozen_string_literal: true

require 'rialto/etl/readers/sparql_statement_reader'

RSpec.describe Rialto::Etl::Readers::SparqlStatementReader do
  let(:reader) { described_class.new('', '') }

  describe '#logger' do
    let(:logger) { instance_double('Yell::Logger') }
    let(:message) { 'Did a thing!' }

    before do
      allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
      allow(logger).to receive(:info)
    end

    context 'when specified in settings' do
      it 'uses the given logger' do
        reader.logger.info(message)
        expect(logger).to have_received(:info)
      end
    end

    context 'when not specified in settings' do
      let(:settings) { {} }

      it 'uses a null logger' do
        reader.logger.info(message)
        expect(logger).to have_received(:info).with(message)
      end
    end
  end
end
