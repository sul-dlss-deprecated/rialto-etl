require 'rialto/etl/sources/abstract_stanford_source'

module Rialto::Etl::Sources
  class StanfordOrganizations < AbstractStanfordSource
    def extract
      client.get("/cap/v1/orgs/stanford?p=1&ps=10").body
    rescue => exception
      puts "Error: #{exception.message}"
    end
  end
end
