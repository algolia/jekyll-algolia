require 'rubygems'
require 'bundler/setup'

require 'awesome_print'

require_relative './push.rb'

# `jekyll algolia` main entry
class AlgoliaSearchJekyll < Jekyll::Command
  class << self
    def init_with_program(prog)
      prog.command(:algolia) do |command|
        command.syntax 'algolia <command> [options]'
        command.description 'Keep your content in sync with your Algolia index'

        command.command(:push) do |subcommand|
          subcommand.syntax 'push [options]'
          subcommand.description 'Push your content to your index'

          add_build_options(subcommand)

          subcommand.action do |args, options|
            @config = configuration_from_options(options)
            AlgoliaSearchJekyllPush.process(args, options, @config)
          end
        end
      end
    end

    # Allow a subset of the default `jekyll build` options
    def add_build_options(command)
      command.option 'config', '--config CONFIG_FILE[,CONFIG_FILE2,...]',
                     Array, 'Custom configuration file'
      command.option 'future', '--future', 'Index posts with a future date'
      command.option 'limit_posts', '--limit_posts MAX_POSTS', Integer,
                     'Limits the number of posts to parse and index'
      command.option 'show_drafts', '-D', '--drafts',
                     'Index posts in the _drafts folder'
      command.option 'unpublished', '--unpublished',
                     'Index posts that were marked as unpublished'
    end

    def api_key
      return ENV['ALGOLIA_API_KEY'] if ENV['ALGOLIA_API_KEY']
      key_file = File.join(@config['source'], '_algolia_api_key')

      if File.exist?(key_file) && File.size(key_file) > 0
        return File.open(key_file).read.strip
      end
      nil
    end
  end
end
