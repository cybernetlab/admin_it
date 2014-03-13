module AdminIt
  class ShowContext < SingleContext
    include Identifiable

    class << self
      include Renderable

      protected

      def default_icon
        'info-circle'
      end
    end

    def self.entity_path?
      true
    end

    def self.read(entity = nil, &block)
      if entity.nil?
        @reader = block if block_given?
      elsif !@reader.nil?
        @reader.call(entity)
      end
    end

    def destroy_entity
      if entity_destroyer.nil?
        if controller.respond_to?("#{resource.name}_destroy")
          controller.send("#{resource.name}_destroy")
        elsif controller.respond_to?(:destroy_entity)
          controller.destroy_entity(entity_class)
        else
          destroy
        end
      else
        entity_destroyer.call(controller)
      end
    end

    protected

    def destroy; end
  end
end
