require 'rubygems'
require 'bundler/setup'

# --- EnsureIt
if ENV['USE_REFINES']
  require 'ensure_it_refined'
else
  require 'ensure_it'
end
# --- EOF EnsureIt

# --- ExtendIt
require 'extend_it'
# --- EOF ExtendIt

require 'combustion'
require 'capybara/rspec'

Combustion.initialize! :all

require 'rspec/rails'
require 'capybara/rails'

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each do |file|
  require file
end

RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
  config.run_all_when_everything_filtered = true
  config.filter_run :focus
  config.order = 'random'
end
