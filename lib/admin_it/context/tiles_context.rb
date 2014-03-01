module AdminIt
  class TilesContext < CollectionContext
    @header = nil

    class << self
      def copy
        proc do |source|
          if source <= TilesContext
            @header = source.header
          end
        end
      end

      def header(field_name = nil)
        if field_name.nil?
          @header ||= fields.empty? ? nil : fields.first.name
        else
          f = find_field(field_name)
          @header = f.name unless f.nil?
        end
      end

      def path
        AdminIt::Engine.routes
          .url_helpers.send("tiles_#{resource.plural}_path")
      end

      protected

      def default_icon
        'th'
      end
    end

    class_attr_reader :header
  end
end
