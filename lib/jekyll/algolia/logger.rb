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

      # Public: Only display a log line if verbose mode is enabled
      #
      # line - The line to display, following the same format as .log
      def self.verbose(line)
        return unless Configurator.verbose?
        log(line)
      end

      # Public: Displays a helpful error message for one of the knows errors
      #
      # message_id: A string identifying a know message
      # metadata: Hash of variables that can be used in the final text
      #
      # It will read files in ./errors/*.txt with the matching error and
      # display them using Jekyll internal logger.
      def self.known_message(message_id, metadata = {})
        file = File.expand_path(
          File.join(
            __dir__, '../..', 'errors', "#{message_id}.txt"
          )
        )

        # Convert all variables
        content = File.open(file).read
        metadata.each do |key, value|
          content.gsub!("{#{key}}", value)
        end

        # Display each line differently
        lines = content.each_line.map(&:chomp)
        lines.each do |line|
          log(line)
        end
      end
    end
  end
end
