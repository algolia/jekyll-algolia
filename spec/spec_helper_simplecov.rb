# frozen_string_literal: true

require 'simplecov'

SimpleCov.configure do
  load_profile 'test_frameworks'
end

SimpleCov.start do
  add_filter '/.rvm/'
end
