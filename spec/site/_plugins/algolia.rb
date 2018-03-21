# frozen_string_literal: true

module Jekyll
  module Algolia
    # Custom user hooks
    module Hooks
      def self.should_be_excluded?(filepath)
        filepath == 'excluded-from-hook.html'
      end

      def self.before_indexing_each(record, _node, _context)
        record[:added_through_each] = true
        record
      end

      def self.before_indexing_all(records, _context)
        records << {
          name: 'Last one'
        }
        records
      end
    end
  end
end
