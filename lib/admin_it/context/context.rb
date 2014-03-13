require 'uri'
require File.join %w(extend_it dsl)
require File.join %w(extend_it array_of)
require File.join %w(extend_it symbolize)

using ExtendIt::Symbolize

module AdminIt
  class Context
    extend ExtendIt::Class
    extend ExtendIt::Dsl
    include ExtendIt::Callbacks
    extend DataBehavior
    extend FieldsHolder

    class << self
      extend ExtendIt::Dsl

      attr_reader :context_name
      attr_accessor :controller_class

      dsl_accessor :icon do |value|
        value.nil? ? default_icon : value.to_s
      end
      dsl_use_hash :fields
    end

    inherited_class_reader :resource, :entity_class
    define_callbacks :initialize, :load, :save

    def self.create(context_name, _resource, &block)
      fail ArgumentError, 'Wrong resource' unless _resource.is_a?(Resource)
      base = self
      Class.new(base) do
        @resource = _resource
        @context_name = context_name
        @entity_class = @resource.entity_class

        import_data_module(base)

        @fields = Hash[
          _resource.fields(scope: :all).map { |f| [f.field_name, f] }
        ]

        before_configure if respond_to?(:before_configure)
        instance_eval(&block) if block_given?
        after_configure if respond_to?(:after_configure)
      end
    end

    def self.field(*names, field_class: nil, &block)
      names.ensure_symbols.each do |name|
        if @fields.key?(name)
          field = @fields[name] = Class.new(@fields[name]) if block_given?
        else
          field_class = Field if field_class.nil? || !field_class <= Field
          field = @fields[name] = field_class.create(name, entity_class)
        end
        field.instance_eval(&block) if block_given?
      end
    end

    def self.collection?
      false
    end

    def self.single?
      false
    end

    def self.entity_path?
      false
    end

    def self.url(context = nil, **params)
      url = context.nil? ? path : context.path
      params = context.nil? ? params : context.url_params(**params)
      unless params.empty?
        url << '?' << params.map { |k, v| "#{k}=#{v}" }.join('&')
        url = URI.escape(url)
      end
      url
    end

    class << self
      protected

      def default_icon
        ''
      end
    end

    class_attr_reader :collection?, :single?, :entity_class, :resource, :icon,
                      :entity_path?
    attr_reader :top_menu, :toolbar, :parent, :template, :controller

    CONTEXT_REGEXP = /\A
      (?<resource_name>[a-zA-Z_][a-zA-Z_0-9]*)\/
      (?<context_name>[a-zA-Z_][a-zA-Z_0-9]*)
      (\((?<identity_value>[a-zA-Z_0-9]+)\))?
    \z/x

    def initialize(from, params: nil, store: nil, parent_init: false)
      run_callbacks :initialize do
        if from.is_a?(self.class.controller_class)
          @controller = from
        elsif from.is_a?(Context)
          @controller = from.controller
          self.parent = from unless parent_init == true
          params ||= {}
          store ||= {}
        end

        @fields = self.class.fields(scope: :all).map { |f| f.new }

        if store.nil?
          session = controller.session
          store = session[:admin_it] ||= {}
          store = store[resource.name] ||= {}
          store = store[name] ||= {}
        end

        if params.nil?
          params = controller.request.query_parameters
        end
        params = Hash[params.map { |k, v| [k.to_sym, v] }]

        run_callbacks :load, arguments: { params: params, store: store } do
          load_context unless parent_init == true
        end
      end
    end

    after_load do |store: {}, params: {}|
      self.layout = params[:layout] if params.key?(:layout)
      if params.key?(:parent)
        self.parent = params[:parent]
      elsif store.key?(:parent)
        self.parent = store[:parent]
      end
    end

    def name
      @name ||= self.class.context_name
    end

    def field(name)
      @fields.find { |f| f.name == name }
    end

    def fields(scope: :visible)
      case scope
      when nil, :all then @fields
      when :visible then @fields.select { |f| f.visible? }
      when :hidden then @fields.select { |f| !f.visible? }
      when :readable then @fields.select { |f| f.readable? }
      when :writable then @fields.select { |f| f.writable? }
      when Field::TYPES then @fields.select { |f| f.type == scope }
      else @fields
      end
    end

    def save(**params)
      return if controller.nil?
      session = controller.session
      store = session[:admin_it] ||= {}
      store = store[resource.name] ||= {}
      run_callbacks :save, arguments: [{ params: params }] do
        store[name] = params
      end
    end

    def layout
      @layout ||= ''
    end

    def layout=(value)
      value = value.to_sym if value.is_a?(String)
      return unless value.is_a?(Symbol)
      @layout = case value
      when :dialog then 'dialog'
      else ''
      end
    end

    def parent=(value)
      return if value.nil?
      if value.is_a?(Context)
        @parent = value
      elsif value.is_a?(String)
        m = CONTEXT_REGEXP.match(value)
        unless m.nil?
          r = AdminIt.resources[m[:resource_name].downcase.to_sym]
          return if r.nil?
          c = r[m[:context_name].downcase.to_sym]
          return if c.nil?
          @parent = c.new(self, parent_init: true)
          unless m[:identity_value].nil?
            @parent.entity = @parent.load_entity(identity: m[:identity_value])
          end
        end
      else
        @parent = nil
      end
    end

    def child?
      parent.is_a?(Context)
    end

    def begin_render(template)
      @template = template
      @toolbar = Helpers::Toolbar.new(template)
      @top_menu = Helpers::TopMenu.new(template, class: 'navbar-nav')
    end

    def url_params(**params)
      unless @parent.nil?
        params.merge!(parent: @parent.send(:context_param))
      end
      params
    end

    protected

    def context_param
      "#{resource.name}/#{name}"
    end

    def load_context; end
  end
end
