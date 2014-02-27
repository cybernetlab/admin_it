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
      Gem::Specification.find_by_name('pundit')
      true
    rescue Gem::LoadError
      false
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
