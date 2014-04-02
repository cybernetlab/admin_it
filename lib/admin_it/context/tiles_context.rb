module AdminIt
  #
  class TilesContext < CollectionContext
    dsl do
      dsl_accessor :header do |value|
        field = fields.find { |f| f.field_name == value }
        field.nil? ? header : field.field_name
      end
    end

    class << self
      attr_reader :header

      protected

      def default_icon
        'th'
      end
    end

    def self.header
      fields.empty? ? nil : fields.first.name
    end

    def self.path
      AdminIt::Engine.routes
        .url_helpers.send("tiles_#{resource.plural}_path")
    end

    class_attr_reader :header
  end
end
