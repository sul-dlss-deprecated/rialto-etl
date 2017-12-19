require 'rialto/etl/sources/abstract_stanford_source'

module Rialto::Etl::Sources
  class StanfordResearchers < AbstractStanfordSource
    def extract
      client.get("/profiles/v1?p=1&ps=10").body
    rescue => exception
      puts "Error: #{exception.message}"
    end
  end
end
