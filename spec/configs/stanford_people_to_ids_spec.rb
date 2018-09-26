# frozen_string_literal: true

require 'rialto/etl/transformer'

RSpec.describe Rialto::Etl::Transformer do
  let(:person1) { '{"uid": "mjgiarlo"}' }
  let(:person2) { '{"fooid": "justinlittman"}' }

  describe 'stanford_people_to_ids' do
    let(:hash) do
      json_io = StringIO.new

      transformer = Traject::Indexer.new.tap do |indexer|
        indexer.load_config_file('lib/rialto/etl/configs/stanford_people_to_ids.rb')
        indexer.settings['output_stream'] = json_io
      end

      transformer.process(StringIO.new([person1, person2].join("\n")))
      JSON.parse(json_io.string)
    end

    it 'includes the correct Stanford people' do
      expect(hash).to include('sunetid' => 'mjgiarlo')
      expect(hash).not_to include('sunetid' => 'justinlittman')
    end
  end
end
