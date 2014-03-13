module AdminIt
  module Helpers
    class Field < WrapIt::Base
      include WrapIt::TextContainer
      attr_accessor :field, :context
      option :field
      option :context
      argument :field, if: AdminIt::Field
      argument :context, if: AdminIt::Context

      before_capture do
        unless context.is_a?(AdminIt::Context)
          self.context = @template.context
        end
        if field.is_a?(AdminIt::Field)
          entity = context.entity
          field.render(entity, instance: self)
          body << field.show(entity).to_s if body.empty?
        end
      end
    end

    register :field, Field
  end
end
