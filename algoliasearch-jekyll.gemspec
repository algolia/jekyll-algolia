Gem::Specification.new do |s|
  s.name        = 'algoliasearch-jekyll'
  s.version     = '0.1.0'
  s.date        = '2015-06-18'
  s.summary     = 'AlgoliaSearch for Jekyll'
  s.description = 'Index all your pages and posts to an Algolia index with `jekyll algolia index`'
  s.authors     = ['Tim Carry']
  s.email       = 'tim@pixelastic.com'
  s.files       = [
    'lib/algoliasearch-jekyll.rb',
    'lib/push.rb'
  ]
  s.add_runtime_dependency('nokogiri', ['~> 1.6'])
  s.add_runtime_dependency('json', ['~> 1.8'])
  s.add_runtime_dependency('awesome_print', ['~> 1.6'])
  s.add_runtime_dependency('algoliasearch', ['~> 1.4'])
  s.homepage    = 'https://github.com/algolia/algoliasearch-jekyll'
  s.license     = 'MIT'
end
