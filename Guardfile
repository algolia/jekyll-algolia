# frozen_string_literal: true

# Live-reload unit tests
guard :rspec, cmd: 'bundle exec rspec --color --format progress' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) do |match|
    "spec/#{match[1]}_spec.rb"
  end
  watch(%r{^lib/jekyll/algolia/overwrites/jekyll-algolia-site\.rb$}) do
    'spec/jekyll-algolia_spec.rb'
  end
  watch('spec/spec_helper.rb') { 'spec' }
end

notification :off
