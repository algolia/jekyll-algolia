# frozen_string_literal: true

require 'algoliasearch'
require 'jekyll'
require 'jekyll-algolia'

Algolia.init(
  application_id: ENV['ALGOLIA_APPLICATION_ID'],
  api_key: ENV['ALGOLIA_API_KEY']
)

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.fail_fast = true
  config.run_all_when_everything_filtered = true
end

SITE_PATH = File.expand_path('./spec/integration/site/_site')
RSpec::Matchers.define :have_file do |expected|
  match do
    File.exist?(File.join(SITE_PATH, expected))
  end
end
