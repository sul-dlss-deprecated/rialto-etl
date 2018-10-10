# frozen_string_literal: true

require 'yell'

require 'traject/util'
require 'traject/qualified_const_get'
require 'traject/thread_pool'

require 'concurrent' # for atomic_fixnum
# require 'rialto/etl/service_client/connection_factory'
require 'aws-sdk-sns'

module Rialto
  module Etl
    module Writers
      # Write to SPARQL
      #
      # This should work under both MRI and JRuby, with JRuby getting much
      # better performance due to the threading model.
      #
      # Relevant settings
      #
      # * sparql_writer.update_url: The actual update url.
      #
      # * sparql_writer.batch_size: How big a batch to send to SPARQL. Default is 100.
      #
      # * sparql_writer.thread_pool: How many threads to use for the writer. Default is 1.
      #   Likely useful even under MRI since thread will be waiting on SPARQL for some time.
      #
      # * sparql_writer.client Mainly intended for testing, set your own SPARQL::Client
      #   or mock object to be used for SPARQL.
      class SnsWriter
        include Traject::QualifiedConstGet

        DEFAULT_BATCH_SIZE = 500

        # The passed-in settings
        attr_reader :settings

        # A queue to hold documents before sending to sns
        attr_reader :batched_queue

        def initialize(arg_settings)
          @settings = Traject::Indexer::Settings.new(arg_settings)

          @batch_size = (settings['sns_writer.batch_size'] || DEFAULT_BATCH_SIZE).to_i
          @batch_size = 1 if @batch_size < 1

          @batched_queue = Queue.new
          @thread_pool = Traject::ThreadPool.new(thread_pool_size)

          logger.info "   #{self.class.name} writing to '#{endpoint}' " \
            "in batches of #{@batch_size} with #{thread_pool_size} bg threads"
        end

        # Add a single context to the queue, ready to be sent to SPARQL
        def put(context)
          @thread_pool.raise_collected_exception!

          @batched_queue << context
          return unless @batched_queue.size >= @batch_size
          batch = Traject::Util.drain_queue(@batched_queue)
          @thread_pool.maybe_in_thread_pool(batch) { |batch_arg| send_batch(batch_arg) }
        end

        # On close, we need to (a) raise any exceptions we might have, (b) send off
        # the last (possibly empty) batch
        def close
          @thread_pool.raise_collected_exception!

          # Finish off whatever's left. Do it in the thread pool for
          # consistency, and to ensure expected order of operations, so
          # it goes to the end of the queue behind any other work.
          batch = Traject::Util.drain_queue(@batched_queue)
          @thread_pool.maybe_in_thread_pool { send_batch(batch) } if batch.length.positive?

          # Wait for shutdown, and time it.
          logger.debug "#{self.class.name}: Shutting down thread pool, waiting if needed..."
          elapsed = @thread_pool.shutdown_and_wait
          if elapsed > 60
            logger.warn "Waited #{elapsed} seconds for all threads, you may want to increase sns_writer.thread_pool " \
              "(currently #{thread_pool_size})"
          end
          logger.debug "#{self.class.name}: Thread pool shutdown complete"

          # check again now that we've waited, there could still be some
          # that didn't show up before.
          @thread_pool.raise_collected_exception!
        end

        private

        # Send the given batch of contexts. If something goes wrong, send
        # them one at a time.
        # @param [Array<Traject::Indexer::Context>] batch an array of contexts
        def send_batch(batch)
          return if batch.empty?
          subjects = []
          batch.each { |b| subjects << b.source_record }
          post(subjects)
        end

        # Post the subject to SNS
        # @param [String] subjects to send
        def post(subjects)
          client.publish(
            topic_arn: topic_arn,
            message: %({"Action": "touch", "Entities": #{subjects}})
          )
        rescue Aws::SNS::Errors::ServiceError => exception
          logger.warn "Error in SNS update. #{exception}"
        end

        # Get the logger from the settings, or default to an effectively null logger
        def logger
          settings['logger'] ||= Yell.new(STDERR, level: 'gt.fatal') # null logger
        end

        # How many threads to use for the writer?
        # if our thread pool settings are 0, it'll just create a null threadpool that
        # executes in calling context.
        def thread_pool_size
          @thread_pool_size ||= (settings['sns_writer.thread_pool'] || 1).to_i
        end

        def client
          @client ||= Aws::SNS::Client.new(region: region,
                                           endpoint: endpoint,
                                           logger: logger,
                                           access_key_id: access_key,
                                           secret_access_key: secret_key)
        end

        def region
          settings['sns_writer.region']
        end

        def endpoint
          settings['sns_writer.endpoint_url']
        end

        def access_key
          settings['sns_writer.access_key'].to_s
        end

        def secret_key
          settings['sns_writer.secret_key'].to_s
        end

        def topic_arn
          settings['sns_writer.topic_arn']
        end
      end
    end
  end
end
