require File.join(File.dirname(__FILE__), 'lib/jekyll/algolia/version.rb')

Gem::Specification.new do |gem|
  # Required attributes
  gem.name = 'jekyll-algolia'
  gem.summary = 'Index your Jekyll content into Algolia'
  gem.version = Jekyll::Algolia::VERSION

  # Recommended attributes
  gem.authors = ['Tim Carry']
  gem.description = 'Index all your content into Algolia by '\
    'running `jekyll algolia`'
  gem.email = 'tim@pixelastic.com'
  gem.homepage = 'https://github.com/algolia/jekyll-algolia'
  gem.licenses = ['MIT']

  # Supported Ruby versions
  gem.required_ruby_version = ">= 2.3.0"

  # Dependencies
  gem.add_runtime_dependency 'algoliasearch', '~> 1.18'
  gem.add_runtime_dependency 'algolia_html_extractor', '~> 2.1'
  gem.add_runtime_dependency 'awesome_print', '~> 1.8'
  gem.add_runtime_dependency 'filesize', '~> 0.1'
  gem.add_runtime_dependency 'jekyll', '~> 3.6'
  gem.add_runtime_dependency 'jekyll-paginate', '~> 1.1'
  gem.add_runtime_dependency 'json', '~> 2.0'
  gem.add_runtime_dependency 'nokogiri', '~> 1.6'
  gem.add_runtime_dependency 'verbal_expressions', '~> 0.1.5'

  gem.add_development_dependency 'coveralls', '~> 0.8'
  gem.add_development_dependency 'flay', '~> 2.6'
  gem.add_development_dependency 'flog', '~> 4.3'
  gem.add_development_dependency 'guard-rspec', '~> 4.6'
  gem.add_development_dependency 'jeweler', '~> 2.0'
  gem.add_development_dependency 'rspec', '~> 3.0'
  gem.add_development_dependency 'rubocop', '~> 0.51'
  gem.add_development_dependency 'rubocop-rspec-focused', '~> 0.1.0'
  gem.add_development_dependency 'simplecov', '~> 0.10'

  # Files
  gem.files = Dir[
    'lib/**/*.rb',
    'errors/*.txt',
    'README.md',
    'CONTRIBUTING.md',
    'LICENSE.txt',
  ]
end
