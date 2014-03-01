module AdminIt
  #
  # Describes any field of data
  #
  # @author [alexiss]
  #
  class Field
    TYPES = %i(unknown integer float string date relation enum)

    attr_reader :name, :entity_class

    def initialize(
      name,
      entity_class,
      type: :unknown,
      readable: true,
      writable: true,
      visible: true
    )
      name = Utils.assert_symbol_arg!(name, name: 'name')
      @name, @entity_class = name, entity_class
      @readable = readable == true
      @writable = writable == true
      @visible = visible == true
      self.type(type)
    end

    def display_name(value = nil)
      if value.nil?
        @display_name ||= default_display_name
      else
        @display_name = value.to_s
      end
    end

    def type(value = nil)
      if value.nil?
        @type
      else
        @type = TYPES.include?(value) ? value : TYPES[0]
      end
    end

    def readable?
      @readable
    end

    def writable?
      @writable
    end

    def visible?
      @visible
    end

    def placeholder(value = nil)
      if value.nil?
        @placeholder ||= display_name
      else
        @placeholder = value
      end
    end

    def read(entity = nil, &block)
      if entity.nil?
        @reader = block if block_given?
      else
        unless readable?
          fail FieldReadError, "Attempt to read write-only field #{name}"
        end
        @reader.nil? ? read_value(entity) : @reader.call(entity)
      end
    end

    def write(entity = nil, value = nil, &block)
      if entity.nil? && value.nil?
        @writer = block if block_given?
      elsif !entity.nil? && !value.nil?
        unless writable?
          fail FieldWriteError, "Attempt to write read-only field #{name}"
        end
        @writer.nil? ? write_value(entity, value) : @writer.call(entity, value)
        entity
      else
        fail ArgumentError, 'Wrong entity and value arguments'
      end
    end

    def render(entity = nil, instance = nil, &block)
      if entity.nil? && instance.nil?
        # method used as setter - just save block
        @renderer = block if block_given?
      elsif !@renderer.nil?
        # method used as event emmiter, call block in instance or caller
        # context if it present
        if instance.nil?
          @renderer.call(entity)
        else
          instance.instance_exec(entity, &@renderer)
        end
      end
    end

    def copy
      field = self.class.new(
        name,
        entity_class,
        type: type,
        readable: readable?,
        writable: writable?,
        visible: visible?
      )
      singleton_class.included_modules.each { |m| field.extend(m) }
      field.display_name = display_name unless @display_name.nil?
      field.placeholder = placeholder unless @placeholder.nil?
      field.read(&@reader) unless @reader.nil?
      field.write(&@writer) unless @writer.nil?
      field.render(&@renderer) unless @renderer.nil?
      field
    end

    def hide
      @visible = false
    end

    def show
      @visible = true
    end

    protected

    def default_display_name
      name
    end

    def read_value(entity)
      raise NotImplementedError,
            "Attempt to read field #{name} with unimplemented reader"
    end

    def write_value(entity, value)
      raise NotImplementedError,
            "Attempt to write to field #{name} with unimplemented writer"
    end
  end
end
