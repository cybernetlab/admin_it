require File.join %w(extend_it dsl)

module AdminIt
  class TilesContext < CollectionContext
    class << self
      dsl_accessor :header do |value|
        if value.nil?
          fields.empty? ? nil : fields.first.name
        else
          field = fields.find { |f| f.field_name == value }
          field.nil? ? header(nil) : field.field_name
        end
      end
    end

    def self.path
      AdminIt::Engine.routes
        .url_helpers.send("tiles_#{resource.plural}_path")
    end

    class << self
      protected

      def default_icon
        'th'
      end
    end

    class_attr_reader :header
  end
end
