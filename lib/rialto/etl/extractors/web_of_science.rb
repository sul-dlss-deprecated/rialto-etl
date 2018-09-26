# frozen_string_literal: true

require 'active_support/core_ext/array/wrap'

module Rialto
  module Etl
    module Extractors
      # Web of Science JSON API client
      class WebOfScience
        # @param [Hash] options
        # @option options [String] :client a preconfigured client.  May be used for testing, all other
        #                                  options will be ignored.
        # @option options [String] :firstname The first name of the person to search for
        # @option options [String] :lastname The last name of the person to search for
        # @option options [String] :institution ('Stanford University') The institution to search for
        def initialize(options)
          @client = options.fetch(:client) { build_client(options) }
          @more = true
          @page = options[:start_page] || 1
        end

        # Hit an API endpoint and return the results
        def each(&_block)
          return to_enum(:each) unless block_given?
          while more
            # Retrieve a page of results
            records = fetch_results_for_page(page)
            # Yield the block for each result on the page
            records.each do |val|
              yield val.to_json
            end
          end
        rescue StandardError => exception
          warn "Error: #{exception.message}"
        end

        private

        attr_accessor :more, :page
        attr_reader :client

        def build_client(options)
          ServiceClient::WebOfScienceClient.new(firstname: options['firstname'],
                                                lastname: options['lastname'],
                                                institution: options.fetch('institution', 'Stanford University'))
        end

        def fetch_results_for_page(page)
          result = client.request(page: page)
          raise result.body unless result.success?
          json = JSON.parse(result.body)
          found = json.fetch('QueryResult').fetch('RecordsFound')
          self.more = client.last_record(page: page) < found

          # web of science returns an empty string of records in this case.
          return [] if found.zero?

          self.page = page + 1 if more
          Array.wrap(json.fetch('Data').fetch('Records').fetch('records').fetch('REC'))
        end
      end
    end
  end
end
