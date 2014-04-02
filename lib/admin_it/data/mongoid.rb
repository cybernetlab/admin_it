if AdminIt::Env.mongoid?
  require 'mongoid'
  require File.join %w(admin_it data mongoid resource)
  require File.join %w(admin_it data mongoid field)
#  require File.join %w(admin_it data monfo_id collection_context)
#  require File.join %w(admin_it data monfo_id single_context)
#  require File.join %w(admin_it data monfo_id field)
#  require File.join %w(admin_it data monfo_id filter)

  #
  module AdminIt
    register_data ::Mongoid::Document, AdminIt::MongoidData
  end
end
