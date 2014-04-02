module AdminIt
  #
  module Helpers
    #
    class Field < WrapIt::Base
      include WrapIt::TextContainer
      attr_accessor :field, :context
      option :field
      option :context
      argument :field, if: AdminIt::Field
      argument :context, if: AdminIt::Context

      before_capture do
        self.context = @template.context unless context.is_a?(AdminIt::Context)
        if field.is_a?(AdminIt::Field)
          entity = context.entity
          body << html_safe(field.show(entity).to_s) if body.empty?
          field.render(entity, instance: self)
        end
      end
    end

    register :field, Field
  end
end
