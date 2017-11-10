# Launch tests whenever a file in ./lib or ./spec changes
guard :rspec, cmd: 'bundle exec rspec --color --format progress' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) do |match|
    "spec/#{match[1]}_spec.rb"
  end
  watch('spec/spec_helper.rb') { 'spec' }
end

notification :off
