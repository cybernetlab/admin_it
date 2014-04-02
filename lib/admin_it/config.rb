module AdminIt
  #
  module Config
    def self.root
      @root ||= Rails.root.join('app', 'admin_it')
    end

    def self.root=(value)
      value = File.expand_path(value, Rails.root)
      fail ArgumentError unless File.directory?(value)
      @root = value
    end

    def self.controller
      @controller ||= ActionController::Base
    end

    def self.controller=(value)
      unless value <= ActionController::Base
        fail ArgumentError, 'Wrong controller'
      end
      @controller = value
    end
  end
end
