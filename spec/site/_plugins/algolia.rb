# frozen_string_literal: true

module Jekyll
  # Custom hooks
  module Algolia
    def self.hook_should_be_excluded?(filepath)
      filepath == 'excluded-from-hook.html'
    end

    def self.hook_before_indexing_each(record, _node)
      record[:added_through_each] = true
      record
    end

    def self.hook_before_indexing_all(records)
      records << {
        name: 'Last one'
      }
      records
    end
  end
end
