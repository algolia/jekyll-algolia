Gem::Specification.new do |s|
  s.name        = 'algoliasearch-jekyll'
  s.version     = '0.2.1'
  s.date        = '2015-07-03'
  s.summary     = 'AlgoliaSearch for Jekyll'
  s.description = 'Index all your pages and posts to an Algolia index with ' \
                  '`jekyll algolia push`'
  s.authors     = ['Tim Carry']
  s.email       = 'tim@pixelastic.com'
  s.files       = ['lib/*.rb']

  s.add_development_dependency('jekyll', ['~> 2.5'])
  s.add_development_dependency('rspec', ['~> 3.0'])
  s.add_development_dependency('guard-rspec', ['~> 4.6'])

  s.add_runtime_dependency('nokogiri', ['~> 1.6'])
  s.add_runtime_dependency('json', ['~> 1.8'])
  s.add_runtime_dependency('awesome_print', ['~> 1.6'])
  s.add_runtime_dependency('algoliasearch', ['~> 1.4'])
  s.homepage    = 'https://github.com/algolia/algoliasearch-jekyll'
  s.license     = 'MIT'
end
