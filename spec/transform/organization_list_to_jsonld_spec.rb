# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Transforming organization list to jsonld' do
  let(:source_file) { 'spec/fixtures/organizations.ndj' }
  let(:input_stream) { File.new(source_file, 'r') }
  let(:config_file_path) { 'lib/rialto/etl/configs/organizations_to_jsonld.rb' }
  let(:transformer) { Rialto::Etl::Transformer.new(input_stream: input_stream, config_file_path: config_file_path) }

  let(:division) { 'http://vivoweb.org/ontology/core#Division' }
  let(:agent) { 'http://xmlns.com/foaf/0.1/Agent' }
  let(:organization) { 'http://xmlns.com/foaf/0.1/Organization' }

  it 'outputs transformer results to stdout' do
    expect { transformer.transform }.to output(/"@type":\["#{division}","#{agent}","#{organization}"\]/).to_stdout
  end
end
