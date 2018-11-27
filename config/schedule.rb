# frozen_string_literal: true

# Config file for whenever. Learn more: http://github.com/javan/whenever

$LOAD_PATH.unshift 'lib'
require 'rialto/etl'

set :output, 'log/etl_cron.log'

job_type :exe, 'cd :path && :task'

every :tuesday, at: '01:45pm' do
  exe 'exe/extract call StanfordOrganizations > data/organizations.json ' \
    '&& exe/transform call StanfordOrganizations -i data/organizations.json > data/organizations.sparql ' \
    '&& exe/load call Sparql -i data/organizations.sparql ' \
    '&& exe/extract call StanfordResearchers > data/researchers.ndj ' \
    '&& exe/transform call StanfordPeople -i data/researchers.ndj > data/researchers.sparql ' \
    '&& exe/load call Sparql -i data/researchers.sparql ' \
    '&& exe/transform call StanfordPeopleList -i data/researchers.ndj > data/researchers.csv ' \
    '&& exe/grants load -s 3 -i data/researchers.csv ' \
    "&& exe/publications load -d data/raw/pubs -o data/pubs --since #{Settings.wos.load_timespan}"
end
