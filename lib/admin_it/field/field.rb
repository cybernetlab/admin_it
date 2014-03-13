require File.join %w(extend_it class)
require File.join %w(extend_it dsl)
require File.join %w(extend_it callbacks)

module AdminIt
  #
  # Describes any field of data
  #
  # @author [alexiss]
  #
  class Field
    extend ExtendIt::Class
    extend DataBehavior
    include ExtendIt::Callbacks

    TYPES = %i(unknown integer float string date relation enum)

    define_callbacks :initialize#, :configure

    class << self
      extend ExtendIt::Dsl

      # attr_reader :field_name, :entity_class

      dsl_accessor :display_name do |value = nil|
        value.nil? ? default_display_name : value.to_s
      end

      dsl_accessor :type, default: TYPES[0] do |value|
        TYPES.include?(value) ? value : TYPES[0]
      end

      dsl_accessor :placeholder do |value = nil|
        value.nil? ? display_name : value
      end

      dsl_boolean :readable, :writable, :visible, :sortable

      dsl_block :read, :write, :render, :display

      protected

      def default_display_name
        name.to_s
      end
    end

    inherited_class_reader :field_name, :entity_class

    def self.create(name, _entity_class,
                    type: :unknown,
                    readable: true,
                    writable: true,
                    visible: true,
                    sortable: true
                   )
      base = self
      Class.new(base) do
        #run_callbacks :configure do
        @field_name, @entity_class = name, _entity_class
        import_data_module(base)
        self.readable = readable
        self.writable = writable
        self.visible = visible
        self.sortable = sortable
        self.type = type
        #end
      end
    end

    def self.hide
      @visible = false
    end

    def self.show
      @visible = true
    end

    class_attr_reader :entity_class, :display_name, :type
    attr_writer :visible, :readable, :writable

    def initialize(readable: nil, writable: nil, visible: nil, sortable: nil)
      run_callbacks :initialize do
        @readable = readable.nil? ? self.class.readable? : readable == true
        @writable = writable.nil? ? self.class.writable? : writable == true
        @visible = visible.nil? ? self.class.visible? : visible == true
        @sortable = sortable.nil? ? self.class.sortable? : sortable == true
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
      raise NotImplementedError,
            "Attempt to read field #{name} with unimplemented reader"
    end

    def show_value(entity)
      read_value(entity)
    end

    def write_value(entity, value)
      raise NotImplementedError,
            "Attempt to write to field #{name} with unimplemented writer"
    end
  end
end
