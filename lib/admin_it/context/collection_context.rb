module AdminIt
  class CollectionContext < Context
    @entities_getter = nil

    class << self
      attr_reader :entities_getter

      def copy
        proc do |source|
          if source <= CollectionContext
            @entities_getter = source.entities_getter
          end
        end
      end

      def entities(&block)
        return unless block_given?
        @entities_getter = block
      end

      def collection?
        true
      end

      def load_context(context, controller)
        context.entities =
          if context.entities_getter.nil?
            if controller.respond_to?("#{context.resource.name}_entities")
              controller.send(
                "#{context.resource.name}_entities",
                context.name
              )
            elsif controller.respond_to?(:entities)
              controller.entities(entity_class, context.name)
            else
              context.class.load_entities(controller)
            end
          else
            context.entities_getter.call
          end
      end

      def load_entities(controller)
        []
      end

      def path
        AdminIt::Engine.routes.url_helpers.send("#{resource.plural}_path")
      end
    end

    attr_accessor :entity
    class_attr_reader :entities_getter, :path

    def entities=(value)
      @entities = value
    end

    def entities
      self.entity = nil
      collection = self
      @enumerator ||= Enumerator.new do |yielder|
        @entities.each do |v|
          collection.entity = v
          yielder << v
        end
        collection.entity = nil
      end
    end

    def count
      return @count unless @count.nil?
      # apply filters and limits first
      entities if @enumerator.nil?
      # if @count is not setted yet - calculate it
      @count = entities.count
    end
  end

  class ListContext < CollectionContext
    class << self
      def path
        AdminIt::Engine.routes.url_helpers.send("list_#{resource.plural}_path")
      end

      def icon
        'bars'
      end
    end
  end
end
