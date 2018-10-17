# frozen_string_literal: true

require 'active_support/core_ext/array/wrap'

module Rialto
  module Etl
    module Extractors
      # Web of Science JSON API client
      class WebOfScience
        # Instead of a bare `raise`, raise a custom error so it can be caught reliably
        class ThrottledConnectionError < StandardError; end

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

        # rubocop:disable Metrics/MethodLength
        # Hit an API endpoint and return the results
        def each(&_block)
          return to_enum(:each) unless block_given?
          while more
            begin
              retries ||= 0
              # Retrieve a page of results
              records = fetch_results_for_page(page)
            rescue ThrottledConnectionError
              retries += 1
              puts "retrying connection to WebOfScience because connection is throttled. Sleeping for #{retries} second(s)..."
              sleep retries
              retry if retries < 3
            rescue StandardError => exception
              warn "Error fetching #{client.path(page: page)}: #{exception.message}"
              return
            end
            # Yield the block for each result on the page
            Array.wrap(records).each do |val|
              yield val.to_json
            end
          end
        end
        # rubocop:enable Metrics/MethodLength

        private

        attr_accessor :more, :page
        attr_reader :client

        def build_client(options)
          ServiceClient::WebOfScienceClient.new(firstname: options[:firstname],
                                                lastname: options[:lastname],
                                                institution: options.fetch('institution', 'Stanford University'))
        end

        # rubocop:disable Metrics/AbcSize
        def fetch_results_for_page(page)
          result = client.request(page: page)
          unless result.success?
            raise result.status == 429 ? ThrottledConnectionError : result.body
          end
          json = JSON.parse(result.body)
          found = json.fetch('QueryResult').fetch('RecordsFound')
          self.more = client.last_record(page: page) < found

          # web of science returns an empty string of records in this case.
          return [] if found.zero?

          self.page = page + 1 if more
          Array.wrap(json.fetch('Data').fetch('Records').fetch('records').fetch('REC'))
        end
        # rubocop:enable Metrics/AbcSize
      end
    end
  end
end
