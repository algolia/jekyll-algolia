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
          subcommand.syntax 'push [INDEX_NAME] [options]'
          subcommand.description 'Push your content to your index'

          subcommand.action do |args, options|
            @config = configuration_from_options(options)
            AlgoliaSearchJekyllPush.process(args, options, @config)
          end
        end
      end
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
