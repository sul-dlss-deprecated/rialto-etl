# frozen_string_literal: true

module Rialto
  module Etl
    module Extractors
      # Stanford Profiles API
      class StanfordResearchers
        def initialize(client: StanfordClient.new, per_page: 100, start_page: 1)
          @client = client
          @per_page = per_page # 100 seems to be the max the API allows
          @page = start_page
          @more = true
        end

        # Hit an API endpoint and return the results
        def each(&_block)
          return to_enum(:each) unless block_given?
          while more
            # Retrieve a page of results
            result = fetch_results_for_page(page)
            # Yield the block for each result on the page
            result['values'].each do |val|
              yield val
            end
          end
        rescue StandardError => exception
          puts "Error: #{exception.message}"
        end

        private

        attr_reader :client, :per_page
        attr_accessor :more, :page

        def fetch_results_for_page(page)
          result = client.get(path(page))
          json = JSON.parse(result)
          self.more = !json.fetch('lastPage')
          self.page = page + 1 if more
          json
        end

        def path(page)
          "/profiles/v1?p=#{page}&ps=#{per_page}"
        end
      end
    end
  end
end
