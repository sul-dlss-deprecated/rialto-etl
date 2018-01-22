# frozen_string_literal: true

require 'rialto/etl/readers/stanford_organizations_json_reader'

RSpec.describe Rialto::Etl::Readers::StanfordOrganizationsJsonReader do
  subject(:reader) { described_class.new(json, settings) }

  let(:json) { StringIO.new('{}') }
  let(:settings) { instance_double(Traject::Indexer::Settings, each: true) }

  describe 'subclass' do
    it 'inherits from TrajectPlus' do
      expect(reader).to be_a TrajectPlus::JsonReader
    end
  end

  describe '#each' do
    it 'calls #yield_children' do
      allow(reader).to receive(:yield_children)
      reader.each { |record| record }
      expect(reader).to have_received(:yield_children).once
    end
  end
end
