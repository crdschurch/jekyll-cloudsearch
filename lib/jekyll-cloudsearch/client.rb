module Jekyll
  module Cloudsearch
    class Client

      attr_accessor :filename, :site, :docs

      def initialize
        @docs = []
      end

      def perform
        build
        write
        upload
      end

      def write
        base = File.join(site.config.dig('source'), 'tmp')
        FileUtils.mkdir_p(base)
        File.open(File.join(base, filename),"w") do |f|
          f.puts(@docs.to_json)
        end
      end

      def upload
        aws.upload_documents({
          content_type: "application/json",
          documents: @docs.to_json
        })
      end

      def add_document(doc)
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

      def get_deletions
        space.entries.all.select{|e| !e.published? || e.archived? }.collect do |doc|
          { id: uid(doc), type: 'delete' }
        end
      end

      private

        def uid(doc)
          "CF_#{ENV['CONTENTFUL_SPACE_ID']}_#{doc.id}"
        end

        def filename
          @filename ||= "cloudsearch-#{Time.now.strftime("%Y%m%d%H%M%S")}.json"
        end

        def management
          @management ||= Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
        end

        def space
          @space ||= management.spaces.find(ENV['CONTENTFUL_SPACE_ID'])
        end

        def aws
          @aws ||= Aws::CloudSearchDomain::Client.new(endpoint: "https://#{ENV['CRDS_AWS_CSENDPOINT']}")
        end

    end
  end
end