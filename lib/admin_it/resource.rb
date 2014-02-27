module AdminIt
  class Resource
    attr_reader :name, :plural, :entity_class, :menu, :contexts
    attr_accessor :default_context, :icon

    def initialize(name, entity_class = nil, menu: true)
      name = name.to_sym if name.is_a?(String)
      fail ArgumentError, 'Wrong resource name' unless name.is_a?(Symbol)
      @name = name
      @entity_class = entity_class
      sanitize_entity_class
      import_data_module
      @menu = menu == true
      @plural = name.to_s.pluralize
      @contexts = {}
      @default_context = nil
    end

    def [](name)
      @contexts[name]
    end

    def []=(name, context)
      return unless context <= Context
      @contexts[name] = context
    end

    def display_name
      plural.split('_').map { |s| s.capitalize }.join(' ')
    end

    def collection_path
      AdminIt::Engine.routes.url_helpers.send("#{plural}_path")
    end

    def single_path(*args)
      AdminIt::Engine.routes.url_helpers.send("#{name}_path", *args)
    end

    def define_controller
      c_name = "#{name.to_s.camelize}Controller"
      contexts = @contexts
      resource = self
      c_class = Class.new(AdminIt.config.controller) do
        @admin_resource = resource
        include AdminIt::Controller

        contexts.each do |cont_name, context|
          define_method(cont_name) { load_context(context, cont_name) }

          if cont_name == :new || cont_name == :edit
            action = cont_name == :new ? :create : :update
            define_method action do
              load_context(context, action) do
                admin_context.save_entity(self)
              end
            end
          end

          if cont_name == :show
            define_method :destroy do
              load_context(context, :show) do
                admin_context.destroy_entity(self)
              end
            end
          end
        end
      end
      AdminIt.const_set(c_name, c_class)
    end

    protected

    LAYOUTS = %w(content)

    def sanitize_entity_class
      @entity_class = @name.to_s.camelize if @entity_class.nil?
      if @entity_class.is_a?(Symbol)
        @entity_class = @entity_class.to_s.camelize
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

    def update_action(context)
      proc do
        @admin_action = :update
        @admin_context = context.load(self)
        if !admin_context.nil? && !admin_context.entity.nil?
          if save_entity(:update)
            redirect_to_default
          else
            render :edit
          end
        else
          redirect_to_default
        end
        @admin_context.save
      end
    end

    def destroy_action(context)
      proc do
        @admin_action = :destroy
        @admin_context = context.load(self)
        unless admin_context.nil? || admin_context.entity.nil?
          destroy_entity
        end
        redirect_to_default
        @admin_context.save
      end
    end

    private

    def import_data_module
      @data_module = AdminIt.data_module(entity_class)
      return unless @data_module.is_a?(Module)

      begin
        resource_module = @data_module.const_get(:Resource)
        extend(resource_module) if resource_module.is_a?(Module)
      rescue NameError
      end
    end
  end
end
