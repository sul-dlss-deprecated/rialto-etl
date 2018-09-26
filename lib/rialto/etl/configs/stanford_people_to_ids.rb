# frozen_string_literal: true

require 'traject_plus'
require 'rialto/etl/readers/ndjson_reader'

extend TrajectPlus::Macros
extend TrajectPlus::Macros::JSON

settings do
  provide 'reader_class_name', 'Rialto::Etl::Readers::NDJsonReader'
  provide 'writer_class_name', 'Traject::JsonWriter'
end

to_field 'sunetid', lambda { |json, accumulator, context|
  id = JsonPath.on(json, '$.uid').first
  # Do not index record if it lacks a SUNet ID
  context.skip! if id.nil?
  accumulator << id
}, single: true
