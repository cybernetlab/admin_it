module AdminIt
  module Helpers
    class Input < WrapIt::Base
      html_class 'form-control'
      attr_accessor :field, :entity
      option :field, :entity
      argument :field, if: AdminIt::Field

      before_capture do
        html_attr[:type] = 'text'
        if field.is_a?(AdminIt::Field)
          context = @template.context
          resource = context.resource
          entity ||= context.entity
          html_attr[:name] = "#{resource.name}[#{field.name}]"
          html_attr[:id] = "#{resource.name}_#{field.name}"
          html_attr[:value] = field.render(entity, instance: self)
        end
      end
    end
  end
end
