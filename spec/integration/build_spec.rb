# frozen_string_literal: true

SITE_PATH = File.expand_path('./spec/site/_site')
RSpec::Matchers.define :have_file do |expected|
  match do
    File.exist?(File.join(SITE_PATH, expected))
  end
end

describe('built website') do
  it { should have_file('404.html') }
  it { should have_file('index.html') }
end
