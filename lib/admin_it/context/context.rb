require 'uri'
require File.join %w(extend_it dsl)
require File.join %w(extend_it base)
require File.join %w(extend_it callbacks)

#
module AdminIt
  using EnsureIt if EnsureIt.refined?

  class Partial
    attr_reader :name, :locals
    def initialize(name, **locals)
      @name = name
      @locals = locals
    end
  end

  #
  class Context
    extend ExtendIt::Base
    extend ExtendIt::Dsl
    extend Iconed
    extend FieldsHolder
    extend DataBehavior
    include ExtendIt::Callbacks

    class << self
      attr_reader :context_name
      attr_accessor :controller_class
    end

    dsl do
      dsl_boolean :confirm_destroy
    end

    inherited_class_reader :resource, :entity_class
    define_callbacks :initialize, :load, :save

    def self.create(context_name, _resource)
      _resource.ensure_instance_of!(Resource)
      base = self
      Class.new(base) do
        @resource = _resource
        @context_name = context_name
        @entity_class = @resource.entity_class
        @confirm_destroy = @resource.confirm_destroy?

        import_data_module(base)

        @fields = Hash[
          _resource.fields(scope: :all).map { |f| [f.field_name, f] }
        ]

        before_configure if respond_to?(:before_configure)
      end
    end

    def self.confirm_destroy?
      @confirm_destroy.nil? ? true : @confirm_destroy == true
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

    def self.url(*args, **params)
      context = nil
      args.reject! { |arg| arg.is_a?(Context) ? context = arg : false }
      url = context.nil? ? path(*args) : context.path(*args)
      params = context.nil? ? params : context.url_params(**params)
      if params.key?(:parent) && params[:parent].is_a?(Context)
        params[:parent] = params[:parent].to_link
      end
      unless params.empty?
        url << '?' << params.map { |k, v| "#{k}=#{v}" }.join('&')
        url = URI.escape(url)
      end
      url
    end

    class_attr_reader :collection?, :single?, :entity_class, :resource,
                      :entity_path?, :confirm_destroy?
    attr_reader :top_menu, :toolbar, :parent, :template, :controller

    CONTEXT_REGEXP = /\A
      (?<resource_name>[a-zA-Z_][a-zA-Z_0-9]*)\/
      (?<context_name>[a-zA-Z_][a-zA-Z_0-9]*)
      (\((?<identity_value>[a-zA-Z_0-9]+)\))?
    \z/x

    def initialize(from, params: nil, store: nil, parent_init: false)
      @children = []

      run_callbacks :initialize do
        if from.is_a?(self.class.controller_class)
          @controller = from
        elsif from.is_a?(Context)
          @controller = from.controller
          unless parent_init == true
            self.parent = from
            from.instance_variable_get(:@children) << self
          end
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

        params = controller.request.params if params.nil?
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

    def fields(scope: :visible)
      values = @fields
      if scope.is_a?(Hash)
        if scope.key?(:editor)
          return values.select { |f| f.editor == scope[:editor] }
        end
      end
      case scope
      when nil, :all then values
      when :visible then values.select { |f| f.visible? }
      when :hidden then values.select { |f| !f.visible? }
      when :readable then values.select { |f| f.readable? }
      when :writable then values.select { |f| f.writable? }
      when :sortable then values.select { |f| f.sortable? }
      when :with_labels then values.select { |f| f.show_label? }
      when :without_labels then values.select { |f| !f.show_label? }
      when *Field::TYPES then values.select { |f| f.type == scope }
      else values
      end
    end

    def field(name)
      name = name.ensure_symbol
      @fields.find { |f| f.name == name }
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
      @layout =
        case value
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
      unless child?
        @top_menu = Helpers::TopMenu.new(template, class: 'navbar-nav')
      end
    end

    def end_render(template)
      request = AdminIt::Request.get(controller.request)
      request["admin_it_#{resource.name}_toolbar"] = template.capture do
        @toolbar.render
      end
      unless child?
        request['admin_it_top_menu'] = template.capture { @top_menu.render }
#        @children.each { |c| c.end_render(template) }
      end
    end

    def url_params(**params)
      params.merge!(parent: @parent.to_link) unless @parent.nil?
      params
    end

    def url_for(*args, **params)
      return nil if @template.nil?
      @template.url_for(*args, url_params(**params))
    end

    def partial(name, **locals)
      Partial.new(name, **locals)
    end

    def to_link
      "#{resource.name}/#{name}"
    end

    protected

    def load_context; end
  end
end
