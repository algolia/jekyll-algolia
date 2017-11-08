# Launch tests whenever a file in ./lib or ./spec changes
guard 'rake', task: 'test_details' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$}) do |match|
    "spec/#{match[1]}_spec.rb"
  end
  watch('spec/spec_helper.rb') { 'spec' }
end

notification :off
