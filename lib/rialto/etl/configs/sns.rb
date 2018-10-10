# frozen_string_literal: true

require 'rialto/etl/readers/sparql_subject_reader'
require 'rialto/etl/writers/sns_writer'

settings do
  provide 'writer_class_name', 'Rialto::Etl::Writers::SnsWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::SparqlSubjectReader'
  provide 'sns_writer.access_key', ::Settings.sns_writer.access_key
  provide 'sns_writer.secret_key', ::Settings.sns_writer.secret_key
  provide 'sns_writer.endpoint_url', ::Settings.sns_writer.endpoint_url
  provide 'sns_writer.region', ::Settings.sns_writer.region
  provide 'sns_writer.topic_arn', ::Settings.sns_writer.topic_arn
  provide 'sns_writer.thread_pool', 0
end
