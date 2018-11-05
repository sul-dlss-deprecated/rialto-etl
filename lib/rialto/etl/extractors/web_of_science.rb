# frozen_string_literal: true

require 'active_support/core_ext/array/wrap'

module Rialto
  module Etl
    module Extractors
      # Web of Science JSON API client
      class WebOfScience
        DEFAULT_INSTITUTION = 'Stanford University'

        attr_reader :client

        # @param [Hash] options
        # @option options [String] :client a preconfigured client.  May be used for testing, all other
        #                                  options will be ignored.
        # @option options [String] :first_name The first name of the person to search for
        # @option options [String] :last_name The last name of the person to search for
        # @option options [String] :institution ('Stanford University') The institution to search for
        def initialize(options)
          @client = options.fetch(:client) { build_client(options) }
        end

        # Use the client to iterate over records and yield them as JSON
        def each
          return to_enum(:each) unless block_given?
          client.each do |record|
            yield record.to_json
          end
        end

        private

        def build_client(options)
          ServiceClient::WebOfScienceClient.new(first_name: options[:first_name],
                                                last_name: options[:last_name],
                                                institution: options.fetch(:institution, DEFAULT_INSTITUTION))
        end
      end
    end
  end
end
