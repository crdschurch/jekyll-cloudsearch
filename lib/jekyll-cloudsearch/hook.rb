require 'jekyll'
require 'aws-sdk-cloudsearchdomain'
require 'contentful/management'
require 'pry'
require 'json'

@docs = []

Jekyll::Hooks.register :site, :post_write do |site|
  base = File.join(site.config.dig('source'), 'tmp')
  name = "cloudsearch-#{Time.now.strftime("%Y%m%d%H%M%S")}.json"
  FileUtils.mkdir_p(base)
  File.open(File.join(base, name),"w") do |f|
    f.puts(@docs.to_json)
  end

  cf_client = ::Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
  space = cf_client.spaces.find(ENV['CONTENTFUL_SPACE_ID'])
  unpublished_entries = space.entries.all.select{|e| !e.published? || e.archived? }.each do |doc|
    @docs.push({ id: "CF_#{ENV['CONTENTFUL_SPACE_ID']}_#{doc.id}", type: 'delete' });
  end

  aws_client = Aws::CloudSearchDomain::Client.new(endpoint: "https://#{ENV['CRDS_AWS_CSENDPOINT']}")
  resp = aws_client.upload_documents({
    content_type: "application/json",
    documents: @docs.to_json
  })
  Jekyll.logger.info('AWS Cloudsearch:', resp)
end

Jekyll::Hooks.register :documents, :post_render do |doc|
  @docs.push({
    id: "CF_#{ENV['CONTENTFUL_SPACE_ID']}_#{doc.data.dig('id')}",
    type: 'add',
    fields: {
      title: doc.data.dig('title'),
      content: Nokogiri::HTML(doc.content, &:noblanks).text,
      link: doc.url,
      type: 'MediaResource'
    }
  })
end