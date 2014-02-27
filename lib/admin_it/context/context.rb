module AdminIt
  module Contexts; end

  class Context
    def self.create_class(context_name, _resource, copy_from = nil, &block)
      fail ArgumentError, 'Wrong resource' unless _resource.is_a?(Resource)

      base = self
      Class.new(base) do
        def self.parents
          @parents ||= ancestors
            .take_while { |a| a != Context }
            .concat([Context])
        end

        @context_name = context_name
        @resource = _resource

        import_data_module(base)

        if copy_from.nil?
          @fields = default_fields
        else
          parents.select { |parent| parent.methods.include?(:copy) }
                 .each { |parent| instance_exec(copy_from, &parent.copy) }
        end
        call_inherited(:before_config, base_first: true)
        instance_eval(&block) if block_given?
        call_inherited(:after_config, base_first: true)
      end
    end

    def self.copy
      proc do |source|
        @resource = source.resource
        @fields = source.fields(scope: :all).map { |f| f.copy }
      end
    end

    def self.load(controller)
      @controller = controller
      context = new
      call_inherited(:load_context, context, controller, base_first: true)

      session = controller.session
      store = session[:admin_it] ||= {}
      store = store[resource.name] ||= {}
      store = store[context_name] ||= {}
      # load context from session
      context.load(store)
      params = controller.request.query_parameters
      unless params.empty?
        # set context parameters if its present
        context.load(Hash[params.map { |k, v| [k.to_sym, v] }])
      end
      context
    end

    def self.call_inherited(method_name, *args, base_first: false, &block)
      arr = parents.select { |parent| parent.methods.include?(method_name) }
      arr.reverse! if base_first == true
      arr.reduce([]) { |a, e| a << e.send(method_name, *args, &block) }
    end

    def self.class_attr_reader(*attrs)
      attrs.flatten.uniq.each do |attr_name|
        attr_name = attr_name.to_sym if attr_name.is_a?(String)
        next unless attr_name.is_a?(Symbol)
        next if instance_methods.include?(attr_name)
        var_name = "@#{attr_name}".to_sym
        if methods.include?(attr_name)
          define_method(attr_name) { self.class.send(attr_name) }
        elsif instance_variable_defined?(var_name)
          define_method attr_name do
            self.class.instance_variable_get(var_name)
          end
        end
      end
    end

    def self.entity_class
      @entity_class ||= resource.entity_class
    end

    def self.resource
      @resource
    end

    def self.context_name
      @context_name
    end

    def self.field(name, type: nil, display_name: nil, visible: nil, &block)
      field = find_field(name)
      if field.nil?
        field = Field.new(name, entity_class, type: type)
                     .extend(ObjectData::Field)
        fields(scope: :all) << field
      else
        field.type(type) if type != field.type
      end
      field.display_name(display_name) unless display_name.nil?
      unless visible.nil?
        visible == true ? field.show : field.hide
      end
      field.instance_eval(&block) if block_given?
      field
    end

    def self.find_field(name)
      name = name.to_sym if name.is_a?(String)
      _fields = fields(scope: :all)
      return nil if !name.is_a?(Symbol) || _fields.nil? || _fields.empty?
      _fields.find { |f| f.name == name }
    end

    def self.fields(*args, scope: :visible, &block)
      if args.empty? && !block_given?
        case scope
        when :all then @fields
        when :visible then @fields.select { |f| f.visible? }
        when :hidden then @fields.select { |f| !f.visible? }
        when :readable then @fields.select { |f| f.readable? }
        when :writable then @fields.select { |f| f.writable? }
        when Field::TYPES then @fields.select { |f| f.type == scope }
        else @fields
        end
      else
        args = args.flatten + required_fields.map { |f| f.name }
        @fields = args.uniq.map { |name| field(name, &block) }.compact
      end
    end

    def self.exclude_fields(*args)
      required = required_fields.map { |f| f.name }
      args.flatten.each do |arg|
        f = find_field(arg)
        next if f.nil? || required.include?(arg)
        @fields.delete(f)
      end
    end

    def self.hide_fields(*args)
      args.flatten.uniq.each do |name|
        f = find_field(name)
        f.hide unless f.nil?
      end
    end

    def self.show_fields(*args)
      args.flatten.uniq.each do |name|
        f = find_field(name)
        f.show unless f.nil?
      end
    end

    def self.collection?
      false
    end

    def self.single?
      false
    end

    class_attr_reader :collection?, :single?, :entity_class, :resource

    def fields(scope: :visible)
      self.class.fields(scope: scope)
    end

    def name
      self.class.context_name
    end

    def save(params = {})
      return unless params.is_a?(Hash)
      controller = self.class.instance_variable_get(:@controller)
      return if controller.nil?
      session = controller.session
      store = session[:admin_it] ||= {}
      store = store[resource.name] ||= {}
      store[name] = params
    end

    def load(params)
    end

    protected

    def self.default_fields
      call_inherited(:load_fields).flatten
    end

    def self.required_fields
      []
    end

    def self.load_fields
      []
    end

    private

    def self.import_data_module(base)
      @data_module = AdminIt.data_module(entity_class)
      return unless @data_module.is_a?(Module)

      parents.reverse.each do |mod|
        next if mod.name.nil?
        begin
          context_module = @data_module.const_get(mod.name.split('::').last)
          include(context_module) if context_module.is_a?(Module)
        rescue NameError
        end
      end
    end
  end
end
