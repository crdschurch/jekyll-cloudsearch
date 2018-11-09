enabled = ARGV.include?('--cloudsearch')

if enabled
  @client = Jekyll::Cloudsearch::Client.new
  Jekyll::Hooks .register :documents, :post_render do |doc|
    @client.add_document(doc)
  end
end

Jekyll::Hooks.register :site, :post_write do |site|
  if enabled
    @client.instance_variable_set('@site', site)
    resp = @client.run
    Jekyll.logger.info('AWS Cloudsearch:', resp)
  else
    Jekyll.logger.info('AWS Cloudsearch:', 'disabled. Enable with -- --cloudsearch')
  end
end
