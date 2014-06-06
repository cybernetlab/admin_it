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

    def self.s3
      @s3 ||= {}
    end

    def self.s3=(value)
      fail ArgumentError, 'Wrong S3 options' unless value.is_a?(Hash)
      @s3 = value
    end
  end
end
