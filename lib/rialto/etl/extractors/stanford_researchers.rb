# frozen_string_literal: true

require 'ruby-progressbar'
require 'rialto/etl/logging'

module Rialto
  module Etl
    module Extractors
      # Stanford Profiles API
      class StanfordResearchers
        include Rialto::Etl::Logging

        def initialize(client: ServiceClient::StanfordClient.new, per_page: 100, start_page: 1)
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
            result = fetch_results_for_page(page) { progress }
            # Yield the block for each result on the page
            result['values'].each do |val|

              output_json = {
                "affiliations": val["affiliations"],
                "orgs": val['organizations'],
                "ldapAdditionalInfo": val['ldapAdditionalInfo'],
                "uid": val['uid'],
                "universityId": val['universityId'] }

              yield output_json.to_json # output only data noted above, to export all data, comment this line out, and uncomment line below
              # yield val.to_json
            end
          end
        rescue StandardError => exception
          logger.error "Error: #{exception.message}"
        end

        attr_reader :total_pages

        private

        attr_reader :client, :per_page
        attr_accessor :more, :page
        attr_writer :total_pages

        def fetch_results_for_page(page)
          result = client.get(path(page))
          json = JSON.parse(result)
          self.total_pages ||= json.fetch('totalPages')
          self.more = !json.fetch('lastPage')

          yield if block_given?
          self.page = page + 1 if more
          json
        end

        def progress
          @progressbar ||= ProgressBar.create(title: progress_title,
                                              total: total_pages,
                                              output: STDERR)
          @progressbar.increment
          @progressbar.title = progress_title
        end

        def progress_title
          "Requests (#{page}/#{total_pages}): "
        end

        def path(page)
          "/profiles/v1?p=#{page}&ps=#{per_page}"
        end
      end
    end
  end
end
