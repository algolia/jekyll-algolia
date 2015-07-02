require 'jekyll'
require 'awesome_print'
require './lib/push.rb'

RSpec.configure do |config|
  config.filter_run(focus: true)
  config.run_all_when_everything_filtered = true
end
