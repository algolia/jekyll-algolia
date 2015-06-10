require 'algoliasearch'
require 'nokogiri'
require 'json'

# `jekyll algolia push` command
class AlgoliaSearchJekyllPush < Jekyll::Command
  class << self
    def init_with_program(_prog)
    end

    def process(args = [], options = {}, config = {})
      @args = args
      @options = options
      @config = config

      index_name = args[0]

      @config['algolia']['index_name'] = index_name if index_name
      site = Jekyll::Site.new(@config)

      # Instead of writing generated website to disk, we will push it to the
      # index
      def site.write
        items = []
        each_site_file do |file|
          new_items = AlgoliaSearchJekyllPush.get_items_from_file(file)
          next if new_items.nil?
          items += new_items
        end
        AlgoliaSearchJekyllPush.push(items)
      end

      site.process
    end

    def markdown?(filename)
      ext = File.extname(filename).delete('.')
      @config['markdown_ext'].split(',').include?(ext)
    end

    def check_credentials(api_key, application_id, index_name)
      unless api_key
        Jekyll.logger.error 'Algolia Error: No API key defined'
        Jekyll.logger.warn '  You have two ways to configure your API key:'
        Jekyll.logger.warn '    - The ALGOLIA_API_KEY environment variable'
        Jekyll.logger.warn '    - A file named ./_algolia_api_key'
        exit 1
      end

      unless application_id
        Jekyll.logger.error 'Algolia Error: No application ID defined'
        Jekyll.logger.warn '  Please set your application id in the '\
                           '_config.yml file, like so:'
        puts ''
        # The spaces are needed otherwise the text is centered
        Jekyll.logger.warn '  algolia:         '
        Jekyll.logger.warn '    application_id: \'{your_application_id}\''
        puts ''
        Jekyll.logger.warn '  Your application ID can be found in your algolia'\
                           ' dashboard'
        Jekyll.logger.warn '    https://www.algolia.com/licensing'
        exit 1
      end

      unless index_name
        Jekyll.logger.error 'Algolia Error: No index name defined'
        Jekyll.logger.warn '  Please set your index name in the _config.yml'\
                           ' file, like so:'
        puts ''
        # The spaces are needed otherwise the text is centered
        Jekyll.logger.warn '  algolia:         '
        Jekyll.logger.warn '    index_name: \'{your_index_name}\''
        puts ''
        Jekyll.logger.warn '  You can edit your indices in your dashboard'
        Jekyll.logger.warn '    https://www.algolia.com/explorer'
        exit 1
      end
      true
    end

    def configure_index(index)
      index.set_settings(
        attributeForDistinct: 'parent_id',
        attributesForFaceting: %w(tags type),
        attributesToHighlight: %w(title content),
        attributesToIndex: %w(title h1 h2 h3 h4 h5 h6 content tags),
        attributesToRetrieve: %w(title posted_at content url),
        customRanking: ['desc(posted_at)'],
        distinct: true,
        highlightPreTag: '<span class="algolia__result-highlight">',
        highlightPostTag: '</span>'
      )
    end

    def push(items)
      api_key = AlgoliaSearchJekyll.api_key
      application_id = @config['algolia']['application_id']
      index_name = @config['algolia']['index_name']
      check_credentials(api_key, application_id, index_name)

      Algolia.init(application_id: application_id, api_key: api_key)
      index = Algolia::Index.new(index_name)
      configure_index(index)
      index.clear_index

      items.each_slice(1000) do |batch|
        Jekyll.logger.info "Indexing #{batch.size} items"
        begin
          index.add_objects(batch)
        rescue StandardError => error
          Jekyll.logger.error 'Algolia Error: HTTP Error'
          Jekyll.logger.warn error.message
          exit 1
        end
      end

      Jekyll.logger.info "Indexing of #{items.size} items done."
    end

    def get_items_from_file(file)
      is_page = file.is_a?(Jekyll::Page)
      is_post = file.is_a?(Jekyll::Post)

      # We only index posts, and markdown pages
      return nil unless is_page || is_post
      return nil if is_page && !markdown?(file.path)

      html = file.content.gsub("\n", ' ')

      if is_post
        tags = file.tags.map { |tag| tag.gsub(',', '') }
        base_data = {
          type: 'post',
          parent_id: file.id,
          url: file.url,
          title: file.title,
          tags: tags,
          slug: file.slug,
          posted_at: file.date.to_time.to_i
        }
      else
        base_data = {
          type: 'page',
          parent_id: file.basename,
          url: file.url,
          title: file['title'],
          slug: file.basename
        }
      end

      base_data.merge!(get_hx_from_html(html))

      get_paragraphs_from_html(html).map.with_index do |item, index|
        new_item = base_data.clone
        new_item[:objectID] = "#{new_item[:parent_id]}_#{index}"
        new_item[:content] = item
        new_item
      end
    end

    def get_paragraphs_from_html(html)
      doc = Nokogiri::HTML(html)
      doc.css('p').map(&:to_s)
    end

    def get_hx_from_html(html)
      doc = Nokogiri::HTML(html)
      data = {}
      %w(h1 h2 h3 h4 h5 h6).each do |hx|
        data[hx.to_sym] = doc.css(hx).map(&:text)
      end
      data
    end
  end
end
