module AdminIt
  class TilesContext < CollectionContext
    @header = nil

    def self.copy
      proc do |source|
        if source <= TilesContext
          @header = source.header
        end
      end
    end

    def self.header(field_name = nil)
      if field_name.nil?
        @header ||= fields.empty? ? nil : fields.first.name
      else
        f = find_field(field_name)
        @header = f.name unless f.nil?
      end
    end

    def self.path
      AdminIt::Engine.routes.url_helpers.send("tiles_#{resource.plural}_path")
    end

    class_attr_reader :header
  end
end
