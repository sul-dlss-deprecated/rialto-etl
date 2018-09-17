# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Transforming organization list to jsonld' do
  subject(:transformed) { indexer.map_record(record) }

  let(:source_file) { 'spec/fixtures/wos/000424386600014.json' }
  let(:record) { File.open(source_file, &:readline) }
  let(:config_file_path) { 'lib/rialto/etl/configs/wos.rb' }
  let(:indexer) do
    Traject::Indexer.new.tap do |indexer|
      indexer.load_config_file(config_file_path)
    end
  end

  before do
    stub_request(:get, 'http://127.0.0.1:3001/person?country=USA&first_name=Jennifer%20L.&full_name=Wilson,%20Jennifer%20L.&last_name=Wilson&orcid_id=0000-0002-2328-2018&organization=Stanford%20University')
      .with(headers: { 'X-Api-Key' => 'abc123' })
      .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/15bf29be-470a-442e-9389-f66aac440a7b')

    stub_request(:get, 'http://127.0.0.1:3001/person?country=USA&first_name=Russ%20B.&full_name=Altman,%20Russ%20B.&last_name=Altman&organization=Stanford%20University')
      .with(headers: { 'X-Api-Key' => 'abc123' })
      .to_return(status: 200, body: 'http://sul.stanford.edu/rialto/agents/people/dc934b74-e554-409b-967b-0d555c44cc2c')
  end

  it 'outputs transformer results to stdout' do
    expect(transformed).to eq(
      '@id' => 'http://sul.stanford.edu/rialto/publications/1361324f8ff0b8ef1ed408a1f0b58107',
      '@type' => 'http://purl.org/ontology/bibo/Document',
      'http://purl.org/dc/terms/created' => '2018-02-01',
      'http://purl.org/dc/terms/hasPart' => 'EXPERIMENTAL BIOLOGY AND MEDICINE',
      'http://purl.org/dc/terms/title' => 'Biomarkers: Delivering on the expectation of ' \
        'molecularly driven, quantitative health',
      'http://purl.org/ontology/bibo/abstract' => 'Biomarkers are the pillars of precision ' \
        'medicine and are delivering on expectations of molecular, quantitative health. These ' \
        'features have made clinical decisions more precise and personalized, but require a ' \
        'high bar for validation. Biomarkers have improved health outcomes in a few areas such ' \
        'as cancer, pharmacogenetics, and safety. Burgeoning big data research infrastructure, ' \
        'the internet of things, and increased patient participation will accelerate discovery ' \
        'in the many areas that have not yet realized the full potential of biomarkers for ' \
        'precision health. Here we review themes of biomarker discovery, current ' \
        'implementations of biomarkers for precision health, and future opportunities and ' \
        'challenges for biomarker discovery.',
      'http://purl.org/ontology/bibo/doi' => '10.1177/1535370217744775',
      'http://purl.org/ontology/bibo/identifier' => ['1535-3702', '1535-3699',
                                                     '10.1177/1535370217744775',
                                                     'MEDLINE:29199461'],
      'http://vivoweb.org/ontology/core#publisher' => 'SAGE PUBLICATIONS LTD',
      'http://vivoweb.org/ontology/core#relatedBy' => {
        '@type' => 'http://vivoweb.org/ontology/core#Authorship',
        'http://vivoweb.org/ontology/core#relates' => [
          { '@id' => 'http://sul.stanford.edu/rialto/agents/people/15bf29be-470a-442e-9389-f66aac440a7b' },
          { '@id' => 'http://sul.stanford.edu/rialto/agents/people/dc934b74-e554-409b-967b-0d555c44cc2c' }
        ]
      }
    )
  end
end
