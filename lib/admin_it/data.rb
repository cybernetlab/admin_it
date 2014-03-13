require File.join %w(admin_it data data_behavior)
require File.join %w(admin_it data object)
require File.join %w(admin_it data hash)
require File.join %w(admin_it data active_record)

module AdminIt
  def self.register_data(entity_class, mod)
    return if entity_class.nil?
    @data_modules ||= []
    @data_modules.unshift [entity_class, mod]
  end

  def self.data_module(entity_class)
    return nil if entity_class.nil?
    @data_modules ||= []
    @data_modules.each do |mod|
      return mod[1] if entity_class <= mod[0]
    end
  end

  register_data Object, AdminIt::ObjectData
  register_data Hash, AdminIt::HashData
  register_data ActiveRecord::Base, AdminIt::ActiveRecordData
end
