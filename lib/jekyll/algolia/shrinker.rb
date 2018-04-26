# frozen_string_literal: true

require 'json'
module Jekyll
  module Algolia
    # Module to shrink a record so it fits in the plan quotas
    module Shrinker
      include Jekyll::Algolia

      # Public: Get the byte size of the object once converted to JSON
      # - record: The record to estimate
      def self.size(record)
        record.to_json.length
      end

      # Public: Attempt to reduce the size of the record by reducing the size of
      # the less needed attributes
      #
      # - raw_record: The record to attempt to reduce
      # - max_size: The max size to achieve in bytes
      #
      # The excerpts are the attributes most subject to being reduced. We'll go
      # as far as removing them if there is no other choice.
      def self.fit_to_size(raw_record, max_size)
        return raw_record if size(raw_record) <= max_size

        # No excerpt, we can't shrink it
        return raw_record unless raw_record.key?(:excerpt_html)

        record = raw_record.clone

        # We replace the HTML excerpt with the textual one
        record[:excerpt_html] = record[:excerpt_text]
        return record if size(record) <= max_size

        # We halve the excerpts
        excerpt_words = record[:excerpt_text].split(/\s+/)
        shortened_excerpt = excerpt_words[0...excerpt_words.size / 2].join(' ')
        record[:excerpt_text] = shortened_excerpt
        record[:excerpt_html] = shortened_excerpt
        return record if size(record) <= max_size

        # We remove the excerpts completely
        record[:excerpt_text] = nil
        record[:excerpt_html] = nil

        record
      end
    end
  end
end
