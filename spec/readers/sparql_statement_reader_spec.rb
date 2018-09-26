# frozen_string_literal: true

require 'rialto/etl/readers/sparql_statement_reader'

RSpec.describe Rialto::Etl::Readers::SparqlStatementReader do
  let(:reader) { described_class.new('', settings) }

  describe '#logger' do
    let(:logger) { double }
    let(:message) { 'Did a thing!' }

    before do
      allow(logger).to receive(:info)
    end

    context 'when specified in settings' do
      let(:settings) { { 'logger' => logger } }

      it 'uses the given logger' do
        reader.logger.info(message)
        expect(logger).to have_received(:info).with(message)
      end
    end

    context 'when not specified in settings' do
      let(:settings) { {} }

      before do
        allow(Yell).to receive(:new).and_return(logger)
      end

      it 'uses a null logger' do
        reader.logger.info(message)
        expect(Yell).to have_received(:new)
        expect(logger).to have_received(:info).with(message)
      end
    end
  end
end
