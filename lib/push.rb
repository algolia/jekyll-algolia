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

    def parseable?(file)
      ext = file.ext.delete('.')
      # Allow markdown and html pages
      return true if @config['markdown_ext'].split(',').include?(ext)
      return false unless ext == 'html'
      return false unless file['title']
      true
    end

    def check_credentials(api_key, application_id, index_name)
      unless api_key
        Jekyll.logger.error 'Algolia Error: No API key defined'
        Jekyll.logger.warn '  You have two ways to configure your API key:'
        Jekyll.logger.warn '    - The ALGOLIA_API_KEY environment variable'
        Jekyll.logger.warn '    - A file named ./_algolia_api_key in your '\
                           'source folder'
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
        attributesToRetrieve: %w(title posted_at content url css_selector),
        customRanking: ['desc(posted_at)', 'desc(title_weight)'],
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

      Jekyll.logger.info "Indexing of #{items.size} items " \
                         "in #{index_name} done."
    end

    def get_items_from_file(file)
      is_page = file.is_a?(Jekyll::Page)
      is_post = file.is_a?(Jekyll::Post)

      # We only index posts, and markdown pages
      return nil unless is_page || is_post
      return nil if is_page && !parseable?(file)

      html = file.content.gsub("\n", ' ')

      if is_post
        tags = get_tags_from_post(file)
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

      get_paragraphs_from_html(html, base_data)
    end

    # Get a list of tags from a post. Handle both classic string tags or
    # extended object tags
    def get_tags_from_post(post)
      tags = post.tags
      return [] if tags.is_a?(Array) || tags.nil?
      tags.map! { |tag| tag.to_s.gsub(',', '') }
    end

    def get_previous_hx(node, memo = { level: 7 })
      previous = node.previous_sibling
      # Stop if no previous element
      unless previous
        memo.delete(:level)
        return memo
      end

      # Skip non-html elements
      return get_previous_hx(previous, memo) unless previous.element?

      # Skip non-title elements
      tag_name = previous.name
      possible_title_elements = %w(h1 h2 h3 h4 h5 h6)
      unless possible_title_elements.include?(tag_name)
        return get_previous_hx(previous, memo)
      end

      # Skip if item already as title of a higher level
      title_level = tag_name.gsub('h', '').to_i
      return get_previous_hx(previous, memo) if title_level >= memo[:level]
      memo[:level] = title_level

      # Add to the memo and continue
      memo[tag_name.to_sym] = previous.text
      get_previous_hx(previous, memo)
    end

    # Get a custom value representing the number of word occurence from the
    # titles into the content
    def get_title_weight(content, item)
      # Get list of words
      words = %i(title h1 h2 h3 h4 h5 h6)
              .select { |title| item.key?(title) }
              .map { |title| item[title].split(/\W+/) }
              .flatten
              .compact
              .uniq
      # Count how many words are in the text
      weight = 0
      words.each { |word| weight += 1 if content.include?(word) }
      weight
    end

    # Will get a unique css selector for the node
    def get_css_selector(node)
      node.css_path.gsub('html > body > ', '')
    end

    def get_paragraphs_from_html(html, base_data)
      doc = Nokogiri::HTML(html)
      doc.css('p').map.with_index do |p, index|
        new_item = base_data.clone
        new_item.merge!(get_previous_hx(p))
        new_item[:objectID] = "#{new_item[:parent_id]}_#{index}"
        new_item[:css_selector] = get_css_selector(p)
        new_item[:content] = p.to_s
        new_item[:title_weight] = get_title_weight(p.text, new_item)
        new_item
      end
    end
  end
end
