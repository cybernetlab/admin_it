#require 'delegate'

module AdminIt
  class ResourceDefinition # < SimpleDelegator
    COLLECTIONS = %i(table tiles list)
    SINGLE = %i(show new edit)
    CONTEXTS = COLLECTIONS + SINGLE

    def initialize(resource)
      @resource = resource
      @resource.contexts.replace(CONTEXTS.map do |name|
        Object.const_get("AdminIt::#{name.capitalize}Context")
              .create_class(name, @resource)
      end)
    end

    def exclude_context(*args)
      args.flatten.each do |arg|
        arg = Utils.assert_symbol_arg(arg) { next }
        puts "--- EXCLUDE: #{arg}"
        @resource.contexts.reject! { |c| c.context_name == arg }
        puts "--> #{@resource.contexts.map(&:context_name)}"
      end
    end

    def exclude_collection
      @resource.contexts.reject! { |c| c.collection? }
    end

    def exclude_single
      @resource.contexts.reject! { |c| c.single? }
    end

    def contexts(*names, &block)
      unless names.empty?
        @resource.contexts.replace(
          names.flatten.uniq.map { |name| context(name) }
        )
      end
      if block_given?
        @resource.contexts.each { |context| context.instance_eval(&block) }
      end
    end

    def context(name, context_class: nil, &block)
      Utils.assert_symbol_arg!(name, 'name')
      context = @resource[name]
      if context.nil?
        unless context_class <= Context
          context_class =
            Object.const_get("AdminIt::#{name.capitalize}Context")
        end
        context = context_class.create_class(name, @resource)
        @resource.contexts << context
      end
      context.instance_eval(&block) if block_given?
    end

    def all(&block)
      @resource.contexts.each { |c| c.instance_eval(&block) } if block_given?
    end

    def single(&block)
      @resource.singles.each { |c| c.instance_eval(&block) } if block_given?
    end

    def collection(&block)
      return unless block_given?
      @resource.collections.each { |c| c.instance_eval(&block) }
    end

    def default_context(value)
      return if @resource[value].nil?
      @resource.instance_variable_set(:@default_context, value)
    end

    def icon(value = nil)
      @resource.instance_variable_set(:@icon, value.to_s)
    end
  end

  def self.resource(name, entity_class = nil, **opts, &block)
    _resource = Resource.new(name, entity_class, **opts)
    definition = ResourceDefinition.new(_resource)
    definition.instance_eval(&block) if block_given?
    _resource.define_controller
    @resources ||= {}
    @resources[_resource.name] = _resource
  end

  def self.resources
    @resources ||= {}
  end
end
