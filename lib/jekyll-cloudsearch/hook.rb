@docs = []
@client = Jekyll::Cloudsearch::Client.new

Jekyll::Hooks.register :documents, :post_render do |doc|
  @client.add_document(doc)
end

Jekyll::Hooks.register :site, :post_write do |site|
  @client.instance_variable_set('@site', site)
  resp = @client.run
  Jekyll.logger.info('AWS Cloudsearch:', resp)
end