# frozen_string_literal: true

require 'rialto/etl/namespaces'
require 'rialto/etl/transformer'

STANFORD_PEOPLE_SOURCE1 = <<~JSON
  {
    "profileId": 400150,
    "names": {
      "preferred": {
        "firstName": "Bill",
        "lastName": "Chen"
      }
    },
    "uid": "billchen1"
  }
JSON

STANFORD_PEOPLE_SOURCE2 = <<~JSON
  {
    "profileId": 12350,
    "names": {
      "preferred": {
        "firstName": "Lucia",
        "lastName": "Veiongo"
      }
    },
    "uid": "lucia"
  }
JSON

RSpec.describe Rialto::Etl::Transformer do
  describe 'stanford_people_to_list' do
    describe 'insert' do
      let(:csv) do
        csv_io = StringIO.new

        transformer = Traject::Indexer.new.tap do |indexer|
          indexer.load_config_file('lib/rialto/etl/configs/stanford_people_to_list.rb')
          indexer.settings['output_stream'] = csv_io
        end

        transformer.process(StringIO.new(
                              [STANFORD_PEOPLE_SOURCE1, STANFORD_PEOPLE_SOURCE2].map { |p| p.delete("\n") }.join("\n")
                            ))
        CSV.parse(csv_io.string)
      end

      it 'has the correct header' do
        expect(csv[0]).to match_array(%w[uri first_name last_name sunetid])
      end

      it 'has the right number of lines' do
        expect(csv.length).to eq(3)
      end
      it 'includes the correct Stanford people' do
        expect(csv[1][0]).to eq("#{Rialto::Etl::Vocabs::RIALTO_PEOPLE}400150")
        expect(csv[1][1]).to eq('Bill')
        expect(csv[1][2]).to eq('Chen')
        expect(csv[1][3]).to eq('billchen1')
      end
    end
  end
end
