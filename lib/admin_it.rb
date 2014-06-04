if !defined?(EnsureIt) && RUBY_VERSION >= '2.1.0'
  require 'ensure_it_refined'
else
  require 'ensure_it'
end

require 'extend_it'

#
module AdminIt
  LAYOUTS = %i(dialog)
end

require File.join %w(admin_it env)
require File.join %w(admin_it errors)
require File.join %w(admin_it config)
require File.join %w(admin_it shared)
require File.join %w(admin_it data)
require File.join %w(admin_it field)
require File.join %w(admin_it actions)
require File.join %w(admin_it filters)
require File.join %w(admin_it resource)
require File.join %w(admin_it context)
require File.join %w(admin_it controller)
require File.join %w(admin_it middleware)
require File.join %w(admin_it engine)
require File.join %w(admin_it helpers)
