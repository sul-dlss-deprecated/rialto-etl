# frozen_string_literal: true

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

desc 'Run style checker'
RuboCop::RakeTask.new(:rubocop) do |task|
  task.fail_on_error = true
end

RSpec::Core::RakeTask.new(:spec)

task ci: [:rubocop] do
  Rake::Task['spec'].invoke
end

task default: :ci
