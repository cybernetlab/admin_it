if AdminIt::Env.active_record?
  require File.join %w(admin_it data active_record resource)
  require File.join %w(admin_it data active_record collection_context)
  require File.join %w(admin_it data active_record single_context)
  require File.join %w(admin_it data active_record field)
  require File.join %w(admin_it data active_record filter)

  #
  module AdminIt
    register_data ActiveRecord::Base, AdminIt::ActiveRecordData
  end
end
