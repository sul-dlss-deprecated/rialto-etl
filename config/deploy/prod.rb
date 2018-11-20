# frozen_string_literal: true

server 'rialto-etl-prod.stanford.edu', user: 'rialto', roles: %w[app]
Capistrano::OneTimeKey.generate_one_time_key!
