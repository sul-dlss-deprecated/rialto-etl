# frozen_string_literal: true

require 'rialto/etl/extractors/sera'
require 'rialto/etl/extractors/stanford_researchers'
require 'rialto/etl/extractors/stanford_organizations'
require 'rialto/etl/extractors/web_of_science'

require 'rialto/etl/service_client/oauth_client_factory'
require 'rialto/etl/service_client/retriable_connection_factory'
require 'rialto/etl/service_client/stanford_client'
require 'rialto/etl/service_client/web_of_science_client'
require 'rialto/etl/service_client/entity_resolver'

module Rialto
  module Etl
    # A module to hold extractors
    module Extractors
    end
  end
end
