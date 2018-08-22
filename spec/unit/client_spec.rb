require 'spec_helper'

describe Jekyll::Cloudsearch::Client do

  before do
    Jekyll.logger.adjust_verbosity(quiet: true)
    @base = File.join(__dir__, '../dummy')
    @site = JekyllHelper.scaffold(@base)
    @site.read

    @client = Jekyll::Cloudsearch::Client.new
    @client.instance_variable_set('@site', @site)
  end

  it 'should write a CSV file' do
    base = File.join(@site.config.dig('source'), 'tmp')
    FileUtils.mkdir_p(base)
    filename = 'cloudsearch-test.json'
    path = File.join(base, filename)
    FileUtils.rm path if File.exists?(path)

    expect(File.exists?(path)).to be(false)
    @client.instance_variable_set('@filename', filename)
    @client.write
    expect(File.exists?(path)).to be(true)
  end

  it 'should return CMA client' do
    expect(@client.send(:management)).to be_instance_of(Contentful::Management::Client)
  end

  it 'should return CFL space instance' do
    VCR.use_cassette 'cfl/space' do
      expect(@client.send(:space)).to be_instance_of(Contentful::Management::Space)
    end
  end

  it 'should return all unpublished entries' do
    VCR.use_cassette 'cfl/entries' do
      entries = @client.get_deletions
      expect(entries.all?{|e| e[:type] == 'delete' }).to be(true)
    end
  end

  it 'should generate ID strings for a given document' do
    doc = OpenStruct.new('id' => '6KiG75hCPC8K8gS0gSeIKG')
    expect(@client.send(:uid, doc)).to eq("CF_#{ENV['CONTENTFUL_SPACE_ID']}_#{doc.id}")
  end

  it 'should return AWS client' do
    expect(@client.send(:aws)).to be_instance_of(Aws::CloudSearchDomain::Client)
  end

  it 'should push document onto the docs array' do
    doc = @site.collections['posts'].docs.first
    @client.add_document(doc)
    expect(@client.docs).to_not be_empty
    expect(@client.docs.first.keys).to match_array([:id, :type, :fields])
    expect(@client.docs.first[:fields].keys).to match_array([:title, :content, :link, :type])
  end

end