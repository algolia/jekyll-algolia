# Expose gem version
class AlgoliaSearchJekyllVersion
  MAJOR = 0
  MINOR = 5
  PATCH = 1
  BUILD = nil

  def self.to_s
    [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end
