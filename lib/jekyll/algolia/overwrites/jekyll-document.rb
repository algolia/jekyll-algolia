# frozen_string_literal: true

module Jekyll
  # Overwriting the Jekyll::Document class
  class Document
    # By default, Jekyll will set the current date (time of build) to any
    # collection item. This will break our diff algorithm, so we monkey patch
    # this call to return nil if no date is defined and the file is not a
    # draft instead.
    def date
      data["date"] ||= (draft? ? source_file_mtime : nil)
    end
  end
end
