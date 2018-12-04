# frozen_string_literal: true

server 'rialto-etl-stage.stanford.edu', user: 'rialto', roles: %w[app]
Capistrano::OneTimeKey.generate_one_time_key!

# Don't run whenever on stage
Rake::Task['whenever:update_crontab'].clear_actions
