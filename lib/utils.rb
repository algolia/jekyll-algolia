# Generic util helpers
class AlgoliaSearchUtils
  # Check the current Jekyll version
  def self.restrict_jekyll_version(more_than: nil, less_than: nil)
    jekyll_version = Gem::Version.new(Jekyll::VERSION)
    minimum_version = Gem::Version.new(more_than)
    maximum_version = Gem::Version.new(less_than)

    return false if !more_than.nil? && jekyll_version < minimum_version
    return false if !less_than.nil? && jekyll_version > maximum_version
    true
  end
end
