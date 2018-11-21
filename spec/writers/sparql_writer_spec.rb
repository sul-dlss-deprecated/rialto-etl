# frozen_string_literal: true

require 'traject'
require 'rialto/etl/writers/sparql_writer'

RSpec.describe Rialto::Etl::Writers::SparqlWriter do
  subject(:writer) do
    described_class.new(
      'sparql_writer.update_url' => 'http://127.0.0.1:9999/sparql',
      'sparql_writer.thread_pool' => 0,
      'sparql_writer.batch_size' => batch_size
    )
  end

  let(:logger) { instance_double('Yell::Logger') }

  let(:batch_size) { 1 }

  let(:batch) do
    Traject::Indexer::Context.new(source_record: 'SPARQL INSERT STATEMENT')
  end

  let(:status) { 200 }

  before do
    allow_any_instance_of(described_class).to receive(:logger).and_return(logger)
    allow(logger).to receive(:error)
    allow(logger).to receive(:info)
    allow(logger).to receive(:debug)

    stub_request(:post, 'http://127.0.0.1:9999/sparql')
      .with(
        body: 'SPARQL INSERT STATEMENT',
        headers: {
          'Content-Type' => 'application/sparql-update; charset=utf-8'
        }
      )
      .to_return(status: status, body: '', headers: {})
  end

  describe '#put' do
    context 'when returns 200' do
      it 'posts the statement' do
        expect { writer.put(batch) }.not_to raise_error
      end
    end
    context 'when returns 500' do
      let(:status) { 500 }

      it 'raises an error' do
        expect { writer.put(batch) }.to raise_error(Rialto::Etl::ErrorResponse)
        expect(logger).to have_received(:error).with('Error in SPARQL update. : 500  () (Rialto::Etl::ErrorResponse)')
      end
    end
  end
  describe '#close' do
    let(:batch_size) { 2 }

    it 'posts the statement' do
      writer.put(batch)
      expect { writer.close }.not_to raise_error
    end
  end
end
