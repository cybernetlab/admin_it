module AdminIt
  #
  # Framework detection methods
  #
  module Env
    # @private
    def self.framework
      return @framework unless @framework.nil?
      gems = Gem.loaded_specs.keys
      if gems.include?('rails')
        @framework = :rails
      elsif gems.include?('sinatra')
        @framework = :sinatra
      else
        @framework = :unknown
      end
    end

    # @private
    def self.pundit?
      return @pundit unless @pundit.nil?
      Gem::Specification.find_by_name('pundit')
      @pundit = true
    rescue Gem::LoadError
      @pundit = false
    end

    # @private
    def self.active_record?
      return @active_record unless @active_record.nil?
      Gem::Specification.find_by_name('activerecord')
      @active_record = true
    rescue Gem::LoadError
      @active_record = false
    end

    # @private
    def self.mongoid?
      return @mongoid unless @mongoid.nil?
      Gem::Specification.find_by_name('mongoid')
      @mongoid = true
    rescue Gem::LoadError
      @mongoid = false
    end

    # @private
    def self.rails?
      framework == :rails
    end

    # @private
    def self.sinatra?
      framework == :sinatra
    end
  end
end
