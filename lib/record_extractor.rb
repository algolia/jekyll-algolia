require 'algoliasearch'
require 'nokogiri'
require 'json'
require 'html-hierarchy-extractor'
require_relative './utils'

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

  ##
  # Return the type of the Jekyll element
  # It can be either page, post or document
  def type
    classname = @file.class.name
    subclass = classname.split('::')[1]
    type = subclass.downcase

    # In Jekyll v2, Page, Post and Document have their own class
    return type if AlgoliaSearchUtils.restrict_jekyll_version(less_than: '3.0')

    # In Jekyll v3, Post are actually a specific type of Documents
    if type == 'document'
      collection_name = @file.collection.instance_variable_get('@label')
      return 'post' if collection_name == 'posts'
    end

    type
  end

  ##
  # Return the url of the page
  def url
    @file.url
  end

  ##
  # Return the title of the page
  def title
    @file.data['title']
  end

  ##
  # Returns the slug of the document
  def slug
    # We can guess the slug from the filename for all documents
    basename = File.basename(@file.path)
    extname = File.extname(basename)
    slug = File.basename(basename, extname)

    # Jekyll v3 posts have it in data
    return @file.data['slug'] if @file.data.key?('slug')

    # Jekyll v2 posts have a specific slug method
    return @file.slug if @file.respond_to?(:slug)

    slug
  end

  ##
  # Get an array of tags of the document
  def tags
    tags = []

    is_v2 = AlgoliaSearchUtils.restrict_jekyll_version(less_than: '3.0')
    is_v3 = AlgoliaSearchUtils.restrict_jekyll_version(more_than: '3.0')
    has_tags_method = @file.respond_to?(:tags)
    has_tags_data = @file.data.key?('tags')

    # Starting from Jekyll v3, all tags are in data['tags']
    tags = @file.data['tags'] if is_v3 && has_tags_data

    # In Jekyll v2, tags are in data['tags'], or in .tags
    if is_v2
      tags = @file.tags if has_tags_method
      tags = @file.data['tags'] if tags.empty? && has_tags_data
    end

    # Some extension extends the tags with custom classes, so we make sure we
    # cast them as strings
    tags.map(&:to_s)
  end

  ##
  # Get the post date timestamp
  def date
    return nil unless @file.respond_to?(:date)

    @file.date.to_time.to_i
  end

  ##
  # Get a hash of all front-matter data
  def front_matter
    raw_data = @file.data

    # We clean some keys that will be handled by specific methods
    attributes_to_remove = %w(title tags slug url date type)
    attributes_to_remove.each do |attribute|
      raw_data.delete(attribute)
    end

    # Convert to symbols
    data = {}
    raw_data.each do |key, value|
      data[key.to_sym] = value
    end

    data
  end

  ##
  # Get the list of all node data
  def hierarchy_nodes
    extractor_options = {
      css_selector: @config['record_css_selector']
    }

    HTMLHierarchyExtractor.new(
      @file.content,
      options: extractor_options
    ).extract
  end

  # Extract all records from the page and return the list
  def extract
    # Getting all hierarchical nodes from the HTML input
    raw_items = hierarchy_nodes

    # Shared attributes relative to the page that all records will have
    shared_attributes = {
      type: type,
      url: url,
      title: title,
      slug: slug,
      date: date,
      tags: tags
    }

    # Enriching with page metadata
    items = []
    raw_items.each do |raw_item|
      nokogiri_node = raw_item[:node]
      raw_item.delete(:node)
      item = shared_attributes.merge(raw_item)

      item = custom_hook_each(item, nokogiri_node)
      next if item.nil?

      items << item
    end

    custom_hook_all(items)
  end
end
