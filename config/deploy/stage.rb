# frozen_string_literal: true

server 'rialto-vitro-dev.stanford.edu', user: 'vitro', roles: %w[app]
Capistrano::OneTimeKey.generate_one_time_key!

# Don't run whenever on stage
Rake::Task['whenever:update_crontab'].clear_actions

set :deploy_to, '/opt/app/vitro/rialto/rialto-etl'
