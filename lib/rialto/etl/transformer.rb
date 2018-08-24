# frozen_string_literal: true

require 'traject'

module Rialto
  module Etl
    # Transformer turning Stanford org info into Vivo format
    class Transformer
      attr_reader :input_stream, :config_file_path

      # Initialize a new instance of the transformer
      #
      # @param input [String] valid file path
      def initialize(input_stream:, config_file_path:)
        @input_stream = input_stream
        @config_file_path = config_file_path
      end

      # Transform a stream into a new representation, using Traject
      def transform
        transformer.process(input_stream)
      end

      private

      def transformer
        @transformer ||= Traject::Indexer.new.tap do |indexer|
          indexer.load_config_file(config_file_path)
        end
      end
    end
  end
end
