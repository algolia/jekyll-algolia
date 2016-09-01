# Expose gem version
class AlgoliaSearchJekyllVersion
  def self.to_s
    '1.0.0.beta-1'
  end

  # Return the current Algolia client version
  def self.client
    Algolia::VERSION
  end

  # Return the current Jekyll version
  def self.jekyll
    Jekyll::VERSION
  end

  # Return the current Ruby version
  def self.ruby
    RUBY_VERSION
  end
end
