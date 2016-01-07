group :jekyll_v3 do
  guard :rspec, cmd: 'appraisal jekyll-v3 bundle exec rspec --color --format documentation' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')  { 'spec' }
  end
end

group :jekyll_v2 do
  guard :rspec, cmd: 'appraisal jekyll-v2 bundle exec rspec --color --format documentation' do
    watch(%r{^spec/.+_spec\.rb$})
    watch(%r{^lib/(.+)\.rb$})     { |m| "spec/#{m[1]}_spec.rb" }
    watch('spec/spec_helper.rb')  { 'spec' }
  end
end

notification :off
