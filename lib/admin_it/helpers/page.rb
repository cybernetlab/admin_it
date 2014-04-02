module AdminIt
  #
  module Helpers
    #
    class Page < WrapIt::Container
      default_tag 'body'

      child :create_top_menu, TopMenu
      child :create_toolbar, Toolbar

      def top_menu
        children.find { |item| item.is_a?(TopMenu) }
      end

      def toolbar
        children.find { |item| item.is_a?(Toolbar) }
      end

      after_initialize { self.deffered_render = true }

      before_capture do
        html_attr[:style] = 'padding-top: 70px;'
      end
    end

    register :body, Page
  end
end
