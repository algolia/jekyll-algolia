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

  def tags
    "hhh"
  end

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
