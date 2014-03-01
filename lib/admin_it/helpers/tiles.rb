module AdminIt
  module Helpers
    class TileHeader < WrapIt::Base
      include WrapIt::TextContainer
      default_tag 'h4'

      before_capture do
        field = @template.context.field(@template.context.header)
        unless field.nil?
          field.render(@template.context.entity, self)
        end
      end
    end

    register :tile_header, TileHeader
  end
end
