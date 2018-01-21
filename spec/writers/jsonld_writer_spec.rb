# frozen_string_literal: true

RSpec.describe Rialto::Etl::Writers::JsonldWriter do
  subject(:writer) { described_class.new(settings) }

  let(:settings) { instance_double(Traject::Indexer::Settings, each: true) }
  let(:context_object) do
    {
      rdfs: 'http://www.w3.org/2000/01/rdf-schema#',
      vivo: 'http://vivoweb.org/ontology/core#'
    }
  end

  before do
    allow(settings).to receive(:[]).with('context_object').and_return(context_object)
  end

  describe '#put' do
    let(:context) { Traject::Indexer::Context.new(source_record: { foo: 'bar' }) }

    it 'appends data to the @records instance variable' do
      expect { writer.put(context) }.to change { writer.send(:records).count }.from(0).to(1)
    end
  end

  describe '#close' do
    before do
      records.each do |record|
        writer.put(record)
      end
    end

    # rubocop:disable RSpec/VerifiedDoubles
    let(:records) do
      [
        double(output_hash: { foo: 'bar' }),
        double(output_hash: { bar: 'baz' }),
        double(output_hash: { baz: 'quux' })
      ]
    end
    # rubocop:enable RSpec/VerifiedDoubles

    let(:json_object) do
      {
        '@context' => context_object,
        '@graph' => [
          {
            foo: 'bar'
          },
          {
            bar: 'baz'
          },
          {
            baz: 'quux'
          }
        ]
      }.to_json
    end

    it 'prints JSON to STDOUT' do
      allow($stdout).to receive(:puts)
      writer.close
      expect($stdout).to have_received(:puts).with(json_object)
    end
  end
end
