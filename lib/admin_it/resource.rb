require File.join %w(extend_it base)
require File.join %w(extend_it callbacks)

using ExtendIt::Ensures

module AdminIt
  class Resource
    extend ExtendIt::Base
    include ExtendIt::Callbacks
    include ExtendIt::Dsl
    include Iconed
    include FieldsHolder
    include FiltersHolder

    dsl do
      dsl_hash_of_objects :contexts, single: :context do |name, **opts|
        context_class = opts[:class] || opts[:context_class] || Context
        unless context_class.is_a?(Class) && context_class <= Context
          fail(
            ArgumentError,
            'context class should be AdminIt::Context descendant'
          )
        end
        @contexts[name] = context_class.create(name, entity_class)
      end

      dsl_boolean :confirm_destroy
      dsl_accessor :display_name

      def collection(&block)
        return unless block_given?
        hash = dsl_get(:contexts, {})
        hash.select { |_, c| c.collection? }.each { |_, c| c.dsl_eval(&block) }
      end

      def single(&block)
        return unless block_given?
        hash = dsl_get(:contexts, {})
        hash.select { |_, c| c.single? }.each { |_, c| c.dsl_eval(&block) }
      end

      dsl_accessor :default_context do |value|
        value = value.ensure_symbol
        @contexts.key?(value) ? value : nil
      end
    end

    attr_reader :name, :plural, :entity_class, :menu

    define_callbacks :initialize

    def initialize(
      name,
      entity_class = nil,
      menu: true,
      destroyable: true,
      auto_filters: true
    )
      name = name.ensure_symbol || fail(
        ArgumentError,
        '`name` argument for resource constructor should be a Symbol ' \
        'or a String'
      )

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

    def confirm_destroy?
      @confirm_destroy.nil? ? @confirm_destroy = true : @confirm_destroy == true
    end

    def destroyable?
      @destroyable.nil? ? @destroyable = true : @destroyable == true
    end

    def [](name)
      context(name)
    end

    def context(name)
      @contexts[name.ensure_symbol]
    end

    def contexts
      @contexts.values
    end

    def default_context(value = nil)
      return @default_context unless @default_context.nil?
      if collections.size > 0
        @default_context = collections.first.context_name
      elsif singles.size > 0
        @default_context = singles.first.context_name
      end
    end

    def contexts_names
      @contexts.map(&:context_name)
    end

    def display_name
      @display_name ||= i18n_display_name || default_display_name
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
      c_name = "#{name.to_s.camelize}Controller" # !PORTABLE
      resource = self
      c_class = Class.new(AdminIt.config.controller) do
        @resource = resource
        include AdminIt::Controller

        resource.contexts.each do |_context|
          define_method(_context.context_name) { load_context(_context) }

          if _context < SavableSingleContext
            define_method _context.save_action do
              load_context(_context) { context.save_entity }
            end
          end
        end

        if resource.destroyable?
          define_method :destroy do
            load_context(resource[:show]) { context.destroy_entity }
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

    def default_display_name
      plural.split('_').map { |s| s.capitalize }.join(' ')
    end

    def i18n_display_name
      begin
        I18n
          .t!("admin_it.resources.#{name}.display_name.plural")
          .split(' ')
          .map { |s| s.mb_chars.capitalize }
          .join(' ')
      rescue I18n::MissingTranslationData
        nil
      end
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
    resource = Resource.new(name, entity_class, **opts)
    resource.dsl_eval(&block) if block_given?
    resource.define_controller
    @resources ||= {}
    @resources[resource.name] = resource
  end

  def self.resources
    @resources ||= {}
  end
end
