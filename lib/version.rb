# Expose gem version
class AlgoliaSearchJekyllVersion
  MAJOR = 0
  MINOR = 4
  PATCH = 3
  BUILD = nil

  def self.to_s
    [MAJOR, MINOR, PATCH, BUILD].compact.join('.')
  end
end
