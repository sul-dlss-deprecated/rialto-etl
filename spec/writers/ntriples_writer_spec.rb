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
        'http://example.net/ns#quuux' => 'quuuux'
      }
    end
    let(:output_lines) do
      [
        '<http://id.example.org/1234> <http://example.net/ns#quuux> "quuuux" .',
        '<http://id.example.org/1234> <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://types.example.org/bar> .',
        '<http://id.example.org/1234> <http://example.org/baz> "quux" .'
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
