Gem::Specification.new do |s|
  s.name        = 'algoliasearch-jekyll'
  s.version     = '0.1.3'
  s.date        = '2015-06-30'
  s.summary     = 'AlgoliaSearch for Jekyll'
  s.description = 'Index all your pages and posts to an Algolia index with ' \
                  '`jekyll algolia push`'
  s.authors     = ['Tim Carry']
  s.email       = 'tim@pixelastic.com'
  s.files       = [
    'lib/algoliasearch-jekyll.rb',
    'lib/push.rb'
  ]
  s.add_development_dependency('jekyll', ['~> 2.5'])
  s.add_development_dependency('rake')
  s.add_development_dependency('rspec', ['~> 3.0'])

  s.add_runtime_dependency('nokogiri', ['~> 1.6'])
  s.add_runtime_dependency('json', ['~> 1.8'])
  s.add_runtime_dependency('awesome_print', ['~> 1.6'])
  s.add_runtime_dependency('algoliasearch', ['~> 1.4'])
  s.homepage    = 'https://github.com/algolia/algoliasearch-jekyll'
  s.license     = 'MIT'
end
