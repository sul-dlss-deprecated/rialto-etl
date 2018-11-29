# frozen_string_literal: true

# Config file for whenever. Learn more: http://github.com/javan/whenever

$LOAD_PATH.unshift 'lib'
require 'rialto/etl'

set :output, 'log/etl_cron.log'

job_type :exe, 'cd :path && :task'

# Organization ETL
every :tuesday, at: '01:45pm' do
  exe 'exe/extract call StanfordOrganizations > data/organizations.json ' \
    '&& aws s3 cp data/organizations.json s3://rialto-data-load/organizations-$(date \'+%Y-%m-%d\').json ' \
    '&& exe/transform call StanfordOrganizations -i data/organizations.json > data/organizations.sparql ' \
    '&& exe/load call Sparql -i data/organizations.sparql'
end

# Researcher ETL
every :wednesday, at: '09:30am' do
  exe 'exe/extract call StanfordResearchers > data/researchers.ndj ' \
    '&& aws s3 cp data/researchers.ndj s3://rialto-data-load/researchers-$(date \'+%Y-%m-%d\').ndj ' \
    '&& exe/transform call StanfordPeople -o data/organizations.json -i data/researchers.ndj > data/researchers.sparql ' \
    '&& exe/load call Sparql -i data/researchers.sparql '
end

# Grant ETL
every 2.months do
  exe 'exe/transform call StanfordPeopleList -i data/researchers.ndj > data/researchers.csv ' \
    '&& exe/grants load -s 3 -i data/researchers.csv -d data/raw/grants -o data/grants'
end

# Publication ETL
every 2.weeks do
  exe "exe/publications load -d data/raw/pubs -o data/pubs --since #{Settings.wos.load_timespan}"
end
