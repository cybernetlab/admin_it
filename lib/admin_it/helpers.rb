require 'wrap_it'

#
module AdminIt
  #
  module Helpers; end
  WrapIt.register_module Helpers
end

require File.join %w(admin_it helpers field)
require File.join %w(admin_it helpers top_menu)
require File.join %w(admin_it helpers toolbar)
require File.join %w(admin_it helpers table)
require File.join %w(admin_it helpers tiles)
