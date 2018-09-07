# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Transforming organization list to jsonld' do
  let(:source_file) { 'spec/fixtures/wos/000424386600014.json' }
  let(:input_stream) { File.new(source_file, 'r') }
  let(:config_file_path) { 'lib/rialto/etl/configs/wos.rb' }
  let(:transformer) { Rialto::Etl::Transformer.new(input_stream: input_stream, config_file_path: config_file_path) }

  it 'outputs transformer results to stdout' do
    expect { transformer.transform }.to output.to_stdout
  end
end
