module AdminIt
  module Helpers
    class Cell < WrapIt::Base
      include WrapIt::TextContainer
      default_tag 'td'
      attr_accessor :column
      option :column

      before_capture do
        unless column.nil?
          col = parent.parent.context.field(column)
          unless col.nil?
            col.render(parent.parent.context.entity, instance: self)
          end
        end
      end
    end

    class ActionsCell < WrapIt::Base
      default_tag 'td'

      before_capture do
        single = parent.parent.resource.singles.select { |c| !(c <= NewContext) }
        buttons = single.map do |context|
            cl = context <= ShowContext ? 'info' : 'default'
            href = context.path(parent.parent.context.entity)
            "<a class=\"btn btn-xs btn-#{cl}\" href=\"#{href}\">" \
            "<i class=\"fa fa-#{context.icon}\"></i></a>"
          end
        show = single.first { |c| c <= ShowContext }
        unless show.nil?
          buttons << @template.link_to(
            html_safe('<i class="fa fa-trash-o"></i>'),
            show.path(parent.parent.context.entity),
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
        block = parent.context.class.row
        unless block.nil?
          instance_exec(parent.context.entity, &block)
        end
      end
    end

    class Table < WrapIt::Container
      default_tag 'table'
      html_class %w(table)
      attr_writer :context
      argument :context, if: AdminIt::Context

      def context
        @context ||= @template.context
      end

      def resource
        context.resource
      end

      child :header, Header
      child :row, Row
    end

    register :table, Table
  end
end
