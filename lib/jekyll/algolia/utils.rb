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
    end
  end
end
