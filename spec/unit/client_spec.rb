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

  it 'should return deletions' do
    VCR.use_cassette 'cfl/entries' do
      entries = @client.deletions
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

  it 'should not push search excluded documents onto the docs array' do
    excluded_doc = @site.collections['posts'].docs.select{ |item| item.data.dig('search_excluded') == true }.first
    @client.add_document(excluded_doc)
    expect(@client.docs.include?(excluded_doc)).to eq(false)
  end

  it 'should write and upload' do
    allow(@client).to receive(:write)
    allow(@client).to receive(:upload)
    @client.run
    expect(@client).to have_received(:write).once
    expect(@client).to have_received(:upload).once
  end

  it 'should return absolute url' do
    doc = @site.collections['posts'].docs.first
    url = doc.send(:url)
    ENV['AWS_CLOUDSEARCH_BASE_URL'] = 'https://mediaint.crossroads.net'
    expect(@client.send(:url,doc)).to eq("https://mediaint.crossroads.net#{url}")
  end

  it 'should return cache directory' do
    base = File.expand_path File.join(@site.config.dig('source'), 'tmp')
    expect(@client.send(:cache_dir)).to eq(base)
  end

  it 'should return list of ids from manifest' do
    manifest = @client.send(:manifest)
    expect(manifest).to be_a(Array)
    expect(manifest.all?{|id| id.match(/CF_[a-zA-Z0-9]*_[a-zA-Z0-9]/) }).to be_truthy
  end

  it 'should return manifest file' do
    file = @client.send(:manifest_file)
    expect(file).to include('spec/dummy/tmp/cloudsearch-20180827.json')
  end

  it 'should return stale_ids' do
    @client.instance_variable_set('@docs', %w(abc def).collect{|i| OpenStruct.new(id: i)})
    allow(@client).to receive(:manifest).and_return(%w(abc def ghi))
    stale_ids = @client.send(:stale_ids)
    expect(stale_ids).to match_array(['ghi'])
  end

  it 'should return unpublished ids' do
    VCR.use_cassette 'cfl/entries' do
      unpublished = @client.send(:unpublished_ids)
      expect(unpublished).to be_a(Array)
      expect(unpublished).to include('CF_p9oq1ve41d7r_6KiG75hCPC8K8gS0gSeIKG')
    end
  end

end
