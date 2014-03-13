module AdminIt
  module Helpers
    class TopMenuItem < WrapIt::Link
      attr_accessor :resource
      option :resource

      before_capture do
        unless resource.icon.nil?
          body << html_safe("<i class=\"fa fa-#{resource.icon}\"></i> ")
        end
        body << resource.display_name
        self.link = @template.url_for(
          controller: resource.name,
          action: resource.default_context
        )
        options = { tag: 'li' }
        options[:class] = 'active' if resource == @template.resource
        wrap(options)
      end
    end

    class TopMenu < WrapIt::Container
      default_tag 'ul'
      html_class 'nav'
      child :item, TopMenuItem

      after_initialize { self.deffered_render = true }

      before_capture do
        AdminIt.resources.each do |name, resource|
          next unless resource.menu == true
          item(resource: resource)
        end
      end
    end

    register :top_menu, TopMenu
  end
end
