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
        context = parent.parent.context
        entity = context.entity
        resource = parent.parent.resource
        single = resource.singles.select { |c| !(c <= NewContext) }
        buttons = single.map do |_context|
          if _context <= ShowContext && context.show_in_dialog?
            '<a class="btn btn-xs btn-info" ' +
            %Q{data-toggle="modal" data-target="#confirm_modal" } +
            %Q{href="#{_context.path(entity)}?layout=dialog">} +
            %Q{<i class="fa fa-#{_context.icon}"></i></a>}
          else
            cl = _context <= ShowContext ? 'info' : 'default'
            href = _context.path(entity)
            "<a class=\"btn btn-xs btn-#{cl}\" href=\"#{href}\">" \
            "<i class=\"fa fa-#{_context.icon}\"></i></a>"
          end
        end
        if resource.destroyable?
          if context.confirm_destroy?
            confirm = single.find { |c| c.context_name == :confirm } ||
                      single.first { |c| c <= ShowContext }
            unless confirm.nil?
              buttons <<
                '<a class="btn btn-xs btn-danger" ' +
                %Q{data-toggle="modal" data-target="#confirm_modal" } +
                %Q{href="#{confirm.path(entity)}} +
                '?layout=dialog&confirm=destroy">' +
                '<i class="fa fa-trash-o"></i></a>'
            end
          else
            show = single.first { |c| c <= ShowContext }
            unless show.nil?
              buttons << @template.link_to(
                html_safe('<i class="fa fa-trash-o"></i>'),
                show.path(entity),
                method: :delete,
                class: 'btn btn-xs btn-danger'
              )
            end
          end
        end

        html = buttons.join
        html = "<div class=\"btn-group\">#{html}</div>" if buttons.size > 1

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
        block = parent.context.row
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
