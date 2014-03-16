require 'extend_it'
require File.join %w(extend_it ensures)

module AdminIt
  using ExtendIt::Ensures if ExtendIt.config.use_refines?
end

require File.join %w(admin_it env)
require File.join %w(admin_it errors)
require File.join %w(admin_it utils)
require File.join %w(admin_it config)
require File.join %w(admin_it shared)
require File.join %w(admin_it data)
require File.join %w(admin_it field)
require File.join %w(admin_it filters)
require File.join %w(admin_it resource)
require File.join %w(admin_it context)
require File.join %w(admin_it controller)
require File.join %w(admin_it definitions)
require File.join %w(admin_it engine)
require File.join %w(admin_it helpers)
