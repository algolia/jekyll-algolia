require 'simplecov'

SimpleCov.configure do
  load_adapter 'test_frameworks'
end

ENV['COVERAGE'] && SimpleCov.start do
  add_filter '/.rvm/'
end
