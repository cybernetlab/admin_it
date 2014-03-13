module AdminIt
  class FieldFilter < Filter
    class << self
      attr_reader :field

      protected

      def default_display_name
        field.nil? ? superclass.default_display_name : field.display_name
      end
    end

    class_attr_reader :field

    def self.create(name, _resource, _field)
      field_class = create_class(name, _resource)
      field_class.class_eval do
        _field = _field.to_sym if _field.is_a?(String)
        @field =
          if _field <= Field
            _field
          elsif _field.is_a?(Symbol)
            @resource.fields.find { |fld| fld.field_name == _field }
          else
            nil
          end
      end
      field_class
    end
  end
end
