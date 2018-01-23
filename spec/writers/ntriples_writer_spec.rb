# frozen_string_literal: true

require 'rialto/etl/writers/ntriples_writer'

RSpec.describe Rialto::Etl::Writers::NtriplesWriter do
  subject(:writer) { described_class.new(settings) }

  let(:settings) { instance_double(Traject::Indexer::Settings, each: true) }

  before do
    allow(settings).to receive(:[])
  end

  describe 'parentage' do
    it { is_expected.to be_a Traject::LineWriter }
  end

  describe '#serialize' do
    # rubocop:disable RSpec/VerifiedDoubles
    let(:context) { double('context', output_hash: hash) }
    # rubocop:enable RSpec/VerifiedDoubles
    let(:hash) do
      {
        '@id' => 'http://id.example.org/1234',
        '@type' => 'http://types.example.org/bar',
        'http://example.org/baz' => 'quux',
        'http://example.net/ns#quuux' => 'quuuux',
        '@parent' => 'http://id.example.org/5678',
        '@webpage' => 'http://sites.example.org/awesome.html'
      }
    end
    # rubocop:disable Metrics/LineLength
    let(:output_lines) do
      [
        '<http://id.example.org/1234> <http://example.net/ns#quuux> "quuuux" .',
        '<http://id.example.org/1234> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://types.example.org/bar> .',
        '<http://id.example.org/1234> <http://example.org/baz> "quux" .',
        '<http://id.example.org/1234> <http://purl.obolibrary.org/obo/BFO_0000050> <http://id.example.org/5678> .',
        '<http://id.example.org/1234> <http://purl.obolibrary.org/obo/ARG_2000028> <http://rialto.stanford.edu/cards/5a69f5d0-e201-0135-1f1a-54ee756b784d> .',
        '<http://rialto.stanford.edu/cards/5a69f5d0-e201-0135-1f1a-54ee756b784d> <http://www.w3.org/2006/vcard/ns#hasURL> <http://rialto.stanford.edu/cards/f6213850-e201-0135-1f1c-54ee756b784d> .',
        '<http://rialto.stanford.edu/cards/f6213850-e201-0135-1f1c-54ee756b784d> <http://www.w3.org/2006/vcard/ns#url> "http://sites.example.org/awesome.html"^^<http://www.w3.org/2001/XMLSchema#anyURI> .'
      ]
    end
    # rubocop:enable Metrics/LineLength
    let(:serialized) { writer.serialize(context) }

    before do
      allow(UUID).to receive(:generate).and_return(
        '5a69f5d0-e201-0135-1f1a-54ee756b784d',
        'f6213850-e201-0135-1f1c-54ee756b784d'
      )
    end

    it 'dumps an ntriples representation of the context' do
      output_lines.each do |line|
        expect(serialized).to include(line)
      end
    end
  end
end
