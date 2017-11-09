module Jekyll
  # Custom hooks
  module Algolia
    def self.hook_should_be_excluded?(filepath)
      filepath == 'excluded-from-hook.html'
    end
  end
end
