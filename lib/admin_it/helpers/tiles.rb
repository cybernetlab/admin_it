module AdminIt
  module Helpers
    class TileHeader < WrapIt::Base
      include WrapIt::TextContainer
      default_tag 'h4'

      before_capture do
        field = @template.admin_context.class.field(@template.admin_context.header)
        unless field.nil?
          field.render(@template.admin_context.entity, self)
        end
      end
    end

    register :tile_header, TileHeader
  end
end
