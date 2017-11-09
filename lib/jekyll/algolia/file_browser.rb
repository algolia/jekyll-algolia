require 'algolia_html_extractor'

module Jekyll
  module Algolia
    # Module to get information about Jekyll file. Jekyll handles posts, pages,
    # collection, etc. They each need specific processing, so knowing which kind
    # of file we're working on will help.
    #
    # We also do not index all files. This module will help in defining which
    # files should be indexed and which should not.
    module FileBrowser
      include Jekyll::Algolia

      # Public: Check if the specified file is a static Jekyll asset
      #
      # file - The Jekyll file
      #
      # We don't index static assets (js, css, images)
      def self.static_file?(file)
        file.is_a?(Jekyll::StaticFile)
      end

      # Public: Check if the file is a 404 error page
      #
      # file - The Jekyll file
      #
      # 404 pages are not Jekyll defaults but a convention adopted by GitHub
      # pages. We don't want to index those.
      # Source: https://help.github.com/articles/creating-a-custom-404-page-for-your-github-pages-site/
      #
      # rubocop:disable Style/PredicateName
      def self.is_404?(file)
        File.basename(file.path, File.extname(file.path)) == '404'
      end
      # rubocop:enable Style/PredicateName

      # Public: Check if the page is a pagination page
      #
      # file - The Jekyll file
      #
      # `jekyll-paginate` automatically creates pages to paginate through posts.
      # We don't want to index those
      def self.pagination_page?(file)
        %r{page([0-9]*)/index\.html$}.match?(file.path)
      end

      # Public: Check if the file has one of the allowed extensions
      #
      # file - The Jekyll file
      #
      # Jekyll can transform markdown files to HTML by default. With plugins, it
      # can convert many more file formats. By default we'll only index markdown
      # and raw HTML files but this list can be extended using the
      # `extensions_to_index` config option.
      def self.allowed_extension?(file)
        extensions = Configurator.algolia('extensions_to_index').split(',')
        extname = File.extname(file.path)[1..-1]
        extensions.include?(extname)
      end

      # Public: Check if the file has been excluded by the user
      #
      # file - The Jekyll file
      #
      # Files can be excluded either by setting the `files_to_exclude` option,
      # or by defining a custom hook
      def self.excluded_by_user?(file)
        excluded_from_config?(file) || excluded_from_hook?(file)
      end

      # Public: Check if the file has been excluded by `files_to_exclude`
      #
      # file - The Jekyll file
      def self.excluded_from_config?(file)
        excluded_files = Configurator.algolia('files_to_exclude')
        excluded_files.include?(file.path)
      end

      # Public: Check if the file has been excluded by running a custom user
      # hook
      #
      # file - The Jekyll file
      def self.excluded_from_hook?(file)
        Jekyll::Algolia.hook_should_be_excluded?(file.path)
      end

      # Public: Check if the file should be indexed
      #
      # file - The Jekyll file
      #
      # There are many reasons a file should not be indexed. We need to exclude
      # all the static assets, only keep the actual content.
      def self.indexable?(file)
        return false if static_file?(file)
        return false if is_404?(file)
        return false if pagination_page?(file)
        return false unless allowed_extension?(file)
        return false if excluded_by_user?(file)

        true
      end
    end
  end
end
