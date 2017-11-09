module Jekyll
  # Hooks that can be safely overwritten by the user
  module Algolia
    # Public: Check if the file should be indexed or not
    #
    # filepath - The path to the file, before transformation
    #
    # This hook allow users to define if a specific file should be indexed or
    # not. Basic exclusion can be done through the `nodes_to_exclude` option,
    # but a custom hook like this one can allow more fine-grained customisation.
    def hook_should_be_excluded?(_filepath)
      true
    end
  end
end
