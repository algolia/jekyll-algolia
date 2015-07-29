require 'rubygems'
require 'bundler/setup'

require 'awesome_print'

require_relative './version'
require_relative './push'

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
            default_options = {
              'dry_run' => false,
              'verbose' => false
            }
            options = default_options.merge(options)
            @config = configuration_from_options(options)

            AlgoliaSearchJekyllPush.init_options(args, options, @config)
                                   .jekyll_new(@config)
                                   .process
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
      command.option 'dry_run', '--dry-run', '-n',
                     'Do a dry run, do not push records'
      command.option 'verbose', '--verbose',
                     'Display more information on what is indexed'
    end
  end
end
