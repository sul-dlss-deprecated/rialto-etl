# Rialto::Etl

Rialto::Etl is a set of ETL tools for RIALTO, Stanford University Libraries' research intelligence project

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rialto-etl'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rialto-etl

## Usage

### Extract

Run `bin/extract` to hit a named data source and print output to STDOUT.

    $ bin/extract -s StanfordResearchers
    {"count":10,"firstPage":true,"lastPage":false,"page":1,"totalCount":29089,"totalPages":2909,"values":[{"administrativeAppointments":[...

### Transform

TBD. Planning to use TrajectPlus

### Load

TBD

## Help

    $ bin/extract -h
    Usage: bin/extract [options]
        -s, --source NAME                Name of the data source to extract (REQUIRED)

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sul-dlss-labs/rialto-etl.
