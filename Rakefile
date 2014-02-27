begin
  require 'bundler/setup'
rescue LoadError
  puts 'You must `gem install bundler` and `bundle install` to run rake tasks'
end

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
# require 'yard'
# require 'rake/testtask'

# Rake::TestTask.new do |t|
#   t.name = :spec_rails
#   t.libs.push "spec_rails"
#   t.test_files = FileList['spec_rails/**/*_spec.rb']
#   t.verbose = true
# end

#YARD::Rake::YardocTask.new

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
