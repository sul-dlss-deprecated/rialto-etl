# frozen_string_literal: true

# Config file for whenever. Learn more: http://github.com/javan/whenever

set :output, 'log/etl_cron.log'

every 7.days do
  command 'exe/extract call StanfordOrganizations > data/organizations.json ' /
          '&& exe/transform call StanfordOrganizations -i data/organizations.json > data/organizations.sparql ' /
          '&& exe/load call Sparql -i data/organizations.sparql'
end
