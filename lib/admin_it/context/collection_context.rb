module AdminIt
  class CollectionContext < Context
    @entities_getter = nil

    def self.copy
      proc do |source|
        if source <= CollectionContext
          @entities_getter = source.entities_getter
        end
      end
    end

    def self.entities(&block)
      return unless block_given?
      @entities_getter = block
    end

    def self.collection?
      true
    end

    def self.entities_getter
      @entities_getter
    end

    def self.load_context(context, controller)
      context.entities =
        if context.entities_getter.nil?
          if controller.respond_to?("#{context.resource.name}_entities")
            controller.send("#{context.resource.name}_entities", context.name)
          elsif controller.respond_to?(:entities)
            controller.entities(entity_class, context.name)
          else
            context.class.load_entities(controller)
          end
        else
          context.entities_getter.call
        end
    end

    def self.load_entities(controller)
      []
    end

    def self.path
      AdminIt::Engine.routes.url_helpers.send("#{resource.plural}_path")
    end

    attr_accessor :entity
    class_attr_reader :entities_getter, :path

    def entities=(value)
      @entities = value
    end

    def entities
      self.entity = nil
      collection = self
      # make only single enumerator
      @enumerator ||= Enumerator.new do |yielder|
        @entities.each do |v|
          collection.entity = v
          yielder << Hash[self.class.fields.map do |f|
            [f.name, f.read(v)]
          end]
        end
        collection.entity = nil
      end
    end

    def count
      return @count unless @count.nil?
      # apply filters and limits first
      entities if @enumerator.nil?
      # if @count is not setted yet - calculate it
      @count =
        if entities.is_a?(Enumerable) || entities.respond_to?(:count)
          entities.count
        elsif entities.respond_to?(:size)
          entities.size
        end
    end
  end

  class ListContext < CollectionContext
    def self.path
      AdminIt::Engine.routes.url_helpers.send("list_#{resource.plural}_path")
    end
  end
end
