module AdminIt
  module Helpers
    class Cell < WrapIt::Base
      include WrapIt::TextContainer
      default_tag 'td'
      attr_accessor :column
      option :column

      before_capture do
        unless column.nil?
          col = @template.context.class.field(column)
          unless col.nil?
            col.render(@template.context.entity, self)
          end
        end
      end
    end

    class ActionsCell < WrapIt::Base
      default_tag 'td'

      before_capture do
        single = @template.resource.singles.select { |c| !(c <= NewContext) }
        buttons = single.map do |context|
            cl = context <= ShowContext ? 'info' : 'default'
            href = context.path(@template.context.entity)
            "<a class=\"btn btn-xs btn-#{cl}\" href=\"#{href}\">" \
            "<i class=\"fa fa-#{context.icon}\"></i></a>"
          end
        show = single.first { |c| c <= ShowContext }
        unless show.nil?
          buttons << @template.link_to(
            html_safe('<i class="fa fa-trash-o"></i>'),
            show.path(@template.context.entity),
            method: :delete,
            class: 'btn btn-xs btn-danger'
          )
        end

        html = buttons.join
        html = "<div class=\"btn-group\">#{html}</dic>" if buttons.size > 1

        self[:content] = html_safe(html)
      end
    end

    class Header < WrapIt::Container
      default_tag 'tr'
      child :cell, Cell, tag: 'th'
    end

    class Row < WrapIt::Container
      default_tag 'tr'
      child :cell, Cell
      child :actions, ActionsCell

      before_capture do
        block = @template.context.class.row
        unless block.nil?
          instance_exec(@template.context.entity, &block)
        end
      end
    end

    class Table < WrapIt::Container
      default_tag 'table'
      html_class %w(table)

      def context
        @template.context
      end

      child :header, Header
      child :row, Row
    end

    register :table, Table
  end
end
