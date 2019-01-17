# frozen_string_literal: true

require 'rialto/etl/readers/sparql_statement_reader'
require 'rialto/etl/writers/sparql_writer'
require 'rialto/etl/logging'

extend Rialto::Etl::Logging

self.logger = logger

settings do
  provide 'writer_class_name', 'Rialto::Etl::Writers::SparqlWriter'
  provide 'reader_class_name', 'Rialto::Etl::Readers::SparqlStatementReader'
  provide 'sparql_writer.update_url', ::Settings.sparql_writer.update_url
  provide 'sparql_writer.thread_pool', 0
  provide 'sparql_writer.batch_size', ::Settings.sparql_writer.batch_size
  provide 'sparql_writer.max_retries', ::Settings.sparql_writer.max_retries
  provide 'sparql_writer.max_interval', ::Settings.sparql_writer.max_interval
  provide 'processing_thread_pool', 0 # Turns off multithreading, for debugging
end
