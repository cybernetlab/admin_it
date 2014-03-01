module AdminIt
  class Resource
    attr_reader :name, :plural, :entity_class, :menu, :contexts, :icon

    def initialize(name, entity_class = nil, menu: true, destroyable: true)
      name = Utils.assert_symbol_arg!(name, name: 'name')
      @name, @entity_class = name, entity_class
      if @entity_class.nil?
        begin
          @entity_class = Object.const_get(name.to_s.camelize) # !PORTABLE
        rescue NameError
          fail ArgumentError, "Can't find entity class for #{name}"
        end
      end

      import_data_module

      @menu = menu == true
      @destroyable = destroyable == true
      @plural = name.to_s.pluralize # !POTABLE
      @contexts = []
      @default_context = nil
    end

    def [](name)
      name = Utils.assert_symbol_arg!(name)
      @contexts.find { |c| c.context_name == name }
    end

    def default_context
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
      plural.split('_').map { |s| s.capitalize }.join(' ')
    end

    def destroyable?
      @destroyable
    end

    def collection_path
      AdminIt::Engine.routes.url_helpers.send("#{plural}_path")
    end

    def single_path(*args)
      AdminIt::Engine.routes.url_helpers.send("#{name}_path", *args)
    end

    def collections
      @contexts.select { |c| c.collection? }
    end

    def singles
      @contexts.select { |c| c.single? }
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
    end

    protected

    LAYOUTS = %w(content)

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

    private

    def import_data_module
      data_module = AdminIt.data_module(entity_class)
      return unless data_module.is_a?(Module)
      resource_module = data_module.const_get(:Resource)
      extend(resource_module) if resource_module.is_a?(Module)
    rescue NameError
    end
  end
end
