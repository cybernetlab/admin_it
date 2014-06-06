require File.join %w(extend_it base)
require File.join %w(extend_it dsl)
require File.join %w(extend_it callbacks)

#
module AdminIt
  using EnsureIt if EnsureIt.refined?

  #
  # Describes any field of data
  #
  # @author [alexiss]
  #
  class Field
    extend ExtendIt::Base
    extend DataBehavior
    extend ExtendIt::Dsl
    extend DisplayableName
    include ExtendIt::Callbacks

    TYPES = %i(unknown integer float string date datetime time relation enum
               array hash range regexp symbol binary image)
    EDITORS = %i(text combo radio image hidden)

    define_callbacks :initialize

    dsl do
      dsl_accessor :type, default: TYPES[0]
      dsl_accessor :placeholder
      dsl_accessor :partial
      dsl_accessor :editor, default: EDITORS[0]
      dsl_boolean :readable, :writable, :visible, :sortable, :show_label
      dsl_block :read, :write, :render, :display

      def hide
        dsl_set(:visible, false)
      end

      def show
        dsl_set(:visible, true)
      end
    end

    class << self
      attr_reader :read, :write, :render, :display, :type, :partial, :editor

      protected

      def default_display_name
        field_name
      end
    end

    def self.readable?
      @readable.nil? ? @readable = true : @readable == true
    end

    def self.writable?
      @writable.nil? ? @writable = true : @writable == true
    end

    def self.visible?
      @visible.nil? ? @visible = true : @visible == true
    end

    def self.sortable?
      @sortable.nil? ? @sortable = true : @sortable == true
    end

    def self.show_label?
      @show_label.nil? ? @show_label = true : @show_label == true
    end

    inherited_class_reader :field_name, :entity_class

    def self.create(name, _entity_class, **opts)
      base = self
      Class.new(base) do
        @field_name, @entity_class = name, _entity_class
        import_data_module(base)
        @readable = opts[:readable].nil? ? true : opts[:readable] == true
        @writable = opts[:writable].nil? ? true : opts[:writable] == true
        @visible = opts[:visible].nil? ? true : opts[:visible] == true
        @sortable = opts[:sortable].nil? ? true : opts[:sortable] == true
        @show_label = opts[:show_label].nil? ? true : opts[:show_label] == true
        self.type = opts[:type]
        self.editor = opts[:editor]
      end
    end

    def self.type=(value)
      @type = value.ensure_symbol(values: TYPES, default: TYPES[0])
    end

    def self.editor=(value)
      @editor = value.ensure_symbol(values: EDITORS, default: EDITORS[0])
    end

    def self.placeholder
      @placeholder ||= display_name
    end

    def self.partial
      @partial ||= nil
    end

    def self.hide
      @visible = false
    end

    def self.show
      @visible = true
    end

    class_attr_reader :entity_class, :display_name, :type, :partial, :editor
    attr_writer :visible, :readable, :writable

    def initialize(readable: nil, writable: nil, visible: nil, sortable: nil, show_label: nil)
      run_callbacks :initialize do
        @readable = readable.nil? ? self.class.readable? : readable == true
        @writable = writable.nil? ? self.class.writable? : writable == true
        @visible = visible.nil? ? self.class.visible? : visible == true
        @sortable = sortable.nil? ? self.class.sortable? : sortable == true
        @show_label = show_label.nil? ? self.class.show_label? : show_label == true
      end
    end

    def name
      @name ||= self.class.field_name
    end

    def readable?
      @readable == true
    end

    def writable?
      @writable == true
    end

    def visible?
      @visible == true
    end

    def sortable?
      @sortable == true
    end

    def show_label?
      @show_label == true
    end

    def read(entity)
      unless readable?
        fail FieldReadError, "Attempt to read write-only field #{name}"
      end
      self.class.read.nil? ? read_value(entity) : self.class.read.call(entity)
    end

    def show(entity)
      unless readable?
        fail FieldReadError, "Attempt to read write-only field #{name}"
      end
      self.class.display.nil? ? show_value(entity) : self.class.display.call(entity)
    end

    def write(entity, value)
      unless writable?
        fail FieldWriteError, "Attempt to write read-only field #{name}"
      end
      if self.class.write.nil?
        write_value(entity, value)
      else
        self.class.write.call(entity, value)
      end
      entity
    end

    def render(entity, instance: nil)
      renderer = self.class.render
      return if renderer.nil?
      # method used as event emmiter, call block in instance or caller
      # context if it present
      if instance.nil?
        self.class.render.call(entity)
      else
        instance.instance_exec(entity, &renderer)
      end
    end

    def input(template, entity)
      typed_method = "#{type}_input".to_sym
      if respond_to?(typed_method)
        send typed_method, template, entity
      else
        Helpers::Input.new(template, self, entity: entity)
      end
    end

    protected

    def read_value(entity)
      fail NotImplementedError,
           "Attempt to read field #{name} with unimplemented reader"
    end

    def show_value(entity)
      read_value(entity)
    end

    def write_value(entity, value)
      fail NotImplementedError,
           "Attempt to write to field #{name} with unimplemented writer"
    end
  end

  #
  module FieldsHolder
    extend ExtendIt::DslModule

    dsl do
      dsl_hash_of_objects :fields, single: :field do |name, **opts|
        field_class = opts[:class] || opts[:field_class] || Field
        field_class.ensure_class(Field)
        field_class.create(name, entity_class)
      end

      def hide_fields(*names)
        hash = dsl_get(:fields, {})
        names = names.ensure_array(:flatten, :ensure_symbol, :compact, :uniq)
        names.each { |name| hash[name].hide if hash.key?(name) }
      end

      def show_fields(*names)
        hash = dsl_get(:fields, {})
        names = names.ensure_array(:flatten, :ensure_symbol, :compact, :uniq)
        names.each { |name| hash[name].show if hash.key?(name) }
      end

    extended do |base|
      base.include(Scope)
      base.extend(Scope)
    end

    included do |base|
      base.include(Scope)
    end
    end

    module Scope
      def fields(scope: :visible)
        values = is_a?(Field) ? @fields : @fields.values
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
        when Field::TYPES then values.select { |f| f.type == scope }
        else values
        end
      end

      def field(name)
        name = name.ensure_symbol
        is_a?(Field) ? @fields.find { |f| f.name == name } : @fields[name]
      end
    end
  end
end
