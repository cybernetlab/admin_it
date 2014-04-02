if !defined?(EnsureIt) && RUBY_VERSION >= '2.1.0'
  require 'ensure_it_refined'
else
  require 'ensure_it'
end

EnsureIt.configure do |config|
  config.error_class = ArgumentError
end
