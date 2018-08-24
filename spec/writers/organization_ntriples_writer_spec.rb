# frozen_string_literal: true

require 'rialto/etl/writers/organization_ntriples_writer'

RSpec.describe Rialto::Etl::Writers::OrganizationNtriplesWriter do
  subject(:writer) { described_class.new(settings) }

  let(:settings) { instance_double(Traject::Indexer::Settings, each: true) }

  before do
    allow(settings).to receive(:[])
  end

  describe 'parentage' do
    it { is_expected.to be_a Traject::LineWriter }
  end

  describe '#serialize' do
    let(:context) { instance_double(Traject::Indexer::Context, output_hash: hash) }
    let(:hash) do
      {
        '@id' => 'http://id.example.org/1234',
        '@type' => 'http://types.example.org/bar',
        'http://example.org/baz' => 'quux',
        'http://example.net/ns#quuux' => 'quuuux',
        'parent' => 'http://id.example.org/5678',
        '@context' => {
          'parent' => {
            '@id' => 'http://purl.obolibrary.org/obo/BFO_0000050',
            '@type' => '@id'
          }
        }
      }
    end

    let(:output_lines) do
      [
        '<http://id.example.org/1234> <http://example.net/ns#quuux> "quuuux" .',
        '<http://id.example.org/1234> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://types.example.org/bar> .',
        '<http://id.example.org/1234> <http://example.org/baz> "quux" .',
        '<http://id.example.org/1234> <http://purl.obolibrary.org/obo/BFO_0000050> <http://id.example.org/5678> .'
      ]
    end
    let(:serialized) { writer.serialize(context) }

    it 'dumps an ntriples representation of the context' do
      output_lines.each do |line|
        expect(serialized).to include(line)
      end
    end
  end
end
