module AdminIt
  module Helpers
    class Cell < WrapIt::Base
      include WrapIt::TextContainer
      default_tag 'td'
      attr_accessor :column
      option :column

      before_capture do
        unless column.nil?
          col = @template.admin_context.class.field(column)
          unless col.nil?
            col.render(@template.admin_context.entity, self)
          end
        end
      end
    end

    class ActionsCell < WrapIt::Base
      ACTIONS = { show: 'info-circle', edit: 'pencil' }

      default_tag 'td'

      before_capture do
        single = @template.admin_resource.contexts
          .select { |c, _| ACTIONS.keys.include?(c) }
        buttons = single.map do |c, context|
            cl = c == :show ? 'btn-info' : 'btn-default'
            href = context.path(@template.admin_context.entity)
            "<a class=\"btn btn-xs #{cl}\" href=\"#{href}\">" \
            "<i class=\"fa fa-#{ACTIONS[c]}\"></i></a>"
          end
        if single.key?(:show)
          buttons << @template.link_to(
            html_safe('<i class="fa fa-minus"></i>'),
            single[:show].path(@template.admin_context.entity),
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
        block = @template.admin_context.class.row
        unless block.nil?
          instance_exec(@template.admin_context.entity, &block)
        end
      end
    end

    class Table < WrapIt::Container
      default_tag 'table'
      html_class %w(table)

      def context
        @template.admin_context
      end

      child :header, Header
      child :row, Row
    end

    register :table, Table
  end
end
