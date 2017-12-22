# frozen_string_literal: true

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
      # rubocop:disable Naming/PredicateName
      def self.is_404?(file)
        File.basename(file.path, File.extname(file.path)) == '404'
      end
      # rubocop:enable Naming/PredicateName

      # Public: Check if the page is a pagination page
      #
      # file - The Jekyll file
      #
      # `jekyll-paginate` automatically creates pages to paginate through posts.
      # We don't want to index those
      def self.pagination_page?(file)
        Utils.match?(file.path, %r{page([0-9]*)/index\.html$})
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
        extensions = Configurator.algolia('extensions_to_index')
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
        excluded_patterns = Configurator.algolia('files_to_exclude')
        excluded_files = []

        # Transform the glob patterns into a real list of files
        Dir.chdir(Configurator.get('source')) do
          excluded_patterns.each do |pattern|
            excluded_files += Dir.glob(pattern)
          end
        end

        excluded_files.include?(file.path)
      end

      # Public: Check if the file has been excluded by running a custom user
      # hook
      #
      # file - The Jekyll file
      def self.excluded_from_hook?(file)
        Hooks.should_be_excluded?(file.path)
      end

      # Public: Return the path to the original file, relative from the Jekyll
      # source
      #
      # file - The Jekyll file
      #
      # Pages have their .path property relative to the source, but collections
      # (including posts) have an absolute file path.
      def self.path_from_root(file)
        source = Configurator.get('source')
        file.path.gsub(%r{^#{source}/}, '')
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

      # Public: Return a hash of all the file metadata
      #
      # file - The Jekyll file
      #
      # It contains both the raw metadata extracted from the front-matter, as
      # well as more specific fields like the collection name, date timestamp,
      # slug, type and url
      def self.metadata(file)
        raw_data = raw_data(file)
        specific_data = {
          collection: collection(file),
          date: date(file),
          excerpt_html: excerpt_html(file),
          excerpt_text: excerpt_text(file),
          slug: slug(file),
          type: type(file),
          url: url(file)
        }

        metadata = Utils.compact_empty(raw_data.merge(specific_data))

        metadata
      end

      # Public: Return a hash of all the raw data, as defined in the
      # front-matter and including default values
      #
      # file - The Jekyll file
      #
      # Any custom data passed to the front-matter will be returned by this
      # method. It ignores any key where we have a better, custom, getter.

      # Note that even if you define tags and categories in a collection item,
      # it will not be included in the data. It's always an empty array.
      def self.raw_data(file)
        data = file.data.clone

        # Remove all keys where we have a specific getter
        data.each_key do |key|
          data.delete(key) if respond_to?(key)
        end

        # Also delete keys we manually handle
        data.delete('excerpt')

        # Convert all keys to symbols
        data = Utils.keys_to_symbols(data)

        data
      end

      # Public: Get the type of the document (page, post, collection, etc)
      #
      # file - The Jekyll file
      #
      # Pages are simple html and markdown documents in the tree
      # Elements from a collection are called Documents
      # Posts are a custom kind of Documents
      def self.type(file)
        type = file.class.name.split('::')[-1].downcase

        type = 'post' if type == 'document' && file.collection.label == 'posts'

        type
      end

      # Public: Returns the url of the file, starting from the root
      #
      # file - The Jekyll file
      def self.url(file)
        file.url
      end

      # Public: Returns a timestamp of the file date
      #
      # file - The Jekyll file
      #
      # All collections (including posts) will have a date taken either from the
      # front-matter or the filename prefix. If none is set, Jekyll will use the
      # current date.
      #
      # For pages, only dates defined in the front-matter will be used.
      #
      # Note that because the default date is the current one if none is
      # defined, we have to make sure the date is actually nil when we index it.
      # Otherwise the diff indexing mode will think that records have changed
      # while they haven't.
      def self.date(file)
        date = file.data['date']
        return nil if date.nil?

        # The date is *exactly* the time where the `jekyll algolia` was run.
        # What a coincidence! It's a safe bet to assume that the original date
        # was nil and has been overwritten by Jekyll
        return nil if date.to_i == Jekyll::Algolia.start_time.to_i

        date.to_i
      end

      # Public: Returns the HTML version of the excerpt
      #
      # file - The Jekyll file
      #
      # Only collections (including posts) have an excerpt. Pages don't.
      def self.excerpt_html(file)
        excerpt = file.data['excerpt']
        return nil if excerpt.nil?
        excerpt.to_s.tr("\n", ' ').strip
      end

      # Public: Returns the text version of the excerpt
      #
      # file - The Jekyll file
      #
      # Only collections (including posts) have an excerpt. Pages don't.
      def self.excerpt_text(file)
        html = excerpt_html(file)
        return nil if html.nil?
        Utils.html_to_text(html)
      end

      # Public: Returns the slug of the file
      #
      # file - The Jekyll file
      #
      # Slugs can be automatically extracted from collections, but for other
      # files, we have to create them from the basename
      def self.slug(file)
        # We get the real slug from the file data if available
        return file.data['slug'] if file.data.key?('slug')

        # We create it ourselves from the filepath otherwise
        File.basename(file.path, File.extname(file.path)).downcase
      end

      # Public: Returns the name of the collection
      #
      # file - The Jekyll file
      #
      # Only collection documents can have a collection name. Pages don't. Posts
      # are purposefully excluded from it as well even if they are technically
      # part of a collection
      def self.collection(file)
        return nil unless file.respond_to?(:collection)

        collection_name = file.collection.label

        # Posts are a special kind of collection, but it's an implementation
        # detail from my POV, so I'll exclude them
        return nil if collection_name == 'posts'

        collection_name
      end
    end
  end
end
