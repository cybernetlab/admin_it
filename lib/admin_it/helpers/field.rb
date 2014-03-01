module AdminIt
  module Helpers
    class Field < WrapIt::Base
      include WrapIt::TextContainer
      attr_accessor :field
      option :field
      argument :field, if: AdminIt::Field

      before_capture do
        if field.is_a?(AdminIt::Field)
          entity = @template.context.entity
          field.render(entity, self)
          body << field.read(entity).to_s if body.empty?
        end
      end
    end

    register :field, Field
  end
end
