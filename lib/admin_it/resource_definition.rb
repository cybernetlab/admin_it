require 'delegate'

module AdminIt
  class ResourceDefinition < SimpleDelegator
    COLLECTIONS = %i(table tiles list)
    CONTEXTS = COLLECTIONS + %i(new edit show)

    attr_reader :contexts, :fake_context, :default_context

    def initialize(resource)
      @resource = resource
      @fake_context = SingleContext.create_class(CONTEXTS.last, @resource)
      @contexts = Hash[CONTEXTS.map { |n| [n, nil] }]
      super(@fake_context)
    end

    def exclude_context(*args)
      args.flatten.each do |arg|
        arg = arg.to_sym if arg.is_a?(String)
        next unless arg.is_a?(Symbol)
        @contexts.delete(arg)
      end
    end

    def context(name, &block)
      name = name.to_sym if name.is_a?(String)
      unless name.is_a?(Symbol) && CONTEXTS.include?(name)
        fail ArgumentError, 'Wrong context name'
      end
      if @contexts[name].nil?
        class_name = "AdminIt::#{name.capitalize}Context"
        fake = COLLECTIONS.include?(name) ? collection : @fake_context
        context_class = Object.const_get(class_name)
        @contexts[name] = context_class.create_class(
          name, @resource, fake, &block
        )
      end
      @contexts[name]
    end

    def collection(&block)
      if @fake_collection.nil?
        @fake_collection = CollectionContext.create_class(
          COLLECTIONS.first, @resource, @fake_context
        )
      end
      if block_given?
        @fake_collection.instance_eval(&block)
      end
      @fake_collection
    end

    def default_context(value = nil)
      if value.nil?
        @default_context ||= @contexts.keys.first
      elsif CONTEXTS.include?(value)
        @default_context = value
      end
    end

    def icon(value = nil)
      if value.nil?
        @icon
      else
        @icon = value
      end
    end
  end

  def self.resource(name, entity_class = nil, menu: true, &block)
    res = Resource.new(name, entity_class, menu: menu)
    definition = ResourceDefinition.new(res)
    definition.instance_eval(&block) if block_given?
    definition.contexts.each do |c_name, context|
      if context.nil?
        class_name = "AdminIt::#{c_name.capitalize}Context"
        fake = ResourceDefinition::COLLECTIONS.include?(c_name) ?
          definition.collection : definition.fake_context
        context_class = Object.const_get(class_name)
        context = context_class.create_class(c_name, res, fake)
      end
      res[c_name] = context
    end
    res.default_context = definition.default_context
    res.icon = definition.icon
    res.define_controller
    @resources ||= {}
    @resources[res.name] = res
  end

  def self.resources
    @resources ||= {}
  end
end
