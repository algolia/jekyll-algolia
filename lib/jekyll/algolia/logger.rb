module Jekyll
  module Algolia
    # Display helpful error messages
    module Logger
      # Public: Displays a log line
      #
      # line - Line to display. Expected to be of the following format:
      #   "X:Your content"
      # Where X is either I, W or E for marking respectively an info, warning or
      # error display
      def self.log(line)
        type, content = /^(I|W|E):(.*)/.match(line).captures
        logger_mapping = {
          'E' => :error,
          'I' => :info,
          'W' => :warn
        }

        # Jekyll logger tries to center log lines, so we force a consistent
        # width of 80 chars
        content = content.ljust(80, ' ')
        Jekyll.logger.send(logger_mapping[type], content)
      end

      # Public: Displays a helpful error message for one of the knows errors
      #
      # message_id: A string identifying a know message
      #
      # It will read files in ./errors/*.txt with the matching error and
      # display them using Jekyll internal logger.
      def self.known_message(message_id)
        file = File.expand_path(
          File.join(
            File.dirname(__FILE__), '../../..', 'errors', "#{message_id}.txt"
          )
        )

        # Display each line differently
        lines = File.open(file).readlines.map(&:chomp)
        lines.each do |line|
          log(line)
        end
      end
    end
  end
end
