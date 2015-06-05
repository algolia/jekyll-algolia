require 'nokogiri'
require 'json'

# `jekyll algolia push` command
class AlgoliaSearchJekyllPush < Jekyll::Command
  class << self
    def init_with_program(_prog)
    end

    def process(args = [], options = {})
      index_name = args[0]
      puts "Pushing to #{index_name} with options #{options}"

      @config = configuration_from_options(options)
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

    def push(items)
      api_key = AlgoliaSearchJekyll.api_key
      unless api_key
        Jekyll.logger.error 'Algolia Error: No API key defined'
        Jekyll.logger.warn '  You have two ways to configure your API key:'
        Jekyll.logger.warn '    - The ALGOLIA_API_KEY environment variable'
        Jekyll.logger.warn '    - A file named ./_algolia_api_key'
        exit 1
      end
      p items
    end

    def get_items_from_file(file)
      is_page = file.is_a?(Jekyll::Page)
      is_post = file.is_a?(Jekyll::Post)

      # We only index posts, and markdown pages
      return nil unless is_page || is_post
      return nil if is_page && !markdown?(file.path)

      html = file.content.gsub("\n", ' ')

      if is_post
        base_data = {
          type: 'post',
          parent_id: file.id,
          url: file.url,
          title: file.title,
          tags: file.tags,
          slug: file.slug,
          posted_at: file.date.to_time.to_i
        }
      else
        base_data = {
          type: 'page',
          parent_id: file.basename,
          url: file.url,
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
