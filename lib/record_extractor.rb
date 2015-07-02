require 'algoliasearch'
require 'nokogiri'
require 'json'

# Given an HTML file as input, will return an array of records to index
class AlgoliaSearchRecordExtractor
  def initialize(file)
    @file = file
  end

  # Returns metadata from the current file
  def metadata
    return metadata_page if @file.is_a?(Jekyll::Page)
    return metadata_post if @file.is_a?(Jekyll::Post)
    false
  end

  # Extract a list of tags
  def tags
    return nil unless @file.respond_to? :tags
    # Some plugins will extend the tags from simple strings to full featured
    # objects. We'll simply call .to_s to always have a string
    @file.tags.map(&:to_s)
  end

  # Extract metadata from a post
  def metadata_post
    {
      type: 'post',
      url: @file.url,
      title: @file.title,
      slug: @file.slug,
      posted_at: @file.date.to_time.to_i,
      tags: tags
    }
  end

  # Extract metadata from a page
  def metadata_page
    {
      type: 'page',
      url: @file.url,
      title: @file['title'],
      slug: @file.basename
    }
  end

  def extract
    ap metadata
  end
end
