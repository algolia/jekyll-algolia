# frozen_string_literal: true

module Jekyll
  module Commands
    # Registering the `jekyll algolia` command
    class Algolia < Command
      class << self
        def init_with_program(prog)
          prog.command(:algolia) do |command|
            command.syntax 'algolia [options]'
            command.description 'Push your content to an Algolia index'
            # Document the options that can be passed from the CLI
            command.option 'config',
                           '--config CONFIG_FILE[,CONFIG_FILE2,...]',
                           Array,
                           'Custom configuration file'
            command.option 'future',
                           '--future',
                           'Index posts with a future date'
            command.option 'limit_posts',
                           '--limit_posts MAX_POSTS',
                           Integer,
                           'Limits the number of posts to parse and index'
            command.option 'show_drafts',
                           '-D',
                           '--drafts',
                           'Index posts in the _drafts folder'
            command.option 'unpublished',
                           '--unpublished',
                           'Index posts that were marked as unpublished'
            command.option 'dry_run',
                           '--dry-run',
                           '-n',
                           'Do a dry run, do not push records'
            command.option 'verbose',
                           '--verbose',
                           'Display more information on what is indexed'

            command.action do |_, options|
              configuration = configuration_from_options(options)

              Jekyll::Algolia.init(configuration).run
            end
          end
        end
      end
    end
  end
end
