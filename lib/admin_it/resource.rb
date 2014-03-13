require File.join %w(extend_it symbolize)
require File.join %w(extend_it asserts)
require File.join %w(extend_it callbacks)
require File.join %w(extend_it class)

using ExtendIt::Symbolize

module AdminIt
  module FieldsHolder
    def fields(scope: :visible)
      case scope
      when nil, :all then @fields.values
      when :visible then @fields.values.select { |f| f.visible? }
      when :hidden then @fields.values.select { |f| !f.visible? }
      when :readable then @fields.values.select { |f| f.readable? }
      when :writable then @fields.values.select { |f| f.writable? }
      when :sortable then @fields.values.select { |f| f.sortable? }
      when Field::TYPES then @fields.values.select { |f| f.type == scope }
      else @fields.values
      end
    end

    def hide_fields(*names)
      names.ensure_symbols.each do |name|
        @fields[name].hide if @fields.key?(name)
      end
    end

    def show_fields(*names)
      names.ensure_symbols.each do |name|
        @fields[name].show if @fields.key?(name)
      end
    end
  end

  module FiltersHolder
    def filters(scope: :all)
      @filters ||= {}
      case scope
      when nil, :all then @filters.values
      else @filters.values
      end
    end
  end

  class Resource
    extend ExtendIt::Class
    extend ExtendIt::Dsl
    include ExtendIt::Asserts
    include ExtendIt::Callbacks
    include FieldsHolder
    include FiltersHolder

    attr_reader :name, :plural, :entity_class, :menu

    dsl_accessor :icon
    dsl_use_hash :fields

    define_callbacks :initialize

    def initialize(
      name,
      entity_class = nil,
      menu: true,
      destroyable: true,
      auto_filters: true
    )
      assert_symbol(:name)

      @name, @entity_class = name, entity_class
      if @entity_class.nil?
        begin
          @entity_class = Object.const_get(name.to_s.camelize) # !PORTABLE
        rescue NameError
          fail ArgumentError, "Can't find entity class for #{name}"
        end
      end

      import_data_module

      run_callbacks :initialize do
        @fields = Hash[default_fields.map { |f| [f.field_name, f] }]

        @filters =
          if auto_filters
            Hash[default_filters.map { |f| [f.filter_name, f] }]
          else
            {}
          end

        @contexts = Hash[default_contexts.map { |c| [c.context_name, c] }]

        @menu = menu == true
        @destroyable = destroyable == true
        @plural = name.to_s.pluralize # !POTABLE
        @default_context = nil
      end
    end

    def field(*names, field_class: nil, &block)
      names.ensure_symbols.each do |name|
        if @fields.key?(name)
          field = @fields[name]
        else
          field_class = Field if field_class.nil? || !field_class <= Field
          field = @fields[name] = field_class.create(name, entity_class)
        end
        field.instance_eval(&block) if block_given?
      end
    end

    def [](name)
      assert_symbol(:name)
      @contexts[name]
    end

    def context(*names, context_class: nil, &block)
      names.ensure_symbols.each do |name|
        if @contexts.key?(name)
          context = @contexts[name]
        else
          if context_class.nil? || !context_class <= Context
            context_class = Context
          end
          context = @contexts[name] = context_class.create(name, entity_class)
        end
        context.instance_eval(&block) if block_given?
      end
    end

    def contexts
      @contexts.values
    end

    dsl_use_hash :contexts

    def filter(name, filter_class: nil, &block)
      assert_symbol(:name)
      filter = @filters[name]
      if filter.nil?
        filter_class = Filter if filter_class.nil? || !filter_class <= Filter
        filter = @filters[name] = filter_class.create(name, self)
      end
      filter.instance_eval(&block) if block_given?
    end

    dsl_use_hash :filters

    def collection(&block)
      return unless block_given?
      contexts.select { |c| c.collection? }.each do |c|
        c.instance_eval(&block)
      end
    end

    def single(&block)
      return unless block_given?
      contexts.select { |c| c.single? }.each do |c|
        c.instance_eval(&block)
      end
    end

    def default_context(value = nil)
      if value.nil?
        return @default_context unless @default_context.nil?
        if collections.size > 0
          @default_context = collections.first.context_name
        elsif singles.size > 0
          @default_context = singles.first.context_name
        end
      else
        @default_context = @contexts.keys.include?(value) ? value : default_context
      end
    end

    def contexts_names
      @contexts.map(&:context_name)
    end

    def display_name
      plural.split('_').map { |s| s.capitalize }.join(' ')
    end

    def destroyable?
      @destroyable
    end

    def collection_path
      AdminIt::Engine.routes.url_helpers.send("#{plural}_path")
    end

    def single_path(entity)
      AdminIt::Engine.routes.url_helpers.send("#{name}_path", entity)
    end

    def collections
      contexts.select { |c| c.collection? }
    end

    def singles
      contexts.select { |c| c.single? }
    end

    def define_controller
      c_name = "#{name.to_s.camelize}Controller" # !POTABLE
      resource = self
      c_class = Class.new(AdminIt.config.controller) do
        @resource = resource
        include AdminIt::Controller

        resource.contexts.each do |_context|
          define_method(_context.context_name) { load_context(_context) }

          if _context < SavableSingleContext
            define_method _context.save_action do
              load_context(_context) { context.save_entity(self) }
            end
          end
        end

        if resource.destroyable?
          define_method :destroy do
            load_context(resource[:show]) { context.destroy_entity(self) }
          end
        end
      end
      AdminIt.const_set(c_name, c_class)
      contexts.each { |c| c.controller_class = c_class }
    end

    protected

    # LAYOUTS = %w(content)
    COLLECTIONS = %i(table tiles list)
    SINGLE = %i(show new edit)
    CONTEXTS = COLLECTIONS + SINGLE

    def sanitize_entity_class
      @entity_class = @name.to_s.camelize if @entity_class.nil? # !PORTABLE
      if @entity_class.is_a?(Symbol)
        @entity_class = @entity_class.to_s.camelize # !PORTABLE
      end
      if @entity_class.is_a?(String)
        begin
          @entity_class = Object.const_get(@entity_class)
        rescue NameError
          @entity_class = Object
        end
      end
      unless @entity_class.is_a?(Class)
        fail ArgumentError, 'Wrong entity class'
      end
    end

    def default_fields
      []
    end

    def default_contexts
      CONTEXTS.map do |c|
        context_class = AdminIt.const_get("#{c.capitalize}Context")
        context_class.create(c, self)
      end
    end

    def default_filters
      []
    end

    private

    def import_data_module
      data_module = AdminIt.data_module(entity_class)
      return unless data_module.is_a?(Module)
      resource_module = data_module.const_get(:Resource)
      extend(resource_module) if resource_module.is_a?(Module)
    rescue NameError
    end
  end

  def self.resource(name, entity_class = nil, **opts, &block)
    _resource = Resource.new(name, entity_class, **opts)
    _resource.instance_eval(&block) if block_given?
    _resource.define_controller
    @resources ||= {}
    @resources[_resource.name] = _resource
  end

  def self.resources
    @resources ||= {}
  end
end
