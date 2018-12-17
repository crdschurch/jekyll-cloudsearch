module Jekyll
  module Cloudsearch
    class Client

      attr_accessor :filename, :site, :docs, :search_excluded_ids

      def initialize
        @docs = []
        @search_excluded_ids = []
        @markdown = Jekyll::Converters::Markdown.new
        @markdown.instance_variable_set('@config', { 'markdown' => 'kramdown' })
      end

      def run
        write
        upload
      end

      def write
        path = File.join(local_cache_dir, filename)
        FileUtils.mkdir_p(local_cache_dir)
        Jekyll.logger.info('AWS Cloudsearch:', "Writing #{path}...")
        File.open(path,"w") do |f|
          f.puts(@docs.to_json)
        end
        persist_to_build_cache!
      end

      def upload
        Jekyll.logger.info('AWS Cloudsearch:', "Uploading documents to AWS...")
        aws.upload_documents({
          content_type: "application/json",
          documents: (deletions + @docs).to_json
        })
      end

      def add_document(doc)
        if doc.data.dig('search_excluded') || ! doc.collection.metadata.dig('output')
          @search_excluded_ids.push("CF_#{ENV['CONTENTFUL_SPACE_ID']}_#{doc.data.dig('id')}")
        else

          fields = doc.site.config.dig('cloudsearch', doc.collection.label.singularize)
          if fields.nil?
            content = doc.content
          else
            content = @markdown.convert(fields.collect{|f| doc.data.dig(f).try(:strip) }.compact.reverse.join("\n"))
          end

          @docs.push({
            id: "CF_#{ENV['CONTENTFUL_SPACE_ID']}_#{doc.data.dig('id')}",
            type: 'add',
            fields: {
              title: doc.data.dig('title'),
              content: ::Nokogiri::HTML(content, &:noblanks).text,
              link: url(doc),
              type: doc.data.dig('index_type') || 'MediaResource'
            }
          })
        end
      end

      def deletions
        (stale_ids + unpublished_ids + @search_excluded_ids).collect do |id|
          { id: id, type: 'delete' }
        end
      end

      def persist_to_build_cache!
        if local_cache_dir != build_cache_dir
          src = File.join(local_cache_dir, filename)
          dest = File.join(build_cache_dir, filename)
          FileUtils.mkdir_p(build_cache_dir)
          FileUtils.cp(src, dest)
        end
      end

      private

        def manifest
          if manifest_file.nil?
            []
          else
            JSON.parse(File.read(manifest_file)).collect{|c| c.dig('id')}
          end
        end

        def manifest_file
          file = Dir.glob("#{build_cache_dir}/cloudsearch-*").max_by {|f|
            timestamp = File.basename(f).sub(/cloudsearch-([0-9]*).json/,'\1')
            Date.parse(timestamp).to_time.to_i rescue 0
          }
        end

        def unpublished_ids
          unpublished_ids = space.entries.all.collect{|e|
            uid(e) if !e.published? || e.archived?
          }.compact
        end

        def stale_ids
          if manifest.empty?
            []
          else
            new_ids = @docs.collect{|d|d.dig(:id)}
            stale_ids = manifest - new_ids
          end
        end

        def url(doc)
          "#{ENV['AWS_CLOUDSEARCH_BASE_URL']}#{doc.url}"
        end

        def uid(doc)
          "CF_#{ENV['CONTENTFUL_SPACE_ID']}_#{doc.id}"
        end

        def filename
          @filename ||= "cloudsearch-#{Time.now.strftime("%Y%m%d%H%M%S")}.json"
        end

        def management
          @management ||= ::Contentful::Management::Client.new(ENV['CONTENTFUL_MANAGEMENT_TOKEN'])
        end

        def space
          @space ||= management.spaces.find(ENV['CONTENTFUL_SPACE_ID'])
        end

        def aws
          @aws ||= ::Aws::CloudSearchDomain::Client.new(endpoint: "https://#{ENV['AWS_CLOUDSEARCH_ENDPOINT']}")
        end

        def local_cache_dir
          File.join(site.source, '.aws')
        end

        def build_cache_dir
          ENV['NETLIFY_CACHE_DIR'] || local_cache_dir
        end

    end
  end
end
