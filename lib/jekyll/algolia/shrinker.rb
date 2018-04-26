# frozen_string_literal: true

require 'json'
module Jekyll
  module Algolia
    # Module to shrink a record so it fits in the plan quotas
    module Shrinker
      include Jekyll::Algolia

      def self.size(record)
        record.to_json.length
      end

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

        p size(record)
        p record

        record
      end
    end
  end
end
