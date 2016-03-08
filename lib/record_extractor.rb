require 'algoliasearch'
require 'nokogiri'
require 'json'

# Given an HTML file as input, will return an array of records to index
class AlgoliaSearchRecordExtractor
  attr_reader :file

  def initialize(file)
    @file = file
    @config = file.site.config
    default_config = {
      'record_css_selector' => 'p'
    }
    @config = default_config.merge(file.site.config['algolia'])
  end

  # Hook to modify a record after extracting
  def custom_hook_each(item, _node)
    item
  end

  # Hook to modify all records after extracting
  def custom_hook_all(items)
    items
  end

  # Returns metadata from the current file
  def metadata
    metadata = {}
    @file.data.each { |key, value| metadata[key.to_sym] = value }

    metadata[:type] = @file.class.name.split('::')[1].downcase
    metadata[:url] = @file.url

    metadata[:slug] = slug

    metadata[:posted_at] = @file.date.to_time.to_i if @file.respond_to? :date
    metadata[:tags] = tags

    metadata
  end

  # Returns the slug of the document
  def slug
    # Jekyll v3 has it in data
    return @file.data['slug'] if @file.data.key?('slug')
    # Old Jekyll v2 has it at the root
    return @file.slug if @file.respond_to? :slug
    # Otherwise, we guess it from the filename
    basename = File.basename(@file.path)
    extname = File.extname(basename)
    File.basename(basename, extname)
  end

  # Extract a list of tags
  def tags
    tags = nil

    # Jekyll v3 has it in data, while v2 have it at the root
    if @file.data.key?('tags')
      tags = @file.data['tags']
    elsif @file.respond_to? :tags
      tags = @file.tags
    end

    return tags if tags.nil?

    # Anyway, we force cast it to string as some plugins will extend the tags to
    # full featured objects
    tags.map(&:to_s)
  end

  # Get the list of all HTML nodes to index
  def html_nodes
    document = Nokogiri::HTML(@file.content)
    document.css(@config['record_css_selector'])
  end

  # Check if node is a heading
  def node_heading?(node)
    %w(h1 h2 h3 h4 h5 h6).include?(node.name)
  end

  # Get the closest heading parent
  def node_heading_parent(node, level = 'h7')
    # If initially called on a heading, we only accept stronger headings
    level = node.name if level == 'h7' && node_heading?(node)

    previous = node.previous_element

    # No previous element, we go up to the parent
    unless previous
      parent = node.parent
      # No more parent, then no heading found
      return nil if parent.name == 'body'
      return node_heading_parent(parent, level)
    end

    # This is a heading, we return it
    return previous if node_heading?(previous) && previous.name < level

    node_heading_parent(previous, level)
  end

  # Get all the parent headings of the specified node
  # If the node itself is a heading, we include it
  def node_hierarchy(node, state = { level: 7 })
    tag_name = node.name
    level = tag_name.delete('h').to_i

    if node_heading?(node) && level < state[:level]
      state[tag_name.to_sym] = node_text(node)
      state[:level] = level
    end

    heading = node_heading_parent(node)

    # No previous heading, we can stop the recursion
    unless heading
      state.delete(:level)
      return state
    end

    node_hierarchy(heading, state)
  end

  # Return the raw HTML of the element to index
  def node_raw_html(node)
    node.to_s
  end

  # Return the text of the element, sanitized to be displayed
  def node_text(node)
    node.content.gsub('<', '&lt;').gsub('>', '&gt;')
  end

  # Returns a unique string of hierarchy from title to h6, used for distinct
  def unique_hierarchy(data)
    headings = %w(title h1 h2 h3 h4 h5 h6)
    headings.map { |heading| data[heading.to_sym] }.compact.join(' > ')
  end

  # Returns a hash of two CSS selectors. One for the node itself, and one its
  # closest heading parent
  def node_css_selector(node)
    return nil if node.nil?

    # Use the CSS id if one is set
    return "##{node['id']}" if node['id']

    # Default Nokogiri selector
    node.css_path.gsub('html > body > ', '')
  end

  # The more words are in common between this node and its parent heading, the
  # higher the score
  def weight_heading_relevance(data)
    # Get list of unique words in headings
    title_words = %i(title h1 h2 h3 h4 h5 h6)
                  .select { |title| data.key?(title) }
                  .map { |title| data[title].to_s.split(/\W+/) }
                  .flatten
                  .compact
                  .map(&:downcase)
                  .uniq
    # Intersect words in headings with words in test
    text_words = data[:text].downcase.split(/\W+/)
    (title_words & text_words).size
  end

  # Returns a weight based on the tag_name
  def weight_tag_name(item)
    tag_name = item[:tag_name]
    # No a heading, no weight
    return 0 unless %w(h1 h2 h3 h4 h5 h6).include?(tag_name)
    # h1: 100, h2: 90, ..., h6: 50
    100 - (tag_name.delete('h').to_i - 1) * 10
  end

  # Returns an object of all weights
  def weight(item, index)
    {
      tag_name: weight_tag_name(item),
      heading_relevance: weight_heading_relevance(item),
      position: index
    }
  end

  def extract
    items = []
    html_nodes.each_with_index do |node, index|
      next if node.text.empty?

      item = metadata.clone
      item.merge!(node_hierarchy(node))
      item[:tag_name] = node.name
      item[:raw_html] = node_raw_html(node)
      item[:text] = node_text(node)
      item[:unique_hierarchy] = unique_hierarchy(item)
      item[:css_selector] = node_css_selector(node)
      item[:css_selector_parent] = node_css_selector(node_heading_parent(node))
      item[:weight] = weight(item, index)

      # We pass item through the user defined custom hook
      item = custom_hook_each(item, node)
      next if item.nil?

      items << item
    end
    custom_hook_all(items)
  end
end
