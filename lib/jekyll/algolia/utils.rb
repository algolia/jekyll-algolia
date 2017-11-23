# frozen_string_literal: true

require 'nokogiri'

module Jekyll
  module Algolia
    # Generic language-wide utils
    module Utils
      # Public: Convert a hash with string keys to a hash with symbol keys
      #
      # hash - The input hash, with string keys
      def self.keys_to_symbols(hash)
        Hash[hash.map { |key, value| [key.to_sym, value] }]
      end

      # Public: Convert an HTML string to its content only
      #
      # html - String representation of the HTML node
      def self.html_to_text(html)
        text = Nokogiri::HTML(html).text
        text.tr("\n", ' ').squeeze(' ').strip
      end

      # Public: Remove all keys with a nil value or an empty array from a hash
      #
      # hash - The input hash
      def self.compact_empty(hash)
        new_hash = {}
        hash.each do |key, value|
          next if value.nil?
          next if value.respond_to?(:empty?) && value.empty?
          new_hash[key] = value
        end
        new_hash
      end

      # Public: Check if a string matches a regex
      #
      # string - The string to test
      # regex - The regex to match against
      #
      # Newer versions of Ruby have easy ways to test this, but a wrapper is
      # needed for older versions.
      def self.match?(string, regex)
        # Ruby 2.4 introduces .match?
        return regex.match?(string) if regex.respond_to?(:match?)

        # Older versions of Ruby have to deal with =~ returning nil if no match
        # is found
        !(string =~ regex).nil?
      end

      # Public: Find an item from an array based on the value of one of its key
      #
      # items - The array of hashes to search
      # key - The key to search for
      # value - The value of the key to filter
      #
      # It is basically a wrapper around [].find, handling more edge-cases
      def self.find_by_key(items, key, value)
        return nil if items.nil?
        items.find do |item|
          item[key] == value
        end
      end
    end
  end
end
